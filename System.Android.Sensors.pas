{*******************************************************}
{                                                       }
{           CodeGear Delphi Runtime Library             }
{ Copyright(c) 2013-2022 Embarcadero Technologies, Inc. }
{              All rights reserved                      }
{                                                       }
{*******************************************************}

unit System.Android.Sensors;

interface

uses
  System.Sensors, Androidapi.Sensor, Androidapi.JNI.Location;

type
  INDKSensor = interface
  ['{523B5B0F-AD54-4C1E-B9A1-978B5CD37D8B}']
    /// <summary>
    /// Type of this instance of sensor. Using this value you can understand what kind of sensor you use.
    /// For example, if SensorType = 10 it means that you use ASENSOR_TYPE_LINEAR_ACCELERATION.
    /// This const declared in Androidapi.Sensor.pas
    /// </summary>
    function SensorType: Integer;
    /// <summary>
    /// Instance of a specific sensor manager
    /// </summary>
    function SensorManager: PASensorManager;
    /// <summary>
    /// Instance of a specific sensor
    /// </summary>
    function Sensor: PASensor;
    /// <summary>
    /// Event queue for the sensor
    /// </summary>
    function NativeEventQueue: PASensorEventQueue;
    /// <summary>
    /// This record represents a Sensor event and holds information such as the time-stamp, accuracy and the sensor data.
    /// </summary>
    function LastValue: ASensorEvent;
  end;

  ILocationListeners = interface
    ['{F379C0D0-63A5-4B98-845B-09C611BE5D40}']
    /// <summary>
    /// For GPS location provider. Used for receiving notifications from the LocationManager when the location has changed.
    /// </summary>
    function GetGPSListener: JLocationListener;
    /// <summary>
    /// For network location provider. Used for receiving notifications from the LocationManager when the location has changed.
    /// </summary>
    function GetNetworkListener: JLocationListener;
    /// <summary>
    /// For passive location provider. Used for receiving notifications from the LocationManager when the location has changed.
    /// </summary>
    function GetPassiveListener: JLocationListener;
  end;

  TPlatformSensorManager = class(TSensorManager)
  protected
    class function GetSensorManager: TSensorManager; override;
  end;

  TPlatformGeocoder = class(TGeocoder)
  protected
    class function GetGeocoderImplementer: TGeocoderClass; override;
  end;

  TPlatformGpsStatus = class(TGpsStatus)
  protected
    class function GetGpsStatusImplementer: TGpsStatusClass; override;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.DateUtils, System.Permissions, System.RTLConsts, System.Math,
  Androidapi.AppGlue, Androidapi.Looper, Androidapi.Jni, Androidapi.JNIBridge, Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Os, Androidapi.JNI.App, Androidapi.JNI.GraphicsContentViewText, Androidapi.Helpers;

type
  TAndroidGeocoder = class(TGeocoder)
  private class var
    FGeocoder: JGeocoder;
  private
    class constructor Create;
    class destructor Destroy;
  protected
    class function GetGeocoderImplementer: TGeocoderClass; override;
    class procedure GeocodeRequest(const AAddress: TCivicAddress); override;
    class procedure GeocodeReverseRequest(const Coords: TLocationCoord2D); override;
  public
    class function Supported: Boolean; override;
    class function Authorized: TAuthorizationType; override;
    class procedure Cancel; override;
  end;

  TUIAndroidLocationSensor = class(TCustomLocationSensor)
  private
    FPermitted: Boolean;
    FLastValue: JLocation;
    FLocationManager: JLocationManager;
    FAccuracy: TLocationAccuracy;
    FDistance: TLocationDistance;
    type
      TLocationListener = class(TJavaLocal, JLocationListener)
      private
        FLocationSensor: TUIAndroidLocationSensor;
      public
        constructor Create(ALocationSensor: TUIAndroidLocationSensor);
        procedure onFlushComplete(requestCode: Integer); cdecl;
        procedure onLocationChanged(location: JLocation); overload; cdecl;
        procedure onLocationChanged(locations: JList); overload; cdecl;
        procedure onProviderDisabled(provider: JString); cdecl;
        procedure onProviderEnabled(provider: JString); cdecl;
        procedure onStatusChanged(provider: JString; status: Integer; extras: JBundle); cdecl;
        ///
        procedure onLocationChanged(P1: JObject); overload; cdecl;
        procedure onLocationChanged(P1: JArrayList); overload; cdecl;
      end;

      TLocationRunnable = class(TJavaLocal, JRunnable)
      private
        FLocationManager: JLocationManager;
        FListener: TLocationListener;
        FProvider: JString;
      public
        constructor Create(ALocationManager: JLocationManager; AListener: TLocationListener; AProvider: JString);
        procedure run; cdecl;
      end;

      TInterfaceHolder = class(TInterfacedObject, ILocationListeners)
      private
        FLocationSensor: TUIAndroidLocationSensor;
        function GetGPSListener: JLocationListener;
        function GetNetworkListener: JLocationListener;
        function GetPassiveListener: JLocationListener;
      public
        constructor Create(const ALocationSensor: TUIAndroidLocationSensor);
      end;

  private
    FActivityType: TLocationActivityType;
    FLocationListeners: ILocationListeners;
    FGPSListener: TLocationListener;
    FGPSRunner: TLocationRunnable;
    FNetworkListener: TLocationListener;
    FNetworkRunner: TLocationRunnable;
    FPassiveListener: TLocationListener;
    FPassiveRunner: TLocationRunnable;
    FUsageAuthorization: TLocationUsageAuthorization;
  protected
    function DoStart: Boolean; override;
    procedure DoStop; override;
    function GetLocationSensorType: TLocationSensorType; override;
    function GetActivityType: TLocationActivityType; override;
    function GetAvailableProperties: TCustomLocationSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomLocationSensor.TProperty): Double; override;
    function GetStringProperty(Prop: TCustomLocationSensor.TProperty): string; override;
    function GetState: TSensorState; override;
    function GetTimeStamp: TDateTime; override;
    function GetUsageAuthorization: TLocationUsageAuthorization; override;
    procedure DoOptimize; override;
    function GetAuthorized: TAuthorizationType; override;
    function GetAccuracy: TLocationAccuracy; override;
    function GetDistance: TLocationDistance; override;
    function GetPowerConsumption: TPowerConsumption; override;
    procedure SetAccuracy(const Value: TLocationAccuracy); override;
    procedure SetActivityType(const Value: TLocationActivityType); override;
    procedure SetDistance(const Value: TLocationDistance); override;
    procedure SetUsageAuthorization(const Value: TLocationUsageAuthorization); override;
    procedure DoLocationChangeType; override;
    function DoGetInterface(const IID: TGUID; out Obj): HResult; override;
  public
    constructor Create(AManager: TSensorManager); override;
    function Supported: Boolean;
  end;

  TNDKSensor = class(TInterfacedObject, INDKSensor)
  strict private
    FEnabled: Boolean;
    FNativeSensor: PASensor;
    FSensorType: Integer;
    FSensorManager: PASensorManager;
    FNativeEventQueue: PASensorEventQueue;
    FLastSensorEvent: ASensorEvent;
    FUpdateInterval: Double;
    procedure SetUpdateInterval(const Value: Double);
  public
    constructor Create(const ANativeSensor: PASensor); overload;
    destructor Destroy; override;

    property Enabled: Boolean read FEnabled;
    function Start: Boolean;
    procedure Stop;
    property UpdateInterval: Double read FUpdateInterval write SetUpdateInterval;
    function TimeStamp: Double;
    function Name: string;
    function Manufacturer: string;

    { INDKSensor }
    function SensorType: Integer;
    function SensorManager: PASensorManager;
    function Sensor: PASensor;
    function NativeEventQueue: PASensorEventQueue;
    function LastValue: ASensorEvent;
  end;

