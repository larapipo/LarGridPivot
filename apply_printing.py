from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
s=s.replace('Vcl.Themes, Vcl.Clipbrd, Winapi.Messages, Data.DB,','Vcl.Themes, Vcl.Clipbrd, Vcl.Printers, Winapi.Messages, Data.DB,',1)
s=s.replace('    FSelectionRect:TRect;','    FSelectionRect:TRect;\n    FPrintTitle:string;\n    FPrintLandscape:Boolean;\n    FPrintShowPageNumbers:Boolean;',1)
s=s.replace('    procedure GridCopyClick(Sender:TObject);','    procedure GridCopyClick(Sender:TObject);\n    procedure GridPrintClick(Sender:TObject);',1)
s=s.replace('    procedure CopyToClipboard;','    procedure CopyToClipboard;\n    procedure PrintPivot;\n    function PrintPivotDialog:Boolean;',1)
s=s.replace('    property AllowCopyToClipboard:Boolean read FAllowCopyToClipboard write FAllowCopyToClipboard default True;','    property AllowCopyToClipboard:Boolean read FAllowCopyToClipboard write FAllowCopyToClipboard default True;\n    property PrintTitle:string read FPrintTitle write FPrintTitle;\n    property PrintLandscape:Boolean read FPrintLandscape write FPrintLandscape default True;\n    property PrintShowPageNumbers:Boolean read FPrintShowPageNumbers write FPrintShowPageNumbers default True;',1)
s=s.replace(" FAllowCellSelection:=True; FAllowMultiSelect:=True; FAllowCopyToClipboard:=True; TabStop:=True;"," FAllowCellSelection:=True; FAllowMultiSelect:=True; FAllowCopyToClipboard:=True; FPrintTitle:=''; FPrintLandscape:=True; FPrintShowPageNumbers:=True; TabStop:=True;",1)
# handler
needle='procedure TLarGridPivot.GridCopyClick(Sender:TObject);\nbegin\n CopySelectionToClipboard;\nend;'
repl=needle+'\n\nprocedure TLarGridPivot.GridPrintClick(Sender:TObject);\nbegin\n PrintPivotDialog;\nend;'
assert needle in s
s=s.replace(needle,repl,1)
# add menu item after copy in both menu builders
s=s.replace("AddItem('Copiar',GridCopyClick);\n AddItem('Exportar a Excel...',GridExportExcelClick);","AddItem('Copiar',GridCopyClick);\n AddItem('Imprimir...',GridPrintClick);\n AddItem('Exportar a Excel...',GridExportExcelClick);")
# insert implementation before ExportToCSV
marker='procedure TLarGridPivot.ExportToCSV(const AFileName:string);'
assert marker in s
impl=r'''function TLarGridPivot.PrintPivotDialog:Boolean;
var D:TPrintDialog;
begin
 D:=TPrintDialog.Create(Self);
 try
  D.Options:=[poPageNums,poWarning];
  D.MinPage:=1; D.MaxPage:=9999; D.FromPage:=1; D.ToPage:=9999;
  Result:=D.Execute;
  if Result then PrintPivot;
 finally D.Free; end;
end;

procedure TLarGridPivot.PrintPivot;
var
 RFs,DFs:TList<TLarPivotField>; Row,D,I,PageNo,Y,LeftM,TopM,RightM,BottomM,
 HeaderH,LineH,AvailW,TotalW,X,W:Integer; Scale:Double; S:string;
 Cell:TLarPivotResultCell; V:Variant; R:TRect;
 procedure TextCell(const AText:string; const AR:TRect; AAlign:TAlignment; ABold:Boolean=False);
 var Flags:Cardinal; RR:TRect;
 begin
  RR:=AR; Printer.Canvas.Brush.Style:=bsClear;
  if ABold then Printer.Canvas.Font.Style:=[fsBold] else Printer.Canvas.Font.Style:=[];
  Flags:=DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
  case AAlign of taRightJustify:Flags:=Flags or DT_RIGHT; taCenter:Flags:=Flags or DT_CENTER; else Flags:=Flags or DT_LEFT; end;
  InflateRect(RR,-4,0); DrawText(Printer.Canvas.Handle,PChar(AText),Length(AText),RR,Flags);
 end;
 procedure Box(const AR:TRect);
 begin Printer.Canvas.Brush.Style:=bsClear; Printer.Canvas.Pen.Color:=clSilver; Printer.Canvas.Rectangle(AR); end;
 procedure PageHeader;
 var J,XX,WW:Integer; Cap:string;
 begin
  Y:=TopM;
  Printer.Canvas.Font.Assign(Font); Printer.Canvas.Font.Size:=11; Printer.Canvas.Font.Style:=[fsBold];
  if FPrintTitle<>'' then S:=FPrintTitle else S:='Pivot';
  Printer.Canvas.TextOut(LeftM,Y,S); Inc(Y,LineH+4);
  Printer.Canvas.Font.Size:=8; Printer.Canvas.Font.Style:=[];
  if FPrintShowPageNumbers then begin
   S:='Pagina '+IntToStr(PageNo); Printer.Canvas.TextOut(RightM-Printer.Canvas.TextWidth(S),TopM,S);
  end;
  XX:=LeftM;
  for J:=0 to RFs.Count-1 do begin
   WW:=Round(RFs[J].Width*Scale); R:=Rect(XX,Y,XX+WW,Y+HeaderH); Box(R); Cap:=RFs[J].Caption; if Cap='' then Cap:=RFs[J].FieldName; TextCell(Cap,R,taLeftJustify,True); Inc(XX,WW);
  end;
  for J:=0 to FLayoutEngine.Columns.Count-1 do begin
   WW:=Round(FLayoutEngine.Columns[J].Width*Scale); R:=Rect(XX,Y,XX+WW,Y+HeaderH); Box(R);
   Cap:=FLayoutEngine.Columns[J].ColumnKey; if FLayoutEngine.Columns[J].DataField<>nil then begin if Cap<>'' then Cap:=Cap+' '; Cap:=Cap+FLayoutEngine.Columns[J].DataField.Caption; end;
   TextCell(Cap,R,taCenter,True); Inc(XX,WW);
  end;
  Inc(Y,HeaderH);
 end;
begin
 if (FEngine=nil) or (FEngine.Model=nil) then Exit;
 BuildViewInfo;
 RFs:=AxisFields(paRow); DFs:=DataFields;
 try
  if FPrintLandscape then Printer.Orientation:=poLandscape else Printer.Orientation:=poPortrait;
  Printer.Title:=FPrintTitle;
  Printer.BeginDoc;
  try
   LeftM:=Round(Printer.PageWidth*0.04); RightM:=Printer.PageWidth-LeftM;
   TopM:=Round(Printer.PageHeight*0.04); BottomM:=Printer.PageHeight-TopM;
   LineH:=Max(Printer.Canvas.TextHeight('Ag')+8,28); HeaderH:=LineH+4;
   TotalW:=0; for I:=0 to RFs.Count-1 do Inc(TotalW,RFs[I].Width);
   for D:=0 to FLayoutEngine.Columns.Count-1 do Inc(TotalW,FLayoutEngine.Columns[D].Width);
   AvailW:=RightM-LeftM; if TotalW>0 then Scale:=Min(1.0,AvailW/TotalW) else Scale:=1.0;
   PageNo:=1; PageHeader;
   for Row:=0 to FEngine.Model.RowKeys.Count-1 do begin
    if Y+LineH>BottomM then begin Printer.NewPage; Inc(PageNo); PageHeader; end;
    X:=LeftM;
    for I:=0 to RFs.Count-1 do begin
     W:=Round(RFs[I].Width*Scale); R:=Rect(X,Y,X+W,Y+LineH); Box(R); TextCell(KeyPart(FEngine.Model.RowKeys[Row],I),R,taLeftJustify); Inc(X,W);
    end;
    for D:=0 to FLayoutEngine.Columns.Count-1 do begin
     W:=Round(FLayoutEngine.Columns[D].Width*Scale); R:=Rect(X,Y,X+W,Y+LineH); Box(R);
     Cell:=FEngine.Model.FindCell(FEngine.Model.RowKeys[Row],FLayoutEngine.Columns[D].ColumnKey,FLayoutEngine.Columns[D].DataField.FieldName);
     if Cell<>nil then V:=Cell.Accumulator.Value(FLayoutEngine.Columns[D].DataField.SummaryType) else V:=Null;
     S:=FormatCellValue(V,FLayoutEngine.Columns[D].DataField); TextCell(S,R,taRightJustify); Inc(X,W);
    end;
    Inc(Y,LineH);
   end;
  finally Printer.EndDoc; end;
 finally DFs.Free; RFs.Free; end;
end;

'''
s=s.replace(marker,impl+marker,1)
p.write_text(s,encoding='utf-8')
