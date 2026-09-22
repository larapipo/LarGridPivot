object FrmLarGridPivotDemo: TFrmLarGridPivotDemo
  Left = 0
  Top = 0
  Caption = 'LarGridPivot v1 - Pivot interactivo'
  ClientHeight = 661
  ClientWidth = 1304
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
    Width = 1304
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnSaveLayout: TButton
      Left = 8
      Top = 6
      Width = 105
      Height = 27
      Caption = 'Guardar vista'
      TabOrder = 0
      OnClick = SaveLayout
    end
    object btnLoadLayout: TButton
      Left = 118
      Top = 6
      Width = 105
      Height = 27
      Caption = 'Restaurar vista'
      TabOrder = 1
      OnClick = LoadLayout
    end
    object btnRowTotals: TButton
      Left = 228
      Top = 6
      Width = 105
      Height = 27
      Caption = 'Tot. filas'
      TabOrder = 2
      OnClick = ToggleRowTotals
    end
    object btnColumnTotals: TButton
      Left = 338
      Top = 6
      Width = 105
      Height = 27
      Caption = 'Tot. columnas'
      TabOrder = 3
      OnClick = ToggleColumnTotals
    end
    object btnFields: TButton
      Left = 448
      Top = 6
      Width = 105
      Height = 27
      Caption = 'Ocultar campos'
      TabOrder = 4
      OnClick = ToggleFields
    end
    object cbStyle: TComboBox
      Left = 563
      Top = 8
      Width = 175
      Height = 21
      Style = csDropDownList
      TabOrder = 5
      OnChange = ChangeVclStyle
    end
    object btnGestion: TButton
      Left = 745
      Top = 6
      Width = 130
      Height = 27
      Caption = 'Conectar Gesti'#243'n'
      TabOrder = 6
      OnClick = OpenGestionDemo
    end
  end
  object LarGridPivot1: TLarGridPivot
    Left = 0
    Top = 40
    Width = 1304
    Height = 621
    Align = alClient
    DataSource = DataSource1
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object ClientDataSet1: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 32
    Top = 72
  end
  object DataSource1: TDataSource
    DataSet = ClientDataSet1
    Left = 120
    Top = 72
  end
end
