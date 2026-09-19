unit LarGridPivot.Grid;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  Vcl.Controls, Vcl.Graphics, Data.DB,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.DataProvider,
  LarGridPivot.Model, LarGridPivot.Engine;

type
  TLarGridPivot = class(TCustomControl)
  private
    FDataSource: TDataSource;
    FDataLink: TDataLink;
    FFields: TLarPivotFields;
    FEngine: TLarPivotEngine;
    FHeaderHeight: Integer;
    FRowHeight: Integer;
    FRowHeaderWidth: Integer;
    FUpdating: Integer;
    procedure SetDataSource(const Value: TDataSource);
    procedure SetFields(const Value: TLarPivotFields);
    procedure DataChanged(Sender: TObject);
    procedure BuildFieldsFromDataSet;
    function FirstDataField: TLarPivotField;
    function DefaultAlignment(AField: TLarPivotField): TAlignment;
    function FormatCellValue(const V: Variant; AField: TLarPivotField): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure RefreshFields;
    procedure Rebuild;
    function FieldByName(const AFieldName: string): TLarPivotField;
    property Engine: TLarPivotEngine read FEngine;
  published
    property Align;
    property Anchors;
    property Color default clWhite;
    property Font;
    property ParentFont;
    property ParentColor;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property DataSource: TDataSource read FDataSource write SetDataSource;
    property Fields: TLarPivotFields read FFields write SetFields;
    property HeaderHeight: Integer read FHeaderHeight write FHeaderHeight default 32;
    property RowHeight: Integer read FRowHeight write FRowHeight default 28;
    property RowHeaderWidth: Integer read FRowHeaderWidth write FRowHeaderWidth default 180;
  end;

implementation

type
  TLarPivotDataLink = class(TDataLink)
  private
    FOwner: TLarGridPivot;
  protected
    procedure DataSetChanged; override;
    procedure ActiveChanged; override;
  public
    constructor Create(AOwner: TLarGridPivot);
  end;

constructor TLarPivotDataLink.Create(AOwner: TLarGridPivot);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TLarPivotDataLink.ActiveChanged;
begin
  inherited;
  if Assigned(FOwner) then FOwner.DataChanged(Self);
end;

procedure TLarPivotDataLink.DataSetChanged;
begin
  inherited;
  if Assigned(FOwner) then FOwner.DataChanged(Self);
end;

constructor TLarGridPivot.Create(AOwner: TComponent);
begin
  inherited;
  Width := 640;
  Height := 360;
  Color := clWhite;
  FHeaderHeight := 32;
  FRowHeight := 28;
  FRowHeaderWidth := 180;
  FFields := TLarPivotFields.Create(Self);
  FEngine := TLarPivotEngine.Create(FFields);
  FDataLink := TLarPivotDataLink.Create(Self);
  ControlStyle := ControlStyle + [csOpaque];
end;

destructor TLarGridPivot.Destroy;
begin
  FDataLink.Free;
  FEngine.Free;
  FFields.Free;
  inherited;
end;

procedure TLarGridPivot.BeginUpdate;
begin
  Inc(FUpdating);
end;

procedure TLarGridPivot.EndUpdate;
begin
  if FUpdating > 0 then Dec(FUpdating);
  if FUpdating = 0 then Rebuild;
end;

procedure TLarGridPivot.SetDataSource(const Value: TDataSource);
begin
  if FDataSource = Value then Exit;
  FDataSource := Value;
  FDataLink.DataSource := Value;
  if Assigned(Value) then Value.FreeNotification(Self);
  RefreshFields;
end;

procedure TLarGridPivot.SetFields(const Value: TLarPivotFields);
begin
  FFields.Assign(Value);
  Rebuild;
end;

procedure TLarGridPivot.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FDataSource) then
    DataSource := nil;
end;

procedure TLarGridPivot.DataChanged(Sender: TObject);
begin
  if FUpdating = 0 then Rebuild;
end;

procedure TLarGridPivot.BuildFieldsFromDataSet;
var
  DS: TDataSet;
  I: Integer;
  PF: TLarPivotField;
  DF: TField;
begin
  if (FDataSource = nil) or (FDataSource.DataSet = nil) then Exit;
  DS := FDataSource.DataSet;
  if not DS.Active then Exit;
  FFields.BeginUpdate;
  try
    FFields.Clear;
    for I := 0 to DS.FieldCount - 1 do
    begin
      DF := DS.Fields[I];
      PF := FFields.Add;
      PF.FieldName := DF.FieldName;
      PF.Caption := DF.DisplayLabel;
      PF.Width := 100;
      case DF.DataType of
        ftSmallint, ftInteger, ftWord, ftLargeint, ftAutoInc,
        ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftSingle, ftExtended:
          PF.Alignment := pvaRight;
        ftDate, ftTime, ftDateTime, ftTimeStamp, ftTimeStampOffset:
          PF.Alignment := pvaCenter;
      else
        PF.Alignment := pvaLeft;
      end;
    end;
  finally
    FFields.EndUpdate;
  end;
end;

procedure TLarGridPivot.RefreshFields;
begin
  BuildFieldsFromDataSet;
  Invalidate;
end;

