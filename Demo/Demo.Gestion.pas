unit Demo.Gestion;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.ComCtrls,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.Intf, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.DApt,
  LarGridPivot.Grid, LarGridPivot.Types, LarGridPivot.Fields;

type
  TFrmLarGridPivotGestionDemo = class(TForm)
  private
    FConnection: TFDConnection;
    FQuery: TFDQuery;
    FSource: TDataSource;
    FPivot: TLarGridPivot;
    FTop: TPanel;
    FDesde, FHasta: TDateTimePicker;
    FBtnAbrir: TButton;
    FStatus: TLabel;
    procedure AbrirDatos(Sender:TObject);
    procedure ConfigurarConexionDemo;
    procedure ConfigurarPivot;
  public
    constructor Create(AOwner:TComponent); override;
    procedure UseConnection(AConnection:TFDConnection);
    property Connection:TFDConnection read FConnection;
  end;

implementation

const
  { The demo deliberately uses the existing Firebird procedure documented in
    Gestion's metadata. The pivot itself remains database-neutral: it only sees
    the TDataSource below. }
  SQL_VENTAS =
    'select * from LISTA_COSTO_ART_VENDIDO(:DESDE, :HASTA, :VENDEDOR, :SUCURSAL, :ZONA)';

constructor TFrmLarGridPivotGestionDemo.Create(AOwner:TComponent);
begin
  inherited CreateNew(AOwner);
  Caption:='LarGridPivot - conexión Firebird / Gestión';
  Width:=1280; Height:=720; Position:=poScreenCenter;

  FConnection:=TFDConnection.Create(Self);
  ConfigurarConexionDemo;

  FQuery:=TFDQuery.Create(Self);
  FQuery.Connection:=FConnection;
  FQuery.SQL.Text:=SQL_VENTAS;

  FSource:=TDataSource.Create(Self);
  FSource.DataSet:=FQuery;

  FTop:=TPanel.Create(Self); FTop.Parent:=Self; FTop.Align:=alTop;
  FTop.Height:=42; FTop.BevelOuter:=bvNone;

  FDesde:=TDateTimePicker.Create(Self); FDesde.Parent:=FTop;
  FDesde.Left:=8; FDesde.Top:=8; FDesde.Width:=120;
  FDesde.Date:=StartOfTheMonth(Date);

  FHasta:=TDateTimePicker.Create(Self); FHasta.Parent:=FTop;
  FHasta.Left:=136; FHasta.Top:=8; FHasta.Width:=120; FHasta.Date:=Date;

  FBtnAbrir:=TButton.Create(Self); FBtnAbrir.Parent:=FTop;
  FBtnAbrir.Left:=264; FBtnAbrir.Top:=7; FBtnAbrir.Width:=110;
  FBtnAbrir.Height:=27; FBtnAbrir.Caption:='Abrir ventas';
  FBtnAbrir.OnClick:=AbrirDatos;

  FStatus:=TLabel.Create(Self); FStatus.Parent:=FTop;
  FStatus.Left:=390; FStatus.Top:=13;
  FStatus.Caption:='Configure Connection.Params y abra los datos';

  FPivot:=TLarGridPivot.Create(Self); FPivot.Parent:=Self; FPivot.Align:=alClient;
  FPivot.Font.Name:='Segoe UI'; FPivot.Font.Size:=9;
  FPivot.Theme:=ptVclStyle;
  FPivot.DataSource:=FSource;
end;

procedure TFrmLarGridPivotGestionDemo.ConfigurarConexionDemo;
begin
 { Do not invoke FireDAC's default connection editor: in a runtime-only demo
   its design-time factory may not be registered and raises "Object factory
   ... is missing". Configure the connection explicitly instead. }
 FConnection.LoginPrompt:=False;
 FConnection.Params.Clear;
 FConnection.DriverName:='FB';
 FConnection.Params.Values['Protocol']:='TCPIP';
 FConnection.Params.Values['Server']:='127.0.0.1';
 FConnection.Params.Values['Port']:='3050';
 FConnection.Params.Values['User_Name']:='SYSDBA';
 FConnection.Params.Values['Password']:='masterkey';
 FConnection.Params.Values['CharacterSet']:='WIN1252';
 FConnection.Params.Values['Database']:='';
end;

procedure TFrmLarGridPivotGestionDemo.UseConnection(AConnection:TFDConnection);
begin
 if AConnection=nil then Exit;
 FQuery.Close;
 FQuery.Connection:=AConnection;
 FStatus.Caption:='Conexión FireDAC asignada: '+AConnection.Name;
end;

procedure TFrmLarGridPivotGestionDemo.AbrirDatos(Sender:TObject);
begin
  try
    FQuery.Close;
    if (FQuery.Connection=FConnection) and (Trim(FConnection.Params.Database)='') then begin
      ShowMessage('Demo Gestión: configure FConnection.Params.Database con la ruta/alias de su base Firebird, o use UseConnection() para reutilizar la TFDConnection abierta del ERP.');
      Exit;
    end;
    FQuery.ParamByName('DESDE').AsDateTime:=StartOfTheDay(FDesde.Date);
    FQuery.ParamByName('HASTA').AsDateTime:=EndOfTheDay(FHasta.Date);
    FQuery.ParamByName('VENDEDOR').AsString:='***';
    FQuery.ParamByName('SUCURSAL').AsInteger:=-1;
    FQuery.ParamByName('ZONA').AsInteger:=-1;
    FQuery.Open;
    FPivot.RefreshFields;
    ConfigurarPivot;
    FStatus.Caption:=Format('%d registros cargados desde Firebird',[FQuery.RecordCount]);
  except
    on E:Exception do begin
      FStatus.Caption:='Error de conexión/consulta';
      Application.ShowException(E);
    end;
  end;
end;

procedure TFrmLarGridPivotGestionDemo.ConfigurarPivot;
var F:TLarPivotField;
  procedure RowField(const AName,ACaption:string; AIndex:Integer);
  begin
    F:=FPivot.FieldByName(AName); if F=nil then Exit;
    F.Caption:=ACaption; F.Area:=paRow; F.AreaIndex:=AIndex; F.ShowSubTotal:=True;
  end;
  procedure DataField(const AName,ACaption,AFormat:string; AIndex:Integer);
  begin
    F:=FPivot.FieldByName(AName); if F=nil then Exit;
    F.Caption:=ACaption; F.Area:=paData; F.AreaIndex:=AIndex;
    F.SummaryType:=psSum; F.DisplayFormat:=AFormat; F.Alignment:=pvaRight;
  end;
begin
  FPivot.BeginUpdate;
  try
    RowField('CODIGOARTICULO','Código',0);
    RowField('DETALLE','Artículo',1);
    DataField('CANTIDAD','Cantidad','#,##0.000',0);
    DataField('TOTAL_VENTA','Venta','#,##0.00',1);
    DataField('TOTAL_COSTO_VENTA','Costo','#,##0.00',2);
  finally
    FPivot.EndUpdate;
  end;
end;

end.
