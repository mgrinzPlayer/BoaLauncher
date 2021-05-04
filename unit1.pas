unit Unit1;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Zipper, windows, IniFiles;

var
  execName:string ='boa.exe:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';
  ipk3Name:string ='boa.ipk3:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';

  prepareBoA_addons_page_processing: boolean=false;
  terminate: boolean=false;

type

  { TForm1 }

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
    mainAddonsPanel: TPanel;
    ScrollBox1: TScrollBox;
    Image1: TImage;

    procedure btnAddonScanClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure ClosePreviewKey(Sender: TObject; var {%H-}Key: Word; {%H-}Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
    procedure Image1MouseDown(Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);

    procedure delayedExecution(Sender: TObject);
  private
    LanguageList: array of string;
    AddonList_titles: array of string;
    AddonList_fileNames: array of string;
    listOfAllAddonPanels: array of TPanel;
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
  ScrollBox1.Visible:=not ScrollBox1.Visible;
  if ScrollBox1.Visible then
  begin
    btnAddonScan.Caption:='Close addons informations';
    if not prepareBoA_addons_page_processing then preparing_BoA_addons_page();
  end
  else
    btnAddonScan.Caption:='Click to scan for addons';
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  SendMessage(Form1.Handle,WM_SYSCOMMAND,$F012,0);
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  SendMessage(Form1.Handle,WM_SYSCOMMAND,$F012,0);
end;


var delayedExecutionTimer: TTimer;

procedure TForm1.delayedExecution(Sender: TObject);
begin
  delayedExecutionTimer.Enabled:=false;

  AdjustComboboxSize(cbDetailPreset, Canvas);
  AdjustComboboxSize(cbDisplacementTextures, Canvas);
  AdjustComboboxSize(cbLanguage, Canvas);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SetCurrentDir(ExtractFilePath(ParamStr(0)));

  lblActiveAddon.Caption:='Addon not selected.';
  chkbLaunchWithAddon.Visible:=false;
  loadSettings;
  Image1.Picture.LoadFromResourceName(HInstance,'LAUNCHERIMAGE');

  removePadding(execName);
  removePadding(ipk3Name);

  findSupportedLanguages;

  delayedExecutionTimer:=TTimer.Create(Self);
  delayedExecutionTimer.OnTimer:=delayedExecution;
  delayedExecutionTimer.Interval:=1;
  delayedExecutionTimer.Enabled:=true;
end;

end.

