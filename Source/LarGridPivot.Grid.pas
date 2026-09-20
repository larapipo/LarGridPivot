unit LarGridPivot.Grid;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.Dialogs, Vcl.Forms, Vcl.StdCtrls, Vcl.CheckLst, Vcl.ExtCtrls, Vcl.Menus, Vcl.Themes, Winapi.Messages, Data.DB,
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
    FTheme:TLarPivotTheme;
    FDragField: TLarPivotField;
    FDragStart: TPoint;
    FDraggingField: Boolean;
    FResizingField: TLarPivotField;
    FResizeStartX, FResizeStartWidth: Integer;
    FDragTargetArea: TLarPivotArea;
    FDragTargetIndex: Integer;
    FFilterButtonField: TLarPivotField;
    FHotFilterField: TLarPivotField;
    FHScrollPos, FVScrollPos:Integer;
    FContentWidth, FContentHeight:Integer;
    FCollapsedGroups:TStringList;
    FSavedViews:TStringList;
    FHierarchyMenu:TPopupMenu;
    FFieldMenu:TPopupMenu;
    FMenuField:TLarPivotField;
    FHierarchyHit:TLarPivotHitTest;
    FAutoSaveLayout:Boolean;
    FAutoSaveKey:string;
    FViewDirty:Boolean;
    FScrollDirty:Boolean;
    FFilterValueCache:TStringList;
    FFilterRecordCache:TDictionary<string,TArray<string>>;
    procedure HierarchyExpandClick(Sender:TObject);
    procedure HierarchyCollapseClick(Sender:TObject);
    procedure HierarchyExpandAllClick(Sender:TObject);
    procedure HierarchyCollapseAllClick(Sender:TObject);
    procedure HierarchyToggleSubtotalClick(Sender:TObject);
    procedure ShowHierarchyMenu(X,Y:Integer; const AHit:TLarPivotHitTest);
    procedure ShowFieldMenu(X,Y:Integer; AField:TLarPivotField);
    procedure FieldSortAscClick(Sender:TObject);
    procedure FieldSortDescClick(Sender:TObject);
    procedure FieldSortNoneClick(Sender:TObject);
    procedure FieldFilterClick(Sender:TObject);
    function RowPrefix(const ARowKey:string; ALevel:Integer):string;
    function GroupID(const ARowKey:string; ALevel:Integer):string;
    procedure ToggleGroup(const ARowKey:string; ALevel:Integer);
    procedure SetTheme(const Value:TLarPivotTheme);
    function ThemeHeaderColor:TColor;
    function ThemeTotalColor:TColor;
    function ThemeGridColor:TColor;
    function ThemePanelColor:TColor;
    function ThemeTextColor:TColor;
    function ThemeHeaderTextColor:TColor;
    function ThemeTotalTextColor:TColor;
    function ThemeCellColor:TColor;
    function ThemeChipColor:TColor;

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
    procedure FilterChecklistClickCheck(Sender:TObject);
    procedure PopulateFilterValues(AField: TLarPivotField; AValues: TStrings);
    procedure BuildFilterValueCache;
    function TryBuildFilteredModelFromCache:Boolean;
    procedure ToggleFieldSort(AField:TLarPivotField; AKeepExisting:Boolean=False);
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
    function AutoLayoutFileName:string;
    procedure RestoreAutoLayout;
    procedure SaveAutoLayout;
  protected
    procedure CreateParams(var Params:TCreateParams); override;
    procedure Loaded; override;
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
    procedure SaveView(const AName:string);
    function LoadView(const AName:string):Boolean;
    procedure DeleteView(const AName:string);
    procedure GetViewNames(AList:TStrings);
    procedure SaveViewsToFile(const AFileName:string);
    procedure LoadViewsFromFile(const AFileName:string);
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
    property Theme:TLarPivotTheme read FTheme write SetTheme default ptVclStyle;
    property AutoSaveLayout:Boolean read FAutoSaveLayout write FAutoSaveLayout default True;
    property AutoSaveKey:string read FAutoSaveKey write FAutoSaveKey;
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
 FShowFieldPanel:=True; FFieldPanelFontSize:=8; FTheme:=ptVclStyle; FHScrollPos:=0; FVScrollPos:=0; FContentWidth:=0; FContentHeight:=0;
 FSavedViews:=TStringList.Create; FSavedViews.NameValueSeparator:='=';
 FFilterValueCache:=TStringList.Create; FFilterValueCache.NameValueSeparator:='=';
 FFilterRecordCache:=TDictionary<string,TArray<string>>.Create;
 FAutoSaveLayout:=True; FAutoSaveKey:=''; FViewDirty:=True; FScrollDirty:=True;
 FHierarchyMenu:=TPopupMenu.Create(Self);
 FFieldMenu:=TPopupMenu.Create(Self); FMenuField:=nil;
 FCollapsedGroups:=TStringList.Create; FCollapsedGroups.Sorted:=True; FCollapsedGroups.Duplicates:=dupIgnore;
 FDragTargetArea:=paNone; FDragTargetIndex:=-1; FFilterButtonField:=nil; FHotFilterField:=nil; FFields:=TLarPivotFields.Create(Self);
 FEngine:=TLarPivotEngine.Create(FFields); FLayoutEngine:=TLarPivotLayoutEngine.Create; FViewInfo:=TLarPivotViewInfo.Create(FLayoutEngine); FDataLink:=TLarPivotDataLink.Create(Self); ControlStyle:=ControlStyle+[csOpaque]; DoubleBuffered:=True; end;
