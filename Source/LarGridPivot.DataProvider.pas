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
    function GetValueByIndex(AIndex:Integer):Variant;
    function FieldIndexOf(const AFieldName:string):Integer;
  end;

  { In-memory snapshot used after the first dataset read.  Pivot operations such
    as filtering must not navigate FireDAC/ClientDataSet again. }
  TLarMemoryPivotProvider = class(TInterfacedObject, ILarPivotDataProvider)
  private
    FFieldNames:TArray<string>;
    FFieldTypes:TArray<TFieldType>;
    FFieldIndex:TDictionary<string,Integer>;
    FRows:TArray<TArray<Variant>>;
    FPos:Integer;
  public
    constructor Create(ADataSet:TDataSet);
    destructor Destroy; override;
    function GetFieldCount:Integer;
    function GetFieldName(AIndex:Integer):string;
    function GetFieldDataType(AIndex:Integer):TFieldType;
    function GetValue(const AFieldName:string):Variant;
    function First:Boolean;
    function Next:Boolean;
    function EOF:Boolean;
    function GetRecordCount:Integer;
    function GetValueByIndex(AIndex:Integer):Variant;
    function FieldIndexOf(const AFieldName:string):Integer;
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
    function GetValueByIndex(AIndex:Integer):Variant;
    function FieldIndexOf(const AFieldName:string):Integer;
    property DataSet: TDataSet read FDataSet;
  end;

implementation

constructor TLarMemoryPivotProvider.Create(ADataSet:TDataSet);
var I,N,Capacity:Integer; B:TBookmark; HasBookmark:Boolean;
begin
 inherited Create;
 if ADataSet=nil then raise EArgumentNilException.Create('ADataSet');
 FFieldIndex:=TDictionary<string,Integer>.Create;
 SetLength(FFieldNames,ADataSet.FieldCount);
 SetLength(FFieldTypes,ADataSet.FieldCount);
 for I:=0 to ADataSet.FieldCount-1 do begin
  FFieldNames[I]:=ADataSet.Fields[I].FieldName;
  FFieldTypes[I]:=ADataSet.Fields[I].DataType;
  FFieldIndex.AddOrSetValue(UpperCase(FFieldNames[I]),I);
 end;
 N:=0; Capacity:=0; FPos:=-1;
 if not ADataSet.Active then Exit;
 HasBookmark:=not ADataSet.IsEmpty;
 if HasBookmark then B:=ADataSet.GetBookmark;
 ADataSet.DisableControls;
 try
  ADataSet.First;
  while not ADataSet.Eof do begin
   if N>=Capacity then begin
    if Capacity=0 then Capacity:=1024 else Capacity:=Capacity*2;
    SetLength(FRows,Capacity);
   end;
   SetLength(FRows[N],ADataSet.FieldCount);
   for I:=0 to ADataSet.FieldCount-1 do
    FRows[N][I]:=ADataSet.Fields[I].Value;
   Inc(N);
   ADataSet.Next;
  end;
  SetLength(FRows,N);
 finally
  if HasBookmark then begin
   if ADataSet.BookmarkValid(B) then ADataSet.GotoBookmark(B);
   ADataSet.FreeBookmark(B);
  end;
  ADataSet.EnableControls;
 end;
end;

destructor TLarMemoryPivotProvider.Destroy;
begin FFieldIndex.Free; inherited; end;

function TLarMemoryPivotProvider.FieldIndexOf(const AFieldName:string):Integer;
begin
 if not FFieldIndex.TryGetValue(UpperCase(AFieldName),Result) then Result:=-1;
end;
function TLarMemoryPivotProvider.GetValueByIndex(AIndex:Integer):Variant;
begin
 if (FPos<0) or (FPos>=Length(FRows)) or (AIndex<0) or
    (AIndex>=Length(FFieldNames)) then Exit(Null);
 Result:=FRows[FPos][AIndex];
end;

function TLarMemoryPivotProvider.GetFieldCount:Integer;
begin Result:=Length(FFieldNames); end;
function TLarMemoryPivotProvider.GetFieldName(AIndex:Integer):string;
begin Result:=FFieldNames[AIndex]; end;
function TLarMemoryPivotProvider.GetFieldDataType(AIndex:Integer):TFieldType;
begin Result:=FFieldTypes[AIndex]; end;
function TLarMemoryPivotProvider.GetValue(const AFieldName:string):Variant;
var I:Integer;
begin
 if (FPos<0) or (FPos>=Length(FRows)) then Exit(Null);
 if not FFieldIndex.TryGetValue(UpperCase(AFieldName),I) then
  raise EDatabaseError.CreateFmt('Campo no encontrado: %s',[AFieldName]);
 Result:=FRows[FPos][I];
end;
function TLarMemoryPivotProvider.First:Boolean;
begin FPos:=0; Result:=Length(FRows)>0; end;
function TLarMemoryPivotProvider.Next:Boolean;
begin Inc(FPos); Result:=FPos<Length(FRows); end;
function TLarMemoryPivotProvider.EOF:Boolean;
begin Result:=(FPos<0) or (FPos>=Length(FRows)); end;
function TLarMemoryPivotProvider.GetRecordCount:Integer;
begin Result:=Length(FRows); end;

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

function TLarDataSetPivotProvider.FieldIndexOf(const AFieldName:string):Integer;
var F:TField;
begin F:=FDataSet.FindField(AFieldName); if F=nil then Result:=-1 else Result:=F.Index; end;

function TLarDataSetPivotProvider.GetValueByIndex(AIndex:Integer):Variant;
begin
 if (AIndex<0) or (AIndex>=FDataSet.FieldCount) then Exit(Null);
 Result:=FDataSet.Fields[AIndex].Value;
end;

end.
