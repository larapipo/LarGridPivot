from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
s=s.replace('    procedure SetConfigAreaColor(const Value:TColor);\n    procedure SetConfigAreaColor(const Value:TColor);','    procedure SetConfigAreaColor(const Value:TColor);',1)
s=s.replace('    property ConfigAreaColor:TColor read FConfigAreaColor write SetConfigAreaColor default $00FCF8F5;\n    property ConfigAreaColor:TColor read FConfigAreaColor write SetConfigAreaColor default $00FCF8F5;','    property ConfigAreaColor:TColor read FConfigAreaColor write SetConfigAreaColor default $00FCF8F5;',1)
s=s.replace('FFieldAreaSplitPercent:=27; FConfigAreaColor:=$00FCF8F5; FConfigAreaColor:=$00FCF8F5;','FFieldAreaSplitPercent:=27; FConfigAreaColor:=$00FCF8F5;',1)
block='''procedure TLarGridPivot.SetConfigAreaColor(const Value:TColor);\nbegin\n if FConfigAreaColor=Value then Exit;\n FConfigAreaColor:=Value;\n Invalidate;\nend;'''
double=block+'\n\n'+block
s=s.replace(double,block,1)
assert s.count('procedure SetConfigAreaColor(const Value:TColor);') == 1
assert s.count('property ConfigAreaColor:TColor') == 1
assert s.count('procedure TLarGridPivot.SetConfigAreaColor(const Value:TColor);') == 1
assert s.count('FConfigAreaColor:=$00FCF8F5;') == 1
assert 'Canvas.Brush.Color:=FConfigAreaColor; Canvas.FillRect(AR);' in s
p.write_text(s,encoding='utf-8')
