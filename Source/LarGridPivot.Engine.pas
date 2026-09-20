unit LarGridPivot.Engine;

interface

uses
  System.SysUtils, System.Variants, System.Generics.Collections, System.Generics.Defaults,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Filters,
  LarGridPivot.DataProvider, LarGridPivot.Model;

type
  TLarPivotEngine = class
  private
    FFields: TLarPivotFields;
    FFilters: TLarPivotFilters;
    FModel: TLarPivotModel;
    function FieldsForArea(AArea: TLarPivotArea): TList<TLarPivotField>;
    function BuildKey(const AProvider:ILarPivotDataProvider; AFields:TList<TLarPivotField>):string;
    function EncodeKeyPart(const S: string): string;
    function CompareKeys(const A, B: string; AFields: TList<TLarPivotField>): Integer;
    procedure SortKeys(AKeys: TList<string>; AFields: TList<TLarPivotField>);
    function RecordAccepted(const AProvider: ILarPivotDataProvider): Boolean;
    procedure AddValue(const ARowKey, AColKey: string; AField: TLarPivotField; const AValue: Variant);
    procedure AddValueRaw(const ARowKey, AColKey: string; AField: TLarPivotField; const AValue: Variant);
    function RowPrefix(const ARowKey:string; ALevel:Integer):string;
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

function TLarPivotEngine.BuildKey(const AProvider:ILarPivotDataProvider;AFields:TList<TLarPivotField>):string;
var F:TLarPivotField; V:Variant;
begin
 Result:='';
 for F in AFields do begin
  V:=AProvider.GetValue(F.FieldName);
  if Result<>'' then Result:=Result+#29;
  if VarIsNull(V) then Result:=Result+EncodeKeyPart('(null)')
  else Result:=Result+EncodeKeyPart(VarToStr(V));
 end;
end;

function TLarPivotEngine.CompareKeys(const A,B:string;AFields:TList<TLarPivotField>):Integer;
var I,PA,PB:Integer; SA,SB:string;
 function NextPart(const K:string;var P:Integer):string;
 var L:Integer;
 begin
  Result:=''; L:=Length(K);
  while P<=L do begin
   if K[P]=#29 then begin
    if (P<L) and (K[P+1]=#29) then begin Result:=Result+#29; Inc(P,2); Continue; end;
    Inc(P); Exit;
   end;
   Result:=Result+K[P]; Inc(P);
  end;
 end;
begin
 Result:=0; PA:=1; PB:=1;
 for I:=0 to AFields.Count-1 do begin
  SA:=NextPart(A,PA); SB:=NextPart(B,PB);
  Result:=CompareText(SA,SB);
  if AFields[I].SortOrder=psoDescending then Result:=-Result;
  if Result<>0 then Exit;
 end;
end;

procedure TLarPivotEngine.SortKeys(AKeys:TList<string>;AFields:TList<TLarPivotField>);
begin
 if (AFields=nil) or (AFields.Count=0) or (AKeys.Count<2) then Exit;
 AKeys.Sort(TComparer<string>.Construct(
  function(const L,R:string):Integer
  begin Result:=CompareKeys(L,R,AFields); end));
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

procedure TLarPivotEngine.AddValueRaw(const ARowKey, AColKey: string; AField: TLarPivotField; const AValue: Variant);
var Cell: TLarPivotResultCell;
begin
  Cell := FModel.EnsureAggregateCell(ARowKey, AColKey, AField.FieldName);
  Cell.Accumulator.Add(AValue);
end;

function TLarPivotEngine.RowPrefix(const ARowKey:string;ALevel:Integer):string;
var P,I,L:Integer;
begin
 Result:=''; P:=1; I:=0; L:=Length(ARowKey);
 while (P<=L) and (I<=ALevel) do begin
  if ARowKey[P]=#29 then begin
   if (P<L) and (ARowKey[P+1]=#29) then begin Result:=Result+#29#29; Inc(P,2); Continue; end;
   if I=ALevel then Exit;
   Result:=Result+#29; Inc(I); Inc(P); Continue;
  end;
  Result:=Result+ARowKey[P]; Inc(P);
 end;
end;

procedure TLarPivotEngine.Build(const AProvider: ILarPivotDataProvider);
var RowKey, ColKey, PrefixKey: string; DataFields,RowFields,ColumnFields: TList<TLarPivotField>; F: TLarPivotField; V: Variant; Lvl:Integer;
begin
  if AProvider = nil then raise EArgumentNilException.Create('AProvider');
  FModel.Clear;
  DataFields := FieldsForArea(paData); RowFields:=FieldsForArea(paRow); ColumnFields:=FieldsForArea(paColumn);
  try
    if DataFields.Count = 0 then Exit;
    if not AProvider.First then Exit;
    while not AProvider.EOF do
    begin
      if RecordAccepted(AProvider) then
      begin
        RowKey:=BuildKey(AProvider,RowFields);
        ColKey:=BuildKey(AProvider,ColumnFields);
        for F in DataFields do
        begin
          V := AProvider.GetValue(F.FieldName);
          AddValue(RowKey, ColKey, F, V);
          AddValue(RowKey, LAR_PIVOT_TOTAL_KEY, F, V);
          { Accumulate every non-leaf row prefix.  These cells back hierarchical
            row subtotals such as SUCURSAL -> VENDEDOR. }
          for Lvl:=0 to RowFields.Count-2 do begin
            PrefixKey:=RowPrefix(RowKey,Lvl);
            AddValueRaw(PrefixKey,ColKey,F,V);
            AddValueRaw(PrefixKey,LAR_PIVOT_TOTAL_KEY,F,V);
          end;
          AddValue(LAR_PIVOT_TOTAL_KEY, ColKey, F, V);
          AddValue(LAR_PIVOT_TOTAL_KEY, LAR_PIVOT_TOTAL_KEY, F, V);
        end;
      end;
      AProvider.Next;
    end;
    FModel.RowKeys.Remove(LAR_PIVOT_TOTAL_KEY);
    FModel.ColumnKeys.Remove(LAR_PIVOT_TOTAL_KEY);
    SortKeys(FModel.RowKeys,RowFields); SortKeys(FModel.ColumnKeys,ColumnFields);
  finally ColumnFields.Free; RowFields.Free; DataFields.Free; end;
end;

end.
