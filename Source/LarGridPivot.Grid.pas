unit LarGridPivot.Grid;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Data.DB,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Filters,
  LarGridPivot.Layout, LarGridPivot.DataProvider, LarGridPivot.Model,
  LarGridPivot.Engine, LarGridPivot.LayoutEngine, LarGridPivot.ViewInfo;

type
  TLarGridPivot = class(TCustomControl)
  private
    FDataSource: TDataSource; FDataLink: TDataLink; FFields: TLarPivotFields;
    FEngine: TLarPivotEngine; FLayoutEngine: TLarPivotLayoutEngine; FViewInfo: TLarPivotViewInfo; FHeaderHeight, FRowHeight, FRowHeaderWidth: Integer;
    FUpdating: Integer; FRebuilding: Boolean;
    FShowRowTotals, FShowColumnTotals, FShowGrandTotal: Boolean;
    FFieldAreaHeight: Integer;
    FDragField: TLarPivotField;
    FDragStart: TPoint;
    FDraggingField: Boolean;
    FResizingField: TLarPivotField;
    FResizeStartX, FResizeStartWidth: Integer;
    FDragTargetArea: TLarPivotArea;
    FDragTargetIndex: Integer;
    function ResizeFieldAtPoint(AX, AY: Integer): TLarPivotField;
    procedure DrawFieldAreas;
    function AreaFromY(AY: Integer): TLarPivotArea;
    function FieldAtPoint(AX, AY: Integer): TLarPivotField;
    function DropIndexAtPoint(AArea: TLarPivotArea; AX: Integer): Integer;
    function AreaFields(AArea: TLarPivotArea): TList<TLarPivotField>;
    function AreaCaption(AArea: TLarPivotArea): string;
    procedure SetDataSource(const Value: TDataSource); procedure SetFields(const Value: TLarPivotFields);
    procedure SetHeaderHeight(const Value: Integer); procedure SetRowHeight(const Value: Integer);
    procedure SetRowHeaderWidth(const Value: Integer); procedure SetShowRowTotals(const Value: Boolean);
    procedure SetShowColumnTotals(const Value: Boolean); procedure SetShowGrandTotal(const Value: Boolean);
    procedure DataChanged(Sender: TObject); procedure BuildFieldsFromDataSet;
    function DataFields: TList<TLarPivotField>;
    function DefaultAlignment(AField: TLarPivotField): TAlignment;
    function FormatCellValue(const V: Variant; AField: TLarPivotField): string;
    function AxisFields(AArea: TLarPivotArea): TList<TLarPivotField>;
    function KeyPart(const AKey: string; ALevel: Integer): string;
    procedure NormalizeAreaIndexes(AArea: TLarPivotArea);
    procedure BuildViewInfo;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override; procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override; destructor Destroy; override;
    procedure BeginUpdate; procedure EndUpdate; procedure RefreshFields; procedure Rebuild;
    function FieldByName(const AFieldName: string): TLarPivotField;
    procedure MoveField(const AFieldName: string; AArea: TLarPivotArea; AIndex: Integer = -1);
    procedure RemoveField(const AFieldName: string);
    function SaveLayoutToString: string;
    procedure LoadLayoutFromString(const ALayout: string);
    procedure SaveLayoutToFile(const AFileName: string);
    procedure LoadLayoutFromFile(const AFileName: string);
    procedure SaveLayoutToStream(AStream: TStream);
    procedure LoadLayoutFromStream(AStream: TStream);
    property Engine: TLarPivotEngine read FEngine;
    function HitTestAt(X, Y: Integer): TLarPivotHitTest;
  published
    property Align; property Anchors; property Color default clWhite; property Font; property ParentFont;
    property ParentColor; property PopupMenu; property ShowHint; property Visible;
    property DataSource: TDataSource read FDataSource write SetDataSource;
    property Fields: TLarPivotFields read FFields write SetFields;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default 32;
    property RowHeight: Integer read FRowHeight write SetRowHeight default 28;
    property RowHeaderWidth: Integer read FRowHeaderWidth write SetRowHeaderWidth default 180;
    property ShowRowTotals: Boolean read FShowRowTotals write SetShowRowTotals default True;
    property ShowColumnTotals: Boolean read FShowColumnTotals write SetShowColumnTotals default True;
    property ShowGrandTotal: Boolean read FShowGrandTotal write SetShowGrandTotal default True;
  end;

