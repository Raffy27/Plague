program Plague;

{$mode objfpc}{$H+}

uses
  Debug,
  NetModule, Tools,
  Classes, Windows, SysUtils, CmdWorker;

{$R *.res}

var
  J, I: LongInt;
  CmdID, ToAbort: String;

Begin
  LoadSettings;
  Initialize;
  if ParamStr(1)='/wait' then Sleep(2000);
  if ParamStr(2)='/removeold' then
    if FileExists(ParamStr(0)+'.old') then DeleteFile(ParamStr(0)+'.old');
  ChDir(ExtractFileDir(ParamStr(0)));
  //if Settings.ReadInteger('General', 'FirstRun', 1) = 1 then DoFirstRun;

  Net:=TNet.Create(Nil);
  Repeat
    Net.GetCommands;
    Writeln('Available commands: ',Net.CommandCount);
    For J:=1 to Net.CommandCount do Begin
      CmdID:=Net.GetCommandID(J);
      //Check if it is an Abort command
      if Net.Commands.ReadString(CmdID, 'Type', '')='Abort' then Begin
        ToAbort:=Net.Commands.ReadString(CmdID, 'CommandID', '');
        I:=ExecIndex(ToAbort);
        Workers[I].Abort(CmdID);
      end else Begin
        //Check if commands are already under execution
        I:=ExecIndex(CmdID);
        if I=-1 then Begin
          I:=FindAPlace;
          Writeln('Command ',CmdID,' will be assigned to Worker #',I,'.');
          Workers[I]:=TCmdWorker.Create(CmdID, I);
        end;
      end;
    end;
    //Readln;
    Sleep(Delay);
  until False;
end.
