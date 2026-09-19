program LarGridPivotDemo;

uses
  Vcl.Forms,
  Demo.Main in 'Demo.Main.pas' {FrmLarGridPivotDemo};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmLarGridPivotDemo, FrmLarGridPivotDemo);
  Application.Run;
end.
