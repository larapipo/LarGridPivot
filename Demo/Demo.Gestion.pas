unit Demo.Gestion;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.IOUtils, System.DateUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Themes, Vcl.Styles,
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
    FBtnAbrir:TButton;
    FBtnCampos:TButton;
    FBtnGuardarVista:TButton;
    FBtnBorrarVista:TButton;
    FEstilo:TComboBox;
    FStyleFiles:TStringList;
    FVistas:TComboBox;
    FStatus:TLabel;
    procedure AbrirDatos(Sender:TObject);
    procedure ConfigurarConexionDemo;
    procedure CambiarEstilo(Sender:TObject);
    procedure AlternarCampos(Sender:TObject);
    procedure CargarEstilosVcl;
    procedure GuardarVista(Sender:TObject);
    procedure CargarVista(Sender:TObject);
    procedure BorrarVista(Sender:TObject);
    procedure ActualizarVistas;
    procedure ConfigurarPivot;
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
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

  FStyleFiles:=TStringList.Create;
  FEstilo:=TComboBox.Create(Self); FEstilo.Parent:=FTop;
  FEstilo.Left:=260; FEstilo.Top:=8; FEstilo.Width:=150; FEstilo.Style:=csDropDownList;
  CargarEstilosVcl;
  FEstilo.OnChange:=CambiarEstilo;

  FBtnCampos:=TButton.Create(Self); FBtnCampos.Parent:=FTop;
  FBtnCampos.Left:=420; FBtnCampos.Top:=7; FBtnCampos.Width:=115; FBtnCampos.Height:=27;
  FBtnCampos.Caption:='Ocultar campos'; FBtnCampos.OnClick:=AlternarCampos;

  FVistas:=TComboBox.Create(Self); FVistas.Parent:=FTop;
  FVistas.Left:=545; FVistas.Top:=8; FVistas.Width:=150; FVistas.Style:=csDropDownList;
  FVistas.OnChange:=CargarVista;

  FBtnGuardarVista:=TButton.Create(Self); FBtnGuardarVista.Parent:=FTop;
  FBtnGuardarVista.Left:=700; FBtnGuardarVista.Top:=7; FBtnGuardarVista.Width:=95;
  FBtnGuardarVista.Height:=27; FBtnGuardarVista.Caption:='Guardar vista';
  FBtnGuardarVista.OnClick:=GuardarVista;

  FBtnBorrarVista:=TButton.Create(Self); FBtnBorrarVista.Parent:=FTop;
  FBtnBorrarVista.Left:=800; FBtnBorrarVista.Top:=7; FBtnBorrarVista.Width:=85;
  FBtnBorrarVista.Height:=27; FBtnBorrarVista.Caption:='Borrar vista';
  FBtnBorrarVista.OnClick:=BorrarVista;

  FStatus:=TLabel.Create(Self); FStatus.Parent:=FTop;
  FStatus.Left:=895; FStatus.Top:=13;
  FStatus.Caption:='Gestión local: GESTIONV3.FDB';

  FPivot:=TLarGridPivot.Create(Self); FPivot.Parent:=Self; FPivot.Align:=alClient;
  FPivot.Font.Name:='Segoe UI'; FPivot.Font.Size:=9;
  FPivot.Theme:=ptVclStyle;
  FPivot.DataSource:=FSource;
  if FileExists(ChangeFileExt(Application.ExeName,'.views')) then
    FPivot.LoadViewsFromFile(ChangeFileExt(Application.ExeName,'.views'));
  ActualizarVistas;
end;

destructor TFrmLarGridPivotGestionDemo.Destroy;
begin
 FStyleFiles.Free;
 inherited;
end;

procedure TFrmLarGridPivotGestionDemo.CargarEstilosVcl;
var BDSPath,PublicPath:string;
 procedure AddFolder(const AFolder:string);
 var Files:TStringDynArray; FN,N:string; I:Integer;
 begin
  if (AFolder='') or not TDirectory.Exists(AFolder) then Exit;
  try
   Files:=TDirectory.GetFiles(AFolder,'*.vsf',TSearchOption.soAllDirectories);
   for FN in Files do begin
    N:=ChangeFileExt(ExtractFileName(FN),'');
    if FEstilo.Items.IndexOf(N)>=0 then Continue;
    I:=FEstilo.Items.Add(N);
    while FStyleFiles.Count<=I do FStyleFiles.Add('');
    FStyleFiles[I]:=FN;
   end;
  except
  end;
 end;
