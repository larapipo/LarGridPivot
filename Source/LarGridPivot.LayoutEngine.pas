unit LarGridPivot.LayoutEngine;

interface

uses
  System.SysUtils, System.Generics.Collections,
  LarGridPivot.Fields, LarGridPivot.Model;

type
  TLarPivotVisualColumn = class
  public
    ColumnKey: string;
    DataField: TLarPivotField;
    Left: Integer;
    Width: Integer;
    constructor Create(const AColumnKey: string; ADataField: TLarPivotField;
      ALeft, AWidth: Integer);
  end;

  TLarPivotHeaderNode = class
  private
    FChildren: TObjectList<TLarPivotHeaderNode>;
  public
    Caption: string;
    Level: Integer;
    Left: Integer;
    Width: Integer;
    ColumnKey: string;
    KeyPrefix: string;
    constructor Create(const ACaption: string; ALevel: Integer);
    destructor Destroy; override;
    function FindChild(const ACaption: string): TLarPivotHeaderNode;
    function AddChild(const ACaption: string): TLarPivotHeaderNode;
    property Children: TObjectList<TLarPivotHeaderNode> read FChildren;
  end;

  TLarPivotLayoutEngine = class
  private
    FRoots: TObjectList<TLarPivotHeaderNode>;
    FColumns: TObjectList<TLarPivotVisualColumn>;
    function KeyPart(const AKey: string; ALevel: Integer): string;
    procedure AssignNodeGeometry(ANode: TLarPivotHeaderNode);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Build(AModel: TLarPivotModel; AColumnFields, ADataFields: TList<TLarPivotField>;
      AStartX: Integer);
    property Roots: TObjectList<TLarPivotHeaderNode> read FRoots;
    property Columns: TObjectList<TLarPivotVisualColumn> read FColumns;
  end;

implementation

constructor TLarPivotVisualColumn.Create(const AColumnKey:string;
  ADataField:TLarPivotField; ALeft,AWidth:Integer);
begin
 inherited Create; ColumnKey:=AColumnKey; DataField:=ADataField;
 Left:=ALeft; Width:=AWidth;
end;

constructor TLarPivotHeaderNode.Create(const ACaption:string;ALevel:Integer);
begin
 inherited Create; Caption:=ACaption; Level:=ALevel;
 FChildren:=TObjectList<TLarPivotHeaderNode>.Create(True);
end;

destructor TLarPivotHeaderNode.Destroy;
begin FChildren.Free; inherited; end;

function TLarPivotHeaderNode.FindChild(const ACaption:string):TLarPivotHeaderNode;
var N:TLarPivotHeaderNode;
begin
 Result:=nil;
 for N in FChildren do if N.Caption=ACaption then Exit(N);
end;

function TLarPivotHeaderNode.AddChild(const ACaption:string):TLarPivotHeaderNode;
begin
 Result:=FindChild(ACaption);
 if Result=nil then begin Result:=TLarPivotHeaderNode.Create(ACaption,Level+1); FChildren.Add(Result); end;
end;

constructor TLarPivotLayoutEngine.Create;
begin
 inherited; FRoots:=TObjectList<TLarPivotHeaderNode>.Create(True);
 FColumns:=TObjectList<TLarPivotVisualColumn>.Create(True);
end;

destructor TLarPivotLayoutEngine.Destroy;
begin FColumns.Free; FRoots.Free; inherited; end;

procedure TLarPivotLayoutEngine.Clear;
begin FRoots.Clear; FColumns.Clear; end;

function TLarPivotLayoutEngine.KeyPart(const AKey:string;ALevel:Integer):string;
var I,L,N:Integer; P:string;
begin
 Result:=''; P:=''; N:=0; I:=1; L:=Length(AKey);
 while I<=L do begin
  if AKey[I]=#29 then begin
   if (I<L) and (AKey[I+1]=#29) then begin P:=P+#29; Inc(I,2); Continue; end;
   if N=ALevel then Exit(P); Inc(N); P:=''; Inc(I); Continue;
  end;
  P:=P+AKey[I]; Inc(I);
 end;
 if N=ALevel then Result:=P;
end;

procedure TLarPivotLayoutEngine.AssignNodeGeometry(ANode:TLarPivotHeaderNode);
var MinL,MaxR:Integer; C:TLarPivotHeaderNode; VC:TLarPivotVisualColumn;
begin
 if ANode.Children.Count>0 then begin
  for C in ANode.Children do AssignNodeGeometry(C);
  MinL:=MaxInt; MaxR:=0;
  for C in ANode.Children do begin if C.Left<MinL then MinL:=C.Left; if C.Left+C.Width>MaxR then MaxR:=C.Left+C.Width; end;
  ANode.Left:=MinL; ANode.Width:=MaxR-MinL; Exit;
 end;
 MinL:=MaxInt; MaxR:=0;
 for VC in FColumns do if VC.ColumnKey=ANode.ColumnKey then begin
  if VC.Left<MinL then MinL:=VC.Left; if VC.Left+VC.Width>MaxR then MaxR:=VC.Left+VC.Width;
 end;
 if MinL=MaxInt then MinL:=0;
 ANode.Left:=MinL; ANode.Width:=MaxR-MinL;
end;

procedure TLarPivotLayoutEngine.Build(AModel:TLarPivotModel;
 AColumnFields,ADataFields:TList<TLarPivotField>;AStartX:Integer);
var Col,Lvl,D,X,I:Integer; K,Cap,Prefix:string; Root,Node,Candidate:TLarPivotHeaderNode;
begin
 Clear; if (AModel=nil) or (ADataFields=nil) or (ADataFields.Count=0) then Exit; X:=AStartX;
 if (AColumnFields=nil) or (AColumnFields.Count=0) then begin
  K:='';
  for D:=0 to ADataFields.Count-1 do begin
   FColumns.Add(TLarPivotVisualColumn.Create(K,ADataFields[D],X,ADataFields[D].Width));
   Inc(X,ADataFields[D].Width);
  end;
  Exit;
 end;
 for Col:=0 to AModel.ColumnKeys.Count-1 do begin
  K:=AModel.ColumnKeys[Col]; Node:=nil; Prefix:='';
  for Lvl:=0 to AColumnFields.Count-1 do begin
   Cap:=KeyPart(K,Lvl);
   if Prefix='' then Prefix:=Cap else Prefix:=Prefix+#29+Cap;
   if Lvl=0 then begin
    Root:=nil;
    for I:=0 to FRoots.Count-1 do begin
     Candidate:=FRoots[I];
     if Candidate.Caption=Cap then begin Root:=Candidate; Break; end;
    end;
    if Root=nil then begin Root:=TLarPivotHeaderNode.Create(Cap,0); FRoots.Add(Root); end;
    Node:=Root;
   end else Node:=Node.AddChild(Cap);
   if Node.KeyPrefix='' then Node.KeyPrefix:=Prefix;
   if Lvl=AColumnFields.Count-1 then Node.ColumnKey:=K;
  end;
  for D:=0 to ADataFields.Count-1 do begin
   FColumns.Add(TLarPivotVisualColumn.Create(K,ADataFields[D],X,ADataFields[D].Width));
   Inc(X,ADataFields[D].Width);
  end;
 end;
 for Root in FRoots do AssignNodeGeometry(Root);
end;

end.
