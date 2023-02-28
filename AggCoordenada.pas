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
  TCoords = record
    EsteUTM,NorteUTM,Lat,Lon: single;
    LatGMS,LonGMS,Descripcion: string;
    Fecha: TDate;
  end;
  TFrmAggCoord = class(TFrame)
    Query: TFDQuery;
    QrLista: TFDQuery;
    Layout1: TLayout;
    Layout2: TLayout;
    Layout3: TLayout;
    Layout4: TLayout;
    Layout5: TLayout;
    Layout6: TLayout;
    Layout7: TLayout;
    Layout8: TLayout;
    Layout9: TLayout;
    LCoordSex: TLabel;
    LCoordDec: TLabel;
    LCoordUTM: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Memo1: TMemo;
    Button1: TButton;
    ListView1: TListView;
    SBVolverOK: TSpeedButton;
    procedure SBVolverOKClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses DataMod;

{$R *.fmx}

procedure TFrmAggCoord.Button1Click(Sender: TObject);
begin
  Query.SQL.Text:='insert into Coordenadas (EsteUTM,NorteUTM,Lat,Lon,LatGMS,'+
    'LonGMS,Descripcion,Fecha) values (:esu,:nou,:lat,:lon,:lag,:log,:dsc,:fch)';
  Query.ParamByName(''):=;
  Query.ParamByName(''):=;
  Query.ParamByName(''):=;
  Query.ParamByName(''):=;
  Query.ParamByName(''):=;
  Query.ParamByName(''):=;
  Query.ParamByName(''):=;
  Query.ParamByName(''):=;
  Query.ExecSQL;
end;

procedure TFrmAggCoord.SBVolverOKClick(Sender: TObject);
begin
  Visible:=false;
end;

end.
