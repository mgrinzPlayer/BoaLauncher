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

procedure parseAddonInfoTXT(SL: TStringList; var title,description,requirements: string; var previewImages: integer);
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