implementation

type TLarPivotDataLink = class(TDataLink)
private FOwner: TLarGridPivot;
protected procedure DataSetChanged; override; procedure ActiveChanged; override;
public constructor Create(AOwner: TLarGridPivot); end;
constructor TLarPivotDataLink.Create(AOwner: TLarGridPivot); begin inherited Create; FOwner:=AOwner; end;
procedure TLarPivotDataLink.ActiveChanged; begin inherited; if Assigned(FOwner) then FOwner.DataChanged(Self); end;
procedure TLarPivotDataLink.DataSetChanged; begin inherited; if Assigned(FOwner) then FOwner.DataChanged(Self); end;

constructor TLarGridPivot.Create(AOwner:TComponent);
begin inherited; Width:=640; Height:=360; Color:=clWhite; FHeaderHeight:=32; FRowHeight:=28; FRowHeaderWidth:=180;
 FShowRowTotals:=True; FShowColumnTotals:=True; FShowGrandTotal:=True; FFieldAreaHeight:=150;
 FDragTargetArea:=paNone; FDragTargetIndex:=-1; FFields:=TLarPivotFields.Create(Self);
 FEngine:=TLarPivotEngine.Create(FFields); FLayoutEngine:=TLarPivotLayoutEngine.Create; FViewInfo:=TLarPivotViewInfo.Create(FLayoutEngine); FDataLink:=TLarPivotDataLink.Create(Self); ControlStyle:=ControlStyle+[csOpaque]; end;
destructor TLarGridPivot.Destroy; begin FDataLink.Free; FViewInfo.Free; FLayoutEngine.Free; FEngine.Free; FFields.Free; inherited; end;
procedure TLarGridPivot.BeginUpdate; begin Inc(FUpdating); end;
procedure TLarGridPivot.EndUpdate; begin if FUpdating>0 then Dec(FUpdating); if FUpdating=0 then Rebuild; end;
procedure TLarGridPivot.SetDataSource(const Value:TDataSource); begin if FDataSource=Value then Exit; FDataSource:=Value; FDataLink.DataSource:=Value; if Assigned(Value) then Value.FreeNotification(Self); RefreshFields; end;
procedure TLarGridPivot.SetFields(const Value:TLarPivotFields); begin FFields.Assign(Value); Rebuild; end;
procedure TLarGridPivot.Notification(AComponent:TComponent;Operation:TOperation); begin inherited; if (Operation=opRemove) and (AComponent=FDataSource) then DataSource:=nil; end;
procedure TLarGridPivot.DataChanged(Sender:TObject); begin if (FUpdating=0) and not FRebuilding then Rebuild; end;

procedure TLarGridPivot.SetHeaderHeight(const Value:Integer);
var N:Integer;
begin N:=Value; if N<16 then N:=16; if N=FHeaderHeight then Exit; FHeaderHeight:=N; Invalidate; end;
procedure TLarGridPivot.SetRowHeight(const Value:Integer);
var N:Integer;
begin N:=Value; if N<16 then N:=16; if N=FRowHeight then Exit; FRowHeight:=N; Invalidate; end;
procedure TLarGridPivot.SetRowHeaderWidth(const Value:Integer);
var N:Integer;
begin N:=Value; if N<40 then N:=40; if N=FRowHeaderWidth then Exit; FRowHeaderWidth:=N; Invalidate; end;
procedure TLarGridPivot.SetShowRowTotals(const Value:Boolean);
begin if Value=FShowRowTotals then Exit; FShowRowTotals:=Value; Invalidate; end;
procedure TLarGridPivot.SetShowColumnTotals(const Value:Boolean);
begin if Value=FShowColumnTotals then Exit; FShowColumnTotals:=Value; Invalidate; end;
procedure TLarGridPivot.SetShowGrandTotal(const Value:Boolean);
begin if Value=FShowGrandTotal then Exit; FShowGrandTotal:=Value; Invalidate; end;

