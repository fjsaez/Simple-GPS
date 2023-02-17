//conversion  World Geodetic System 1984 <-> Universal Transverse Mercator WGS84

unit UTM_WGS84;

interface

type

  TRecLatLon = record
    Lat,Lon : double;
    OK      : boolean;
  end;
  TRecUTM = record
    X,Y          : double;
    fuseau       : integer;
    OK,southhemi : boolean;
    CharLat      : char;
  end;

  function DecAGrados(Valor: Double; EsLatitud: boolean): string;
  procedure LatLon_To_UTM(LatLon: TRecLatLon; var UTM: TRecUTM);
  procedure UTM_To_LatLon(UTM: TRecUTM; var latlon: TRecLatLon);
  function Str_LatLon_To_UTM(const LatLon: TrecLatLon):string; // U UTM30 X="408439" Y="5370236"
  function Str_UTM_To_LatLon(const UTM: TrecUTM) : string;    // lat="43.715023" lon="4.716750"

implementation

uses SysUtils, Math;

const  ct_dga = 6378137;      //demi grand axe
       ct_dpa = 6356752.314;  //demi petit axe
       ct_UTMScaleFactor = 0.9996; //facteur d'échelle

{Convierte grados a formato grados/minutos/segundos}
function DecAGrados(Valor: Double; EsLatitud: boolean): string;
var
  sGrad,sMin,sSeg,Orientacion: string;
  xMin,xSeg: Double;
