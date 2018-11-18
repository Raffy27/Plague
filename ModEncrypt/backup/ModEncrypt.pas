program ModEncrypt;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils;

var
  I, O: String;
  MS: TMemoryStream;

begin
  I:='';
  Repeat;
    Writeln('File to encrypt = ');
    Readln(I);
  until FileExists(I);
  Writeln('Encrypting...');
  MS:=TMemoryStream.Create;
  MS.LoadFromFile(I);
  MS.Position:=0;
  ToggleCrypt(MS, 7019);
  Writeln('Done.');
  Writeln('Output file = ');
  Readln(O);
  MS.SaveToFile(O);
  MS.Free;
  Writeln('Saved. Press ENTER to Exit');
  Readln;
end.