procedure TLarGridPivot.BuildFieldsFromDataSet;
var DS:TDataSet; I:Integer; PF:TLarPivotField; DF:TField;
begin if (FDataSource=nil) or (FDataSource.DataSet=nil) then Exit; DS:=FDataSource.DataSet; if not DS.Active then Exit;
 FFields.BeginUpdate; try FFields.Clear; for I:=0 to DS.FieldCount-1 do begin DF:=DS.Fields[I]; PF:=FFields.Add; PF.FieldName:=DF.FieldName; PF.Caption:=DF.DisplayLabel; PF.Width:=100;
 case DF.DataType of ftSmallint,ftInteger,ftWord,ftLargeint,ftAutoInc,ftFloat,ftCurrency,ftBCD,ftFMTBcd,ftSingle,ftExtended:PF.Alignment:=pvaRight;
 ftDate,ftTime,ftDateTime,ftTimeStamp,ftTimeStampOffset:PF.Alignment:=pvaCenter; else PF.Alignment:=pvaLeft; end; end; finally FFields.EndUpdate; end; end;
procedure TLarGridPivot.RefreshFields; begin if FRebuilding then Exit; FRebuilding:=True; try BuildFieldsFromDataSet; Invalidate; finally FRebuilding:=False; end; end;
procedure TLarGridPivot.Rebuild;
var P:ILarPivotDataProvider;
begin if (FUpdating>0) or FRebuilding then Exit; FRebuilding:=True; try if (FDataSource=nil) or (FDataSource.DataSet=nil) or not FDataSource.DataSet.Active then begin FEngine.Model.Clear; FViewInfo.Clear; FLayoutEngine.Clear; Invalidate; Exit; end;
 if FFields.Count=0 then BuildFieldsFromDataSet; P:=TLarDataSetPivotProvider.Create(FDataSource.DataSet); try FEngine.Build(P); finally P:=nil; end; Invalidate; finally FRebuilding:=False; end; end;
function TLarGridPivot.FieldByName(const AFieldName:string):TLarPivotField; begin Result:=FFields.FindField(AFieldName); if Result=nil then raise EDatabaseError.CreateFmt('Campo Pivot no encontrado: %s',[AFieldName]); end;

procedure TLarGridPivot.NormalizeAreaIndexes(AArea: TLarPivotArea);
var L:TList<TLarPivotField>; I,J:Integer; T:TLarPivotField;
begin
 if AArea=paNone then begin
  for I:=0 to FFields.Count-1 do if FFields[I].Area=paNone then FFields[I].AreaIndex:=-1;
  Exit;
 end;
 L:=TList<TLarPivotField>.Create; try
  for I:=0 to FFields.Count-1 do if FFields[I].Area=AArea then L.Add(FFields[I]);
  for I:=0 to L.Count-2 do for J:=I+1 to L.Count-1 do if L[I].AreaIndex>L[J].AreaIndex then begin T:=L[I];L[I]:=L[J];L[J]:=T;end;
  for I:=0 to L.Count-1 do L[I].AreaIndex:=I;
 finally L.Free; end;
end;

procedure TLarGridPivot.MoveField(const AFieldName:string; AArea:TLarPivotArea; AIndex:Integer);
var F,T:TLarPivotField; I,J:Integer; OldArea:TLarPivotArea; L:TList<TLarPivotField>;
begin
 F:=FieldByName(AFieldName); OldArea:=F.Area; BeginUpdate;
 try
  if AArea=paNone then begin
   F.Area:=paNone; F.AreaIndex:=-1;
   if OldArea<>paNone then NormalizeAreaIndexes(OldArea);
   Exit;
  end;

  F.Area:=AArea;
  L:=TList<TLarPivotField>.Create;
  try
   for I:=0 to FFields.Count-1 do
    if (FFields[I]<>F) and (FFields[I].Area=AArea) then L.Add(FFields[I]);
   for I:=0 to L.Count-2 do
    for J:=I+1 to L.Count-1 do
     if L[I].AreaIndex>L[J].AreaIndex then begin
      T:=L[I]; L[I]:=L[J]; L[J]:=T;
     end;
   if AIndex<0 then AIndex:=L.Count;
   if AIndex<0 then AIndex:=0;
   if AIndex>L.Count then AIndex:=L.Count;
   L.Insert(AIndex,F);
   for I:=0 to L.Count-1 do L[I].AreaIndex:=I;
  finally
   L.Free;
  end;
  if (OldArea<>AArea) and (OldArea<>paNone) then NormalizeAreaIndexes(OldArea);
 finally
  EndUpdate;
 end;
