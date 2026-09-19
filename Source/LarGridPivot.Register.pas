unit LarGridPivot.Register;

interface

procedure Register;

implementation

uses
  System.Classes,
  LarGridPivot.Grid;

procedure Register;
begin
  RegisterComponents('LarSoft', [TLarGridPivot]);
end;

end.
