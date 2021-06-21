procedure TForm1.findSupportedLanguages;
var
  i,j,a,b,c,d,z: integer;
  s: string;
  brackets: integer;
  menudef_txt_SL: TStringList=nil;
begin
  // finding languages
  // menudef.txt has OptionString "BoALanguageOptions" {"it", "Italiano (Italian)"\n"pl", "Polski (Polish)"}

  if not FileExists(ipk3Name) then exit;
  if not ExtractSingleFileToStringList(ipk3Name, 'menudef.txt', menudef_txt_SL) then exit;

  brackets:=0;
  for i:=0 to menudef_txt_SL.Count-1 do
  begin
    s:=menudef_txt_SL.Strings[i].Trim().ToLower;
    if s.StartsWith('optionstring "boalanguageoptions"') then
    begin
      s:=trimComment(menudef_txt_SL.Strings[i+1]);
      inc(brackets,s.CountChar('{'));dec(brackets,s.CountChar('}'));
      if brackets=0 then break;

      for j:=i+2 to menudef_txt_SL.Count-1 do
      begin
        s:=trimComment(menudef_txt_SL.Strings[j]);
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
          cbLanguage.Items.Add(copy(s,c+1,d-c-1));
        end;
      end;

      break;
    end;
  end;
end;

procedure parseAddonInfoTXT(SL: TStringList; var title,credits,creditsFull,description,requirements: string; var previewImages: integer);
var
  s,key,value: string;
  i,a: integer;
begin

  //mandatory
  title:='missing title';
  credits:='missing credits';
  description:='missing description';
  requirements:='missing requirements';

  //optional
  creditsFull:='';
  previewImages:=0;

  for i:=0 to SL.Count-1 do
  begin
    s:=trimComment(SL.Strings[i]);
    if s='' then continue;
    a:=Pos('=',s);
    if (a>0) then
    begin
      key:=copy(s,1,a-1); key:=key.Trim().ToLower;
      value:=s.Substring(a).Trim();
      if key='title' then title:=value;
      if key='credits' then credits:=value;
      if key='creditsfull' then creditsFull:=value;
      if key='description' then description:=value;
      if key='requirements' then requirements:=value;
      if key='previewimages' then previewImages:=StrToInt(value);
    end;
  end;
end;

procedure scanAllBoaFiles(var AddonList: dotBoAFileArray);
var
  searchRec: TSearchRec;
  i,r: integer;
  fileList: TStringList=nil;
  addonInfoTXT: TStringList=nil;

  title: string='';
  credits: string='';
  creditsFull: string='';
  description: string='';
  requirements: string='';
  imageCount: integer=0;
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

  for i:=0 to fileList.Count-1 do
  begin
    AddonList[i].FileName:=ExtractFileName(fileList[i]);
    if Form1.ExtractSingleFileToStringList(fileList[i], 'addoninfo.txt', addonInfoTXT) then
    begin
      parseAddonInfoTXT(addonInfoTXT,title,credits,creditsFull,description,requirements,imageCount);
      AddonList[i].Title:=title;
      AddonList[i].Credits:=credits;
      AddonList[i].CreditsFull:=creditsFull;
      AddonList[i].Description:=description;
      AddonList[i].Requirements:=requirements;
      AddonList[i].PrevievImageCount:=imageCount;
      AddonList[i].hasAddonInfoTXT:=true;
    end
    else
    begin
      AddonList[i].Title:=AddonList[i].FileName;
      AddonList[i].Credits:='';
      AddonList[i].CreditsFull:='';
      AddonList[i].Description:='';
      AddonList[i].Requirements:='';
      AddonList[i].PrevievImageCount:=0;
      AddonList[i].hasAddonInfoTXT:=false;
    end;
  end;

  if fileList<>nil then FreeAndNil(fileList);
  if addonInfoTXT<>nil then FreeAndNil(addonInfoTXT);
end;

procedure get_gameinfo_LOAD(boaFile: string; var IWAD, LOAD: string);
var
  i,a: integer;
  gameInfoTXT: TStringList=nil;
  s,key,value: string;
  sa: TStringArray;
begin
  IWAD:='';
  LOAD:='';

  if Form1.ExtractSingleFileToStringList(boaFile, 'gameinfo.txt', gameInfoTXT) then
  begin
    for i:=0 to gameInfoTXT.Count-1 do
    begin
      s:=trimComment(gameInfoTXT.Strings[i]);
      if s='' then continue;
      a:=Pos('=',s);
      if (a>0) then
      begin
        key:=copy(s,1,a-1); key:=key.Trim().ToLower;
        value:=s.Substring(a).Trim();
        if key='iwad' then IWAD:=value;
        if key='load' then LOAD:=value;
      end;
    end;

    if LOAD<>'' then
    begin
      sa:=LOAD.Split(',');
      LOAD:=sa[0].Trim();
      for i:=1 to Length(sa)-1 do
        LOAD:=LOAD+' '+sa[i].Trim();
    end;
  end;

  if gameInfoTXT<>nil then FreeAndNil(gameInfoTXT);
end;






