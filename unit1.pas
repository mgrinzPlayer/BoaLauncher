unit Unit1;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, Zipper, windows, IniFiles;

type

  { TForm1 }

  TForm1 = class(TForm)

    btnStart: TButton;
    btnExit: TButton;

    chkbDeveloperCommentary: TCheckBox;

    lblDetailPreset: TLabel;
    cbDetailPreset: TComboBox;
    lblDisplacementTextures: TLabel;
    cbDisplacementTextures: TComboBox;
    lblTextureFiltering: TLabel;
    cbTextureFiltering: TComboBox;
    lblLanguage: TLabel;
    cbLanguage: TComboBox;

    Image1: TImage;

    procedure btnExitClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    LanguageList: array of string;
    DecompressedFile: TStringList;
    procedure ZipOnCreateStreamProc(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
    procedure ZipOnDoneStreamProc(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
    procedure examineIPK3file;
    procedure saveSettings;
  public

  end;

var
  Form1: TForm1;

implementation

uses StrUtils;

{$R *.lfm}

function findFileInsideArchive(zip: TUnZipper; what: string):integer;
var i: integer;
begin
  for i:=0 to zip.Entries.Count-1 do
    if zip.Entries.Entries[i].ArchiveFileName=what then exit(i);
  result:=-1;
end;

procedure TForm1.ZipOnCreateStreamProc(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  AStream:=TMemorystream.Create;
end;

procedure TForm1.ZipOnDoneStreamProc(Sender: TObject; var AStream: TStream; AItem: TFullZipFileEntry);
begin
  AStream.Position:=0;
  DecompressedFile.LoadFromStream(AStream);
  Astream.Free;
end;

procedure TForm1.examineIPK3file;
var
  zip: TUnZipper;
  i,j,a,b,c,d,z: integer;
  s: string;
  sl: TStringList;
  brackets: integer;
begin
  if not FileExists('boa.ipk3') then exit;

  // finding languages
  // menudef.txt has OptionString "BoALanguageOptions" {"it", "Italiano (Italian)"\n"pl", "Polski (Polish)"}
  zip := TUnZipper.Create;
  zip.FileName := 'boa.ipk3';
  zip.Examine;
  i:=findFileInsideArchive(zip,'menudef.txt');
  if i=-1 then exit;

  DecompressedFile:=TStringList.Create;
  sl:=TStringList.Create;
  sl.Add('menudef.txt');
  zip.OnCreateStream:=ZipOnCreateStreamProc;
  zip.OnDoneStream:=ZipOnDoneStreamProc;
  zip.UnZipFiles(sl);
  zip.Free;

  brackets:=0;
  for i:=0 to DecompressedFile.Count-1 do
  begin
    s:=DecompressedFile.Strings[i].Trim().ToLower;
    if s.StartsWith('optionstring "boalanguageoptions"') then
    begin
      s:=DecompressedFile.Strings[i+1].Trim();
      inc(brackets,s.CountChar('{'));dec(brackets,s.CountChar('}'));
      if brackets=0 then break;

      cbLanguage.Clear;
      cbLanguage.AddItem('Use last setting',nil);
      cbLanguage.ItemIndex:=0;

      for j:=i+2 to DecompressedFile.Count-1 do
      begin
        s:=DecompressedFile.Strings[j].Trim();
        if s.StartsWith('//') then continue;

        inc(brackets,s.CountChar('{'));dec(brackets,s.CountChar('}'));
        if brackets=0 then break;

        a:=Pos('"',s);
        b:=PosEx('"',s,a+1);
        c:=PosEx('"',s,b+1);
        d:=PosEx('"',s,c+1);

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

procedure TForm1.saveSettings;
var
  inifile:TIniFile;
begin
  inifile:=TIniFile.Create('boa-launcher.ini');
  inifile.WriteBool('Launcher','DevCommentary',chkbDeveloperCommentary.Checked);
  inifile.WriteInteger('Launcher','DisplacementTextures',cbDisplacementTextures.ItemIndex);
  inifile.UpdateFile;
  inifile.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  inifile:TIniFile;
begin
  inifile:=TIniFile.Create('boa-launcher.ini');
  chkbDeveloperCommentary.Checked:=inifile.ReadBool('Launcher','DevCommentary',false);
  cbDisplacementTextures.ItemIndex:=inifile.ReadInteger('Launcher','DisplacementTextures',0);
  inifile.Free;
  examineIPK3file;
end;

procedure TForm1.btnExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.btnStartClick(Sender: TObject);
var
  execName,ipk3Name,detail,displacement,filtering,devcom,lang,commandLineParam: string;
begin
  execName:='boa.exe:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';
  execName:=copy(execName,1,pos(':',execName)-1);

  ipk3Name:='boa.ipk3:PADDINGPADDINGPADDINGPADDINGFORYOURHEXEDITMODIFICATIONS';
  ipk3Name:=copy(ipk3Name,1,pos(':',ipk3Name)-1);

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

  case cbTextureFiltering.ItemIndex of
    0: filtering:='';                     //unchanged
    1: filtering:='+exec launcher-resource/texfilt-none.cfg';
    2: filtering:='+exec launcher-resource/texfilt-tri.cfg';
    3: filtering:='+exec launcher-resource/texfilt-nnx.cfg';
  end;

  case chkbDeveloperCommentary.Checked of
    false: devcom:='+set boa_devcomswitch 0';
    true: devcom:='+set boa_devcomswitch 1';
  end;

  if cbLanguage.ItemIndex=0 then lang:=''
                            else lang:='+set language '+LanguageList[cbLanguage.ItemIndex-1];

  commandLineParam:=Format('-iwad "%s" %s %s %s %s %s',[ipk3Name,displacement,detail,filtering,devcom,lang]);

  ShellExecute(0, 'open', pchar(execName), pchar(commandLineParam), '', sw_show);

  saveSettings;

  Application.Terminate;

end;

end.

