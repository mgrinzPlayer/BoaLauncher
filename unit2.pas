unit Unit2;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons;

type

  { TForm2 }

  TForm2 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    Label2: TLabel;
    ListBox1: TListBox;
    ListBox2: TListBox;
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure ListBox2DblClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
  private

  public

  end;

var
  Form2: TForm2;

implementation

resourcestring
  rsMultiselect = 'select multiple addons';
  rsAvailableAddons = 'Available addons:';
  rsLoadOrder = 'Load order:';
  rsApply = 'Apply';
  rsCancel = 'Cancel';

{$R *.lfm}

{ TForm2 }

procedure TForm2.FormCreate(Sender: TObject);
begin
  Caption:='Blade of Agony: '+rsMultiselect;
  Label1.Caption:=rsAvailableAddons;
  Label2.Caption:=rsLoadOrder;
  Button1.Caption:=rsApply;
  Button2.Caption:=rsCancel;

  ListBox1.Sorted:=true;
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
  ModalResult:=mrOK;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

// double clicking will just append an entry
procedure TForm2.ListBox1DblClick(Sender: TObject);
var i:integer;
begin
  if ListBox1.ItemIndex<0 then exit;
  if ListBox2.ItemIndex<0 then
    ListBox2.Items.InsertObject(ListBox2.Items.Count-1,ListBox1.Items[ListBox1.ItemIndex],ListBox1.Items.Objects[ListBox1.ItemIndex])
  else
    ListBox2.Items.InsertObject(ListBox2.ItemIndex,    ListBox1.Items[ListBox1.ItemIndex],ListBox1.Items.Objects[ListBox1.ItemIndex]);
  i:=ListBox1.ItemIndex; if i=ListBox1.Items.Count-1 then Dec(i);
  ListBox1.Items.Delete(ListBox1.ItemIndex);
  ListBox1.ItemIndex:=i;
end;

procedure TForm2.ListBox2DblClick(Sender: TObject);
var i:integer;
begin
  if ListBox2.ItemIndex<0 then exit;
  if ListBox2.ItemIndex=ListBox2.Items.Count-1 then exit; // prevent removing last empty item

  ListBox1.Items.AddObject(ListBox2.Items[ListBox2.ItemIndex],ListBox2.Items.Objects[ListBox2.ItemIndex]);
  i:=ListBox2.ItemIndex;
  ListBox2.Items.Delete(ListBox2.ItemIndex);
  ListBox2.ItemIndex:=i;
end;

// with buttons, we take care of items positions
procedure TForm2.SpeedButton1Click(Sender: TObject);
begin
  ListBox1DblClick(Sender);
end;

procedure TForm2.SpeedButton2Click(Sender: TObject);
begin
  ListBox2DblClick(Sender);
end;

procedure TForm2.SpeedButton3Click(Sender: TObject);
var i:integer;
begin
  if (ListBox2.ItemIndex=0) or (ListBox2.ItemIndex=ListBox2.Items.Count-1) then exit; // do not move first and empty item
  i:=ListBox2.ItemIndex;
  ListBox2.Items.Move(i,i-1);
  ListBox2.ItemIndex:=i-1;
end;

procedure TForm2.SpeedButton4Click(Sender: TObject);
var i:integer;
begin
  if ListBox2.ItemIndex>=ListBox2.Items.Count-2 then exit; // do not move last two items
  i:=ListBox2.ItemIndex;
  ListBox2.Items.Move(i,i+1);
  ListBox2.ItemIndex:=i+1;
end;

end.