{ Motion sensors }

  TAndroidMotionSensor = class abstract(TCustomMotionSensor)
  protected
    FNativeSensor: TNDKSensor;
    function DoStart: Boolean; override;
    procedure DoStop; override;
    function GetState: TSensorState; override;
    function GetTimeStamp: TDateTime; override;
    function GetSensorProperty(Prop: TCustomSensor.TProperty): string; override;
    function GetUpdateInterval: Double;  override;
    procedure SetUpdateInterval(AInterval: Double); override;
    function DoGetInterface(const IID: TGUID; out Obj): HResult; override;
  public
    constructor Create(AManager: TSensorManager; const ANativeSensor: PASensor); reintroduce;
  end;

  TAndroidGravitySensor = class(TAndroidMotionSensor)
  protected
    function GetMotionSensorType: TMotionSensorType; override;
    function GetAvailableProperties: TCustomMotionSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomMotionSensor.TProperty): Double; override;
  end;

  TAndroidLinearAccelerometrSensor = class(TAndroidMotionSensor)
  protected
    function GetMotionSensorType: TMotionSensorType; override;
    function GetAvailableProperties: TCustomMotionSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomMotionSensor.TProperty): Double; override;
  end;

  TAndroidAccelerometrSensor = class(TAndroidMotionSensor)
  protected
    function GetMotionSensorType: TMotionSensorType; override;
    function GetAvailableProperties: TCustomMotionSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomMotionSensor.TProperty): Double; override;
  end;

  TAndroidGyroscopeSensor = class(TAndroidMotionSensor)
  protected
    function GetMotionSensorType: TMotionSensorType; override;
    function GetAvailableProperties: TCustomMotionSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomMotionSensor.TProperty): Double; override;
  end;

{ Enviroument sensors }

  TAndroidEnvironmentalSensor = class abstract(TCustomEnvironmentalSensor)
  protected
    FNativeSensor: TNDKSensor;
    function DoStart: Boolean; override;
    procedure DoStop; override;
    function GetState: TSensorState; override;
    function GetTimeStamp: TDateTime; override;
    function GetSensorProperty(Prop: TCustomSensor.TProperty): string; override;
    function DoGetInterface(const IID: TGUID; out Obj): HResult; override;
  public
    constructor Create(AManager: TSensorManager; const ANativeSensor: PASensor); reintroduce;
  end;

  TAndroidHumiditySensor = class(TAndroidEnvironmentalSensor)
  protected
    function GetEnvironmentalSensorType: TEnvironmentalSensorType; override;
    function GetAvailableProperties: TCustomEnvironmentalSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomEnvironmentalSensor.TProperty): Double; override;
  end;

  TAndroidTemperatureSensor = class(TAndroidEnvironmentalSensor)
  protected
    function GetEnvironmentalSensorType: TEnvironmentalSensorType; override;
    function GetAvailableProperties: TCustomEnvironmentalSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomEnvironmentalSensor.TProperty): Double; override;
  end;

  TAndroidPressureSensor = class(TAndroidEnvironmentalSensor)
  protected
    function GetEnvironmentalSensorType: TEnvironmentalSensorType; override;
    function GetAvailableProperties: TCustomEnvironmentalSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomEnvironmentalSensor.TProperty): Double; override;
  end;

{ Orientation sensors }

  TAndroidOrientationSensor = class abstract(TCustomOrientationSensor)
  protected
    FNativeSensor: TNDKSensor;
    function DoStart: Boolean; override;
    procedure DoStop; override;
    function GetState: TSensorState; override;
    function GetTimeStamp: TDateTime; override;
    function GetSensorProperty(Prop: TCustomSensor.TProperty): string; override;
    function GetUpdateInterval: Double;  override;
    procedure SetUpdateInterval(AInterval: Double); override;
    function DoGetInterface(const IID: TGUID; out Obj): HResult; override;
  public
    constructor Create(AManager: TSensorManager; const ANativeSensor: PASensor); reintroduce;
  end;

  TAndroidMagneticSensor = class(TAndroidOrientationSensor)
  protected
    function GetOrientationSensorType: TOrientationSensorType; override;
    function GetAvailableProperties: TCustomOrientationSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomOrientationSensor.TProperty): Double; override;
  end;

  TAndroidRotationSensor = class(TAndroidOrientationSensor)
  protected
    function GetOrientationSensorType: TOrientationSensorType; override;
    function GetAvailableProperties: TCustomOrientationSensor.TProperties;  override;
    function GetDoubleProperty(Prop: TCustomOrientationSensor.TProperty): Double;  override;
  end;

{ Biometric sensors }

  TAndroidProximitySensor = class(TCustomBiometricSensor)
  strict private
    FNativeSensor: TNDKSensor;
  protected
    function GetBiometricSensorType: TBiometricSensorType; override;
    function GetState: TSensorState; override;
    function GetTimeStamp: TDateTime; override;
    function GetAvailableProperties: TCustomBiometricSensor.TProperties; override;
    function GetSensorProperty(Prop: TCustomSensor.TProperty): string; override;
    function GetDoubleProperty(Prop: TCustomBiometricSensor.TProperty): Double; override;
    function DoStart: Boolean; override;
    procedure DoStop; override;
    function DoGetInterface(const IID: TGUID; out Obj): HResult; override;
  public
    constructor Create(AManager: TSensorManager; const ANativeSensor: PASensor); reintroduce;
  end;

{ Light sensors }

  TAndroidLightSensor = class(TCustomLightSensor)
  strict private
    FNativeSensor: TNDKSensor;
  protected
    function GetLightSensorType: TLightSensorType; override;
    function GetAvailableProperties: TCustomLightSensor.TProperties; override;
    function GetDoubleProperty(Prop: TCustomLightSensor.TProperty): Double; override;
    function GetSensorProperty(Prop: TCustomSensor.TProperty): string; override;
    function GetState: TSensorState; override;
    function GetTimeStamp: TDateTime; override;
    function DoStart: Boolean; override;
    procedure DoStop; override;
    function DoGetInterface(const IID: TGUID; out Obj): HResult; override;
  public
    constructor Create(AManager: TSensorManager; const ANativeSensor: PASensor); reintroduce;
  end;

  TAndroidSensorManager = class(TPlatformSensorManager)
  private
    FActive: Boolean;
    FSensorManager: PASensorManager;
  protected
    function GetCanActivate: Boolean; override;
    function GetActive: Boolean; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Activate; override;
    procedure Deactivate; override;
  end;

