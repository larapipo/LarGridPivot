unit Demo.Main;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.IOUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Graphics,
  Vcl.Themes, Vcl.Styles, Data.DB, Datasnap.DBClient,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Filters, LarGridPivot.Grid;

type
  TFrmLarGridPivotDemo = class(TForm)
    pnlTop: TPanel;
    btnSaveLayout: TButton;
    btnLoadLayout: TButton;
    btnRowTotals: TButton;
    btnColumnTotals: TButton;
    btnFields: TButton;
    cbStyle: TComboBox;
    btnGestion: TButton;
    LarGridPivot1: TLarGridPivot;
    ClientDataSet1: TClientDataSet;
    DataSource1: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SaveLayout(Sender: TObject);
    procedure LoadLayout(Sender: TObject);
    procedure ToggleRowTotals(Sender: TObject);
    procedure ToggleColumnTotals(Sender: TObject);
    procedure ToggleFields(Sender: TObject);
    procedure ChangeVclStyle(Sender: TObject);
    procedure OpenGestionDemo(Sender: TObject);
  private
    FLayout: string;
    FStyleFiles: TStringList;
    FLoadedStyleNames: TStringList;
    procedure AddSale(const AVendedor, AMes, ASucursal: string;
      AVenta: Currency; ACantidad: Integer; AAnio: Integer = 2026;
      const ARubro: string = 'GENERAL'; ACosto: Currency = 0);
    procedure ConfigurePivot;
    procedure LoadStylesFromFolder(const AFolder: string);
    procedure LoadAvailableStyles;
  end;

var
  FrmLarGridPivotDemo: TFrmLarGridPivotDemo;

implementation

{$R *.dfm}

uses
  Demo.Gestion;

