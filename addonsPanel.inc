procedure TForm1.previewButtonEnter(Sender: TObject);
var
  pos: Integer;
  control: TControl;
begin
  control:=TControl(TControl(Sender).Parent); //panel pos
  pos:=control.Top;
  dec(pos,control.BorderSpacing.Top);

  if pos < ScrollBox1.VertScrollBar.Position then
    ScrollBox1.VertScrollBar.Position:=pos
  else if pos-ScrollBox1.VertScrollBar.Position > (3 * ScrollBox1.Height div 4) then
    ScrollBox1.VertScrollBar.Position:=pos;
end;

procedure TForm1.addon_panelinfo_click(Sender: TObject);
var
  i,selected: integer;
begin
  if prepareBoA_addons_page_processing then exit;

  selected:=TControl(Sender).Tag;
  addonTitle:=AddonList[selected].Title;
  addonFileName:=AddonList[selected].FileName;

  lblActiveAddon.Caption:='"'+addonTitle+'"';
  chkbLaunchWithAddon.Checked:=true;
  chkbLaunchWithAddonVisibilityChange(true);

  for i:=0 to Length(AddonList)-1 do // colors
  begin
    if i=selected then AddonList[i].Panel.Color:=clActiveCaption
                  else AddonList[i].Panel.Color:=clDefault;
  end;
end;

var
  PreviewForm: TForm;
  PreviewImageFullSize: TImage;
  previewImagesArray: array of TMemoryStream;
  PreviewImageIndex: integer;

procedure TForm1.ClosePreviewClick(Sender: TObject);
begin
  PreviewForm.Close;
end;

procedure TForm1.PreviewKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (key=37) or (key=38) then
  begin
    PreviewImageIndex:=max(0,PreviewImageIndex-1);
    previewImagesArray[PreviewImageIndex].Position:=0;
    PreviewImageFullSize.Picture.LoadFromStream(previewImagesArray[PreviewImageIndex]);
  end
  else if (key=39) or (key=40) then
  begin
    PreviewImageIndex:=min(Length(previewImagesArray)-1,PreviewImageIndex+1);
    previewImagesArray[PreviewImageIndex].Position:=0;
    PreviewImageFullSize.Picture.LoadFromStream(previewImagesArray[PreviewImageIndex]);
  end
  else
    PreviewForm.Close;
end;

procedure TForm1.PreviewClick(Sender: TObject);
var
  i,j,r: integer;
  MS: TMemoryStream=nil;
begin
  i:=TControl(Sender).Tag;
  if AddonList[i].PrevievImageCount<=0 then exit;

  PreviewImageIndex:=0;

  PreviewForm:=TForm.Create(Form1);
  PreviewForm.Color:=clBlack;
  PreviewForm.BorderStyle:=bsToolWindow;
  PreviewForm.Position:=Form1.Position;
  PreviewForm.Constraints.MaxHeight:=Screen.DesktopHeight * 6 div 10;
  PreviewForm.Constraints.MaxWidth:=Screen.DesktopWidth * 6 div 10;
  PreviewForm.AutoSize:=true;
  PreviewForm.OnClick:=ClosePreviewClick;
  PreviewForm.OnKeyUp:=PreviewKeyUp;

  PreviewImageFullSize:=TImage.Create(PreviewForm);
  PreviewImageFullSize.Parent:=PreviewForm;
  PreviewImageFullSize.Align:=alClient;
  PreviewImageFullSize.BorderSpacing.Around:=10;
  PreviewImageFullSize.Stretch:=true;
  PreviewImageFullSize.StretchInEnabled:=true;
  PreviewImageFullSize.StretchOutEnabled:=true;
  PreviewImageFullSize.OnClick:=ClosePreviewClick;

  //cleanup
  for j:=0 to Length(previewImagesArray)-1 do previewImagesArray[j].free;
  SetLength(previewImagesArray,0);

  //try to load all known existing images
  for j:=1 to AddonList[i].PrevievImageCount do
  begin
    if ExtractSingleFileToStream(AddonList[i].FileName,format('preview/%d.jpg',[j]),MS) then
    begin
      r:=Length(previewImagesArray);
      SetLength(previewImagesArray,r+1);
      previewImagesArray[r]:=MS;
    end;
  end;

  if Length(previewImagesArray)>0 then
  begin
    PreviewForm.Caption:='Add-on preview.';
    if Length(previewImagesArray)>1 then
      PreviewForm.Caption:=PreviewForm.Caption + ' Use arrow keys to see other images';
  end;

  previewImagesArray[0].Position:=0;
  PreviewImageFullSize.Picture.LoadFromStream(previewImagesArray[0]);

  PreviewForm.ShowModal;

  //cleanup
  PreviewForm.Free;
  for j:=0 to Length(previewImagesArray)-1 do previewImagesArray[j].free;
  SetLength(previewImagesArray,0);
end;