{ TAndroidSensorManager }

procedure TAndroidSensorManager.Activate;
var
  SensorManager: PASensorManager;
  NativeSensors: ASensorList;
  SensorsCount: Integer;
  Location: TUIAndroidLocationSensor;
  I: Integer;
  Sensor: PASensor;
begin
  if not Active then
  begin
    FActive := True;

    SensorManager := ASensorManager_getInstance;
    SensorsCount := ASensorManager_getSensorList(SensorManager, @NativeSensors);

    for I := 0 to SensorsCount - 1 do
    begin
      Sensor := PASensor(NativeSensors^);
      case ASensor_getType(Sensor) of
        ASENSOR_TYPE_ACCELEROMETER,
        ASENSOR_TYPE_ACCELEROMETER_UNCALIBRATED:
          TAndroidAccelerometrSensor.Create(Self, Sensor);

        ASENSOR_TYPE_GYROSCOPE,
        ASENSOR_TYPE_GYROSCOPE_UNCALIBRATED:
          TAndroidGyroscopeSensor.Create(Self, Sensor);

        ASENSOR_TYPE_LIGHT:
          TAndroidLightSensor.Create(Self, Sensor);

        ASENSOR_TYPE_PRESSURE:
          TAndroidPressureSensor.Create(Self, Sensor);

        ASENSOR_TYPE_MAGNETIC_FIELD,
        ASENSOR_TYPE_MAGNETIC_FIELD_UNCALIBRATED:
          TAndroidMagneticSensor.Create(Self, Sensor);

        ASENSOR_TYPE_PROXIMITY:
          TAndroidProximitySensor.Create(Self, Sensor);

        ASENSOR_TYPE_ROTATION_VECTOR,
        ASENSOR_TYPE_GAME_ROTATION_VECTOR,
        ASENSOR_TYPE_GEOMAGNETIC_ROTATION_VECTOR:
          TAndroidRotationSensor.Create(Self, Sensor);

        ASENSOR_TYPE_AMBIENT_TEMPERATURE:
          TAndroidTemperatureSensor.Create(Self, Sensor);

        ASENSOR_TYPE_RELATIVE_HUMIDITY:
          TAndroidHumiditySensor.Create(Self, Sensor);

        ASENSOR_TYPE_GRAVITY:
          TAndroidGravitySensor.Create(Self, Sensor);

        ASENSOR_TYPE_LINEAR_ACCELERATION:
          TAndroidLinearAccelerometrSensor.Create(Self, Sensor);
      end;
      Inc(NativeSensors);
    end;

    Location := TUIAndroidLocationSensor.Create(Self);
    if not Location.Supported then
      RemoveSensor(Location);
  end;
end;

constructor TAndroidSensorManager.Create;
begin
  inherited;
  FSensorManager := ASensorManager_getInstance;
  FActive := False;
end;

procedure TAndroidSensorManager.Deactivate;
var
  I: Integer;
begin
  FActive := False;
  for I := Count - 1 downto 0 do
    RemoveSensor(Sensors[I]);
end;

destructor TAndroidSensorManager.Destroy;
begin
  inherited;
end;

function TAndroidSensorManager.GetActive: Boolean;
begin
  Result := FActive;
end;

function TAndroidSensorManager.GetCanActivate: Boolean;
begin
  Result := Assigned(FSensorManager);
end;

{ TAndroidCustomSensor }

function TAndroidAccelerometrSensor.GetAvailableProperties: TCustomMotionSensor.TProperties;
begin
  Result := [TCustomMotionSensor.TProperty.AccelerationX, TCustomMotionSensor.TProperty.AccelerationY,
    TCustomMotionSensor.TProperty.AccelerationZ]
end;

function TAndroidAccelerometrSensor.GetDoubleProperty(Prop: TCustomMotionSensor.TProperty): Double;
begin
  case Prop of
    TCustomMotionSensor.TProperty.AccelerationX: Result := -1 * FNativeSensor.LastValue.acceleration.x / ASENSOR_STANDARD_GRAVITY;
    TCustomMotionSensor.TProperty.AccelerationY: Result := -1 * FNativeSensor.LastValue.acceleration.y / ASENSOR_STANDARD_GRAVITY;
    TCustomMotionSensor.TProperty.AccelerationZ: Result := -1 * FNativeSensor.LastValue.acceleration.z / ASENSOR_STANDARD_GRAVITY;
  else
    Result := NaN;
  end;
end;

function TAndroidAccelerometrSensor.GetMotionSensorType: TMotionSensorType;
begin
  Result := TMotionSensorType.Accelerometer3D;
end;

{ TPlatformSensorManager }

class function TPlatformSensorManager.GetSensorManager: TSensorManager;
begin
  Result := TAndroidSensorManager.Create;
end;

{ TPlatformGeocoder }

class function TPlatformGeocoder.GetGeocoderImplementer: TGeocoderClass;
begin
  Result := TAndroidGeocoder;
end;

{ TPlatformGpsStatus }

class function TPlatformGpsStatus.GetGpsStatusImplementer: TGpsStatusClass;
begin
  Result := nil;
end;

{ TAndroidGyroscopeSensor }

function TAndroidGyroscopeSensor.GetAvailableProperties: TCustomMotionSensor.TProperties;
begin
  Result := [TCustomMotionSensor.TProperty.AngleAccelX, TCustomMotionSensor.TProperty.AngleAccelY, TCustomMotionSensor.TProperty.AngleAccelZ];
end;

function TAndroidGyroscopeSensor.GetDoubleProperty(Prop: TCustomMotionSensor.TProperty): Double;
begin
  case Prop of
    TCustomMotionSensor.TProperty.AngleAccelX: Result := FNativeSensor.LastValue.vector.x;
    TCustomMotionSensor.TProperty.AngleAccelY: Result := FNativeSensor.LastValue.vector.y;
    TCustomMotionSensor.TProperty.AngleAccelZ: Result := FNativeSensor.LastValue.vector.z;
  else
    Result := NaN;
  end;
end;

function TAndroidGyroscopeSensor.GetMotionSensorType: TMotionSensorType;
begin
  Result := TMotionSensorType.Gyrometer3D;
end;

{ TNativeSensor }

constructor TNDKSensor.Create(const ANativeSensor: PASensor);
begin
  if ANativeSensor = nil then
    raise EArgumentException.CreateResFmt(@SParamIsNil, ['ANativeSensor']);

  FSensorType := ASensor_getType(ANativeSensor);
  FSensorManager := ASensorManager_getInstance;
  FNativeSensor := ANativeSensor;
  FNativeEventQueue := ASensorManager_createEventQueue(FSensorManager, ALooper_forThread, LOOPER_ID_USER, nil, nil);
  if FNativeEventQueue = nil then
    raise EArgumentException.CreateResFmt(@SParamIsNil, ['FNativeEventQueue']);
  UpdateInterval := 1000;
  FillChar(FLastSensorEvent, SizeOf(ASensorEvent), 0);
