unit Demo.Main;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Forms, Vcl.Controls, Data.DB, Datasnap.DBClient,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Grid;

type
  TFrmLarGridPivotDemo = class(TForm)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FPivot: TLarGridPivot;
    procedure AddSale(const AVendedor, AMes: string; AVenta: Currency; ACantidad: Integer);
    procedure ConfigurePivot;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var FrmLarGridPivotDemo: TFrmLarGridPivotDemo;

implementation

constructor TFrmLarGridPivotDemo.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'LarGridPivot v1 - Hito 3 Multiples datos';
  Width := 1100; Height := 520; Position := poScreenCenter;
  FData := TClientDataSet.Create(Self);
  FData.FieldDefs.Add('VENDEDOR', ftString, 40);
  FData.FieldDefs.Add('MES', ftString, 20);
  FData.FieldDefs.Add('VENTA', ftCurrency);
  FData.FieldDefs.Add('CANTIDAD', ftInteger);
  FData.CreateDataSet;
  AddSale('JUAN','ENERO',125420,10);
  AddSale('JUAN','FEBRERO',145210,12);
  AddSale('PEDRO','ENERO',98300,7);
  AddSale('PEDRO','FEBRERO',120000,9);
  AddSale('JUAN','ENERO',10000,2);
  FSource := TDataSource.Create(Self); FSource.DataSet := FData;
  FPivot := TLarGridPivot.Create(Self); FPivot.Parent := Self; FPivot.Align := alClient;
  FPivot.DataSource := FSource; FPivot.Font.Name := 'Segoe UI'; FPivot.Font.Size := 10;
  ConfigurePivot;
end;

procedure TFrmLarGridPivotDemo.AddSale(const AVendedor, AMes:string; AVenta:Currency; ACantidad:Integer);
begin
  FData.Append;
  FData.FieldByName('VENDEDOR').AsString:=AVendedor;
  FData.FieldByName('MES').AsString:=AMes;
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
    F:=FPivot.FieldByName('VENTA'); F.Caption:='Venta'; F.Area:=paData; F.AreaIndex:=0; F.SummaryType:=psSum; F.DisplayFormat:='#,##0.00'; F.Alignment:=pvaRight;
    F:=FPivot.FieldByName('CANTIDAD'); F.Caption:='Cantidad'; F.Area:=paData; F.AreaIndex:=1; F.SummaryType:=psSum; F.DisplayFormat:='#,##0'; F.Alignment:=pvaRight;
  finally FPivot.EndUpdate; end;
end;

end.