begin
 FEstilo.Items.BeginUpdate;
 try
  FEstilo.Items.Clear; FStyleFiles.Clear;
  FEstilo.Items.Add('Windows'); FStyleFiles.Add('');
  AddFolder(TPath.Combine(ExtractFilePath(ParamStr(0)),'Styles'));
  BDSPath:=GetEnvironmentVariable('BDSCOMMONDIR');
  if BDSPath<>'' then AddFolder(TPath.Combine(BDSPath,'Styles'));
  BDSPath:=GetEnvironmentVariable('BDS');
  if BDSPath<>'' then AddFolder(TPath.Combine(BDSPath,'Redist\styles\vcl'));
  BDSPath:=GetEnvironmentVariable('ProgramFiles(x86)');
  if BDSPath<>'' then AddFolder(TPath.Combine(BDSPath,'Embarcadero\Studio\23.0\Redist\styles\vcl'));
  BDSPath:=ExpandFileName(TPath.Combine(ExtractFilePath(ParamStr(0)),'..\..\..\..\..'));
  AddFolder(TPath.Combine(BDSPath,'Redist\styles\vcl'));
  AddFolder(TPath.Combine(BDSPath,'Styles'));
  PublicPath:=GetEnvironmentVariable('PUBLIC');
  if PublicPath<>'' then AddFolder(TPath.Combine(PublicPath,'Documents\Embarcadero\Studio\23.0\Styles'));
  FEstilo.ItemIndex:=0;
 finally FEstilo.Items.EndUpdate; end;
end;

procedure TFrmLarGridPivotGestionDemo.CambiarEstilo(Sender:TObject);
var FN:string;
begin
 if FEstilo.ItemIndex<0 then Exit;
 FN:=FStyleFiles[FEstilo.ItemIndex];
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

procedure TFrmLarGridPivotGestionDemo.ActualizarVistas;
var N:TStringList; S,Current:string;
begin
 Current:=FVistas.Text; N:=TStringList.Create;
 try
  FPivot.GetViewNames(N);
  FVistas.Items.Assign(N);
  FVistas.ItemIndex:=FVistas.Items.IndexOf(Current);
 finally N.Free; end;
end;

procedure TFrmLarGridPivotGestionDemo.GuardarVista(Sender:TObject);
var N:string;
begin
 N:=FVistas.Text;
 if not InputQuery('Guardar vista','Nombre de la vista:',N) then Exit;
 N:=Trim(N); if N='' then Exit;
 FPivot.SaveView(N);
 FPivot.SaveViewsToFile(ChangeFileExt(Application.ExeName,'.views'));
 ActualizarVistas;
 FVistas.ItemIndex:=FVistas.Items.IndexOf(N);
end;

procedure TFrmLarGridPivotGestionDemo.CargarVista(Sender:TObject);
begin
 if FVistas.ItemIndex<0 then Exit;
 if FPivot.LoadView(FVistas.Items[FVistas.ItemIndex]) then
  FStatus.Caption:='Vista cargada: '+FVistas.Items[FVistas.ItemIndex];
end;

procedure TFrmLarGridPivotGestionDemo.BorrarVista(Sender:TObject);
var N:string;
begin
 if FVistas.ItemIndex<0 then Exit;
 N:=FVistas.Items[FVistas.ItemIndex];
 FPivot.DeleteView(N);
 FPivot.SaveViewsToFile(ChangeFileExt(Application.ExeName,'.views'));
 ActualizarVistas;
end;

procedure TFrmLarGridPivotGestionDemo.AlternarCampos(Sender:TObject);
begin
 FPivot.ShowFieldPanel:=not FPivot.ShowFieldPanel;
 if FPivot.ShowFieldPanel then FBtnCampos.Caption:='Ocultar campos'
 else FBtnCampos.Caption:='Mostrar campos';
end;

procedure TFrmLarGridPivotGestionDemo.ConfigurarConexionDemo;
begin
 { Do not invoke FireDAC's default connection editor: in a runtime-only demo
   its design-time factory may not be registered and raises "Object factory
   ... is missing". Configure the connection explicitly instead. }
 FConnection.LoginPrompt:=False;
 FConnection.Params.Clear;
 FConnection.DriverName:='FB';
 FConnection.Params.Values['Protocol']:='Local';
 FConnection.Params.Values['User_Name']:='SYSDBA';
 FConnection.Params.Values['Password']:='regulador';
 FConnection.LoginPrompt:=False;
 FConnection.Params.Values['CharacterSet']:='NONE';
 FConnection.Params.Values['SQLDialect']:='3';
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
    { Configure the pivot while the dataset is closed. Opening the query fires
      DataLink notifications; letting those build a default pivot first caused
      an expensive snapshot/build that was immediately discarded below. }
    FPivot.BeginUpdate;
    try
     FQuery.Open;
     FPivot.RefreshFields;
     ConfigurarPivot;
    finally
     { ConfigurarPivot has its own balanced Begin/EndUpdate. This outer batch
       absorbs DataLink notifications from Open and performs the final build. }
     FPivot.EndUpdate;
    end;
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
    F.Caption:=ACaption; F.Area:=paRow; F.AreaIndex:=AIndex; F.ShowSubTotal:=False;
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
    RowField('DETALLE_STK','Articulo',2);
    { NROCPBTE remains available above the pivot: dragging it after Artículo
      produces the leaf rows shown in the Gestion/DevExpress reference video. }
    F:=FPivot.FieldByName('MES'); if F<>nil then begin F.Caption:='Mes'; F.Area:=paColumn; F.AreaIndex:=0; end;
    DataField('CANTIDAD','Cantidad','#,##0.000',0);
    DataField('TOTAL_FINAL','Venta','#,##0.00',1);
  finally
    FPivot.EndUpdate;
  end;
end;

end.
