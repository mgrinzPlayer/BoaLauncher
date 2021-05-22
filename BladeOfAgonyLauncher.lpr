program BladeOfAgonyLauncher;
{$mode delphi}

uses
  Interfaces, Forms, Unit1, Classes, sysutils;

{$R *.res}

var
  i: integer=1;
begin
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
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