destructor TLarGridPivot.Destroy; begin SaveAutoLayout; FFilterRecordCache.Free; FFilterValueCache.Free; FFieldMenu.Free; FHierarchyMenu.Free; FSavedViews.Free; FCollapsedGroups.Free; FDataLink.Free; FViewInfo.Free; FLayoutEngine.Free; FEngine.Free; FFields.Free; inherited; end;
procedure TLarGridPivot.BeginUpdate; begin Inc(FUpdating); end;
procedure TLarGridPivot.EndUpdate; begin if FUpdating>0 then Dec(FUpdating); if FUpdating=0 then Rebuild; end;
function TLarGridPivot.AutoLayoutFileName:string;
var N:string;
begin
 N:=FAutoSaveKey;
 if N='' then begin
  N:=Name;
  if (Owner<>nil) and (Owner.Name<>'') then N:=Owner.Name+'_'+N;
 end;
 if N='' then N:='LarGridPivot';
 Result:=IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA'))+
   'LarGridPivot\\'+N+'.json';
end;

procedure TLarGridPivot.SaveAutoLayout;
var FN:string;
begin
 if not FAutoSaveLayout or (csDesigning in ComponentState) or (FFields.Count=0) then Exit;
 FN:=AutoLayoutFileName;
 ForceDirectories(ExtractFilePath(FN));
 SaveLayoutToFile(FN);
end;

procedure TLarGridPivot.RestoreAutoLayout;
var FN:string;
begin
 if not FAutoSaveLayout or (csDesigning in ComponentState) then Exit;
 FN:=AutoLayoutFileName;
 if FileExists(FN) then
  try LoadLayoutFromFile(FN); except end;
end;

procedure TLarGridPivot.Loaded;
begin
 inherited;
 RestoreAutoLayout;
end;

procedure TLarGridPivot.SetDataSource(const Value:TDataSource); begin if FDataSource=Value then Exit; FDataSource:=Value; FDataLink.DataSource:=Value; if Assigned(Value) then Value.FreeNotification(Self); RefreshFields; end;
procedure TLarGridPivot.SetFields(const Value:TLarPivotFields); begin FFields.Assign(Value); Rebuild; end;
procedure TLarGridPivot.CreateParams(var Params:TCreateParams);
begin
 inherited;
 Params.Style:=Params.Style or WS_HSCROLL or WS_VSCROLL;
end;

procedure TLarGridPivot.Notification(AComponent:TComponent;Operation:TOperation); begin inherited; if (Operation=opRemove) and (AComponent=FDataSource) then DataSource:=nil; end;
procedure TLarGridPivot.DataChanged(Sender:TObject); begin FFilterValueCache.Clear; FFilterRecordCache.Clear; if (FUpdating=0) and not FRebuilding then Rebuild; end;

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

procedure TLarGridPivot.SetTheme(const Value:TLarPivotTheme);
begin if FTheme=Value then Exit; FTheme:=Value; Invalidate; end;

function TLarGridPivot.ThemeHeaderColor:TColor;
begin
 if FTheme=ptVclStyle then Result:=StyleServices.GetSystemColor(clBtnFace) else
 case FTheme of ptClassicBlue:Result:=$00F2E3D5; ptLight:Result:=$00F5F5F5;
 ptSilver:Result:=$00E8E8E8; ptOffice:Result:=$00F0E6D6; ptDark:Result:=$00383838;
 else Result:=clBtnFace; end;
end;
function TLarGridPivot.ThemeTotalColor:TColor;
begin if FTheme=ptVclStyle then Result:=StyleServices.GetSystemColor(clHighlight)
 else if FTheme=ptDark then Result:=$00505050 else Result:=$00E6D4BE; end;
function TLarGridPivot.ThemeGridColor:TColor;
begin if FTheme=ptVclStyle then Result:=StyleServices.GetSystemColor(clBtnShadow)
 else if FTheme=ptDark then Result:=$00606060 else Result:=$00C8C8C8; end;
function TLarGridPivot.ThemePanelColor:TColor;
begin if FTheme=ptVclStyle then Result:=StyleServices.GetSystemColor(clWindow)
 else if FTheme=ptDark then Result:=$002B2B2B else Result:=clWhite; end;
function TLarGridPivot.ThemeTextColor:TColor;
begin if FTheme=ptVclStyle then Result:=StyleServices.GetSystemColor(clWindowText)
 else if FTheme=ptDark then Result:=$00E8E8E8 else Result:=clWindowText; end;
function TLarGridPivot.ThemeHeaderTextColor:TColor;
begin if FTheme=ptVclStyle then Result:=StyleServices.GetSystemColor(clBtnText)
 else Result:=ThemeTextColor; end;
function TLarGridPivot.ThemeTotalTextColor:TColor;
begin if FTheme=ptVclStyle then Result:=StyleServices.GetSystemColor(clHighlightText)
 else Result:=ThemeTextColor; end;
function TLarGridPivot.ThemeCellColor:TColor;
begin if FTheme=ptVclStyle then Result:=StyleServices.GetSystemColor(clWindow)
 else if FTheme=ptDark then Result:=$002B2B2B else Result:=clWhite; end;
function TLarGridPivot.ThemeChipColor:TColor;
begin Result:=ThemeHeaderColor; end;

procedure TLarGridPivot.SetShowFieldPanel(const Value:Boolean);
begin if FShowFieldPanel=Value then Exit; FShowFieldPanel:=Value; FViewDirty:=True; FScrollDirty:=True; Invalidate; end;

