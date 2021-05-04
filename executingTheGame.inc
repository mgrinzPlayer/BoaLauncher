procedure TForm1.gameExecute;
var
  detail,displacement,devcom,lang,commandLineParam: string;
  //filtering: string;
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

  case (addonFileName<>'') and chkbLaunchWithAddon.Checked of
    false: commandLineParam:=Format('-iwad "%s" %s %s %s %s',[ipk3Name,displacement,detail,devcom,lang]);
    true: commandLineParam:=Format('-file "%s" %s %s %s %s',[addonFileName,displacement,detail,devcom,lang]);
  end;

  ShellExecute(0, 'open', pchar(execName), pchar(commandLineParam), '', sw_show);
end;
