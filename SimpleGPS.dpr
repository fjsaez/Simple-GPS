program SimpleGPS;

uses
  System.StartUpCopy,
  Androidapi.JNI.App,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers,
  FMX.Forms,
  UtilesSimpleGPS in 'UtilesSimpleGPS.pas',
  Principal in 'Principal.pas' {FPrinc},
  Androidapi.JNI.Location in 'Androidapi.JNI.Location.pas',
  System.Android.Sensors in 'System.Android.Sensors.pas',
  DataMod in 'DataMod.pas' {DMod: TDataModule},
  AgrCoordenada in 'AgrCoordenada.pas' {FrmAgrCoord: TFrame};

{$R *.res}

begin
  Application.Initialize;
  TAndroidHelper.Activity.getWindow.addFlags(
    TJWindowManager_LayoutParams.JavaClass.FLAG_KEEP_SCREEN_ON);
  Application.FormFactor.Orientations := [TFormOrientation.Portrait];
  Application.CreateForm(TDMod, DMod);
  Application.CreateForm(TFPrinc, FPrinc);
  Application.Run;
end.
