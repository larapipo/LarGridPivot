unit LarGridPivot.Grid;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Data.DB,
  LarGridPivot.Types, LarGridPivot.Fields, LarGridPivot.DataProvider,
  LarGridPivot.Model, LarGridPivot.Engine;

type
  TLarGridPivot = class(TCustomControl)
  private
    FDataSource: TDataSource; FDataLink: TDataLink; FFields: TLarPivotFields;
    FEngine: TLarPivotEngine; FHeaderHeight, FRowHeight, FRowHeaderWidth: Integer;
    FUpdating: Integer; FRebuilding: Boolean;
    FShowRowTotals, FShowColumnTotals, FShowGrandTotal: Boolean;
    procedure SetDataSource(const Value: TDataSource); procedure SetFields(const Value: TLarPivotFields);
    procedure DataChanged(Sender: TObject); procedure BuildFieldsFromDataSet;
    function DataFields: TList<TLarPivotField>;
    function DefaultAlignment(AField: TLarPivotField): TAlignment;
    function FormatCellValue(const V: Variant; AField: TLarPivotField): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; override; procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override; destructor Destroy; override;
    procedure BeginUpdate; procedure EndUpdate; procedure RefreshFields; procedure Rebuild;
    function FieldByName(const AFieldName: string): TLarPivotField;
    property Engine: TLarPivotEngine read FEngine;
  published
    property Align; property Anchors; property Color default clWhite; property Font; property ParentFont;
    property ParentColor; property PopupMenu; property ShowHint; property Visible;
    property DataSource: TDataSource read FDataSource write SetDataSource;
    property Fields: TLarPivotFields read FFields write SetFields;
    property HeaderHeight: Integer read FHeaderHeight write FHeaderHeight default 32;
    property RowHeight: Integer read FRowHeight write FRowHeight default 28;
    property RowHeaderWidth: Integer read FRowHeaderWidth write FRowHeaderWidth default 180;
    property ShowRowTotals: Boolean read FShowRowTotals write FShowRowTotals default True;
    property ShowColumnTotals: Boolean read FShowColumnTotals write FShowColumnTotals default True;
    property ShowGrandTotal: Boolean read FShowGrandTotal write FShowGrandTotal default True;
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
 FShowRowTotals:=True; FShowColumnTotals:=True; FShowGrandTotal:=True; FFields:=TLarPivotFields.Create(Self);
 FEngine:=TLarPivotEngine.Create(FFields); FDataLink:=TLarPivotDataLink.Create(Self); ControlStyle:=ControlStyle+[csOpaque]; end;
destructor TLarGridPivot.Destroy; begin FDataLink.Free; FEngine.Free; FFields.Free; inherited; end;
procedure TLarGridPivot.BeginUpdate; begin Inc(FUpdating); end;
procedure TLarGridPivot.EndUpdate; begin if FUpdating>0 then Dec(FUpdating); if FUpdating=0 then Rebuild; end;
procedure TLarGridPivot.SetDataSource(const Value:TDataSource); begin if FDataSource=Value then Exit; FDataSource:=Value; FDataLink.DataSource:=Value; if Assigned(Value) then Value.FreeNotification(Self); RefreshFields; end;
procedure TLarGridPivot.SetFields(const Value:TLarPivotFields); begin FFields.Assign(Value); Rebuild; end;
procedure TLarGridPivot.Notification(AComponent:TComponent;Operation:TOperation); begin inherited; if (Operation=opRemove) and (AComponent=FDataSource) then DataSource:=nil; end;
procedure TLarGridPivot.DataChanged(Sender:TObject); begin if (FUpdating=0) and not FRebuilding then Rebuild; end;

procedure TLarGridPivot.BuildFieldsFromDataSet;
var DS:TDataSet; I:Integer; PF:TLarPivotField; DF:TField;
begin if (FDataSource=nil) or (FDataSource.DataSet=nil) then Exit; DS:=FDataSource.DataSet; if not DS.Active then Exit;
 FFields.BeginUpdate; try FFields.Clear; for I:=0 to DS.FieldCount-1 do begin DF:=DS.Fields[I]; PF:=FFields.Add; PF.FieldName:=DF.FieldName; PF.Caption:=DF.DisplayLabel; PF.Width:=100;
 case DF.DataType of ftSmallint,ftInteger,ftWord,ftLargeint,ftAutoInc,ftFloat,ftCurrency,ftBCD,ftFMTBcd,ftSingle,ftExtended:PF.Alignment:=pvaRight;
 ftDate,ftTime,ftDateTime,ftTimeStamp,ftTimeStampOffset:PF.Alignment:=pvaCenter; else PF.Alignment:=pvaLeft; end; end; finally FFields.EndUpdate; end; end;