end;

procedure TLarGridPivot.RemoveField(const AFieldName:string);
begin MoveField(AFieldName,paNone,-1); end;

function TLarGridPivot.SaveLayoutToString:string;
begin Result:=TLarPivotLayout.SaveToString(FFields,FEngine.Filters,FShowRowTotals,FShowColumnTotals,FShowGrandTotal); end;

procedure TLarGridPivot.LoadLayoutFromString(const ALayout:string);
var A:TLarPivotArea;
begin
 BeginUpdate;
 try
  TLarPivotLayout.LoadFromString(ALayout,FFields,FEngine.Filters,FShowRowTotals,FShowColumnTotals,FShowGrandTotal);
  for A:=Low(TLarPivotArea) to High(TLarPivotArea) do NormalizeAreaIndexes(A);
 finally
  EndUpdate;
 end;
end;

procedure TLarGridPivot.SaveLayoutToStream(AStream:TStream);
var S:TStringStream;
begin if AStream=nil then raise EArgumentNilException.Create('AStream'); S:=TStringStream.Create(SaveLayoutToString,TEncoding.UTF8); try S.Position:=0; AStream.CopyFrom(S,0); finally S.Free; end; end;
procedure TLarGridPivot.LoadLayoutFromStream(AStream:TStream);
var S:TStringStream;
begin if AStream=nil then raise EArgumentNilException.Create('AStream'); S:=TStringStream.Create('',TEncoding.UTF8); try AStream.Position:=0; S.CopyFrom(AStream,0); LoadLayoutFromString(S.DataString); finally S.Free; end; end;
procedure TLarGridPivot.SaveLayoutToFile(const AFileName:string);
var FS:TFileStream;
begin FS:=TFileStream.Create(AFileName,fmCreate); try SaveLayoutToStream(FS); finally FS.Free; end; end;
procedure TLarGridPivot.LoadLayoutFromFile(const AFileName:string);
var FS:TFileStream;
begin FS:=TFileStream.Create(AFileName,fmOpenRead or fmShareDenyWrite); try LoadLayoutFromStream(FS); finally FS.Free; end; end;

procedure TLarGridPivot.BuildViewInfo;
var DFs,RFs,CFs:TList<TLarPivotField>; Lvl,HeaderLevels,RowHeaderTotal:Integer;
begin
 DFs:=DataFields; RFs:=AxisFields(paRow); CFs:=AxisFields(paColumn);
 try
  if DFs.Count=0 then begin FViewInfo.Clear; FLayoutEngine.Clear; Exit; end;
  HeaderLevels:=CFs.Count; if DFs.Count>1 then Inc(HeaderLevels);
  if HeaderLevels=0 then HeaderLevels:=1;
  RowHeaderTotal:=0;
  for Lvl:=0 to RFs.Count-1 do Inc(RowHeaderTotal,RFs[Lvl].Width);
  if RowHeaderTotal=0 then RowHeaderTotal:=FRowHeaderWidth;
  FLayoutEngine.Build(FEngine.Model,CFs,DFs,RowHeaderTotal);
  FViewInfo.RowHeight:=FRowHeight;
  FViewInfo.BuildHeaders(RFs,CFs,DFs,FFieldAreaHeight,FHeaderHeight,RowHeaderTotal);
  FViewInfo.BuildBody(RFs,DFs,FEngine.Model.RowKeys,HeaderLevels,
    FShowRowTotals,FShowColumnTotals,FShowGrandTotal);
 finally
  CFs.Free; RFs.Free; DFs.Free;
 end;
