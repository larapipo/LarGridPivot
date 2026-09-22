from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
# Integration is applied by this helper. Marker update triggers the branch workflow.
exec(Path('apply_print_options_body.py').read_text(encoding='utf-8')) if Path('apply_print_options_body.py').exists() else None
