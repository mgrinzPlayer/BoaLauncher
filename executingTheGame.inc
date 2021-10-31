procedure TForm1.gameExecute;
var
  proc: TProcess;
  IWAD: string='';
  LOAD: string='';
  s: string;
  procedure addParam(s: array of string);
  var i: integer;
  begin
    for i:=0 to Length(s)-1 do proc.Parameters.Add(s[i]);
  end;
begin
  proc:=TProcess.Create(nil);
  proc.InheritHandles:=false;
  proc.Executable:=execName;

  {$ifndef windows}
  addParam(['-config',configs_and_saves_path+'gzdoom.ini']);
  addParam(['-savedir',configs_and_saves_path+'Save']);
  addParam(['-screenshot_dir',configs_and_saves_path+'Screenshots']);
  addParam(['-shotdir',configs_and_saves_path+'Screenshots']);
  {$ifend}

  addParam(['-iwad',ipk3Name]);

  if (addonFileName<>'') and chkbLaunchWithAddon.Checked then
  begin
   addParam(['-file']);
   if pos(':',addonFileName)>0 then
     for s in addonFileName.Split([':']) do
     begin
       get_gameinfo_LOAD(s,IWAD,LOAD);
       addParam(LOAD);
     end
   else
     addParam(addonFileName);
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

  if chkbCoop.Checked then
  begin
    if cbCoopPlayers.ItemIndex=0 then addParam([   '-join',edtCoopJoinHostIP.Text   ])
    else
    begin
      addParam([   '-host',IntToStr(cbCoopPlayers.ItemIndex)   ]);
      addParam([   '-port',edtCoopPort.Text   ]);
      addParam([   '+map',cbCoopStartMap.Text   ]);
    end;
  end;

  //append user commands
  proc.Parameters.AddStrings(userCommands);

  {$ifndef windows}
  writeln(ExtractFileName(ParamStr(0))+' parameters:');
  writeln(proc.Parameters.Text.Replace(LineEnding,' ').Replace(' -',LineEnding+'-').Replace(' +',LineEnding+'+'));
  {$ifend windows}

  if FileExists('boa.cmd') then proc.Executable:='boa.cmd'; // remove this line later

  proc.Execute;
end;
