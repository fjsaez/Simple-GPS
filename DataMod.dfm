object DMod: TDMod
  OnCreate = DataModuleCreate
  Height = 239
  Width = 438
  object FDConn: TFDConnection
    ConnectionName = 'Conex'
    Params.Strings = (
      
        'Database=D:\Users\Francisco S'#225'ez\Documents\Embarcadero\Studio\Pr' +
        'ojects\APLICACIONES ANDROID\Simple GPS\Database\DBSimpleGPS.db'
      'DriverID=SQLite')
    FormatOptions.AssignedValues = [fvFmtDisplayDate]
    FormatOptions.FmtDisplayDate = 'dd/MM/yyyy'
    Connected = True
    LoginPrompt = False
    Left = 96
    Top = 64
  end
  object FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink
    Left = 216
    Top = 64
  end
end
