unit Principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Sensors, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Platform.Android,
  System.Sensors.Components, FMX.Objects, UTM_WGS84, Androidapi.JNI.Location,
  FMX.FontGlyphs.Android, AgrCoordenada;

type
  TFPrinc = class(TForm)
    LayFlecha: TLayout;
    CrcKingOTN: TCircle;
    LayBot: TLayout;
    SpeedButton1: TSpeedButton;
    StyleBook: TStyleBook;
    VertScrollBox1: TVertScrollBox;
    LayMap: TLayout;
    Layout4: TLayout;
    LayLat: TLayout;
    Label2: TLabel;
    LLat: TLabel;
    LayLon: TLayout;
    Label3: TLabel;
    LLon: TLabel;
    LayEste: TLayout;
    Label4: TLabel;
    LEste: TLabel;
    LayNorte: TLayout;
    Label6: TLabel;
    LNorte: TLabel;
    LayMsgGeo: TLayout;
    Label5: TLabel;
    LayMsgUTM: TLayout;
    Label7: TLabel;
    LctSensor: TLocationSensor;
    SpeedButton2: TSpeedButton;
    LayLED: TLayout;
    SwitchGPS: TSwitch;
    LActivar: TLabel;
    Rectangle1: TRectangle;
    RectActivar: TRectangle;
    Rectangle3: TRectangle;
    Rectangle4: TRectangle;
    Layout1: TLayout;
    Layout2: TLayout;
    LRumbo: TLabel;
    Label1: TLabel;
    Label8: TLabel;
    LAzimut: TLabel;
    PnlAcerca: TPanel;
    LayPrinc: TLayout;
    Layout3: TLayout;
    Layout5: TLayout;
    Layout6: TLayout;
    Layout7: TLayout;
    Layout8: TLayout;
    Layout9: TLayout;
    Layout10: TLayout;
    Layout11: TLayout;
    Image1: TImage;
    LNombre: TLabel;
    LVersion: TLabel;
    LAutor: TLabel;
    LFecha: TLabel;
    BAceptar: TButton;
    Rectangle2: TRectangle;
    Image2: TImage;
    LayMsgGMS: TLayout;
    Label9: TLabel;
    LayLatGSM: TLayout;
    Label10: TLabel;
    LLatGMS: TLabel;
    LayLonGSM: TLayout;
    Label12: TLabel;
    LLonGMS: TLabel;
    Rectangle5: TRectangle;
    SBAgregar: TSpeedButton;
    FrmAgrCoord: TFrmAgrCoord;
    procedure LctSensorLocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure SwitchGPSSwitch(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure LctSensorHeadingChanged(Sender: TObject;
      const AHeading: THeading);
    procedure BAceptarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SBAgregarClick(Sender: TObject);
    procedure FrmAgrCoord1SBVolverClick(Sender: TObject);
    procedure FrmAgrCoord1BGuardarClick(Sender: TObject);
  private
    { Private declarations }
    procedure CargarRegCoordenadas;
  public
    { Public declarations }
  end;

const
  Blanco=4294967295;
  Negro=4278190080;
  Lima=4278255360;
  Chartreuse=$FF7FFF00;
  Rojo=$FFFF0000;

var
  FPrinc: TFPrinc;
  Coords: TCoord;

implementation

uses
  System.Permissions, FMX.DialogService, DataMod;

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

function Orientacion(Grados: double): string;
begin
  case Round(Grados) of
    0..10,350..360: Result:='N';  //norte
    11..34: Result:='N - NE';     //norte-noreste
    35..54: Result:='NE';         //noreste
    55..79: Result:='E - NE';     //este-noreste
    80..100: Result:='E';         //este
    101..124: Result:='E - SE';   //este-sureste
    125..144: Result:='SE';       //sureste
    145..169: Result:='S - SE';   //sur-sureste
    170..190: Result:='S';        //sur
    191..214: Result:='S - SW';   //sur-suroeste
    215..234: Result:='SW';       //suroeste
    235..259: Result:='W - SW';   //oeste-suroeste
    260..280: Result:='W';        //oeste
    281..304: Result:='W - NW';   //oeste-noroeste
    305..324: Result:='NW';       //noroeste
    325..349: Result:='N - NW';   //norte-noroeste
  end;
end;

procedure RotarFlecha(Circulo: TCircle; Azimut: Double);
var
  I,AntGrados,NvoGrados,Diferencia: Word;

  procedure MoverFlecha(I: word);
  begin
    Application.ProcessMessages;  //momentáneamente deshabilitado!
    Sleep(50);
    Circulo.RotationAngle:=I;
  end;

begin
  if Round(Circulo.RotationAngle)=0 then AntGrados:=360
  else AntGrados:=Round(Circulo.RotationAngle);
  if Azimut=0 then NvoGrados:=360
              else NvoGrados:=Round(Azimut);
  Diferencia:=Abs(NvoGrados-AntGrados);
  if Diferencia<=180 then
  begin
    if NvoGrados>AntGrados then
      for I:=AntGrados to NvoGrados do MoverFlecha(I)
    else
      for I:=AntGrados downto NvoGrados do MoverFlecha(I);
  end
  else
  begin
    Circulo.RotationAngle:=AntGrados+NvoGrados;
    if AntGrados>NvoGrados then
      for I:=AntGrados to 360+NvoGrados do MoverFlecha(I)
    else
      for I:=AntGrados downto NvoGrados do MoverFlecha(I)
  end;
end;

procedure TFPrinc.BAceptarClick(Sender: TObject);
begin
  PnlAcerca.Visible:=false;
  LayPrinc.Visible:=true;
end;

procedure CargarFuente(Etq: TLabel);
var
  Recursos: TResourceStream;
  Fuente: TFont;
begin
  Fuente:=TFont.Create;
  Recursos:=TResourceStream.Create(hInstance,'1',RT_RCDATA);
end;

procedure TFPrinc.CargarRegCoordenadas;
begin
 //
end;

procedure TFPrinc.FormCreate(Sender: TObject);
begin
  LActivar.TextSettings.FontColor:=Blanco;
  LNombre.Font.Family:='1';
  SBAgregar.Visible:=false;
  FrmAgrCoord.ValInicio;
  FrmAgrCoord.Visible:=false;
  LayPrinc.Visible:=true;
end;

procedure TFPrinc.FrmAgrCoord1BGuardarClick(Sender: TObject);
begin
  FrmAgrCoord.BGuardarClick(Sender);
end;

procedure TFPrinc.FrmAgrCoord1SBVolverClick(Sender: TObject);
begin
  FrmAgrCoord.SBVolverClick(Sender);
  FrmAgrCoord.Visible:=false;
  LayPrinc.Visible:=true;
end;

procedure TFPrinc.LctSensorHeadingChanged(Sender: TObject;
  const AHeading: THeading);
begin
  RotarFlecha(CrcKingOTN,AHeading.Azimuth);
  CrcKingOTN.RotationAngle:=AHeading.Azimuth;
  LAzimut.Text:=FormatFloat('0.##',AHeading.Azimuth)+'º';
  LRumbo.Text:=Orientacion(AHeading.Azimuth);
end;

procedure TFPrinc.LctSensorLocationChanged(Sender: TObject; const OldLocation,
  NewLocation: TLocationCoord2D);
var
  LDecSeparator: char;
  LatLon: TRecLatLon;
  UTM: TRecUTM;
begin
  LDecSeparator:=FormatSettings.DecimalSeparator;
  FormatSettings.DecimalSeparator:='.';
  //muestra la posición actual:
  LatLon.Lat:=NewLocation.Latitude;
  LatLon.Lon:=NewLocation.Longitude;
  LatLon_To_UTM(LatLon,UTM);
  LLat.Text:=Format('%2.6f',[NewLocation.Latitude]);
  LLon.Text:=Format('%2.6f',[NewLocation.Longitude]);
  LEste.Text:=FormatFloat('#0.00',UTM.X);
  LNorte.Text:=FormatFloat('#0.00',UTM.Y);
  LLatGMS.Text:=DecAGrados(LatLon.Lat,true);
  LLonGMS.Text:=DecAGrados(LatLon.Lon,false);
  //carga el registro:
  //CargarRegCoordenadas;
  {FrmAgrCoord.Coord.EsteUTM:=UTM.X;
  FrmAgrCoord.Coord.NorteUTM:=UTM.Y;
  FrmAgrCoord.Coord.Lat:=NewLocation.Latitude;
  FrmAgrCoord.Coord.Lon:=NewLocation.Longitude;
  FrmAgrCoord.Coord.LatGMS:=LLatGMS.Text;
  FrmAgrCoord.Coord.LonGMS:=LLonGMS.Text;
  FrmAgrCoord.Coord.Fecha:=Now; }
  Coords.EsteUTM:=UTM.X;
  Coords.NorteUTM:=UTM.Y;
  Coords.Lat:=NewLocation.Latitude;
  Coords.Lon:=NewLocation.Longitude;
  Coords.LatGMS:=LLatGMS.Text;
  Coords.LonGMS:=LLonGMS.Text;
  Coords.Fecha:=Now;
end;

procedure TFPrinc.SpeedButton1Click(Sender: TObject);
begin
  DMod.FDConn.Connected:=false;
  Application.Terminate;
end;

procedure TFPrinc.SpeedButton2Click(Sender: TObject);
begin
  LayPrinc.Visible:=false;
  PnlAcerca.Visible:=true;
end;

procedure TFPrinc.SBAgregarClick(Sender: TObject);
begin
  FrmAgrCoord.Coord:=Coords;
  FrmAgrCoord.LCoordSex.Text:=Coords.LonGMS+', '+Coords.LatGMS;
  FrmAgrCoord.LCoordDec.Text:=Format('%2.6f',[Coords.Lon])+', '+
                              Format('%2.6f',[Coords.Lat]);
  FrmAgrCoord.LCoordUTM.Text:=FormatFloat('#0.00',Coords.EsteUTM)+
                         ', '+FormatFloat('#0.00',Coords.NorteUTM);
  FrmAgrCoord.Coord.LatLon:=FrmAgrCoord.LCoordDec.Text;
  FrmAgrCoord.BGuardar.Enabled:=false;
  FrmAgrCoord.CargarLista;
  LayPrinc.Visible:=false;
  FrmAgrCoord.Visible:=true;
end;

procedure TFPrinc.SwitchGPSSwitch(Sender: TObject);
const
  PermissionAccessFineLocation='android.permission.ACCESS_FINE_LOCATION';
begin
  PermissionsService.RequestPermissions([PermissionAccessFineLocation],
    procedure(const APermissions: TClassicStringDynArray;
              const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults)=1) and (AGrantResults[0]=TPermissionStatus.Granted) then
        LctSensor.Active := SwitchGPS.IsChecked
      else
      begin
        SwitchGPS.IsChecked:=false;
        FrmAgrCoord.ValInicio;
        TDialogService.ShowMessage('Permiso de Localización no está permitido');
      end;
    end);
  //se cambian los colores según esté activo o no el GPS:
  if SwitchGPS.IsChecked then
  begin
    LActivar.Text:='Desactivar GPS';
    LActivar.TextSettings.FontColor:=Negro;
    RectActivar.Fill.Color:=Lima;
    CrcKingOTN.Stroke.Color:=Chartreuse;
  end
  else
  begin
    LActivar.Text:='Activar GPS';
    LActivar.TextSettings.FontColor:=Blanco;
    RectActivar.Fill.Color:=Rojo;
    CrcKingOTN.Stroke.Color:=Rojo;
    LLat.Text:='--.-----';
    LLon.Text:='--.-----';
    LEste.Text:='--';
    LNorte.Text:='--';
    LAzimut.Text:='--';
    LRumbo.Text:='--';
    LLatGMS.Text:='--º --'' --"';
    LLonGMS.Text:='--º --'' --"';
    CrcKingOTN.RotationAngle:=0;
  end;
  SBAgregar.Visible:=SwitchGPS.IsChecked;
end;

end.