begin
  Orientacion:='';
  xMin:=Frac(Valor)*60;
  xSeg:=Frac(xMin)*60;
  sGrad:=Abs(Trunc(Valor)).ToString;
  if EsLatitud then
    if Trunc(Valor)>=0 then Orientacion:='N'
                       else Orientacion:='S'
  else
    if Trunc(Valor)>=0 then Orientacion:='E'
                       else Orientacion:='O';
  sMin:=Abs(Trunc(xMin)).ToString;
  sSeg:=Abs(Trunc(xSeg)).ToString;
  Result:=sGrad+'° '+sMin+''' '+sSeg+'" '+Orientacion;
end;

function ArcLengthOfMeridian(phi:Double):Double;
var
  alpha, beta, gamma, delta, epsilon, n: Double;
begin
  n:=(ct_dga-ct_dpa)/(ct_dga+ct_dpa);
  alpha:=((ct_dga+ct_dpa)/2)*(1+(intPower(n,2)/4)+(intPower(n,4)/64));
  beta:=(-3*n/2)+(9*intPower(n,3)/16)+(-3*intPower(n,5)/32);
  gamma:=(15*intPower(n,2)/16)+(-15*intPower(n,4)/32);
  delta:=(-35*intPower(n,3)/48)+(105*intPower(n,5)/256);
  epsilon:=(315*intPower(n,4)/512);
  result:=alpha*(phi+(beta*sin(2*phi))+(gamma*sin(4*phi))+
          (delta*sin(6*phi))+(epsilon*sin(8*phi)));
end;

function UTMCentralMeridian(fuseau:integer):Double;
begin
  Result:=DegToRad(-183+(fuseau*6));
end;

function FootpointLatitude (y:Double):Double;
var y_, alpha_, beta_, gamma_, delta_, epsilon_, n:Double;
begin
  n:=(ct_dga-ct_dpa)/(ct_dga+ct_dpa);
  alpha_:=((ct_dga+ct_dpa)/2)*(1+(intPower(n,2)/4)+(intPower(n,4)/64));
  y_:=y/alpha_;
  beta_:=(3*n/2)+(-27*intPower(n,3)/32)+(269*intPower(n,5)/512);
  gamma_:=(21*intPower(n,2)/16)+(-55*intPower(n,4)/32);
  delta_:=(151*intPower(n,3)/96)+(-417*intPower(n,5)/128);
  epsilon_:=(1097*intPower(n,4)/512);
  result:=y_+(beta_*sin(2*y_))+(gamma_*sin(4*y_))+(delta_*sin(6*y_))+
          (epsilon_*sin(8*y_));
end;

procedure MapLatLonToXY (LatLon:TrecLatLon; lambda0:Double; var UTM:TrecUTM);
var N, nu2, ep2, t, t2, l, phi, lambda:Double;
var l3coef, l4coef, l5coef, l6coef, l7coef, l8coef:Double;
begin
  phi:=LatLon.Lat; lambda:=LatLon.Lon;
  ep2 := (intPower (ct_dga, 2) - intPower (ct_dpa, 2)) / intPower (ct_dpa, 2);
  nu2 := ep2 * intPower (cos (phi), 2);
  N := intPower (ct_dga, 2) / (ct_dpa * sqrt (1 + nu2));
  t := tan (phi); t2 := t * t;
  l := lambda - lambda0;
  l3coef := 1 - t2 + nu2; l4coef := 5 - t2 + 9 * nu2 + 4 * (nu2 * nu2);
  l5coef := 5 - 18 * t2 + (t2 * t2) + 14 * nu2 - 58 * t2 * nu2;
  l6coef := 61 - 58 * t2 + (t2 * t2) + 270 * nu2 - 330 * t2 * nu2;
  l7coef := 61 - 479 * t2 + 179 * (t2 * t2) - (t2 * t2 * t2);
  l8coef := 1385 - 3111 * t2 + 543 * (t2 * t2) - (t2 * t2 * t2);
  UTM.X := N * cos (phi) * l
        + (N / 6 * intPower (cos (phi), 3) * l3coef * intPower (l, 3))
        + (N / 120 * intPower (cos (phi), 5) * l5coef * intPower (l, 5))
        + (N / 5040 * intPower (cos (phi), 7) * l7coef * intPower (l, 7));
  UTM.Y := ArcLengthOfMeridian (phi)
        + (t / 2 * N * intPower (cos (phi), 2) * intPower (l, 2))
        + (t / 24 * N * intPower (cos (phi), 4) * l4coef * intPower (l, 4))
        + (t / 720 * N * intPower (cos (phi), 6) * l6coef * intPower (l, 6))
        + (t / 40320 * N * intPower (cos (phi), 8) * l8coef * intPower (l, 8));
end;

procedure MapXYToLatLon (UTM:TrecUTM; lambda0:Double; var philambda:TrecLatLon);
var phif, Nf, Nfpow, nuf2, ep2, tf, tf2, tf4, cf,x ,y:Double;
var x1frac, x2frac, x3frac, x4frac, x5frac, x6frac, x7frac, x8frac:Double;
var x2poly, x3poly, x4poly, x5poly, x6poly, x7poly, x8poly:Double;
begin
  x:=UTM.X; y:=UTM.Y;
  phif := FootpointLatitude (y);
  ep2 := (intPower (ct_dga, 2) - intPower (ct_dpa, 2)) / intPower (ct_dpa, 2);
  cf := cos (phif);
  nuf2 := ep2 * intPower (cf, 2);
  Nf := intPower (ct_dga, 2) / (ct_dpa * sqrt (1 + nuf2)); Nfpow := Nf;
  tf := tan (phif); tf2 := tf * tf; tf4 := tf2 * tf2;
  x1frac := 1 / (Nfpow * cf);
  Nfpow := Nfpow * Nf; x2frac := tf / (2 * Nfpow);  // now equals Nf**2)
  Nfpow := Nfpow * Nf; x3frac := 1 / (6 * Nfpow * cf);  // now equals Nf**3)
  Nfpow := Nfpow * Nf; x4frac := tf / (24 * Nfpow);  // now equals Nf**4)
  Nfpow := Nfpow * Nf; x5frac := 1 / (120 * Nfpow * cf);  // now equals Nf**5)
  Nfpow := Nfpow * Nf; x6frac := tf / (720 * Nfpow);  // now equals Nf**6)
  Nfpow := Nfpow * Nf; x7frac := 1 / (5040 * Nfpow * cf);  // now equals Nf**7)
  Nfpow := Nfpow * Nf; x8frac := tf / (40320 * Nfpow);  // now equals Nf**8)
  x2poly := -1 - nuf2; x3poly := -1 - 2 * tf2 - nuf2;
  x4poly := 5 + 3 * tf2 + 6 * nuf2 - 6 * tf2 * nuf2
         - 3 * (nuf2 *nuf2) - 9 * tf2 * (nuf2 * nuf2);
  x5poly := 5 + 28 * tf2 + 24 * tf4 + 6 * nuf2 + 8 * tf2 * nuf2;
  x6poly := -61 - 90 * tf2 - 45 * tf4 - 107 * nuf2 + 162 * tf2 * nuf2;
  x7poly := -61 - 662 * tf2 - 1320 * tf4 - 720 * (tf4 * tf2);
  x8poly := 1385 + 3633 * tf2 + 4095 * tf4 + 1575 * (tf4 * tf2);
  philambda.Lat := phif + x2frac * x2poly * (x * x) + x4frac * x4poly * intPower (x, 4)
        	+ x6frac * x6poly * intPower (x, 6) + x8frac * x8poly * intPower (x, 8);
  philambda.Lon := lambda0 + x1frac * x + x3frac * x3poly * intPower (x, 3)
        	+ x5frac * x5poly * intPower (x, 5) + x7frac * x7poly * intPower (x, 7);
end;

function LatLonToUTMXY (LatLon:TrecLatLon; var UTM:TrecUTM):Integer;
begin
  MapLatLonToXY (LatLon, UTMCentralMeridian (UTM.fuseau), UTM); //calcul xy
  UTM.X := UTM.X * ct_UTMScaleFactor + 500000;
  UTM.Y := UTM.Y * ct_UTMScaleFactor;
  if UTM.Y < 0 then UTM.Y := UTM.Y + 10000000;
  Result:=UTM.fuseau;
end;

procedure UTMXYToLatLon (UTM:TrecUTM; var latlon:TrecLatLon);
var cmeridian:Double;
begin
  UTM.x := UTM.x - 500000; UTM.x := UTM.x / ct_UTMScaleFactor;
  if UTM.southhemi then UTM.y := UTM.y - 10000000;
  UTM.y := UTM.y / ct_UTMScaleFactor;
  cmeridian := UTMCentralMeridian (UTM.fuseau);
  MapXYToLatLon (UTM, cmeridian, latlon);
end;

function Limits(LatLon:TrecLatLon):boolean;
begin
  Result:=((LatLon.Lat <= 84) and (LatLon.Lat >= -80)) and
  ((LatLon.Lon <= 180) and (LatLon.Lon >= -180));
end;

function CharLat(LatLon:TrecLatLon):char;
var Od : integer;
begin
  Od:=floor(abs(LatLon.Lat/8));
  if LatLon.Lat < 0 then
  begin
    Od:=9-Od; if Od < 0 then Od:=0;
    Result:=chr(ord('C')+Od);
    if Result > 'H' then inc(Result);
  end else
  begin
    if Od > 9 then Od:=9;
    Result:=chr(ord('N')+Od); if Result > 'N' then inc(Result);
  end;
end;

procedure LatLon_TO_UTM(LatLon:TrecLatLon; var UTM:TrecUTM);
begin
  UTM.OK:=Limits(LatLon); if not UTM.OK then exit;
  UTM.CharLat:=CharLat(LatLon);
  UTM.fuseau := floor ((LatLon.lon + 180) / 6) + 1;
  LatLon.Lat:=DegToRad (LatLon.Lat); LatLon.Lon:=DegToRad (LatLon.Lon);
  UTM.fuseau := LatLonToUTMXY (LatLon,UTM);
  UTM.southhemi:=LatLon.Lat < 0;
  if UTM.southhemi then UTM.Y:=UTM.Y*-1;
end;

procedure UTM_TO_LatLon(UTM:TrecUTM; var latlon:TrecLatLon);
var LonH,LonL:Integer;
begin
  LatLon.OK:=(UTM.fuseau >= 1) and (UTM.fuseau <= 60);
  if not LatLon.OK then exit;
  UTM.southhemi:=UTM.Y < 0;
  if UTM.southhemi then UTM.Y:=abs(UTM.Y);
  UTMXYToLatLon (UTM,latlon);
  latlon.Lat:=RadToDeg(LatLon.Lat);
  latLon.Lon:=RadToDeg(LatLon.Lon);
  if UTM.southhemi then UTM.Y:=UTM.Y*-1;
  LatLon.OK:=Limits(LatLon);
  if not LatLon.OK then exit;
  LonL:=-186 + (UTM.fuseau * 6);
  LonH:=LonL+6;
  LatLon.OK:=(LatLon.Lon >= LonL) and (LatLon.lon <= LonH);
end;

Const CtHorsLimites = 'Hors Limites';

function STR_LatLon_TO_UTM(Const LatLon:TrecLatLon):string;
const Fmt0 = '0';
var UTM : TrecUTM;
    STRfuseau : string;
begin
  LatLon_TO_UTM(LatLon,UTM);
  if UTM.OK then
  begin
    STRfuseau:=intTOstr(UTM.fuseau);
    if UTM.fuseau < 10 then STRfuseau:='0'+STRfuseau;
    Result:=UTM.CharLat+' UTM'+STRfuseau+' X="'+formatFloat(Fmt0,UTM.X)+
    '" Y="'+formatFloat(Fmt0,UTM.Y)+'"';
  end else
  Result:=CtHorsLimites;
end;

function STR_UTM_TO_LatLon(Const UTM:TrecUTM) : string;
const
  Fmt7 = '0.0000000000';
  C = ',';
  S = ',';
var
  LatLon: TrecLatLon;
  P: integer;
begin
  UTM_TO_LatLon(UTM,LatLon);
  if LatLon.OK then
  begin
    Result:=FormatFloat(Fmt7,LatLon.Lon)+','+
            FormatFloat(Fmt7,LatLon.Lat)+',0';
    P:=pos(C,Result);
    if P <> 0 then Result[P]:=S;
    P:=pos(C,Result);
    if P <> 0 then Result[P]:=S;
  end
  else Result:=CtHorsLimites;
end;

end.  //445   431   267   297  257