end;

destructor TNDKSensor.Destroy;
begin
  ASensorManager_destroyEventQueue(FSensorManager, FNativeEventQueue);
  inherited;
end;

function TNDKSensor.Start: Boolean;
begin
  FEnabled := ASensorEventQueue_enableSensor(FNativeEventQueue, FNativeSensor) = 0;
  ASensorEventQueue_setEventRate(FNativeEventQueue, FNativeSensor, Round(FUpdateInterval));
  Result := FEnabled;
end;

procedure TNDKSensor.Stop;
begin
  ASensorEventQueue_disableSensor(FNativeEventQueue,FNativeSensor);
  FEnabled := False;
end;

function TNDKSensor.LastValue: ASensorEvent;
var
  SensorEvent: ASensorEvent;
begin
  while ASensorEventQueue_getEvents(FNativeEventQueue, @SensorEvent,1) > 0 do
    FLastSensorEvent := SensorEvent;
  Result := FLastSensorEvent;
end;

function TNDKSensor.Manufacturer: string;
begin
  Result := string(ASensor_getVendor(FNativeSensor));
end;

function TNDKSensor.Name: string;
begin
  Result := string(ASensor_getName(FNativeSensor));
end;

function TNDKSensor.NativeEventQueue: PASensorEventQueue;
begin
  Result := FNativeEventQueue;
end;

function TNDKSensor.Sensor: PASensor;
begin
  Result := FNativeSensor;
end;

function TNDKSensor.SensorManager: PASensorManager;
begin
  Result := FSensorManager;
end;

function TNDKSensor.SensorType: Integer;
begin
  Result := FSensorType;
end;

procedure TNDKSensor.SetUpdateInterval(const Value: Double);
begin
  FUpdateInterval := Value;
  if FEnabled then
    ASensorEventQueue_setEventRate(FNativeEventQueue, FNativeSensor, Round(FUpdateInterval));
end;

function TNDKSensor.TimeStamp: Double;
const
  TimeScale = 1000000;
begin
  Result := IncMilliSecond(UnixDateDelta, LastValue.timestamp div TimeScale);
end;

{ TAndroidLightSensor }

constructor TAndroidLightSensor.Create(AManager: TSensorManager; const ANativeSensor: PASensor);
begin
  inherited Create(AManager);
  FNativeSensor := TNDKSensor.Create(ANativeSensor);
end;

function TAndroidLightSensor.DoGetInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := FNativeSensor.QueryInterface(IID, Obj);
end;

function TAndroidLightSensor.DoStart: Boolean;
begin
  Result := FNativeSensor.Start;
end;

procedure TAndroidLightSensor.DoStop;
begin
  inherited;
  FNativeSensor.Stop;
end;

function TAndroidLightSensor.GetAvailableProperties: TCustomLightSensor.TProperties;
begin
  Result := [TCustomLightSensor.TProperty.Lux];
end;

function TAndroidLightSensor.GetDoubleProperty(Prop: TCustomLightSensor.TProperty): Double;
begin
  case Prop of
    TCustomLightSensor.TProperty.Lux: Result := FNativeSensor.LastValue.light;
  else
    Result := NaN;
  end;
end;

function TAndroidLightSensor.GetLightSensorType: TLightSensorType;
begin
  Result := TLightSensorType.AmbientLight;
end;

function TAndroidLightSensor.GetSensorProperty(Prop: TCustomSensor.TProperty): string;
begin
  case Prop of
    TCustomSensor.TProperty.Manufacturer:
      Result := FNativeSensor.Manufacturer;
    TCustomSensor.TProperty.Name:
      Result := FNativeSensor.Name;
  else
    Result := string.Empty;
  end;
end;

function TAndroidLightSensor.GetState: TSensorState;
begin
  if FNativeSensor.Enabled then
    Result := TSensorState.Ready
  else
    Result := TSensorState.NoData;
end;

function TAndroidLightSensor.GetTimeStamp: TDateTime;
begin
  Result := FNativeSensor.TimeStamp;
end;

{ TAndroidPressureSensor }

function TAndroidPressureSensor.GetAvailableProperties: TCustomEnvironmentalSensor.TProperties;
begin
  Result := [TCustomEnvironmentalSensor.TProperty.Pressure];
end;

function TAndroidPressureSensor.GetDoubleProperty(Prop: TCustomEnvironmentalSensor.TProperty): Double;
begin
  case Prop of
    //  Atmospheric pressure in hPa (millibar)
    TCustomEnvironmentalSensor.TProperty.Pressure: Result := FNativeSensor.LastValue.pressure;
  else
    Result := NaN;
  end;
end;

function TAndroidPressureSensor.GetEnvironmentalSensorType: TEnvironmentalSensorType;
begin
  Result := TEnvironmentalSensorType.AtmosphericPressure;
end;

{ TAndroidMagneticSensor }

function TAndroidMagneticSensor.GetAvailableProperties: TCustomOrientationSensor.TProperties;
begin
  Result := [TCustomOrientationSensor.TProperty.HeadingX, TCustomOrientationSensor.TProperty.HeadingY,
    TCustomOrientationSensor.TProperty.HeadingZ];
end;

function TAndroidMagneticSensor.GetDoubleProperty(Prop: TCustomOrientationSensor.TProperty): Double;
begin
  case Prop of
    // All values are in micro-Tesla (uT) and measure the ambient magnetic field in the X, Y and Z axis.
    TCustomOrientationSensor.TProperty.HeadingX: Result := FNativeSensor.LastValue.magnetic.x;
    TCustomOrientationSensor.TProperty.HeadingY: Result := FNativeSensor.LastValue.magnetic.y;
    TCustomOrientationSensor.TProperty.HeadingZ: Result := FNativeSensor.LastValue.magnetic.z;
  else
    Result := NaN;
  end;
end;

function TAndroidMagneticSensor.GetOrientationSensorType: TOrientationSensorType;
begin
  Result := TOrientationSensorType.Compass3D;
end;

{ TAndroidProximitySensor }

constructor TAndroidProximitySensor.Create(AManager: TSensorManager; const ANativeSensor: PASensor);
begin
  inherited Create(AManager);
  FNativeSensor := TNDKSensor.Create(ANativeSensor);
end;

function TAndroidProximitySensor.DoGetInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := FNativeSensor.QueryInterface(IID, Obj);
end;

function TAndroidProximitySensor.DoStart: Boolean;
begin
  Result := FNativeSensor.Start;
end;

procedure TAndroidProximitySensor.DoStop;
begin
  inherited;
  FNativeSensor.Stop;
end;

function TAndroidProximitySensor.GetAvailableProperties: TCustomBiometricSensor.TProperties;
begin
  Result := [TCustomBiometricSensor.TProperty.HumanProximity];
end;

