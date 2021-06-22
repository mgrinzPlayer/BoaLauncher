program BladeOfAgonyLauncher;
{$mode delphi}

uses
  Interfaces, Forms, Unit1, Classes, sysutils, Unit2, LazUTF8, Translations;

{$R *.res}

var
  i: integer=1;
begin
  SetCurrentDir(ExtractFilePath(ParamStr(0)));

  userCommands:=TStringList.Create;
  while i<=ParamCount do
  begin
    if (ParamStr(i).Substring(0,18).ToLower='-launcher_mainpath') and (i+1<=ParamCount) then
    // search for launcher command mainpath
    begin
      configs_and_saves_path:=ExcludeTrailingPathDelimiter(ParamStr(i+1))+PathDelim;
      inc(i);
    end
    else if (ParamStr(i).Substring(0,14).ToLower='-launcher_lang') and (i+1<=ParamCount) then
    // search for launcher command lang
    begin
      langid:=ParamStr(i+1);
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

  if langid='' then LazGetShortLanguageID(langid);
  Translations.TranslateResourceStrings('language'+PathDelim+'Blade of Agony - Launcher.'+langid+'.po');

  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

