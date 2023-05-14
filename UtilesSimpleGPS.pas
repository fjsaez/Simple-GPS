unit UtilesSimpleGPS;

interface

uses
  FMX.FontGlyphs.Android, FMX.Forms, FMX.Objects, FMX.StdCtrls, FMX.Graphics,
  System.Sensors.Components, System.SysUtils, System.Classes, System.Types,
  System.Permissions, FMX.DialogService;

type
  TCoord = record
    IDCoord: Cardinal;
    EsteUTM,NorteUTM,Lat,Lon: single;
    LatGMS,LonGMS,LatLon,Descripcion: string;
    Fecha: TDate;
  end;

const
  Blanco=4294967295;
  Negro=4278190080;
  Lima=4278255360;
  Chartreuse=$FF7FFF00;
  Rojo=$FFFF0000;

var
  Coords: TCoord;

  function Orientacion(Grados: double): string;
  procedure RotarFlecha(Circulo: TCircle; Azimut: Double);
  procedure CargarFuente(Etq: TLabel);
  procedure ActivarGPS(LcSensor: TLocationSensor; Activo: boolean);

implementation

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

procedure CargarFuente(Etq: TLabel);
var
  Recursos: TResourceStream;
  Fuente: TFont;
begin
  Fuente:=TFont.Create;
  Recursos:=TResourceStream.Create(hInstance,'1',RT_RCDATA);
end;

procedure ActivarGPS(LcSensor: TLocationSensor; Activo: boolean);
const
  PermissionAccessFineLocation='android.permission.ACCESS_FINE_LOCATION';
begin
  PermissionsService.RequestPermissions([PermissionAccessFineLocation],
    procedure(const APermissions: TClassicStringDynArray;
              const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults)=1) and (AGrantResults[0]=TPermissionStatus.Granted) then
        LcSensor.Active:=Activo
      else
      begin
        Activo:=false;
        TDialogService.ShowMessage('Permiso a Localización no concedido');
      end;
    end);
end;

end.
