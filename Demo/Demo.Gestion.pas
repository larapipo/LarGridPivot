unit Demo.Gestion;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.IOUtils, System.DateUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Themes,
  Vcl.Styles, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.Intf, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.DApt,
  LarGridPivot.Grid, LarGridPivot.Types, LarGridPivot.Fields;

type
  TFrmLarGridPivotGestionDemo = class(TForm)
    pnlTop: TPanel;
    edAnio: TEdit;
    edMes: TEdit;
    btnAbrirVentas: TButton;
    cbEstilo: TComboBox;
    btnCampos: TButton;
    cbVistas: TComboBox;
    btnGuardarVista: TButton;
    btnBorrarVista: TButton;
    lblStatus: TLabel;
    LarGridPivot1: TLarGridPivot;
    FDConnection1: TFDConnection;
    FDQuery1: TFDQuery;
    DataSource1: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AbrirDatos(Sender: TObject);
    procedure CambiarEstilo(Sender: TObject);
    procedure AlternarCampos(Sender: TObject);
    procedure GuardarVista(Sender: TObject);
    procedure CargarVista(Sender: TObject);
    procedure BorrarVista(Sender: TObject);
  private
    FStyleFiles: TStringList;
    procedure ConfigurarConexionDemo;
    procedure CargarEstilosVcl;
    procedure ActualizarVistas;
    procedure ConfigurarPivot;
  public
    procedure UseConnection(AConnection: TFDConnection);
    property Connection: TFDConnection read FDConnection1;
  end;

implementation

{$R *.dfm}

const
  SQL_VENTAS =
    'select v.* from VTAS_ANUAL_ARTIC_2(:anio, :codigo, :cliente, :suc, :mes, :Tipo_Fecha) v';

procedure TFrmLarGridPivotGestionDemo.FormCreate(Sender: TObject);
begin
  FStyleFiles := TStringList.Create;

  edAnio.Text := IntToStr(YearOf(Date));
  edMes.Text := '0';

  ConfigurarConexionDemo;
  FDQuery1.SQL.Text := SQL_VENTAS;

  CargarEstilosVcl;
  if FileExists(ChangeFileExt(Application.ExeName, '.views')) then
    LarGridPivot1.LoadViewsFromFile(ChangeFileExt(Application.ExeName, '.views'));
  ActualizarVistas;
end;

procedure TFrmLarGridPivotGestionDemo.FormDestroy(Sender: TObject);
begin
  FStyleFiles.Free;
end;

procedure TFrmLarGridPivotGestionDemo.CargarEstilosVcl;
var
  BDSPath, PublicPath: string;

  procedure AddFolder(const AFolder: string);
  var
    Files: TStringDynArray;
    FN, N: string;
    I: Integer;
  begin
    if (AFolder = '') or not TDirectory.Exists(AFolder) then
      Exit;
    try
      Files := TDirectory.GetFiles(AFolder, '*.vsf', TSearchOption.soAllDirectories);
      for FN in Files do
      begin
        N := ChangeFileExt(ExtractFileName(FN), '');
        if cbEstilo.Items.IndexOf(N) >= 0 then
          Continue;
        I := cbEstilo.Items.Add(N);
        while FStyleFiles.Count <= I do
          FStyleFiles.Add('');
        FStyleFiles[I] := FN;
      end;
    except
      { Optional style folders must never prevent the demo from starting. }
    end;
  end;

