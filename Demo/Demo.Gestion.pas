unit Demo.Gestion;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.ComCtrls,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.Intf, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.DApt,
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
    FAnio, FMes:TEdit;
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
    'select v.* from VTAS_ANUAL_ARTIC_2(:anio, :codigo, :cliente, :suc, :mes, :Tipo_Fecha) v';

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

  FAnio:=TEdit.Create(Self); FAnio.Parent:=FTop;
  FAnio.Left:=8; FAnio.Top:=8; FAnio.Width:=70; FAnio.Text:=IntToStr(YearOf(Date));
  FMes:=TEdit.Create(Self); FMes.Parent:=FTop;
  FMes.Left:=86; FMes.Top:=8; FMes.Width:=45; FMes.Text:='0';

  FBtnAbrir:=TButton.Create(Self); FBtnAbrir.Parent:=FTop;
  FBtnAbrir.Left:=140; FBtnAbrir.Top:=7; FBtnAbrir.Width:=110;
  FBtnAbrir.Height:=27; FBtnAbrir.Caption:='Abrir ventas';
  FBtnAbrir.OnClick:=AbrirDatos;

  FStatus:=TLabel.Create(Self); FStatus.Parent:=FTop;
  FStatus.Left:=390; FStatus.Top:=13;
  FStatus.Caption:='Gestión local: GESTIONV3.FDB';

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
 FConnection.Params.Values['Password']:=''; { configure locally; never commit DB passwords }
 FConnection.Params.Values['CharacterSet']:='WIN1252';
 FConnection.Params.Values['Database']:='C:\\Proyectos Delphi\\GestionComercial\\Tablas IB\\GESTIONV3.FDB';
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

    FQuery.ParamByName('anio').AsInteger:=StrToIntDef(FAnio.Text,YearOf(Date));
    FQuery.ParamByName('codigo').AsString:='********';
    FQuery.ParamByName('cliente').AsString:='******';
    FQuery.ParamByName('suc').AsInteger:=-1;
    FQuery.ParamByName('mes').AsInteger:=StrToIntDef(FMes.Text,0);
    FQuery.ParamByName('Tipo_Fecha').AsString:='V';
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
    RowField('RUBRODETALLE','Rubro',0);
    RowField('SUBRUBRODETALL','Subrubro',1);
    RowField('DETALLE_STK','Artículo',2);
    F:=FPivot.FieldByName('MES'); if F<>nil then begin F.Caption:='Mes'; F.Area:=paColumn; F.AreaIndex:=0; end;
    DataField('CANTIDAD','Cantidad','#,##0.000',0);
    DataField('TOTAL_FINAL','Venta','#,##0.00',1);
  finally
    FPivot.EndUpdate;
  end;
end;

end.
