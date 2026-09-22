unit LarGridPivot.PrintConfig;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections;

type
  TLarPivotPaperSize = (ppsPrinterDefault, ppsA4, ppsLetter, ppsA5, ppsLegal);

  TLarPivotPrintColumn = class(TCollectionItem)
  private
    FFieldName: string;
    FWidth: Integer;
    FVisible: Boolean;
  published
    property FieldName: string read FFieldName write FFieldName;
    property Width: Integer read FWidth write FWidth default 0;
    property Visible: Boolean read FVisible write FVisible default True;
  public
    constructor Create(Collection: TCollection); override;
  end;

  TLarPivotPrintColumns = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TLarPivotPrintColumn;
  public
    constructor Create(AOwner: TPersistent);
    function Find(const AFieldName: string): TLarPivotPrintColumn;
    function Ensure(const AFieldName: string): TLarPivotPrintColumn;
    property Items[Index: Integer]: TLarPivotPrintColumn read GetItem; default;
  end;

  TLarPivotPrintOptions = class(TPersistent)
  private
    FPaperSize: TLarPivotPaperSize;
    FMarginLeft, FMarginRight, FMarginTop, FMarginBottom: Integer;
    FFitToPageWidth: Boolean;
    FColumns: TLarPivotPrintColumns;
  public
    constructor Create(AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property PaperSize: TLarPivotPaperSize read FPaperSize write FPaperSize default ppsA4;
    property MarginLeftMM: Integer read FMarginLeft write FMarginLeft default 12;
    property MarginRightMM: Integer read FMarginRight write FMarginRight default 12;
    property MarginTopMM: Integer read FMarginTop write FMarginTop default 12;
    property MarginBottomMM: Integer read FMarginBottom write FMarginBottom default 12;
    property FitToPageWidth: Boolean read FFitToPageWidth write FFitToPageWidth default True;
    property Columns: TLarPivotPrintColumns read FColumns;
  end;

implementation

constructor TLarPivotPrintColumn.Create(Collection: TCollection);
begin inherited; FVisible:=True; FWidth:=0; end;
constructor TLarPivotPrintColumns.Create(AOwner: TPersistent);
begin inherited Create(AOwner, TLarPivotPrintColumn); end;
function TLarPivotPrintColumns.GetItem(Index: Integer): TLarPivotPrintColumn;
begin Result:=TLarPivotPrintColumn(inherited Items[Index]); end;
function TLarPivotPrintColumns.Find(const AFieldName: string): TLarPivotPrintColumn;
var I:Integer;
begin Result:=nil; for I:=0 to Count-1 do if SameText(Items[I].FieldName,AFieldName) then Exit(Items[I]); end;
function TLarPivotPrintColumns.Ensure(const AFieldName: string): TLarPivotPrintColumn;
begin Result:=Find(AFieldName); if Result=nil then begin Result:=TLarPivotPrintColumn(Add); Result.FieldName:=AFieldName; end; end;
constructor TLarPivotPrintOptions.Create(AOwner: TPersistent);
begin inherited Create; FPaperSize:=ppsA4; FMarginLeft:=12; FMarginRight:=12; FMarginTop:=12; FMarginBottom:=12; FFitToPageWidth:=True; FColumns:=TLarPivotPrintColumns.Create(AOwner); end;
destructor TLarPivotPrintOptions.Destroy; begin FColumns.Free; inherited; end;
procedure TLarPivotPrintOptions.Assign(Source: TPersistent);
var S:TLarPivotPrintOptions;
begin
 if Source is TLarPivotPrintOptions then begin S:=TLarPivotPrintOptions(Source); FPaperSize:=S.FPaperSize; FMarginLeft:=S.FMarginLeft; FMarginRight:=S.FMarginRight; FMarginTop:=S.FMarginTop; FMarginBottom:=S.FMarginBottom; FFitToPageWidth:=S.FFitToPageWidth; FColumns.Assign(S.FColumns); end else inherited;
end;
end.
