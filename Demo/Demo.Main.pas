unit Demo.Main;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.IOUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Graphics, Vcl.Themes, Vcl.Styles,
  Data.DB, Datasnap.DBClient,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Filters,
  LarGridPivot.Grid;

type
  TFrmLarGridPivotDemo = class(TForm)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FPivot: TLarGridPivot;
    FTop: TPanel;
    FAreaPanel: TPanel;
    FAvailable, FRows, FColumns, FValues, FFilters: TListBox;
    FBtnToRows, FBtnToColumns, FBtnToValues, FBtnToFilters, FBtnRemove: TButton;
    FBtnSave, FBtnLoad, FBtnRowTotals, FBtnColumnTotals, FBtnFields: TButton;
    FLayout:string;
    FStyleCombo:TComboBox;
    FStyleFiles:TStringList;
    FBtnGestion:TButton;
    procedure AddSale(const AVendedor, AMes, ASucursal: string; AVenta: Currency; ACantidad: Integer; AAnio:Integer=2026; const ARubro:string='GENERAL'; ACosto:Currency=0);
    procedure ConfigurePivot;
    procedure RefreshAreaLists;
    function SelectedFieldName: string;
    procedure MoveSelected(AArea: TLarPivotArea);
    procedure ToRows(Sender: TObject);
    procedure ToColumns(Sender: TObject);
    procedure ToValues(Sender: TObject);
    procedure ToFilters(Sender: TObject);
    procedure RemoveField(Sender: TObject);
    procedure SaveLayout(Sender: TObject);
    procedure LoadLayout(Sender: TObject);
    procedure ToggleRowTotals(Sender:TObject);
    procedure ToggleColumnTotals(Sender:TObject);
    procedure ToggleFields(Sender:TObject);
    procedure ChangeVclStyle(Sender:TObject);
    procedure OpenGestionDemo(Sender:TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var FrmLarGridPivotDemo: TFrmLarGridPivotDemo;

implementation

uses Demo.Gestion;

constructor TFrmLarGridPivotDemo.Create(AOwner: TComponent);
  procedure MakeList(var L: TListBox; ALeft: Integer; const ATitle: string);
  var Lab: TLabel;
  begin
    Lab:=TLabel.Create(Self); Lab.Parent:=FAreaPanel; Lab.Left:=ALeft; Lab.Top:=6;
    Lab.Caption:=ATitle; Lab.Font.Style:=[fsBold];
    L:=TListBox.Create(Self); L.Parent:=FAreaPanel; L.Left:=ALeft; L.Top:=25;
    L.Width:=150; L.Height:=82;
  end;
  procedure MakeButton(var B:TButton; ALeft,ATop:Integer; const ACaption:string; AClick:TNotifyEvent);
  begin
    B:=TButton.Create(Self); B.Parent:=FTop; B.Left:=ALeft; B.Top:=ATop;
    B.Width:=105; B.Height:=27; B.Caption:=ACaption; B.OnClick:=AClick;
  end;
var BDSPath, PublicPath:string;
  procedure LoadStylesFromFolder(const AFolder:string);
  var Files:TStringDynArray; FileName, DisplayName:string; I:Integer;
  begin
    if (AFolder='') or not TDirectory.Exists(AFolder) then Exit;
    try
      Files:=TDirectory.GetFiles(AFolder,'*.vsf',TSearchOption.soAllDirectories);
      for FileName in Files do begin
        DisplayName:=ChangeFileExt(ExtractFileName(FileName),'');
        if FStyleCombo.Items.IndexOf(DisplayName)>=0 then Continue;
        I:=FStyleCombo.Items.Add(DisplayName);
        while FStyleFiles.Count<=I do FStyleFiles.Add('');
        FStyleFiles[I]:=FileName;
      end;
    except
      { An optional style folder must never prevent the demo from starting. }
    end;
  end;
begin
  inherited CreateNew(AOwner);
  Caption:='LarGridPivot v1 - Pivot interactivo';
  Width:=1320; Height:=700; Position:=poScreenCenter;

  FData:=TClientDataSet.Create(Self);
  FData.FieldDefs.Add('VENDEDOR',ftString,40);
  FData.FieldDefs.Add('MES',ftString,20);
  FData.FieldDefs.Add('SUCURSAL',ftString,20);
  FData.FieldDefs.Add('ANIO',ftInteger);
  FData.FieldDefs.Add('RUBRO',ftString,30);
  FData.FieldDefs.Add('VENTA',ftCurrency);
  FData.FieldDefs.Add('CANTIDAD',ftInteger);
  FData.FieldDefs.Add('COSTO',ftCurrency);
  FData.CreateDataSet;
  AddSale('JUAN','ENERO','CENTRO',125420,10);
  AddSale('JUAN','FEBRERO','CENTRO',145210,12);
  AddSale('PEDRO','ENERO','NORTE',98300,7);
  AddSale('PEDRO','FEBRERO','NORTE',120000,9);
  AddSale('JUAN','ENERO','NORTE',10000,2);
  AddSale('ANA','MARZO','CENTRO',84500,6,2026,'FERRETERIA');
  AddSale('ANA','ABRIL','SUR',91750,8,2026,'FERRETERIA');
  AddSale('LUIS','ENERO','SUR',67200,5,2026,'ELECTRICIDAD');
  AddSale('LUIS','FEBRERO','CENTRO',73400,6,2026,'ELECTRICIDAD');
  AddSale('PEDRO','MARZO','NORTE',132600,11,2026,'PINTURAS');
  AddSale('JUAN','ABRIL','CENTRO',156800,13,2026,'PINTURAS');
  AddSale('ANA','ENERO','NORTE',77800,7,2025,'FERRETERIA');
  AddSale('LUIS','FEBRERO','SUR',82400,8,2025,'ELECTRICIDAD');
  AddSale('PEDRO','MARZO','CENTRO',109900,9,2025,'PINTURAS');
  AddSale('JUAN','ABRIL','NORTE',118300,10,2025,'FERRETERIA');
  AddSale('MARTA','ENERO','CENTRO',96300,8,2026,'BAZAR');
  AddSale('MARTA','FEBRERO','SUR',104200,9,2026,'BAZAR',62500);
  AddSale('ANA','MAYO','CENTRO',112500,9,2026,'FERRETERIA',71000);
  AddSale('JUAN','JUNIO','CENTRO',168400,14,2026,'ELECTRICIDAD',103000);
  AddSale('LUIS','JULIO','NORTE',94500,8,2026,'BAZAR',59000);
  AddSale('PEDRO','AGOSTO','SUR',151300,12,2026,'PINTURAS',93000);
  AddSale('MARTA','SEPTIEMBRE','CENTRO',127900,10,2026,'FERRETERIA',77000);
  AddSale('ANA','OCTUBRE','NORTE',139600,11,2026,'ELECTRICIDAD',85000);
  AddSale('JUAN','NOVIEMBRE','SUR',176200,15,2026,'BAZAR',108000);
  AddSale('PEDRO','DICIEMBRE','CENTRO',184500,16,2026,'PINTURAS',111000);
  AddSale('MARTA','MAYO','NORTE',88900,7,2025,'BAZAR',54000);
  AddSale('ANA','JUNIO','SUR',103200,9,2025,'FERRETERIA',63000);
  AddSale('LUIS','JULIO','CENTRO',119700,10,2025,'ELECTRICIDAD',72000);
  AddSale('PEDRO','AGOSTO','NORTE',128800,11,2025,'PINTURAS',79000);
  AddSale('JUAN','SEPTIEMBRE','SUR',142600,12,2025,'FERRETERIA',86000);

  FSource:=TDataSource.Create(Self); FSource.DataSet:=FData;

  FTop:=TPanel.Create(Self); FTop.Parent:=Self; FTop.Align:=alTop; FTop.Height:=40;
  FTop.BevelOuter:=bvNone;
  MakeButton(FBtnSave,8,6,'Guardar vista',SaveLayout);
  MakeButton(FBtnLoad,118,6,'Restaurar vista',LoadLayout);
  MakeButton(FBtnRowTotals,228,6,'Tot. filas',ToggleRowTotals);
  MakeButton(FBtnColumnTotals,338,6,'Tot. columnas',ToggleColumnTotals);
  MakeButton(FBtnFields,448,6,'Mostrar campos',ToggleFields);
  FStyleCombo:=TComboBox.Create(Self); FStyleCombo.Parent:=FTop;
  FStyleCombo.Left:=563; FStyleCombo.Top:=8; FStyleCombo.Width:=175; FStyleCombo.Style:=csDropDownList;
  FStyleFiles:=TStringList.Create;
  FStyleCombo.Items.Add('Windows'); FStyleFiles.Add('');
  { Enumerate the actual .vsf files instead of relying on StyleNames. StyleNames
    only reports styles already registered in this executable. }
  LoadStylesFromFolder(TPath.Combine(ExtractFilePath(ParamStr(0)),'Styles'));
  BDSPath:=GetEnvironmentVariable('BDSCOMMONDIR');
  if BDSPath<>'' then LoadStylesFromFolder(TPath.Combine(BDSPath,'Styles'));
  BDSPath:=GetEnvironmentVariable('BDS');
  if BDSPath<>'' then LoadStylesFromFolder(TPath.Combine(BDSPath,'Redist\styles\vcl'));
  BDSPath:=GetEnvironmentVariable('ProgramFiles(x86)');
  if BDSPath<>'' then
    LoadStylesFromFolder(TPath.Combine(BDSPath,'Embarcadero\Studio\23.0\Redist\styles\vcl'));
  { This repository is commonly installed below Studio\23.0\Librerias.
    Derive the RAD Studio root from the running EXE as well; unlike BDS this
    remains available when the application is launched outside the IDE. }
  BDSPath:=ExpandFileName(TPath.Combine(ExtractFilePath(ParamStr(0)),'..\..\..\..\..'));
  LoadStylesFromFolder(TPath.Combine(BDSPath,'Redist\styles\vcl'));
  LoadStylesFromFolder(TPath.Combine(BDSPath,'Styles'));
  PublicPath:=GetEnvironmentVariable('PUBLIC');
  if PublicPath<>'' then
    LoadStylesFromFolder(TPath.Combine(PublicPath,'Documents\Embarcadero\Studio\23.0\Styles'));
  FStyleCombo.ItemIndex:=0;
  FStyleCombo.OnChange:=ChangeVclStyle;
  MakeButton(FBtnGestion,745,6,'Conectar Gestión',OpenGestionDemo); FBtnGestion.Width:=130;

  FAreaPanel:=TPanel.Create(Self); FAreaPanel.Parent:=Self; FAreaPanel.Align:=alTop;
  FAreaPanel.Height:=0; FAreaPanel.Visible:=False; FAreaPanel.BevelOuter:=bvNone;
  MakeList(FAvailable,8,'DISPONIBLES');
  MakeList(FRows,168,'FILAS');
  MakeList(FColumns,328,'COLUMNAS');
  MakeList(FValues,488,'DATOS');
  MakeList(FFilters,648,'FILTROS');

  FPivot:=TLarGridPivot.Create(Self); FPivot.Parent:=Self; FPivot.Align:=alClient;
  FPivot.DataSource:=FSource; FPivot.Font.Name:='Segoe UI'; FPivot.Font.Size:=10;
  ConfigurePivot;
  FBtnFields.Caption:='Ocultar campos';
  RefreshAreaLists;
end;

procedure TFrmLarGridPivotDemo.AddSale(const AVendedor,AMes,ASucursal:string; AVenta:Currency; ACantidad:Integer; AAnio:Integer; const ARubro:string; ACosto:Currency);
begin
  FData.Append;
  FData.FieldByName('VENDEDOR').AsString:=AVendedor;
  FData.FieldByName('MES').AsString:=AMes;
  FData.FieldByName('SUCURSAL').AsString:=ASucursal;
  FData.FieldByName('VENTA').AsCurrency:=AVenta;
  FData.FieldByName('CANTIDAD').AsInteger:=ACantidad;
  FData.FieldByName('ANIO').AsInteger:=AAnio;
  FData.FieldByName('RUBRO').AsString:=ARubro;
  if ACosto=0 then ACosto:=AVenta*0.62;
  FData.FieldByName('COSTO').AsCurrency:=ACosto;
  FData.Post;
end;

procedure TFrmLarGridPivotDemo.ConfigurePivot;
var F:TLarPivotField;
begin
  FPivot.BeginUpdate;
  try
    F:=FPivot.FieldByName('SUCURSAL'); F.Area:=paRow; F.AreaIndex:=0; F.ShowSubTotal:=True;
    F:=FPivot.FieldByName('VENDEDOR'); F.Area:=paRow; F.AreaIndex:=1; F.ShowSubTotal:=False;
    F:=FPivot.FieldByName('RUBRO'); F.Area:=paRow; F.AreaIndex:=2; F.ShowSubTotal:=False;
    F:=FPivot.FieldByName('MES'); F.Area:=paColumn; F.AreaIndex:=0;
    F:=FPivot.FieldByName('ANIO'); F.Area:=paNone; F.AreaIndex:=-1;
    F:=FPivot.FieldByName('VENTA'); F.Caption:='Venta'; F.Area:=paData; F.AreaIndex:=0;
    F.SummaryType:=psSum; F.DisplayFormat:='#,##0.00'; F.Alignment:=pvaRight;
    F:=FPivot.FieldByName('CANTIDAD'); F.Caption:='Cantidad'; F.Area:=paNone; F.AreaIndex:=-1;
    F.SummaryType:=psSum; F.DisplayFormat:='#,##0'; F.Alignment:=pvaRight;
    F:=FPivot.FieldByName('COSTO'); F.Caption:='Costo'; F.Area:=paData; F.AreaIndex:=1;
    F.SummaryType:=psSum; F.DisplayFormat:='#,##0.00'; F.Alignment:=pvaRight;
  finally FPivot.EndUpdate; end;
end;

procedure TFrmLarGridPivotDemo.RefreshAreaLists;
var I:Integer; F:TLarPivotField; L:TListBox;
begin
  FAvailable.Clear; FRows.Clear; FColumns.Clear; FValues.Clear; FFilters.Clear;
  for I:=0 to FPivot.Fields.Count-1 do begin
    F:=FPivot.Fields[I];
    case F.Area of
      paRow: L:=FRows;
      paColumn: L:=FColumns;
      paData: L:=FValues;
      paFilter: L:=FFilters;
    else L:=FAvailable;
    end;
    L.Items.AddObject(F.Caption,TObject(F));
  end;
end;

function TFrmLarGridPivotDemo.SelectedFieldName:string;
var L:TListBox; F:TLarPivotField;
begin
  Result:='';
  for L in [FAvailable,FRows,FColumns,FValues,FFilters] do
    if L.ItemIndex>=0 then begin
      F:=TLarPivotField(L.Items.Objects[L.ItemIndex]);
      Exit(F.FieldName);
    end;
end;

procedure TFrmLarGridPivotDemo.MoveSelected(AArea:TLarPivotArea);
var N:string;
begin
  N:=SelectedFieldName;
  if N='' then begin ShowMessage('Seleccione primero un campo.'); Exit; end;
  FPivot.MoveField(N,AArea);
  RefreshAreaLists;
end;

procedure TFrmLarGridPivotDemo.ToRows(Sender:TObject); begin MoveSelected(paRow); end;
procedure TFrmLarGridPivotDemo.ToColumns(Sender:TObject); begin MoveSelected(paColumn); end;
procedure TFrmLarGridPivotDemo.ToValues(Sender:TObject); begin MoveSelected(paData); end;
procedure TFrmLarGridPivotDemo.ToFilters(Sender:TObject); begin MoveSelected(paFilter); end;
procedure TFrmLarGridPivotDemo.RemoveField(Sender:TObject); begin MoveSelected(paNone); end;

procedure TFrmLarGridPivotDemo.SaveLayout(Sender:TObject);
begin
  FLayout:=FPivot.SaveLayoutToString;
  ShowMessage('Vista guardada en memoria.');
end;

procedure TFrmLarGridPivotDemo.LoadLayout(Sender:TObject);
begin
  if FLayout='' then begin ShowMessage('Primero guarde una vista.'); Exit; end;
  FPivot.LoadLayoutFromString(FLayout);
  RefreshAreaLists;
end;

procedure TFrmLarGridPivotDemo.ToggleRowTotals(Sender:TObject);
begin FPivot.ShowRowTotals:=not FPivot.ShowRowTotals; FPivot.Rebuild; end;

procedure TFrmLarGridPivotDemo.ToggleColumnTotals(Sender:TObject);
begin FPivot.ShowColumnTotals:=not FPivot.ShowColumnTotals; FPivot.Rebuild; end;

procedure TFrmLarGridPivotDemo.OpenGestionDemo(Sender:TObject);
var F:TForm;
begin
 F:=TFrmLarGridPivotGestionDemo.Create(Application);
 F.Show;
end;

procedure TFrmLarGridPivotDemo.ChangeVclStyle(Sender:TObject);
var FN:string;
begin
 if FStyleCombo.ItemIndex<0 then Exit;
 FN:=FStyleFiles[FStyleCombo.ItemIndex];
 try
  if FN='' then TStyleManager.SetStyle('Windows')
  else begin
   TStyleManager.SetStyle(TStyleManager.LoadFromFile(FN));
  end;
  FPivot.Theme:=ptVclStyle;
  FPivot.Invalidate;
 except
  on E:Exception do Application.ShowException(E);
 end;
end;

destructor TFrmLarGridPivotDemo.Destroy;
begin
 FStyleFiles.Free;
 inherited;
end;

procedure TFrmLarGridPivotDemo.ToggleFields(Sender:TObject);
begin
 FPivot.ShowFieldPanel:=not FPivot.ShowFieldPanel;
 if FPivot.ShowFieldPanel then FBtnFields.Caption:='Ocultar campos'
 else FBtnFields.Caption:='Mostrar campos';
end;

end.