function TAndroidProximitySensor.GetBiometricSensorType: TBiometricSensorType;
begin
  Result := TBiometricSensorType.HumanProximity;
end;

function TAndroidProximitySensor.GetDoubleProperty(
  Prop: TCustomBiometricSensor.TProperty): Double;
begin
  case Prop of
    // Proximity sensor distance measured in centimeters
    TCustomBiometricSensor.TProperty.HumanProximity:
    begin
      Result := FNativeSensor.LastValue.distance;
    end;
  else
    Result := NaN;
  end;
end;

function TAndroidProximitySensor.GetSensorProperty(Prop: TCustomSensor.TProperty): string;
begin
  case Prop of
    TCustomSensor.TProperty.Manufacturer:
      Result := FNativeSensor.Manufacturer;
    TCustomSensor.TProperty.Name:
      Result := FNativeSensor.Name;
  else
    Result := string.Empty;
  end;
end;

function TAndroidProximitySensor.GetState: TSensorState;
begin
  if FNativeSensor.Enabled then
    Result := TSensorState.Ready
  else
    Result := TSensorState.NoData;
end;

function TAndroidProximitySensor.GetTimeStamp: TDateTime;
begin
  Result := FNativeSensor.TimeStamp;
end;

{ TAndroidNativeRotationSensor }

function TAndroidRotationSensor.GetAvailableProperties: TCustomOrientationSensor.TProperties;
begin
  Result := [TCustomOrientationSensor.TProperty.TiltX, TCustomOrientationSensor.TProperty.TiltY, TCustomOrientationSensor.TProperty.TiltZ];
end;

function TAndroidRotationSensor.GetDoubleProperty(Prop: TCustomOrientationSensor.TProperty): Double;
var
  Tilts: ASensorVector;

  function VectorToAngles(const RotationVector: ASensorVector): ASensorVector;
  var
    RM: array[0..8] of Double;
    Len: Double;
    sqX, sqY, sqZ, qXY, qZL, qXZ, qYL, qYZ, qXL: Double;
  begin
    sqX := RotationVector.x * RotationVector.x;
    sqY := RotationVector.y * RotationVector.y;
    sqZ := RotationVector.z * RotationVector.z;
    Len := 1 - sqX - sqY - sqZ;
    if Len > 0 then
      Len := Sqrt(Len)
    else
      Len := 0;
    sqX := 2 * sqX;
    sqY := 2 * sqY;
    sqZ := 2 * sqZ;
    qXY := 2 * RotationVector.x * RotationVector.y;
    qZL := 2 * RotationVector.z * Len;
    qXZ := 2 * RotationVector.x * RotationVector.z;
    qYL := 2 * RotationVector.y * Len;
    qYZ := 2 * RotationVector.y * RotationVector.z;
    qXL := 2 * RotationVector.x * Len;

    RM[0] := 1 - sqY - sqZ;
    RM[1] := qXY - qZL;
    RM[2] := qXZ + qYL;

    RM[3] := qXY + qZL;
    RM[4] := 1 - sqX - sqZ;
    RM[5] := qYZ - qXL;

    RM[6] := qXZ - qYL;
    RM[7] := qYZ + qXL;
    RM[8] := 1 - sqX - sqY;

    Result.azimuth := RadToDeg(ArcTan2( RM[1], RM[4]));
    Result.pitch := RadToDeg(ArcCos( - RM[7]) - Pi / 2);
    Result.roll := RadToDeg(ArcTan2( - RM[6], RM[8]));
  end;

begin
  Tilts := VectorToAngles(FNativeSensor.LastValue.vector);
  case Prop of
    TCustomOrientationSensor.TProperty.TiltX: Result := Tilts.roll;
    TCustomOrientationSensor.TProperty.TiltY: Result := Tilts.pitch;
    TCustomOrientationSensor.TProperty.TiltZ: Result := Tilts.azimuth;
  else
    Result := NaN;
  end;
end;

function TAndroidRotationSensor.GetOrientationSensorType: TOrientationSensorType;
begin
  Result := TOrientationSensorType.Inclinometer3D;
end;

{ TAndroidTemperatureSensor }

function TAndroidTemperatureSensor.GetAvailableProperties: TCustomEnvironmentalSensor.TProperties;
begin
  Result := [TCustomEnvironmentalSensor.TProperty.Temperature];
end;

function TAndroidTemperatureSensor.GetDoubleProperty(Prop: TCustomEnvironmentalSensor.TProperty): Double;
begin
  case Prop of
    // ambient (room) temperature in degree Celsius
    TCustomEnvironmentalSensor.TProperty.Temperature: Result := FNativeSensor.LastValue.temperature;
  else
    Result := NaN;
  end;
end;

function TAndroidTemperatureSensor.GetEnvironmentalSensorType: TEnvironmentalSensorType;
begin
  Result := TEnvironmentalSensorType.Temperature;
end;

{ TAndroidHumiditySensor }

function TAndroidHumiditySensor.GetAvailableProperties: TCustomEnvironmentalSensor.TProperties;
begin
  Result := [TCustomEnvironmentalSensor.TProperty.Humidity];
end;

function TAndroidHumiditySensor.GetDoubleProperty(Prop: TCustomEnvironmentalSensor.TProperty): Double;
begin
  case Prop of
    // Relative ambient air humidity in percent
    TCustomEnvironmentalSensor.TProperty.Humidity: Result := FNativeSensor.LastValue.vector.v[0];
  else
    Result := NaN;
  end;
end;

function TAndroidHumiditySensor.GetEnvironmentalSensorType: TEnvironmentalSensorType;
begin
  Result := TEnvironmentalSensorType.Humidity;
end;

{ TAndroidGravitySensor }

function TAndroidGravitySensor.GetAvailableProperties: TCustomMotionSensor.TProperties;
begin
  Result := [TCustomMotionSensor.TProperty.AccelerationX, TCustomMotionSensor.TProperty.AccelerationY,
    TCustomMotionSensor.TProperty.AccelerationZ]
end;

function TAndroidGravitySensor.GetDoubleProperty(Prop: TCustomMotionSensor.TProperty): Double;
begin
  case Prop of
    TCustomMotionSensor.TProperty.AccelerationX: Result := -1 * FNativeSensor.LastValue.acceleration.x / ASENSOR_STANDARD_GRAVITY;
    TCustomMotionSensor.TProperty.AccelerationY: Result := -1 * FNativeSensor.LastValue.acceleration.y / ASENSOR_STANDARD_GRAVITY;
    TCustomMotionSensor.TProperty.AccelerationZ: Result := -1 * FNativeSensor.LastValue.acceleration.z / ASENSOR_STANDARD_GRAVITY;
  else
    Result := NaN;
  end;
end;

function TAndroidGravitySensor.GetMotionSensorType: TMotionSensorType;
begin
  Result := TMotionSensorType.GravityAccelerometer3D;
end;

{ TAndroidLinearAccelerometrSensor }

