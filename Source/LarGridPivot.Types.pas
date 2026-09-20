unit LarGridPivot.Types;

interface

uses
  System.Types;

const
  LAR_GRID_PIVOT_VERSION_MAJOR = 1;
  LAR_GRID_PIVOT_VERSION_MINOR = 0;
  LAR_GRID_PIVOT_VERSION_PATCH = 0;

type
  TLarPivotArea = (paNone, paRow, paColumn, paData, paFilter);
  TLarPivotSummaryType = (psSum, psCount, psAverage, psMin, psMax);
  TLarPivotSortOrder = (psoNone, psoAscending, psoDescending);
  TLarPivotAlignment = (pvaDefault, pvaLeft, pvaCenter, pvaRight);
  TLarPivotTheme = (ptClassicBlue, ptLight, ptSilver, ptOffice, ptDark);

  TLarPivotCellType = (
    pctEmpty,
    pctRowHeader,
    pctColumnHeader,
    pctData,
    pctSubtotal,
    pctGrandTotal
  );

  TLarPivotViewElementKind = (
    pvekNone,
    pvekFieldHeader,
    pvekRowValue,
    pvekColumnValue,
    pvekDataCell,
    pvekTotalCell,
    pvekGrandTotalCell,
    pvekExpandButton,
    pvekFilterButton,
    pvekFieldArea
  );

  TLarPivotHitTest = record
    Kind: TLarPivotViewElementKind;
    Bounds: TRect;
    FieldName: string;
    RowKey: string;
    ColumnKey: string;
    Level: Integer;
    DataIndex: Integer;
    class function Empty: TLarPivotHitTest; static;
  end;

  TLarPivotCellSpan = record
    RowSpan: Integer;
    ColSpan: Integer;
    class function Create(ARowSpan, AColSpan: Integer): TLarPivotCellSpan; static;
  end;

implementation

class function TLarPivotHitTest.Empty:TLarPivotHitTest;
begin
 Result.Kind:=pvekNone;
 Result.Bounds:=Rect(0,0,0,0);
 Result.FieldName:='';
 Result.RowKey:='';
 Result.ColumnKey:='';
 Result.Level:=-1;
 Result.DataIndex:=-1;
end;

class function TLarPivotCellSpan.Create(ARowSpan,
  AColSpan: Integer): TLarPivotCellSpan;
begin
  Result.RowSpan := ARowSpan;
  Result.ColSpan := AColSpan;
end;

end.
