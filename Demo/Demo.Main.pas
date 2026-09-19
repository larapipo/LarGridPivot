unit Demo.Main;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Data.DB, Datasnap.DBClient,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Filters, LarGridPivot.Grid;

type
  TFrmLarGridPivotDemo = class(TForm)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FPivot: TLarGridPivot;
    FTop: TPanel;
    FFilter: TComboBox;
    FLabel: TLabel;
    procedure AddSale(const AVendedor, AMes, ASucursal: string; AVenta: Currency; ACantidad: Integer);
    procedure ConfigurePivot;
    procedure FilterChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var FrmLarGridPivotDemo: TFrmLarGridPivotDemo;

implementation

constructor TFrmLarGridPivotDemo.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'LarGridPivot v1 - Hito 4 Filtros';
  Width := 1100; Height := 560; Position := poScreenCenter;

  FData := TClientDataSet.Create(Self);
  FData.FieldDefs.Add('VENDEDOR', ftString, 40);
  FData.FieldDefs.Add('MES', ftString, 20);
  FData.FieldDefs.Add('SUCURSAL', ftString, 20);
  FData.FieldDefs.Add('VENTA', ftCurrency);
  FData.FieldDefs.Add('CANTIDAD', ftInteger);
  FData.CreateDataSet;
  AddSale('JUAN','ENERO','CENTRO',125420,10);
  AddSale('JUAN','FEBRERO','CENTRO',145210,12);
  AddSale('PEDRO','ENERO','NORTE',98300,7);
  AddSale('PEDRO','FEBRERO','NORTE',120000,9);
  AddSale('JUAN','ENERO','NORTE',10000,2);

  FSource := TDataSource.Create(Self); FSource.DataSet := FData;

  FTop := TPanel.Create(Self); FTop.Parent := Self; FTop.Align := alTop; FTop.Height := 48; FTop.BevelOuter := bvNone;
  FLabel := TLabel.Create(Self); FLabel.Parent := FTop; FLabel.Left := 12; FLabel.Top := 16; FLabel.Caption := 'Filtro SUCURSAL:';
  FFilter := TComboBox.Create(Self); FFilter.Parent := FTop; FFilter.Left := 120; FFilter.Top := 11; FFilter.Width := 180; FFilter.Style := csDropDownList;
  FFilter.Items.Add('TODAS'); FFilter.Items.Add('CENTRO'); FFilter.Items.Add('NORTE'); FFilter.ItemIndex := 0; FFilter.OnChange := FilterChanged;

  FPivot := TLarGridPivot.Create(Self); FPivot.Parent := Self; FPivot.Align := alClient;
  FPivot.DataSource := FSource; FPivot.Font.Name := 'Segoe UI'; FPivot.Font.Size := 10;
  ConfigurePivot;
end;

procedure TFrmLarGridPivotDemo.AddSale(const AVendedor, AMes, ASucursal:string; AVenta:Currency; ACantidad:Integer);
begin
  FData.Append;
  FData.FieldByName('VENDEDOR').AsString:=AVendedor;
  FData.FieldByName('MES').AsString:=AMes;
  FData.FieldByName('SUCURSAL').AsString:=ASucursal;
  FData.FieldByName('VENTA').AsCurrency:=AVenta;
  FData.FieldByName('CANTIDAD').AsInteger:=ACantidad;
  FData.Post;
end;

procedure TFrmLarGridPivotDemo.ConfigurePivot;
var F:TLarPivotField;
begin
  FPivot.BeginUpdate;
  try
    F:=FPivot.FieldByName('VENDEDOR'); F.Area:=paRow; F.AreaIndex:=0;
    F:=FPivot.FieldByName('MES'); F.Area:=paColumn; F.AreaIndex:=0;
    F:=FPivot.FieldByName('SUCURSAL'); F.Area:=paFilter; F.AreaIndex:=0;
    F:=FPivot.FieldByName('VENTA'); F.Caption:='Venta'; F.Area:=paData; F.AreaIndex:=0; F.SummaryType:=psSum; F.DisplayFormat:='#,##0.00'; F.Alignment:=pvaRight;
    F:=FPivot.FieldByName('CANTIDAD'); F.Caption:='Cantidad'; F.Area:=paData; F.AreaIndex:=1; F.SummaryType:=psSum; F.DisplayFormat:='#,##0'; F.Alignment:=pvaRight;
  finally FPivot.EndUpdate; end;
end;

procedure TFrmLarGridPivotDemo.FilterChanged(Sender:TObject);
var F:TLarPivotFilter;
begin
  F := FPivot.Engine.Filters.Ensure('SUCURSAL');
  F.Clear;
  if FFilter.ItemIndex > 0 then F.AddValue(FFilter.Text);
  FPivot.Rebuild;
end;

end.