procedure TFrmLarGridPivotDemo.FormCreate(Sender: TObject);
begin
  FStyleFiles := TStringList.Create;
  FLoadedStyleNames := TStringList.Create;

  { The pivot is already connected through the DFM.  Batch dataset creation
    and sample inserts so DataLink notifications do not rebuild the pivot for
    every appended field/record. }
  LarGridPivot1.BeginUpdate;
  try
    ClientDataSet1.Close;
    ClientDataSet1.FieldDefs.Clear;
  ClientDataSet1.FieldDefs.Add('VENDEDOR', ftString, 40);
  ClientDataSet1.FieldDefs.Add('MES', ftString, 20);
  ClientDataSet1.FieldDefs.Add('SUCURSAL', ftString, 20);
  ClientDataSet1.FieldDefs.Add('ANIO', ftInteger);
  ClientDataSet1.FieldDefs.Add('RUBRO', ftString, 30);
  ClientDataSet1.FieldDefs.Add('VENTA', ftCurrency);
  ClientDataSet1.FieldDefs.Add('CANTIDAD', ftInteger);
  ClientDataSet1.FieldDefs.Add('COSTO', ftCurrency);
  ClientDataSet1.CreateDataSet;

  AddSale('JUAN', 'ENERO', 'CENTRO', 125420, 10);
  AddSale('JUAN', 'FEBRERO', 'CENTRO', 145210, 12);
  AddSale('PEDRO', 'ENERO', 'NORTE', 98300, 7);
  AddSale('PEDRO', 'FEBRERO', 'NORTE', 120000, 9);
  AddSale('JUAN', 'ENERO', 'NORTE', 10000, 2);
  AddSale('ANA', 'MARZO', 'CENTRO', 84500, 6, 2026, 'FERRETERIA');
  AddSale('ANA', 'ABRIL', 'SUR', 91750, 8, 2026, 'FERRETERIA');
  AddSale('LUIS', 'ENERO', 'SUR', 67200, 5, 2026, 'ELECTRICIDAD');
  AddSale('LUIS', 'FEBRERO', 'CENTRO', 73400, 6, 2026, 'ELECTRICIDAD');
  AddSale('PEDRO', 'MARZO', 'NORTE', 132600, 11, 2026, 'PINTURAS');
  AddSale('JUAN', 'ABRIL', 'CENTRO', 156800, 13, 2026, 'PINTURAS');
  AddSale('ANA', 'ENERO', 'NORTE', 77800, 7, 2025, 'FERRETERIA');
  AddSale('LUIS', 'FEBRERO', 'SUR', 82400, 8, 2025, 'ELECTRICIDAD');
  AddSale('PEDRO', 'MARZO', 'CENTRO', 109900, 9, 2025, 'PINTURAS');
  AddSale('JUAN', 'ABRIL', 'NORTE', 118300, 10, 2025, 'FERRETERIA');
  AddSale('MARTA', 'ENERO', 'CENTRO', 96300, 8, 2026, 'BAZAR');
  AddSale('MARTA', 'FEBRERO', 'SUR', 104200, 9, 2026, 'BAZAR', 62500);
  AddSale('ANA', 'MAYO', 'CENTRO', 112500, 9, 2026, 'FERRETERIA', 71000);
  AddSale('JUAN', 'JUNIO', 'CENTRO', 168400, 14, 2026, 'ELECTRICIDAD', 103000);
  AddSale('LUIS', 'JULIO', 'NORTE', 94500, 8, 2026, 'BAZAR', 59000);
  AddSale('PEDRO', 'AGOSTO', 'SUR', 151300, 12, 2026, 'PINTURAS', 93000);
  AddSale('MARTA', 'SEPTIEMBRE', 'CENTRO', 127900, 10, 2026, 'FERRETERIA', 77000);
  AddSale('ANA', 'OCTUBRE', 'NORTE', 139600, 11, 2026, 'ELECTRICIDAD', 85000);
  AddSale('JUAN', 'NOVIEMBRE', 'SUR', 176200, 15, 2026, 'BAZAR', 108000);
  AddSale('PEDRO', 'DICIEMBRE', 'CENTRO', 184500, 16, 2026, 'PINTURAS', 111000);
  AddSale('MARTA', 'MAYO', 'NORTE', 88900, 7, 2025, 'BAZAR', 54000);
  AddSale('ANA', 'JUNIO', 'SUR', 103200, 9, 2025, 'FERRETERIA', 63000);
  AddSale('LUIS', 'JULIO', 'CENTRO', 119700, 10, 2025, 'ELECTRICIDAD', 72000);
  AddSale('PEDRO', 'AGOSTO', 'NORTE', 128800, 11, 2025, 'PINTURAS', 79000);
    AddSale('JUAN', 'SEPTIEMBRE', 'SUR', 142600, 12, 2025, 'FERRETERIA', 86000);

    LarGridPivot1.RefreshFields;
    ConfigurePivot;
  finally
    LarGridPivot1.EndUpdate;
  end;

  LoadAvailableStyles;
  btnFields.Caption := 'Ocultar campos';
end;

procedure TFrmLarGridPivotDemo.FormDestroy(Sender: TObject);
begin
  FLoadedStyleNames.Free;
  FStyleFiles.Free;
end;

procedure TFrmLarGridPivotDemo.LoadStylesFromFolder(const AFolder: string);
var
  Files: TStringDynArray;
  FileName, DisplayName: string;
  I: Integer;
begin
  if (AFolder = '') or not TDirectory.Exists(AFolder) then
    Exit;
  try
    Files := TDirectory.GetFiles(AFolder, '*.vsf', TSearchOption.soAllDirectories);
    for FileName in Files do
    begin
      DisplayName := ChangeFileExt(ExtractFileName(FileName), '');
      if cbStyle.Items.IndexOf(DisplayName) >= 0 then
        Continue;
      I := cbStyle.Items.Add(DisplayName);
      while FStyleFiles.Count <= I do
        FStyleFiles.Add('');
      while FLoadedStyleNames.Count <= I do
        FLoadedStyleNames.Add('');
      FStyleFiles[I] := FileName;
    end;
  except
    { Optional style folders must never prevent the demo from starting. }
  end;
