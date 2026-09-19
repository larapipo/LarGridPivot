unit Demo.Main;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Data.DB, Datasnap.DBClient,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Grid;

type
  TFrmLarGridPivotDemo = class(TForm)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FPivot: TLarGridPivot;
    procedure AddSale(const AVendedor, AMes: string; AVenta: Currency);
    procedure ConfigurePivot;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  FrmLarGridPivotDemo: TFrmLarGridPivotDemo;

implementation

constructor TFrmLarGridPivotDemo.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'LarGridPivot v1 - Primera prueba';
  Width := 900;
  Height := 520;
  Position := poScreenCenter;

  FData := TClientDataSet.Create(Self);
  FData.FieldDefs.Add('VENDEDOR', ftString, 40);
  FData.FieldDefs.Add('MES', ftString, 20);
  FData.FieldDefs.Add('VENTA', ftCurrency);
  FData.CreateDataSet;

  AddSale('JUAN', 'ENERO', 125420);
  AddSale('JUAN', 'FEBRERO', 145210);
  AddSale('PEDRO', 'ENERO', 98300);
  AddSale('PEDRO', 'FEBRERO', 120000);
  AddSale('JUAN', 'ENERO', 10000);

  FSource := TDataSource.Create(Self);
  FSource.DataSet := FData;

  FPivot := TLarGridPivot.Create(Self);
  FPivot.Parent := Self;
  FPivot.Align := alClient;
  FPivot.DataSource := FSource;
  FPivot.Font.Name := 'Segoe UI';
  FPivot.Font.Size := 10;

  ConfigurePivot;
end;

destructor TFrmLarGridPivotDemo.Destroy;
begin
  inherited;
end;

procedure TFrmLarGridPivotDemo.AddSale(const AVendedor, AMes: string; AVenta: Currency);
begin
  FData.Append;
  FData.FieldByName('VENDEDOR').AsString := AVendedor;
  FData.FieldByName('MES').AsString := AMes;
  FData.FieldByName('VENTA').AsCurrency := AVenta;
  FData.Post;
end;

procedure TFrmLarGridPivotDemo.ConfigurePivot;
var F: TLarPivotField;
begin
  FPivot.BeginUpdate;
  try
    F := FPivot.FieldByName('VENDEDOR');
    F.Area := paRow;
    F.AreaIndex := 0;

    F := FPivot.FieldByName('MES');
    F.Area := paColumn;
    F.AreaIndex := 0;

    F := FPivot.FieldByName('VENTA');
    F.Area := paData;
    F.AreaIndex := 0;
    F.SummaryType := psSum;
    F.DisplayFormat := '#,##0.00';
    F.Alignment := pvaRight;
  finally
    FPivot.EndUpdate;
  end;
end;

end.
