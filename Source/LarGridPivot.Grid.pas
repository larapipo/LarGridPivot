unit LarGridPivot.Grid;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.Dialogs, Winapi.Messages, Data.DB,
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
    FShowFieldPanel:Boolean;
    FFieldPanelFontSize:Integer;
    FDragField: TLarPivotField;
    FDragStart: TPoint;
    FDraggingField: Boolean;
    FResizingField: TLarPivotField;
    FResizeStartX, FResizeStartWidth: Integer;
    FDragTargetArea: TLarPivotArea;
    FDragTargetIndex: Integer;
    FFilterButtonField: TLarPivotField;
    FHScrollPos, FVScrollPos:Integer;
    FContentWidth, FContentHeight:Integer;
    procedure WMHScroll(var Message:TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Message:TWMVScroll); message WM_VSCROLL;
    procedure WMMouseWheel(var Message:TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure UpdateScrollBars;
    function ResultTop:Integer;
    function EffectiveFieldAreaHeight:Integer;
    function AvailableBandHeight:Integer;
    procedure SetShowFieldPanel(const Value:Boolean);
    procedure SetFieldPanelFontSize(const Value:Integer);
    function ResizeFieldAtPoint(AX, AY: Integer): TLarPivotField;
    procedure DrawFieldAreas;
    function AreaFromPoint(AX, AY: Integer): TLarPivotArea;
    function AreaRect(AArea:TLarPivotArea):TRect;
    function FieldAtPoint(AX, AY: Integer): TLarPivotField;
    function DropIndexAtPoint(AArea: TLarPivotArea; AX: Integer): Integer;
    function FilterButtonAtPoint(AX, AY: Integer): TLarPivotField;
    function SortButtonAtPoint(AX, AY: Integer): TLarPivotField;
    function FieldChipRect(AField:TLarPivotField; out R:TRect):Boolean;
    procedure ShowFieldFilter(AField: TLarPivotField);
    procedure PopulateFilterValues(AField: TLarPivotField; AValues: TStrings);
    procedure ToggleFieldSort(AField: TLarPivotField);
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
    procedure CreateParams(var Params:TCreateParams); override;
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
    property ShowFieldPanel:Boolean read FShowFieldPanel write SetShowFieldPanel default True;
    property FieldPanelFontSize:Integer read FFieldPanelFontSize write SetFieldPanelFontSize default 8;
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
begin inherited; Width:=640; Height:=360; Color:=clWhite; ControlStyle:=ControlStyle+[csOpaque]; FHeaderHeight:=32; FRowHeight:=28; FRowHeaderWidth:=180;
 FShowRowTotals:=True; FShowColumnTotals:=True; FShowGrandTotal:=True; FFieldAreaHeight:=128;
 FShowFieldPanel:=True; FFieldPanelFontSize:=8; FHScrollPos:=0; FVScrollPos:=0; FContentWidth:=0; FContentHeight:=0;
 FDragTargetArea:=paNone; FDragTargetIndex:=-1; FFilterButtonField:=nil; FFields:=TLarPivotFields.Create(Self);
 FEngine:=TLarPivotEngine.Create(FFields); FLayoutEngine:=TLarPivotLayoutEngine.Create; FViewInfo:=TLarPivotViewInfo.Create(FLayoutEngine); FDataLink:=TLarPivotDataLink.Create(Self); ControlStyle:=ControlStyle+[csOpaque]; DoubleBuffered:=True; end;
destructor TLarGridPivot.Destroy; begin FDataLink.Free; FViewInfo.Free; FLayoutEngine.Free; FEngine.Free; FFields.Free; inherited; end;
procedure TLarGridPivot.BeginUpdate; begin Inc(FUpdating); end;
procedure TLarGridPivot.EndUpdate; begin if FUpdating>0 then Dec(FUpdating); if FUpdating=0 then Rebuild; end;
procedure TLarGridPivot.SetDataSource(const Value:TDataSource); begin if FDataSource=Value then Exit; FDataSource:=Value; FDataLink.DataSource:=Value; if Assigned(Value) then Value.FreeNotification(Self); RefreshFields; end;
procedure TLarGridPivot.SetFields(const Value:TLarPivotFields); begin FFields.Assign(Value); Rebuild; end;
procedure TLarGridPivot.CreateParams(var Params:TCreateParams);
begin
 inherited;
 Params.Style:=Params.Style or WS_HSCROLL or WS_VSCROLL;
end;

procedure TLarGridPivot.Notification(AComponent:TComponent;Operation:TOperation); begin inherited; if (Operation=opRemove) and (AComponent=FDataSource) then DataSource:=nil; end;
procedure TLarGridPivot.DataChanged(Sender:TObject); begin if (FUpdating=0) and not FRebuilding then Rebuild; end;

function TLarGridPivot.AvailableBandHeight:Integer;
var L:TList<TLarPivotField>; I,X,W,Rows,Usable:Integer; S:string;
begin
 if not FShowFieldPanel then Exit(0);
 L:=AreaFields(paNone);
 try
  Canvas.Font.Assign(Font); Canvas.Font.Size:=FFieldPanelFontSize;
  X:=8; Rows:=1; Usable:=ClientWidth-16;
  for I:=0 to L.Count-1 do begin
   S:=L[I].Caption; if S='' then S:=L[I].FieldName;
   W:=Canvas.TextWidth(S)+44; if W<82 then W:=82;
   if (X+W>Usable) and (X>8) then begin Inc(Rows); X:=8; end;
   Inc(X,W+4);
  end;
  Result:=Rows*24+8;
 finally L.Free; end;
end;

function TLarGridPivot.EffectiveFieldAreaHeight:Integer;
var R:TRect;
begin
 if not FShowFieldPanel then Exit(0);
 R:=AreaRect(paRow); Result:=R.Bottom;
end;

procedure TLarGridPivot.SetShowFieldPanel(const Value:Boolean);
begin if FShowFieldPanel=Value then Exit; FShowFieldPanel:=Value; Invalidate; end;

procedure TLarGridPivot.SetFieldPanelFontSize(const Value:Integer);
var N:Integer;
begin N:=Value; if N<6 then N:=6; if N>14 then N:=14;
 if N=FFieldPanelFontSize then Exit; FFieldPanelFontSize:=N; Invalidate; end;

function TLarGridPivot.ResultTop:Integer;
begin Result:=EffectiveFieldAreaHeight; end;

procedure TLarGridPivot.UpdateScrollBars;
var SI:TScrollInfo; RFs,DFs,CFs:TList<TLarPivotField>; I,W,H,HeaderLevels:Integer;
begin
 RFs:=AxisFields(paRow); DFs:=DataFields; CFs:=AxisFields(paColumn);
 try
  W:=0; for I:=0 to RFs.Count-1 do Inc(W,RFs[I].Width);
  if W=0 then W:=FRowHeaderWidth;
  for I:=0 to FLayoutEngine.Columns.Count-1 do
   if FLayoutEngine.Columns[I].Left+FLayoutEngine.Columns[I].Width>W then
    W:=FLayoutEngine.Columns[I].Left+FLayoutEngine.Columns[I].Width;
  if FShowRowTotals then for I:=0 to DFs.Count-1 do Inc(W,DFs[I].Width);
  HeaderLevels:=CFs.Count;
  if HeaderLevels>0 then Inc(HeaderLevels);
  if DFs.Count>1 then Inc(HeaderLevels);
  if HeaderLevels=0 then HeaderLevels:=1;
  H:=ResultTop+HeaderLevels*FHeaderHeight+FEngine.Model.RowKeys.Count*FRowHeight;
  if FShowColumnTotals then Inc(H,FRowHeight);
  FContentWidth:=W; FContentHeight:=H;
 finally CFs.Free; RFs.Free; DFs.Free; end;

 FillChar(SI,SizeOf(SI),0); SI.cbSize:=SizeOf(SI); SI.fMask:=SIF_RANGE or SIF_PAGE or SIF_POS;
 SI.nMin:=0; SI.nMax:=FContentWidth-1; SI.nPage:=ClientWidth; SI.nPos:=FHScrollPos;
 SetScrollInfo(Handle,SB_HORZ,SI,True); FHScrollPos:=GetScrollPos(Handle,SB_HORZ);

 FillChar(SI,SizeOf(SI),0); SI.cbSize:=SizeOf(SI); SI.fMask:=SIF_RANGE or SIF_PAGE or SIF_POS;
 SI.nMin:=0; SI.nMax:=FContentHeight-ResultTop-1;
 if ClientHeight>ResultTop then SI.nPage:=ClientHeight-ResultTop else SI.nPage:=1;
 SI.nPos:=FVScrollPos;
 SetScrollInfo(Handle,SB_VERT,SI,True); FVScrollPos:=GetScrollPos(Handle,SB_VERT);
end;

procedure TLarGridPivot.WMHScroll(var Message:TWMHScroll);
var SI:TScrollInfo; P:Integer;
begin
 FillChar(SI,SizeOf(SI),0); SI.cbSize:=SizeOf(SI); SI.fMask:=SIF_ALL; GetScrollInfo(Handle,SB_HORZ,SI); P:=SI.nPos;
 case Message.ScrollCode of
  SB_LINELEFT:Dec(P,32); SB_LINERIGHT:Inc(P,32);
  SB_PAGELEFT:Dec(P,Integer(SI.nPage)); SB_PAGERIGHT:Inc(P,Integer(SI.nPage));
  SB_THUMBTRACK,SB_THUMBPOSITION:P:=SI.nTrackPos; SB_LEFT:P:=SI.nMin; SB_RIGHT:P:=SI.nMax;
 end;
 if P<SI.nMin then P:=SI.nMin;
 if P>SI.nMax-Integer(SI.nPage)+1 then P:=SI.nMax-Integer(SI.nPage)+1;
 if P<0 then P:=0;
 if P<>FHScrollPos then begin FHScrollPos:=P; SetScrollPos(Handle,SB_HORZ,P,True); Invalidate; end;
end;

procedure TLarGridPivot.WMVScroll(var Message:TWMVScroll);
var SI:TScrollInfo; P:Integer;
begin
 FillChar(SI,SizeOf(SI),0); SI.cbSize:=SizeOf(SI); SI.fMask:=SIF_ALL; GetScrollInfo(Handle,SB_VERT,SI); P:=SI.nPos;
 case Message.ScrollCode of
  SB_LINEUP:Dec(P,FRowHeight); SB_LINEDOWN:Inc(P,FRowHeight);
  SB_PAGEUP:Dec(P,Integer(SI.nPage)); SB_PAGEDOWN:Inc(P,Integer(SI.nPage));
  SB_THUMBTRACK,SB_THUMBPOSITION:P:=SI.nTrackPos; SB_TOP:P:=SI.nMin; SB_BOTTOM:P:=SI.nMax;
 end;
 if P<SI.nMin then P:=SI.nMin;
 if P>SI.nMax-Integer(SI.nPage)+1 then P:=SI.nMax-Integer(SI.nPage)+1;
 if P<0 then P:=0;
 if P<>FVScrollPos then begin FVScrollPos:=P; SetScrollPos(Handle,SB_VERT,P,True); Invalidate; end;
end;

procedure TLarGridPivot.WMMouseWheel(var Message:TWMMouseWheel);
var SI:TScrollInfo; MaxPos:Integer;
begin
 FillChar(SI,SizeOf(SI),0); SI.cbSize:=SizeOf(SI); SI.fMask:=SIF_ALL;
 GetScrollInfo(Handle,SB_VERT,SI);
 if Message.WheelDelta>0 then Dec(FVScrollPos,FRowHeight*3)
 else Inc(FVScrollPos,FRowHeight*3);
 MaxPos:=SI.nMax-Integer(SI.nPage)+1; if MaxPos<0 then MaxPos:=0;
 if FVScrollPos<0 then FVScrollPos:=0;
 if FVScrollPos>MaxPos then FVScrollPos:=MaxPos;
 SetScrollPos(Handle,SB_VERT,FVScrollPos,True); Invalidate;
 Message.Result:=1;
end;

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
  HeaderLevels:=CFs.Count; if CFs.Count>0 then Inc(HeaderLevels); if DFs.Count>1 then Inc(HeaderLevels);
  if HeaderLevels=0 then HeaderLevels:=1;
  RowHeaderTotal:=0;
  for Lvl:=0 to RFs.Count-1 do Inc(RowHeaderTotal,RFs[Lvl].Width);
  if RowHeaderTotal=0 then RowHeaderTotal:=FRowHeaderWidth;
  FLayoutEngine.Build(FEngine.Model,CFs,DFs,RowHeaderTotal);
  FViewInfo.RowHeight:=FRowHeight;
  FViewInfo.BuildHeaders(RFs,CFs,DFs,EffectiveFieldAreaHeight,FHeaderHeight,RowHeaderTotal);
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

function TLarGridPivot.AreaRect(AArea:TLarPivotArea):TRect;
var AvH,WorkTop,HalfW,LineH:Integer;
begin
 if not FShowFieldPanel then Exit(Rect(0,0,0,0));
 AvH:=AvailableBandHeight; WorkTop:=AvH; HalfW:=ClientWidth div 2; LineH:=24;
 case AArea of
  paNone: Result:=Rect(0,0,ClientWidth,AvH);
  paData: Result:=Rect(0,WorkTop,HalfW,WorkTop+LineH);
  paColumn: Result:=Rect(HalfW,WorkTop,ClientWidth,WorkTop+LineH);
  paRow: Result:=Rect(0,WorkTop+LineH,ClientWidth,WorkTop+LineH*2);
 else Result:=Rect(0,0,0,0);
 end;
end;

function TLarGridPivot.AreaFromPoint(AX,AY:Integer):TLarPivotArea;
var R:TRect;
begin
 Result:=paNone;
 R:=AreaRect(paNone); if PtInRect(R,Point(AX,AY)) then Exit(paNone);
 R:=AreaRect(paData); if PtInRect(R,Point(AX,AY)) then Exit(paData);
 R:=AreaRect(paColumn); if PtInRect(R,Point(AX,AY)) then Exit(paColumn);
 R:=AreaRect(paRow); if PtInRect(R,Point(AX,AY)) then Exit(paRow);
end;

function TLarGridPivot.FieldChipRect(AField:TLarPivotField;out R:TRect):Boolean;
var A:TLarPivotArea; L:TList<TLarPivotField>; I,X,Y,W:Integer; S:string; AR:TRect;
begin
 Result:=False; R:=Rect(0,0,0,0); if AField=nil then Exit;
 A:=AField.Area; AR:=AreaRect(A);
 Canvas.Font.Assign(Font); Canvas.Font.Size:=FFieldPanelFontSize;
 X:=AR.Left+6; Y:=AR.Top+3; if A<>paNone then X:=AR.Left+72;
 L:=AreaFields(A);
 try
  for I:=0 to L.Count-1 do begin
   S:=L[I].Caption; if S='' then S:=L[I].FieldName;
   W:=Canvas.TextWidth(S)+44; if W<82 then W:=82;
   if (A=paNone) and (X+W>AR.Right-6) and (X>AR.Left+6) then begin X:=AR.Left+6; Inc(Y,24); end;
   R:=Rect(X,Y,X+W,Y+20);
   if L[I]=AField then Exit(True);
   X:=R.Right+4;
  end;
 finally L.Free; end;
end;

function TLarGridPivot.FieldAtPoint(AX,AY:Integer):TLarPivotField;
var A:TLarPivotArea; L:TList<TLarPivotField>; I:Integer; R:TRect;
begin
 Result:=nil; if not FShowFieldPanel then Exit;
 A:=AreaFromPoint(AX,AY); L:=AreaFields(A);
 try
  for I:=0 to L.Count-1 do
   if FieldChipRect(L[I],R) and PtInRect(R,Point(AX,AY)) then Exit(L[I]);
 finally L.Free; end;
end;

function TLarGridPivot.DropIndexAtPoint(AArea:TLarPivotArea;AX:Integer):Integer;
var L:TList<TLarPivotField>; I,X,ChipW:Integer; S:string;
begin
 Result:=0; X:=AreaRect(AArea).Left+6; if AArea<>paNone then X:=AreaRect(AArea).Left+72; L:=AreaFields(AArea);
 try
  Canvas.Font.Assign(Font); Canvas.Font.Size:=FFieldPanelFontSize;
  for I:=0 to L.Count-1 do begin
   if L[I]=FDragField then Continue;
   S:=L[I].Caption; if S='' then S:=L[I].FieldName;
   ChipW:=Canvas.TextWidth(S)+44; if ChipW<82 then ChipW:=82;
   if AX < X+(ChipW div 2) then Exit(Result);
   Inc(Result); Inc(X,ChipW+4);
  end;
 finally L.Free; end;
end;

function TLarGridPivot.FilterButtonAtPoint(AX,AY:Integer):TLarPivotField;
var F:TLarPivotField; R,B:TRect;
begin
 Result:=nil; F:=FieldAtPoint(AX,AY); if F=nil then Exit;
 if not FieldChipRect(F,R) then Exit;
 B:=Rect(R.Right-16,R.Top,R.Right,R.Bottom);
 if PtInRect(B,Point(AX,AY)) then Result:=F;
end;

function TLarGridPivot.SortButtonAtPoint(AX,AY:Integer):TLarPivotField;
var F:TLarPivotField; R,B:TRect;
begin
 Result:=nil; F:=FieldAtPoint(AX,AY); if F=nil then Exit;
 if not FieldChipRect(F,R) then Exit;
 B:=Rect(R.Right-32,R.Top,R.Right-16,R.Bottom);
 if PtInRect(B,Point(AX,AY)) then Result:=F;
end;

procedure TLarGridPivot.PopulateFilterValues(AField:TLarPivotField;AValues:TStrings);
var DS:TDataSet; B:TBookmark; V:Variant; S:string; HasBookmark:Boolean;
begin
 AValues.Clear;
 if (AField=nil) or (FDataSource=nil) or (FDataSource.DataSet=nil) then Exit;
 DS:=FDataSource.DataSet; if not DS.Active or (DS.FindField(AField.FieldName)=nil) then Exit;
 HasBookmark:=not DS.IsEmpty;
 if HasBookmark then B:=DS.GetBookmark;
 DS.DisableControls;
 try
  DS.First;
  while not DS.Eof do begin
   V:=DS.FieldByName(AField.FieldName).Value;
   if VarIsNull(V) or VarIsEmpty(V) then S:='(null)' else S:=VarToStr(V);
   if AValues.IndexOf(S)<0 then AValues.Add(S);
   DS.Next;
  end;
 finally
  if HasBookmark then begin
   if DS.BookmarkValid(B) then DS.GotoBookmark(B);
   DS.FreeBookmark(B);
  end;
  DS.EnableControls;
 end;
end;

procedure TLarGridPivot.ToggleFieldSort(AField:TLarPivotField);
begin
 if AField=nil then Exit;
 case AField.SortOrder of
  psoNone: AField.SortOrder:=psoAscending;
  psoAscending: AField.SortOrder:=psoDescending;
 else AField.SortOrder:=psoNone;
 end;
 Rebuild;
end;

procedure TLarGridPivot.ShowFieldFilter(AField:TLarPivotField);
var Fil:TLarPivotFilter; Values:TStringList; S,Prompt:string;
begin
 if AField=nil then Exit;
 Fil:=FEngine.Filters.Ensure(AField.FieldName);
 Values:=TStringList.Create;
 try
  Values.Sorted:=True; Values.Duplicates:=dupIgnore;
  PopulateFilterValues(AField,Values);
  Prompt:='Valores disponibles para '+AField.Caption+':'+sLineBreak+
    Values.Text+sLineBreak+'Ingrese un valor exacto. Deje vacio para quitar el filtro:';
  S:='';
  if Fil.Values.Count=1 then S:=Fil.Values[0];
  if not InputQuery('Filtro - '+AField.Caption,Prompt,S) then Exit;
  Fil.Clear;
  S:=Trim(S);
  if S<>'' then Fil.Values.Add(S);
  Fil.Enabled:=S<>'';
  Rebuild;
 finally Values.Free; end;
end;

procedure TLarGridPivot.DrawFieldAreas;
const Areas:array[0..3] of TLarPivotArea=(paNone,paData,paColumn,paRow);
var I,J,X,Y,ChipW,Count:Integer; A:TLarPivotArea; R,AR:TRect; F:TLarPivotField; S:string; L:TList<TLarPivotField>;
begin
 if not FShowFieldPanel then Exit;
 Canvas.Font.Assign(Font); Canvas.Font.Size:=FFieldPanelFontSize;
 for I:=0 to High(Areas) do begin
  A:=Areas[I]; AR:=AreaRect(A);
  Canvas.Brush.Color:=$00F5F5F5; Canvas.FillRect(AR); Canvas.Pen.Color:=$00D8D8D8; Canvas.Rectangle(AR);
  Canvas.Font.Style:=[fsBold]; Canvas.Font.Color:=$00606060;
  if A<>paNone then Canvas.TextOut(AR.Left+6,AR.Top+7,AreaCaption(A));
  Canvas.Font.Style:=[]; X:=AR.Left+6; Y:=AR.Top+3; if A<>paNone then X:=AR.Left+72;
  L:=AreaFields(A);
  try
   Count:=L.Count;
   for J:=0 to Count-1 do begin
    F:=L[J]; S:=F.Caption; if S='' then S:=F.FieldName;
    ChipW:=Canvas.TextWidth(S)+44; if ChipW<82 then ChipW:=82;
    if (A=paNone) and (X+ChipW>AR.Right-6) and (X>AR.Left+6) then begin X:=AR.Left+6; Inc(Y,24); end;
    if FDraggingField and (A=FDragTargetArea) and (J=FDragTargetIndex) then begin Canvas.Pen.Color:=clRed; Canvas.Pen.Width:=3; Canvas.MoveTo(X-2,Y-1); Canvas.LineTo(X-2,Y+21); Canvas.Pen.Width:=1; end;
    R:=Rect(X,Y,X+ChipW,Y+20);
    if F=FDragField then Canvas.Brush.Color:=$00E8F2FF else Canvas.Brush.Color:=clWhite;
    Canvas.Pen.Color:=$00B8B8B8; Canvas.RoundRect(R.Left,R.Top,R.Right,R.Bottom,4,4);
    Canvas.Font.Color:=clWindowText; Canvas.TextOut(R.Left+6,R.Top+3,S);
    Canvas.Font.Style:=[fsBold];
    case F.SortOrder of psoAscending:Canvas.TextOut(R.Right-31,R.Top+3,'^'); psoDescending:Canvas.TextOut(R.Right-31,R.Top+3,'v'); end;
    Canvas.TextOut(R.Right-14,R.Top+3,'v'); Canvas.Font.Style:=[]; X:=R.Right+4;
   end;
  finally L.Free; end;
  if FDraggingField and (A=FDragTargetArea) and (FDragTargetIndex>=Count) then begin Canvas.Pen.Color:=clRed; Canvas.Pen.Width:=3; Canvas.MoveTo(X-2,Y-1); Canvas.LineTo(X-2,Y+21); Canvas.Pen.Width:=1; end;
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
 function RowPartEqual(const K1,K2:string;ALevel:Integer):Boolean;
 var I:Integer;
 begin
  Result:=True;
  for I:=0 to ALevel do
   if KeyPart(K1,I)<>KeyPart(K2,I) then Exit(False);
 end;
 function TextFor(const AR,AC:string;F:TLarPivotField):string;
 begin Cell:=FEngine.Model.FindCell(AR,AC,F.FieldName); if Cell<>nil then V:=Cell.Accumulator.Value(F.SummaryType) else V:=Null; Result:=FormatCellValue(V,F); end;
begin
 Canvas.Brush.Color:=Color; Canvas.FillRect(ClientRect); DrawFieldAreas;
 DFs:=DataFields; RFs:=AxisFields(paRow); CFs:=AxisFields(paColumn);
 try
  if DFs.Count=0 then begin FViewInfo.Clear; FLayoutEngine.Clear; Exit; end;
  HeaderLevels:=CFs.Count; if CFs.Count>0 then Inc(HeaderLevels); if DFs.Count>1 then Inc(HeaderLevels);
  if HeaderLevels=0 then HeaderLevels:=1;
  RowHeaderTotal:=0; for Lvl:=0 to RFs.Count-1 do Inc(RowHeaderTotal,RFs[Lvl].Width);
  if RowHeaderTotal=0 then RowHeaderTotal:=FRowHeaderWidth;
  BuildViewInfo;
  UpdateScrollBars;
  SaveDC(Canvas.Handle);
  IntersectClipRect(Canvas.Handle,0,EffectiveFieldAreaHeight,ClientWidth,ClientHeight);
  SetViewportOrgEx(Canvas.Handle,-FHScrollPos,-FVScrollPos,nil);
  Y:=EffectiveFieldAreaHeight+FVScrollPos;

  if RFs.Count=0 then
   DrawCell(Rect(0,Y,RowHeaderTotal,Y+HeaderLevels*FHeaderHeight),'',taLeftJustify,True);
  for VI in FViewInfo.Items do
   case VI.Kind of
    pvekFieldHeader,pvekColumnValue:
     DrawCell(VI.Bounds,VI.Caption,taCenter,True);
    pvekRowValue:
     begin
      S:=KeyPart(VI.RowKey,VI.Level);
      { Parent row dimensions behave as grouped labels: suppress the repeated
        caption while the sorted row prefix remains unchanged. }
      if (VI.Level<RFs.Count-1) then begin
       Row:=FEngine.Model.RowKeys.IndexOf(VI.RowKey);
       if (Row>0) and RowPartEqual(VI.RowKey,FEngine.Model.RowKeys[Row-1],VI.Level) then S:='';
      end;
      DrawCell(VI.Bounds,S,DefaultAlignment(VI.Field),VI.Level<RFs.Count-1);
     end;
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
    Y:=EffectiveFieldAreaHeight+FVScrollPos+HeaderLevels*FHeaderHeight+Row*FRowHeight;
    DrawCell(Rect(0,Y,RowHeaderTotal,Y+FRowHeight),'',taLeftJustify);
   end;

  RestoreDC(Canvas.Handle,-1);
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
 FFilterButtonField:=FilterButtonAtPoint(X,Y);
 if Assigned(FFilterButtonField) then begin ShowFieldFilter(FFilterButtonField); FFilterButtonField:=nil; Exit; end;
 FFilterButtonField:=SortButtonAtPoint(X,Y);
 if Assigned(FFilterButtonField) then begin ToggleFieldSort(FFilterButtonField); FFilterButtonField:=nil; Exit; end;
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
var A:TLarPivotArea; N:Integer;
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
  A:=FDragTargetArea; N:=FDragTargetIndex;
  if FShowFieldPanel and (Y>=0) and (Y<EffectiveFieldAreaHeight) then begin
   FDragTargetArea:=AreaFromPoint(X,Y);
   FDragTargetIndex:=DropIndexAtPoint(FDragTargetArea,X);
   Cursor:=crHandPoint;
  end else begin
   FDragTargetArea:=paNone; FDragTargetIndex:=-1; Cursor:=crDefault;
  end;
  if (A<>FDragTargetArea) or (N<>FDragTargetIndex) then Invalidate;
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
  if Assigned(F) and FDraggingField and FShowFieldPanel and (Y>=0) and (Y<EffectiveFieldAreaHeight) then begin
   A:=AreaFromPoint(X,Y); N:=DropIndexAtPoint(A,X);
   MoveField(F.FieldName,A,N);
  end;
 finally
  FDragField:=nil; FDraggingField:=False; FDragTargetArea:=paNone; FDragTargetIndex:=-1;
  MouseCapture:=False; Cursor:=crDefault; Invalidate;
 end;
end;

procedure TLarGridPivot.Resize; begin inherited;Invalidate;end;
end.
