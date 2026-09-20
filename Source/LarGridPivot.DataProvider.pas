unit LarGridPivot.DataProvider;

interface

uses
  System.SysUtils, System.Variants, System.Generics.Collections, Data.DB;

type
  ILarPivotDataProvider = interface
    ['{15D47065-522C-42B4-BE77-5D22F7D7D24C}']
    function GetFieldCount: Integer;
    function GetFieldName(AIndex: Integer): string;
    function GetFieldDataType(AIndex: Integer): TFieldType;
    function GetValue(const AFieldName: string): Variant;
    function First: Boolean;
    function Next: Boolean;
    function EOF: Boolean;
    function GetRecordCount: Integer;
  end;

  TLarDataSetPivotProvider = class(TInterfacedObject, ILarPivotDataProvider)
  private
    FDataSet: TDataSet;
    FBookmark: TBookmark;
    FHasBookmark: Boolean;
    FControlsDisabled:Boolean;
    FFieldCache:TDictionary<string,TField>;
    procedure RestoreState;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function GetFieldCount: Integer;
    function GetFieldName(AIndex: Integer): string;
    function GetFieldDataType(AIndex: Integer): TFieldType;
    function GetValue(const AFieldName: string): Variant;
    function First: Boolean;
    function Next: Boolean;
    function EOF: Boolean;
    function GetRecordCount: Integer;
    property DataSet: TDataSet read FDataSet;
  end;

implementation

constructor TLarDataSetPivotProvider.Create(ADataSet:TDataSet);
var I:Integer;
begin
  inherited Create;
  if ADataSet = nil then
    raise EArgumentNilException.Create('ADataSet');
  FDataSet := ADataSet;
  FFieldCache:=TDictionary<string,TField>.Create;
  for I:=0 to FDataSet.FieldCount-1 do FFieldCache.AddOrSetValue(UpperCase(FDataSet.Fields[I].FieldName),FDataSet.Fields[I]);
  if FDataSet.Active then
  begin
    FDataSet.DisableControls;
    FControlsDisabled := True;
    if not FDataSet.IsEmpty then
    begin
      FBookmark := FDataSet.Bookmark;
      FHasBookmark := True;
    end;
  end;
end;

destructor TLarDataSetPivotProvider.Destroy;
begin
  RestoreState;
  FFieldCache.Free;
  inherited;
end;

procedure TLarDataSetPivotProvider.RestoreState;
begin
  if FDataSet = nil then Exit;
  if FDataSet.Active and FHasBookmark and FDataSet.BookmarkValid(FBookmark) then
    FDataSet.Bookmark := FBookmark;
  FHasBookmark := False;
  FBookmark := nil;
  if FControlsDisabled then
  begin
    FDataSet.EnableControls;
    FControlsDisabled := False;
  end;
end;

function TLarDataSetPivotProvider.GetFieldCount: Integer;
begin
  Result := FDataSet.FieldCount;
end;

function TLarDataSetPivotProvider.GetFieldName(AIndex: Integer): string;
begin
  Result := FDataSet.Fields[AIndex].FieldName;
end;

function TLarDataSetPivotProvider.GetFieldDataType(AIndex: Integer): TFieldType;
begin
  Result := FDataSet.Fields[AIndex].DataType;
end;

function TLarDataSetPivotProvider.GetValue(const AFieldName: string): Variant;
var F: TField;
begin
  if not FFieldCache.TryGetValue(UpperCase(AFieldName),F) then
    raise EDatabaseError.CreateFmt('Campo no encontrado: %s',[AFieldName]);
  Result:=F.Value;
end;

function TLarDataSetPivotProvider.First: Boolean;
begin
  if not FDataSet.Active then Exit(False);
  FDataSet.First;
  Result := not FDataSet.Eof;
end;

function TLarDataSetPivotProvider.Next: Boolean;
begin
  if not FDataSet.Eof then FDataSet.Next;
  Result := not FDataSet.Eof;
end;

function TLarDataSetPivotProvider.EOF: Boolean;
begin
  Result := (not FDataSet.Active) or FDataSet.Eof;
end;

function TLarDataSetPivotProvider.GetRecordCount: Integer;
begin
  Result := FDataSet.RecordCount;
end;

end.
