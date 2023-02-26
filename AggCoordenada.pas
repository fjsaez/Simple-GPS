unit AggCoordenada;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FMX.Layouts, FMX.Controls.Presentation, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView;

type
  TFrmAggCoord = class(TFrame)
    Query: TFDQuery;
    Layout1: TLayout;
    Layout2: TLayout;
    Layout3: TLayout;
    Layout4: TLayout;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Layout5: TLayout;
    LCoordSex: TLabel;
    LCoordDec: TLabel;
    LCoordUTM: TLabel;
    Memo1: TMemo;
    Button1: TButton;
    Layout6: TLayout;
    Layout7: TLayout;
    Layout8: TLayout;
    Layout9: TLayout;
    ListView1: TListView;
    SBVolverOK: TSpeedButton;
    procedure SBVolverOKClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses DataMod;

{$R *.fmx}

procedure TFrmAggCoord.SBVolverOKClick(Sender: TObject);
begin
  Visible:=false;
end;

end.