end;

function TLarGridPivot.ResizeFieldAtPoint(AX,AY:Integer):TLarPivotField;
begin
 BuildViewInfo;
 Result:=FViewInfo.FieldAtResizeEdge(AX,AY,4);
end;

function TLarGridPivot.AreaCaption(AArea:TLarPivotArea):string;
begin
 case AArea of
  paNone: Result:='CAMPOS DISPONIBLES';
  paFilter: Result:='FILTROS';
  paColumn: Result:='COLUMNAS';
  paData: Result:='DATOS';
  paRow: Result:='FILAS';
 else Result:='';
 end;
end;

function TLarGridPivot.AreaFields(AArea:TLarPivotArea):TList<TLarPivotField>;
var I,J:Integer; T:TLarPivotField;
begin
 Result:=TList<TLarPivotField>.Create;
 for I:=0 to FFields.Count-1 do
  if FFields[I].Visible and (FFields[I].Area=AArea) then Result.Add(FFields[I]);
 for I:=0 to Result.Count-2 do
  for J:=I+1 to Result.Count-1 do
   if Result[I].AreaIndex>Result[J].AreaIndex then begin
    T:=Result[I]; Result[I]:=Result[J]; Result[J]:=T;
   end;
end;

function TLarGridPivot.AreaFromY(AY:Integer):TLarPivotArea;
var H,N:Integer;
begin
 Result:=paNone;
 if (AY<0) or (AY>=FFieldAreaHeight) then Exit;
 H:=FFieldAreaHeight div 5; if H<=0 then Exit;
 N:=AY div H;
 case N of
  0:Result:=paNone; 1:Result:=paFilter; 2:Result:=paColumn;
  3:Result:=paData; 4:Result:=paRow;
 end;
end;

function TLarGridPivot.FieldAtPoint(AX,AY:Integer):TLarPivotField;
var A:TLarPivotArea; L:TList<TLarPivotField>; I,X,H,Y,ChipW:Integer; S:string; R:TRect;
begin
 Result:=nil; A:=AreaFromY(AY); H:=FFieldAreaHeight div 5;
 case A of paNone:Y:=0;paFilter:Y:=H;paColumn:Y:=H*2;paData:Y:=H*3;paRow:Y:=H*4;else Exit;end;
 X:=125; L:=AreaFields(A);
 try
  Canvas.Font.Assign(Font);
  for I:=0 to L.Count-1 do begin
   S:=L[I].Caption; if S='' then S:=L[I].FieldName;
   ChipW:=Canvas.TextWidth(S)+24; if ChipW<80 then ChipW:=80;
   R:=Rect(X,Y+3,X+ChipW,Y+H-3);
   if PtInRect(R,Point(AX,AY)) then Exit(L[I]);
   X:=R.Right+6;
  end;
 finally L.Free; end;
end;

function TLarGridPivot.DropIndexAtPoint(AArea:TLarPivotArea;AX:Integer):Integer;
var L:TList<TLarPivotField>; I,X,ChipW:Integer; S:string;
begin
 Result:=0; X:=125; L:=AreaFields(AArea);
 try
  Canvas.Font.Assign(Font);
  for I:=0 to L.Count-1 do begin
   if L[I]=FDragField then Continue;
   S:=L[I].Caption; if S='' then S:=L[I].FieldName;
   ChipW:=Canvas.TextWidth(S)+24; if ChipW<80 then ChipW:=80;
   if AX < X+(ChipW div 2) then Exit(Result);
   Inc(Result); Inc(X,ChipW+6);
  end;
 finally L.Free; end;
end;

