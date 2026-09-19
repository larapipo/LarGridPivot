unit LarGridPivot.Engine;

interface

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.DataProvider,
  LarGridPivot.Model;

type
  TLarPivotEngine = class
  private
    FFields: TLarPivotFields;
    FModel: TLarPivotModel;
    function FieldsForArea(AArea: TLarPivotArea): TList<TLarPivotField>;
    function BuildKey(const AProvider: ILarPivotDataProvider; AArea: TLarPivotArea): string;
  public
    constructor Create(AFields: TLarPivotFields);
    destructor Destroy; override;
    procedure Build(const AProvider: ILarPivotDataProvider);
    property Model: TLarPivotModel read FModel;
  end;

implementation

constructor TLarPivotEngine.Create(AFields: TLarPivotFields);
begin
  inherited Create;
  if AFields = nil then raise EArgumentNilException.Create('AFields');
  FFields := AFields;
  FModel := TLarPivotModel.Create;
end;

destructor TLarPivotEngine.Destroy;
begin
  FModel.Free;
  inherited;
end;

function TLarPivotEngine.FieldsForArea(AArea: TLarPivotArea): TList<TLarPivotField>;
var I, J: Integer; F, T: TLarPivotField;
begin
  Result := TList<TLarPivotField>.Create;
  for I := 0 to FFields.Count - 1 do begin F := FFields[I]; if F.Visible and (F.Area = AArea) then Result.Add(F); end;
  for I := 0 to Result.Count - 2 do
    for J := I + 1 to Result.Count - 1 do
      if Result[I].AreaIndex > Result[J].AreaIndex then begin T := Result[I]; Result[I] := Result[J]; Result[J] := T; end;
end;

function TLarPivotEngine.BuildKey(const AProvider: ILarPivotDataProvider; AArea: TLarPivotArea): string;
var L: TList<TLarPivotField>; F: TLarPivotField; V: Variant;
begin
  Result := '';
  L := FieldsForArea(AArea);
  try
    for F in L do begin
      V := AProvider.GetValue(F.FieldName);
      if Result <> '' then Result := Result + ' | ';
      if VarIsNull(V) then Result := Result + '(null)' else Result := Result + VarToStr(V);
    end;
  finally L.Free; end;
end;

procedure TLarPivotEngine.Build(const AProvider: ILarPivotDataProvider);
var
  RowKey, ColKey: string;
  DataFields: TList<TLarPivotField>;
  F: TLarPivotField;
  Cell: TLarPivotResultCell;
  V: Variant;
begin
  if AProvider = nil then raise EArgumentNilException.Create('AProvider');
  FModel.Clear;
  DataFields := FieldsForArea(paData);
  try
    if DataFields.Count = 0 then Exit;
    if not AProvider.First then Exit;
    while not AProvider.EOF do
    begin
      RowKey := BuildKey(AProvider, paRow);
      ColKey := BuildKey(AProvider, paColumn);
      for F in DataFields do
      begin
        V := AProvider.GetValue(F.FieldName);
        Cell := FModel.EnsureCell(RowKey, ColKey, F.FieldName);
        Cell.Accumulator.Add(V);
      end;
      AProvider.Next;
    end;
  finally
    DataFields.Free;
  end;
end;

end.