procedure TLarGridPivot.SetFieldPanelFontSize(const Value:Integer);
var N:Integer;
begin N:=Value; if N<6 then N:=6; if N>14 then N:=14;
 if N=FFieldPanelFontSize then Exit; FFieldPanelFontSize:=N; Invalidate; end;

function TLarGridPivot.ResultTop:Integer;
begin Result:=EffectiveFieldAreaHeight; end;

procedure TLarGridPivot.UpdateScrollBars;
var SI:TScrollInfo; RFs,DFs,CFs:TList<TLarPivotField>; I,W,H,HeaderLevels:Integer; VI:TLarPivotViewItem;
begin
 if not FScrollDirty then Exit;
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
  H:=ResultTop+HeaderLevels*FHeaderHeight;
  for VI in FViewInfo.Items do begin
   if VI.Bounds.Right>W then W:=VI.Bounds.Right;
   if VI.Bounds.Bottom>H then H:=VI.Bounds.Bottom;
  end;
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
 FScrollDirty:=False;
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
begin if Value=FShowRowTotals then Exit; FShowRowTotals:=Value; FViewDirty:=True; FScrollDirty:=True; Invalidate; end;
procedure TLarGridPivot.SetShowColumnTotals(const Value:Boolean);
begin if Value=FShowColumnTotals then Exit; FShowColumnTotals:=Value; FViewDirty:=True; FScrollDirty:=True; Invalidate; end;
procedure TLarGridPivot.SetShowGrandTotal(const Value:Boolean);
begin if Value=FShowGrandTotal then Exit; FShowGrandTotal:=Value; FViewDirty:=True; FScrollDirty:=True; Invalidate; end;

procedure TLarGridPivot.BuildFieldsFromDataSet;
var DS:TDataSet; I:Integer; PF:TLarPivotField; DF:TField;
begin if (FDataSource=nil) or (FDataSource.DataSet=nil) then Exit; DS:=FDataSource.DataSet; if not DS.Active then Exit;
 FFields.BeginUpdate; try FFields.Clear; for I:=0 to DS.FieldCount-1 do begin DF:=DS.Fields[I]; PF:=FFields.Add; PF.FieldName:=DF.FieldName;
 { The user-facing label always starts from the dataset field caption. FieldName
   remains only the binding key, so applications can expose friendly captions. }
 if Trim(DF.DisplayLabel)<>'' then PF.Caption:=DF.DisplayLabel else PF.Caption:=DF.FieldName; PF.Width:=100;
 case DF.DataType of ftSmallint,ftInteger,ftWord,ftLargeint,ftAutoInc,ftFloat,ftCurrency,ftBCD,ftFMTBcd,ftSingle,ftExtended:PF.Alignment:=pvaRight;
 ftDate,ftTime,ftDateTime,ftTimeStamp,ftTimeStampOffset:PF.Alignment:=pvaCenter; else PF.Alignment:=pvaLeft; end; end; finally FFields.EndUpdate; end; end;
procedure TLarGridPivot.RefreshFields; begin if FRebuilding then Exit; FRebuilding:=True; try BuildFieldsFromDataSet; Invalidate; finally FRebuilding:=False; end; end;
procedure TLarGridPivot.Rebuild;
var P:ILarPivotDataProvider;
begin if (FUpdating>0) or FRebuilding then Exit; FRebuilding:=True; try if (FDataSource=nil) or (FDataSource.DataSet=nil) or not FDataSource.DataSet.Active then begin FEngine.Model.Clear; FViewInfo.Clear; FLayoutEngine.Clear; Invalidate; Exit; end;
 if FFields.Count=0 then BuildFieldsFromDataSet; P:=TLarDataSetPivotProvider.Create(FDataSource.DataSet); try FEngine.Build(P); finally P:=nil; end; BuildFilterValueCache; FViewDirty:=True; FScrollDirty:=True; Invalidate; finally FRebuilding:=False; end; end;
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
begin Result:=TLarPivotLayout.SaveToString(FFields,FEngine.Filters,FShowRowTotals,FShowColumnTotals,FShowGrandTotal,FTheme,FCollapsedGroups); end;

procedure TLarGridPivot.LoadLayoutFromString(const ALayout:string);
var A:TLarPivotArea;
begin
 BeginUpdate;
 try
  TLarPivotLayout.LoadFromString(ALayout,FFields,FEngine.Filters,FShowRowTotals,FShowColumnTotals,FShowGrandTotal,FTheme,FCollapsedGroups);
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
 if not FViewDirty then Exit;
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
    FShowRowTotals,FShowColumnTotals,FShowGrandTotal,FCollapsedGroups);
 finally
  CFs.Free; RFs.Free; DFs.Free;
 end;
 FViewDirty:=False; FScrollDirty:=True;
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

procedure TLarGridPivot.BuildFilterValueCache;
var DS:TDataSet; B:TBookmark; HasBookmark:Boolean; I,J:Integer; F:TField;
 Lists:TObjectList<TStringList>; FieldRefs:TList<TField>; L:TStringList;
 S,CacheKey,Cached:string;
