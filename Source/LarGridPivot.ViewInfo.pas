unit LarGridPivot.ViewInfo;

interface

uses
  System.SysUtils, System.Types, System.Generics.Collections,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.LayoutEngine;

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
    procedure AddHeaderNode(ANode: TLarPivotHeaderNode);
  public
    constructor Create(ALayout: TLarPivotLayoutEngine);
    destructor Destroy; override;
    procedure Clear;
    procedure BuildHeaders(ARowFields, AColumnFields, ADataFields: TList<TLarPivotField>;
      AHeaderTop, AHeaderHeight, ARowHeaderWidth: Integer);
    procedure BuildBody(ARowFields, ADataFields: TList<TLarPivotField>; ARows: TList<string>;
      AHeaderLevels: Integer; AShowRowTotals, AShowColumnTotals, AShowGrandTotal: Boolean);
    function HitTest(AX, AY: Integer): TLarPivotHitTest;
    function FieldAtResizeEdge(AX, AY, ATolerance: Integer): TLarPivotField;
    property Items: TObjectList<TLarPivotViewItem> read FItems;
    property HeaderTop: Integer read FHeaderTop;
    property HeaderHeight: Integer read FHeaderHeight;
    property RowHeight: Integer read FRowHeight write FRowHeight;
    property RowHeaderWidth: Integer read FRowHeaderWidth;
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

procedure TLarPivotViewInfo.AddHeaderNode(ANode:TLarPivotHeaderNode);
var C:TLarPivotHeaderNode; Item:TLarPivotViewItem;
begin
 Item:=TLarPivotViewItem.Create;
 Item.Kind:=pvekColumnValue; Item.Caption:=ANode.Caption;
 Item.Bounds:=Rect(ANode.Left,FHeaderTop+ANode.Level*FHeaderHeight,
   ANode.Left+ANode.Width,FHeaderTop+(ANode.Level+1)*FHeaderHeight);
 Item.ColumnKey:=ANode.KeyPrefix;
 Item.Level:=ANode.Level;
 FItems.Add(Item);
 for C in ANode.Children do AddHeaderNode(C);
end;

procedure TLarPivotViewInfo.BuildHeaders(ARowFields,AColumnFields,ADataFields:TList<TLarPivotField>;
 AHeaderTop,AHeaderHeight,ARowHeaderWidth:Integer);
var I,X,Levels:Integer; Item:TLarPivotViewItem; Root:TLarPivotHeaderNode; VC:TLarPivotVisualColumn;
begin
 Clear;
 FHeaderTop:=AHeaderTop; FHeaderHeight:=AHeaderHeight; FRowHeaderWidth:=ARowHeaderWidth;
 Levels:=AColumnFields.Count;
 if ADataFields.Count>1 then Inc(Levels);
 if Levels=0 then Levels:=1;
 FHeaderLevels:=Levels;

 X:=0;
 for I:=0 to ARowFields.Count-1 do begin
  Item:=TLarPivotViewItem.Create;
  Item.Kind:=pvekFieldHeader; Item.Field:=ARowFields[I]; Item.Level:=I;
  Item.Caption:=ARowFields[I].Caption; if Item.Caption='' then Item.Caption:=ARowFields[I].FieldName;
  Item.Bounds:=Rect(X,FHeaderTop,X+ARowFields[I].Width,FHeaderTop+Levels*FHeaderHeight);
  FItems.Add(Item); Inc(X,ARowFields[I].Width);
 end;

 for Root in FLayout.Roots do AddHeaderNode(Root);

 if ADataFields.Count>1 then
  for I:=0 to FLayout.Columns.Count-1 do begin
   VC:=FLayout.Columns[I];
   Item:=TLarPivotViewItem.Create;
   Item.Kind:=pvekFieldHeader; Item.Field:=VC.DataField; Item.ColumnKey:=VC.ColumnKey;
   Item.Caption:=VC.DataField.Caption; if Item.Caption='' then Item.Caption:=VC.DataField.FieldName;
   Item.DataIndex:=I; Item.Level:=AColumnFields.Count;
   Item.Bounds:=Rect(VC.Left,FHeaderTop+AColumnFields.Count*FHeaderHeight,
     VC.Left+VC.Width,FHeaderTop+(AColumnFields.Count+1)*FHeaderHeight);
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
 ARows:TList<string>;AHeaderLevels:Integer;AShowRowTotals,AShowColumnTotals,AShowGrandTotal:Boolean);
