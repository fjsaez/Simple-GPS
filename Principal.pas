unit Principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, System.Sensors,
  System.Sensors.Components, FMX.Objects, FMX.Platform.Android, UTM_WGS84;

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
    procedure LctSensorLocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure SwitchGPSSwitch(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure LctSensorHeadingChanged(Sender: TObject;
      const AHeading: THeading);
    procedure BAceptarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FPrinc: TFPrinc;

implementation

{$R *.fmx}

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
    Application.ProcessMessages;
    Sleep(0);
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
begin            //continuar aqu? ma?ana
  Fuente:=TFont.Create;
  Recursos:=TResourceStream.Create(hInstance,'1',RT_RCDATA);
end;

procedure TFPrinc.FormCreate(Sender: TObject);
begin
  LActivar.TextSettings.FontColor:=4294967295; //blanco
  LNombre.Font.Family:='1';
end;

procedure TFPrinc.LctSensorHeadingChanged(Sender: TObject;
  const AHeading: THeading);
begin
  RotarFlecha(CrcKingOTN,AHeading.Azimuth);
  CrcKingOTN.RotationAngle:=AHeading.Azimuth;
  LAzimut.Text:=FormatFloat('0.##',AHeading.Azimuth)+'?';
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
  //muestra la posici?n actual:
  LatLon.Lat:=NewLocation.Latitude;
  LatLon.Lon:=NewLocation.Longitude;
  LatLon_To_UTM(LatLon,UTM);
  LLat.Text:=Format('%2.6f',[NewLocation.Latitude]);
  LLon.Text:=Format('%2.6f',[NewLocation.Longitude]);
  LEste.Text:=FormatFloat('#0.00',UTM.X);
  LNorte.Text:=FormatFloat('#0.00',UTM.Y);
end;

procedure TFPrinc.SpeedButton1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFPrinc.SpeedButton2Click(Sender: TObject);
begin
  LayPrinc.Visible:=false;
  PnlAcerca.Visible:=true;
end;

procedure TFPrinc.SwitchGPSSwitch(Sender: TObject);
begin
  LctSensor.Active:=SwitchGPS.IsChecked;
  if SwitchGPS.IsChecked then
  begin
    LActivar.Text:='Desactivar GPS';
    LActivar.TextSettings.FontColor:=4278190080; //negro
    RectActivar.Fill.Color:=4278255360;          //lime
    CrcKingOTN.Stroke.Color:=$FF7FFF00;          //chartreuse
  end
  else
  begin
    LActivar.Text:='Activar GPS';
    LActivar.TextSettings.FontColor:=4294967295; //blanco
    RectActivar.Fill.Color:=$FFFF0000;           //rojo
    CrcKingOTN.Stroke.Color:=$FFFF0000;          //rojo
    LLat.Text:='--.-----';
    LLon.Text:='--.-----';
    LEste.Text:='--';
    LNorte.Text:='--';
    LAzimut.Text:='--';
    LRumbo.Text:='--';
    CrcKingOTN.RotationAngle:=0;
  end;
end;

end.

{procedure TFPrinc.SpeedButton1Click(Sender: TObject);
begin
  //MainActivity.finish;
  Application.Terminate;
end;}
