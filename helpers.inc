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

function trimComment(s: string): string;
var a: integer;
begin
  result:=s.Replace('://',':\/\/');
  a:=pos('//',result);
  if a>0 then result:=result.Substring(0,a-1).Trim();
  result:=s.Replace(':\/\/','://');
end;

procedure removePadding(var s: string);
var a: integer;
begin
  a:=pos(':',s);
  if a>0 then s:=copy(s,1,a-1);
end;

{$ifdef windows}
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

  cb.Constraints.MinWidth:=w;
  cb.width:=w;
end;
{$else}
function min(a,b: integer):integer;
begin
  exit(IfThen<integer>(a<b,a,b));
end;

function max(a,b: integer):integer;
begin
  exit(IfThen<integer>(a<b,b,a));
end;

procedure AdjustComboboxSize(cb: TComboBox; canvas: TCanvas);
var
  i,w: integer;
  maxwidth: integer=0;
begin
  for i:=0 to cb.Items.Count-1 do maxwidth:=max(maxwidth, canvas.TextWidth(cb.Items[i]));
  w:=maxwidth+30;
  cb.Constraints.MinWidth:=w;
  cb.width:=w;
end;
{$ifend windows}