procedure TLarGridPivot.RefreshFields; begin if FRebuilding then Exit; FRebuilding:=True; try BuildFieldsFromDataSet; Invalidate; finally FRebuilding:=False; end; end;
procedure TLarGridPivot.Rebuild;
var P:ILarPivotDataProvider;
begin if (FUpdating>0) or FRebuilding then Exit; FRebuilding:=True; try if (FDataSource=nil) or (FDataSource.DataSet=nil) or not FDataSource.DataSet.Active then begin FEngine.Model.Clear; Invalidate; Exit; end;
 if FFields.Count=0 then BuildFieldsFromDataSet; P:=TLarDataSetPivotProvider.Create(FDataSource.DataSet); try FEngine.Build(P); finally P:=nil; end; Invalidate; finally FRebuilding:=False; end; end;
function TLarGridPivot.FieldByName(const AFieldName:string):TLarPivotField; begin Result:=FFields.FindField(AFieldName); if Result=nil then raise EDatabaseError.CreateFmt('Campo Pivot no encontrado: %s',[AFieldName]); end;
function TLarGridPivot.DataFields:TList<TLarPivotField>;
var I,J:Integer; T:TLarPivotField;
begin Result:=TList<TLarPivotField>.Create; for I:=0 to FFields.Count-1 do if FFields[I].Visible and (FFields[I].Area=paData) then Result.Add(FFields[I]);
 for I:=0 to Result.Count-2 do for J:=I+1 to Result.Count-1 do if Result[I].AreaIndex>Result[J].AreaIndex then begin T:=Result[I];Result[I]:=Result[J];Result[J]:=T;end; end;
function TLarGridPivot.DefaultAlignment(AField:TLarPivotField):TAlignment; begin case AField.Alignment of pvaLeft:Result:=taLeftJustify;pvaCenter:Result:=taCenter;pvaRight:Result:=taRightJustify;else Result:=taLeftJustify;end; end;
function TLarGridPivot.FormatCellValue(const V:Variant;AField:TLarPivotField):string; begin if VarIsNull(V) or VarIsEmpty(V) then Exit(''); if (AField.DisplayFormat<>'') and VarIsNumeric(V) then Result:=FormatFloat(AField.DisplayFormat,V) else Result:=VarToStr(V); end;

procedure TLarGridPivot.Paint;
var R:TRect; Row,Col,D,BaseCols,VisibleCols,CellW,X,Y:Integer; RowKey,ColKey,S:string; DF:TLarPivotField; Cell:TLarPivotResultCell; V:Variant; Flags:Cardinal; DFs:TList<TLarPivotField>;
 procedure DrawCell(const ARect:TRect;const Txt:string;Al:TAlignment;Bold:Boolean=False;Total:Boolean=False);
 var RR:TRect; begin RR:=ARect; if Total then Canvas.Brush.Color:=$00F3F3F3 else Canvas.Brush.Color:=Color; Canvas.FillRect(RR); Canvas.Pen.Color:=$00E0E0E0; Canvas.Rectangle(RR); InflateRect(RR,-6,-2); Canvas.Font.Assign(Font); if Bold then Canvas.Font.Style:=Canvas.Font.Style+[fsBold]; Flags:=DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS; case Al of taRightJustify:Flags:=Flags or DT_RIGHT;taCenter:Flags:=Flags or DT_CENTER;else Flags:=Flags or DT_LEFT;end; DrawText(Canvas.Handle,PChar(Txt),Length(Txt),RR,Flags); end;
 function TextFor(const AR,AC:string;F:TLarPivotField):string; begin Cell:=FEngine.Model.FindCell(AR,AC,F.FieldName); if Cell<>nil then V:=Cell.Accumulator.Value(F.SummaryType) else V:=Null; Result:=FormatCellValue(V,F); end;
 function HeaderFor(const C:string;F:TLarPivotField):string; begin if DFs.Count=1 then Result:=C else Result:=C+' - '+F.Caption; end;