var Row,I,X,Y,RightEdge:Integer; Item:TLarPivotViewItem; VC:TLarPivotVisualColumn;
begin
 RightEdge:=FRowHeaderWidth;
 for VC in FLayout.Columns do
  if VC.Left+VC.Width>RightEdge then RightEdge:=VC.Left+VC.Width;

 for Row:=0 to ARows.Count-1 do begin
  Y:=FHeaderTop+AHeaderLevels*FHeaderHeight+Row*FRowHeight;
  X:=0;
  for I:=0 to ARowFields.Count-1 do begin
   Item:=TLarPivotViewItem.Create;
   Item.Kind:=pvekRowValue; Item.Field:=ARowFields[I];
   Item.RowKey:=ARows[Row]; Item.Level:=I;
   Item.Bounds:=Rect(X,Y,X+ARowFields[I].Width,Y+FRowHeight);
   FItems.Add(Item); Inc(X,ARowFields[I].Width);
  end;
  for I:=0 to FLayout.Columns.Count-1 do begin
   VC:=FLayout.Columns[I];
   Item:=TLarPivotViewItem.Create;
   Item.Kind:=pvekDataCell; Item.Field:=VC.DataField;
   Item.RowKey:=ARows[Row]; Item.ColumnKey:=VC.ColumnKey; Item.DataIndex:=I;
   Item.Bounds:=Rect(VC.Left,Y,VC.Left+VC.Width,Y+FRowHeight);
   FItems.Add(Item);
  end;
  if AShowRowTotals then begin
   X:=RightEdge;
   for I:=0 to ADataFields.Count-1 do begin
    Item:=TLarPivotViewItem.Create;
    Item.Kind:=pvekTotalCell; Item.Field:=ADataFields[I]; Item.RowKey:=ARows[Row];
    Item.ColumnKey:=LAR_PIVOT_TOTAL_KEY; Item.DataIndex:=I;
    Item.Bounds:=Rect(X,Y,X+ADataFields[I].Width,Y+FRowHeight);
    FItems.Add(Item); Inc(X,ADataFields[I].Width);
   end;
  end;
 end;

 if AShowColumnTotals then begin
  Y:=FHeaderTop+AHeaderLevels*FHeaderHeight+ARows.Count*FRowHeight;
  Item:=TLarPivotViewItem.Create;
  Item.Kind:=pvekTotalCell; Item.RowKey:=LAR_PIVOT_TOTAL_KEY;
  Item.Caption:='TOTAL'; Item.Bounds:=Rect(0,Y,FRowHeaderWidth,Y+FRowHeight);
  FItems.Add(Item);
  for I:=0 to FLayout.Columns.Count-1 do begin
   VC:=FLayout.Columns[I];
   Item:=TLarPivotViewItem.Create;
   Item.Kind:=pvekTotalCell; Item.Field:=VC.DataField;
   Item.RowKey:=LAR_PIVOT_TOTAL_KEY; Item.ColumnKey:=VC.ColumnKey; Item.DataIndex:=I;
   Item.Bounds:=Rect(VC.Left,Y,VC.Left+VC.Width,Y+FRowHeight);
   FItems.Add(Item);
  end;
  if AShowRowTotals and AShowGrandTotal then begin
   X:=RightEdge;
   for I:=0 to ADataFields.Count-1 do begin
    Item:=TLarPivotViewItem.Create;
    Item.Kind:=pvekGrandTotalCell; Item.Field:=ADataFields[I];
    Item.RowKey:=LAR_PIVOT_TOTAL_KEY; Item.ColumnKey:=LAR_PIVOT_TOTAL_KEY; Item.DataIndex:=I;
    Item.Bounds:=Rect(X,Y,X+ADataFields[I].Width,Y+FRowHeight);
    FItems.Add(Item); Inc(X,ADataFields[I].Width);
   end;
  end;
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
