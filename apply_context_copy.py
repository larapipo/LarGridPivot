from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
s=s.replace('    procedure GridExportExcelClick(Sender:TObject);','    procedure GridCopyClick(Sender:TObject);\n    procedure GridExportExcelClick(Sender:TObject);',1)
s=s.replace("procedure TLarGridPivot.GridExportExcelClick(Sender:TObject);","procedure TLarGridPivot.GridCopyClick(Sender:TObject);\nbegin\n CopySelectionToClipboard;\nend;\n\nprocedure TLarGridPivot.GridExportExcelClick(Sender:TObject);",1)
# Add Copy to hierarchy context menu before exports.
s=s.replace(" AddTotalsMenuItems(FHierarchyMenu);\n AddItem('-',nil);\n AddItem('Exportar a Excel...',GridExportExcelClick);"," AddTotalsMenuItems(FHierarchyMenu);\n AddItem('-',nil);\n if FAllowCopyToClipboard and (FSelectedCells.Count>0) then\n  AddItem('Copiar',GridCopyClick);\n AddItem('Exportar a Excel...',GridExportExcelClick);",1)
# Add Copy to generic result context menu before exports.
s=s.replace(" AddTotalsMenuItems(FGridMenu);\n AddItem('-',nil);\n AddItem('Exportar a Excel...',GridExportExcelClick);"," AddTotalsMenuItems(FGridMenu);\n AddItem('-',nil);\n if FAllowCopyToClipboard and (FSelectedCells.Count>0) then\n  AddItem('Copiar',GridCopyClick);\n AddItem('Exportar a Excel...',GridExportExcelClick);",1)
p.write_text(s,encoding='utf-8')
