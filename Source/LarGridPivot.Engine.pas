unit LarGridPivot.Engine;

interface

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Filters,
  LarGridPivot.DataProvider, LarGridPivot.Model;

type
  TLarPivotEngine = class
  private
    FFields: TLarPivotFields;
    FFilters: TLarPivotFilters;
    FModel: TLarPivotModel;
    function FieldsForArea(AArea: TLarPivotArea): TList<TLarPivotField>;
    function BuildKey(const AProvider: ILarPivotDataProvider; AArea: TLarPivotArea): string;
    function EncodeKeyPart(const S: string): string;
    function RecordAccepted(const AProvider: ILarPivotDataProvider): Boolean;
    procedure AddValue(const ARowKey, AColKey: string; AField: TLarPivotField; const AValue: Variant);
  public
    constructor Create(AFields: TLarPivotFields);
    destructor Destroy; override;
    procedure Build(const AProvider: ILarPivotDataProvider);
    property Model: TLarPivotModel read FModel;
    property Filters: TLarPivotFilters read FFilters;
  end;

const
  LAR_PIVOT_TOTAL_KEY = #1'LAR_TOTAL';

implementation

constructor TLarPivotEngine.Create(AFields: TLarPivotFields);
begin
  inherited Create;
  if AFields = nil then raise EArgumentNilException.Create('AFields');
  FFields := AFields;
  FFilters := TLarPivotFilters.Create;
  FModel := TLarPivotModel.Create;
end;

destructor TLarPivotEngine.Destroy;
begin
  FModel.Free;
  FFilters.Free;
  inherited;
end;

function TLarPivotEngine.FieldsForArea(AArea: TLarPivotArea): TList<TLarPivotField>;
var I, J: Integer; F, T: TLarPivotField;
begin
  Result := TList<TLarPivotField>.Create;
  for I := 0 to FFields.Count - 1 do
  begin
    F := FFields[I];
    if F.Visible and (F.Area = AArea) then Result.Add(F);
  end;
  for I := 0 to Result.Count - 2 do
    for J := I + 1 to Result.Count - 1 do
      if Result[I].AreaIndex > Result[J].AreaIndex then
      begin T := Result[I]; Result[I] := Result[J]; Result[J] := T; end;
end;

function TLarPivotEngine.EncodeKeyPart(const S:string):string;
begin
 Result:=StringReplace(S,#29,#29#29,[rfReplaceAll]);
end;

function TLarPivotEngine.BuildKey(const AProvider: ILarPivotDataProvider; AArea: TLarPivotArea): string;
var L: TList<TLarPivotField>; F: TLarPivotField; V: Variant;
begin
  Result := '';
  L := FieldsForArea(AArea);
  try
    for F in L do
    begin
      V := AProvider.GetValue(F.FieldName);
      if Result <> '' then Result := Result + #29;
      if VarIsNull(V) then Result := Result + EncodeKeyPart('(null)') else Result := Result + EncodeKeyPart(VarToStr(V));
    end;
  finally L.Free; end;
end;

function TLarPivotEngine.RecordAccepted(const AProvider: ILarPivotDataProvider): Boolean;
var I:Integer; F:TLarPivotField; Filter:TLarPivotFilter;
begin
  Result:=True;
  { A filter belongs to the field, not to the filter area.  A row/column/data
    field remains filterable exactly like a TcxPivotGrid field. }
  for I:=0 to FFields.Count-1 do begin
    F:=FFields[I];
    if not F.Visible then Continue;
    Filter:=FFilters.Find(F.FieldName);
    if (Filter<>nil) and Filter.Enabled and
       not Filter.Accepts(AProvider.GetValue(F.FieldName)) then Exit(False);
  end;
end;

procedure TLarPivotEngine.AddValue(const ARowKey, AColKey: string; AField: TLarPivotField; const AValue: Variant);
var Cell: TLarPivotResultCell;
begin
  Cell := FModel.EnsureCell(ARowKey, AColKey, AField.FieldName);
  Cell.Accumulator.Add(AValue);
end;

procedure TLarPivotEngine.Build(const AProvider: ILarPivotDataProvider);
var RowKey, ColKey: string; DataFields: TList<TLarPivotField>; F: TLarPivotField; V: Variant;
begin
  if AProvider = nil then raise EArgumentNilException.Create('AProvider');
  FModel.Clear;
  DataFields := FieldsForArea(paData);
  try
    if DataFields.Count = 0 then Exit;
    if not AProvider.First then Exit;
    while not AProvider.EOF do
    begin
      if RecordAccepted(AProvider) then
      begin
        RowKey := BuildKey(AProvider, paRow);
        ColKey := BuildKey(AProvider, paColumn);
        for F in DataFields do
        begin
          V := AProvider.GetValue(F.FieldName);
          AddValue(RowKey, ColKey, F, V);
          AddValue(RowKey, LAR_PIVOT_TOTAL_KEY, F, V);
          AddValue(LAR_PIVOT_TOTAL_KEY, ColKey, F, V);
          AddValue(LAR_PIVOT_TOTAL_KEY, LAR_PIVOT_TOTAL_KEY, F, V);
        end;
      end;
      AProvider.Next;
    end;
    FModel.RowKeys.Remove(LAR_PIVOT_TOTAL_KEY);
    FModel.ColumnKeys.Remove(LAR_PIVOT_TOTAL_KEY);
  finally DataFields.Free; end;
end;

end.
