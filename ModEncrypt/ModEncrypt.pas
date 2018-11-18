program ModEncrypt;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils;

var
  I, O: String;
  MS: TMemoryStream;

procedure ToggleCrypt(var MS: TMemoryStream; Key: Word);
var
   InMS: TMemoryStream;
   cnt: Integer;
   C: byte;
begin
  C:=0;
  InMS := TMemoryStream.Create;
  try
    InMS.CopyFrom(MS, MS.Size);
    InMS.Position := 0;
    MS.Clear;
    for cnt := 0 to InMS.Size - 1 do
      begin
        InMS.Read(C, 1) ;
        C := (C xor not (ord(Key shr cnt)));
        MS.Write(C, 1) ;
      end;
  finally
    InMS.Free;
  end;
end;

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

