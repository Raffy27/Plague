unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics,
  Dialogs, ComCtrls, ExtCtrls, StdCtrls, Menus, BCButton, BCTypes,
  Windows, LCLType;

type

  { TBuildForm }

  TBuildForm = class(TForm)
    BaseLocLabel: TLabel;
    BaseLocButton: TBCButton;
    BuildStatLabel: TLabel;
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
    Label2: TLabel;
    SettingsMenu: TBCButton;
    MinimizeButton: TBCButton;
    MoveButton: TBCButton;
    AboutMenu: TBCButton;
    CloseButton: TBCButton;
    MenuSeparator: TShape;
    TopMenu: TPanel;
    DelaySelector: TUpDown;
    procedure BrowseButtonClick(Sender: TObject);
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
  private

  public
    procedure ChangeTab(AName: String);
  end;

var
  BuildForm: TBuildForm;
  PX, PY: Integer;
  MouseIsDown: Boolean;

  IconLoc, BaseLoc: String;

const
  ActiveC  = $0044F4AA;
  PassiveC = $001D1616;
  PActiveC = $00453434;
  PPassive = $00100C0C;
  MenuItemHeight = 26;

implementation

{$R *.lfm}

{ TBuildForm }

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
end;

procedure TBuildForm.FormDestroy(Sender: TObject);
begin

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

procedure TBuildForm.RandButtonClick(Sender: TObject);
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

end.

