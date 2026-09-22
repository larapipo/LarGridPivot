from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
old='ControlStyle:=ControlStyle+[csOpaque,csWantAllKeys]; DoubleBuffered:=True; end;'
new='ControlStyle:=ControlStyle+[csOpaque]; DoubleBuffered:=True; end;'
if old not in s:
    raise SystemExit('Target csWantAllKeys line not found')
s=s.replace(old,new,1)
p.write_text(s,encoding='utf-8')