begin
  cbEstilo.Items.BeginUpdate;
  try
    cbEstilo.Items.Clear;
    FStyleFiles.Clear;

    cbEstilo.Items.Add('Windows');
    FStyleFiles.Add('');

    AddFolder(TPath.Combine(ExtractFilePath(ParamStr(0)), 'Styles'));

    BDSPath := GetEnvironmentVariable('BDSCOMMONDIR');
    if BDSPath <> '' then
      AddFolder(TPath.Combine(BDSPath, 'Styles'));

    BDSPath := GetEnvironmentVariable('BDS');
    if BDSPath <> '' then
      AddFolder(TPath.Combine(BDSPath, 'Redist\styles\vcl'));

    BDSPath := GetEnvironmentVariable('ProgramFiles(x86)');
    if BDSPath <> '' then
      AddFolder(TPath.Combine(BDSPath,
        'Embarcadero\Studio\23.0\Redist\styles\vcl'));

    BDSPath := ExpandFileName(TPath.Combine(
      ExtractFilePath(ParamStr(0)), '..\..\..\..'));
    AddFolder(TPath.Combine(BDSPath, 'Redist\styles\vcl'));
    AddFolder(TPath.Combine(BDSPath, 'Styles'));

    PublicPath := GetEnvironmentVariable('PUBLIC');
    if PublicPath <> '' then
      AddFolder(TPath.Combine(PublicPath,
        'Documents\Embarcadero\Studio\23.0\Styles'));

    cbEstilo.ItemIndex := cbEstilo.Items.IndexOf(TStyleManager.ActiveStyle.Name);
    if cbEstilo.ItemIndex < 0 then
      cbEstilo.ItemIndex := 0;
  finally
    cbEstilo.Items.EndUpdate;
  end;
end;

procedure TFrmLarGridPivotGestionDemo.CambiarEstilo(Sender: TObject);
var
  FN, StyleName: string;
begin
  if cbEstilo.ItemIndex < 0 then
    Exit;

  FN := FStyleFiles[cbEstilo.ItemIndex];
  StyleName := cbEstilo.Items[cbEstilo.ItemIndex];

  try
    if FN = '' then
      TStyleManager.SetStyle('Windows')
    else
    begin
      if not TStyleManager.TrySetStyle(StyleName, False) then
        TStyleManager.SetStyle(TStyleManager.LoadFromFile(FN));
    end;

    LarGridPivot1.Theme := ptVclStyle;
    LarGridPivot1.Invalidate;
  except
    on E: Exception do
      Application.ShowException(E);
  end;
end;

procedure TFrmLarGridPivotGestionDemo.ActualizarVistas;
var
  N: TStringList;
  Current: string;
begin
  Current := cbVistas.Text;
  N := TStringList.Create;
  try
    LarGridPivot1.GetViewNames(N);
    cbVistas.Items.Assign(N);
    cbVistas.ItemIndex := cbVistas.Items.IndexOf(Current);
  finally
    N.Free;
  end;
end;

procedure TFrmLarGridPivotGestionDemo.GuardarVista(Sender: TObject);
var
  N: string;
begin
  N := cbVistas.Text;
  if not InputQuery('Guardar vista', 'Nombre de la vista:', N) then
    Exit;

  N := Trim(N);
  if N = '' then
    Exit;

  LarGridPivot1.SaveView(N);
  LarGridPivot1.SaveViewsToFile(ChangeFileExt(Application.ExeName, '.views'));
  ActualizarVistas;
  cbVistas.ItemIndex := cbVistas.Items.IndexOf(N);
end;

procedure TFrmLarGridPivotGestionDemo.CargarVista(Sender: TObject);
begin
  if cbVistas.ItemIndex < 0 then
    Exit;

  if LarGridPivot1.LoadView(cbVistas.Items[cbVistas.ItemIndex]) then
    lblStatus.Caption := 'Vista cargada: ' + cbVistas.Items[cbVistas.ItemIndex];
end;

procedure TFrmLarGridPivotGestionDemo.BorrarVista(Sender: TObject);
var
  N: string;
begin
  if cbVistas.ItemIndex < 0 then
    Exit;

  N := cbVistas.Items[cbVistas.ItemIndex];
  LarGridPivot1.DeleteView(N);
  LarGridPivot1.SaveViewsToFile(ChangeFileExt(Application.ExeName, '.views'));
  ActualizarVistas;
end;

procedure TFrmLarGridPivotGestionDemo.AlternarCampos(Sender: TObject);
begin
  LarGridPivot1.ShowFieldPanel := not LarGridPivot1.ShowFieldPanel;
  if LarGridPivot1.ShowFieldPanel then
    btnCampos.Caption := 'Ocultar campos'
  else
    btnCampos.Caption := 'Mostrar campos';
