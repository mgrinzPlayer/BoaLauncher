unit Unit1;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Zipper, IniFiles{$ifdef windows}, Windows{$else}, process{$ifend};

var
  {$ifdef windows}
  execName:string ='boa.exe:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';
  {$else}
  execName:string ='gzdoom:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';
  {$ifend windows}
  ipk3Name:string ='boa.ipk3:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';

  prepareBoA_addons_page_processing: boolean=false;
  terminate: boolean=false;

  //for sandboxed packages
  userCommands: TStringList=nil;
  configs_and_saves_path: string='.'+PathDelim;
type

  { TForm1 }

  dotBoAFile = record
    Title: string;
    FileName: string;
    Panel: TPanel;
    PrevievImageCount: integer; // e.g. do not search for 7.jpg inside .boa when PrevievImageCount is 6
  end;

  TForm1 = class(TForm)
    lblDetailPreset: TLabel;
    cbDetailPreset: TComboBox;
    lblDisplacementTextures: TLabel;
    cbDisplacementTextures: TComboBox;
    lblLanguage: TLabel;
    cbLanguage: TComboBox;
    chkbDeveloperCommentary: TCheckBox;
    lblActiveAddon: TLabel;
    chkbLaunchWithAddon: TCheckBox;

    btnStart: TButton;
    btnExit: TButton;
    btnAddonScan: TButton;
    pnlAddonsContainer: TPanel;
    pnlSettingsControls: TPanel;
    pnlActiveAddon: TPanel;
    ScrollBox1: TScrollBox;

    Image1: TImage;
    Image2: TImage;
    Timer1: TTimer;

    procedure btnAddonScanClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure settingsControlsHorizontal(yes: boolean);
    procedure chkbLaunchWithAddonVisibilityChange(visible: boolean);
    procedure FormCreate(Sender: TObject);

    procedure PreviewKeyUp(Sender: TObject; var {%H-}Key: Word; {%H-}Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);

    procedure delayedExecution(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    LanguageList: array of string;
    AddonList: array of dotBoAFile;
    addonFileName: string;
    addonTitle: string;

    //zip
    tmpMemoryStream: TMemoryStream;

    procedure ZipOnCreateStreamProc(Sender: TObject; var AStream: TStream; {%H-}AItem: TFullZipFileEntry);
    procedure ZipOnDoneStreamProc(Sender: TObject; var AStream: TStream; {%H-}AItem: TFullZipFileEntry);

    function ExtractSingleFileToStream(archiveName: string; fileName: string; var MS: TMemoryStream): boolean;
    function ExtractSingleFileToStringList(archiveName: string; fileName: string; var SL: TStringList): boolean;

    //addon preview
    procedure ClosePreviewClick(Sender: TObject);
    procedure PreviewClick(Sender: TObject);
    procedure previewButtonEnter(Sender: TObject);

    //main launcher
    procedure gameExecute;
    procedure findSupportedLanguages;
    procedure addon_panelinfo_click(Sender: TObject);
    procedure preparing_BoA_addons_page;
    procedure saveSettings;
    procedure loadSettings;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

//extract from ZIP functions/procedures, parsing text helpers
{$I helpers.inc}

//parsing existing languages
{$I parsing.inc}

//load/save setttings
{$I loadAndSaveSetttings.inc}

//executing boa.exe with arguments
{$I executingTheGame.inc}

//Addons
{$I addonsPanel.inc}

procedure TForm1.btnStartClick(Sender: TObject);
begin
  saveSettings;
  gameExecute;
  Application.Terminate;
end;

procedure TForm1.btnExitClick(Sender: TObject);
begin
  terminate:=true;
  Application.Terminate;
end;

procedure TForm1.btnAddonScanClick(Sender: TObject);
begin
  if not ScrollBox1.Visible then
  begin
    settingsControlsHorizontal(false);
    ScrollBox1.Visible:=true;
    btnAddonScan.Caption:='Close addons informations';
    if not prepareBoA_addons_page_processing then preparing_BoA_addons_page();
  end
  else
  begin
    ScrollBox1.Visible:=false;
    settingsControlsHorizontal(true);
    btnAddonScan.Caption:='Click to scan for addons';
  end;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  {$ifdef windows}
  ReleaseCapture;
  SendMessage(Form1.Handle,WM_SYSCOMMAND,$F012,0);
  {$ifend windows}
end;


var delayedExecutionTimer: TTimer;

procedure TForm1.delayedExecution(Sender: TObject);
begin
  delayedExecutionTimer.Enabled:=false;

  AdjustComboboxSize(cbDetailPreset, Canvas);
  AdjustComboboxSize(cbDisplacementTextures, Canvas);
  AdjustComboboxSize(cbLanguage, Canvas);

  btnAddonScan.Width:=Canvas.getTextWidth('_____'+btnAddonScan.Caption+'_____');
end;

var animDirection:integer=0;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Interval:=100;
  if animDirection=0 then
  begin
    Image2.BorderSpacing.Bottom:=Image2.BorderSpacing.Bottom+1;
    if Image2.BorderSpacing.Bottom>=4 then
    begin
      Timer1.Interval:=1000;
      animDirection:=1;
    end;
  end
  else
  begin
    Image2.BorderSpacing.Bottom:=Image2.BorderSpacing.Bottom-1;
    if Image2.BorderSpacing.Bottom<=0 then
    begin
      Timer1.Interval:=1000;
      animDirection:=0;
    end;
  end
end;

procedure TForm1.settingsControlsHorizontal(yes: boolean);
var x:integer;
begin
  pnlSettingsControls.Anchors:=pnlSettingsControls.Anchors-[akBottom];
  pnlSettingsControls.DisableAutoSizing;

  if yes then
  begin
    pnlSettingsControls.AnchorHorizontalCenterTo(Form1);
    pnlSettingsControls.BorderSpacing.Left:=0;

    lblDetailPreset.AnchorHorizontalCenterTo(cbDetailPreset);

    lblDisplacementTextures.AnchorToNeighbour(akBottom,5,cbDisplacementTextures);
    lblDisplacementTextures.AnchorHorizontalCenterTo(cbDisplacementTextures);
    lblDisplacementTextures.Anchors:=[akLeft, akBottom];
    lblDisplacementTextures.BorderSpacing.Top:=0;

    cbDisplacementTextures.AnchorParallel(akTop,0,cbDetailPreset);
    cbDisplacementTextures.AnchorToNeighbour(akLeft,20,cbDetailPreset);

    lblLanguage.AnchorToNeighbour(akBottom,5,cbLanguage);
    lblLanguage.AnchorHorizontalCenterTo(cbLanguage);
    lblLanguage.Anchors:=[akLeft, akBottom];
    lblLanguage.BorderSpacing.Top:=0;

    cbLanguage.AnchorParallel(akTop,0,cbDisplacementTextures);
    cbLanguage.AnchorToNeighbour(akLeft,20,cbDisplacementTextures);

    chkbDeveloperCommentary.AnchorToNeighbour(akTop,5,cbDetailPreset);
    chkbDeveloperCommentary.BorderSpacing.Bottom:=0;

            cbDetailPreset.Width:=        cbDetailPreset.Constraints.MinWidth;
    cbDisplacementTextures.Width:=cbDisplacementTextures.Constraints.MinWidth;
                cbLanguage.Width:=            cbLanguage.Constraints.MinWidth;

  end
  else
  begin
    pnlSettingsControls.AnchorParallel(akLeft,15,Form1);

    lblDetailPreset.AnchorParallel(akLeft,0,pnlSettingsControls);

    lblDisplacementTextures.AnchorToNeighbour(akTop,30,cbDetailPreset);
    lblDisplacementTextures.AnchorParallel(akLeft,0,pnlSettingsControls);
    lblDisplacementTextures.Anchors:=[akLeft, akTop];

    cbDisplacementTextures.AnchorToNeighbour(akTop,5,lblDisplacementTextures);
    cbDisplacementTextures.AnchorParallel(akLeft,0,pnlSettingsControls);

    lblLanguage.AnchorToNeighbour(akTop,30,cbDisplacementTextures);
    lblLanguage.AnchorParallel(akLeft,0,pnlSettingsControls);
    lblLanguage.Anchors:=[akLeft, akTop];

    cbLanguage.AnchorToNeighbour(akTop,5,lblLanguage);
    cbLanguage.AnchorParallel(akLeft,0,pnlSettingsControls);

    chkbDeveloperCommentary.AnchorToNeighbour(akTop,30,cbLanguage);
    chkbDeveloperCommentary.BorderSpacing.Bottom:=30;

    x:=cbDetailPreset.Constraints.MinWidth;
    x:=max(x,cbDisplacementTextures.Constraints.MinWidth);
    x:=max(x,cbLanguage.Constraints.MinWidth);

            cbDetailPreset.Width:=x;
    cbDisplacementTextures.Width:=x;
                cbLanguage.Width:=x;

  end;

  pnlSettingsControls.EnableAutoSizing;
  pnlSettingsControls.AdjustSize;

  x:=btnStart.Top+btnStart.Height+15;
  Form1.Top:=Form1.Top - ( (x-Form1.Height) div 2 ); // fix position
  Form1.Height:=x;

  pnlSettingsControls.Anchors:=pnlSettingsControls.Anchors+[akBottom];
end;

procedure TForm1.chkbLaunchWithAddonVisibilityChange(visible: boolean);
begin
  if chkbLaunchWithAddon.Visible=visible then exit;

  chkbLaunchWithAddon.Visible:=visible;
  if visible then
  begin
    lblActiveAddon.AnchorToNeighbour(akLeft,0,chkbLaunchWithAddon);
    lblActiveAddon.AnchorVerticalCenterTo(chkbLaunchWithAddon);
  end
  else
  begin
    lblActiveAddon.AnchorParallel(akLeft,0,pnlActiveAddon);
    lblActiveAddon.AnchorParallel(akTop,0,pnlActiveAddon);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SetCurrentDir(ExtractFilePath(ParamStr(0)));

  loadSettings;
  Image1.Picture.LoadFromResourceName(HInstance,'LAUNCHERIMAGE');
  Image2.Picture.LoadFromResourceName(HInstance,'SIMPLEANIMATION');

  removePadding(execName);
  removePadding(ipk3Name);

  findSupportedLanguages;

  delayedExecutionTimer:=TTimer.Create(Self);
  delayedExecutionTimer.OnTimer:=delayedExecution;
  delayedExecutionTimer.Interval:=1;
  delayedExecutionTimer.Enabled:=true;
end;

end.

