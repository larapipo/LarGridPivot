unit LarGridPivot.ViewInfo;

interface

uses
  System.SysUtils, System.Types, System.Classes, System.Generics.Collections,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.LayoutEngine, LarGridPivot.Model,
  LarGridPivot.Engine;

type
  TLarPivotViewItem = class
  public
    Kind: TLarPivotViewElementKind;
    Bounds: TRect;
    Field: TLarPivotField;
    RowKey: string;
    ColumnKey: string;
    Level: Integer;
    DataIndex: Integer;
    Caption: string;
    constructor Create;
    function Contains(AX, AY: Integer): Boolean;
  end;

  TLarPivotViewInfo = class
  private
    FItems: TObjectList<TLarPivotViewItem>;
    FLayout: TLarPivotLayoutEngine;
    FHeaderTop: Integer;
    FHeaderHeight: Integer;
    FRowHeight: Integer;
    FRowHeaderWidth: Integer;
    FHeaderLevels: Integer;
    FContentBottom:Integer;
    procedure AddHeaderNode(ANode: TLarPivotHeaderNode; AColumnFields: TList<TLarPivotField>);
  public
    constructor Create(ALayout: TLarPivotLayoutEngine);
    destructor Destroy; override;
    procedure Clear;
    procedure BuildHeaders(ARowFields, AColumnFields, ADataFields: TList<TLarPivotField>;
      AHeaderTop, AHeaderHeight, ARowHeaderWidth: Integer);
    procedure BuildBody(ARowFields, ADataFields: TList<TLarPivotField>; ARows: TList<string>;
      AHeaderLevels: Integer; AShowRowTotals, AShowColumnTotals, AShowGrandTotal: Boolean; ACollapsedGroups:TStrings;
      AViewLeft, AViewTop, AViewRight, AViewBottom:Integer);
    function HitTest(AX, AY: Integer): TLarPivotHitTest;
    function FieldAtResizeEdge(AX, AY, ATolerance: Integer): TLarPivotField;
    property Items: TObjectList<TLarPivotViewItem> read FItems;
    property HeaderTop: Integer read FHeaderTop;
    property HeaderHeight: Integer read FHeaderHeight;
    property RowHeight: Integer read FRowHeight write FRowHeight;
    property RowHeaderWidth: Integer read FRowHeaderWidth;
    property ContentBottom:Integer read FContentBottom;
  end;

implementation

constructor TLarPivotViewItem.Create;
begin
 inherited Create;
 Kind:=pvekNone; Bounds:=Rect(0,0,0,0); Field:=nil;
 Level:=-1; DataIndex:=-1; Caption:='';
end;

function TLarPivotViewItem.Contains(AX,AY:Integer):Boolean;
begin
 Result:=(AX>=Bounds.Left) and (AX<Bounds.Right) and
   (AY>=Bounds.Top) and (AY<Bounds.Bottom);
end;

constructor TLarPivotViewInfo.Create(ALayout:TLarPivotLayoutEngine);
begin
 inherited Create;
 FLayout:=ALayout;
 FItems:=TObjectList<TLarPivotViewItem>.Create(True);
 FRowHeight:=28;
end;

destructor TLarPivotViewInfo.Destroy;
begin
 FItems.Free;
 inherited;
end;

procedure TLarPivotViewInfo.Clear;
begin
 FItems.Clear;
end;

procedure TLarPivotViewInfo.AddHeaderNode(ANode:TLarPivotHeaderNode; AColumnFields:TList<TLarPivotField>);
var C:TLarPivotHeaderNode; Item:TLarPivotViewItem;
begin
 Item:=TLarPivotViewItem.Create;
 Item.Kind:=pvekColumnValue; Item.Caption:=ANode.Caption;
 if (ANode.Level>=0) and (ANode.Level<AColumnFields.Count) then Item.Field:=AColumnFields[ANode.Level];
 Item.Bounds:=Rect(ANode.Left,FHeaderTop+(ANode.Level+1)*FHeaderHeight,
   ANode.Left+ANode.Width,FHeaderTop+(ANode.Level+2)*FHeaderHeight);
 Item.ColumnKey:=ANode.KeyPrefix;
 Item.Level:=ANode.Level;
 FItems.Add(Item);
 for C in ANode.Children do AddHeaderNode(C,AColumnFields);
end;

procedure TLarPivotViewInfo.BuildHeaders(ARowFields,AColumnFields,ADataFields:TList<TLarPivotField>;
 AHeaderTop,AHeaderHeight,ARowHeaderWidth:Integer);
