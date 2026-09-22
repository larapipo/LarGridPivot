from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
# declarations
s=s.replace('    procedure GridPrintClick(Sender:TObject);','    procedure GridPrintClick(Sender:TObject);\n    procedure GridPrintPreviewClick(Sender:TObject);',1)
s=s.replace('    procedure CopySelectionToClipboard;','    procedure CopySelectionToClipboard;\n    function PrintPageCount(AWidth,AHeight:Integer; ACanvas:TCanvas):Integer;\n    procedure RenderPrintPage(ACanvas:TCanvas; AWidth,AHeight,APageNo:Integer);',1)
s=s.replace('    procedure PrintPivot;\n    function PrintPivotDialog:Boolean;','    procedure PrintPivot;\n    function PrintPivotDialog:Boolean;\n    procedure PrintPreview;',1)
# preview form class after datalink class declaration
needle='type TLarPivotDataLink = class(TDataLink)\nprivate FOwner: TLarGridPivot;\nprotected procedure DataSetChanged; override; procedure ActiveChanged; override;\npublic constructor Create(AOwner: TLarGridPivot); end;'
insert=needle+r'''

type
  TLarPivotPrintPreviewForm = class(TForm)
  private
    FPivot: TLarGridPivot;
    FPage, FPageCount: Integer;
    FZoom: Double;
    FTopPanel: TPanel;
    FPaint: TPaintBox;
    FPrev, FNext, FPrint, FClose: TButton;
    FInfo: TLabel;
    FZoomBox: TComboBox;
    procedure PreviewPaint(Sender:TObject);
    procedure PrevClick(Sender:TObject);
    procedure NextClick(Sender:TObject);
    procedure PrintClick(Sender:TObject);
    procedure CloseClick(Sender:TObject);
    procedure ZoomChange(Sender:TObject);
    procedure UpdateState;
  public
    constructor CreatePreview(AOwner:TComponent; APivot:TLarGridPivot);
  end;
'''
assert needle in s
s=s.replace(needle,insert,1)
# form implementation before constructor grid
marker='constructor TLarGridPivot.Create(AOwner:TComponent);'
formimpl=r'''constructor TLarPivotPrintPreviewForm.CreatePreview(AOwner:TComponent; APivot:TLarGridPivot);
begin
 inherited CreateNew(AOwner);
 FPivot:=APivot; FPage:=1; FZoom:=0.75;
 Caption:='Vista previa de impresión'; Position:=poScreenCenter; Width:=1000; Height:=760;
 Color:=clBtnFace; DoubleBuffered:=True;
 FTopPanel:=TPanel.Create(Self); FTopPanel.Parent:=Self; FTopPanel.Align:=alTop; FTopPanel.Height:=44; FTopPanel.BevelOuter:=bvNone;
 FPrev:=TButton.Create(Self); FPrev.Parent:=FTopPanel; FPrev.SetBounds(8,8,80,28); FPrev.Caption:='< Anterior'; FPrev.OnClick:=PrevClick;
 FNext:=TButton.Create(Self); FNext.Parent:=FTopPanel; FNext.SetBounds(94,8,80,28); FNext.Caption:='Siguiente >'; FNext.OnClick:=NextClick;
 FInfo:=TLabel.Create(Self); FInfo.Parent:=FTopPanel; FInfo.SetBounds(188,14,130,20);
 FZoomBox:=TComboBox.Create(Self); FZoomBox.Parent:=FTopPanel; FZoomBox.Style:=csDropDownList; FZoomBox.SetBounds(330,9,90,24);
 FZoomBox.Items.Add('50%'); FZoomBox.Items.Add('75%'); FZoomBox.Items.Add('100%'); FZoomBox.Items.Add('125%'); FZoomBox.ItemIndex:=1; FZoomBox.OnChange:=ZoomChange;
 FPrint:=TButton.Create(Self); FPrint.Parent:=FTopPanel; FPrint.SetBounds(440,8,90,28); FPrint.Caption:='Imprimir...'; FPrint.OnClick:=PrintClick;
 FClose:=TButton.Create(Self); FClose.Parent:=FTopPanel; FClose.SetBounds(536,8,80,28); FClose.Caption:='Cerrar'; FClose.OnClick:=CloseClick;
 FPaint:=TPaintBox.Create(Self); FPaint.Parent:=Self; FPaint.Align:=alClient; FPaint.OnPaint:=PreviewPaint;
 FPageCount:=FPivot.PrintPageCount(1120,790,FPaint.Canvas); if FPageCount<1 then FPageCount:=1;
 UpdateState;
end;

procedure TLarPivotPrintPreviewForm.UpdateState;
begin
 FInfo.Caption:='Página '+IntToStr(FPage)+' de '+IntToStr(FPageCount);
 FPrev.Enabled:=FPage>1; FNext.Enabled:=FPage<FPageCount; FPaint.Invalidate;
end;
procedure TLarPivotPrintPreviewForm.PrevClick(Sender:TObject); begin if FPage>1 then begin Dec(FPage); UpdateState; end; end;
procedure TLarPivotPrintPreviewForm.NextClick(Sender:TObject); begin if FPage<FPageCount then begin Inc(FPage); UpdateState; end; end;
procedure TLarPivotPrintPreviewForm.PrintClick(Sender:TObject); begin FPivot.PrintPivotDialog; end;
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

'''
assert marker in s
s=s.replace(marker,formimpl+marker,1)
# handler and menu
needle2='procedure TLarGridPivot.GridPrintClick(Sender:TObject);\nbegin\n PrintPivotDialog;\nend;'
s=s.replace(needle2,needle2+'\n\nprocedure TLarGridPivot.GridPrintPreviewClick(Sender:TObject);\nbegin\n PrintPreview;\nend;',1)
s=s.replace("AddItem('Imprimir...',GridPrintClick);","AddItem('Vista previa de impresión...',GridPrintPreviewClick);\n AddItem('Imprimir...',GridPrintClick);")
# replace print methods block
start=s.index('function TLarGridPivot.PrintPivotDialog:Boolean;')
end=s.index('procedure TLarGridPivot.ExportToCSV',start)
new=r'''function TLarGridPivot.PrintPivotDialog:Boolean;
var D:TPrintDialog;
begin
 D:=TPrintDialog.Create(Self);
 try
  D.Options:=[poWarning]; Result:=D.Execute;
  if Result then PrintPivot;
 finally D.Free; end;
end;

procedure TLarGridPivot.PrintPreview;
var F:TLarPivotPrintPreviewForm;
begin
 if (FEngine=nil) or (FEngine.Model=nil) then Exit;
 BuildViewInfo;
 F:=TLarPivotPrintPreviewForm.CreatePreview(Self,Self);
 try F.ShowModal; finally F.Free; end;
end;

function TLarGridPivot.PrintPageCount(AWidth,AHeight:Integer; ACanvas:TCanvas):Integer;
var LineH,HeaderH,TopM,BottomM,RowsPerPage:Integer;
begin
 ACanvas.Font.Assign(Font); ACanvas.Font.Size:=8;
 TopM:=Round(AHeight*0.04); BottomM:=AHeight-TopM;
 LineH:=Max(ACanvas.TextHeight('Ag')+8,28); HeaderH:=LineH+4;
 RowsPerPage:=Max(1,(BottomM-(TopM+LineH+4+HeaderH)) div LineH);
 if (FEngine=nil) or (FEngine.Model=nil) or (FEngine.Model.RowKeys.Count=0) then Exit(1);
 Result:=(FEngine.Model.RowKeys.Count+RowsPerPage-1) div RowsPerPage;
end;

procedure TLarGridPivot.RenderPrintPage(ACanvas:TCanvas; AWidth,AHeight,APageNo:Integer);
var RFs:TList<TLarPivotField>; Row,D,I,Y,LeftM,TopM,RightM,BottomM,HeaderH,LineH,
 AvailW,TotalW,X,W,RowsPerPage,FirstRow,LastRow:Integer; Scale:Double; S,Cap:string;
 Cell:TLarPivotResultCell; V:Variant; R:TRect;
 procedure TextCell(const AText:string; const AR:TRect; AAlign:TAlignment; ABold:Boolean=False);
 var Flags:Cardinal; RR:TRect;
 begin
  RR:=AR; ACanvas.Brush.Style:=bsClear;
  if ABold then ACanvas.Font.Style:=[fsBold] else ACanvas.Font.Style:=[];
  Flags:=DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
  case AAlign of taRightJustify:Flags:=Flags or DT_RIGHT; taCenter:Flags:=Flags or DT_CENTER; else Flags:=Flags or DT_LEFT; end;
  InflateRect(RR,-4,0); DrawText(ACanvas.Handle,PChar(AText),Length(AText),RR,Flags);
 end;
 procedure Box(const AR:TRect); begin ACanvas.Brush.Style:=bsClear; ACanvas.Pen.Color:=clSilver; ACanvas.Rectangle(AR); end;
begin
 if (FEngine=nil) or (FEngine.Model=nil) then Exit;
 BuildViewInfo; RFs:=AxisFields(paRow);
 try
  ACanvas.Brush.Color:=clWhite; ACanvas.FillRect(Rect(0,0,AWidth,AHeight)); ACanvas.Font.Assign(Font);
  LeftM:=Round(AWidth*0.04); RightM:=AWidth-LeftM; TopM:=Round(AHeight*0.04); BottomM:=AHeight-TopM;
  ACanvas.Font.Size:=8; LineH:=Max(ACanvas.TextHeight('Ag')+8,28); HeaderH:=LineH+4;
  Y:=TopM; ACanvas.Font.Size:=11; ACanvas.Font.Style:=[fsBold]; if FPrintTitle<>'' then S:=FPrintTitle else S:='Pivot'; ACanvas.TextOut(LeftM,Y,S);
  if FPrintShowPageNumbers then begin S:='Página '+IntToStr(APageNo)+' de '+IntToStr(PrintPageCount(AWidth,AHeight,ACanvas)); ACanvas.TextOut(RightM-ACanvas.TextWidth(S),Y,S); end;
  Inc(Y,LineH+4); ACanvas.Font.Size:=8;
  TotalW:=0; for I:=0 to RFs.Count-1 do Inc(TotalW,RFs[I].Width); for D:=0 to FLayoutEngine.Columns.Count-1 do Inc(TotalW,FLayoutEngine.Columns[D].Width);
  AvailW:=RightM-LeftM; if TotalW>0 then Scale:=Min(1.0,AvailW/TotalW) else Scale:=1.0;
  X:=LeftM;
  for I:=0 to RFs.Count-1 do begin W:=Round(RFs[I].Width*Scale); R:=Rect(X,Y,X+W,Y+HeaderH); Box(R); Cap:=RFs[I].Caption; if Cap='' then Cap:=RFs[I].FieldName; TextCell(Cap,R,taLeftJustify,True); Inc(X,W); end;
  for D:=0 to FLayoutEngine.Columns.Count-1 do begin W:=Round(FLayoutEngine.Columns[D].Width*Scale); R:=Rect(X,Y,X+W,Y+HeaderH); Box(R); Cap:=FLayoutEngine.Columns[D].ColumnKey; if FLayoutEngine.Columns[D].DataField<>nil then begin if Cap<>'' then Cap:=Cap+' '; Cap:=Cap+FLayoutEngine.Columns[D].DataField.Caption; end; TextCell(Cap,R,taCenter,True); Inc(X,W); end;
  Inc(Y,HeaderH); RowsPerPage:=Max(1,(BottomM-Y) div LineH); FirstRow:=(APageNo-1)*RowsPerPage; LastRow:=Min(FEngine.Model.RowKeys.Count-1,FirstRow+RowsPerPage-1);
  for Row:=FirstRow to LastRow do begin
   X:=LeftM;
   for I:=0 to RFs.Count-1 do begin W:=Round(RFs[I].Width*Scale); R:=Rect(X,Y,X+W,Y+LineH); Box(R); TextCell(KeyPart(FEngine.Model.RowKeys[Row],I),R,taLeftJustify); Inc(X,W); end;
   for D:=0 to FLayoutEngine.Columns.Count-1 do begin W:=Round(FLayoutEngine.Columns[D].Width*Scale); R:=Rect(X,Y,X+W,Y+LineH); Box(R); Cell:=FEngine.Model.FindCell(FEngine.Model.RowKeys[Row],FLayoutEngine.Columns[D].ColumnKey,FLayoutEngine.Columns[D].DataField.FieldName); if Cell<>nil then V:=Cell.Accumulator.Value(FLayoutEngine.Columns[D].DataField.SummaryType) else V:=Null; S:=FormatCellValue(V,FLayoutEngine.Columns[D].DataField); TextCell(S,R,taRightJustify); Inc(X,W); end;
   Inc(Y,LineH);
  end;
 finally RFs.Free; end;
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

'''
s=s[:start]+new+s[end:]
p.write_text(s,encoding='utf-8')