procedure TLarGridPivot.Rebuild;
var Provider: ILarPivotDataProvider;
begin
  if FUpdating > 0 then Exit;
  if (FDataSource = nil) or (FDataSource.DataSet = nil) or
     not FDataSource.DataSet.Active then
  begin
    FEngine.Model.Clear;
    Invalidate;
    Exit;
  end;
  if FFields.Count = 0 then BuildFieldsFromDataSet;
  Provider := TLarDataSetPivotProvider.Create(FDataSource.DataSet);
  FEngine.Build(Provider);
  Provider := nil;
  Invalidate;
end;

function TLarGridPivot.FieldByName(const AFieldName: string): TLarPivotField;
begin
  Result := FFields.FindField(AFieldName);
  if Result = nil then
    raise EDatabaseError.CreateFmt('Campo Pivot no encontrado: %s', [AFieldName]);
end;

function TLarGridPivot.FirstDataField: TLarPivotField;
var I: Integer;
begin
  Result := nil;
  for I := 0 to FFields.Count - 1 do
    if FFields[I].Visible and (FFields[I].Area = paData) then Exit(FFields[I]);
end;

function TLarGridPivot.DefaultAlignment(AField: TLarPivotField): TAlignment;
begin
  if AField = nil then Exit(taRightJustify);
  case AField.Alignment of
    pvaLeft: Result := taLeftJustify;
    pvaCenter: Result := taCenter;
    pvaRight: Result := taRightJustify;
  else Result := taLeftJustify;
  end;
end;

function TLarGridPivot.FormatCellValue(const V: Variant; AField: TLarPivotField): string;
begin
  if VarIsNull(V) or VarIsEmpty(V) then Exit('');
  if (AField <> nil) and (AField.DisplayFormat <> '') and VarIsNumeric(V) then
    Result := FormatFloat(AField.DisplayFormat, V)
  else
    Result := VarToStr(V);
end;

procedure TLarGridPivot.Paint;
var
  R: TRect;
  Row, Col, ColCount, CellW: Integer;
  RowKey, ColKey, S: string;
  DF: TLarPivotField;
  Cell: TLarPivotResultCell;
  V: Variant;
  Flags: Cardinal;

  procedure DrawTextCell(const ARect: TRect; const AText: string; AAlignment: TAlignment; ABold: Boolean = False);
  var RR: TRect;
  begin
    RR := ARect;
    Canvas.Brush.Color := Color;
    Canvas.FillRect(RR);
    Canvas.Pen.Color := $00E5E5E5;
    Canvas.Rectangle(RR);
    InflateRect(RR, -8, -2);
    Canvas.Font.Assign(Font);
    if ABold then Canvas.Font.Style := Canvas.Font.Style + [fsBold];
    Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
    case AAlignment of
      taRightJustify: Flags := Flags or DT_RIGHT;
      taCenter: Flags := Flags or DT_CENTER;
    else Flags := Flags or DT_LEFT;
    end;
    DrawText(Canvas.Handle, PChar(AText), Length(AText), RR, Flags);
  end;

begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  DF := FirstDataField;
  if (DF = nil) or (FEngine.Model.ColumnKeys.Count = 0) then
  begin
    Canvas.Font.Assign(Font);
    Canvas.Font.Color := clGrayText;
    R := ClientRect;
    InflateRect(R, -12, -12);
    DrawText(Canvas.Handle, 'Configure campos Row, Column y Data y ejecute Rebuild.', -1, R,
      DT_LEFT or DT_TOP or DT_WORDBREAK);
    Exit;
  end;

  ColCount := FEngine.Model.ColumnKeys.Count;
  CellW := 120;
  if ColCount > 0 then
    CellW := (ClientWidth - FRowHeaderWidth) div ColCount;
  if CellW < 80 then CellW := 80;

  R := Rect(0, 0, FRowHeaderWidth, FHeaderHeight);
  DrawTextCell(R, '', taLeftJustify, True);
  for Col := 0 to ColCount - 1 do
  begin
    ColKey := FEngine.Model.ColumnKeys[Col];
    R := Rect(FRowHeaderWidth + Col * CellW, 0,
              FRowHeaderWidth + (Col + 1) * CellW, FHeaderHeight);
    DrawTextCell(R, ColKey, taCenter, True);
  end;

  for Row := 0 to FEngine.Model.RowKeys.Count - 1 do
  begin
    RowKey := FEngine.Model.RowKeys[Row];
    R := Rect(0, FHeaderHeight + Row * FRowHeight,
              FRowHeaderWidth, FHeaderHeight + (Row + 1) * FRowHeight);
    DrawTextCell(R, RowKey, taLeftJustify, False);
    for Col := 0 to ColCount - 1 do
    begin
      ColKey := FEngine.Model.ColumnKeys[Col];
      Cell := FEngine.Model.FindCell(RowKey, ColKey, DF.FieldName);
      if Cell <> nil then V := Cell.Accumulator.Value(DF.SummaryType) else V := Null;
      S := FormatCellValue(V, DF);
      R := Rect(FRowHeaderWidth + Col * CellW, FHeaderHeight + Row * FRowHeight,
                FRowHeaderWidth + (Col + 1) * CellW, FHeaderHeight + (Row + 1) * FRowHeight);
      DrawTextCell(R, S, DefaultAlignment(DF), False);
    end;
  end;
end;

procedure TLarGridPivot.Resize;
begin
  inherited;
  Invalidate;
end;

end.