var I,X,Levels:Integer; Item:TLarPivotViewItem; Root:TLarPivotHeaderNode; VC:TLarPivotVisualColumn;
begin
 Clear;
 FHeaderTop:=AHeaderTop; FHeaderHeight:=AHeaderHeight; FRowHeaderWidth:=ARowHeaderWidth;
 Levels:=AColumnFields.Count;
 if AColumnFields.Count>0 then Inc(Levels); { field-name band above column members }
 if ADataFields.Count>1 then Inc(Levels);
 if Levels=0 then Levels:=1;
 FHeaderLevels:=Levels;

 X:=0;
 for I:=0 to ARowFields.Count-1 do begin
  Item:=TLarPivotViewItem.Create;
  Item.Kind:=pvekFieldHeader; Item.Field:=ARowFields[I]; Item.Level:=I;
  Item.Caption:=ARowFields[I].Caption; if Item.Caption='' then Item.Caption:=ARowFields[I].FieldName;
  Item.Bounds:=Rect(X,FHeaderTop+(Levels-1)*FHeaderHeight,X+ARowFields[I].Width,FHeaderTop+Levels*FHeaderHeight);
  FItems.Add(Item); Inc(X,ARowFields[I].Width);
 end;

 if AColumnFields.Count>0 then begin
  X:=FRowHeaderWidth;
  for I:=0 to AColumnFields.Count-1 do begin
   Item:=TLarPivotViewItem.Create;
   Item.Kind:=pvekFieldHeader; Item.Field:=AColumnFields[I]; Item.Level:=I;
   Item.Caption:=AColumnFields[I].Caption; if Item.Caption='' then Item.Caption:=AColumnFields[I].FieldName;
   Item.Bounds:=Rect(X,FHeaderTop,X+AColumnFields[I].Width,FHeaderTop+FHeaderHeight);
   FItems.Add(Item); Inc(X,AColumnFields[I].Width);
  end;
 end;
 for Root in FLayout.Roots do AddHeaderNode(Root,AColumnFields);

 if ADataFields.Count>1 then
  for I:=0 to FLayout.Columns.Count-1 do begin
   VC:=FLayout.Columns[I];
   Item:=TLarPivotViewItem.Create;
   Item.Kind:=pvekFieldHeader; Item.Field:=VC.DataField; Item.ColumnKey:=VC.ColumnKey;
   Item.Caption:=VC.DataField.Caption; if Item.Caption='' then Item.Caption:=VC.DataField.FieldName;
   Item.DataIndex:=I; Item.Level:=AColumnFields.Count;
   Item.Bounds:=Rect(VC.Left,FHeaderTop+(AColumnFields.Count+1)*FHeaderHeight,
     VC.Left+VC.Width,FHeaderTop+(AColumnFields.Count+2)*FHeaderHeight);
   FItems.Add(Item);
  end
 else if (AColumnFields.Count=0) and (ADataFields.Count=1) then begin
  Item:=TLarPivotViewItem.Create;
  Item.Kind:=pvekFieldHeader; Item.Field:=ADataFields[0]; Item.DataIndex:=0; Item.Level:=0;
  Item.Caption:=ADataFields[0].Caption; if Item.Caption='' then Item.Caption:=ADataFields[0].FieldName;
  Item.Bounds:=Rect(FRowHeaderWidth,FHeaderTop,FRowHeaderWidth+ADataFields[0].Width,
    FHeaderTop+FHeaderHeight);
  FItems.Add(Item);
 end;
end;

procedure TLarPivotViewInfo.BuildBody(ARowFields,ADataFields:TList<TLarPivotField>;
 ARows:TList<string>;AHeaderLevels:Integer;AShowRowTotals,AShowColumnTotals,AShowGrandTotal:Boolean; ACollapsedGroups:TStrings;
 AViewLeft,AViewTop,AViewRight,AViewBottom:Integer);
