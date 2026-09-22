from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
# collapse adjacent duplicate declarations/properties created by the one-shot workflow being triggered twice
for block in [
'    FPrintTitle:string;\n    FPrintLandscape:Boolean;\n    FPrintShowPageNumbers:Boolean;\n',
'    procedure GridPrintClick(Sender:TObject);\n',
'    procedure PrintPivot;\n    function PrintPivotDialog:Boolean;\n',
'    property PrintTitle:string read FPrintTitle write FPrintTitle;\n    property PrintLandscape:Boolean read FPrintLandscape write FPrintLandscape default True;\n    property PrintShowPageNumbers:Boolean read FPrintShowPageNumbers write FPrintShowPageNumbers default True;\n']:
    s=s.replace(block+block,block)
# remove duplicated handler, keeping one
h='procedure TLarGridPivot.GridPrintClick(Sender:TObject);\nbegin\n PrintPivotDialog;\nend;\n\n'
while s.count(h)>1:
    pos=s.rfind(h); s=s[:pos]+s[pos+len(h):]
# remove duplicated full printing implementation, keeping the first block
start='function TLarGridPivot.PrintPivotDialog:Boolean;'
end='procedure TLarGridPivot.ExportToCSV(const AFileName:string);'
first=s.find(start); second=s.find(start,first+1)
if second>=0:
    e=s.find(end,second)
    if e<0: raise SystemExit('Export marker missing')
    s=s[:second]+s[e:]
p.write_text(s,encoding='utf-8')