procedure TLarGridPivot.DrawFieldAreas;
const Areas:array[0..4] of TLarPivotArea=(paNone,paFilter,paColumn,paData,paRow);
var I,J,X,Y,H,ChipW:Integer; A:TLarPivotArea; R:TRect; F:TLarPivotField; S:string; L:TList<TLarPivotField>;
begin
 H:=FFieldAreaHeight div 5; Y:=0; Canvas.Font.Assign(Font);
 for I:=0 to High(Areas) do begin
  A:=Areas[I]; R:=Rect(0,Y,ClientWidth,Y+H);
  Canvas.Brush.Color:=$00F5F5F5; Canvas.FillRect(R);
  Canvas.Pen.Color:=$00D8D8D8; Canvas.Rectangle(R);
  Canvas.Font.Style:=[fsBold]; Canvas.Font.Color:=$00606060;
  Canvas.TextOut(8,Y+6,AreaCaption(A)); X:=125; Canvas.Font.Style:=[];
  L:=AreaFields(A);
  try
   for J:=0 to L.Count-1 do begin
    F:=L[J]; S:=F.Caption; if S='' then S:=F.FieldName;
    ChipW:=Canvas.TextWidth(S)+24; if ChipW<80 then ChipW:=80;
    if FDraggingField and (A=FDragTargetArea) and (J=FDragTargetIndex) then begin
     Canvas.Pen.Color:=$00808080; Canvas.Pen.Width:=2;
     Canvas.MoveTo(X-3,Y+4); Canvas.LineTo(X-3,Y+H-4); Canvas.Pen.Width:=1;
    end;
    R:=Rect(X,Y+3,X+ChipW,Y+H-3);
    if F=FDragField then Canvas.Brush.Color:=$00E8F2FF else Canvas.Brush.Color:=clWhite;
    Canvas.Pen.Color:=$00B8B8B8; Canvas.RoundRect(R.Left,R.Top,R.Right,R.Bottom,6,6);
    Canvas.Font.Color:=clWindowText;
    Canvas.TextOut(R.Left+10,R.Top+((R.Bottom-R.Top-Canvas.TextHeight(S)) div 2),S);
    X:=R.Right+6;
   end;
  finally L.Free; end;
  if FDraggingField and (A=FDragTargetArea) and (FDragTargetIndex>=J) then begin
   Canvas.Pen.Color:=$00808080; Canvas.Pen.Width:=2;
   Canvas.MoveTo(X-3,Y+4); Canvas.LineTo(X-3,Y+H-4); Canvas.Pen.Width:=1;
  end;
  Inc(Y,H);
 end;
end;

function TLarGridPivot.AxisFields(AArea:TLarPivotArea):TList<TLarPivotField>;
begin Result:=AreaFields(AArea); end;