procedure TForm1.preparing_BoA_addons_page;
var
  searchRec: TSearchRec;
  i,r: integer;
  fileList: TStringList=nil;
  addonInfoTXT: TStringList=nil;
  MS: TMemoryStream=nil;

  title: string='';
  credits: string='';
  description: string='';
  requirements: string='';
  imageCount: integer=0;

  pnlAddon: TPanel;
  btnNameOfAddon: TButton; // user can use tab to select addon
  lblDescOfAddon, lblRequirementsOfAddon: TLabel;
  imgPreview: TImage;

  creditsPnl: TPanel;
  creditsLbl: TLabel;

  progressBar: TProgressBar;

  lastControl: TControl=nil;
const
  leftMargin=10;// pnlAddon margins
  rightMargin=10;
  topMargin=15;
  bottomMargin=15;

  buttonBottomSpace=15;// space between btnNameOfAddon and other control below
  blockSpacing=10; //space between two TextBlocks, or two images
begin

  fileList:=TStringList.Create;
  r:=FindFirst('*.boa', FaAnyfile, searchRec);
  while (r=0) do
  begin
    fileList.Add(GetCurrentDir + pathdelim + searchRec.Name);
    r:=FindNext(searchRec);
  end;
  SysUtils.FindClose(searchRec);

  fileList.Sort;

  SetLength(AddonList,fileList.Count);

  pnlAddonsContainer.Free;
  pnlAddonsContainer:=TPanel.Create(Form1);
  pnlAddonsContainer.Parent:=ScrollBox1;
  pnlAddonsContainer.Align:=alClient;
  pnlAddonsContainer.BevelOuter:=bvNone;

  progressBar:=TProgressBar.Create(Form1);
  progressBar.Max:=fileList.Count-1;
  progressBar.Parent:=Form1;
  progressBar.Anchors:=[];
  progressBar.AnchorParallel(akBottom,0,ScrollBox1);
  progressBar.AnchorParallel(akLeft,0,ScrollBox1);
  progressBar.AnchorParallel(akRight,0,ScrollBox1);

  prepareBoA_addons_page_processing:=true;

  for i:=0 to fileList.Count-1 do
  begin
    if terminate then break;

    progressBar.Position:=i;
    Application.ProcessMessages;

    pnlAddon:=TPanel.Create(pnlAddonsContainer);
    pnlAddon.Parent:=pnlAddonsContainer;
    pnlAddon.BorderSpacing.Bottom:=bottomMargin;

    if i=0 then
    begin
      pnlAddon.AnchorParallel(akTop,topMargin,pnlAddonsContainer);
      pnlAddon.AnchorParallel(akLeft,leftMargin,pnlAddonsContainer);
      pnlAddon.AnchorParallel(akRight,rightMargin,pnlAddonsContainer);
    end
    else
      pnlAddon.AnchorToCompanion(akTop,topMargin,lastControl);

    lastControl:=pnlAddon;

    AddonList[i].FileName:=ExtractFileName(fileList[i]);
    AddonList[i].Panel:=pnlAddon;

    btnNameOfAddon:=TButton.Create(pnlAddonsContainer);
    btnNameOfAddon.Parent:=pnlAddon;
    btnNameOfAddon.AutoSize:=true;
    btnNameOfAddon.AnchorParallel(akTop,topMargin,pnlAddon);
    btnNameOfAddon.AnchorParallel(akLeft,leftMargin,pnlAddon);
    btnNameOfAddon.AnchorParallel(akRight,rightMargin,pnlAddon);

    if ExtractSingleFileToStringList(fileList[i], 'addoninfo.txt', addonInfoTXT) then
    begin
      parseAddonInfoTXT(addonInfoTXT,title,credits,description,requirements,imageCount);
      AddonList[i].Title:=title;
      AddonList[i].PrevievImageCount:=imageCount;

      btnNameOfAddon.Caption:=title;

      creditsPnl:= TPanel.Create(pnlAddonsContainer);
      creditsPnl.Parent:=pnlAddon;
      creditsPnl.Anchors:=[];
      creditsPnl.AnchorVerticalCenterTo(btnNameOfAddon);
      creditsPnl.AnchorParallel(akRight,5,btnNameOfAddon);
      creditsPnl.BevelOuter:=bvNone;
      creditsPnl.AutoSize:=True;
      creditsLbl:=TLabel.Create(pnlAddonsContainer);
      creditsLbl.Parent:=creditsPnl;
      creditsLbl.Align:=alRight;
      creditsLbl.Font.Style:=[fsBold];
      creditsLbl.BorderSpacing.Bottom:=1;
      creditsLbl.Caption:=' by '+credits+' ';

      lblDescOfAddon:=TLabel.Create(pnlAddonsContainer);
      lblDescOfAddon.Parent:=pnlAddon;
      lblDescOfAddon.WordWrap:=true;
      lblDescOfAddon.AutoSize:=true;
      lblDescOfAddon.AnchorToNeighbour(akTop,buttonBottomSpace,btnNameOfAddon);
      lblDescOfAddon.AnchorParallel(akLeft,leftMargin,pnlAddon);
      lblDescOfAddon.AnchorParallel(akRight,rightMargin,pnlAddon);
      lblDescOfAddon.Caption:='Description:'+LineEnding+description;

      lblRequirementsOfAddon:=TLabel.Create(pnlAddonsContainer);
      lblRequirementsOfAddon.Parent:=pnlAddon;
      lblRequirementsOfAddon.WordWrap:=true;
      lblRequirementsOfAddon.AutoSize:=true;
      lblRequirementsOfAddon.AnchorToCompanion(akTop,blockSpacing,lblDescOfAddon);
      lblRequirementsOfAddon.BorderSpacing.Bottom:=bottomMargin;
      lblRequirementsOfAddon.Caption:='Requirements:'+LineEnding+requirements;

      //show icon if exists
      if ExtractSingleFileToStream(fileList[i],'preview/icon.png',MS)
      then
      begin
        imgPreview:=TImage.Create(pnlAddonsContainer);
        imgPreview.Picture.LoadFromStream(MS);
        imgPreview.Parent:=pnlAddon;
        imgPreview.Constraints.MaxWidth:=trunc(Screen.PixelsPerInch / Form1.DesignTimePPI * 128);
        imgPreview.Constraints.MaxHeight:= (9 * imgPreview.Constraints.MaxWidth) div 16;
        imgPreview.AnchorParallel(akRight,0,btnNameOfAddon);
        imgPreview.Anchors:=imgPreview.Anchors-[akLeft];
        imgPreview.AnchorToNeighbour(akTop,buttonBottomSpace,btnNameOfAddon);

        lblDescOfAddon.AnchorToNeighbour(akRight,rightMargin,imgPreview);

        imgPreview.Proportional:=true;
        imgPreview.Stretch:=true;
        imgPreview.StretchInEnabled:=true;
        imgPreview.StretchOutEnabled:=false;
        imgPreview.AutoSize:=true;

        imgPreview.Tag:=i;
        imgPreview.OnClick:=addon_panelinfo_click;
        if imageCount>0 then
        begin
          imgPreview.Cursor:=crHandPoint;
          imgPreview.OnDblClick:=PreviewClick;
        end;
      end
      else if imageCount>0 then // else show preview image
      begin
        if ExtractSingleFileToStream(fileList[i],'preview/1.jpg',MS) then
        begin
          imgPreview:=TImage.Create(pnlAddonsContainer);
          imgPreview.Cursor:=crHandPoint;
          imgPreview.Picture.LoadFromStream(MS);
          imgPreview.Parent:=pnlAddon;
          imgPreview.Constraints.MaxWidth:= trunc(Screen.PixelsPerInch / Form1.DesignTimePPI * 128);
          imgPreview.Constraints.MaxHeight:= (9 * imgPreview.Constraints.MaxWidth) div 16;
          imgPreview.AnchorParallel(akRight,0,btnNameOfAddon);
          imgPreview.Anchors:=imgPreview.Anchors-[akLeft];
          imgPreview.AnchorToNeighbour(akTop,buttonBottomSpace,btnNameOfAddon);

          lblDescOfAddon.AnchorToNeighbour(akRight,rightMargin,imgPreview);

          imgPreview.Proportional:=true;
          imgPreview.Stretch:=true;
          imgPreview.StretchInEnabled:=true;
          imgPreview.StretchOutEnabled:=false;
          imgPreview.AutoSize:=true;

          imgPreview.Tag:=i;
          imgPreview.OnClick:=addon_panelinfo_click;
          imgPreview.OnDblClick:=PreviewClick;
        end;
      end;

      //make them clickable
      lblDescOfAddon.Tag:=i;
      lblDescOfAddon.OnClick:=addon_panelinfo_click;
      lblRequirementsOfAddon.Tag:=i;
      lblRequirementsOfAddon.OnClick:=addon_panelinfo_click;
    end
    else
    begin
      AddonList[i].Title:=AddonList[i].FileName;
      btnNameOfAddon.Caption:=ExtractFileName(fileList[i]);
      btnNameOfAddon.BorderSpacing.Bottom:=bottomMargin;
    end;

    //make them clickable (common)
    pnlAddon.Tag:=i;
    pnlAddon.OnClick:=addon_panelinfo_click;
    btnNameOfAddon.Tag:=i;
    btnNameOfAddon.OnClick:=addon_panelinfo_click;
    btnNameOfAddon.OnEnter:=previewButtonEnter;

    pnlAddon.AutoSize:=true;

  end;//end loop: "for i:=0 to fileList.Count-1"

  progressBar.Free;
  if fileList<>nil then FreeAndNil(fileList);
  if addonInfoTXT<>nil then FreeAndNil(addonInfoTXT);
  if MS<>nil then FreeAndNil(MS);

  prepareBoA_addons_page_processing:=false;
end;
