unit LarGridPivot.Model;

interface

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  LarGridPivot.Types;

type
  TLarPivotValueAccumulator = record
  private
    FSum: Double;
    FCount: Int64;
    FMin: Double;
    FMax: Double;
    FHasValue: Boolean;
  public
    procedure Clear;
    procedure Add(const AValue: Variant);
    function Value(ASummary: TLarPivotSummaryType): Variant;
  end;

  TLarPivotResultCell = class
  public
    RowKey: string;
    ColumnKey: string;
    DataField: string;
    Accumulator: TLarPivotValueAccumulator;
    RowSpan: Integer;
    ColSpan: Integer;
    constructor Create;
  end;

  TLarPivotModel = class
  private
    FCells: TObjectDictionary<string, TLarPivotResultCell>;
    FRowKeys: TList<string>;
    FColumnKeys: TList<string>;
    class function MakeCellKey(const ARowKey, AColumnKey, ADataField: string): string; static;
    procedure AddUnique(AList: TList<string>; const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function EnsureCell(const ARowKey, AColumnKey, ADataField: string): TLarPivotResultCell;
    function FindCell(const ARowKey, AColumnKey, ADataField: string): TLarPivotResultCell;
    property RowKeys: TList<string> read FRowKeys;
    property ColumnKeys: TList<string> read FColumnKeys;
  end;

implementation

procedure TLarPivotValueAccumulator.Clear;
begin
  FSum := 0; FCount := 0; FMin := 0; FMax := 0; FHasValue := False;
end;

procedure TLarPivotValueAccumulator.Add(const AValue: Variant);
var V: Double;
begin
  if VarIsNull(AValue) or VarIsEmpty(AValue) or not VarIsNumeric(AValue) then Exit;
  V := AValue;
  if not FHasValue then begin FMin := V; FMax := V; FHasValue := True; end
  else begin if V < FMin then FMin := V; if V > FMax then FMax := V; end;
  FSum := FSum + V;
  Inc(FCount);
end;

function TLarPivotValueAccumulator.Value(ASummary: TLarPivotSummaryType): Variant;
begin
  case ASummary of
    psSum: Result := FSum;
    psCount: Result := FCount;
    psAverage: if FCount > 0 then Result := FSum / FCount else Result := Null;
    psMin: if FHasValue then Result := FMin else Result := Null;
    psMax: if FHasValue then Result := FMax else Result := Null;
  else Result := Null;
  end;
end;

constructor TLarPivotResultCell.Create;
begin
  inherited;
  RowSpan := 1; ColSpan := 1; Accumulator.Clear;
end;

constructor TLarPivotModel.Create;
begin
  inherited;
  FCells := TObjectDictionary<string, TLarPivotResultCell>.Create([doOwnsValues]);
  FRowKeys := TList<string>.Create;
  FColumnKeys := TList<string>.Create;
end;

destructor TLarPivotModel.Destroy;
begin
  FColumnKeys.Free; FRowKeys.Free; FCells.Free; inherited;
end;

procedure TLarPivotModel.Clear;
begin
  FCells.Clear; FRowKeys.Clear; FColumnKeys.Clear;
end;

class function TLarPivotModel.MakeCellKey(const ARowKey, AColumnKey, ADataField: string): string;
begin
  Result := ARowKey + #30 + AColumnKey + #30 + UpperCase(ADataField);
end;

procedure TLarPivotModel.AddUnique(AList: TList<string>; const AValue: string);
begin
  if AList.IndexOf(AValue) < 0 then AList.Add(AValue);
end;

function TLarPivotModel.EnsureCell(const ARowKey, AColumnKey, ADataField: string): TLarPivotResultCell;
var K: string;
begin
  K := MakeCellKey(ARowKey, AColumnKey, ADataField);
  if not FCells.TryGetValue(K, Result) then
  begin
    Result := TLarPivotResultCell.Create;
    Result.RowKey := ARowKey; Result.ColumnKey := AColumnKey; Result.DataField := ADataField;
    FCells.Add(K, Result);
  end;
  AddUnique(FRowKeys, ARowKey);
  AddUnique(FColumnKeys, AColumnKey);
end;

function TLarPivotModel.FindCell(const ARowKey, AColumnKey, ADataField: string): TLarPivotResultCell;
begin
  if not FCells.TryGetValue(MakeCellKey(ARowKey, AColumnKey, ADataField), Result) then Result := nil;
end;

end.
