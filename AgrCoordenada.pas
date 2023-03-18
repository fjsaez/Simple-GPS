unit AgrCoordenada;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.ListView.Types, FMX.ListView,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FMX.Objects, FMX.ListBox;

type
  TCoord = record
    IDCoord: Cardinal;
    EsteUTM,NorteUTM,Lat,Lon: single;
    LatGMS,LonGMS,Descripcion: string;
    Fecha: TDate;
  end;
  TFrmAgrCoord = class(TFrame)
    LCoordUTM: TLabel;
    LTit3: TLabel;
    LCoordDec: TLabel;
    LTit2: TLabel;
    LCoordSex: TLabel;
    LTit1: TLabel;
    Layout6: TLayout;
    Layout7: TLayout;
    SBVolver: TSpeedButton;
    MemoDescr: TMemo;
    BGuardar: TButton;
    Query: TFDQuery;
    QrLista: TFDQuery;
    Rectangle1: TRectangle;
    Rectangle2: TRectangle;
    LTotPtos: TLabel;
    LstVw: TListView;
    procedure SBVolverClick(Sender: TObject);
    procedure BGuardarClick(Sender: TObject);
    procedure MemoDescrChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Coord: TCoord;
    procedure ValInicio;
  end;

implementation

{$R *.fmx}

procedure TFrmAgrCoord.ValInicio;
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

procedure TFrmAgrCoord.BGuardarClick(Sender: TObject);
begin
  Coord.Descripcion:=Trim(MemoDescr.Text);
  Coord.Fecha:=Now;
  {Query.SQL.Text:='insert into Coordenadas (EsteUTM,NorteUTM,Lat,Lon,LatGMS,'+
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
  QrLista.Refresh;}
  ValInicio;
  MemoDescr.Text:='';
  ShowMessage('Coordenada agregada');
end;

procedure TFrmAgrCoord.MemoDescrChange(Sender: TObject);
begin
  BGuardar.Enabled:=Trim(MemoDescr.Text)<>'';
end;

procedure TFrmAgrCoord.SBVolverClick(Sender: TObject);
begin
  Visible:=false;
end;

end.
