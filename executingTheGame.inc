procedure TForm1.gameExecute;
var
  {$ifdef windows}
  params: string='';
  procedure addParam(s: array of string);
  var i: integer;
  begin
    for i:=0 to Length(s)-1 do params:=Format('%s %s',[params,s[i]]);
  end;
  {$else}
  proc: TProcess;
  procedure addParam(s: array of string);
  var i: integer;
  begin
    for i:=0 to Length(s)-1 do proc.Parameters.Add(s[i]);
  end;
  {$ifend windows}
begin

  {$ifndef windows}
  proc:=TProcess.Create(nil);
  proc.InheritHandles:=false;
  proc.Executable:=execName;
  {$ifend}

  addParam(['-config',configs_and_saves_path+'gzdoom.ini']);
  addParam(['-savedir',configs_and_saves_path+'Save']);
  addParam(['-screenshot_dir',configs_and_saves_path+'Screenshots']);
  addParam(['-shotdir',configs_and_saves_path+'Screenshots']);

  case (addonFileName<>'') and chkbLaunchWithAddon.Checked of
    false: addParam(['-iwad',ipk3Name]);
    true:  addParam(['-file',addonFileName]);
  end;

  if cbDisplacementTextures.ItemIndex=1 then addParam(['-file','boa_dt.pk3']);

  case cbDetailPreset.ItemIndex of
    1: addParam(['+exec','launcher-resource/detail-default.cfg']);
    2: addParam(['+exec','launcher-resource/detail-verylow.cfg']);
    3: addParam(['+exec','launcher-resource/detail-low.cfg']);
    4: addParam(['+exec','launcher-resource/detail-normal.cfg']);
    5: addParam(['+exec','launcher-resource/detail-high.cfg']);
    6: addParam(['+exec','launcher-resource/detail-veryhigh.cfg']);
  end;

  {
  case cbTextureFiltering.ItemIndex of
    1: addParam(['+exec','launcher-resource/texfilt-none.cfg']);
    2: addParam(['+exec','launcher-resource/texfilt-tri.cfg']);
    3: addParam(['+exec','launcher-resource/texfilt-nnx.cfg']);
  end;
  }

  case chkbDeveloperCommentary.Checked of
    false: addParam(['+set','boa_devcomswitch','0']);
    true:  addParam(['+set','boa_devcomswitch','1']);
  end;

  if cbLanguage.ItemIndex<>0 then addParam([   '+set','language',LanguageList[cbLanguage.ItemIndex-1]   ]);

  addParam(userCommands.ToStringArray);

  {$ifdef windows}
  ShellExecute(0, 'open', pchar(execName), pchar(params), '', sw_show);
  {$else}
  //append user commands
  proc.Parameters.AddStrings(userCommands);

  writeln(ExtractFileName(ParamStr(0))+' parameters:');
  writeln(proc.Parameters.Text.Replace(LineEnding,' ').Replace(' -',LineEnding+'-').Replace(' +',LineEnding+'+'));
  proc.Execute;
  {$ifend windows}
end;
