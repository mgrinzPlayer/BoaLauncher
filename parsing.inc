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
  lang: string;
begin
  if langid<>'en' then lang:='_'+langid.ToLower else lang:='';

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

      // other languages
      if key='title'+lang then title:=value;
      if key='creditsfull'+lang then creditsFull:=value;
      if key='description'+lang then description:=value;
      if key='requirements'+lang then requirements:=value;
    end;
  end;
end;

function isDefaultBoAPlayer(pk3file: string): boolean;
var
  i,a: integer;
  mapInfoTXT: TStringList=nil;
  s,key,value: string;
begin
  result:=true;
  if Form1.ExtractSingleFileToStringList(pk3file.Replace('"',''), 'mapinfo.txt', mapInfoTXT) then
  begin
    for i:=0 to mapInfoTXT.Count-1 do
    begin
      s:=trimComment(mapInfoTXT.Strings[i]);
      if s='' then continue;
      a:=Pos('=',s);
      if (a>0) then
      begin
        key:=copy(s,1,a-1); key:=key.Trim().ToLower;
        value:=s.Substring(a).Replace('"','').Trim().ToLower;
        if (key='playerclasses') and (value<>'boaplayer') then begin result:=false; break; end;
      end;
    end;
  end;
  if mapInfoTXT<>nil then FreeAndNil(mapInfoTXT);
end;

procedure get_gameinfo_LOAD(boaFile: string; var IWAD: string; var LOAD: TStringArray);
var
  i,a: integer;
  gameInfoTXT: TStringList=nil;
  s,key,value, LOADstr: string;
begin
  IWAD:='';
  LOADstr:='';

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
        if key='load' then LOADstr:=value;
      end;
    end;

    {$ifdef windows}
    LOADstr:=LOADstr.Replace('/','\');
    {$ifend windows}

    LOAD:=LOADstr.Split([',',' '], TStringSplitOptions.ExcludeEmpty);
  end;
  if gameInfoTXT<>nil then FreeAndNil(gameInfoTXT);
end;

procedure scanAllBoaFiles(var AddonList: dotBoAFileArray; checkForDefaultBoAPlayer:boolean=false);
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

  IWAD: string='';
  LOAD: TStringArray=[];
  s: string;
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
    AddonList[i].DefaultBoAPlayer:=true;

    //addon addoninfo.txt
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

    //addon gameinfo.txt (checking for different playerclasses)
    if checkForDefaultBoAPlayer then
    begin
      get_gameinfo_LOAD(fileList[i], IWAD, LOAD);
      for s in LOAD do
        if isDefaultBoAPlayer(s)=false then
        begin
          AddonList[i].DefaultBoAPlayer:=false;
          break;
        end;
    end;

  end;

  if fileList<>nil then FreeAndNil(fileList);
  if addonInfoTXT<>nil then FreeAndNil(addonInfoTXT);
end;












