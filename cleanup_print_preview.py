from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
# Adjacent duplicated declarations from two workflow runs.
for block in [
'    function PrintPageCount(AWidth,AHeight:Integer; ACanvas:TCanvas):Integer;\n    procedure RenderPrintPage(ACanvas:TCanvas; AWidth,AHeight,APageNo:Integer);\n',
'    procedure GridPrintPreviewClick(Sender:TObject);\n',
'    procedure PrintPreview;\n']:
    while block+block in s: s=s.replace(block+block,block)
# Keep only one preview-form class declaration.
tag='type\n  TLarPivotPrintPreviewForm = class(TForm)'
a=s.find(tag); b=s.find(tag,a+1) if a>=0 else -1
if b>=0: s=s[:a]+s[b:]
# Keep only one complete preview-form implementation block before grid constructor.
tag2='constructor TLarPivotPrintPreviewForm.CreatePreview'
a=s.find(tag2); b=s.find(tag2,a+1) if a>=0 else -1
if b>=0: s=s[:a]+s[b:]
# Duplicate handler/menu entries.
h='procedure TLarGridPivot.GridPrintPreviewClick(Sender:TObject);\nbegin\n PrintPreview;\nend;\n\n'
while s.count(h)>1:
    a=s.find(h); s=s[:a]+s[a+len(h):]
line=" AddItem('Vista previa de impresión...',GridPrintPreviewClick);\n"
while line+line in s: s=s.replace(line+line,line)
p.write_text(s,encoding='utf-8')