function TAndroidLinearAccelerometrSensor.GetAvailableProperties: TCustomMotionSensor.TProperties;
begin
  Result := [TCustomMotionSensor.TProperty.AccelerationX, TCustomMotionSensor.TProperty.AccelerationY,
    TCustomMotionSensor.TProperty.AccelerationZ]
end;

function TAndroidLinearAccelerometrSensor.GetDoubleProperty(Prop: TCustomMotionSensor.TProperty): Double;
begin
  case Prop of
    TCustomMotionSensor.TProperty.AccelerationX: Result := -1 * FNativeSensor.LastValue.acceleration.x / ASENSOR_STANDARD_GRAVITY;
    TCustomMotionSensor.TProperty.AccelerationY: Result := -1 * FNativeSensor.LastValue.acceleration.y / ASENSOR_STANDARD_GRAVITY;
    TCustomMotionSensor.TProperty.AccelerationZ: Result := -1 * FNativeSensor.LastValue.acceleration.z / ASENSOR_STANDARD_GRAVITY;
  else
    Result := NaN;
  end;
end;

function TAndroidLinearAccelerometrSensor.GetMotionSensorType: TMotionSensorType;
begin
  Result := TMotionSensorType.LinearAccelerometer3D;
end;

{ TUIAndroidLocationSensor.TLocationListener }

constructor TUIAndroidLocationSensor.TLocationListener.Create(ALocationSensor: TUIAndroidLocationSensor);
begin
  inherited Create;
  FLocationSensor := ALocationSensor;
end;

procedure TUIAndroidLocationSensor.TLocationListener.onFlushComplete(requestCode: Integer);
begin
end;

procedure TUIAndroidLocationSensor.TLocationListener.onLocationChanged(location: JLocation);
var
  OldLocation, CurrentLocation: TLocationCoord2D;
  Heading: THeading;
begin
  if Assigned(FLocationSensor.FLastValue) then
    OldLocation.Create(FLocationSensor.FLastValue.getLatitude, FLocationSensor.FLastValue.getLongitude)
  else
    OldLocation.Create(NaN,NaN);
  CurrentLocation.Create(location.getLatitude, location.getLongitude);
  FLocationSensor.FLastValue := location;
  FLocationSensor.DoLocationChanged(OldLocation, CurrentLocation);
  if location.hasBearing then
  begin
    Heading.Azimuth := location.getBearing;
    FLocationSensor.DoHeadingChanged(Heading);
  end;
end;

procedure TUIAndroidLocationSensor.TLocationListener.onLocationChanged(locations: JList);
var
  I: Integer;
begin
  for I := 0 to locations.size - 1 do
    onLocationChanged(TJLocation.Wrap(locations.get(I)));
end;

procedure TUIAndroidLocationSensor.TLocationListener.onProviderDisabled(provider: JString);
begin
end;

procedure TUIAndroidLocationSensor.TLocationListener.onProviderEnabled(provider: JString);
begin
end;

procedure TUIAndroidLocationSensor.TLocationListener.onStatusChanged(provider: JString; status: Integer; extras: JBundle);
begin
end;

// ojo aquí: procedures agregados
procedure TUIAndroidLocationSensor.TLocationListener.onLocationChanged(P1: JObject);
begin
  if TJNIResolver.IsInstanceOf(P1, TJArrayList.GetClsID) then
    onLocationChanged(TJArrayList.Wrap(P1))
  else if TJNIResolver.IsInstanceOf(P1, TJLocation.GetClsID) then
    onLocationChanged(TJLocation.Wrap(P1));
end;

procedure TUIAndroidLocationSensor.TLocationListener.onLocationChanged(P1: JArrayList);
begin
  onLocationChanged(TJLocation.Wrap(P1.get(P1.size-1)))
end;

{ TUIAndroidLocationSensor.TLocationRunnable }

constructor TUIAndroidLocationSensor.TLocationRunnable.Create(ALocationManager: JLocationManager; AListener: TLocationListener;
  AProvider: JString);
begin
  Inherited Create;
  FLocationManager := ALocationManager;
  FListener := AListener;
  FProvider := AProvider;
end;

procedure TUIAndroidLocationSensor.TLocationRunnable.run;
const
  cMinTime = 100;
  cMinDistance = 10;
begin
  FLocationManager.requestLocationUpdates( FProvider, cMinTime, cMinDistance, FListener);
end;

{ TUIAndroidLocationSensor }

constructor TUIAndroidLocationSensor.Create(AManager: TSensorManager);
begin
  inherited;
  FLocationManager := TJLocationManager.Wrap(TAndroidHelper.Context.getSystemService(TJContext.JavaClass.LOCATION_SERVICE));
  FLocationListeners := TInterfaceHolder.Create(Self);
end;

function TUIAndroidLocationSensor.DoGetInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := E_NOTIMPL;
  if FLastValue <> nil then
    Result := FLastValue.QueryInterface(IID, Obj);
  if (Result <> S_OK) and (FLocationManager <> nil) then
    Result := FLocationManager.QueryInterface(IID, Obj);
  if (Result <> S_OK) then
    Result := FLocationListeners.QueryInterface(IID, Obj);
end;

procedure TUIAndroidLocationSensor.DoLocationChangeType;
begin
  inherited;
end;

procedure TUIAndroidLocationSensor.DoOptimize;
begin

end;

function TUIAndroidLocationSensor.DoStart: Boolean;

  function RunIfPossible(var ARunnable: TLocationRunnable; var AListener: TLocationListener; AProviderName: JString):
    Boolean;
  var
    Provider: JLocationProvider;
    Handler: JHandler;
  begin
    Result := False;
    if FLocationManager.isProviderEnabled(AProviderName) then
    begin
      if AListener = nil then
        AListener := TLocationListener.Create(Self);
      Provider := FLocationManager.getProvider(AProviderName);
      if Provider <> nil then
      begin
        ARunnable := TLocationRunnable.Create(FLocationManager, AListener, AProviderName);
        if System.DelphiActivity <> nil then
          TAndroidHelper.Activity.runOnUiThread(ARunnable)
        else
        begin
          Handler := TJHandler.JavaClass.init;
          Handler.post(ARunnable);
        end;
        Result := True;
      end;
    end;
  end;

  function RunTheBestProvider(var ARunnable: TLocationRunnable; var AListener: TLocationListener):Boolean;
  var
    Criteria: JCriteria;
    ProviderName: JString;
  begin
    Result := False;
    Criteria := TJCriteria.JavaClass.init;
    case Round(FAccuracy) of
      0..100:
        Criteria.setHorizontalAccuracy(TJCriteria.JavaClass.ACCURACY_HIGH);
      101..500:
        Criteria.setHorizontalAccuracy(TJCriteria.JavaClass.ACCURACY_MEDIUM);
    else
      Criteria.setHorizontalAccuracy(TJCriteria.JavaClass.ACCURACY_LOW);
    end;

    ProviderName := FLocationManager.getBestProvider(Criteria, True);

    if ProviderName <> nil then
      Result := RunIfPossible(ARunnable, AListener, ProviderName);
  end;

var
  GPSStarted, NetworkStarted, PassiveStarted: Boolean;