end;

procedure TFrmLarGridPivotDemo.LoadAvailableStyles;
var
  BDSPath, PublicPath: string;
begin
  cbStyle.Items.BeginUpdate;
  try
    cbStyle.Items.Clear;
    FStyleFiles.Clear;
    FLoadedStyleNames.Clear;

    cbStyle.Items.Add('Windows');
    FStyleFiles.Add('');
    FLoadedStyleNames.Add('Windows');

    LoadStylesFromFolder(TPath.Combine(ExtractFilePath(ParamStr(0)), 'Styles'));

    BDSPath := GetEnvironmentVariable('BDSCOMMONDIR');
    if BDSPath <> '' then
      LoadStylesFromFolder(TPath.Combine(BDSPath, 'Styles'));

    BDSPath := GetEnvironmentVariable('BDS');
    if BDSPath <> '' then
      LoadStylesFromFolder(TPath.Combine(BDSPath, 'Redist\styles\vcl'));

    BDSPath := GetEnvironmentVariable('ProgramFiles(x86)');
    if BDSPath <> '' then
      LoadStylesFromFolder(TPath.Combine(BDSPath,
        'Embarcadero\Studio\23.0\Redist\styles\vcl'));

    BDSPath := ExpandFileName(TPath.Combine(
      ExtractFilePath(ParamStr(0)), '..\..\..\..'));
    LoadStylesFromFolder(TPath.Combine(BDSPath, 'Redist\styles\vcl'));
    LoadStylesFromFolder(TPath.Combine(BDSPath, 'Styles'));

    PublicPath := GetEnvironmentVariable('PUBLIC');
    if PublicPath <> '' then
      LoadStylesFromFolder(TPath.Combine(PublicPath,
        'Documents\Embarcadero\Studio\23.0\Styles'));

    cbStyle.ItemIndex := cbStyle.Items.IndexOf(TStyleManager.ActiveStyle.Name);
    if cbStyle.ItemIndex < 0 then
      cbStyle.ItemIndex := 0;
  finally
    cbStyle.Items.EndUpdate;
  end;
end;

procedure TFrmLarGridPivotDemo.AddSale(const AVendedor, AMes, ASucursal: string;
  AVenta: Currency; ACantidad: Integer; AAnio: Integer; const ARubro: string;
  ACosto: Currency);
begin
  ClientDataSet1.Append;
  ClientDataSet1.FieldByName('VENDEDOR').AsString := AVendedor;
  ClientDataSet1.FieldByName('MES').AsString := AMes;
  ClientDataSet1.FieldByName('SUCURSAL').AsString := ASucursal;
  ClientDataSet1.FieldByName('VENTA').AsCurrency := AVenta;
  ClientDataSet1.FieldByName('CANTIDAD').AsInteger := ACantidad;
  ClientDataSet1.FieldByName('ANIO').AsInteger := AAnio;
  ClientDataSet1.FieldByName('RUBRO').AsString := ARubro;
  if ACosto = 0 then
    ACosto := AVenta * 0.62;
  ClientDataSet1.FieldByName('COSTO').AsCurrency := ACosto;
  ClientDataSet1.Post;
end;

procedure TFrmLarGridPivotDemo.ConfigurePivot;
var
  F: TLarPivotField;
