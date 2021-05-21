procedure TForm1.gameExecute;
var
  detail,displacement,devcom,lang: string;
  //filtering: string;
  {$ifndef windows}proc: TProcess;{$ifend windows}
begin

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

  {$ifdef windows}
  case (addonFileName<>'') and chkbLaunchWithAddon.Checked of
    false: ShellExecute(0, 'open', pchar(execName), pchar(Format('-iwad "%s" %s %s %s %s',[ipk3Name,displacement,detail,devcom,lang])), '', sw_show);
    true:  ShellExecute(0, 'open', pchar(execName), pchar(Format('-file "%s" %s %s %s %s',[addonFileName,displacement,detail,devcom,lang])), '', sw_show);
  end;
  {$else}
  proc:=TProcess.Create(nil);
  proc.InheritHandles:=false;
  //proc.Options:=[poNewConsole]; // uncomment when debugging
  proc.Executable:=execName;

  case (addonFileName<>'') and chkbLaunchWithAddon.Checked of
    false: proc.Parameters.Add(Format('-iwad %s',[ipk3Name]));
    true: proc.Parameters.Add(Format('-file %s',[addonFileName]));
  end;

  if displacement<>'' then proc.Parameters.Add(displacement);
  if detail<>'' then proc.Parameters.Add(detail);
  if devcom<>'' then proc.Parameters.Add(devcom);
  if lang<>'' then proc.Parameters.Add(lang);

  writeln(ExtractFileName(ParamStr(0))+' parameters:');
  writeln(proc.Parameters.Text);

  proc.Execute;
  {$ifend windows}
end;