begin
  Result := False;
  FPermitted := TPermissionsService.DefaultService.IsPermissionGranted(JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION));
  if FPermitted then
  begin
    if FAccuracy > 0 then
      Result := RunTheBestProvider(FPassiveRunner, FPassiveListener)
    else
    begin
      GPSStarted := RunIfPossible(FGPSRunner, FGPSListener, TJLocationManager.JavaClass.GPS_PROVIDER);
      NetworkStarted := RunIfPossible(FNetworkRunner, FNetworkListener, TJLocationManager.JavaClass.NETWORK_PROVIDER);
      PassiveStarted := RunIfPossible(FPassiveRunner, FPassiveListener, TJLocationManager.JavaClass.PASSIVE_PROVIDER);
      Result := GPSStarted or NetworkStarted or PassiveStarted;
    end;
  end;
end;

procedure TUIAndroidLocationSensor.DoStop;
begin
  inherited;
  if FPassiveListener <> nil then
    FLocationManager.removeUpdates(FPassiveListener);
  if FNetworkListener <> nil then
    FLocationManager.removeUpdates(FNetworkListener);
  if FGPSListener <> nil then
    FLocationManager.removeUpdates(FGPSListener);
end;

function TUIAndroidLocationSensor.GetAccuracy: TLocationAccuracy;
begin
  Result := FAccuracy;
end;

function TUIAndroidLocationSensor.GetActivityType: TLocationActivityType;
begin
  Result := FActivityType;
end;

function TUIAndroidLocationSensor.GetAuthorized: TAuthorizationType;
begin
  Result := TAuthorizationType.atNotSpecified;
end;

function TUIAndroidLocationSensor.GetAvailableProperties: TCustomLocationSensor.TProperties;
begin
  Result := [TCustomLocationSensor.TProperty.Latitude,
    TCustomLocationSensor.TProperty.Longitude, TCustomLocationSensor.TProperty.Altitude,
    TCustomLocationSensor.TProperty.Speed, TCustomLocationSensor.TProperty.TrueHeading];

end;

function TUIAndroidLocationSensor.GetDistance: TLocationDistance;
begin
  Result := FDistance;
end;

function TUIAndroidLocationSensor.GetDoubleProperty(Prop: TCustomLocationSensor.TProperty): Double;
begin
  Result := NaN;
  if Assigned(FLastValue) then
    case Prop of
      TCustomLocationSensor.TProperty.Latitude: Result := FLastValue.getLatitude;
      TCustomLocationSensor.TProperty.Longitude: Result := FLastValue.getLongitude ;
      TCustomLocationSensor.TProperty.Altitude:
        if FLastValue.hasAltitude then
          Result := FLastValue.getAltitude;
      TCustomLocationSensor.TProperty.Speed:
        if FLastValue.hasSpeed then
          Result := FLastValue.getSpeed;
      TCustomLocationSensor.TProperty.TrueHeading:
        if FLastValue.hasBearing then
          Result := FLastValue.getBearing;
    else
      Result := NaN;
    end;
end;

function TUIAndroidLocationSensor.GetLocationSensorType: TLocationSensorType;
begin
  Result := TLocationSensorType.GPS;
end;

function TUIAndroidLocationSensor.GetPowerConsumption: TPowerConsumption;
begin
  Result := TPowerConsumption.pcNotSpecified;
end;

function TUIAndroidLocationSensor.GetState: TSensorState;
begin
  if Supported then
  begin
    FPermitted := TPermissionsService.DefaultService.IsPermissionGranted(JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION));
    if FPermitted then
      Result := TSensorState.Ready
    else
      Result := TSensorState.AccessDenied
  end
  else
    Result := TSensorState.NoData;
end;

function TUIAndroidLocationSensor.GetStringProperty(Prop: TCustomLocationSensor.TProperty): string;
begin
  Result := '';
end;

function TUIAndroidLocationSensor.GetTimeStamp: TDateTime;
begin
  if Assigned(FLastValue) then
    Result := IncMilliSecond(UnixDateDelta, FLastValue.getTime)
  else
    Result := 0;
end;

function TUIAndroidLocationSensor.GetUsageAuthorization: TLocationUsageAuthorization;
begin
  Result := FUsageAuthorization;
end;

procedure TUIAndroidLocationSensor.SetAccuracy(const Value: TLocationAccuracy);
begin
  inherited;
  FAccuracy := Max(0, Value);
end;

procedure TUIAndroidLocationSensor.SetActivityType(const Value: TLocationActivityType);
begin
  FActivityType := Value;
end;

procedure TUIAndroidLocationSensor.SetDistance(const Value: TLocationDistance);
begin
  inherited;
  FDistance := Value;
end;

procedure TUIAndroidLocationSensor.SetUsageAuthorization(const Value: TLocationUsageAuthorization);
begin
  FUsageAuthorization := Value;
end;

function TUIAndroidLocationSensor.Supported: Boolean;
begin
  Result := Assigned(FLocationManager);
end;

{ TAndroidGeocoder }

class function TAndroidGeocoder.Authorized: TAuthorizationType;
begin
  Result := TAuthorizationType.atNotSpecified;
end;

class procedure TAndroidGeocoder.Cancel;
begin
;
end;

class constructor TAndroidGeocoder.Create;
begin
  FGeocoder := TJGeocoder.JavaClass.init(TAndroidHelper.Context);
end;

class destructor TAndroidGeocoder.Destroy;
begin

end;

class procedure TAndroidGeocoder.GeocodeRequest(const AAddress: TCivicAddress);
var
  I: Integer;
  List: JList;
  LAddress: JAddress;
  JO: JObject;
begin
  List := FGeocoder.getFromLocationName(StringToJString(AAddress.ToString), 10);
  SetLength(FGeoFwdCoords, List.size);
  for I := 0 to List.size - 1 do
  begin
    JO := List.get(I);
    LAddress := TJAddress.Wrap(JO);
    FGeoFwdCoords[I] := TLocationCoord2D.Create(LAddress.getLatitude, LAddress.getLongitude);
  end;
  DoGeocode(FGeoFwdCoords);
end;

class procedure TAndroidGeocoder.GeocodeReverseRequest(const Coords: TLocationCoord2D);
var
  List: JList;
  LAddress: JAddress;
  Addr: TCivicAddress;
  JO: JObject;
  I: Integer;
