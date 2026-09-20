unit LarGridPivot.ViewInfo;

interface

uses
  System.Types, System.Generics.Collections,
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
    procedure AddHeaderNode(ANode: TLarPivotHeaderNode);
  public
    constructor Create(ALayout: TLarPivotLayoutEngine);
    destructor Destroy; override;
    procedure Clear;
    procedure BuildHeaders(ARowFields, AColumnFields, ADataFields: TList<TLarPivotField>;
      AHeaderTop, AHeaderHeight, ARowHeaderWidth: Integer);
    function HitTest(AX, AY: Integer): TLarPivotHitTest;
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
 Level:=-1; DataIndex:=-1;
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
 Item.Kind:=pvekColumnValue;
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

 X:=0;
 for I:=0 to ARowFields.Count-1 do begin
  Item:=TLarPivotViewItem.Create;
  Item.Kind:=pvekFieldHeader; Item.Field:=ARowFields[I]; Item.Level:=I;
  Item.Bounds:=Rect(X,FHeaderTop,X+ARowFields[I].Width,FHeaderTop+Levels*FHeaderHeight);
  FItems.Add(Item); Inc(X,ARowFields[I].Width);
 end;

 for Root in FLayout.Roots do AddHeaderNode(Root);

 if ADataFields.Count>1 then
  for I:=0 to FLayout.Columns.Count-1 do begin
   VC:=FLayout.Columns[I];
   Item:=TLarPivotViewItem.Create;
   Item.Kind:=pvekFieldHeader; Item.Field:=VC.DataField; Item.ColumnKey:=VC.ColumnKey;
   Item.DataIndex:=I; Item.Level:=AColumnFields.Count;
   Item.Bounds:=Rect(VC.Left,FHeaderTop+AColumnFields.Count*FHeaderHeight,
     VC.Left+VC.Width,FHeaderTop+(AColumnFields.Count+1)*FHeaderHeight);
   FItems.Add(Item);
  end
 else if (AColumnFields.Count=0) and (ADataFields.Count=1) then begin
  Item:=TLarPivotViewItem.Create;
  Item.Kind:=pvekFieldHeader; Item.Field:=ADataFields[0]; Item.DataIndex:=0; Item.Level:=0;
  Item.Bounds:=Rect(FRowHeaderWidth,FHeaderTop,FRowHeaderWidth+ADataFields[0].Width,
    FHeaderTop+FHeaderHeight);
  FItems.Add(Item);
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

end.
