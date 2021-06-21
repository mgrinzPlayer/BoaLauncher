program BladeOfAgonyLauncher;
{$mode delphi}

uses
  Interfaces, Forms, Unit1, Classes, sysutils, Unit2, LazUTF8, Translations;

{$R *.res}

var
  i: integer=1;
  langid: string='';
begin
  SetCurrentDir(ExtractFilePath(ParamStr(0)));

  userCommands:=TStringList.Create;
  while i<=ParamCount do
  begin
    if (ParamStr(i).Substring(0,18).ToLower='-launcher_mainpath') and (i+1<=ParamCount) then
    // search for launcher command
    begin
      configs_and_saves_path:=ExcludeTrailingPathDelimiter(ParamStr(i+1))+PathDelim;
      inc(i);
    end
    // gather the rest for gzdoom
    else
      userCommands.Add(ParamStr(i));

    inc(i);
  end;

  RequireDerivedFormResource:=True;
  Application.Title:='Blade of Agony Launcher';
  Application.Scaled:=True;
  Application.Initialize;

  LazGetShortLanguageID(langid);
  Translations.TranslateResourceStrings('language'+PathDelim+'Blade of Agony - Launcher.'+langid+'.po');

  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

