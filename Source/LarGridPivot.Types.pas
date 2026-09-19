unit LarGridPivot.Types;

interface

const
  LAR_GRID_PIVOT_VERSION_MAJOR = 1;
  LAR_GRID_PIVOT_VERSION_MINOR = 0;
  LAR_GRID_PIVOT_VERSION_PATCH = 0;

type
  TLarPivotArea = (paNone, paRow, paColumn, paData, paFilter);
  TLarPivotSummaryType = (psSum, psCount, psAverage, psMin, psMax);
  TLarPivotSortOrder = (psoNone, psoAscending, psoDescending);
  TLarPivotAlignment = (pvaDefault, pvaLeft, pvaCenter, pvaRight);

  TLarPivotCellType = (
    pctEmpty,
    pctRowHeader,
    pctColumnHeader,
    pctData,
    pctSubtotal,
    pctGrandTotal
  );

  TLarPivotCellSpan = record
    RowSpan: Integer;
    ColSpan: Integer;
    class function Create(ARowSpan, AColSpan: Integer): TLarPivotCellSpan; static;
  end;

implementation

class function TLarPivotCellSpan.Create(ARowSpan,
  AColSpan: Integer): TLarPivotCellSpan;
begin
  Result.RowSpan := ARowSpan;
  Result.ColSpan := AColSpan;
end;

end.
