unit Principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Sensors, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Platform.Android,
  System.Sensors.Components, FMX.Objects, UTM_WGS84, Androidapi.JNI.Location,
  FMX.FontGlyphs.Android, System.Math, AgrCoordenada, UtilesSimpleGPS;

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
    Layout12: TLayout;
    Label11: TLabel;
    LVelocidad: TLabel;
    Layout13: TLayout;
    Line1: TLine;
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
  public
    { Public declarations }
  end;

var
  FPrinc: TFPrinc;


implementation

uses       
  System.Permissions, FMX.DialogService, DataMod;

{$R *.fmx}

/// Eventos ///

procedure TFPrinc.BAceptarClick(Sender: TObject);
begin
  PnlAcerca.Visible:=false;
  LayPrinc.Visible:=true;
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
  if IsNaN(LctSensor.Sensor.Speed) then LVelocidad.Text:='0.00'
  else LVelocidad.Text:=FormatFloat('#0.00',LctSensor.Sensor.Speed);
  //carga el registro:
  Coords.EsteUTM:=UTM.X;
  Coords.NorteUTM:=UTM.Y;
  Coords.Lat:=NewLocation.Latitude;
  Coords.Lon:=NewLocation.Longitude;
  Coords.LatGMS:=LLatGMS.Text;
  Coords.LonGMS:=LLonGMS.Text;
  Coords.LatLon:=Format('%2.6f',[NewLocation.Longitude])+', '+
                 Format('%2.6f',[NewLocation.Latitude]);
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
  FrmAgrCoord.LCoordDec.Text:=Coords.LatLon;
  FrmAgrCoord.LCoordUTM.Text:=FormatFloat('#0.00',Coords.EsteUTM)+', '+
                              FormatFloat('#0.00',Coords.NorteUTM);
  FrmAgrCoord.MemoDescr.ReadOnly:=false;
  FrmAgrCoord.BGuardar.Enabled:=false;
  FrmAgrCoord.CargarLista;
  FrmAgrCoord.ColDescr.Width:=FrmAgrCoord.SGrid.Width;
  LayPrinc.Visible:=false;
  FrmAgrCoord.Visible:=true;
  FrmAgrCoord.MemoDescr.SetFocus;
end;

procedure TFPrinc.SwitchGPSSwitch(Sender: TObject);
begin
  ActivarGPS(LctSensor,SwitchGPS.IsChecked);
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
    FrmAgrCoord.ValInicio;
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
