object FrmLarGridPivotGestionDemo: TFrmLarGridPivotGestionDemo
  Left = 0
  Top = 0
  Caption = 'LarGridPivot - conexi'#243'n Firebird / Gesti'#243'n'
  ClientHeight = 681
  ClientWidth = 1264
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  Position = poScreenCenter
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1264
    Height = 42
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object edAnio: TEdit
      Left = 8
      Top = 8
      Width = 70
      Height = 21
      TabOrder = 0
      Text = '2026'
    end
    object edMes: TEdit
      Left = 86
      Top = 8
      Width = 45
      Height = 21
      TabOrder = 1
      Text = '0'
    end
    object btnAbrirVentas: TButton
      Left = 140
      Top = 7
      Width = 110
      Height = 27
      Caption = 'Abrir ventas'
      TabOrder = 2
      OnClick = AbrirDatos
    end
    object cbEstilo: TComboBox
      Left = 260
      Top = 8
      Width = 150
      Height = 21
      Style = csDropDownList
      TabOrder = 3
      OnChange = CambiarEstilo
    end
    object btnCampos: TButton
      Left = 420
      Top = 7
      Width = 115
      Height = 27
      Caption = 'Ocultar campos'
      TabOrder = 4
      OnClick = AlternarCampos
    end
    object cbVistas: TComboBox
      Left = 545
      Top = 8
      Width = 150
      Height = 21
      TabOrder = 5
      OnChange = CargarVista
    end
    object btnGuardarVista: TButton
      Left = 700
      Top = 7
      Width = 95
      Height = 27
      Caption = 'Guardar vista'
      TabOrder = 6
      OnClick = GuardarVista
    end
    object btnBorrarVista: TButton
      Left = 800
      Top = 7
      Width = 85
      Height = 27
      Caption = 'Borrar vista'
      TabOrder = 7
      OnClick = BorrarVista
    end
    object lblStatus: TLabel
      Left = 895
      Top = 13
      Width = 165
      Height = 13
      Caption = 'Gesti'#243'n local: GESTIONV3.FDB'
    end
  end
  object LarGridPivot1: TLarGridPivot
    Left = 0
    Top = 42
    Width = 1264
    Height = 639
    Align = alClient
    DataSource = DataSource1
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Theme = ptVclStyle
    TabOrder = 1
  end
  object FDConnection1: TFDConnection
    LoginPrompt = False
    Left = 48
    Top = 88
  end
  object FDQuery1: TFDQuery
    Connection = FDConnection1
    Left = 136
    Top = 88
  end
  object DataSource1: TDataSource
    DataSet = FDQuery1
    Left = 224
    Top = 88
  end
end
