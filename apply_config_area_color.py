from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
s=s.replace('    FFieldAreaSplitPercent:Integer;\n    FTheme:TLarPivotTheme;', '    FFieldAreaSplitPercent:Integer;\n    FConfigAreaColor:TColor;\n    FTheme:TLarPivotTheme;',1)
s=s.replace('    procedure SetFieldAreaSplitPercent(const Value:Integer);', '    procedure SetFieldAreaSplitPercent(const Value:Integer);\n    procedure SetConfigAreaColor(const Value:TColor);',1)
s=s.replace('    property FieldAreaSplitPercent:Integer read FFieldAreaSplitPercent write SetFieldAreaSplitPercent default 27;', '    property FieldAreaSplitPercent:Integer read FFieldAreaSplitPercent write SetFieldAreaSplitPercent default 27;\n    property ConfigAreaColor:TColor read FConfigAreaColor write SetConfigAreaColor default $00FCF8F5;',1)
s=s.replace('FShowFieldPanel:=True; FFieldPanelFontSize:=8; FFieldAreaSplitPercent:=27;', 'FShowFieldPanel:=True; FFieldPanelFontSize:=8; FFieldAreaSplitPercent:=27; FConfigAreaColor:=$00FCF8F5;',1)
needle='''procedure TLarGridPivot.SetFieldAreaSplitPercent(const Value:Integer);\nvar N:Integer;\nbegin\n N:=Value;\n if N<15 then N:=15;\n if N>85 then N:=85;\n if FFieldAreaSplitPercent=N then Exit;\n FFieldAreaSplitPercent:=N;\n FViewDirty:=True; FScrollDirty:=True; Invalidate;\nend;'''
repl=needle+'''\n\nprocedure TLarGridPivot.SetConfigAreaColor(const Value:TColor);\nbegin\n if FConfigAreaColor=Value then Exit;\n FConfigAreaColor:=Value;\n Invalidate;\nend;'''
assert needle in s
s=s.replace(needle,repl,1)
s=s.replace('Canvas.Brush.Color:=ThemePanelColor; Canvas.FillRect(AR); Canvas.Pen.Color:=ThemeGridColor; Canvas.Rectangle(AR);','Canvas.Brush.Color:=FConfigAreaColor; Canvas.FillRect(AR); Canvas.Pen.Color:=ThemeGridColor; Canvas.Rectangle(AR);',1)
p.write_text(s,encoding='utf-8')