begin
  LarGridPivot1.BeginUpdate;
  try
    F := LarGridPivot1.FieldByName('SUCURSAL');
    if F <> nil then
    begin
      F.Area := paRow;
      F.AreaIndex := 0;
      F.ShowSubTotal := True;
    end;

    F := LarGridPivot1.FieldByName('VENDEDOR');
    if F <> nil then
    begin
      F.Area := paRow;
      F.AreaIndex := 1;
      F.ShowSubTotal := False;
    end;

    F := LarGridPivot1.FieldByName('RUBRO');
    if F <> nil then
    begin
      F.Area := paRow;
      F.AreaIndex := 2;
      F.ShowSubTotal := False;
    end;

    F := LarGridPivot1.FieldByName('MES');
    if F <> nil then
    begin
      F.Area := paColumn;
      F.AreaIndex := 0;
    end;

    F := LarGridPivot1.FieldByName('ANIO');
    if F <> nil then
    begin
      F.Area := paNone;
      F.AreaIndex := -1;
    end;

    F := LarGridPivot1.FieldByName('VENTA');
    if F <> nil then
    begin
      F.Caption := 'Venta';
      F.Area := paData;
      F.AreaIndex := 0;
      F.SummaryType := psSum;
      F.DisplayFormat := '#,##0.00';
      F.Alignment := pvaRight;
    end;

    F := LarGridPivot1.FieldByName('CANTIDAD');
    if F <> nil then
    begin
      F.Caption := 'Cantidad';
      F.Area := paNone;
      F.AreaIndex := -1;
      F.SummaryType := psSum;
      F.DisplayFormat := '#,##0';
      F.Alignment := pvaRight;
    end;

    F := LarGridPivot1.FieldByName('COSTO');
    if F <> nil then
    begin
      F.Caption := 'Costo';
      F.Area := paData;
      F.AreaIndex := 1;
      F.SummaryType := psSum;
      F.DisplayFormat := '#,##0.00';
      F.Alignment := pvaRight;
    end;
  finally
    LarGridPivot1.EndUpdate;
  end;
end;

procedure TFrmLarGridPivotDemo.SaveLayout(Sender: TObject);
begin
  FLayout := LarGridPivot1.SaveLayoutToString;
  ShowMessage('Vista guardada en memoria.');
end;

procedure TFrmLarGridPivotDemo.LoadLayout(Sender: TObject);
begin
  if FLayout = '' then
  begin
    ShowMessage('Primero guarde una vista.');
    Exit;
  end;
  LarGridPivot1.LoadLayoutFromString(FLayout);
end;

procedure TFrmLarGridPivotDemo.ToggleRowTotals(Sender: TObject);
begin
  LarGridPivot1.ShowRowTotals := not LarGridPivot1.ShowRowTotals;
end;

procedure TFrmLarGridPivotDemo.ToggleColumnTotals(Sender: TObject);
begin
  LarGridPivot1.ShowColumnTotals := not LarGridPivot1.ShowColumnTotals;
end;

procedure TFrmLarGridPivotDemo.ToggleFields(Sender: TObject);
begin
  LarGridPivot1.ShowFieldPanel := not LarGridPivot1.ShowFieldPanel;
  if LarGridPivot1.ShowFieldPanel then
    btnFields.Caption := 'Ocultar campos'
  else
    btnFields.Caption := 'Mostrar campos';
end;

procedure TFrmLarGridPivotDemo.ChangeVclStyle(Sender: TObject);
var
  FN, StyleName: string;
  I: Integer;
begin
  if cbStyle.ItemIndex < 0 then
    Exit;

  I := cbStyle.ItemIndex;
  FN := FStyleFiles[I];
  try
    if FN = '' then
      TStyleManager.SetStyle('Windows')
    else
    begin
      StyleName := FLoadedStyleNames[I];
      if StyleName <> '' then
        TStyleManager.SetStyle(StyleName)
      else
      begin
        TStyleManager.SetStyle(TStyleManager.LoadFromFile(FN));
        FLoadedStyleNames[I] := TStyleManager.ActiveStyle.Name;
      end;
    end;
    LarGridPivot1.Theme := ptVclStyle;
    LarGridPivot1.Invalidate;
  except
    on E: Exception do
      Application.ShowException(E);
  end;
end;

procedure TFrmLarGridPivotDemo.OpenGestionDemo(Sender: TObject);
var
  F: TFrmLarGridPivotGestionDemo;
begin
  F := TFrmLarGridPivotGestionDemo.Create(Application);
  F.Show;
end;

end.
