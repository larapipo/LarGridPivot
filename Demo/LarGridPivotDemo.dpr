program LarGridPivotDemo;

uses
  Vcl.Forms,
  Demo.Main in 'Demo.Main.pas' {FrmLarGridPivotDemo},
  Demo.Gestion in 'Demo.Gestion.pas' {FrmLarGridPivotGestionDemo},
  LarGridPivot.Types in '..\Source\LarGridPivot.Types.pas',
  LarGridPivot.Fields in '..\Source\LarGridPivot.Fields.pas',
  LarGridPivot.Filters in '..\Source\LarGridPivot.Filters.pas',
  LarGridPivot.Model in '..\Source\LarGridPivot.Model.pas',
  LarGridPivot.DataProvider in '..\Source\LarGridPivot.DataProvider.pas',
  LarGridPivot.Engine in '..\Source\LarGridPivot.Engine.pas',
  LarGridPivot.LayoutEngine in '..\Source\LarGridPivot.LayoutEngine.pas',
  LarGridPivot.ViewInfo in '..\Source\LarGridPivot.ViewInfo.pas',
  LarGridPivot.Layout in '..\Source\LarGridPivot.Layout.pas',
  LarGridPivot.Grid in '..\Source\LarGridPivot.Grid.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmLarGridPivotDemo, FrmLarGridPivotDemo);
  Application.Run;
end.
