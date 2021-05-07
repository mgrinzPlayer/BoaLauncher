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

  lblActiveAddon.Caption:='"'+AddonList_titles[selected]+'"';
  chkbLaunchWithAddon.Checked:=true;
  chkbLaunchWithAddonVisibilityChange(true);

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

  progressBar: TProgressBar;

  prevImgPreview: TImage=nil;
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

    pnlAddon:=TPanel.Create(mainAddonsPanel);
    pnlAddon.Parent:=mainAddonsPanel;
    pnlAddon.BorderSpacing.Bottom:=bottomMargin;

    if i=0 then
    begin
      pnlAddon.AnchorParallel(akTop,topMargin,mainAddonsPanel);
      pnlAddon.AnchorParallel(akLeft,leftMargin,mainAddonsPanel);
      pnlAddon.AnchorParallel(akRight,rightMargin,mainAddonsPanel);
    end
    else
      pnlAddon.AnchorToCompanion(akTop,topMargin,lastControl);

    lastControl:=pnlAddon;

    AddonList_fileNames[i]:=ExtractFileName(fileList[i]);
    listOfAllAddonPanels[i]:=pnlAddon;

    btnNameOfAddon:=TButton.Create(mainAddonsPanel);
    btnNameOfAddon.Parent:=pnlAddon;
    btnNameOfAddon.AutoSize:=true;
    btnNameOfAddon.AnchorParallel(akTop,topMargin,pnlAddon);
    btnNameOfAddon.AnchorParallel(akLeft,leftMargin,pnlAddon);
    btnNameOfAddon.AnchorParallel(akRight,rightMargin,pnlAddon);

    if ExtractSingleFileToStringList(fileList[i], 'addoninfo.txt', addonInfoTXT) then
    begin
      parseAddonInfoTXT(addonInfoTXT,title,credits,description,requirements,imageCount);
      AddonList_titles[i]:=title;

      btnNameOfAddon.Caption:=title+#32+credits;

      lblDescOfAddon:=TLabel.Create(mainAddonsPanel);
      lblDescOfAddon.Parent:=pnlAddon;
      lblDescOfAddon.WordWrap:=true;
      lblDescOfAddon.AutoSize:=true;
      lblDescOfAddon.AnchorToNeighbour(akTop,buttonBottomSpace,btnNameOfAddon);
      lblDescOfAddon.AnchorParallel(akLeft,leftMargin,pnlAddon);
      lblDescOfAddon.AnchorParallel(akRight,rightMargin,pnlAddon);
      lblDescOfAddon.Caption:='Description:'+LineEnding+description;

      lblRequirementsOfAddon:=TLabel.Create(mainAddonsPanel);
      lblRequirementsOfAddon.Parent:=pnlAddon;
      lblRequirementsOfAddon.WordWrap:=true;
      lblRequirementsOfAddon.AutoSize:=true;
      lblRequirementsOfAddon.AnchorToCompanion(akTop,blockSpacing,lblDescOfAddon);
      lblRequirementsOfAddon.BorderSpacing.Bottom:=bottomMargin;
      lblRequirementsOfAddon.Caption:='Requirements:'+LineEnding+requirements;

      //show only icon if exists
      if ExtractSingleFileToStream(fileList[i],'preview/icon.png',MS)
      then
      begin
        imgPreview:=TImage.Create(mainAddonsPanel);
        imgPreview.Picture.LoadFromStream(MS);
        imgPreview.Parent:=pnlAddon;
        imgPreview.Constraints.MaxWidth:= 128;
        imgPreview.Constraints.MaxHeight:=(9 * imgPreview.Constraints.MaxWidth) div 16;
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
      end
      else // else show preview images
      begin
        prevImgPreview:=nil;
        imgPreview:=nil;
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
              imgPreview.Constraints.MaxWidth:= 128;
              imgPreview.Constraints.MaxHeight:=(9 * imgPreview.Constraints.MaxWidth) div 16;
              imgPreview.AnchorParallel(akRight,0,btnNameOfAddon);
              imgPreview.Anchors:=imgPreview.Anchors-[akLeft];

              if prevImgPreview=nil then
              begin
                imgPreview.AnchorToNeighbour(akTop,buttonBottomSpace,btnNameOfAddon);
                lblDescOfAddon.AnchorToNeighbour(akRight,rightMargin,imgPreview);
              end
              else
                imgPreview.AnchorToNeighbour(akTop,blockSpacing,prevImgPreview);

              imgPreview.Proportional:=true;
              imgPreview.Stretch:=true;
              imgPreview.StretchInEnabled:=true;
              imgPreview.StretchOutEnabled:=false;
              imgPreview.AutoSize:=true;

              imgPreview.Tag:=i;
              imgPreview.OnClick:=addon_panelinfo_click;
              imgPreview.OnDblClick:=PreviewClick;

              prevImgPreview:=imgPreview;

            end;
          end;
          imgPreview.BorderSpacing.Bottom:=bottomMargin;
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
      AddonList_titles[i]:=AddonList_fileNames[i];
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
  prepareBoA_addons_page_processing:=false;
end;