function TLarGridPivot.KeyPart(const AKey:string;ALevel:Integer):string;
var I,L,N:Integer; P:string;
begin
 Result:=''; P:=''; N:=0; I:=1; L:=Length(AKey);
 while I<=L do begin
  if AKey[I]=#29 then begin
   if (I<L) and (AKey[I+1]=#29) then begin P:=P+#29; Inc(I,2); Continue; end;
   if N=ALevel then Exit(P);
   Inc(N); P:=''; Inc(I); Continue;
  end;
  P:=P+AKey[I]; Inc(I);
 end;
 if N=ALevel then Result:=P;
end;

function TLarGridPivot.DataFields:TList<TLarPivotField>;
var I,J:Integer; T:TLarPivotField;
begin Result:=TList<TLarPivotField>.Create; for I:=0 to FFields.Count-1 do if FFields[I].Visible and (FFields[I].Area=paData) then Result.Add(FFields[I]);
 for I:=0 to Result.Count-2 do for J:=I+1 to Result.Count-1 do if Result[I].AreaIndex>Result[J].AreaIndex then begin T:=Result[I];Result[I]:=Result[J];Result[J]:=T;end; end;
function TLarGridPivot.DefaultAlignment(AField:TLarPivotField):TAlignment; begin case AField.Alignment of pvaLeft:Result:=taLeftJustify;pvaCenter:Result:=taCenter;pvaRight:Result:=taRightJustify;else Result:=taLeftJustify;end; end;
function TLarGridPivot.FormatCellValue(const V:Variant;AField:TLarPivotField):string; begin if VarIsNull(V) or VarIsEmpty(V) then Exit(''); if (AField.DisplayFormat<>'') and VarIsNumeric(V) then Result:=FormatFloat(AField.DisplayFormat,V) else Result:=VarToStr(V); end;

procedure TLarGridPivot.Paint;
var Row,D,Lvl,X,Y,HeaderLevels,RowHeaderTotal:Integer;
 S:string; DF:TLarPivotField; Cell:TLarPivotResultCell; V:Variant; Flags:Cardinal;
 DFs,RFs,CFs:TList<TLarPivotField>; VC:TLarPivotVisualColumn; VI:TLarPivotViewItem;
 procedure DrawCell(const ARect:TRect;const Txt:string;Al:TAlignment;Bold:Boolean=False;Total:Boolean=False);
 var RR:TRect; begin RR:=ARect; if Total then Canvas.Brush.Color:=$00F3F3F3 else Canvas.Brush.Color:=Color;
  Canvas.FillRect(RR); Canvas.Pen.Color:=$00E0E0E0; Canvas.Rectangle(RR); InflateRect(RR,-6,-2);
  Canvas.Font.Assign(Font); if Bold then Canvas.Font.Style:=Canvas.Font.Style+[fsBold];
  Flags:=DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
  case Al of taRightJustify:Flags:=Flags or DT_RIGHT;taCenter:Flags:=Flags or DT_CENTER;else Flags:=Flags or DT_LEFT;end;
  DrawText(Canvas.Handle,PChar(Txt),Length(Txt),RR,Flags);
 end;
 function TextFor(const AR,AC:string;F:TLarPivotField):string;
 begin Cell:=FEngine.Model.FindCell(AR,AC,F.FieldName); if Cell<>nil then V:=Cell.Accumulator.Value(F.SummaryType) else V:=Null; Result:=FormatCellValue(V,F); end;
begin
 Canvas.Brush.Color:=Color; Canvas.FillRect(ClientRect); DrawFieldAreas;
 DFs:=DataFields; RFs:=AxisFields(paRow); CFs:=AxisFields(paColumn);
 try
  if DFs.Count=0 then begin FViewInfo.Clear; FLayoutEngine.Clear; Exit; end;
  HeaderLevels:=CFs.Count; if DFs.Count>1 then Inc(HeaderLevels);
  if HeaderLevels=0 then HeaderLevels:=1;
  RowHeaderTotal:=0; for Lvl:=0 to RFs.Count-1 do Inc(RowHeaderTotal,RFs[Lvl].Width);
  if RowHeaderTotal=0 then RowHeaderTotal:=FRowHeaderWidth;
  BuildViewInfo;
  Y:=FFieldAreaHeight;
  if RFs.Count=0 then
   DrawCell(Rect(0,Y,RowHeaderTotal,Y+HeaderLevels*FHeaderHeight),'',taLeftJustify,True);
  for VI in FViewInfo.Items do
   case VI.Kind of
    pvekFieldHeader,pvekColumnValue:
     DrawCell(VI.Bounds,VI.Caption,taCenter,True);
    pvekRowValue:
     DrawCell(VI.Bounds,KeyPart(VI.RowKey,VI.Level),DefaultAlignment(VI.Field));
    pvekDataCell:
     begin
      DF:=VI.Field;
      S:=TextFor(VI.RowKey,VI.ColumnKey,DF);
      DrawCell(VI.Bounds,S,DefaultAlignment(DF));
     end;
    pvekTotalCell:
     begin
      if VI.Field=nil then
       DrawCell(VI.Bounds,VI.Caption,taLeftJustify,True,True)
      else begin
       DF:=VI.Field;
       if (VI.RowKey=LAR_PIVOT_TOTAL_KEY) and (VI.ColumnKey<>LAR_PIVOT_TOTAL_KEY) then
        S:=TextFor(LAR_PIVOT_TOTAL_KEY,VI.ColumnKey,DF)
       else
        S:=TextFor(VI.RowKey,LAR_PIVOT_TOTAL_KEY,DF);
       DrawCell(VI.Bounds,S,DefaultAlignment(DF),True,True);
      end;
     end;
    pvekGrandTotalCell:
     begin
      DF:=VI.Field;
      S:=TextFor(LAR_PIVOT_TOTAL_KEY,LAR_PIVOT_TOTAL_KEY,DF);
      DrawCell(VI.Bounds,S,DefaultAlignment(DF),True,True);
     end;
   end;
  X:=RowHeaderTotal;
  for VC in FLayoutEngine.Columns do if VC.Left+VC.Width>X then X:=VC.Left+VC.Width;
  if FShowRowTotals then
   for D:=0 to DFs.Count-1 do begin
    S:='TOTAL'; if DFs.Count>1 then S:=S+' '+DFs[D].Caption;
    DrawCell(Rect(X,Y,X+DFs[D].Width,Y+HeaderLevels*FHeaderHeight),S,taCenter,True,True); Inc(X,DFs[D].Width);
   end;

  if RFs.Count=0 then
   for Row:=0 to FEngine.Model.RowKeys.Count-1 do begin
    Y:=FFieldAreaHeight+HeaderLevels*FHeaderHeight+Row*FRowHeight;
    DrawCell(Rect(0,Y,RowHeaderTotal,Y+FRowHeight),'',taLeftJustify);
   end;

 finally CFs.Free; RFs.Free; DFs.Free; end;
end;

function TLarGridPivot.HitTestAt(X,Y:Integer):TLarPivotHitTest;
begin
 BuildViewInfo;
 Result:=FViewInfo.HitTest(X,Y);
end;

procedure TLarGridPivot.MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
begin
 inherited;
 if Button<>mbLeft then Exit;
 FResizingField:=ResizeFieldAtPoint(X,Y);
 if Assigned(FResizingField) then begin
  FResizeStartX:=X; FResizeStartWidth:=FResizingField.Width; MouseCapture:=True; Cursor:=crHSplit; Exit;
 end;
 FDragField:=FieldAtPoint(X,Y);
 if Assigned(FDragField) then begin
  FDragStart:=Point(X,Y); FDraggingField:=False; MouseCapture:=True; Invalidate;
 end;
end;

procedure TLarGridPivot.MouseMove(Shift:TShiftState;X,Y:Integer);
begin
 inherited;
 if Assigned(FResizingField) then begin
  FResizingField.Width:=FResizeStartWidth+(X-FResizeStartX);
  if FResizingField.Width<40 then FResizingField.Width:=40;
  Cursor:=crHSplit; Invalidate; Exit;
 end;
 if not Assigned(FDragField) then begin
  if Assigned(ResizeFieldAtPoint(X,Y)) then Cursor:=crHSplit else Cursor:=crDefault;
  Exit;
 end;
 if (Abs(X-FDragStart.X)>=4) or (Abs(Y-FDragStart.Y)>=4) then FDraggingField:=True;
 if FDraggingField then begin
  if (Y>=0) and (Y<FFieldAreaHeight) then begin
   FDragTargetArea:=AreaFromY(Y);
   FDragTargetIndex:=DropIndexAtPoint(FDragTargetArea,X);
   Cursor:=crHandPoint;
  end else begin
   FDragTargetArea:=paNone; FDragTargetIndex:=-1; Cursor:=crDefault;
  end;
  Invalidate;
 end;
end;

procedure TLarGridPivot.MouseUp(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
var A:TLarPivotArea; N:Integer; F:TLarPivotField;
begin
 inherited;
 if Button<>mbLeft then Exit;
 if Assigned(FResizingField) then begin
  FResizingField:=nil; MouseCapture:=False; Cursor:=crDefault; Invalidate; Exit;
 end;
 F:=FDragField;
 try
  if Assigned(F) and FDraggingField and (Y>=0) and (Y<FFieldAreaHeight) then begin
   A:=AreaFromY(Y); N:=DropIndexAtPoint(A,X);
   MoveField(F.FieldName,A,N);
  end;
 finally
  FDragField:=nil; FDraggingField:=False; FDragTargetArea:=paNone; FDragTargetIndex:=-1;
  MouseCapture:=False; Cursor:=crDefault; Invalidate;
 end;
end;

procedure TLarGridPivot.Resize; begin inherited;Invalidate;end;
end.
