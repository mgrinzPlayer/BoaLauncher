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
  if prepareBoA_addons_page_processing then exit;

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

  progressBar: TProgressBar;

  prevImgPreview: TImage=nil;
  lastControl: TControl=nil;

  start: qword=0;
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

  mainAddonsPanel.Free;
  mainAddonsPanel:=TPanel.Create(Form1);
  mainAddonsPanel.Parent:=ScrollBox1;
  mainAddonsPanel.Align:=alClient;

  progressBar:=TProgressBar.Create(Form1);
  progressBar.Max:=fileList.Count-1;
  progressBar.Parent:=Form1;
  progressBar.AnchorToCompanion(akTop,0,ScrollBox1);

  start:=GetTickCount64;
  for i:=0 to fileList.Count-1 do
  begin
    if terminate then break;

    progressBar.Position:=i;
    Application.ProcessMessages;
    prepareBoA_addons_page_processing:=true;

    pnlAddon:=TPanel.Create(mainAddonsPanel);
    pnlAddon.Parent:=mainAddonsPanel;
    pnlAddon.AutoSize:=true;

    if i=0 then
    begin
      pnlAddon.AnchorParallel(akTop,15,mainAddonsPanel);
      pnlAddon.AnchorParallel(akLeft,15,mainAddonsPanel);
      pnlAddon.AnchorParallel(akRight,15,mainAddonsPanel);
    end
    else
      pnlAddon.AnchorToCompanion(akTop,15,lastControl);

    lastControl:=pnlAddon;

    AddonList_fileNames[i]:=ExtractFileName(fileList[i]);
    listOfAllAddonPanels[i]:=pnlAddon;

    btnNameOfAddon:=TButton.Create(mainAddonsPanel);
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
      parseAddoninfoTXT(addoninfo_txt_SL,title,description,requirements,imageCount);
      AddonList_titles[i]:=title;

      btnNameOfAddon.BorderSpacing.Top:=10;
      btnNameOfAddon.Caption:=title;

      lblDescOfAddon:=TLabel.Create(mainAddonsPanel);
      lblDescOfAddon.Parent:=pnlAddon;
      lblDescOfAddon.WordWrap:=true;
      lblDescOfAddon.AutoSize:=true;
      lblDescOfAddon.AnchorToNeighbour(akTop,15,btnNameOfAddon);
      lblDescOfAddon.AnchorParallel(akLeft,10,pnlAddon);
      lblDescOfAddon.AnchorParallel(akRight,10,pnlAddon);
      lblDescOfAddon.Caption:='Description: '+description;

      lblRequirementsOfAddon:=TLabel.Create(mainAddonsPanel);
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
            imgPreview:=TImage.Create(mainAddonsPanel);
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

  //ShowMessage(FloatToStr((GetTickCount64 - start) / 1000)+' seconds');

  progressBar.Free;
  prepareBoA_addons_page_processing:=false;
end;
