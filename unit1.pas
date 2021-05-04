unit Unit1;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Zipper, windows, IniFiles;

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
    Panel1: TPanel;
    ScrollBox1: TScrollBox;
    Image1: TImage;

    procedure btnAddonScanClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ClosePreviewKey(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

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
    procedure ZipOnCreateStreamProc(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
    procedure ZipOnDoneStreamProc(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
    function ExtractSingleFileToStream(archiveName: string; fileName: string; var MS: TMemoryStream): boolean;
    function ExtractSingleFileToStringList(archiveName: string; fileName: string; var SL: TStringList): boolean;

    //addon preview
    procedure ClosePreviewClick(Sender: TObject);
    procedure PreviewClick(Sender: TObject);
    procedure previewButtonEnter(Sender: TObject);

    //main launcher
    procedure examineIPK3file;
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


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//                 extract from ZIP functions/procedures, parsing text helpers

function findFileInsideArchive(zip: TUnZipper; what: string):integer;
var i: integer;
begin
  for i:=0 to zip.Entries.Count-1 do
    if zip.Entries.Entries[i].ArchiveFileName=what then exit(i);
  result:=-1;
end;

procedure TForm1.ZipOnCreateStreamProc(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  AStream:=TMemorystream.Create;
end;

procedure TForm1.ZipOnDoneStreamProc(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  AStream.Position:=0;
  tmpMemoryStream:=TMemoryStream.Create;
  tmpMemoryStream.LoadFromStream(AStream);
  Astream.Free;
end;

function TForm1.ExtractSingleFileToStream(archiveName: string; fileName: string; var MS: TMemoryStream): boolean;
var
  zip: TUnZipper;
begin
  zip:=TUnZipper.Create;
  zip.FileName:=archiveName;
  zip.Examine;
  if findFileInsideArchive(zip,fileName)=-1 then exit(false);

  zip.OnCreateStream:=ZipOnCreateStreamProc;
  zip.OnDoneStream:=ZipOnDoneStreamProc;
  zip.UnZipFile(fileName);
  zip.Free;

  MS:=tmpMemoryStream; // swap
  tmpMemoryStream:=nil;
  result:=true;
end;

function TForm1.ExtractSingleFileToStringList(archiveName: string; fileName: string; var SL: TStringList): boolean;
var
  MS: TMemoryStream=nil;
begin
  if not ExtractSingleFileToStream(archiveName, fileName, MS) then exit(false);
  if not Assigned(SL) then SL:=TStringList.Create;
  SL.Clear;
  SL.LoadFromStream(MS);
  FreeAndNil(MS);
  result:=true;
end;

procedure trimComment(var s: string);
var a: integer;
begin
  a:=pos('//',s);
  if a>0 then s:=copy(s,1,a-1);
end;

procedure removePadding(var s: string);
var a: integer;
begin
  a:=pos(':',s);
  if a>0 then s:=copy(s,1,a-1);
end;

procedure parse_addoninfo_txt(SL: TStringList; var title,description,requirements: string; var previewImages: integer);
var
  s,key,value: string;
  i,a: integer;
begin
  title:='missing';
  description:='missing';
  requirements:='missing';
  previewImages:=0;

  for i:=0 to SL.Count-1 do
  begin
    s:=SL.Strings[i].Trim(); trimComment(s);
    if s='' then continue;
    a:=Pos('=',s);
    if (a>0) then
    begin
      key:=copy(s,1,a-1); key:=key.Trim().ToLower;
      value:=s.Substring(a+1); value:=value.Trim();
      if key='title' then title:=value;
      if key='description' then description:=value;
      if key='requirements' then requirements:=value;
      if key='previewimages' then previewImages:=StrToInt(value);
    end;
  end;
end;

procedure AdjustComboboxSize(cb: TComboBox; canvas: TCanvas);
var
  i,w: integer;
  maxwidth: integer=0;
  comboboxInfo: TComboboxInfo;
begin
  for i:=0 to cb.Items.Count-1 do maxwidth:=max(maxwidth, canvas.TextWidth(cb.Items[i]));

  comboboxInfo.cbSize:=sizeof(comboboxInfo);
  if GetComboBoxInfo(cb.Handle, @comboboxInfo) then
    w:=(cb.width+comboboxInfo.rcItem.Left-comboboxInfo.rcItem.Right)+maxwidth+4
  else
    w:=maxwidth+16;

  cb.width:=w;
  cb.Constraints.MinWidth:=w;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//                 parsing existing languages

procedure TForm1.examineIPK3file;
var
  i,j,a,b,c,d,z: integer;
  s: string;
  brackets: integer;
  menudef_txt_SL: TStringList=nil;
begin
  // finding languages
  // menudef.txt has OptionString "BoALanguageOptions" {"it", "Italiano (Italian)"\n"pl", "Polski (Polish)"}

  if not FileExists('boa.ipk3') then exit;
  if not ExtractSingleFileToStringList('boa.ipk3', 'menudef.txt', menudef_txt_SL) then exit;

  brackets:=0;
  for i:=0 to menudef_txt_SL.Count-1 do
  begin
    s:=menudef_txt_SL.Strings[i].Trim().ToLower;
    if s.StartsWith('optionstring "boalanguageoptions"') then
    begin
      s:=menudef_txt_SL.Strings[i+1].Trim(); trimComment(s);
      inc(brackets,s.CountChar('{'));dec(brackets,s.CountChar('}'));
      if brackets=0 then break;

      cbLanguage.Clear;
      cbLanguage.AddItem('Use Last Settings',nil);
      cbLanguage.ItemIndex:=0;

      for j:=i+2 to menudef_txt_SL.Count-1 do
      begin
        s:=menudef_txt_SL.Strings[j].Trim(); trimComment(s);
        if s='' then continue;

        inc(brackets,s.CountChar('{'));dec(brackets,s.CountChar('}'));
        if brackets=0 then break;

        a:=Pos('"',s);
        b:=Pos('"',s,a+1);
        c:=Pos('"',s,b+1);
        d:=Pos('"',s,c+1);

        if (a>0) and (b>0) and (c>0) and (d>0) then
        begin
          z:=length(LanguageList);
          setlength(LanguageList, z+1);
          LanguageList[z]:=copy(s,a+1,b-a-1);
          cbLanguage.AddItem(copy(s,c+1,d-c-1),nil);
        end;
      end;

      break;
    end;
  end;
end;



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//                 load/save setttings

procedure TForm1.saveSettings;
var
  inifile:TIniFile;
begin
  inifile:=TIniFile.Create('boa-launcher.ini');
  inifile.WriteBool('Launcher','DevCommentary',chkbDeveloperCommentary.Checked);
  inifile.WriteInteger('Launcher','DisplacementTextures',cbDisplacementTextures.ItemIndex);

  if chkbLaunchWithAddon.Checked then
  begin
    inifile.WriteBool('Launcher','LaunchWithAddon',true);
    inifile.WriteString('Launcher','addonTitle',addonTitle);
    inifile.WriteString('Launcher','addonFileName',addonFileName);
  end
  else
    inifile.WriteBool('Launcher','LaunchWithAddon',false);

  inifile.UpdateFile;
  inifile.Free;
end;

procedure TForm1.loadSettings;
var
  inifile:TIniFile;
begin
  inifile:=TIniFile.Create('boa-launcher.ini');
  chkbDeveloperCommentary.Checked:=inifile.ReadBool('Launcher','DevCommentary',false);
  cbDisplacementTextures.ItemIndex:=inifile.ReadInteger('Launcher','DisplacementTextures',0);

  addonTitle:=inifile.ReadString('Launcher','addonTitle','');
  addonFileName:=inifile.ReadString('Launcher','addonFileName','');
  chkbLaunchWithAddon.Checked:=inifile.ReadBool('Launcher','LaunchWithAddon',false);

  if (addonTitle<>'') and (addonFileName<>'') then
  begin
    lblActiveAddon.Caption:='Currently selected addon: "'+addonTitle+'"';
    chkbLaunchWithAddon.Visible:=true;
  end
  else
    chkbLaunchWithAddon.Checked:=false;

  inifile.Free;
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

  examineIPK3file;

  delayedExecutionTimer:=TTimer.Create(Self);
  delayedExecutionTimer.OnTimer:=delayedExecution;
  delayedExecutionTimer.Interval:=1;
  delayedExecutionTimer.Enabled:=true;
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

procedure TForm1.btnExitClick(Sender: TObject);
begin
  Application.Terminate;
end;



////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//                 executing boa.exe with arguments

procedure TForm1.btnStartClick(Sender: TObject);
var
  execName,ipk3Name,detail,displacement,devcom,lang,commandLineParam: string;
begin
  execName:='boa.exe:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';
  ipk3Name:='boa.ipk3:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';
  removePadding(execName);
  removePadding(ipk3Name);

  case cbDisplacementTextures.ItemIndex of
    0: displacement:='';  // without displacement textures
    1: displacement:='-file boa_dt.pk3';
  end;

  case cbDetailPreset.ItemIndex of
    0: detail:='';                     // unchanged
    1: detail:='+exec launcher-resource/detail-default.cfg';
    2: detail:='+exec launcher-resource/detail-verylow.cfg';
    3: detail:='+exec launcher-resource/detail-low.cfg';
    4: detail:='+exec launcher-resource/detail-normal.cfg';
    5: detail:='+exec launcher-resource/detail-high.cfg';
    6: detail:='+exec launcher-resource/detail-veryhigh.cfg';
  end;

  {
  case cbTextureFiltering.ItemIndex of
    0: filtering:='';                     //unchanged
    1: filtering:='+exec launcher-resource/texfilt-none.cfg';
    2: filtering:='+exec launcher-resource/texfilt-tri.cfg';
    3: filtering:='+exec launcher-resource/texfilt-nnx.cfg';
  end;
  }

  case chkbDeveloperCommentary.Checked of
    false: devcom:='+set boa_devcomswitch 0';
    true: devcom:='+set boa_devcomswitch 1';
  end;

  if cbLanguage.ItemIndex=0 then lang:=''
                            else lang:='+set language '+LanguageList[cbLanguage.ItemIndex-1];

  case (addonFileName<>'') and chkbLaunchWithAddon.Checked of
    false: commandLineParam:=Format('-iwad "%s" %s %s %s %s',[ipk3Name,displacement,detail,devcom,lang]);
    true: commandLineParam:=Format('-file "%s" %s %s %s %s',[addonFileName,displacement,detail,devcom,lang]);
  end;

  ShellExecute(0, 'open', pchar(execName), pchar(commandLineParam), '', sw_show);

  saveSettings;
  Application.Terminate;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//                 Addon stuff

procedure TForm1.btnAddonScanClick(Sender: TObject);
begin
  ScrollBox1.Visible:=not ScrollBox1.Visible;
  if ScrollBox1.Visible then
  begin
    btnAddonScan.Caption:='Close addons informations';
    preparing_BoA_addons_page();
  end
  else
    btnAddonScan.Caption:='Click to scan for addons';
end;

procedure TForm1.previewButtonEnter(Sender: TObject);
var
  pos: Integer=0;
  control: TControl;
begin
  control:=TControl(TControl(Sender).Parent); //panel pos
  inc(pos,control.Top);
  dec(pos,control.BorderSpacing.Top);

  if pos < ScrollBox1.VertScrollBar.Position then
    ScrollBox1.VertScrollBar.Position:=pos
  else if pos-ScrollBox1.VertScrollBar.Position+5 > ScrollBox1.Height then
    ScrollBox1.VertScrollBar.Position:=pos;
end;

procedure TForm1.addon_panelinfo_click(Sender: TObject);
var
  i,selected: integer;
begin
  selected:=TControl(Sender).Tag;
  addonTitle:=AddonList_titles[selected];
  addonFileName:=AddonList_fileNames[selected];

  lblActiveAddon.Caption:='Currently selected addon: "'+AddonList_titles[selected]+'"';
  chkbLaunchWithAddon.Checked:=true;
  chkbLaunchWithAddon.Visible:=true;

  for i:=0 to Length(listOfAllAddonPanels)-1 do // colors
  begin
    if i=selected then listOfAllAddonPanels[i].Color:=clActiveCaption
                  else listOfAllAddonPanels[i].Color:=clDefault;
  end;
end;

var
  PreviewImageFullSize: TImage;
  PreviewForm: TForm;

procedure TForm1.ClosePreviewClick(Sender: TObject);
begin
  PreviewForm.Close;
end;

procedure TForm1.ClosePreviewKey(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  PreviewForm.Close;
end;

procedure TForm1.PreviewClick(Sender: TObject);
begin
  PreviewForm:=TForm.Create(Form1);
  PreviewImageFullSize:=TImage.Create(PreviewForm);
  PreviewImageFullSize.Parent:=PreviewForm;
  PreviewImageFullSize.Picture.Assign(TImage(Sender).Picture);
  PreviewImageFullSize.Align:=alClient;
  PreviewImageFullSize.BorderSpacing.Around:=10;
  PreviewImageFullSize.Stretch:=true;
  PreviewImageFullSize.StretchInEnabled:=true;
  PreviewImageFullSize.StretchOutEnabled:=true;
  PreviewImageFullSize.OnClick:=ClosePreviewClick;

  PreviewForm.Color:=clBlack;
  PreviewForm.BorderStyle:=bsNone;
  PreviewForm.Position:=Form1.Position;
  PreviewForm.Constraints.MaxHeight:=Screen.DesktopHeight * 6 div 10;
  PreviewForm.Constraints.MaxWidth:=Screen.DesktopWidth * 6 div 10;
  PreviewForm.AutoSize:=true;

  PreviewForm.OnClick:=ClosePreviewClick;
  PreviewForm.OnKeyUp:=ClosePreviewKey;
  PreviewForm.ShowModal;
  PreviewForm.Free;
end;

procedure TForm1.preparing_BoA_addons_page;
var
  searchRec: TSearchRec;
  i,j,r: integer;
  fileList: TStringList=nil;
  addoninfo_txt_SL: TStringList=nil;
  MS: TMemoryStream=nil;

  title: string='';
  description: string='';
  requirements: string='';
  imageCount: integer=0;

  pnlAddon: TPanel;
  btnNameOfAddon: TButton; // user can use tab to select addon
  lblDescOfAddon, lblRequirementsOfAddon: TLabel;
  imgPreview: TImage;

  prevImgPreview: TImage=nil;
  lastControl: TControl=nil;

begin
  fileList:=TStringList.Create;
  ZeroMemory(@searchRec,sizeof(TSearchRec));
  r:=FindFirst('*.boa', FaAnyfile, searchRec);
  while (r=0) do
  begin
    fileList.Add(GetCurrentDir + pathdelim + searchRec.Name);
    r:=FindNext(searchRec);
  end;
  SysUtils.FindClose(searchRec);

  SetLength(AddonList_fileNames,fileList.Count);
  SetLength(AddonList_titles,fileList.Count);
  SetLength(listOfAllAddonPanels,fileList.Count);

  while Panel1.ControlCount>0 do Panel1.Controls[0].Free;

  for i:=0 to fileList.Count-1 do
  begin
    Application.ProcessMessages;

    pnlAddon:=TPanel.Create(Panel1);
    pnlAddon.Parent:=Panel1;
    pnlAddon.AutoSize:=true;

    if i=0 then
    begin
      pnlAddon.AnchorParallel(akTop,15,Panel1);
      pnlAddon.AnchorParallel(akLeft,15,Panel1);
      pnlAddon.AnchorParallel(akRight,15,Panel1);
    end
    else
      pnlAddon.AnchorToCompanion(akTop,15,lastControl);

    lastControl:=pnlAddon;

    AddonList_fileNames[i]:=ExtractFileName(fileList[i]);
    listOfAllAddonPanels[i]:=pnlAddon;

    btnNameOfAddon:=TButton.Create(Panel1);
    btnNameOfAddon.Parent:=pnlAddon;
    btnNameOfAddon.AutoSize:=true;
    btnNameOfAddon.AnchorParallel(akLeft,10,pnlAddon);
    btnNameOfAddon.AnchorParallel(akRight,10,pnlAddon);

    if not ExtractSingleFileToStringList(fileList[i], 'addoninfo.txt', addoninfo_txt_SL) then
    begin
      AddonList_titles[i]:=AddonList_fileNames[i];

      btnNameOfAddon.BorderSpacing.Top:=15;
      btnNameOfAddon.BorderSpacing.Bottom:=15;
      btnNameOfAddon.Caption:=ExtractFileName(fileList[i])+'  (couldn''t find addoninfo.txt)';
    end
    else
    begin
      parse_addoninfo_txt(addoninfo_txt_SL,title,description,requirements,imageCount);
      AddonList_titles[i]:=title;

      btnNameOfAddon.BorderSpacing.Top:=10;
      btnNameOfAddon.Caption:=title;

      lblDescOfAddon:=TLabel.Create(Panel1);
      lblDescOfAddon.Parent:=pnlAddon;
      lblDescOfAddon.WordWrap:=true;
      lblDescOfAddon.AutoSize:=true;
      lblDescOfAddon.AnchorToNeighbour(akTop,15,btnNameOfAddon);
      lblDescOfAddon.AnchorParallel(akLeft,10,pnlAddon);
      lblDescOfAddon.AnchorParallel(akRight,10,pnlAddon);
      lblDescOfAddon.Caption:='Description: '+description;

      lblRequirementsOfAddon:=TLabel.Create(Panel1);
      lblRequirementsOfAddon.Parent:=pnlAddon;
      lblRequirementsOfAddon.WordWrap:=true;
      lblRequirementsOfAddon.AutoSize:=true;
      lblRequirementsOfAddon.AnchorToNeighbour(akTop,15,lblDescOfAddon);
      lblRequirementsOfAddon.AnchorParallel(akLeft,10,pnlAddon);
      lblRequirementsOfAddon.AnchorParallel(akRight,10,pnlAddon);
      lblRequirementsOfAddon.Caption:='Requirements: '+requirements;
      lblRequirementsOfAddon.BorderSpacing.Bottom:=10;

      // PREVIEW IMAGES
      if imageCount>0 then
      begin
        for j:=1 to imageCount do
        begin
          Application.ProcessMessages;
          if ExtractSingleFileToStream(fileList[i], Format('preview/%d.jpg',[j]),MS) then
          begin
            imgPreview:=TImage.Create(Panel1);
            imgPreview.Picture.LoadFromStream(MS);
            imgPreview.Parent:=pnlAddon;
            imgPreview.Constraints.MaxWidth:=pnlAddon.Width div 2;
            imgPreview.Constraints.MaxHeight:=(9 * pnlAddon.Width div 2) div 16;
            imgPreview.Proportional:=true;
            imgPreview.AutoSize:=true;
            imgPreview.Stretch:=true;
            imgPreview.StretchInEnabled:=true;
            imgPreview.StretchOutEnabled:=false;
            imgPreview.AnchorParallel(akLeft,10,pnlAddon);

            imgPreview.Tag:=i;
            imgPreview.OnClick:=addon_panelinfo_click;
            imgPreview.OnDblClick:=PreviewClick;

            if prevImgPreview=nil then
              imgPreview.AnchorToNeighbour(akTop,0,lblRequirementsOfAddon)
            else
              imgPreview.AnchorToNeighbour(akTop,15,prevImgPreview);
            prevImgPreview:=imgPreview;

          end;
        end;
        prevImgPreview.BorderSpacing.Bottom:=10;
        prevImgPreview:=nil;
      end;

      //make them clickable
      lblDescOfAddon.Tag:=i;
      lblDescOfAddon.OnClick:=addon_panelinfo_click;
      lblRequirementsOfAddon.Tag:=i;
      lblRequirementsOfAddon.OnClick:=addon_panelinfo_click;
    end;

    //make them clickable
    pnlAddon.Tag:=i;
    pnlAddon.OnClick:=addon_panelinfo_click;
    btnNameOfAddon.Tag:=i;
    btnNameOfAddon.OnClick:=addon_panelinfo_click;
    btnNameOfAddon.OnEnter:=previewButtonEnter;


  end;//end loop: "for i:=0 to fileList.Count-1"

  pnlAddon.BorderSpacing.Bottom:=50;
end;

end.