begin
 FFilterValueCache.Clear;
 if (FDataSource=nil) or (FDataSource.DataSet=nil) then Exit;
 DS:=FDataSource.DataSet; if not DS.Active then Exit;
 Lists:=TObjectList<TStringList>.Create(True);
 FieldRefs:=TList<TField>.Create;
 try
  { Resolve dataset fields once.  FindField inside the 43k-record loop was
    unnecessarily repeated for every pivot field and every record. }
  for I:=0 to FFields.Count-1 do begin
   F:=DS.FindField(FFields[I].FieldName);
   FieldRefs.Add(F);
   L:=TStringList.Create;
   { Collect unsorted: insertion stays O(1). Sorting a large ARTICULO list
     while scanning makes every insertion increasingly expensive. }
   L.Sorted:=False; L.Duplicates:=dupAccept;
   Lists.Add(L);
  end;
  HasBookmark:=not DS.IsEmpty;
  if HasBookmark then B:=DS.GetBookmark;
  DS.DisableControls;
  try
   DS.First;
   while not DS.Eof do begin
    for I:=0 to FFields.Count-1 do begin
     F:=FieldRefs[I];
     if F<>nil then begin
      if F.IsNull then S:='(null)' else S:=F.AsString;
      Lists[I].Add(S);
     end;
    end;
    DS.Next;
   end;
  finally
   if HasBookmark then begin
    if DS.BookmarkValid(B) then DS.GotoBookmark(B);
    DS.FreeBookmark(B);
   end;
   DS.EnableControls;
  end;
  { Sort once after collection and remove adjacent duplicates in one pass. }
  for I:=0 to FFields.Count-1 do begin
   L:=Lists[I];
   L.Sort;
   if L.Count>1 then begin
    J:=L.Count-1;
    while J>0 do begin
     if SameText(L[J],L[J-1]) then L.Delete(J);
     Dec(J);
    end;
   end;
   CacheKey:=UpperCase(FFields[I].FieldName);
   Cached:=StringReplace(L.Text,sLineBreak,#30,[rfReplaceAll]);
   FFilterValueCache.Values[CacheKey]:=Cached;
  end;
 finally
  FieldRefs.Free; Lists.Free;
 end;
end;

procedure TLarGridPivot.PopulateFilterValues(AField:TLarPivotField;AValues:TStrings);
var DS:TDataSet; B:TBookmark; F:TField; S,CacheKey,Cached:string; HasBookmark:Boolean;
begin
 AValues.Clear;
 if (AField=nil) or (FDataSource=nil) or (FDataSource.DataSet=nil) then Exit;
 DS:=FDataSource.DataSet; if not DS.Active then Exit;
 F:=DS.FindField(AField.FieldName); if F=nil then Exit;

 { Distinct filter values are stable until the dataset changes.  Scanning
   40k+ records every time the dropdown opens makes the UI appear frozen. }
 CacheKey:=UpperCase(AField.FieldName);
 Cached:=FFilterValueCache.Values[CacheKey];
 if Cached<>'' then begin
  AValues.Text:=StringReplace(Cached,#30,sLineBreak,[rfReplaceAll]);
  Exit;
 end;

 HasBookmark:=not DS.IsEmpty;
 if HasBookmark then B:=DS.GetBookmark;
 DS.DisableControls;
 try
  DS.First;
  while not DS.Eof do begin
   if F.IsNull then S:='(null)' else S:=F.AsString;
   AValues.Add(S); { caller supplies Sorted=True/Duplicates=dupIgnore }
   DS.Next;
  end;
 finally
  if HasBookmark then begin
   if DS.BookmarkValid(B) then DS.GotoBookmark(B);
   DS.FreeBookmark(B);
  end;
  DS.EnableControls;
 end;
 Cached:=StringReplace(AValues.Text,sLineBreak,#30,[rfReplaceAll]);
 FFilterValueCache.Values[CacheKey]:=Cached;
end;

procedure TLarGridPivot.ToggleFieldSort(AField:TLarPivotField;AKeepExisting:Boolean);
var I:Integer;
begin
 if AField=nil then Exit;
 if not AKeepExisting then
  for I:=0 to FFields.Count-1 do
   if FFields[I]<>AField then FFields[I].SortOrder:=psoNone;
 case AField.SortOrder of
  psoNone:AField.SortOrder:=psoAscending;
  psoAscending:AField.SortOrder:=psoDescending;
 else AField.SortOrder:=psoNone;
 end;
 Rebuild;
end;

procedure TLarGridPivot.FilterChecklistClickCheck(Sender:TObject);
var
 CL:TCheckListBox; K:Integer; NewState,EveryChecked:Boolean;
begin
 if not (Sender is TCheckListBox) then Exit;
 CL:=TCheckListBox(Sender);
 if CL.ItemIndex=0 then begin
  NewState:=CL.Checked[0];
  for K:=1 to CL.Items.Count-1 do CL.Checked[K]:=NewState;
 end else begin
  EveryChecked:=True;
  for K:=1 to CL.Items.Count-1 do
   if not CL.Checked[K] then begin EveryChecked:=False; Break; end;
  CL.Checked[0]:=EveryChecked;
 end;
end;

procedure TLarGridPivot.ShowFieldFilter(AField:TLarPivotField);
var
 Fil:TLarPivotFilter; Values:TStringList; Frm:TForm; P:TPanel;
 CL:TCheckListBox; BtnOK,BtnCancel:TButton; I:Integer; AllSelected:Boolean;
begin
 if AField=nil then Exit;
 Fil:=FEngine.Filters.Ensure(AField.FieldName);
 Values:=TStringList.Create;
 Frm:=TForm.CreateNew(Self);
 try
  Values.Sorted:=True; Values.Duplicates:=dupIgnore;
  PopulateFilterValues(AField,Values);

  Frm.BorderStyle:=bsToolWindow; Frm.Caption:=AField.Caption;
  Frm.Position:=poDesigned; Frm.Width:=300; Frm.Height:=360;
  Frm.Font.Assign(Font); Frm.Color:=ThemePanelColor;
  Frm.Left:=Mouse.CursorPos.X-20; Frm.Top:=Mouse.CursorPos.Y+8;

  CL:=TCheckListBox.Create(Frm); CL.Parent:=Frm; CL.Align:=alClient;
  CL.BorderStyle:=bsNone; CL.Font.Assign(Font); CL.Color:=ThemeCellColor;
  CL.Font.Color:=ThemeTextColor; CL.ItemHeight:=22;
  CL.Items.Add('(Mostrar todos)');
  AllSelected:=not Fil.Enabled;
  for I:=0 to Values.Count-1 do begin
   CL.Items.Add(Values[I]);
   CL.Checked[I+1]:=AllSelected or (Fil.Values.IndexOf(Values[I])>=0);
  end;
  if Fil.Enabled then begin
   AllSelected:=True;
   for I:=1 to CL.Items.Count-1 do
    if not CL.Checked[I] then begin AllSelected:=False; Break; end;
  end;
  CL.Checked[0]:=AllSelected;
  CL.OnClickCheck:=FilterChecklistClickCheck;

  P:=TPanel.Create(Frm); P.Parent:=Frm; P.Align:=alBottom; P.Height:=42;
  P.BevelOuter:=bvNone; P.Color:=ThemePanelColor;

  BtnCancel:=TButton.Create(Frm); BtnCancel.Parent:=P; BtnCancel.Caption:='Cancelar';
  BtnCancel.ModalResult:=mrCancel; BtnCancel.Width:=82; BtnCancel.Height:=25;
  BtnCancel.Top:=8; BtnCancel.Left:=P.Width-90; BtnCancel.Anchors:=[akTop,akRight];

  BtnOK:=TButton.Create(Frm); BtnOK.Parent:=P; BtnOK.Caption:='Aceptar';
  BtnOK.ModalResult:=mrOk; BtnOK.Default:=True; BtnOK.Width:=82; BtnOK.Height:=25;
  BtnOK.Top:=8; BtnOK.Left:=P.Width-178; BtnOK.Anchors:=[akTop,akRight];

  if Frm.ShowModal<>mrOk then Exit;
  Fil.Clear;
  if not CL.Checked[0] then
   for I:=1 to CL.Items.Count-1 do
    if CL.Checked[I] then Fil.Values.Add(CL.Items[I]);
  Fil.Enabled:=(not CL.Checked[0]) and (Fil.Values.Count<Values.Count);
  Rebuild;
 finally
  Frm.Free; Values.Free;
 end;
end;

procedure TLarGridPivot.DrawFieldAreas;
const Areas:array[0..3] of TLarPivotArea=(paNone,paData,paColumn,paRow);
var I,J,X,Y,ChipW,Count:Integer; A:TLarPivotArea; R,AR:TRect; F:TLarPivotField; Fil:TLarPivotFilter; S:string; L:TList<TLarPivotField>;
begin
 if not FShowFieldPanel then Exit;
 Canvas.Font.Assign(Font); Canvas.Font.Size:=FFieldPanelFontSize;
 for I:=0 to High(Areas) do begin
  A:=Areas[I]; AR:=AreaRect(A);
  Canvas.Brush.Color:=ThemePanelColor; Canvas.FillRect(AR); Canvas.Pen.Color:=ThemeGridColor; Canvas.Rectangle(AR);
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
    Canvas.Font.Color:=ThemeTextColor;
    { Subtle sort marker at the left of the field caption. }
    if F.SortOrder<>psoNone then begin
     Canvas.Pen.Color:=ThemeTextColor;
     if F.SortOrder=psoAscending then begin
      Canvas.MoveTo(R.Left+6,R.Top+12); Canvas.LineTo(R.Left+10,R.Top+8); Canvas.LineTo(R.Left+14,R.Top+12);
     end else begin
      Canvas.MoveTo(R.Left+6,R.Top+8); Canvas.LineTo(R.Left+10,R.Top+12); Canvas.LineTo(R.Left+14,R.Top+8);
     end;
     Canvas.TextOut(R.Left+18,R.Top+3,S);
    end else Canvas.TextOut(R.Left+6,R.Top+3,S);
    Canvas.Font.Style:=[fsBold];
    Fil:=FEngine.Filters.Find(F.FieldName);
    if ((Fil<>nil) and Fil.Enabled and (Fil.Values.Count>0)) or (F=FHotFilterField) then begin
     if (Fil<>nil) and Fil.Enabled and (Fil.Values.Count>0) then begin
      Canvas.Brush.Color:=ThemeTotalColor; Canvas.FillRect(Rect(R.Right-18,R.Top+1,R.Right-1,R.Bottom-1));
      Canvas.Font.Color:=ThemeTotalTextColor;
     end else Canvas.Font.Color:=ThemeTextColor;
     { Small dropdown chevron, shown on hover like DevExpress field buttons. }
     Canvas.Pen.Color:=Canvas.Font.Color;
     Canvas.MoveTo(R.Right-13,R.Top+8); Canvas.LineTo(R.Right-9,R.Top+12);
     Canvas.LineTo(R.Right-5,R.Top+8);
    end;
    Canvas.Font.Style:=[]; X:=R.Right+4;
   end;
  finally L.Free; end;
  if FDraggingField and (A=FDragTargetArea) and (FDragTargetIndex>=Count) then begin Canvas.Pen.Color:=clRed; Canvas.Pen.Width:=3; Canvas.MoveTo(X-2,Y-1); Canvas.LineTo(X-2,Y+21); Canvas.Pen.Width:=1; end;
 end;
end;

function TLarGridPivot.AxisFields(AArea:TLarPivotArea):TList<TLarPivotField>;
begin Result:=AreaFields(AArea); end;

function TLarGridPivot.RowPrefix(const ARowKey:string;ALevel:Integer):string;
var I:Integer;
begin
 Result:='';
 for I:=0 to ALevel do begin
  if I>0 then Result:=Result+#29;
  Result:=Result+KeyPart(ARowKey,I);
 end;
end;

function TLarGridPivot.GroupID(const ARowKey:string;ALevel:Integer):string;
begin Result:=IntToStr(ALevel)+'|'+RowPrefix(ARowKey,ALevel); end;

procedure TLarGridPivot.ToggleGroup(const ARowKey:string;ALevel:Integer);
var S:string; I:Integer;
begin
 S:=GroupID(ARowKey,ALevel); I:=FCollapsedGroups.IndexOf(S);
 if I>=0 then FCollapsedGroups.Delete(I) else FCollapsedGroups.Add(S);
 Invalidate;
end;

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
 R,VisibleContent:TRect; S:string; DF:TLarPivotField; Cell:TLarPivotResultCell; V:Variant; Flags:Cardinal;
 DFs,RFs,CFs:TList<TLarPivotField>; VC:TLarPivotVisualColumn; VI:TLarPivotViewItem;
 procedure DrawCell(const ARect:TRect;const Txt:string;Al:TAlignment;Bold:Boolean=False;Total:Boolean=False);
 var RR:TRect; begin RR:=ARect;
  if Total then begin Canvas.Brush.Color:=ThemeTotalColor; Canvas.Font.Color:=ThemeTotalTextColor; end
  else if Bold then begin Canvas.Brush.Color:=ThemeHeaderColor; Canvas.Font.Color:=ThemeHeaderTextColor; end
  else begin Canvas.Brush.Color:=ThemeCellColor; Canvas.Font.Color:=ThemeTextColor; end;
  Canvas.FillRect(RR); Canvas.Pen.Color:=ThemeGridColor; Canvas.Rectangle(RR); InflateRect(RR,-6,-2);
  if Total then Canvas.Font.Color:=ThemeTotalTextColor
  else if Bold then Canvas.Font.Color:=ThemeHeaderTextColor
  else Canvas.Font.Color:=ThemeTextColor;
  Canvas.Font.Name:=Font.Name; Canvas.Font.Size:=Font.Size;
  Canvas.Font.Style:=Font.Style; if Bold then Canvas.Font.Style:=Canvas.Font.Style+[fsBold];
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
 Canvas.Brush.Color:=ThemeCellColor; Canvas.FillRect(ClientRect); DrawFieldAreas;
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
  { ViewInfo can contain hundreds of thousands of cells, but only a tiny
    viewport is visible. Never format values or issue GDI calls for off-screen
    cells. Bounds are in content coordinates because of the viewport origin. }
  VisibleContent:=Rect(FHScrollPos,
    EffectiveFieldAreaHeight+FVScrollPos,
    FHScrollPos+ClientWidth,
    FVScrollPos+ClientHeight);

  if RFs.Count=0 then
   DrawCell(Rect(0,Y,RowHeaderTotal,Y+HeaderLevels*FHeaderHeight),'',taLeftJustify,True);
  for VI in FViewInfo.Items do begin
   if (VI.Bounds.Right<VisibleContent.Left) or
      (VI.Bounds.Left>VisibleContent.Right) or
      (VI.Bounds.Bottom<VisibleContent.Top) or
      (VI.Bounds.Top>VisibleContent.Bottom) then
     Continue;
   case VI.Kind of
    pvekFieldHeader,pvekColumnValue:
     DrawCell(VI.Bounds,VI.Caption,taCenter,True);
    pvekExpandButton:
     begin
      { Compact square hierarchy button, matching the familiar tree/pivot +/- affordance. }
      R:=VI.Bounds;
      Canvas.Brush.Color:=ThemeChipColor; Canvas.FillRect(R);
      Canvas.Pen.Color:=ThemeGridColor; Canvas.Rectangle(R);
      Canvas.Pen.Color:=ThemeHeaderTextColor;
      Canvas.MoveTo(R.Left+3,(R.Top+R.Bottom) div 2); Canvas.LineTo(R.Right-3,(R.Top+R.Bottom) div 2);
      if VI.Caption='+' then begin
       Canvas.MoveTo((R.Left+R.Right) div 2,R.Top+3); Canvas.LineTo((R.Left+R.Right) div 2,R.Bottom-3);
      end;
     end;
    pvekRowValue:
     begin
      { Caption grouping is precomputed when ViewInfo is built.  Never scan
        RowKeys from Paint: that made scrolling large pivots quadratic. }
      S:=VI.Caption;
      { Paint the complete cell first; indent only the text so hierarchy
        buttons never leave an unpainted strip at the left. }
      DrawCell(VI.Bounds,'',DefaultAlignment(VI.Field),VI.Level<RFs.Count-1);
      R:=VI.Bounds;
      if VI.Level<RFs.Count-1 then Inc(R.Left,18) else Inc(R.Left,4);
      InflateRect(R,-2,-2);
      Canvas.Brush.Style:=bsClear; Canvas.Font.Assign(Font);
      Canvas.Font.Color:=ThemeTextColor;
      if VI.Level<RFs.Count-1 then Canvas.Font.Style:=Canvas.Font.Style+[fsBold];
      Flags:=DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
      case DefaultAlignment(VI.Field) of
       taRightJustify:Flags:=Flags or DT_RIGHT;
       taCenter:Flags:=Flags or DT_CENTER;
       else Flags:=Flags or DT_LEFT;
      end;
      DrawText(Canvas.Handle,PChar(S),Length(S),R,Flags);
      Canvas.Brush.Style:=bsSolid;
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
       if VI.ColumnKey<>LAR_PIVOT_TOTAL_KEY then
        S:=TextFor(VI.RowKey,VI.ColumnKey,DF)
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

procedure TLarGridPivot.SaveView(const AName:string);
var N:string;
begin
 N:=Trim(AName); if N='' then raise EArgumentException.Create('Debe indicar un nombre de vista');
 FSavedViews.Values[N]:=SaveLayoutToString;
end;

function TLarGridPivot.LoadView(const AName:string):Boolean;
var I:Integer;
begin
 I:=FSavedViews.IndexOfName(AName); Result:=I>=0;
 if Result then LoadLayoutFromString(FSavedViews.ValueFromIndex[I]);
end;

procedure TLarGridPivot.DeleteView(const AName:string);
var I:Integer;
begin I:=FSavedViews.IndexOfName(AName); if I>=0 then FSavedViews.Delete(I); end;

procedure TLarGridPivot.GetViewNames(AList:TStrings);
var I:Integer;
begin
 if AList=nil then Exit; AList.BeginUpdate;
 try
  AList.Clear; for I:=0 to FSavedViews.Count-1 do AList.Add(FSavedViews.Names[I]);
 finally AList.EndUpdate; end;
end;

procedure TLarGridPivot.SaveViewsToFile(const AFileName:string);
begin FSavedViews.SaveToFile(AFileName); end;

procedure TLarGridPivot.LoadViewsFromFile(const AFileName:string);
begin
 FSavedViews.Clear;
 if FileExists(AFileName) then FSavedViews.LoadFromFile(AFileName);
end;

procedure TLarGridPivot.FieldSortAscClick(Sender:TObject);
begin if FMenuField<>nil then begin FMenuField.SortOrder:=psoAscending; Rebuild; end; end;
procedure TLarGridPivot.FieldSortDescClick(Sender:TObject);
begin if FMenuField<>nil then begin FMenuField.SortOrder:=psoDescending; Rebuild; end; end;
procedure TLarGridPivot.FieldSortNoneClick(Sender:TObject);
begin if FMenuField<>nil then begin FMenuField.SortOrder:=psoNone; Rebuild; end; end;
procedure TLarGridPivot.FieldFilterClick(Sender:TObject);
begin if FMenuField<>nil then ShowFieldFilter(FMenuField); end;

procedure TLarGridPivot.ShowFieldMenu(X,Y:Integer;AField:TLarPivotField);
 procedure AddItem(const C:string; H:TNotifyEvent; Checked:Boolean=False);
 var M:TMenuItem;
 begin M:=TMenuItem.Create(FFieldMenu); M.Caption:=C; M.OnClick:=H; M.Checked:=Checked; FFieldMenu.Items.Add(M); end;
var P:TPoint;
begin
 if AField=nil then Exit;
 FMenuField:=AField; FFieldMenu.Items.Clear;
 AddItem('Orden ascendente',FieldSortAscClick,AField.SortOrder=psoAscending);
 AddItem('Orden descendente',FieldSortDescClick,AField.SortOrder=psoDescending);
 AddItem('Sin orden',FieldSortNoneClick,AField.SortOrder=psoNone);
 AddItem('-',nil);
 AddItem('Filtro...',FieldFilterClick);
 P:=ClientToScreen(Point(X,Y)); FFieldMenu.Popup(P.X,P.Y);
end;

procedure TLarGridPivot.HierarchyExpandClick(Sender:TObject);
begin
 if (FHierarchyHit.RowKey<>'') and (FCollapsedGroups.IndexOf(GroupID(FHierarchyHit.RowKey,FHierarchyHit.Level))>=0) then
  ToggleGroup(FHierarchyHit.RowKey,FHierarchyHit.Level);
end;

procedure TLarGridPivot.HierarchyCollapseClick(Sender:TObject);
begin
 if (FHierarchyHit.RowKey<>'') and (FCollapsedGroups.IndexOf(GroupID(FHierarchyHit.RowKey,FHierarchyHit.Level))<0) then
  ToggleGroup(FHierarchyHit.RowKey,FHierarchyHit.Level);
end;

procedure TLarGridPivot.HierarchyToggleSubtotalClick(Sender:TObject);
var RFs:TList<TLarPivotField>;
begin
 RFs:=AxisFields(paRow);
 try
  if (FHierarchyHit.Level>=0) and (FHierarchyHit.Level<RFs.Count) then
   RFs[FHierarchyHit.Level].ShowSubTotal:=not RFs[FHierarchyHit.Level].ShowSubTotal;
 finally RFs.Free; end;
 Rebuild;
end;

procedure TLarGridPivot.HierarchyExpandAllClick(Sender:TObject);
begin
 FCollapsedGroups.Clear; FViewDirty:=True; FScrollDirty:=True; Invalidate;
end;

procedure TLarGridPivot.HierarchyCollapseAllClick(Sender:TObject);
var RFs:TList<TLarPivotField>; Row,Lvl:Integer; ID:string;
begin
 RFs:=AxisFields(paRow);
 try
  FCollapsedGroups.Clear;
  if RFs.Count>1 then
   for Row:=0 to FEngine.Model.RowKeys.Count-1 do
    for Lvl:=0 to RFs.Count-2 do begin
     ID:=GroupID(FEngine.Model.RowKeys[Row],Lvl);
     if FCollapsedGroups.IndexOf(ID)<0 then FCollapsedGroups.Add(ID);
    end;
 finally RFs.Free; end;
 FViewDirty:=True; FScrollDirty:=True; Invalidate;
end;

procedure TLarGridPivot.ShowHierarchyMenu(X,Y:Integer;const AHit:TLarPivotHitTest);
 procedure AddItem(const ACaption:string; AHandler:TNotifyEvent);
 var M:TMenuItem;
 begin M:=TMenuItem.Create(FHierarchyMenu); M.Caption:=ACaption; M.OnClick:=AHandler; FHierarchyMenu.Items.Add(M); end;
var P:TPoint;
begin
 FHierarchyHit:=AHit; FHierarchyMenu.Items.Clear;
 AddItem('Expandir',HierarchyExpandClick);
 AddItem('Contraer',HierarchyCollapseClick);
 AddItem('-',nil);
 AddItem('Expandir todo',HierarchyExpandAllClick);
 AddItem('Contraer todo',HierarchyCollapseAllClick);
 if (AHit.Level>=0) then begin
  AddItem('-',nil);
  AddItem('Mostrar / ocultar subtotal',HierarchyToggleSubtotalClick);
 end;
 P:=ClientToScreen(Point(X,Y)); FHierarchyMenu.Popup(P.X,P.Y);
end;

procedure TLarGridPivot.MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
var HT:TLarPivotHitTest;
begin
 inherited;
 if FShowFieldPanel and (Y<EffectiveFieldAreaHeight) and (Button=mbRight) then begin
  ShowFieldMenu(X,Y,FieldAtPoint(X,Y)); Exit;
 end;
 if Y>=EffectiveFieldAreaHeight then begin
  BuildViewInfo; HT:=FViewInfo.HitTest(X+FHScrollPos,Y+FVScrollPos);
  if Button=mbRight then begin
   if HT.Kind in [pvekExpandButton,pvekRowValue,pvekTotalCell] then begin
    if HT.Level<0 then HT.Level:=0;
    ShowHierarchyMenu(X,Y,HT); Exit;
   end;
  end;
  if (Button=mbLeft) and (HT.Kind=pvekExpandButton) and (HT.RowKey<>'') then begin
   { ViewInfo places an actionable +/- only on the group header. }
   ToggleGroup(HT.RowKey,HT.Level); Exit;
  end;
 end;
 if Button<>mbLeft then Exit;
 FFilterButtonField:=FilterButtonAtPoint(X,Y);
 if Assigned(FFilterButtonField) then begin ShowFieldFilter(FFilterButtonField); FFilterButtonField:=nil; Exit; end;
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
var A:TLarPivotArea; N:Integer; Hot:TLarPivotField;
begin
 inherited;
 Hot:=nil;
 if FShowFieldPanel and (Y>=0) and (Y<EffectiveFieldAreaHeight) then begin
  Hot:=FieldAtPoint(X,Y);
  if Hot<>FHotFilterField then begin FHotFilterField:=Hot; Invalidate; end;
 end else if FHotFilterField<>nil then begin FHotFilterField:=nil; Invalidate; end;
 if Assigned(FResizingField) then begin
  { Do not rebuild the complete ViewInfo on every mouse pixel.  Large pivots
    can contain hundreds of thousands of visual cells.  The new width is kept
    in the field and geometry is rebuilt once, on MouseUp. }
  FResizingField.Width:=FResizeStartWidth+(X-FResizeStartX);
  if FResizingField.Width<40 then FResizingField.Width:=40;
  Cursor:=crHSplit; Exit;
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
var A:TLarPivotArea; N:Integer; F:TLarPivotField; R:TRect;
begin
 inherited;
 if Button<>mbLeft then Exit;
 if Assigned(FResizingField) then begin
  FResizingField:=nil; MouseCapture:=False; Cursor:=crDefault;
  FViewDirty:=True; FScrollDirty:=True; Invalidate; Exit;
 end;
 F:=FDragField;
 try
  if Assigned(F) and FDraggingField and FShowFieldPanel and (Y>=0) and (Y<EffectiveFieldAreaHeight) then begin
   A:=AreaFromPoint(X,Y); N:=DropIndexAtPoint(A,X);
   MoveField(F.FieldName,A,N);
  end
  else if Assigned(F) and not FDraggingField and FieldChipRect(F,R) and
          PtInRect(R,Point(X,Y)) then
   ToggleFieldSort(F,ssCtrl in Shift);
 finally
  FDragField:=nil; FDraggingField:=False; FDragTargetArea:=paNone; FDragTargetIndex:=-1;
  MouseCapture:=False; Cursor:=crDefault; Invalidate;
 end;
end;

procedure TLarGridPivot.Resize; begin inherited; FViewDirty:=True; FScrollDirty:=True; Invalidate;end;
end.
