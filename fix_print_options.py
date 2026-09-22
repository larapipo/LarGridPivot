from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
s=s.replace('    procedure ConfigurePrint;\n  published','    procedure ConfigurePrint;\n    procedure SetPrintColumnWidth(const AFieldName:string; AWidth:Integer);\n  published')
# Make horizontal margins configurable too (first script only replaced top/bottom in one expression).
s=s.replace('LeftM:=Round(AWidth*0.04); RightM:=AWidth-LeftM;', 'LeftM:=Round(AWidth*(FPrintOptions.MarginLeftMM/210.0)); RightM:=AWidth-Round(AWidth*(FPrintOptions.MarginRightMM/210.0));')
p.write_text(s,encoding='utf-8')
