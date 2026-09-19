unit LarGridPivot.Filters;

interface

uses
  System.Classes, System.SysUtils, System.Variants, System.Generics.Collections;

type
  TLarPivotFilter = class
  private
    FFieldName: string;
    FValues: TStringList;
    FEnabled: Boolean;
  public
    constructor Create(const AFieldName: string);
    destructor Destroy; override;
    procedure Clear;
    procedure AddValue(const AValue: Variant);
    function Accepts(const AValue: Variant): Boolean;
    property FieldName: string read FFieldName;
    property Values: TStringList read FValues;
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

  TLarPivotFilters = class
  private
    FItems: TObjectList<TLarPivotFilter>;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TLarPivotFilter;
  public
    constructor Create;
    destructor Destroy; override;
    function Ensure(const AFieldName: string): TLarPivotFilter;
    function Find(const AFieldName: string): TLarPivotFilter;
    procedure Clear;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TLarPivotFilter read GetItem; default;
  end;

implementation

constructor TLarPivotFilter.Create(const AFieldName: string);
begin
  inherited Create;
  FFieldName := AFieldName;
  FValues := TStringList.Create;
  FValues.CaseSensitive := False;
  FValues.Sorted := True;
  FValues.Duplicates := dupIgnore;
  FEnabled := True;
end;

destructor TLarPivotFilter.Destroy;
begin
  FValues.Free;
  inherited;
end;

procedure TLarPivotFilter.Clear;
begin
  FValues.Clear;
end;

procedure TLarPivotFilter.AddValue(const AValue: Variant);
begin
  if VarIsNull(AValue) or VarIsEmpty(AValue) then
    FValues.Add('(null)')
  else
    FValues.Add(VarToStr(AValue));
end;

function TLarPivotFilter.Accepts(const AValue: Variant): Boolean;
var S: string;
begin
  if not FEnabled then Exit(True);
  if FValues.Count = 0 then Exit(True);
  if VarIsNull(AValue) or VarIsEmpty(AValue) then S := '(null)' else S := VarToStr(AValue);
  Result := FValues.IndexOf(S) >= 0;
end;

constructor TLarPivotFilters.Create;
begin
  inherited;
  FItems := TObjectList<TLarPivotFilter>.Create(True);
end;

destructor TLarPivotFilters.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TLarPivotFilters.GetCount: Integer;
begin Result := FItems.Count; end;
function TLarPivotFilters.GetItem(AIndex: Integer): TLarPivotFilter;
begin Result := FItems[AIndex]; end;

function TLarPivotFilters.Find(const AFieldName: string): TLarPivotFilter;
var F: TLarPivotFilter;
begin
  Result := nil;
  for F in FItems do
    if SameText(F.FieldName, AFieldName) then Exit(F);
end;

function TLarPivotFilters.Ensure(const AFieldName: string): TLarPivotFilter;
begin
  Result := Find(AFieldName);
  if Result = nil then
  begin
    Result := TLarPivotFilter.Create(AFieldName);
    FItems.Add(Result);
  end;
end;

procedure TLarPivotFilters.Clear;
begin FItems.Clear; end;

end.
