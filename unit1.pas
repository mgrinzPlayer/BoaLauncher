unit Unit1;

{$mode delphi}

interface

uses
  Unit2, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Zipper, IniFiles, process{$ifdef windows}, Windows{$ifend};

var
  {$ifdef windows}
  execName:string ='boa.exe:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';
  {$else}
  execName:string ='gzdoom:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';
  {$ifend windows}
  ipk3Name:string ='boa.ipk3:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';

  prepareBoA_addons_page_processing: boolean=false;
  terminate: boolean=false;

  langid: string='';

  //for sandboxed packages
  userCommands: TStringList=nil;
  configs_and_saves_path: string='.'+PathDelim;
type

  { TForm1 }

  dotBoAFile = record
    Panel: TPanel;
    FileName: string;
    hasAddonInfoTXT: boolean;
    Title: string;
    Credits: string;
    CreditsFull: string;
    Description: string;
    Requirements: string;
    PrevievImageCount: integer; // e.g. do not search for 7.jpg inside .boa when PrevievImageCount is 6
  end;

  dotBoAFileArray = array of dotBoAFile;

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

    btnPlay: TButton;
    btnExit: TButton;
    btnAddonScan: TButton;
    btnAddonMultiselect: TButton;
    pnlAddonsContainer: TPanel;
    pnlSettingsControls: TPanel;
    pnlActiveAddon: TPanel;
    ScrollBox1: TScrollBox;

    Image1: TImage;
    Image2: TImage;
    Timer1: TTimer;

    procedure btnAddonMultiselectClick(Sender: TObject);
    procedure btnAddonScanClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure settingsControlsHorizontal(yes: boolean);
    procedure chkbLaunchWithAddonVisibilityChange(visible: boolean);
    procedure FormCreate(Sender: TObject);

    procedure PreviewKeyUp(Sender: TObject; var {%H-}Key: Word; {%H-}Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);

    procedure delayedExecution(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    LanguageList: array of string;
    AddonList: dotBoAFileArray;
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

resourcestring
  rsUseLastSettings = 'Use last settings';
  rsResetToDefaultSettings = 'Reset to default settings';

  rsDetailPreset = 'Detail preset:';
  rsVeryLowDetail = 'Very low detail (fastest)';
  rsLowDetail = 'Low detail (faster)';
  rsNormalDetail = 'Normal detail';
  rsHighDetail = 'High detail (prettier)';
  rsVeryHighDetail = 'Very high detail (beautiful)';

  rsDisplacementTextures = 'Displacement textures:';
  rsDisplacementTexturesDisable = 'Disable (faster)';
  rsDisplacementTexturesEnable = 'Enable (beautiful)';

  rsLanguage = 'Game language:';

  rsDeveloperCommentary = 'Developer commentary';

  rsLaunchWithAddon = 'Launch with:';

  rsPlay = 'Play';
  rsExit = 'Exit';

  rsAddonScan = 'Scan for addons';
  rsAddonHide = 'Hide addons';
  rsAddonMultiselect = 'Select multiple addons';
  rsNoAddonSelected = 'No addon selected.';
  rsAndMore = ', and %d more';

  rsAddonPreview = 'Addon preview';
  rsAddonPreview_alt= 'Addon preview (use arrow keys to see other images)';
  rsDescription = 'Description:';
  rsRequirements = 'Requirements:';
  rsCreditsAuthor = ' by %s ';
  rsDoubleClick = 'double click';

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

procedure TForm1.btnPlayClick(Sender: TObject);
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
    btnAddonScan.Caption:=rsAddonHide;
    if not prepareBoA_addons_page_processing then preparing_BoA_addons_page();
  end
  else
  begin
    ScrollBox1.Visible:=false;
    settingsControlsHorizontal(true);
    btnAddonScan.Caption:=rsAddonScan;
  end;
end;

procedure TForm1.btnAddonMultiselectClick(Sender: TObject);
var
  i: integer;
  s: string;
begin
  Form2:=TForm2.Create(Form1);

  scanAllBoaFiles(AddonList);

  for i:=0 to Length(AddonList)-1 do
    if Pos(AddonList[i].FileName,addonFileName)=0 then Form2.ListBox1.Items.AddObject(AddonList[i].Title,TStringStream.Create(AddonList[i].FileName));

  if addonFileName<>'' then
    for s in addonFileName.Split([':']) do
      for i:=0 to Length(AddonList)-1 do
        if s=AddonList[i].FileName then begin Form2.ListBox2.Items.AddObject(AddonList[i].Title,TStringStream.Create(AddonList[i].FileName)); break; end;

  Form2.ListBox2.Items.Add(' '); // empty item

  if (Form2.ShowModal=mrOK) then
  begin
    if (Form2.ListBox2.Items.Count>=2) then
    begin
      chkbLaunchWithAddon.Checked:=true;
      chkbLaunchWithAddonVisibilityChange(true);

      addonTitle:='"'+Form2.ListBox2.Items[0]+'"';
      addonFileName:=TStringStream(Form2.ListBox2.Items.Objects[0]).DataString;

      for i:=1 to Form2.ListBox2.Items.Count-2 do  // -2, because we ignore the last empty item
      begin
        if i<3 then addonTitle:=addonTitle+', "'+Form2.ListBox2.Items[i]+'"';
        if i=3 then addonTitle:=addonTitle+Format(rsAndMore,[(Form2.ListBox2.Items.Count-4)]);
        addonFileName:=addonFileName+':'+TStringStream(Form2.ListBox2.Items.Objects[i]).DataString;
      end;

      lblActiveAddon.Caption:=addonTitle;
    end
    else
    begin
      chkbLaunchWithAddon.Checked:=false;
      chkbLaunchWithAddonVisibilityChange(false);
      addonFileName:='';
    end;
  end;

  for i:=1 to Form2.ListBox1.Items.Count-1 do Form2.ListBox1.Items.Objects[i].Free;
  for i:=1 to Form2.ListBox2.Items.Count-1 do Form2.ListBox2.Items.Objects[i].Free;
  Form2.Free;
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
var calcWidth: integer=0;
begin
  delayedExecutionTimer.Enabled:=false;

  AdjustComboboxSize(cbDetailPreset, Canvas);
  AdjustComboboxSize(cbDisplacementTextures, Canvas);
  AdjustComboboxSize(cbLanguage, Canvas);

  btnAddonScan.Width:=Canvas.getTextWidth('_____'+btnAddonScan.Caption+'_____');
  btnAddonMultiselect.Width:=Canvas.getTextWidth('_____'+btnAddonMultiselect.Caption+'_____');

  calcWidth:=max(Canvas.getTextWidth('_____'+btnPlay.Caption+'_____'),Canvas.getTextWidth('_____'+btnExit.Caption+'_____'));
  btnPlay.Width:=calcWidth;
  btnExit.Width:=calcWidth;

  Constraints.MinHeight:=btnPlay.Top+btnPlay.Height+15;
  Height:=Constraints.MinHeight;
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

  x:=btnPlay.Top+btnPlay.Height+15;
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
    lblActiveAddon.Caption:=rsNoAddonSelected;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  lblDetailPreset.Caption:=rsDetailPreset;
  cbDetailPreset.Items.Add(rsUseLastSettings);
  cbDetailPreset.Items.Add(rsResetToDefaultSettings);
  cbDetailPreset.Items.Add(rsVeryLowDetail);
  cbDetailPreset.Items.Add(rsLowDetail);
  cbDetailPreset.Items.Add(rsNormalDetail);
  cbDetailPreset.Items.Add(rsHighDetail);
  cbDetailPreset.Items.Add(rsVeryHighDetail);
  cbDetailPreset.ItemIndex:=0;

  lblDisplacementTextures.Caption:=rsDisplacementTextures;
  cbDisplacementTextures.Items.Add(rsDisplacementTexturesDisable);
  cbDisplacementTextures.Items.Add(rsDisplacementTexturesEnable);
  cbDisplacementTextures.ItemIndex:=0;

  lblLanguage.Caption:=rsLanguage;
  cbLanguage.Items.Add(rsUseLastSettings);
  cbLanguage.ItemIndex:=0;

  chkbDeveloperCommentary.Caption:=rsDeveloperCommentary;
  chkbLaunchWithAddon.Caption:=rsLaunchWithAddon;

  btnPlay.Caption:=rsPlay;
  btnExit.Caption:=rsExit;
  btnAddonScan.Caption:=rsAddonScan;
  btnAddonMultiselect.Caption:=rsAddonMultiselect;

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

