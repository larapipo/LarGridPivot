unit LarGridPivot.Grid;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants, System.Zip, System.IOUtils,
  System.Generics.Collections, System.Math, Vcl.Controls, Vcl.Graphics, Vcl.Dialogs, Vcl.Forms, Vcl.StdCtrls, Vcl.CheckLst, Vcl.ExtCtrls, Vcl.Menus, Vcl.Themes, Vcl.Clipbrd, Vcl.Printers, Winapi.Messages, Data.DB,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.Filters,
  LarGridPivot.Layout, LarGridPivot.DataProvider, LarGridPivot.Model,
  LarGridPivot.Engine, LarGridPivot.LayoutEngine, LarGridPivot.ViewInfo, LarGridPivot.PrintConfig;

type
  TLarGridPivot = class(TCustomControl)
  private
    FDataSource: TDataSource; FDataLink: TDataLink; FFields: TLarPivotFields;
    FEngine: TLarPivotEngine; FSnapshot:ILarPivotDataProvider; FLayoutEngine: TLarPivotLayoutEngine; FViewInfo: TLarPivotViewInfo; FHeaderHeight, FRowHeight, FRowHeaderWidth: Integer;
    FUpdating: Integer; FRebuilding: Boolean;
    FShowRowTotals, FShowColumnTotals, FShowGrandTotal: Boolean;
    FFieldAreaHeight: Integer;
    FShowFieldPanel:Boolean;
    FFieldPanelFontSize:Integer;
    FFieldAreaSplitPercent:Integer;
    FConfigAreaColor:TColor;
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
    FGridMenu:TPopupMenu;
    FMenuField:TLarPivotField;
    FHierarchyHit:TLarPivotHitTest;
    FAutoSaveLayout:Boolean;
    FAutoSaveKey:string;
    FViewDirty:Boolean;
    FScrollDirty:Boolean;
    FFilterValueCache:TStringList;
    FBusyDepth:Integer;
    FBusySavedCursor:TCursor;
    FAutoFieldWidth:Boolean;
    FMinAutoFieldWidth:Integer;
    FMaxAutoFieldWidth:Integer;
    FAllowCellSelection:Boolean;
    FAllowMultiSelect:Boolean;
    FAllowCopyToClipboard:Boolean;
    FSelectedCells:TStringList;
    FSelectionBase:TStringList;
    FSelectionAnchor:string;
    FSelectingCells:Boolean;
    FSelectionStart:TPoint;
    FSelectionRect:TRect;
    FPrintTitle:string;
    FPrintLandscape:Boolean;
    FPrintShowPageNumbers:Boolean;
    FPrintOptions:TLarPivotPrintOptions;
    function SelectableItemAt(AX,AY:Integer):TLarPivotViewItem;
    function CellSelectionKey(AItem:TLarPivotViewItem):string;
    function IsCellSelected(AItem:TLarPivotViewItem):Boolean;
    procedure SelectCell(AItem:TLarPivotViewItem; AAdd:Boolean);
    procedure SelectCellsInRect(const ARect:TRect; AAdd:Boolean);
    procedure ClearCellSelection;
    function CellText(AItem:TLarPivotViewItem):string;
    procedure CopySelectionToClipboard;
    function PrintPageCount(AWidth,AHeight:Integer; ACanvas:TCanvas):Integer;
    procedure RenderPrintPage(ACanvas:TCanvas; AWidth,AHeight,APageNo:Integer);
    procedure BeginBusy;
    procedure EndBusy;
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
    procedure GridCopyClick(Sender:TObject);
    procedure GridPrintClick(Sender:TObject);
    procedure GridPrintPreviewClick(Sender:TObject);
    procedure GridPageSetupClick(Sender:TObject);
    procedure GridExportExcelClick(Sender:TObject);
    procedure GridExportCSVClick(Sender:TObject);
    procedure GridToggleRowTotalsClick(Sender:TObject);
    procedure GridToggleColumnTotalsClick(Sender:TObject);
    procedure GridToggleGrandTotalClick(Sender:TObject);
    procedure AddTotalsMenuItems(AMenu:TPopupMenu);
    procedure ShowGridMenu(X,Y:Integer);
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
    function FieldAreaBackgroundColor:TColor;
    function FieldAreaTextColor:TColor;

        procedure WMHScroll(var Message:TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Message:TWMVScroll); message WM_VSCROLL;
    procedure WMMouseWheel(var Message:TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure UpdateScrollBars;
    function ResultTop:Integer;
    function EffectiveFieldAreaHeight:Integer;
    function AvailableBandHeight:Integer;
    procedure SetShowFieldPanel(const Value:Boolean);
    procedure SetFieldPanelFontSize(const Value:Integer);
    procedure SetFieldAreaSplitPercent(const Value:Integer);
    procedure SetConfigAreaColor(const Value:TColor);
    procedure WMEraseBkgnd(var Message:TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMSetCursor(var Message:TWMSetCursor); message WM_SETCURSOR;
    function SuggestedFieldWidth(AField:TField; const ACaption:string):Integer;
    function ResizeFieldAtPoint(AX, AY: Integer): TLarPivotField;
    procedure DrawFieldAreas;
    function AreaFromPoint(AX, AY: Integer): TLarPivotArea;
    function AreaRect(AArea:TLarPivotArea):TRect;
    function WorkAreaRows(AArea:TLarPivotArea; AWidth:Integer):Integer;
    function FieldAtPoint(AX, AY: Integer): TLarPivotField;
    function DropIndexAtPoint(AArea: TLarPivotArea; AX: Integer; AY:Integer): Integer;
    function FilterButtonAtPoint(AX, AY: Integer): TLarPivotField;
    function SortButtonAtPoint(AX, AY: Integer): TLarPivotField;
    function FieldChipRect(AField:TLarPivotField; out R:TRect):Boolean;
    procedure ShowFieldFilter(AField: TLarPivotField);
    procedure FilterChecklistClickCheck(Sender:TObject);
    procedure PopulateFilterValues(AField: TLarPivotField; AValues: TStrings);
    procedure BuildFilterValueCache;
    procedure BuildFilterValueCacheFromSnapshot;
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
    procedure RefreshViewOnly;
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
    procedure KeyDown(var Key:Word; Shift:TShiftState); override;
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
    procedure ExportToCSV(const AFileName:string);
    procedure ExportToExcel(const AFileName:string);
    property Engine: TLarPivotEngine read FEngine;
    function HitTestAt(X, Y: Integer): TLarPivotHitTest;
    procedure ClearSelection;
    procedure CopyToClipboard;
    procedure PrintPivot;
    function PrintPivotDialog:Boolean;
    procedure PrintPreview;
    procedure SetPrintColumnWidth(const AFieldName:string; AWidth:Integer);
    procedure ConfigurePrint;
  published
    property Align; property Anchors; property Color default clWhite; property Font; property ParentFont;
    property ParentColor; property PopupMenu; property ShowHint; property Visible;
    property DataSource: TDataSource read FDataSource write SetDataSource;
    property Fields: TLarPivotFields read FFields write SetFields;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default 24;
    property RowHeight: Integer read FRowHeight write SetRowHeight default 24;
    property RowHeaderWidth: Integer read FRowHeaderWidth write SetRowHeaderWidth default 180;
    property ShowRowTotals: Boolean read FShowRowTotals write SetShowRowTotals default True;
    property ShowColumnTotals: Boolean read FShowColumnTotals write SetShowColumnTotals default True;
    property ShowGrandTotal: Boolean read FShowGrandTotal write SetShowGrandTotal default True;
    property ShowFieldPanel:Boolean read FShowFieldPanel write SetShowFieldPanel default True;
    property FieldPanelFontSize:Integer read FFieldPanelFontSize write SetFieldPanelFontSize default 8;
    property FieldAreaSplitPercent:Integer read FFieldAreaSplitPercent write SetFieldAreaSplitPercent default 27;
    property ConfigAreaColor:TColor read FConfigAreaColor write SetConfigAreaColor default $00FCF8F5;
    property AutoFieldWidth:Boolean read FAutoFieldWidth write FAutoFieldWidth default True;
    property MinAutoFieldWidth:Integer read FMinAutoFieldWidth write FMinAutoFieldWidth default 70;
    property MaxAutoFieldWidth:Integer read FMaxAutoFieldWidth write FMaxAutoFieldWidth default 320;
    property AllowCellSelection:Boolean read FAllowCellSelection write FAllowCellSelection default True;
    property AllowMultiSelect:Boolean read FAllowMultiSelect write FAllowMultiSelect default True;
    property AllowCopyToClipboard:Boolean read FAllowCopyToClipboard write FAllowCopyToClipboard default True;
    property PrintTitle:string read FPrintTitle write FPrintTitle;
    property PrintLandscape:Boolean read FPrintLandscape write FPrintLandscape default True;
    property PrintShowPageNumbers:Boolean read FPrintShowPageNumbers write FPrintShowPageNumbers default True;
    property PrintOptions:TLarPivotPrintOptions read FPrintOptions;
    property Theme:TLarPivotTheme read FTheme write SetTheme default ptVclStyle;
    property AutoSaveLayout:Boolean read FAutoSaveLayout write FAutoSaveLayout default True;
    property AutoSaveKey:string read FAutoSaveKey write FAutoSaveKey;
  end;

implementation

type TLarPivotDataLink = class(TDataLink)
private FOwner: TLarGridPivot;
protected procedure DataSetChanged; override; procedure ActiveChanged; override;
public constructor Create(AOwner: TLarGridPivot); end;

type
  TLarPivotPrintPreviewForm = class(TForm)
  private
    FPivot: TLarGridPivot;
    FPage, FPageCount: Integer;
    FZoom: Double;
    FTopPanel: TPanel;
    FPaint: TPaintBox;
    FPrev, FNext, FPrint, FSetup, FClose: TButton;
    FInfo: TLabel;
    FZoomBox: TComboBox;
    procedure PreviewPaint(Sender:TObject);
    procedure PrevClick(Sender:TObject);
    procedure NextClick(Sender:TObject);
    procedure PrintClick(Sender:TObject);
    procedure SetupClick(Sender:TObject);
    procedure CloseClick(Sender:TObject);
    procedure ZoomChange(Sender:TObject);
    procedure UpdateState;
  public
    constructor CreatePreview(AOwner:TComponent; APivot:TLarGridPivot);
  end;

constructor TLarPivotDataLink.Create(AOwner: TLarGridPivot); begin inherited Create; FOwner:=AOwner; end;
procedure TLarPivotDataLink.ActiveChanged; begin inherited; if Assigned(FOwner) then FOwner.DataChanged(Self); end;
procedure TLarPivotDataLink.DataSetChanged; begin inherited; if Assigned(FOwner) then FOwner.DataChanged(Self); end;

constructor TLarPivotPrintPreviewForm.CreatePreview(AOwner:TComponent; APivot:TLarGridPivot);
begin
 inherited CreateNew(AOwner);
 FPivot:=APivot; FPage:=1; FZoom:=0.75;
 Caption:='Vista previa de impresi'+#243+'n'; Position:=poScreenCenter; Width:=1000; Height:=760;
 Color:=clBtnFace; DoubleBuffered:=True;
 FTopPanel:=TPanel.Create(Self); FTopPanel.Parent:=Self; FTopPanel.Align:=alTop; FTopPanel.Height:=44; FTopPanel.BevelOuter:=bvNone;
 FPrev:=TButton.Create(Self); FPrev.Parent:=FTopPanel; FPrev.SetBounds(8,8,80,28); FPrev.Caption:='< Anterior'; FPrev.OnClick:=PrevClick;
 FNext:=TButton.Create(Self); FNext.Parent:=FTopPanel; FNext.SetBounds(94,8,80,28); FNext.Caption:='Siguiente >'; FNext.OnClick:=NextClick;
 FInfo:=TLabel.Create(Self); FInfo.Parent:=FTopPanel; FInfo.SetBounds(188,14,130,20);
 FZoomBox:=TComboBox.Create(Self); FZoomBox.Parent:=FTopPanel; FZoomBox.Style:=csDropDownList; FZoomBox.SetBounds(330,9,90,24);
 FZoomBox.Items.Add('50%'); FZoomBox.Items.Add('75%'); FZoomBox.Items.Add('100%'); FZoomBox.Items.Add('125%'); FZoomBox.ItemIndex:=1; FZoomBox.OnChange:=ZoomChange;
 FSetup:=TButton.Create(Self); FSetup.Parent:=FTopPanel; FSetup.SetBounds(440,8,110,28); FSetup.Caption:='Configurar...'; FSetup.OnClick:=SetupClick;
 FPrint:=TButton.Create(Self); FPrint.Parent:=FTopPanel; FPrint.SetBounds(556,8,90,28); FPrint.Caption:='Imprimir...'; FPrint.OnClick:=PrintClick;
 FClose:=TButton.Create(Self); FClose.Parent:=FTopPanel; FClose.SetBounds(652,8,80,28); FClose.Caption:='Cerrar'; FClose.OnClick:=CloseClick;
 FPaint:=TPaintBox.Create(Self); FPaint.Parent:=Self; FPaint.Align:=alClient; FPaint.OnPaint:=PreviewPaint;
 FPageCount:=FPivot.PrintPageCount(1120,790,FPaint.Canvas); if FPageCount<1 then FPageCount:=1;
 UpdateState;
end;

procedure TLarPivotPrintPreviewForm.UpdateState;
begin
 FInfo.Caption:='P'+#225+'gina '+IntToStr(FPage)+' de '+IntToStr(FPageCount);
 FPrev.Enabled:=FPage>1; FNext.Enabled:=FPage<FPageCount; FPaint.Invalidate;
end;
procedure TLarPivotPrintPreviewForm.PrevClick(Sender:TObject); begin if FPage>1 then begin Dec(FPage); UpdateState; end; end;
procedure TLarPivotPrintPreviewForm.NextClick(Sender:TObject); begin if FPage<FPageCount then begin Inc(FPage); UpdateState; end; end;
procedure TLarPivotPrintPreviewForm.PrintClick(Sender:TObject); begin FPivot.PrintPivotDialog; end;
procedure TLarPivotPrintPreviewForm.SetupClick(Sender:TObject); begin FPivot.ConfigurePrint; FPageCount:=FPivot.PrintPageCount(1120,790,FPaint.Canvas); UpdateState; end;
procedure TLarPivotPrintPreviewForm.CloseClick(Sender:TObject); begin Close; end;
procedure TLarPivotPrintPreviewForm.ZoomChange(Sender:TObject);
begin case FZoomBox.ItemIndex of 0:FZoom:=0.50; 1:FZoom:=0.75; 2:FZoom:=1.0; 3:FZoom:=1.25; end; FPaint.Invalidate; end;
procedure TLarPivotPrintPreviewForm.PreviewPaint(Sender:TObject);
var PW,PH,X,Y:Integer; R:TRect; B:TBitmap;
begin
 FPaint.Canvas.Brush.Color:=clBtnShadow; FPaint.Canvas.FillRect(FPaint.ClientRect);
 PW:=Round(1120*FZoom); PH:=Round(790*FZoom); X:=Max(12,(FPaint.Width-PW) div 2); Y:=18;
 B:=TBitmap.Create;
 try
  B.SetSize(1120,790); B.PixelFormat:=pf32bit; B.Canvas.Brush.Color:=clWhite; B.Canvas.FillRect(Rect(0,0,B.Width,B.Height));
  FPivot.RenderPrintPage(B.Canvas,B.Width,B.Height,FPage);
  R:=Rect(X,Y,X+PW,Y+PH); FPaint.Canvas.StretchDraw(R,B);
  FPaint.Canvas.Brush.Style:=bsClear; FPaint.Canvas.Pen.Color:=clGray; FPaint.Canvas.Rectangle(R);
 finally B.Free; end;
end;

constructor TLarGridPivot.Create(AOwner:TComponent);
begin inherited; Width:=640; Height:=360; Color:=clWhite; ControlStyle:=ControlStyle+[csOpaque]; FHeaderHeight:=24; FRowHeight:=24; FRowHeaderWidth:=180;
 FShowRowTotals:=True; FShowColumnTotals:=True; FShowGrandTotal:=True; FFieldAreaHeight:=128;
 FShowFieldPanel:=True; FFieldPanelFontSize:=8; FFieldAreaSplitPercent:=27; FConfigAreaColor:=$00FCF8F5; FAutoFieldWidth:=True; FMinAutoFieldWidth:=70; FMaxAutoFieldWidth:=320; FTheme:=ptVclStyle; FHScrollPos:=0; FVScrollPos:=0; FContentWidth:=0; FContentHeight:=0;
 FSavedViews:=TStringList.Create; FSavedViews.NameValueSeparator:='=';
 FFilterValueCache:=TStringList.Create; FFilterValueCache.NameValueSeparator:='=';
 FAutoSaveLayout:=True; FAutoSaveKey:=''; FBusyDepth:=0; FBusySavedCursor:=crDefault; FViewDirty:=True; FScrollDirty:=True;
 FAllowCellSelection:=True; FAllowMultiSelect:=True; FAllowCopyToClipboard:=True; FPrintTitle:=''; FPrintLandscape:=True; FPrintShowPageNumbers:=True; FPrintOptions:=TLarPivotPrintOptions.Create(Self); TabStop:=True;
 FSelectedCells:=TStringList.Create; FSelectedCells.Sorted:=True; FSelectedCells.Duplicates:=dupIgnore;
 FSelectionBase:=TStringList.Create; FSelectionBase.Sorted:=True; FSelectionBase.Duplicates:=dupIgnore; FSelectionAnchor:=''; FSelectingCells:=False;
 FHierarchyMenu:=TPopupMenu.Create(Self);
 FFieldMenu:=TPopupMenu.Create(Self);
 FGridMenu:=TPopupMenu.Create(Self); FMenuField:=nil;
 FCollapsedGroups:=TStringList.Create; FCollapsedGroups.Sorted:=True; FCollapsedGroups.Duplicates:=dupIgnore;
 FDragTargetArea:=paNone; FDragTargetIndex:=-1; FFilterButtonField:=nil; FHotFilterField:=nil; FFields:=TLarPivotFields.Create(Self);
 FEngine:=TLarPivotEngine.Create(FFields); FLayoutEngine:=TLarPivotLayoutEngine.Create; FViewInfo:=TLarPivotViewInfo.Create(FLayoutEngine); FDataLink:=TLarPivotDataLink.Create(Self); ControlStyle:=ControlStyle+[csOpaque]; DoubleBuffered:=True; end;
destructor TLarGridPivot.Destroy; begin SaveAutoLayout; FPrintOptions.Free; FSelectionBase.Free; FSelectedCells.Free; FFilterValueCache.Free; FGridMenu.Free; FFieldMenu.Free; FHierarchyMenu.Free; FSavedViews.Free; FCollapsedGroups.Free; FDataLink.Free; FViewInfo.Free; FLayoutEngine.Free; FEngine.Free; FFields.Free; inherited; end;
function TLarGridPivot.CellSelectionKey(AItem:TLarPivotViewItem):string;
begin
 if AItem=nil then Exit('');
 Result:=IntToStr(Ord(AItem.Kind))+'|'+AItem.RowKey+'|'+AItem.ColumnKey+'|'+IntToStr(AItem.Level)+'|'+IntToStr(AItem.DataIndex);
 if AItem.Field<>nil then Result:=Result+'|'+AItem.Field.FieldName;
end;

function TLarGridPivot.IsCellSelected(AItem:TLarPivotViewItem):Boolean;
begin Result:=(AItem<>nil) and (FSelectedCells.IndexOf(CellSelectionKey(AItem))>=0); end;

function TLarGridPivot.SelectableItemAt(AX,AY:Integer):TLarPivotViewItem;
var VI:TLarPivotViewItem; CX,CY:Integer;
begin
 Result:=nil; BuildViewInfo;
 CY:=AY+FVScrollPos;
 for VI in FViewInfo.Items do begin
  if VI.Kind=pvekRowValue then CX:=AX else CX:=AX+FHScrollPos;
  if (VI.Kind in [pvekRowValue,pvekDataCell,pvekTotalCell,pvekGrandTotalCell]) and VI.Contains(CX,CY) then Exit(VI);
 end;
end;

procedure TLarGridPivot.ClearCellSelection;
var R:TRect;
begin
 FSelectedCells.Clear; FSelectionAnchor:='';
 if HandleAllocated then begin
  R:=Rect(0,EffectiveFieldAreaHeight+(FViewInfo.HeaderLevels*FHeaderHeight),ClientWidth,ClientHeight);
  InvalidateRect(Handle,@R,False);
 end else Invalidate;
end;
procedure TLarGridPivot.ClearSelection;
begin ClearCellSelection; end;

procedure TLarGridPivot.SelectCell(AItem:TLarPivotViewItem;AAdd:Boolean);
var K:string; I:Integer; R:TRect;
begin
 if AItem=nil then Exit; K:=CellSelectionKey(AItem);
 if not AAdd then FSelectedCells.Clear;
 I:=FSelectedCells.IndexOf(K);
 if AAdd and (I>=0) then FSelectedCells.Delete(I) else FSelectedCells.Add(K);
 FSelectionAnchor:=K;
 if HandleAllocated then begin
  R:=AItem.Bounds;
  OffsetRect(R,-FHScrollPos,-FVScrollPos);
  if AItem.Kind=pvekRowValue then OffsetRect(R,FHScrollPos,0);
  InvalidateRect(Handle,@R,False);
 end else Invalidate;
end;

procedure TLarGridPivot.SelectCellsInRect(const ARect:TRect;AAdd:Boolean);
var VI:TLarPivotViewItem; R,PaintR:TRect; OldSelection:TStringList; K:string; Changed:Boolean;
begin
 OldSelection:=TStringList.Create;
 try
  OldSelection.Sorted:=True; OldSelection.Duplicates:=dupIgnore;
  OldSelection.Assign(FSelectedCells);
  FSelectedCells.Clear;
  if AAdd then FSelectedCells.Assign(FSelectionBase);
  for VI in FViewInfo.Items do
   if VI.Kind in [pvekRowValue,pvekDataCell,pvekTotalCell,pvekGrandTotalCell] then begin
    R:=VI.Bounds;
    if VI.Kind=pvekRowValue then OffsetRect(R,FHScrollPos,0);
    if (R.Right>ARect.Left) and (R.Left<ARect.Right) and (R.Bottom>ARect.Top) and (R.Top<ARect.Bottom) then
     FSelectedCells.Add(CellSelectionKey(VI));
   end;
  { Repaint only cells whose selected state actually changed. }
  if HandleAllocated then begin
   for VI in FViewInfo.Items do
    if VI.Kind in [pvekRowValue,pvekDataCell,pvekTotalCell,pvekGrandTotalCell] then begin
     K:=CellSelectionKey(VI);
     Changed:=(OldSelection.IndexOf(K)>=0)<>(FSelectedCells.IndexOf(K)>=0);
     if Changed then begin
      PaintR:=VI.Bounds;
      OffsetRect(PaintR,-FHScrollPos,-FVScrollPos);
      if VI.Kind=pvekRowValue then OffsetRect(PaintR,FHScrollPos,0);
      InvalidateRect(Handle,@PaintR,False);
     end;
    end;
  end else Invalidate;
 finally
  OldSelection.Free;
 end;
end;

function TLarGridPivot.CellText(AItem:TLarPivotViewItem):string;
var C:TLarPivotResultCell; V:Variant;
begin
 Result:=''; if (AItem=nil) then Exit;
 if AItem.Kind=pvekRowValue then Exit(AItem.Caption);
 if AItem.Field=nil then Exit(AItem.Caption);
 C:=FEngine.Model.FindCell(AItem.RowKey,AItem.ColumnKey,AItem.Field.FieldName);
 if C=nil then Exit;
 V:=C.Accumulator.Value(AItem.Field.SummaryType);
 Result:=FormatCellValue(V,AItem.Field);
end;

procedure TLarGridPivot.CopySelectionToClipboard;
var L:TList<TLarPivotViewItem>; VI,T:TLarPivotViewItem; I,J:Integer; S,Line:string; LastTop:Integer;
begin
 if not FAllowCopyToClipboard or (FSelectedCells.Count=0) then Exit;
 BuildViewInfo; L:=TList<TLarPivotViewItem>.Create;
 try
  for VI in FViewInfo.Items do if IsCellSelected(VI) then L.Add(VI);
  for I:=0 to L.Count-2 do for J:=I+1 to L.Count-1 do
   if (L[I].Bounds.Top>L[J].Bounds.Top) or ((L[I].Bounds.Top=L[J].Bounds.Top) and (L[I].Bounds.Left>L[J].Bounds.Left)) then begin T:=L[I]; L[I]:=L[J]; L[J]:=T; end;
  S:=''; Line:=''; LastTop:=-MaxInt;
  for VI in L do begin
   if (LastTop<>-MaxInt) and (VI.Bounds.Top<>LastTop) then begin
    if S<>'' then S:=S+sLineBreak; S:=S+Line; Line:='';
   end;
   if Line<>'' then Line:=Line+#9;
   Line:=Line+CellText(VI); LastTop:=VI.Bounds.Top;
  end;
  if Line<>'' then begin if S<>'' then S:=S+sLineBreak; S:=S+Line; end;
  Clipboard.AsText:=S;
 finally L.Free; end;
end;

procedure TLarGridPivot.CopyToClipboard;
begin CopySelectionToClipboard; end;

procedure TLarGridPivot.KeyDown(var Key:Word;Shift:TShiftState);
begin
 if FAllowCopyToClipboard and (ssCtrl in Shift) and ((Key=Ord('C')) or (Key=VK_INSERT)) then begin CopySelectionToClipboard; Key:=0; Exit; end;
 inherited;
end;

procedure TLarGridPivot.BeginBusy;
begin
 if FBusyDepth=0 then begin
  FBusySavedCursor:=Screen.Cursor;
  { Never preserve a stale hourglass from a previous operation. }
  if FBusySavedCursor=crHourGlass then FBusySavedCursor:=crDefault;
  Screen.Cursor:=crHourGlass;
  Application.ProcessMessages;
 end;
 Inc(FBusyDepth);
end;

procedure TLarGridPivot.EndBusy;
begin
 if FBusyDepth<=0 then begin
  FBusyDepth:=0;
  Screen.Cursor:=crDefault;
  Exit;
 end;
 Dec(FBusyDepth);
 if FBusyDepth=0 then begin
  if FBusySavedCursor=crHourGlass then FBusySavedCursor:=crDefault;
  Screen.Cursor:=FBusySavedCursor;
  if Cursor=crHourGlass then Cursor:=crDefault;
  if HandleAllocated then begin
   SetCursor(LoadCursor(0,IDC_ARROW));
   PostMessage(Handle,WM_SETCURSOR,Handle,MakeLParam(HTCLIENT,WM_MOUSEMOVE));
  end;
 end;
end;

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
procedure TLarGridPivot.DataChanged(Sender:TObject);
begin
 if FRebuilding then Exit;
 FFilterValueCache.Clear;
 FSnapshot:=nil;
 if FUpdating=0 then Rebuild;
end;

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

procedure TLarGridPivot.WMSetCursor(var Message:TWMSetCursor);
begin
 { Screen.Cursor is global, but VCL controls also resolve their own Cursor on
   WM_SETCURSOR. Once a long operation has ended, never let this control keep
   displaying a stale hourglass. }
 if (FBusyDepth=0) and (Cursor=crHourGlass) then Cursor:=crDefault;
 inherited;
end;

procedure TLarGridPivot.WMEraseBkgnd(var Message:TWMEraseBkgnd);
begin
 { Paint owns the complete client background. Suppressing WM_ERASEBKGND avoids
   the erase/paint cycle that caused visible flashing while hovering chips. }
 Message.Result:=1;
end;

procedure TLarGridPivot.SetFieldAreaSplitPercent(const Value:Integer);
var N:Integer;
begin
 N:=Value;
 if N<15 then N:=15;
 if N>85 then N:=85;
 if FFieldAreaSplitPercent=N then Exit;
 FFieldAreaSplitPercent:=N;
 FViewDirty:=True; FScrollDirty:=True; Invalidate;
end;

procedure TLarGridPivot.SetConfigAreaColor(const Value:TColor);
begin
 if FConfigAreaColor=Value then Exit;
 FConfigAreaColor:=Value;
 Invalidate;
end;

procedure TLarGridPivot.SetTheme(const Value:TLarPivotTheme);
begin if FTheme=Value then Exit; FTheme:=Value; Invalidate; end;

function TLarGridPivot.ThemeHeaderColor:TColor;
begin
 if FTheme=ptVclStyle then begin
  if StyleServices.Enabled and (not StyleServices.IsSystemStyle) then
   Result:=StyleServices.GetStyleColor(scPanel)
  else
   Result:=StyleServices.GetSystemColor(clBtnFace);
 end else
 case FTheme of ptClassicBlue:Result:=$00F2E3D5; ptLight:Result:=$00F5F5F5;
 ptSilver:Result:=$00E8E8E8; ptOffice:Result:=$00F0E6D6; ptDark:Result:=$00383838;
 else Result:=clBtnFace; end;
end;
function TLarGridPivot.ThemeTotalColor:TColor;
begin if FTheme=ptVclStyle then Result:=StyleServices.GetSystemColor(clHighlight)
 else if FTheme=ptDark then Result:=$00505050 else Result:=$00E6D4BE; end;
function TLarGridPivot.ThemeGridColor:TColor;
begin
 if FTheme=ptVclStyle then begin
  if StyleServices.Enabled and (not StyleServices.IsSystemStyle) then
   Result:=StyleServices.GetStyleColor(scBorder)
  else
   Result:=StyleServices.GetSystemColor(clBtnShadow);
 end else if FTheme=ptDark then Result:=$00606060 else Result:=$00C8C8C8;
end;
function TLarGridPivot.ThemePanelColor:TColor;
begin
 if FTheme=ptVclStyle then begin
  if StyleServices.Enabled and (not StyleServices.IsSystemStyle) then
   Result:=StyleServices.GetStyleColor(scWindow)
  else
   Result:=StyleServices.GetSystemColor(clWindow);
 end else if FTheme=ptDark then Result:=$002B2B2B else Result:=clWhite;
end;
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
begin
 if FTheme=ptVclStyle then begin
  if StyleServices.Enabled and (not StyleServices.IsSystemStyle) then
   Result:=StyleServices.GetStyleColor(scWindow)
  else
   Result:=StyleServices.GetSystemColor(clWindow);
 end else if FTheme=ptDark then Result:=$002B2B2B else Result:=clWhite;
end;
function TLarGridPivot.ThemeChipColor:TColor;
begin Result:=ThemeHeaderColor; end;

function TLarGridPivot.FieldAreaBackgroundColor:TColor;
begin
 { Custom-painted controls should use the VCL Style palette directly.
   GetSystemColor can legitimately map to the Windows system palette even
   while a custom .vsf style is active.  scWindow is the style-defined window
   surface and therefore follows dark styles such as Carbon reliably. }
 if StyleServices.Enabled and (not StyleServices.IsSystemStyle) then
  Result:=StyleServices.GetStyleColor(scWindow)
 else if FTheme=ptVclStyle then
  Result:=StyleServices.GetSystemColor(clWindow)
 else
  Result:=FConfigAreaColor;
end;

function TLarGridPivot.FieldAreaTextColor:TColor;
begin
 { Text must be paired with the same styled window surface used above. }
 if StyleServices.Enabled and (not StyleServices.IsSystemStyle) then
  Result:=StyleServices.GetSystemColor(clWindowText)
 else if FTheme=ptVclStyle then
  Result:=StyleServices.GetSystemColor(clWindowText)
 else
  Result:=ThemeHeaderTextColor;
end;

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
  H:=FViewInfo.ContentBottom;
  if H<ResultTop+HeaderLevels*FHeaderHeight then
   H:=ResultTop+HeaderLevels*FHeaderHeight;
  { Body items are viewport-virtualized; width still comes from layout above. }
  for VI in FViewInfo.Items do
   if VI.Bounds.Right>W then W:=VI.Bounds.Right;
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
var SI:TScrollInfo; P,OldP,Delta,HeaderLevels:Integer; R:TRect; CFs,DFs:TList<TLarPivotField>;
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
 if P<>FHScrollPos then begin
  OldP:=FHScrollPos; Delta:=OldP-P; FHScrollPos:=P; FViewDirty:=True; SetScrollPos(Handle,SB_HORZ,P,True);
  CFs:=AxisFields(paColumn); DFs:=DataFields;
  try
   HeaderLevels:=CFs.Count; if HeaderLevels>0 then Inc(HeaderLevels); if DFs.Count>1 then Inc(HeaderLevels); if HeaderLevels=0 then HeaderLevels:=1;
  finally DFs.Free; CFs.Free; end;
  { Reuse pixels already on screen. The row hierarchy is frozen, so only the
    horizontally scrolling part to its right is shifted. SW_INVALIDATE repaints
    just the newly exposed strip instead of flashing the whole control. }
  R:=Rect(FRowHeaderWidth,ResultTop,ClientWidth,ClientHeight);
  ScrollWindowEx(Handle,Delta,0,@R,@R,0,nil,SW_INVALIDATE);
  { Header and body share the same horizontal offset; invalidate their exposed
    edges without background erase. }
  RedrawWindow(Handle,nil,0,RDW_INVALIDATE or RDW_NOERASE);
 end;
end;

procedure TLarGridPivot.WMVScroll(var Message:TWMVScroll);
var SI:TScrollInfo; P,OldP,Delta,HeaderLevels:Integer; R:TRect; CFs,DFs:TList<TLarPivotField>;
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
 if P<>FVScrollPos then begin
  OldP:=FVScrollPos; Delta:=OldP-P; FVScrollPos:=P; FViewDirty:=True; SetScrollPos(Handle,SB_VERT,P,True);
  CFs:=AxisFields(paColumn); DFs:=DataFields;
  try HeaderLevels:=CFs.Count; if HeaderLevels>0 then Inc(HeaderLevels); if DFs.Count>1 then Inc(HeaderLevels); if HeaderLevels=0 then HeaderLevels:=1;
  finally DFs.Free; CFs.Free; end;
  R:=Rect(0,ResultTop+HeaderLevels*FHeaderHeight,ClientWidth,ClientHeight);
  if (Abs(Delta)<Max(1,R.Bottom-R.Top)) then
   ScrollWindowEx(Handle,0,Delta,@R,@R,0,nil,SW_INVALIDATE)
  else InvalidateRect(Handle,@R,False);
 end;
end;

procedure TLarGridPivot.WMMouseWheel(var Message:TWMMouseWheel);
var SI:TScrollInfo; MaxPos,NewPos,OldPos,Delta,HeaderLevels:Integer; R:TRect; CFs,DFs:TList<TLarPivotField>;
begin
 FillChar(SI,SizeOf(SI),0); SI.cbSize:=SizeOf(SI); SI.fMask:=SIF_ALL; GetScrollInfo(Handle,SB_VERT,SI);
 OldPos:=FVScrollPos; NewPos:=OldPos;
 if Message.WheelDelta>0 then Dec(NewPos,FRowHeight*3) else Inc(NewPos,FRowHeight*3);
 MaxPos:=SI.nMax-Integer(SI.nPage)+1; if MaxPos<0 then MaxPos:=0;
 if NewPos<0 then NewPos:=0; if NewPos>MaxPos then NewPos:=MaxPos;
 if NewPos<>OldPos then begin
  Delta:=OldPos-NewPos; FVScrollPos:=NewPos; FViewDirty:=True; SetScrollPos(Handle,SB_VERT,FVScrollPos,True);
  CFs:=AxisFields(paColumn); DFs:=DataFields;
  try HeaderLevels:=CFs.Count; if HeaderLevels>0 then Inc(HeaderLevels); if DFs.Count>1 then Inc(HeaderLevels); if HeaderLevels=0 then HeaderLevels:=1;
  finally DFs.Free; CFs.Free; end;
  R:=Rect(0,ResultTop+HeaderLevels*FHeaderHeight,ClientWidth,ClientHeight);
  if (Abs(Delta)<Max(1,R.Bottom-R.Top)) then ScrollWindowEx(Handle,0,Delta,@R,@R,0,nil,SW_INVALIDATE)
  else InvalidateRect(Handle,@R,False);
 end;
 Message.Result:=1;
end;

procedure TLarGridPivot.SetHeaderHeight(const Value:Integer);
var N:Integer;
begin N:=Value; if N<16 then N:=16; if N=FHeaderHeight then Exit; FHeaderHeight:=N; FViewDirty:=True; FScrollDirty:=True; Invalidate; end;
procedure TLarGridPivot.SetRowHeight(const Value:Integer);
var N:Integer;
begin N:=Value; if N<16 then N:=16; if N=FRowHeight then Exit; FRowHeight:=N; FViewDirty:=True; FScrollDirty:=True; Invalidate; end;
procedure TLarGridPivot.SetRowHeaderWidth(const Value:Integer);
var N:Integer;
begin N:=Value; if N<40 then N:=40; if N=FRowHeaderWidth then Exit; FRowHeaderWidth:=N; Invalidate; end;
procedure TLarGridPivot.SetShowRowTotals(const Value:Boolean);
begin
 if Value=FShowRowTotals then Exit;
 FShowRowTotals:=Value;
 { Rebuild geometry first, then clamp horizontal position to the new content width. }
 FViewDirty:=True;
 FScrollDirty:=True;
 BuildViewInfo;
 UpdateScrollBars;
 FHScrollPos:=GetScrollPos(Handle,SB_HORZ);
 FViewDirty:=True;
 BuildViewInfo;
 Invalidate;
 Update;
end;
procedure TLarGridPivot.SetShowColumnTotals(const Value:Boolean);
begin
 if Value=FShowColumnTotals then Exit;
 FShowColumnTotals:=Value;
 RefreshViewOnly;
 UpdateScrollBars;
 Update;
end;
procedure TLarGridPivot.SetShowGrandTotal(const Value:Boolean);
begin
 if Value=FShowGrandTotal then Exit;
 FShowGrandTotal:=Value;
 RefreshViewOnly;
 UpdateScrollBars;
 Update;
end;

function TLarGridPivot.SuggestedFieldWidth(AField:TField;const ACaption:string):Integer;
var CharWidth,ContentWidth,CaptionWidth,N:Integer;
begin
 Canvas.Font.Assign(Font);
 CaptionWidth:=Canvas.TextWidth(ACaption)+30;
 CharWidth:=Canvas.TextWidth('0');
 if CharWidth<6 then CharWidth:=6;
 N:=AField.DisplayWidth;
 if N<=0 then N:=AField.Size;
 if N<=0 then N:=10;
 ContentWidth:=N*CharWidth+16;
 case AField.DataType of
  ftSmallint,ftInteger,ftWord,ftLargeint,ftAutoInc:ContentWidth:=Max(ContentWidth,90);
  ftFloat,ftCurrency,ftBCD,ftFMTBcd,ftSingle,ftExtended:ContentWidth:=Max(ContentWidth,110);
  ftDate:ContentWidth:=Max(ContentWidth,90);
  ftTime:ContentWidth:=Max(ContentWidth,80);
  ftDateTime,ftTimeStamp,ftTimeStampOffset:ContentWidth:=Max(ContentWidth,135);
  ftBoolean:ContentWidth:=Max(ContentWidth,70);
 end;
 Result:=Max(ContentWidth,CaptionWidth);
 if Result<FMinAutoFieldWidth then Result:=FMinAutoFieldWidth;
 if Result>FMaxAutoFieldWidth then Result:=FMaxAutoFieldWidth;
end;

procedure TLarGridPivot.BuildFieldsFromDataSet;
var DS:TDataSet; I:Integer; PF:TLarPivotField; DF:TField;
begin if (FDataSource=nil) or (FDataSource.DataSet=nil) then Exit; DS:=FDataSource.DataSet; if not DS.Active then Exit;
 FFields.BeginUpdate; try FFields.Clear; for I:=0 to DS.FieldCount-1 do begin DF:=DS.Fields[I]; PF:=FFields.Add; PF.FieldName:=DF.FieldName;
 { The user-facing label always starts from the dataset field caption. FieldName
   remains only the binding key, so applications can expose friendly captions. }
 if Trim(DF.DisplayLabel)<>'' then PF.Caption:=DF.DisplayLabel else PF.Caption:=DF.FieldName;
 if FAutoFieldWidth then PF.Width:=SuggestedFieldWidth(DF,PF.Caption) else PF.Width:=100;
 case DF.DataType of ftSmallint,ftInteger,ftWord,ftLargeint,ftAutoInc,ftFloat,ftCurrency,ftBCD,ftFMTBcd,ftSingle,ftExtended:PF.Alignment:=pvaRight;
 ftDate,ftTime,ftDateTime,ftTimeStamp,ftTimeStampOffset:PF.Alignment:=pvaCenter; else PF.Alignment:=pvaLeft; end; end; finally FFields.EndUpdate; end; end;
procedure TLarGridPivot.RefreshFields; begin if FRebuilding then Exit; FRebuilding:=True; try BuildFieldsFromDataSet; Invalidate; finally FRebuilding:=False; end; end;
procedure TLarGridPivot.Rebuild;
var P:ILarPivotDataProvider;
begin
 if (FUpdating>0) or FRebuilding then Exit;
 BeginBusy;
 FRebuilding:=True;
 try if (FDataSource=nil) or (FDataSource.DataSet=nil) or not FDataSource.DataSet.Active then begin FEngine.Model.Clear; FViewInfo.Clear; FLayoutEngine.Clear; Invalidate; Exit; end;
 if FFields.Count=0 then BuildFieldsFromDataSet;
 { Snapshot the dataset once. Subsequent filter/layout rebuilds operate only
   on memory and never walk the application's live dataset again. }
 if FSnapshot=nil then begin
  FSnapshot:=TLarMemoryPivotProvider.Create(FDataSource.DataSet);
  BuildFilterValueCacheFromSnapshot;
 end;
 P:=FSnapshot;
 FEngine.Build(P);
 P:=nil;
 FViewDirty:=True; FScrollDirty:=True; Invalidate; finally FRebuilding:=False; EndBusy; end; end;
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

procedure TLarGridPivot.RefreshViewOnly;
begin
 FViewDirty:=True;
 FScrollDirty:=True;
 Invalidate;
end;

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
    FShowRowTotals,FShowColumnTotals,FShowGrandTotal,FCollapsedGroups,
    FHScrollPos,
    EffectiveFieldAreaHeight+FVScrollPos,
    FHScrollPos+ClientWidth+FRowHeight,
    FVScrollPos+ClientHeight+FRowHeight);
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

function TLarGridPivot.WorkAreaRows(AArea:TLarPivotArea;AWidth:Integer):Integer;
var L:TList<TLarPivotField>; I,X,W,Usable:Integer; S:string;
begin
 Result:=1;
 if AWidth<=80 then Exit;
 L:=AreaFields(AArea);
 try
  Canvas.Font.Assign(Font); Canvas.Font.Size:=FFieldPanelFontSize;
  X:=72; Usable:=AWidth-6;
  for I:=0 to L.Count-1 do begin
   S:=L[I].Caption; if S='' then S:=L[I].FieldName;
   W:=Canvas.TextWidth(S)+44; if W<82 then W:=82;
   if (X+W>Usable) and (X>72) then begin Inc(Result); X:=6; end;
   Inc(X,W+4);
  end;
 finally
  L.Free;
 end;
end;

function TLarGridPivot.AreaRect(AArea:TLarPivotArea):TRect;
var AvH,WorkTop,SplitX,LineH,DataRows,ColumnRows,TopRows,RowRows:Integer;
begin
 if not FShowFieldPanel then Exit(Rect(0,0,0,0));
 AvH:=AvailableBandHeight; WorkTop:=AvH; SplitX:=(ClientWidth*FFieldAreaSplitPercent) div 100; LineH:=24;
 DataRows:=WorkAreaRows(paData,SplitX);
 ColumnRows:=WorkAreaRows(paColumn,ClientWidth-SplitX);
 TopRows:=Max(DataRows,ColumnRows);
 RowRows:=WorkAreaRows(paRow,ClientWidth);
 case AArea of
  paNone: Result:=Rect(0,0,ClientWidth,AvH);
  paData: Result:=Rect(0,WorkTop,SplitX,WorkTop+TopRows*LineH);
  paColumn: Result:=Rect(SplitX,WorkTop,ClientWidth,WorkTop+TopRows*LineH);
  paRow: Result:=Rect(0,WorkTop+TopRows*LineH,ClientWidth,WorkTop+(TopRows+RowRows)*LineH);
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
   if (X+W>AR.Right-6) and
      (((A=paNone) and (X>AR.Left+6)) or ((A<>paNone) and (X>AR.Left+72))) then
   begin
    X:=AR.Left+6;
    Inc(Y,24);
   end;
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

function TLarGridPivot.DropIndexAtPoint(AArea:TLarPivotArea;AX:Integer;AY:Integer):Integer;
var L:TList<TLarPivotField>; I,X,Y,ChipW:Integer; S:string; AR:TRect;
begin
 Result:=0; AR:=AreaRect(AArea); X:=AR.Left+6; Y:=AR.Top+3;
 if AArea<>paNone then X:=AR.Left+72;
 L:=AreaFields(AArea);
 try
  Canvas.Font.Assign(Font); Canvas.Font.Size:=FFieldPanelFontSize;
  for I:=0 to L.Count-1 do begin
   if L[I]=FDragField then Continue;
   S:=L[I].Caption; if S='' then S:=L[I].FieldName;
   ChipW:=Canvas.TextWidth(S)+44; if ChipW<82 then ChipW:=82;
   if (X+ChipW>AR.Right-6) and
      (((AArea=paNone) and (X>AR.Left+6)) or ((AArea<>paNone) and (X>AR.Left+72))) then
   begin
    X:=AR.Left+6;
    Inc(Y,24);
   end;
   { X remains the primary insertion discriminator; wrapped lines preserve the
     same field order used by drawing and hit testing. }
   if (AY<Y+24) and (AX<X+(ChipW div 2)) then Exit(Result);
   if AY<Y then Exit(Result);
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

procedure TLarGridPivot.BuildFilterValueCacheFromSnapshot;
var I,J:Integer; L:TStringList; Lists:TObjectList<TStringList>; V:Variant;
 S,CacheKey,Cached:string;
begin
 FFilterValueCache.Clear;
 if FSnapshot=nil then Exit;
 Lists:=TObjectList<TStringList>.Create(True);
 try
  for I:=0 to FFields.Count-1 do begin
   L:=TStringList.Create;
   L.Sorted:=False; L.Duplicates:=dupAccept;
   Lists.Add(L);
  end;
  if FSnapshot.First then
   while not FSnapshot.EOF do begin
    for I:=0 to FFields.Count-1 do begin
     J:=FSnapshot.FieldIndexOf(FFields[I].FieldName);
     V:=FSnapshot.GetValueByIndex(J);
     if VarIsNull(V) or VarIsEmpty(V) then S:='(null)' else S:=VarToStr(V);
     Lists[I].Add(S);
    end;
    FSnapshot.Next;
   end;
  for I:=0 to FFields.Count-1 do begin
   L:=Lists[I]; L.Sort;
   J:=L.Count-1;
   while J>0 do begin
    if SameText(L[J],L[J-1]) then L.Delete(J);
    Dec(J);
   end;
   CacheKey:=UpperCase(FFields[I].FieldName);
   Cached:=StringReplace(L.Text,sLineBreak,#30,[rfReplaceAll]);
   FFilterValueCache.Values[CacheKey]:=Cached;
  end;
 finally
  Lists.Free;
 end;
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
 { Sorting changes only the order of already aggregated keys. Do not rescan the
   snapshot or rebuild result cells just to change presentation order. }
 BeginBusy;
 try
  FEngine.Resort;
  FViewDirty:=True;
  FScrollDirty:=True;
  Invalidate;
 finally
  EndBusy;
 end;
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
 CL:TCheckListBox; BtnOK,BtnCancel:TButton; I,MaxTextW,Step:Integer; AllSelected:Boolean; Selected:TDictionary<string,Byte>; S:string;
begin
 if AField=nil then Exit;
 Fil:=FEngine.Filters.Ensure(AField.FieldName);
 Values:=TStringList.Create;
 Frm:=TForm.CreateNew(Self);
 try
  Values.Sorted:=True; Values.Duplicates:=dupIgnore;
  PopulateFilterValues(AField,Values);

  Frm.BorderStyle:=bsToolWindow; Frm.Caption:=AField.Caption;
  Frm.Position:=poDesigned; Frm.Height:=360;
  Frm.Font.Assign(Font); Frm.Color:=ThemePanelColor;
  { Size the popup from its actual values.  Text-heavy fields such as article
    descriptions should not be forced into the old fixed 300px window. }
  Frm.Canvas.Font.Assign(Font);
  MaxTextW:=180;
  { Measuring every string with GDI made high-cardinality filters visibly slow.
    Sample the list; width is still bounded by the work area. }
  Step:=1;
  if Values.Count>250 then Step:=(Values.Count div 250)+1;
  I:=0;
  while I<Values.Count do begin
   MaxTextW:=Max(MaxTextW,Frm.Canvas.TextWidth(Values[I]));
   Inc(I,Step);
  end;
  Frm.Width:=MaxTextW+72;
  if Frm.Width<300 then Frm.Width:=300;
  if Frm.Width>Screen.WorkAreaWidth-40 then Frm.Width:=Screen.WorkAreaWidth-40;
  Frm.Left:=Mouse.CursorPos.X-20; Frm.Top:=Mouse.CursorPos.Y+8;
  if Frm.Left+Frm.Width>Screen.WorkAreaRect.Right then
   Frm.Left:=Screen.WorkAreaRect.Right-Frm.Width-8;
  if Frm.Left<Screen.WorkAreaRect.Left then Frm.Left:=Screen.WorkAreaRect.Left+8;

  CL:=TCheckListBox.Create(Frm); CL.Parent:=Frm; CL.Align:=alClient;
  CL.BorderStyle:=bsNone; CL.Font.Assign(Font); CL.Color:=ThemeCellColor;
  CL.Font.Color:=ThemeTextColor; CL.ItemHeight:=22;
  { Populate large filter lists in one Windows control update. Adding thousands
    of article descriptions one-by-one with redraw enabled is extremely costly. }
  Selected:=TDictionary<string,Byte>.Create;
  try
   if Fil.Enabled then
    for I:=0 to Fil.Values.Count-1 do
     Selected.AddOrSetValue(UpperCase(Fil.Values[I]),0);
   CL.Items.BeginUpdate;
   try
    CL.Items.Add('(Mostrar todos)');
    AllSelected:=not Fil.Enabled;
    for I:=0 to Values.Count-1 do begin
     S:=Values[I];
     CL.Items.Add(S);
     CL.Checked[I+1]:=AllSelected or Selected.ContainsKey(UpperCase(S));
    end;
   if Fil.Enabled then begin
    AllSelected:=True;
    for I:=1 to CL.Items.Count-1 do
     if not CL.Checked[I] then begin AllSelected:=False; Break; end;
   end;
   CL.Checked[0]:=AllSelected;
   finally
    CL.Items.EndUpdate;
   end;
  finally
   Selected.Free;
  end;
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
 Details:TThemedElementDetails; AreaTextColor:TColor; UseStyledPanel:Boolean;
begin
 if not FShowFieldPanel then Exit;
 Canvas.Font.Assign(Font); Canvas.Font.Size:=FFieldPanelFontSize;
 UseStyledPanel:=StyleServices.Enabled and (not StyleServices.IsSystemStyle);
 for I:=0 to High(Areas) do begin
  A:=Areas[I]; AR:=AreaRect(A);
  Canvas.Brush.Style:=bsSolid;
  if UseStyledPanel then begin
   { Paint the same themed surface a real VCL TPanel uses.  Picking a single
     palette color is not enough for dark .vsf styles: some styles use a
     themed bitmap/gradient for panels and expose a light fallback color. }
   Details:=StyleServices.GetElementDetails(tpPanelBackground);
   StyleServices.DrawElement(Canvas.Handle,Details,AR);
   AreaTextColor:=ThemeHeaderTextColor;
   StyleServices.GetElementColor(Details,ecTextColor,AreaTextColor);
   Canvas.Brush.Style:=bsClear;
   Canvas.Pen.Color:=ThemeGridColor;
   Canvas.Rectangle(AR);
   Canvas.Brush.Style:=bsSolid;
  end else begin
   Canvas.Brush.Color:=FieldAreaBackgroundColor;
   Canvas.FillRect(AR);
   Canvas.Brush.Style:=bsClear;
   Canvas.Pen.Color:=ThemeGridColor;
   Canvas.Rectangle(AR);
   Canvas.Brush.Style:=bsSolid;
   AreaTextColor:=FieldAreaTextColor;
  end;
  Canvas.Font.Style:=[fsBold];
  Canvas.Font.Color:=AreaTextColor;
  if A<>paNone then Canvas.TextOut(AR.Left+6,AR.Top+7,AreaCaption(A));
  Canvas.Font.Style:=[]; X:=AR.Left+6; Y:=AR.Top+3; if A<>paNone then X:=AR.Left+72;
  L:=AreaFields(A);
  try
   Count:=L.Count;
   for J:=0 to Count-1 do begin
    F:=L[J]; S:=F.Caption; if S='' then S:=F.FieldName;
    ChipW:=Canvas.TextWidth(S)+44; if ChipW<82 then ChipW:=82;
    if (X+ChipW>AR.Right-6) and
       (((A=paNone) and (X>AR.Left+6)) or ((A<>paNone) and (X>AR.Left+72))) then
    begin
     X:=AR.Left+6;
     Inc(Y,24);
    end;
    if FDraggingField and (A=FDragTargetArea) and (J=FDragTargetIndex) then begin Canvas.Pen.Color:=clRed; Canvas.Pen.Width:=3; Canvas.MoveTo(X-2,Y-1); Canvas.LineTo(X-2,Y+21); Canvas.Pen.Width:=1; end;
    R:=Rect(X,Y,X+ChipW,Y+20);
    if F=FDragField then begin
     if FTheme=ptVclStyle then Canvas.Brush.Color:=StyleServices.GetSystemColor(clHighlight)
     else Canvas.Brush.Color:=$00E8F2FF;
    end else Canvas.Brush.Color:=ThemeChipColor;
    Canvas.Pen.Color:=ThemeGridColor; Canvas.RoundRect(R.Left,R.Top,R.Right,R.Bottom,4,4);
    if (F=FDragField) and (FTheme=ptVclStyle) then
     Canvas.Font.Color:=StyleServices.GetSystemColor(clHighlightText)
    else
     Canvas.Font.Color:=ThemeHeaderTextColor;
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
 { Expansion changes only the hierarchy projection. The aggregate model stays
   valid, but cached ViewInfo must be rebuilt once for the new visible rows. }
 FViewDirty:=True;
 FScrollDirty:=True;
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

function TLarGridPivot.PrintPivotDialog:Boolean;
var D:TPrintDialog;
begin
 D:=TPrintDialog.Create(Self);
 try
  D.Options:=[poWarning]; Result:=D.Execute;
  if Result then PrintPivot;
 finally D.Free; end;
end;

procedure TLarGridPivot.SetPrintColumnWidth(const AFieldName:string; AWidth:Integer);
begin FPrintOptions.Columns.Ensure(AFieldName).Width:=Max(0,AWidth); end;

procedure TLarGridPivot.PrintPreview;
var F:TLarPivotPrintPreviewForm;
begin
 if (FEngine=nil) or (FEngine.Model=nil) then Exit;
 BuildViewInfo;
 F:=TLarPivotPrintPreviewForm.CreatePreview(Self,Self);
 try F.ShowModal; finally F.Free; end;
end;

function TLarGridPivot.PrintPageCount(AWidth,AHeight:Integer; ACanvas:TCanvas):Integer;
var RFs,CFs:TList<TLarPivotField>; I,D,LineH,HeaderRows,HeaderH,TopM,BottomM,
 LeftM,RightM,AvailW,FixedW,W,BandW,HCount,RowsPerPage,VCount:Integer;
begin
 Result:=1;
 if (FEngine=nil) or (FEngine.Model=nil) then Exit;
 RFs:=AxisFields(paRow); CFs:=AxisFields(paColumn);
 try
  ACanvas.Font.Assign(Font); ACanvas.Font.Size:=8;
  LeftM:=Round(AWidth*(FPrintOptions.MarginLeftMM/210.0));
  RightM:=AWidth-Round(AWidth*(FPrintOptions.MarginRightMM/210.0));
  TopM:=Round(AHeight*(FPrintOptions.MarginTopMM/297.0));
  BottomM:=AHeight-Round(AHeight*(FPrintOptions.MarginBottomMM/297.0));
  LineH:=Max(ACanvas.TextHeight('Ag')+8,28);
  HeaderRows:=Max(1,CFs.Count+1); HeaderH:=HeaderRows*LineH;
  FixedW:=0;
  for I:=0 to RFs.Count-1 do begin
   if FPrintOptions.Columns.Find(RFs[I].FieldName)<>nil then W:=FPrintOptions.Columns.Find(RFs[I].FieldName).Width else W:=0;
   if W<=0 then W:=RFs[I].Width; Inc(FixedW,W);
  end;
  AvailW:=Max(1,(RightM-LeftM)-FixedW); HCount:=1; BandW:=0;
  for D:=0 to FLayoutEngine.Columns.Count-1 do begin
   if (FLayoutEngine.Columns[D].DataField<>nil) and (FPrintOptions.Columns.Find(FLayoutEngine.Columns[D].DataField.FieldName)<>nil) then W:=FPrintOptions.Columns.Find(FLayoutEngine.Columns[D].DataField.FieldName).Width else W:=0;
   if W<=0 then W:=FLayoutEngine.Columns[D].Width;
   if (BandW>0) and (BandW+W>AvailW) then begin Inc(HCount); BandW:=0; end;
   Inc(BandW,W);
  end;
  RowsPerPage:=Max(1,(BottomM-(TopM+LineH+4+HeaderH)) div LineH);
  VCount:=Max(1,(FEngine.Model.RowKeys.Count+RowsPerPage-1) div RowsPerPage);
  Result:=HCount*VCount;
 finally CFs.Free; RFs.Free; end;
end;

procedure TLarGridPivot.RenderPrintPage(ACanvas:TCanvas; AWidth,AHeight,APageNo:Integer);
var RFs,CFs:TList<TLarPivotField>; Row,D,I,L,Y,LeftM,TopM,RightM,BottomM,LineH,
 HeaderRows,HeaderH,AvailW,FixedW,X,W,RowsPerPage,FirstRow,LastRow,HCount,HPage,VPage,
 BandStart,BandEnd,BandW,CurBand,GroupStart,GroupEnd,GW:Integer; S,Cap,GroupCap:string;
 Cell:TLarPivotResultCell; V:Variant; R:TRect;
 function ColWidth(AIndex:Integer):Integer;
 begin
  Result:=0;
  if (FLayoutEngine.Columns[AIndex].DataField<>nil) and (FPrintOptions.Columns.Find(FLayoutEngine.Columns[AIndex].DataField.FieldName)<>nil) then
   Result:=FPrintOptions.Columns.Find(FLayoutEngine.Columns[AIndex].DataField.FieldName).Width;
  if Result<=0 then Result:=FLayoutEngine.Columns[AIndex].Width;
 end;
 procedure TextCell(const AText:string; const AR:TRect; AAlign:TAlignment; ABold:Boolean=False);
 var Flags:Cardinal; RR:TRect;
 begin
  RR:=AR; ACanvas.Brush.Style:=bsClear;
  if ABold then ACanvas.Font.Style:=[fsBold] else ACanvas.Font.Style:=[];
  Flags:=DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
  case AAlign of taRightJustify:Flags:=Flags or DT_RIGHT; taCenter:Flags:=Flags or DT_CENTER; else Flags:=Flags or DT_LEFT; end;
  InflateRect(RR,-4,0); DrawTextW(ACanvas.Handle,PWideChar(AText),Length(AText),RR,Flags);
 end;
 procedure Box(const AR:TRect); begin ACanvas.Brush.Style:=bsClear; ACanvas.Pen.Color:=clSilver; ACanvas.Rectangle(AR); end;
begin
 if (FEngine=nil) or (FEngine.Model=nil) then Exit;
 BuildViewInfo; RFs:=AxisFields(paRow); CFs:=AxisFields(paColumn);
 try
  ACanvas.Brush.Color:=clWhite; ACanvas.FillRect(Rect(0,0,AWidth,AHeight)); ACanvas.Font.Assign(Font);
  LeftM:=Round(AWidth*(FPrintOptions.MarginLeftMM/210.0)); RightM:=AWidth-Round(AWidth*(FPrintOptions.MarginRightMM/210.0));
  TopM:=Round(AHeight*(FPrintOptions.MarginTopMM/297.0)); BottomM:=AHeight-Round(AHeight*(FPrintOptions.MarginBottomMM/297.0));
  ACanvas.Font.Size:=8; LineH:=Max(ACanvas.TextHeight('Ag')+8,28); HeaderRows:=Max(1,CFs.Count+1); HeaderH:=HeaderRows*LineH;
  FixedW:=0;
  for I:=0 to RFs.Count-1 do begin if FPrintOptions.Columns.Find(RFs[I].FieldName)<>nil then W:=FPrintOptions.Columns.Find(RFs[I].FieldName).Width else W:=0; if W<=0 then W:=RFs[I].Width; Inc(FixedW,W); end;
  AvailW:=Max(1,(RightM-LeftM)-FixedW);
  HCount:=1; BandW:=0;
  for D:=0 to FLayoutEngine.Columns.Count-1 do begin W:=ColWidth(D); if (BandW>0) and (BandW+W>AvailW) then begin Inc(HCount); BandW:=0; end; Inc(BandW,W); end;
  HPage:=(APageNo-1) mod HCount; VPage:=(APageNo-1) div HCount;
  BandStart:=0; BandEnd:=FLayoutEngine.Columns.Count-1; CurBand:=0; BandW:=0;
  for D:=0 to FLayoutEngine.Columns.Count-1 do begin
   W:=ColWidth(D);
   if (BandW>0) and (BandW+W>AvailW) then begin
    if CurBand=HPage then begin BandEnd:=D-1; Break; end;
    Inc(CurBand); BandStart:=D; BandW:=0;
   end;
   Inc(BandW,W);
  end;
  if CurBand<HPage then BandStart:=FLayoutEngine.Columns.Count;
  Y:=TopM; ACanvas.Font.Size:=11; ACanvas.Font.Style:=[fsBold]; if FPrintTitle<>'' then S:=FPrintTitle else S:='Pivot'; ACanvas.TextOut(LeftM,Y,S);
  if FPrintShowPageNumbers then begin S:='P'+#225+'gina '+IntToStr(APageNo)+' de '+IntToStr(PrintPageCount(AWidth,AHeight,ACanvas)); ACanvas.TextOut(RightM-ACanvas.TextWidth(S),Y,S); end;
  Inc(Y,LineH+4); ACanvas.Font.Size:=8;
  X:=LeftM;
  for I:=0 to RFs.Count-1 do begin
   if FPrintOptions.Columns.Find(RFs[I].FieldName)<>nil then W:=FPrintOptions.Columns.Find(RFs[I].FieldName).Width else W:=0; if W<=0 then W:=RFs[I].Width;
   R:=Rect(X,Y,X+W,Y+HeaderH); Box(R); Cap:=RFs[I].Caption; if Cap='' then Cap:=RFs[I].FieldName; TextCell(Cap,R,taLeftJustify,True); Inc(X,W);
  end;
  for L:=0 to CFs.Count-1 do begin
   X:=LeftM+FixedW; D:=BandStart;
   while D<=BandEnd do begin
    GroupCap:=KeyPart(FLayoutEngine.Columns[D].ColumnKey,L); GroupStart:=D; GW:=0;
    while (D<=BandEnd) and (KeyPart(FLayoutEngine.Columns[D].ColumnKey,L)=GroupCap) do begin Inc(GW,ColWidth(D)); Inc(D); end;
    GroupEnd:=D-1; R:=Rect(X,Y+L*LineH,X+GW,Y+(L+1)*LineH); Box(R); TextCell(GroupCap,R,taCenter,True); Inc(X,GW);
   end;
  end;
  X:=LeftM+FixedW;
  for D:=BandStart to BandEnd do begin W:=ColWidth(D); R:=Rect(X,Y+CFs.Count*LineH,X+W,Y+HeaderH); Box(R); if FLayoutEngine.Columns[D].DataField<>nil then Cap:=FLayoutEngine.Columns[D].DataField.Caption else Cap:=''; TextCell(Cap,R,taCenter,True); Inc(X,W); end;
  Inc(Y,HeaderH); RowsPerPage:=Max(1,(BottomM-Y) div LineH); FirstRow:=VPage*RowsPerPage; LastRow:=Min(FEngine.Model.RowKeys.Count-1,FirstRow+RowsPerPage-1);
  for Row:=FirstRow to LastRow do begin
   X:=LeftM;
   for I:=0 to RFs.Count-1 do begin if FPrintOptions.Columns.Find(RFs[I].FieldName)<>nil then W:=FPrintOptions.Columns.Find(RFs[I].FieldName).Width else W:=0; if W<=0 then W:=RFs[I].Width; R:=Rect(X,Y,X+W,Y+LineH); Box(R); TextCell(KeyPart(FEngine.Model.RowKeys[Row],I),R,taLeftJustify); Inc(X,W); end;
   for D:=BandStart to BandEnd do begin W:=ColWidth(D); R:=Rect(X,Y,X+W,Y+LineH); Box(R); Cell:=FEngine.Model.FindCell(FEngine.Model.RowKeys[Row],FLayoutEngine.Columns[D].ColumnKey,FLayoutEngine.Columns[D].DataField.FieldName); if Cell<>nil then V:=Cell.Accumulator.Value(FLayoutEngine.Columns[D].DataField.SummaryType) else V:=Null; S:=FormatCellValue(V,FLayoutEngine.Columns[D].DataField); TextCell(S,R,taRightJustify); Inc(X,W); end;
   Inc(Y,LineH);
  end;
 finally CFs.Free; RFs.Free; end;
end;

procedure TLarGridPivot.PrintPivot;
var P,PC:Integer;
begin
 if (FEngine=nil) or (FEngine.Model=nil) then Exit;
 if FPrintLandscape then Printer.Orientation:=poLandscape else Printer.Orientation:=poPortrait;
 Printer.Title:=FPrintTitle; Printer.BeginDoc;
 try
  PC:=PrintPageCount(Printer.PageWidth,Printer.PageHeight,Printer.Canvas);
  for P:=1 to PC do begin if P>1 then Printer.NewPage; RenderPrintPage(Printer.Canvas,Printer.PageWidth,Printer.PageHeight,P); end;
 finally Printer.EndDoc; end;
end;

procedure TLarGridPivot.ExportToCSV(const AFileName:string);
var SL:TStringList; RFs:TList<TLarPivotField>; Row,D,I:Integer; Line,S:string;
 Cell:TLarPivotResultCell; V:Variant;
 function Q(const A:string):string;
 begin Result:='"'+StringReplace(A,'"','""',[rfReplaceAll])+'"'; end;
begin
 BuildViewInfo;
 RFs:=AxisFields(paRow); SL:=TStringList.Create;
 try
  Line:='';
  for I:=0 to RFs.Count-1 do begin if Line<>'' then Line:=Line+';'; Line:=Line+Q(RFs[I].Caption); end;
  for D:=0 to FLayoutEngine.Columns.Count-1 do begin
   if Line<>'' then Line:=Line+';';
   S:=FLayoutEngine.Columns[D].ColumnKey;
   if FLayoutEngine.Columns[D].DataField<>nil then S:=S+' '+FLayoutEngine.Columns[D].DataField.Caption;
   Line:=Line+Q(S);
  end;
  SL.Add(Line);
  for Row:=0 to FEngine.Model.RowKeys.Count-1 do begin
   Line:='';
   for I:=0 to RFs.Count-1 do begin if Line<>'' then Line:=Line+';'; Line:=Line+Q(KeyPart(FEngine.Model.RowKeys[Row],I)); end;
   for D:=0 to FLayoutEngine.Columns.Count-1 do begin
    Cell:=FEngine.Model.FindCell(FEngine.Model.RowKeys[Row],FLayoutEngine.Columns[D].ColumnKey,FLayoutEngine.Columns[D].DataField.FieldName);
    if Cell<>nil then V:=Cell.Accumulator.Value(FLayoutEngine.Columns[D].DataField.SummaryType) else V:=Null;
    S:=FormatCellValue(V,FLayoutEngine.Columns[D].DataField);
    if Line<>'' then Line:=Line+';'; Line:=Line+Q(S);
   end;
   SL.Add(Line);
  end;
  SL.SaveToFile(AFileName,TEncoding.UTF8);
 finally SL.Free; RFs.Free; end;
end;

procedure TLarGridPivot.ExportToExcel(const AFileName:string);
var Zip:TZipFile; RFs,CFs:TList<TLarPivotField>; Row,D,I,ColIndex,HeaderRows,DataRow,Level,StartCol,EndCol:Integer;
 Sheet,Line,S,FileName,Merges:string; MergeCount:Integer; Cell:TLarPivotResultCell; V:Variant;
 MS:TMemoryStream; B:TBytes;
 function X(const A:string):string;
 begin
  Result:=StringReplace(A,'&','&amp;',[rfReplaceAll]);
  Result:=StringReplace(Result,'<','&lt;',[rfReplaceAll]);
  Result:=StringReplace(Result,'>','&gt;',[rfReplaceAll]);
  Result:=StringReplace(Result,'"','&quot;',[rfReplaceAll]);
 end;
 function ColName(AIndex:Integer):string;
 var N:Integer;
 begin
  Result:=''; N:=AIndex+1;
  while N>0 do begin
   Result:=Chr(Ord('A')+((N-1) mod 26))+Result;
   N:=(N-1) div 26;
  end;
 end;
 function TextCell(ACol,ARow:Integer;const AValue:string):string;
 begin
  Result:='<c r="'+ColName(ACol)+IntToStr(ARow)+'" t="inlineStr"><is><t xml:space="preserve">'+X(AValue)+'</t></is></c>';
 end;
 function NumberCell(ACol,ARow:Integer;const AValue:Variant):string;
 var FS:TFormatSettings; N:Double;
 begin
  N:=AValue; FS:=TFormatSettings.Create; FS.DecimalSeparator:='.';
  Result:='<c r="'+ColName(ACol)+IntToStr(ARow)+'"><v>'+FloatToStr(N,FS)+'</v></c>';
 end;
 procedure AddZipText(const AName,AContent:string);
 begin
  B:=TEncoding.UTF8.GetBytes(AContent);
  MS:=TMemoryStream.Create;
  try
   if Length(B)>0 then MS.WriteBuffer(B[0],Length(B));
   MS.Position:=0; Zip.Add(MS,AName);
  finally MS.Free; end;
 end;
begin
 BuildViewInfo;
 FileName:=ChangeFileExt(AFileName,'.xlsx');
 RFs:=AxisFields(paRow); CFs:=AxisFields(paColumn);
 Zip:=TZipFile.Create;
 try
  Zip.Open(FileName,zmWrite);
  AddZipText('[Content_Types].xml',
   '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+
   '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'+
   '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'+
   '<Default Extension="xml" ContentType="application/xml"/>'+
   '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'+
   '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'+
   '</Types>');
  AddZipText('_rels/.rels',
   '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+
   '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'+
   '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'+
   '</Relationships>');
  AddZipText('xl/workbook.xml',
   '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+
   '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'+
   '<sheets><sheet name="Pivot" sheetId="1" r:id="rId1"/></sheets></workbook>');
  AddZipText('xl/_rels/workbook.xml.rels',
   '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+
   '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'+
   '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'+
   '</Relationships>');

  { Build the worksheet from the pivot layout, preserving the visible
    column hierarchy instead of flattening ColumnKey into one caption. }
  HeaderRows:=CFs.Count;
  if CFs.Count>0 then Inc(HeaderRows); { field-name band, e.g. Mes }
  if FLayoutEngine.Columns.Count>0 then Inc(HeaderRows); { data-field band }
  if HeaderRows=0 then HeaderRows:=1;
  Sheet:='<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+
   '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>';
  Merges:=''; MergeCount:=0;

  { Row fields span the complete pivot header. }
  for Level:=0 to HeaderRows-1 do begin
   Line:='<row r="'+IntToStr(Level+1)+'">';
   if Level=0 then begin
    for I:=0 to RFs.Count-1 do begin
     Line:=Line+TextCell(I,1,RFs[I].Caption);
     if HeaderRows>1 then
      begin Merges:=Merges+'<mergeCell ref="'+ColName(I)+'1:'+ColName(I)+IntToStr(HeaderRows)+'"/>'; Inc(MergeCount); end;
    end;
    { Same top field-name band shown by the pivot: Mes, Semana, Dia, etc. }
    if (CFs.Count>0) and (FLayoutEngine.Columns.Count>0) then begin
     S:='';
     for I:=0 to CFs.Count-1 do begin
      if I>0 then S:=S+' / ';
      if CFs[I].Caption<>'' then S:=S+CFs[I].Caption else S:=S+CFs[I].FieldName;
     end;
     Line:=Line+TextCell(RFs.Count,1,S);
     if FLayoutEngine.Columns.Count>1 then begin
      Merges:=Merges+'<mergeCell ref="'+ColName(RFs.Count)+'1:'+
        ColName(RFs.Count+FLayoutEngine.Columns.Count-1)+'1"/>'; Inc(MergeCount);
     end;
    end;
   end;

   { One real Excel header row for each column hierarchy level. }
   if (CFs.Count>0) and (Level>0) and (Level<=CFs.Count) then begin
    D:=0;
    while D<FLayoutEngine.Columns.Count do begin
     S:=KeyPart(FLayoutEngine.Columns[D].ColumnKey,Level-1);
     StartCol:=RFs.Count+D;
     EndCol:=D;
     while (EndCol+1<FLayoutEngine.Columns.Count) and
       (KeyPart(FLayoutEngine.Columns[EndCol+1].ColumnKey,Level-1)=S) do Inc(EndCol);
     { Do not merge across a change in any parent level. }
     if Level>1 then
      while (EndCol>D) and
       (KeyPart(FLayoutEngine.Columns[EndCol].ColumnKey,Level-2)<>
        KeyPart(FLayoutEngine.Columns[D].ColumnKey,Level-2)) do Dec(EndCol);
     Line:=Line+TextCell(StartCol,Level+1,S);
     if EndCol>D then
      begin
       Merges:=Merges+'<mergeCell ref="'+ColName(StartCol)+IntToStr(Level+1)+':'+
        ColName(RFs.Count+EndCol)+IntToStr(Level+1)+'"/>'; Inc(MergeCount);
      end;
     D:=EndCol+1;
    end;
   end else begin
    { Lowest band contains the actual measure/data fields. }
    for D:=0 to FLayoutEngine.Columns.Count-1 do begin
     S:='';
     if FLayoutEngine.Columns[D].DataField<>nil then begin
      S:=FLayoutEngine.Columns[D].DataField.Caption;
      if S='' then S:=FLayoutEngine.Columns[D].DataField.FieldName;
     end;
     Line:=Line+TextCell(RFs.Count+D,Level+1,S);
    end;
   end;
   Sheet:=Sheet+Line+'</row>';
  end;

  DataRow:=HeaderRows+1;
  for Row:=0 to FEngine.Model.RowKeys.Count-1 do begin
   Line:='<row r="'+IntToStr(DataRow)+'">'; ColIndex:=0;
   for I:=0 to RFs.Count-1 do begin
    Line:=Line+TextCell(ColIndex,DataRow,KeyPart(FEngine.Model.RowKeys[Row],I)); Inc(ColIndex);
   end;
   for D:=0 to FLayoutEngine.Columns.Count-1 do begin
    Cell:=FEngine.Model.FindCell(FEngine.Model.RowKeys[Row],FLayoutEngine.Columns[D].ColumnKey,FLayoutEngine.Columns[D].DataField.FieldName);
    if Cell<>nil then V:=Cell.Accumulator.Value(FLayoutEngine.Columns[D].DataField.SummaryType) else V:=Null;
    if VarIsNull(V) or VarIsEmpty(V) then
     Line:=Line+TextCell(ColIndex,DataRow,'')
    else if VarIsNumeric(V) then
     Line:=Line+NumberCell(ColIndex,DataRow,V)
    else
     Line:=Line+TextCell(ColIndex,DataRow,FormatCellValue(V,FLayoutEngine.Columns[D].DataField));
    Inc(ColIndex);
   end;
   Sheet:=Sheet+Line+'</row>'; Inc(DataRow);
  end;
  Sheet:=Sheet+'</sheetData>';
  if Merges<>'' then
   Sheet:=Sheet+'<mergeCells count="'+IntToStr(MergeCount)+'">'+Merges+'</mergeCells>';
  Sheet:=Sheet+'</worksheet>';
  AddZipText('xl/worksheets/sheet1.xml',Sheet);
 finally
  Zip.Free; CFs.Free; RFs.Free;
 end;
end;

procedure TLarGridPivot.Paint;
var Row,D,Lvl,X,Y,HeaderLevels,RowHeaderTotal:Integer;
 R,VisibleContent:TRect; S:string; DF:TLarPivotField; Cell:TLarPivotResultCell; V:Variant; Flags:Cardinal;
 DFs,RFs,CFs:TList<TLarPivotField>; VC:TLarPivotVisualColumn; VI:TLarPivotViewItem;
 procedure DrawCell(const ARect:TRect;const Txt:string;Al:TAlignment;Bold:Boolean=False;Total:Boolean=False;Selected:Boolean=False);
 var RR:TRect; begin RR:=ARect;
  if Total then begin Canvas.Brush.Color:=ThemeTotalColor; Canvas.Font.Color:=ThemeTotalTextColor; end
  else if Bold then begin Canvas.Brush.Color:=ThemeHeaderColor; Canvas.Font.Color:=ThemeHeaderTextColor; end
  else begin Canvas.Brush.Color:=ThemeCellColor; Canvas.Font.Color:=ThemeTextColor; end;
  if Selected then Canvas.Brush.Color:=RGB(225,240,255);
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
 Canvas.Brush.Color:=ThemeCellColor; Canvas.FillRect(Canvas.ClipRect); DrawFieldAreas;
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
  { The scrolling body starts below the frozen result header.  Clipping it at
    the field-area edge allowed rows to paint through the header before the
    header was repainted, producing the visible overlap while scrolling. }
  IntersectClipRect(Canvas.Handle,0,
    EffectiveFieldAreaHeight+HeaderLevels*FHeaderHeight,
    ClientWidth,ClientHeight);
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
    pvekFieldHeader:
     begin
      { Never use a Unicode glyph for sort direction: projects saved/compiled
        with a legacy source codepage rendered the glyph incorrectly. Draw the marker instead. }
      DrawCell(VI.Bounds,VI.Caption,taCenter,True);
      if (VI.Field<>nil) and (VI.Field.SortOrder<>psoNone) then begin
       R:=VI.Bounds;
       Canvas.Brush.Color:=ThemeHeaderTextColor;
       Canvas.Pen.Color:=ThemeHeaderTextColor;
       if VI.Field.SortOrder=psoAscending then
        Canvas.Polygon([Point(R.Right-14,R.Top+18),Point(R.Right-9,R.Top+11),Point(R.Right-4,R.Top+18)])
       else
        Canvas.Polygon([Point(R.Right-14,R.Top+11),Point(R.Right-9,R.Top+18),Point(R.Right-4,R.Top+11)]);
      end;
     end;
    pvekColumnValue:
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
      DrawCell(VI.Bounds,'',DefaultAlignment(VI.Field),VI.Level<RFs.Count-1,False,IsCellSelected(VI));
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
      DrawCell(VI.Bounds,S,DefaultAlignment(DF),False,False,IsCellSelected(VI));
     end;
    pvekTotalCell:
     begin
      if VI.Field=nil then
       DrawCell(VI.Bounds,VI.Caption,taLeftJustify,True,True,IsCellSelected(VI))
      else begin
       DF:=VI.Field;
       if VI.ColumnKey<>LAR_PIVOT_TOTAL_KEY then
        S:=TextFor(VI.RowKey,VI.ColumnKey,DF)
       else
        S:=TextFor(VI.RowKey,LAR_PIVOT_TOTAL_KEY,DF);
       DrawCell(VI.Bounds,S,DefaultAlignment(DF),True,True,IsCellSelected(VI));
      end;
     end;
    pvekGrandTotalCell:
     begin
      DF:=VI.Field;
      S:=TextFor(LAR_PIVOT_TOTAL_KEY,LAR_PIVOT_TOTAL_KEY,DF);
      DrawCell(VI.Bounds,S,DefaultAlignment(DF),True,True,IsCellSelected(VI));
     end;
   end;
  end;
  X:=RowHeaderTotal;
  for VC in FLayoutEngine.Columns do if VC.Left+VC.Width>X then X:=VC.Left+VC.Width;
  { Row-total headers are frozen and are painted in the frozen-header pass
    below. Painting them in the scrolling-body pass made them disappear when
    that pass was clipped or subsequently covered by the frozen header. }

  if RFs.Count=0 then
   for Row:=0 to FEngine.Model.RowKeys.Count-1 do begin
    Y:=EffectiveFieldAreaHeight+FVScrollPos+HeaderLevels*FHeaderHeight+Row*FRowHeight;
    DrawCell(Rect(0,Y,RowHeaderTotal,Y+FRowHeight),'',taLeftJustify);
   end;

  RestoreDC(Canvas.Handle,-1);

  { Frozen result header: body scrolls vertically, header is repainted at its
    fixed screen Y while retaining horizontal synchronization. }
  SaveDC(Canvas.Handle);
  IntersectClipRect(Canvas.Handle,0,EffectiveFieldAreaHeight,ClientWidth,
    EffectiveFieldAreaHeight+HeaderLevels*FHeaderHeight);
  SetViewportOrgEx(Canvas.Handle,-FHScrollPos,0,nil);
  { The upper-left corner above the row-field captions is intentionally
    empty. Keep the header height/geometry unchanged, but paint this band as
    plain background so it does not look like additional header cells. }
  if (RFs.Count>0) and (HeaderLevels>1) then begin
   R:=Rect(FHScrollPos,EffectiveFieldAreaHeight,
     FHScrollPos+RowHeaderTotal,
     EffectiveFieldAreaHeight+(HeaderLevels-1)*FHeaderHeight);
   Canvas.Brush.Color:=ThemeCellColor;
   Canvas.FillRect(R);
  end;
  for VI in FViewInfo.Items do
   if (VI.Kind in [pvekFieldHeader,pvekColumnValue]) and
      (VI.Bounds.Top<EffectiveFieldAreaHeight+HeaderLevels*FHeaderHeight) then
   begin
    case VI.Kind of
     pvekFieldHeader:
      begin
       DrawCell(VI.Bounds,VI.Caption,taCenter,True);
       if (VI.Field<>nil) and (VI.Field.SortOrder<>psoNone) then begin
        R:=VI.Bounds; Canvas.Brush.Color:=ThemeHeaderTextColor; Canvas.Pen.Color:=ThemeHeaderTextColor;
        if VI.Field.SortOrder=psoAscending then
         Canvas.Polygon([Point(R.Right-14,R.Top+18),Point(R.Right-9,R.Top+11),Point(R.Right-4,R.Top+18)])
        else
         Canvas.Polygon([Point(R.Right-14,R.Top+11),Point(R.Right-9,R.Top+18),Point(R.Right-4,R.Top+11)]);
       end;
      end;
     pvekColumnValue: DrawCell(VI.Bounds,VI.Caption,taCenter,True);
    end;
   end;
  { Paint the total-column header in the same frozen pass as the month/data
    headers. This keeps "Totales" / data captions visible after scrolling and
    after toggling totals. }
  if FShowRowTotals then begin
   X:=RowHeaderTotal;
   for VC in FLayoutEngine.Columns do
    if VC.Left+VC.Width>X then X:=VC.Left+VC.Width;
   if DFs.Count>0 then begin
    D:=0;
    for Lvl:=0 to DFs.Count-1 do Inc(D,DFs[Lvl].Width);
    if HeaderLevels>1 then
     DrawCell(Rect(X,EffectiveFieldAreaHeight,X+D,
       EffectiveFieldAreaHeight+(HeaderLevels-1)*FHeaderHeight),
       'Totales',taCenter,True);
   end;
   for D:=0 to DFs.Count-1 do begin
    if HeaderLevels>1 then
     R:=Rect(X,EffectiveFieldAreaHeight+(HeaderLevels-1)*FHeaderHeight,
       X+DFs[D].Width,EffectiveFieldAreaHeight+HeaderLevels*FHeaderHeight)
    else
     R:=Rect(X,EffectiveFieldAreaHeight,X+DFs[D].Width,
       EffectiveFieldAreaHeight+FHeaderHeight);
    DrawCell(R,DFs[D].Caption,taCenter,True);
    Inc(X,DFs[D].Width);
   end;
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
var RFs:TList<TLarPivotField>; Row,Lvl:Integer; ID:string; Seen:TDictionary<string,Byte>;
begin
 RFs:=AxisFields(paRow);
 Seen:=TDictionary<string,Byte>.Create;
 try
  FCollapsedGroups.BeginUpdate;
  try
   FCollapsedGroups.Clear;
   if RFs.Count>1 then
    for Row:=0 to FEngine.Model.RowKeys.Count-1 do
     for Lvl:=0 to RFs.Count-2 do begin
      ID:=GroupID(FEngine.Model.RowKeys[Row],Lvl);
      if not Seen.ContainsKey(ID) then begin
       Seen.Add(ID,0);
       FCollapsedGroups.Add(ID);
      end;
     end;
  finally
   FCollapsedGroups.EndUpdate;
  end;
 finally
  Seen.Free;
  RFs.Free;
 end;
 RefreshViewOnly;
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
 AddTotalsMenuItems(FHierarchyMenu);
 AddItem('-',nil);
 if FAllowCopyToClipboard and (FSelectedCells.Count>0) then
  AddItem('Copiar',GridCopyClick);
 AddItem('Vista previa de impresi'+#243+'n...',GridPrintPreviewClick);
 AddItem('Configurar impresi'+#243+'n...',GridPageSetupClick);
 AddItem('Imprimir...',GridPrintClick);
 AddItem('Exportar a Excel...',GridExportExcelClick);
 AddItem('Exportar a CSV...',GridExportCSVClick);
 P:=ClientToScreen(Point(X,Y)); FHierarchyMenu.Popup(P.X,P.Y);
end;

procedure TLarGridPivot.GridCopyClick(Sender:TObject);
begin
 CopySelectionToClipboard;
end;

procedure TLarGridPivot.GridPrintClick(Sender:TObject);
begin
 PrintPivotDialog;
end;

procedure TLarGridPivot.GridPrintPreviewClick(Sender:TObject);
begin
 PrintPreview;
end;

procedure TLarGridPivot.GridPageSetupClick(Sender:TObject);
begin ConfigurePrint; end;

procedure TLarGridPivot.ConfigurePrint;
var F:TForm; CPaper:TComboBox; ELeft,ERight,ETop,EBottom:TEdit; CFit:TCheckBox; BOK,BCancel:TButton; L:TLabel; I,Y:Integer; PCol:TLarPivotPrintColumn;
begin
 F:=TForm.CreateNew(Self);
 try
  F.Caption:='Configurar impresi'+#243+'n'; F.Position:=poScreenCenter; F.Width:=430; F.Height:=420; F.BorderStyle:=bsDialog;
  L:=TLabel.Create(F); L.Parent:=F; L.SetBounds(16,18,120,20); L.Caption:='Tama'+#241+'o de papel:';
  CPaper:=TComboBox.Create(F); CPaper.Parent:=F; CPaper.Style:=csDropDownList; CPaper.SetBounds(150,14,230,24); CPaper.Items.Add('Predeterminado'); CPaper.Items.Add('A4'); CPaper.Items.Add('Carta'); CPaper.Items.Add('A5'); CPaper.Items.Add('Legal'); CPaper.ItemIndex:=Ord(FPrintOptions.PaperSize);
  Y:=56;
  for I:=0 to 3 do begin L:=TLabel.Create(F); L.Parent:=F; L.Left:=16; L.Top:=Y+4; case I of 0:L.Caption:='Margen izquierdo (mm):'; 1:L.Caption:='Margen derecho (mm):'; 2:L.Caption:='Margen superior (mm):'; 3:L.Caption:='Margen inferior (mm):'; end; case I of 0:begin ELeft:=TEdit.Create(F); ELeft.Parent:=F; ELeft.Text:=IntToStr(FPrintOptions.MarginLeftMM); ELeft.SetBounds(200,Y,70,24); end; 1:begin ERight:=TEdit.Create(F); ERight.Parent:=F; ERight.Text:=IntToStr(FPrintOptions.MarginRightMM); ERight.SetBounds(200,Y,70,24); end; 2:begin ETop:=TEdit.Create(F); ETop.Parent:=F; ETop.Text:=IntToStr(FPrintOptions.MarginTopMM); ETop.SetBounds(200,Y,70,24); end; 3:begin EBottom:=TEdit.Create(F); EBottom.Parent:=F; EBottom.Text:=IntToStr(FPrintOptions.MarginBottomMM); EBottom.SetBounds(200,Y,70,24); end; end; Inc(Y,34); end;
  CFit:=TCheckBox.Create(F); CFit.Parent:=F; CFit.SetBounds(16,Y+4,280,24); CFit.Caption:='Ajustar columnas al ancho de p'+#225+'gina'; CFit.Checked:=FPrintOptions.FitToPageWidth; Inc(Y,38);
  L:=TLabel.Create(F); L.Parent:=F; L.SetBounds(16,Y,360,20); L.Caption:='Anchos de impresi'+#243+'n (0 = ancho del grid):'; Inc(Y,24);
  for I:=0 to FFields.Count-1 do if FFields[I].Area in [paRow,paData] then begin PCol:=FPrintOptions.Columns.Ensure(FFields[I].FieldName); L:=TLabel.Create(F); L.Parent:=F; L.SetBounds(20,Y+4,180,20); L.Caption:=FFields[I].Caption; with TEdit.Create(F) do begin Parent:=F; Name:='PrintWidth'+IntToStr(I); Tag:=I; Text:=IntToStr(PCol.Width); SetBounds(210,Y,70,24); end; Inc(Y,28); if Y>315 then Break; end;
  BOK:=TButton.Create(F); BOK.Parent:=F; BOK.Caption:='Aceptar'; BOK.ModalResult:=mrOk; BOK.Default:=True; BOK.SetBounds(210,345,80,28); BCancel:=TButton.Create(F); BCancel.Parent:=F; BCancel.Caption:='Cancelar'; BCancel.ModalResult:=mrCancel; BCancel.SetBounds(300,345,80,28);
  if F.ShowModal=mrOk then begin FPrintOptions.PaperSize:=TLarPivotPaperSize(CPaper.ItemIndex); FPrintOptions.MarginLeftMM:=StrToIntDef(ELeft.Text,12); FPrintOptions.MarginRightMM:=StrToIntDef(ERight.Text,12); FPrintOptions.MarginTopMM:=StrToIntDef(ETop.Text,12); FPrintOptions.MarginBottomMM:=StrToIntDef(EBottom.Text,12); FPrintOptions.FitToPageWidth:=CFit.Checked; for I:=0 to F.ComponentCount-1 do if (F.Components[I] is TEdit) and (F.Components[I].Tag>=0) and (Pos('PrintWidth',F.Components[I].Name)=1) then begin PCol:=FPrintOptions.Columns.Ensure(FFields[F.Components[I].Tag].FieldName); PCol.Width:=StrToIntDef(TEdit(F.Components[I]).Text,0); end; end;
 finally F.Free; end;
end;

procedure TLarGridPivot.GridExportExcelClick(Sender:TObject);
var D:TSaveDialog;
begin
 D:=TSaveDialog.Create(nil);
 try
  D.Title:='Exportar pivot a Excel';
  D.Filter:='Libro de Excel (*.xlsx)|*.xlsx';
  D.DefaultExt:='xlsx';
  D.FileName:='Pivot.xlsx';
  if D.Execute then ExportToExcel(D.FileName);
 finally D.Free; end;
end;

procedure TLarGridPivot.GridExportCSVClick(Sender:TObject);
var D:TSaveDialog;
begin
 D:=TSaveDialog.Create(nil);
 try
  D.Title:='Exportar pivot a CSV';
  D.Filter:='Archivo CSV (*.csv)|*.csv';
  D.DefaultExt:='csv';
  D.FileName:='Pivot.csv';
  if D.Execute then ExportToCSV(D.FileName);
 finally D.Free; end;
end;

procedure TLarGridPivot.GridToggleRowTotalsClick(Sender:TObject);
begin ShowRowTotals:=not ShowRowTotals; end;

procedure TLarGridPivot.GridToggleColumnTotalsClick(Sender:TObject);
begin ShowColumnTotals:=not ShowColumnTotals; end;

procedure TLarGridPivot.GridToggleGrandTotalClick(Sender:TObject);
begin ShowGrandTotal:=not ShowGrandTotal; end;

procedure TLarGridPivot.AddTotalsMenuItems(AMenu:TPopupMenu);
 procedure AddItem(const ACaption:string; AHandler:TNotifyEvent; AChecked:Boolean);
 var MI:TMenuItem;
 begin
  MI:=TMenuItem.Create(AMenu); MI.Caption:=ACaption; MI.OnClick:=AHandler;
  MI.AutoCheck:=False; MI.Checked:=AChecked; AMenu.Items.Add(MI);
 end;
var Sep:TMenuItem;
begin
 Sep:=TMenuItem.Create(AMenu); Sep.Caption:='-'; AMenu.Items.Add(Sep);
 AddItem('Mostrar totales en filas',GridToggleRowTotalsClick,FShowRowTotals);
 AddItem('Mostrar totales en columnas',GridToggleColumnTotalsClick,FShowColumnTotals);
 AddItem('Mostrar total general',GridToggleGrandTotalClick,FShowGrandTotal);
end;

procedure TLarGridPivot.ShowGridMenu(X,Y:Integer);
var M:TMenuItem; P:TPoint;
 procedure AddItem(const ACaption:string;AHandler:TNotifyEvent);
 begin M:=TMenuItem.Create(FGridMenu); M.Caption:=ACaption; M.OnClick:=AHandler; FGridMenu.Items.Add(M); end;
begin
 FGridMenu.Items.Clear;
 AddTotalsMenuItems(FGridMenu);
 AddItem('-',nil);
 if FAllowCopyToClipboard and (FSelectedCells.Count>0) then
  AddItem('Copiar',GridCopyClick);
 AddItem('Vista previa de impresi'+#243+'n...',GridPrintPreviewClick);
 AddItem('Configurar impresi'+#243+'n...',GridPageSetupClick);
 AddItem('Imprimir...',GridPrintClick);
 AddItem('Exportar a Excel...',GridExportExcelClick);
 AddItem('Exportar a CSV...',GridExportCSVClick);
 P:=ClientToScreen(Point(X,Y));
 FGridMenu.Popup(P.X,P.Y);
end;

procedure TLarGridPivot.MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
var HT:TLarPivotHitTest; VI:TLarPivotViewItem;
begin
 inherited;
 if FShowFieldPanel and (Y<EffectiveFieldAreaHeight) and (Button=mbRight) then begin
  ShowFieldMenu(X,Y,FieldAtPoint(X,Y)); Exit;
 end;
 if Y>=EffectiveFieldAreaHeight then begin
  BuildViewInfo;
  { Headers are frozen vertically, so their hit-test Y is screen-relative.
    Body rows use content-relative Y. }
  if Y<EffectiveFieldAreaHeight+(FViewInfo.HeaderLevels*FHeaderHeight) then
   HT:=FViewInfo.HitTest(X+FHScrollPos,Y)
  else
   HT:=FViewInfo.HitTest(X+FHScrollPos,Y+FVScrollPos);
  if Button=mbRight then begin
   { Export must always be reachable from the result area. Hierarchy actions
     remain available as additional entries when a grouped row was clicked. }
   if HT.Kind in [pvekExpandButton,pvekRowValue,pvekTotalCell] then begin
    if HT.Level<0 then HT.Level:=0;
    ShowHierarchyMenu(X,Y,HT); Exit;
   end;
   ShowGridMenu(X,Y); Exit;
  end;
  if (Button=mbLeft) and (HT.Kind=pvekExpandButton) and (HT.RowKey<>'') then begin
   { ViewInfo places an actionable +/- only on the group header. }
   ToggleGroup(HT.RowKey,HT.Level); Exit;
  end;
  if (Button=mbLeft) and FAllowCellSelection and
     (HT.Kind in [pvekRowValue,pvekDataCell,pvekTotalCell,pvekGrandTotalCell]) then begin
   SetFocus;
   VI:=SelectableItemAt(X,Y);
   if VI<>nil then begin
    FSelectionBase.Clear;
    if FAllowMultiSelect and (ssCtrl in Shift) then FSelectionBase.Assign(FSelectedCells);
    SelectCell(VI,FAllowMultiSelect and (ssCtrl in Shift));
    FSelectingCells:=FAllowMultiSelect;
    FSelectionStart:=Point(X,Y+FVScrollPos);
    FSelectionRect:=Rect(FSelectionStart.X,FSelectionStart.Y,FSelectionStart.X+1,FSelectionStart.Y+1);
    MouseCapture:=FSelectingCells;
   end;
   Exit;
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
var A:TLarPivotArea; N:Integer; Hot:TLarPivotField; R:TRect;
begin
 inherited;
 if FSelectingCells then begin
  FSelectionRect:=Rect(Min(FSelectionStart.X,X),Min(FSelectionStart.Y,Y+FVScrollPos),
    Max(FSelectionStart.X,X)+1,Max(FSelectionStart.Y,Y+FVScrollPos)+1);
  SelectCellsInRect(FSelectionRect,ssCtrl in Shift); Exit;
 end;
 Hot:=nil;
 if FShowFieldPanel and (Y>=0) and (Y<EffectiveFieldAreaHeight) then begin
  Hot:=FieldAtPoint(X,Y);
  if Hot<>FHotFilterField then begin
   { Hover affects only the old/new chip. Invalidating the whole pivot made
     the complete result area repaint whenever the mouse crossed a label. }
   if FieldChipRect(FHotFilterField,R) then InvalidateRect(Handle,@R,False);
   FHotFilterField:=Hot;
   if FieldChipRect(FHotFilterField,R) then InvalidateRect(Handle,@R,False);
  end;
 end else if FHotFilterField<>nil then begin
  if FieldChipRect(FHotFilterField,R) then InvalidateRect(Handle,@R,False);
  FHotFilterField:=nil;
 end;
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
   FDragTargetIndex:=DropIndexAtPoint(FDragTargetArea,X,Y);
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
 if FSelectingCells then begin FSelectingCells:=False; MouseCapture:=False; SelectCellsInRect(FSelectionRect,ssCtrl in Shift); Exit; end;
 if Assigned(FResizingField) then begin
  FResizingField:=nil; MouseCapture:=False; Cursor:=crDefault;
  RefreshViewOnly; Exit;
 end;
 F:=FDragField;
 try
  if Assigned(F) and FDraggingField and FShowFieldPanel and (Y>=0) and (Y<EffectiveFieldAreaHeight) then begin
   A:=AreaFromPoint(X,Y); N:=DropIndexAtPoint(A,X,Y);
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
