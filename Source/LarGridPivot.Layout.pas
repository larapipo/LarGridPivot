unit LarGridPivot.Layout;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Filters;

type
  TLarPivotLayout = class
  public const
    CurrentVersion = 1;
  public
    class function SaveToString(AFields: TLarPivotFields;
      AFilters: TLarPivotFilters; AShowRowTotals, AShowColumnTotals,
      AShowGrandTotal: Boolean): string; static;
    class procedure LoadFromString(const AJSON: string; AFields: TLarPivotFields;
      AFilters: TLarPivotFilters; out AShowRowTotals, AShowColumnTotals,
      AShowGrandTotal: Boolean); static;
  end;

implementation

function AreaToInt(A: TLarPivotArea): Integer; begin Result := Ord(A); end;
function SummaryToInt(A: TLarPivotSummaryType): Integer; begin Result := Ord(A); end;
function SortToInt(A: TLarPivotSortOrder): Integer; begin Result := Ord(A); end;
function AlignToInt(A: TLarPivotAlignment): Integer; begin Result := Ord(A); end;

class function TLarPivotLayout.SaveToString(AFields: TLarPivotFields;
  AFilters: TLarPivotFilters; AShowRowTotals, AShowColumnTotals,
  AShowGrandTotal: Boolean): string;
var Root, O, FO: TJSONObject; Arr, Vals: TJSONArray; I, J: Integer; F: TLarPivotField; Fil: TLarPivotFilter;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('version', TJSONNumber.Create(CurrentVersion));
    Root.AddPair('showRowTotals', TJSONBool.Create(AShowRowTotals));
    Root.AddPair('showColumnTotals', TJSONBool.Create(AShowColumnTotals));
    Root.AddPair('showGrandTotal', TJSONBool.Create(AShowGrandTotal));
    Arr := TJSONArray.Create; Root.AddPair('fields', Arr);
    for I := 0 to AFields.Count - 1 do begin
      F := AFields[I]; O := TJSONObject.Create; Arr.AddElement(O);
      O.AddPair('name', F.FieldName); O.AddPair('caption', F.Caption);
      O.AddPair('area', TJSONNumber.Create(AreaToInt(F.Area)));
      O.AddPair('areaIndex', TJSONNumber.Create(F.AreaIndex));
      O.AddPair('summary', TJSONNumber.Create(SummaryToInt(F.SummaryType)));
      O.AddPair('sort', TJSONNumber.Create(SortToInt(F.SortOrder)));
      O.AddPair('alignment', TJSONNumber.Create(AlignToInt(F.Alignment)));
      O.AddPair('headerAlignment', TJSONNumber.Create(AlignToInt(F.HeaderAlignment)));
      O.AddPair('displayFormat', F.DisplayFormat); O.AddPair('width', TJSONNumber.Create(F.Width));
      O.AddPair('visible', TJSONBool.Create(F.Visible));
    end;
    Arr := TJSONArray.Create; Root.AddPair('filters', Arr);
    for I := 0 to AFilters.Count - 1 do begin
      Fil := AFilters[I]; FO := TJSONObject.Create; Arr.AddElement(FO);
      FO.AddPair('field', Fil.FieldName); FO.AddPair('enabled', TJSONBool.Create(Fil.Enabled));
      Vals := TJSONArray.Create; FO.AddPair('values', Vals);
      for J := 0 to Fil.Values.Count - 1 do Vals.Add(Fil.Values[J]);
    end;
    Result := Root.ToJSON;
  finally Root.Free; end;
end;

class procedure TLarPivotLayout.LoadFromString(const AJSON: string;
  AFields: TLarPivotFields; AFilters: TLarPivotFilters;
  out AShowRowTotals, AShowColumnTotals, AShowGrandTotal: Boolean);
