procedure TForm1.saveSettings;
var
  inifile:TIniFile;
begin
  inifile:=TIniFile.Create('boa-launcher.ini');
  inifile.WriteBool('Launcher','DevCommentary',chkbDeveloperCommentary.Checked);
  inifile.WriteInteger('Launcher','DisplacementTextures',cbDisplacementTextures.ItemIndex);

  if chkbLaunchWithAddon.Checked then
  begin
    inifile.WriteBool('Launcher','LaunchWithAddon',true);
    inifile.WriteString('Launcher','addonTitle',addonTitle);
    inifile.WriteString('Launcher','addonFileName',addonFileName);
  end
  else
    inifile.WriteBool('Launcher','LaunchWithAddon',false);

  inifile.UpdateFile;
  inifile.Free;
end;

procedure TForm1.loadSettings;
var
  inifile:TIniFile;
begin
  inifile:=TIniFile.Create('boa-launcher.ini');
  chkbDeveloperCommentary.Checked:=inifile.ReadBool('Launcher','DevCommentary',false);
  cbDisplacementTextures.ItemIndex:=inifile.ReadInteger('Launcher','DisplacementTextures',0);

  addonTitle:=inifile.ReadString('Launcher','addonTitle','');
  addonFileName:=inifile.ReadString('Launcher','addonFileName','');
  chkbLaunchWithAddon.Checked:=inifile.ReadBool('Launcher','LaunchWithAddon',false);

  if (addonTitle<>'') and (addonFileName<>'') then
  begin
    lblActiveAddon.Caption:='Currently selected addon: "'+addonTitle+'"';
    chkbLaunchWithAddon.Visible:=true;
  end
  else
    chkbLaunchWithAddon.Checked:=false;

  inifile.Free;
end;
