unit Debug;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

procedure Dump(Str, F: String);
function MSToString(M: TMemoryStream): AnsiString;

implementation

procedure Dump(Str, F: String);
var
  FFile: Text;
Begin
  AssignFile(FFile, F);
  if FileExists(F) then Begin
    Append(FFile);
    Str:=sLineBreak+Str;
  end else Rewrite(FFile);
  Writeln(FFile, Str);
  CloseFile(FFile);
end;

function MSToString(M: TMemoryStream): AnsiString;
begin
  SetString(Result, PAnsiChar(M.Memory), M.Size);
end;

end.

