from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
for line in ['    FPrintOptions:TLarPivotPrintOptions;','    procedure SetPrintColumnWidth(const AFieldName:string; AWidth:Integer);','    property PrintOptions:TLarPivotPrintOptions read FPrintOptions;']:
    while (line+'\n'+line) in s: s=s.replace(line+'\n'+line,line)
while 'FPrintOptions.Free; FPrintOptions.Free;' in s: s=s.replace('FPrintOptions.Free; FPrintOptions.Free;','FPrintOptions.Free;')
impl='procedure TLarGridPivot.SetPrintColumnWidth(const AFieldName:string; AWidth:Integer);\nbegin FPrintOptions.Columns.Ensure(AFieldName).Width:=Max(0,AWidth); end;'
while (impl+'\n\n'+impl) in s: s=s.replace(impl+'\n\n'+impl,impl)
s=s.replace('LeftM:=Round(AWidth*0.04); RightM:=AWidth-LeftM;', 'LeftM:=Round(AWidth*(FPrintOptions.MarginLeftMM/210.0)); RightM:=AWidth-Round(AWidth*(FPrintOptions.MarginRightMM/210.0));')
p.write_text(s,encoding='utf-8')
# trigger
