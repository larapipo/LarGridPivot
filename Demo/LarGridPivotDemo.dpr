program LarGridPivotDemo;

uses
  Vcl.Forms,
  Demo.Main in 'Demo.Main.pas' {FrmLarGridPivotDemo},
  Demo.Gestion in 'Demo.Gestion.pas' {FrmLarGridPivotGestionDemo};


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmLarGridPivotDemo, FrmLarGridPivotDemo);
  Application.Run;
end.
