unit AgrCoordenada;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.ListView.Types, FMX.ListView,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.Memo.Types, Data.DB,
  FMX.ScrollBox, FMX.Memo, FireDAC.Stan.Intf, FireDAC.Stan.Option, FMX.Grid,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FMX.Objects, FMX.ListBox, System.Rtti, Fmx.Bind.Editors,
  Data.Bind.EngExt,System.Bindings.Outputs, Fmx.Bind.DBEngExt,
  Data.Bind.Components, Data.Bind.DBScope, FMX.Grid.Style, System.Actions,
  FMX.ActnList, FMX.StdActns, FMX.MediaLibrary.Actions, System.ImageList,
  FMX.ImgList;

type
  TCoord = record
    IDCoord: Cardinal;
    EsteUTM,NorteUTM,Lat,Lon: single;
    LatGMS,LonGMS,LatLon,Descripcion: string;
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
    SGrid: TStringGrid;
    ColDescr: TStringColumn;
    ColID: TIntegerColumn;
    ColGeoSex: TStringColumn;
    ColGeoDec: TStringColumn;
    ColUTM: TStringColumn;
    ActionList: TActionList;
    ShowShareSheetAction1: TShowShareSheetAction;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    Rectangle3: TRectangle;
    SpeedButton1: TSpeedButton;
    Image1: TImage;
    SpeedButton2: TSpeedButton;
    ImageList: TImageList;
    procedure SBVolverClick(Sender: TObject);
    procedure BGuardarClick(Sender: TObject);
    procedure MemoDescrChange(Sender: TObject);
    procedure SGridCellClick(const Column: TColumn; const Row: Integer);
    procedure ShowShareSheetAction1BeforeExecute(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Coord: TCoord;
    IDCoord: integer;
    procedure ValInicio;
    procedure CargarLista;
    procedure Guardar;
    procedure Eliminar(ID: integer);
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
  Coord.LatLon:='';
  Coord.Descripcion:='';
  Coord.Fecha:=Now;
  LCoordSex.Text:='';
  LCoordDec.Text:='';
  LCoordUTM.Text:='';
  MemoDescr.Text:='';
end;

procedure TFrmAgrCoord.CargarLista;
var
  Ind: word;
begin
  SGrid.BeginUpdate;
  QrLista.Open;
  QrLista.Refresh;
  LTotPtos.Text:='Total puntos: '+QrLista.RecordCount.ToString;
  QrLista.First;
  Ind:=0;
  SGrid.RowCount:=0;
  while not QrLista.Eof do
  begin
    SGrid.RowCount:=SGrid.RowCount+1;
    SGrid.Cells[0,Ind]:=QrLista.FieldByName('Descripcion').AsString;
    SGrid.Cells[1,Ind]:=QrLista.FieldByName('IDCoord').AsString;
    SGrid.Cells[2,Ind]:=QrLista.FieldByName('LonGMS').AsString+', '+
                        QrLista.FieldByName('LatGMS').AsString;
    SGrid.Cells[3,Ind]:=QrLista.FieldByName('LatLon').AsString;
    SGrid.Cells[4,Ind]:=FormatFloat('#0.00',QrLista.FieldByName('EsteUTM').AsFloat)+
              ', '+FormatFloat('#0.00',QrLista.FieldByName('NorteUTM').AsFloat);
    Inc(Ind);
    QrLista.Next;
  end;
  SGrid.EndUpdate;
end;

procedure TFrmAgrCoord.Eliminar(ID: integer);
begin
  Query.SQL.Text:='delete from Coordenadas where IDCoord=:idc';
  Query.ParamByName('idc').AsInteger:=ID;
  Query.ExecSQL;
  ShowMessage('Coordenada eliminada');
  CargarLista;
end;

procedure TFrmAgrCoord.Guardar;
begin
  Coord.Descripcion:=Trim(MemoDescr.Text);
  Coord.Fecha:=Now;
  Query.SQL.Text:='insert into Coordenadas (EsteUTM,NorteUTM,Lat,Lon,LatGMS,'+
    'LonGMS,LatLon,Descripcion,Fecha) values (:esu,:nou,:lat,:lon,:lag,:log,'+
    ':lln,:dsc,:fch)';
  Query.ParamByName('esu').AsSingle:=Coord.EsteUTM;
  Query.ParamByName('nou').AsSingle:=Coord.NorteUTM;
  Query.ParamByName('lat').AsSingle:=Coord.Lat;
  Query.ParamByName('lon').AsSingle:=Coord.Lon;
  Query.ParamByName('lag').AsString:=Coord.LatGMS;
  Query.ParamByName('log').AsString:=Coord.LonGMS;
  Query.ParamByName('lln').AsString:=Coord.LatLon;
  Query.ParamByName('dsc').AsString:=Coord.Descripcion;
  Query.ParamByName('fch').AsDate:=Coord.Fecha;
  Query.ExecSQL;
  QrLista.Close;
  ShowMessage('Coordenada agregada');
  SBVolver.OnClick(Self);
end;

procedure TFrmAgrCoord.BGuardarClick(Sender: TObject);
begin
  if BGuardar.Text='Guardar' then Guardar
                             else Eliminar(IDCoord);
  ValInicio;
end;

procedure TFrmAgrCoord.MemoDescrChange(Sender: TObject);
begin
  BGuardar.Enabled:=Trim(MemoDescr.Text)<>'';
end;

procedure TFrmAgrCoord.SBVolverClick(Sender: TObject);
begin
  Visible:=false;
end;

procedure TFrmAgrCoord.SGridCellClick(const Column: TColumn;
  const Row: Integer);
begin
  MemoDescr.ReadOnly:=true;
  MemoDescr.Text:=SGrid.Cells[0,Row];
  LCoordSex.Text:=SGrid.Cells[2,Row];
  LCoordDec.Text:=SGrid.Cells[3,Row];
  LCoordUTM.Text:=SGrid.Cells[4,Row];
  IDCoord:=SGrid.Cells[1,Row].ToInteger;
  BGuardar.Text:='Quitar';
end;

procedure TFrmAgrCoord.ShowShareSheetAction1BeforeExecute(Sender: TObject);
begin
  ShowShareSheetAction1.Text:='Coord: '+Coord.LatLon+'; Descripción: '+
                              Coord.Descripcion;
  //showmessage('prueba');
end;

procedure TFrmAgrCoord.SpeedButton2Click(Sender: TObject);
begin
  showmessage('prb');
end;

end.
