procedure TForm1.saveSettings;
var
  inifile:TIniFile;
begin
  inifile:=TIniFile.Create(configs_and_saves_path+'boa-launcher.ini');
  inifile.WriteBool('Launcher','DevCommentary',chkbDeveloperCommentary.Checked);
  inifile.WriteInteger('Launcher','DisplacementTextures',cbDisplacementTextures.ItemIndex);

  inifile.WriteBool('Launcher co-op','Enabled',chkbCoop.Checked);
  inifile.WriteInteger('Launcher co-op','Players',cbCoopPlayers.ItemIndex);
  inifile.WriteString('Launcher co-op','StartMap',cbCoopStartMap.Text);
  inifile.WriteString('Launcher co-op','Hostname/IP',edtCoopJoinHostIP.Text);
  inifile.WriteString('Launcher co-op','Port',edtCoopPort.Text);

  if chkbLaunchWithAddon.Checked then
  begin
    inifile.WriteBool('Addon','LaunchWithAddon',true);
    inifile.WriteString('Addon','addonTitle',addonTitle);
    inifile.WriteString('Addon','addonFileName',addonFileName);
  end
  else
    inifile.WriteBool('Addon','LaunchWithAddon',false);

  inifile.UpdateFile;
  inifile.Free;
end;

procedure TForm1.loadSettings;
var
  inifile:TIniFile;
begin
  inifile:=TIniFile.Create(configs_and_saves_path+'boa-launcher.ini');
  chkbDeveloperCommentary.Checked:=inifile.ReadBool('Launcher','DevCommentary',false);
  cbDisplacementTextures.ItemIndex:=inifile.ReadInteger('Launcher','DisplacementTextures',0);

  chkbCoop.Checked:=inifile.ReadBool('Launcher co-op','Enabled',false);
  cbCoopPlayers.ItemIndex:=inifile.ReadInteger('Launcher co-op','Players',0);
  cbCoopStartMap.Text:=inifile.ReadString('Launcher co-op','StartMap','INTROMAP');
  edtCoopJoinHostIP.Text:=inifile.ReadString('Launcher co-op','Hostname/IP','127.0.0.1');
  edtCoopPort.Text:=inifile.ReadString('Launcher co-op','Port','5029');
  CoopChange(chkbCoop);

  addonTitle:=inifile.ReadString('Addon','addonTitle','');
  addonFileName:=inifile.ReadString('Addon','addonFileName','');
  chkbLaunchWithAddon.Checked:=inifile.ReadBool('Addon','LaunchWithAddon',false);

  if (addonTitle<>'') and (addonFileName<>'') then
  begin
    if addonTitle[1]<>'"' then
      lblActiveAddon.Caption:='"'+addonTitle+'"'
    else
      lblActiveAddon.Caption:=addonTitle;
  end
  else
  begin
    chkbLaunchWithAddon.Checked:=false;
    chkbLaunchWithAddonVisibilityChange(false);
  end;

  inifile.Free;
end;