begin
  List := FGeocoder.getFromLocation(Coords.Latitude, Coords.Longitude, 10);
  if List.size = 0 then
    Addr := nil
  else
  begin
    Addr := FGeoRevAddress;
    Addr.Reset;
    for I := 0 to List.size - 1 do
    begin
      JO := List.get(I);
      LAddress := TJAddress.Wrap(JO);
      if string.IsNullOrEmpty(Addr.AdminArea) then
        Addr.AdminArea       := JStringToString(LAddress.getAdminArea);
      if string.IsNullOrEmpty(Addr.CountryName) then
        Addr.CountryName     := JStringToString(LAddress.getCountryName);
      if string.IsNullOrEmpty(Addr.CountryCode) then
        Addr.CountryCode     := JStringToString(LAddress.getCountryCode);
      if string.IsNullOrEmpty(Addr.Locality) then
        Addr.Locality        := JStringToString(LAddress.getLocality);
      if string.IsNullOrEmpty(Addr.FeatureName) then
        Addr.FeatureName     := JStringToString(LAddress.getFeatureName);
      if string.IsNullOrEmpty(Addr.PostalCode) then
        Addr.PostalCode      := JStringToString(LAddress.getPostalCode);
      if string.IsNullOrEmpty(Addr.SubAdminArea) then
        Addr.SubAdminArea    := JStringToString(LAddress.getAdminArea);
      if string.IsNullOrEmpty(Addr.SubLocality) then
        Addr.SubLocality     := JStringToString(LAddress.getSubLocality);
      if string.IsNullOrEmpty(Addr.SubThoroughfare) then
        Addr.SubThoroughfare := JStringToString(LAddress.getSubThoroughfare);
      if string.IsNullOrEmpty(Addr.Thoroughfare) then
        Addr.Thoroughfare    := JStringToString(LAddress.getThoroughfare);
    end;
  end;
  DoGeocodeReverse(Addr);
end;

class function TAndroidGeocoder.GetGeocoderImplementer: TGeocoderClass;
begin
  Result := Self;
end;

class function TAndroidGeocoder.Supported: Boolean;
begin
  Result := False;
  if Assigned(FGeocoder) then
    Result := TjGeocoder.JavaClass.isPresent;
end;

{ TUIAndroidLocationSensor.TInterfaceHolder }

constructor TUIAndroidLocationSensor.TInterfaceHolder.Create(
  const ALocationSensor: TUIAndroidLocationSensor);
begin
  FLocationSensor := ALocationSensor;
end;

function TUIAndroidLocationSensor.TInterfaceHolder.GetGPSListener: JLocationListener;
begin
  Result := FLocationSensor.FGPSListener;
end;

function TUIAndroidLocationSensor.TInterfaceHolder.GetNetworkListener: JLocationListener;
begin
  Result := FLocationSensor.FNetworkListener;
end;

function TUIAndroidLocationSensor.TInterfaceHolder.GetPassiveListener: JLocationListener;
begin
  Result := FLocationSensor.FPassiveListener;
end;

{ TAndroidEnvironmentalSensor }

constructor TAndroidEnvironmentalSensor.Create(AManager: TSensorManager; const ANativeSensor: PASensor);
begin
  inherited Create(AManager);
  FNativeSensor := TNDKSensor.Create(ANativeSensor);
end;

function TAndroidEnvironmentalSensor.DoGetInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := FNativeSensor.QueryInterface(IID, Obj);
end;

function TAndroidEnvironmentalSensor.DoStart: Boolean;
begin
  Result := FNativeSensor.Start;
end;

procedure TAndroidEnvironmentalSensor.DoStop;
begin
  inherited;
  FNativeSensor.Stop;
end;

function TAndroidEnvironmentalSensor.GetSensorProperty(Prop: TCustomSensor.TProperty): string;
begin
  case Prop of
    TCustomSensor.TProperty.Manufacturer:
      Result := FNativeSensor.Manufacturer;
    TCustomSensor.TProperty.Name:
      Result := FNativeSensor.Name;
  else
    Result := string.Empty;
  end;
end;

function TAndroidEnvironmentalSensor.GetState: TSensorState;
begin
  if FNativeSensor.Enabled then
    Result := TSensorState.Ready
  else
    Result := TSensorState.NoData;
end;

function TAndroidEnvironmentalSensor.GetTimeStamp: TDateTime;
begin
  Result := FNativeSensor.TimeStamp;
end;

{ TAndroidMotionSensor }

constructor TAndroidMotionSensor.Create(AManager: TSensorManager; const ANativeSensor: PASensor);
begin
  inherited Create(AManager);
  FNativeSensor := TNDKSensor.Create(ANativeSensor);
end;

function TAndroidMotionSensor.DoGetInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := FNativeSensor.QueryInterface(IID, Obj);
end;

function TAndroidMotionSensor.DoStart: Boolean;
begin
  Result := FNativeSensor.Start;
end;

procedure TAndroidMotionSensor.DoStop;
begin
  inherited;
  FNativeSensor.Stop;
end;

function TAndroidMotionSensor.GetSensorProperty(Prop: TCustomSensor.TProperty): string;
begin
  case Prop of
    TCustomSensor.TProperty.Manufacturer:
      Result := FNativeSensor.Manufacturer;
    TCustomSensor.TProperty.Name:
      Result := FNativeSensor.Name;
  else
    Result := string.Empty;
  end;
end;

function TAndroidMotionSensor.GetState: TSensorState;
begin
  if FNativeSensor.Enabled then
    Result := TSensorState.Ready
  else
    Result := TSensorState.NoData;
end;

function TAndroidMotionSensor.GetTimeStamp: TDateTime;
begin
  Result := FNativeSensor.TimeStamp;
end;

function TAndroidMotionSensor.GetUpdateInterval: Double;
begin
  Result := FNativeSensor.UpdateInterval;
end;

procedure TAndroidMotionSensor.SetUpdateInterval(AInterval: Double);
begin
  inherited;
  FNativeSensor.UpdateInterval := AInterval;
end;

{ TAndroidOrientationSensor }

constructor TAndroidOrientationSensor.Create(AManager: TSensorManager; const ANativeSensor: PASensor);
begin
  inherited Create(AManager);
  FNativeSensor := TNDKSensor.Create(ANativeSensor);
end;

function TAndroidOrientationSensor.DoGetInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := FNativeSensor.QueryInterface(IID, Obj);
end;

function TAndroidOrientationSensor.DoStart: Boolean;
begin
  Result := FNativeSensor.Start;
end;

procedure TAndroidOrientationSensor.DoStop;
begin
  inherited;
  FNativeSensor.Stop;
end;

function TAndroidOrientationSensor.GetSensorProperty(Prop: TCustomSensor.TProperty): string;
begin
  case Prop of
    TCustomSensor.TProperty.Manufacturer:
      Result := FNativeSensor.Manufacturer;
    TCustomSensor.TProperty.Name:
      Result := FNativeSensor.Name;
  else
    Result := string.Empty;
  end;
end;

function TAndroidOrientationSensor.GetState: TSensorState;
begin
  if FNativeSensor.Enabled then
    Result := TSensorState.Ready
  else
    Result := TSensorState.NoData;
end;

function TAndroidOrientationSensor.GetTimeStamp: TDateTime;
begin
  Result := FNativeSensor.TimeStamp;
end;

function TAndroidOrientationSensor.GetUpdateInterval: Double;
begin
  Result := FNativeSensor.UpdateInterval;
end;

procedure TAndroidOrientationSensor.SetUpdateInterval(AInterval: Double);
begin
  inherited;
  FNativeSensor.UpdateInterval := AInterval;
end;

end.