end;

procedure TFrmLarGridPivotGestionDemo.ConfigurarConexionDemo;
begin
  FDConnection1.Connected := False;
  FDConnection1.LoginPrompt := False;
  FDConnection1.Params.Clear;
  FDConnection1.DriverName := 'FB';
  FDConnection1.Params.Values['Protocol'] := 'Local';
  FDConnection1.Params.Values['User_Name'] := 'SYSDBA';
  FDConnection1.Params.Values['Password'] := 'regulador';
  FDConnection1.Params.Values['CharacterSet'] := 'NONE';
  FDConnection1.Params.Values['SQLDialect'] := '3';
  FDConnection1.Params.Values['Database'] :=
    'C:\Proyectos Delphi\GestionComercial\Tablas IB\GESTIONV3.FDB';
end;

procedure TFrmLarGridPivotGestionDemo.UseConnection(AConnection: TFDConnection);
begin
  if AConnection = nil then
    Exit;

  FDQuery1.Close;
  FDQuery1.Connection := AConnection;
  lblStatus.Caption := 'Conexi' + #243 + 'n FireDAC asignada: ' + AConnection.Name;
end;

procedure TFrmLarGridPivotGestionDemo.AbrirDatos(Sender: TObject);
begin
  try
    FDQuery1.Close;

    FDQuery1.ParamByName('anio').AsInteger :=
      StrToIntDef(edAnio.Text, YearOf(Date));
    FDQuery1.ParamByName('codigo').AsString := '********';
    FDQuery1.ParamByName('cliente').AsString := '******';
    FDQuery1.ParamByName('suc').AsInteger := -1;
    FDQuery1.ParamByName('mes').AsInteger := StrToIntDef(edMes.Text, 0);
    FDQuery1.ParamByName('Tipo_Fecha').AsString := 'V';

    LarGridPivot1.BeginUpdate;
    try
      FDQuery1.Open;
      LarGridPivot1.RefreshFields;
      ConfigurarPivot;
    finally
      LarGridPivot1.EndUpdate;
    end;

    lblStatus.Caption := Format('%d registros cargados desde Firebird',
      [FDQuery1.RecordCount]);
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Error de conexi' + #243 + 'n/consulta';
      Application.ShowException(E);
    end;
  end;
end;

procedure TFrmLarGridPivotGestionDemo.ConfigurarPivot;
var
  F: TLarPivotField;

  procedure RowField(const AName, ACaption: string; AIndex: Integer);
  begin
    F := LarGridPivot1.FieldByName(AName);
    if F = nil then
      Exit;
    F.Caption := ACaption;
    F.Area := paRow;
    F.AreaIndex := AIndex;
    F.ShowSubTotal := False;
  end;

  procedure DataField(const AName, ACaption, AFormat: string; AIndex: Integer);
  begin
    F := LarGridPivot1.FieldByName(AName);
    if F = nil then
      Exit;
    F.Caption := ACaption;
    F.Area := paData;
    F.AreaIndex := AIndex;
    F.SummaryType := psSum;
    F.DisplayFormat := AFormat;
    F.Alignment := pvaRight;
  end;

begin
  LarGridPivot1.BeginUpdate;
  try
    RowField('RUBRODETALLE', 'Rubro', 0);
    RowField('SUBRUBRODETALL', 'Subrubro', 1);
    RowField('DETALLE_STK', 'Articulo', 2);

    F := LarGridPivot1.FieldByName('MES');
    if F <> nil then
    begin
      F.Caption := 'Mes';
      F.Area := paColumn;
      F.AreaIndex := 0;
    end;

    DataField('CANTIDAD', 'Cantidad', '#,##0.000', 0);
    DataField('TOTAL_FINAL', 'Venta', '#,##0.00', 1);
  finally
    LarGridPivot1.EndUpdate;
  end;
end;

end.
