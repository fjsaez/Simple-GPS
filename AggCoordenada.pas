unit AggCoordenada;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.DApt.Intf,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FMX.Controls.Presentation,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Data.DB, FMX.Layouts, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  System.Rtti, System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Data.Bind.Components, Data.Bind.DBScope;

type
  TCoord = record
    IDCoord: Cardinal;
    EsteUTM,NorteUTM,Lat,Lon: single;
    LatGMS,LonGMS,Descripcion: string;
    Fecha: TDate;
  end;
  TFrmAggCoord = class(TFrame)
    Query: TFDQuery;
    QrLista: TFDQuery;
    Layout3: TLayout;
    Layout4: TLayout;
    Layout6: TLayout;
    Layout7: TLayout;
    Layout8: TLayout;
    Layout9: TLayout;
    MmDescr: TMemo;
    BGuardar: TButton;
    ListView: TListView;
    SBVolverOK: TSpeedButton;
    Layout2: TLayout;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    LCoordUTM: TLabel;
    LCoordDec: TLabel;
    LCoordSex: TLabel;
    procedure SBVolverOKClick(Sender: TObject);
    procedure BGuardarClick(Sender: TObject);
    procedure ListViewItemClick(const Sender: TObject;
      const AItem: TListViewItem);
  private
    { Private declarations }
  public
    { Public declarations }
    Coord: TCoord;
    procedure ValInicio;
  end;

implementation

uses DataMod;

{$R *.fmx}

procedure TFrmAggCoord.ValInicio;
begin
  Coord.IDCoord:=0;
  Coord.EsteUTM:=0.0;
  Coord.NorteUTM:=0.0;
  Coord.Lat:=0.0;
  Coord.Lon:=0.0;
  Coord.LatGMS:='';
  Coord.LonGMS:='';
  Coord.Descripcion:='';
  Coord.Fecha:=Now;
end;

procedure TFrmAggCoord.BGuardarClick(Sender: TObject);
begin
  Query.SQL.Text:='insert into Coordenadas (EsteUTM,NorteUTM,Lat,Lon,LatGMS,'+
    'LonGMS,Descripcion,Fecha) values (:esu,:nou,:lat,:lon,:lag,:log,:dsc,:fch)';
  Query.ParamByName('esu').AsSingle:=Coord.EsteUTM;
  Query.ParamByName('nou').AsSingle:=Coord.NorteUTM;
  Query.ParamByName('lat').AsSingle:=Coord.Lat;
  Query.ParamByName('lon').AsSingle:=Coord.Lon;
  Query.ParamByName('lag').AsString:=Coord.LatGMS;
  Query.ParamByName('log').AsString:=Coord.LonGMS;
  Query.ParamByName('dsc').AsString:=Coord.Descripcion;
  Query.ParamByName('fch').AsDate:=Coord.Fecha;
  Query.ExecSQL;
  ValInicio;
  ShowMessage('Coordenada agregada');
end;

procedure TFrmAggCoord.ListViewItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  BGuardar.Text:='Eliminar';
end;

procedure TFrmAggCoord.SBVolverOKClick(Sender: TObject);
begin
  ValInicio;
  Visible:=false;
end;

end.