var Root, O: TJSONObject; Arr, Vals: TJSONArray; I,J,N:Integer; F:TLarPivotField; Fil:TLarPivotFilter; V:TJSONValue;
  function JsonText(AObj:TJSONObject;const AName,ADefault:string):string;
  var JV:TJSONValue;
  begin JV:=AObj.GetValue(AName); if JV=nil then Result:=ADefault else Result:=JV.Value; end;
  function JsonInt(AObj:TJSONObject;const AName:string;ADefault,AMin,AMax:Integer):Integer;
  begin Result:=StrToIntDef(JsonText(AObj,AName,''),ADefault); if Result<AMin then Result:=AMin else if Result>AMax then Result:=AMax; end;
begin
  Root := TJSONObject.ParseJSONValue(AJSON) as TJSONObject;
  if Root=nil then raise EConvertError.Create('Layout LarGridPivot invalido');
  try
    V:=Root.GetValue('version'); if V=nil then raise EConvertError.Create('Layout sin version');
    N:=StrToIntDef(V.Value,0); if N>CurrentVersion then raise EConvertError.CreateFmt('Layout version %d no soportado',[N]);
    V:=Root.GetValue('showRowTotals'); AShowRowTotals:=(V=nil) or SameText(V.Value,'true');
    V:=Root.GetValue('showColumnTotals'); AShowColumnTotals:=(V=nil) or SameText(V.Value,'true');
    V:=Root.GetValue('showGrandTotal'); AShowGrandTotal:=(V=nil) or SameText(V.Value,'true');
    Arr:=Root.GetValue('fields') as TJSONArray;
    if Arr<>nil then for I:=0 to Arr.Count-1 do begin
      O:=Arr.Items[I] as TJSONObject; if O=nil then Continue;
      F:=AFields.FindField(JsonText(O,'name','')); if F=nil then Continue;
      F.Caption:=JsonText(O,'caption',F.Caption);
      F.Area:=TLarPivotArea(JsonInt(O,'area',Ord(F.Area),Ord(Low(TLarPivotArea)),Ord(High(TLarPivotArea))));
      F.AreaIndex:=JsonInt(O,'areaIndex',F.AreaIndex,-1,MaxInt);
      F.SummaryType:=TLarPivotSummaryType(JsonInt(O,'summary',Ord(F.SummaryType),Ord(Low(TLarPivotSummaryType)),Ord(High(TLarPivotSummaryType))));
      F.SortOrder:=TLarPivotSortOrder(JsonInt(O,'sort',Ord(F.SortOrder),Ord(Low(TLarPivotSortOrder)),Ord(High(TLarPivotSortOrder))));
      F.Alignment:=TLarPivotAlignment(JsonInt(O,'alignment',Ord(F.Alignment),Ord(Low(TLarPivotAlignment)),Ord(High(TLarPivotAlignment))));
      F.HeaderAlignment:=TLarPivotAlignment(JsonInt(O,'headerAlignment',Ord(F.HeaderAlignment),Ord(Low(TLarPivotAlignment)),Ord(High(TLarPivotAlignment))));
      F.DisplayFormat:=JsonText(O,'displayFormat',F.DisplayFormat);
      F.Width:=JsonInt(O,'width',F.Width,40,MaxInt);
      V:=O.GetValue('visible'); F.Visible:=(V=nil) or SameText(V.Value,'true');
    end;
    AFilters.Clear; Arr:=Root.GetValue('filters') as TJSONArray;
    if Arr<>nil then for I:=0 to Arr.Count-1 do begin
      O:=Arr.Items[I] as TJSONObject; if O=nil then Continue;
      if JsonText(O,'field','')='' then Continue;
      Fil:=AFilters.Ensure(JsonText(O,'field','')); V:=O.GetValue('enabled');
      Fil.Enabled:=(V=nil) or SameText(V.Value,'true');
      Vals:=O.GetValue('values') as TJSONArray;
      if Vals<>nil then for J:=0 to Vals.Count-1 do Fil.Values.Add(Vals.Items[J].Value);
    end;
  finally Root.Free; end;
end;

end.