begin Canvas.Brush.Color:=Color; Canvas.FillRect(ClientRect); DFs:=DataFields; try if (DFs.Count=0) or (FEngine.Model.ColumnKeys.Count=0) then begin Canvas.Font.Assign(Font);Canvas.Font.Color:=clGrayText;R:=ClientRect;InflateRect(R,-12,-12);DrawText(Canvas.Handle,'Configure campos Row, Column y Data y ejecute Rebuild.',-1,R,DT_LEFT or DT_TOP or DT_WORDBREAK);Exit;end;
 BaseCols:=FEngine.Model.ColumnKeys.Count*DFs.Count; VisibleCols:=BaseCols; if FShowRowTotals then Inc(VisibleCols,DFs.Count); CellW:=110; if VisibleCols>0 then CellW:=(ClientWidth-FRowHeaderWidth) div VisibleCols; if CellW<70 then CellW:=70;
 DrawCell(Rect(0,0,FRowHeaderWidth,FHeaderHeight),'',taLeftJustify,True); X:=FRowHeaderWidth;
 for Col:=0 to FEngine.Model.ColumnKeys.Count-1 do begin ColKey:=FEngine.Model.ColumnKeys[Col]; for D:=0 to DFs.Count-1 do begin DF:=DFs[D];DrawCell(Rect(X,0,X+CellW,FHeaderHeight),HeaderFor(ColKey,DF),taCenter,True);Inc(X,CellW);end;end;
 if FShowRowTotals then for D:=0 to DFs.Count-1 do begin DF:=DFs[D]; if DFs.Count=1 then S:='TOTAL' else S:='TOTAL - '+DF.Caption; DrawCell(Rect(X,0,X+CellW,FHeaderHeight),S,taCenter,True,True);Inc(X,CellW);end;
 for Row:=0 to FEngine.Model.RowKeys.Count-1 do begin RowKey:=FEngine.Model.RowKeys[Row];Y:=FHeaderHeight+Row*FRowHeight;DrawCell(Rect(0,Y,FRowHeaderWidth,Y+FRowHeight),RowKey,taLeftJustify);X:=FRowHeaderWidth;
  for Col:=0 to FEngine.Model.ColumnKeys.Count-1 do begin ColKey:=FEngine.Model.ColumnKeys[Col];for D:=0 to DFs.Count-1 do begin DF:=DFs[D];S:=TextFor(RowKey,ColKey,DF);DrawCell(Rect(X,Y,X+CellW,Y+FRowHeight),S,DefaultAlignment(DF));Inc(X,CellW);end;end;
  if FShowRowTotals then for D:=0 to DFs.Count-1 do begin DF:=DFs[D];S:=TextFor(RowKey,LAR_PIVOT_TOTAL_KEY,DF);DrawCell(Rect(X,Y,X+CellW,Y+FRowHeight),S,DefaultAlignment(DF),True,True);Inc(X,CellW);end; end;
 if FShowColumnTotals then begin Row:=FEngine.Model.RowKeys.Count;Y:=FHeaderHeight+Row*FRowHeight;DrawCell(Rect(0,Y,FRowHeaderWidth,Y+FRowHeight),'TOTAL',taLeftJustify,True,True);X:=FRowHeaderWidth;
  for Col:=0 to FEngine.Model.ColumnKeys.Count-1 do begin ColKey:=FEngine.Model.ColumnKeys[Col];for D:=0 to DFs.Count-1 do begin DF:=DFs[D];S:=TextFor(LAR_PIVOT_TOTAL_KEY,ColKey,DF);DrawCell(Rect(X,Y,X+CellW,Y+FRowHeight),S,DefaultAlignment(DF),True,True);Inc(X,CellW);end;end;
  if FShowRowTotals then for D:=0 to DFs.Count-1 do begin DF:=DFs[D]; if FShowGrandTotal then S:=TextFor(LAR_PIVOT_TOTAL_KEY,LAR_PIVOT_TOTAL_KEY,DF) else S:='';DrawCell(Rect(X,Y,X+CellW,Y+FRowHeight),S,DefaultAlignment(DF),True,True);Inc(X,CellW);end; end;
 finally DFs.Free; end; end;
procedure TLarGridPivot.Resize; begin inherited;Invalidate;end;
end.