var Row,I,Lvl,X,Y,RightEdge,CLvl:Integer; Item:TLarPivotViewItem; VC:TLarPivotVisualColumn;
 PrefixCache,PartCache:TDictionary<string,string>; CollapsedSet:TDictionary<string,Byte>;
 function KeyPart(const AKey:string;ALevel:Integer):string;
 var P,N,J:Integer; CacheKey:string;
 begin
  CacheKey:=IntToStr(ALevel)+'|'+AKey;
  if PartCache.TryGetValue(CacheKey,Result) then Exit;
  Result:=''; P:=1; N:=0;
  for J:=1 to Length(AKey)+1 do
   if (J>Length(AKey)) or (AKey[J]=#29) then begin
    if N=ALevel then begin Result:=Copy(AKey,P,J-P); Break; end;
    Inc(N); P:=J+1;
   end;
  PartCache.AddOrSetValue(CacheKey,Result);
 end;
 function PrefixKey(const AKey:string;ALevel:Integer):string;
 var J:Integer; CacheKey:string;
 begin
  CacheKey:=IntToStr(ALevel)+'|'+AKey;
  if PrefixCache.TryGetValue(CacheKey,Result) then Exit;
  Result:='';
  for J:=0 to ALevel do begin
   if J>0 then Result:=Result+#29;
   Result:=Result+KeyPart(AKey,J);
  end;
  PrefixCache.AddOrSetValue(CacheKey,Result);
 end;
 function RowVisible(AY:Integer):Boolean;
 begin Result:=(AY+FRowHeight>=AViewTop) and (AY<=AViewBottom); end;
 function ColumnVisible(ALeft,AWidth:Integer):Boolean;
 begin Result:=(ALeft+AWidth>=AViewLeft) and (ALeft<=AViewRight); end;
 function GroupID(const AKey:string;ALevel:Integer):string;
 begin Result:=IntToStr(ALevel)+'|'+PrefixKey(AKey,ALevel); end;
 function IsCollapsed(const AKey:string;ALevel:Integer):Boolean;
 begin Result:=CollapsedSet.ContainsKey(GroupID(AKey,ALevel)); end;
 function CollapsedLevel(const AKey:string):Integer;
 var K:Integer;
 begin
  Result:=-1;
  for K:=0 to ARowFields.Count-2 do
   if IsCollapsed(AKey,K) then Exit(K);
 end;
 function GroupStarts(ARow,ALevel:Integer):Boolean;
 begin Result:=(ARow=0) or (PrefixKey(ARows[ARow],ALevel)<>PrefixKey(ARows[ARow-1],ALevel)); end;
 function GroupEnds(ARow,ALevel:Integer):Boolean;
 begin
  Result:=(ARow=ARows.Count-1) or
    (PrefixKey(ARows[ARow],ALevel)<>PrefixKey(ARows[ARow+1],ALevel));
 end;
 procedure AddSubtotal(const AKey:string;ALevel:Integer;var AY:Integer);
 var J,LX:Integer; It:TLarPivotViewItem; Col:TLarPivotVisualColumn; Prefix,Cap:string;
 begin
  if not RowVisible(AY) then begin Inc(AY,FRowHeight); Exit; end;
  Prefix:=PrefixKey(AKey,ALevel);
  Cap:=KeyPart(AKey,ALevel)+' Total';
  It:=TLarPivotViewItem.Create; It.Kind:=pvekTotalCell; It.RowKey:=Prefix;
  It.Caption:=Cap; It.Level:=ALevel; It.Bounds:=Rect(0,AY,FRowHeaderWidth,AY+FRowHeight);
  FItems.Add(It);
  for J:=0 to FLayout.Columns.Count-1 do begin
   Col:=FLayout.Columns[J];
   if not ColumnVisible(Col.Left,Col.Width) then Continue;
   It:=TLarPivotViewItem.Create; It.Kind:=pvekTotalCell; It.Field:=Col.DataField;
   It.RowKey:=Prefix; It.ColumnKey:=Col.ColumnKey; It.Level:=ALevel; It.DataIndex:=J;
   It.Bounds:=Rect(Col.Left,AY,Col.Left+Col.Width,AY+FRowHeight); FItems.Add(It);
  end;
  if AShowRowTotals then begin
   LX:=RightEdge;
   for J:=0 to ADataFields.Count-1 do begin
    It:=TLarPivotViewItem.Create; It.Kind:=pvekTotalCell; It.Field:=ADataFields[J];
    It.RowKey:=Prefix; It.ColumnKey:=LAR_PIVOT_TOTAL_KEY; It.Level:=ALevel; It.DataIndex:=J;
    It.Bounds:=Rect(LX,AY,LX+ADataFields[J].Width,AY+FRowHeight); FItems.Add(It);
    Inc(LX,ADataFields[J].Width);
   end;
  end;
  Inc(AY,FRowHeight);
 end;
begin
 PrefixCache:=TDictionary<string,string>.Create;
 PartCache:=TDictionary<string,string>.Create;
 CollapsedSet:=TDictionary<string,Byte>.Create;
 try
 if ACollapsedGroups<>nil then
  for I:=0 to ACollapsedGroups.Count-1 do
   CollapsedSet.AddOrSetValue(ACollapsedGroups[I],0);
 RightEdge:=FRowHeaderWidth;
 for VC in FLayout.Columns do
  if VC.Left+VC.Width>RightEdge then RightEdge:=VC.Left+VC.Width;

 Y:=FHeaderTop+AHeaderLevels*FHeaderHeight;
 for Row:=0 to ARows.Count-1 do begin
  CLvl:=CollapsedLevel(ARows[Row]);
  if CLvl>=0 then begin
   { Render the first row of the outermost collapsed group, preserving all
     ancestor columns so collapsing a child never makes its parent disappear. }
   Lvl:=CLvl;
   if GroupStarts(Row,Lvl) then begin
     if not RowVisible(Y) then begin Inc(Y,FRowHeight); Continue; end;
     X:=0;
     for I:=0 to Lvl do begin
      Item:=TLarPivotViewItem.Create; Item.Kind:=pvekRowValue; Item.Field:=ARowFields[I];
      Item.RowKey:=ARows[Row]; Item.Level:=I;
      if GroupStarts(Row,I) then Item.Caption:=KeyPart(ARows[Row],I) else Item.Caption:='';
      Item.Bounds:=Rect(X,Y,X+ARowFields[I].Width,Y+FRowHeight); FItems.Add(Item);
      Inc(X,ARowFields[I].Width);
     end;
     Item:=TLarPivotViewItem.Create; Item.Kind:=pvekExpandButton; Item.RowKey:=ARows[Row]; Item.Level:=Lvl; Item.Caption:='+';
     X:=0; for I:=0 to Lvl-1 do Inc(X,ARowFields[I].Width);
     Item.Bounds:=Rect(X+3,Y+(FRowHeight-11) div 2,X+14,Y+(FRowHeight-11) div 2+11); FItems.Add(Item);
     for I:=0 to FLayout.Columns.Count-1 do begin
      VC:=FLayout.Columns[I];
      if not ColumnVisible(VC.Left,VC.Width) then Continue;
      Item:=TLarPivotViewItem.Create; Item.Kind:=pvekTotalCell; Item.Field:=VC.DataField;
      Item.RowKey:=PrefixKey(ARows[Row],Lvl); Item.ColumnKey:=VC.ColumnKey; Item.Level:=Lvl;
      Item.Bounds:=Rect(VC.Left,Y,VC.Left+VC.Width,Y+FRowHeight); FItems.Add(Item);
     end;
     Inc(Y,FRowHeight);
    end;
   Continue;
  end;
  if RowVisible(Y) then begin
  X:=0;
  for I:=0 to ARowFields.Count-1 do begin
   Item:=TLarPivotViewItem.Create; Item.Kind:=pvekRowValue; Item.Field:=ARowFields[I];
   Item.RowKey:=ARows[Row]; Item.Level:=I;
   if (I=ARowFields.Count-1) or GroupStarts(Row,I) then Item.Caption:=KeyPart(ARows[Row],I) else Item.Caption:='';
   Item.Bounds:=Rect(X,Y,X+ARowFields[I].Width,Y+FRowHeight);
   FItems.Add(Item);
   if (I<ARowFields.Count-1) then begin
    { Keep the expand/collapse button on the group header. }
    if GroupStarts(Row,I) then begin
     Item:=TLarPivotViewItem.Create; Item.Kind:=pvekExpandButton; Item.RowKey:=ARows[Row]; Item.Level:=I; Item.Caption:='-';
     Item.Bounds:=Rect(X+3,Y+(FRowHeight-11) div 2,X+14,Y+(FRowHeight-11) div 2+11); FItems.Add(Item);
    end;
   end;
   Inc(X,ARowFields[I].Width);
  end;
  for I:=0 to FLayout.Columns.Count-1 do begin
   VC:=FLayout.Columns[I];
   if not ColumnVisible(VC.Left,VC.Width) then Continue;
   Item:=TLarPivotViewItem.Create; Item.Kind:=pvekDataCell; Item.Field:=VC.DataField;
   Item.RowKey:=ARows[Row]; Item.ColumnKey:=VC.ColumnKey; Item.DataIndex:=I;
   Item.Bounds:=Rect(VC.Left,Y,VC.Left+VC.Width,Y+FRowHeight); FItems.Add(Item);
  end;
  if AShowRowTotals then begin
   X:=RightEdge;
   for I:=0 to ADataFields.Count-1 do begin
    Item:=TLarPivotViewItem.Create; Item.Kind:=pvekTotalCell; Item.Field:=ADataFields[I]; Item.RowKey:=ARows[Row];
    Item.ColumnKey:=LAR_PIVOT_TOTAL_KEY; Item.DataIndex:=I;
    Item.Bounds:=Rect(X,Y,X+ADataFields[I].Width,Y+FRowHeight); FItems.Add(Item); Inc(X,ADataFields[I].Width);
   end;
  end;
  end; { visible detail row }
  Inc(Y,FRowHeight);
  { Close deepest groups first, like a conventional pivot hierarchy. }
  for Lvl:=ARowFields.Count-2 downto 0 do
   if ARowFields[Lvl].ShowSubTotal and GroupEnds(Row,Lvl) then AddSubtotal(ARows[Row],Lvl,Y);
 end;

 FContentBottom:=Y;
 if AShowColumnTotals then begin
  Item:=TLarPivotViewItem.Create; Item.Kind:=pvekTotalCell; Item.RowKey:=LAR_PIVOT_TOTAL_KEY;
  Item.Caption:='TOTAL GENERAL'; Item.Bounds:=Rect(0,Y,FRowHeaderWidth,Y+FRowHeight); FItems.Add(Item);
  for I:=0 to FLayout.Columns.Count-1 do begin
   VC:=FLayout.Columns[I]; Item:=TLarPivotViewItem.Create; Item.Kind:=pvekTotalCell; Item.Field:=VC.DataField;
   Item.RowKey:=LAR_PIVOT_TOTAL_KEY; Item.ColumnKey:=VC.ColumnKey; Item.DataIndex:=I;
   Item.Bounds:=Rect(VC.Left,Y,VC.Left+VC.Width,Y+FRowHeight); FItems.Add(Item);
  end;
  if AShowRowTotals and AShowGrandTotal then begin
   X:=RightEdge;
   for I:=0 to ADataFields.Count-1 do begin
    Item:=TLarPivotViewItem.Create; Item.Kind:=pvekGrandTotalCell; Item.Field:=ADataFields[I];
    Item.RowKey:=LAR_PIVOT_TOTAL_KEY; Item.ColumnKey:=LAR_PIVOT_TOTAL_KEY; Item.DataIndex:=I;
    Item.Bounds:=Rect(X,Y,X+ADataFields[I].Width,Y+FRowHeight); FItems.Add(Item); Inc(X,ADataFields[I].Width);
   end;
  end;
 end;
 if AShowColumnTotals then FContentBottom:=Y+FRowHeight;
 finally
  CollapsedSet.Free;
  PartCache.Free;
  PrefixCache.Free;
 end;
end;

function TLarPivotViewInfo.HitTest(AX,AY:Integer):TLarPivotHitTest;
var I:Integer; Item:TLarPivotViewItem;
begin
 Result:=TLarPivotHitTest.Empty;
 for I:=FItems.Count-1 downto 0 do begin
  Item:=FItems[I];
  if not Item.Contains(AX,AY) then Continue;
  Result.Kind:=Item.Kind; Result.Bounds:=Item.Bounds;
  if Item.Field<>nil then Result.FieldName:=Item.Field.FieldName;
  Result.RowKey:=Item.RowKey; Result.ColumnKey:=Item.ColumnKey;
  Result.Level:=Item.Level; Result.DataIndex:=Item.DataIndex;
  Exit;
 end;
end;

function TLarPivotViewInfo.FieldAtResizeEdge(AX,AY,ATolerance:Integer):TLarPivotField;
var I,Dist:Integer; Item:TLarPivotViewItem; VC:TLarPivotVisualColumn;
begin
 Result:=nil;
 for I:=FItems.Count-1 downto 0 do begin
  Item:=FItems[I];
  if (Item.Kind<>pvekFieldHeader) or (Item.Field=nil) then Continue;
  if (AY<Item.Bounds.Top) or (AY>=Item.Bounds.Bottom) then Continue;
  Dist:=Abs(AX-Item.Bounds.Right);
  if Dist<=ATolerance then Exit(Item.Field);
 end;
 if (AY<FHeaderTop) or (AY>=FHeaderTop+FHeaderLevels*FHeaderHeight) then Exit;
 for I:=FLayout.Columns.Count-1 downto 0 do begin
  VC:=FLayout.Columns[I];
  if Abs(AX-(VC.Left+VC.Width))<=ATolerance then Exit(VC.DataField);
 end;
end;

end.
