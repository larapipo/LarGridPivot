unit LarGridPivot.Fields;

interface

uses
  System.Classes, System.SysUtils, LarGridPivot.Types;

type
  TLarPivotFields = class;

  TLarPivotField = class(TCollectionItem)
  private
    FFieldName: string;
    FCaption: string;
    FArea: TLarPivotArea;
    FAreaIndex: Integer;
    FSummaryType: TLarPivotSummaryType;
    FSortOrder: TLarPivotSortOrder;
    FAlignment: TLarPivotAlignment;
    FHeaderAlignment: TLarPivotAlignment;
    FDisplayFormat: string;
    FWidth: Integer;
    FVisible: Boolean;
    FShowSubTotal: Boolean;
    procedure Changed;
    procedure SetArea(const Value: TLarPivotArea);
    procedure SetAreaIndex(const Value: Integer);
    procedure SetFieldName(const Value: string);
    procedure SetShowSubTotal(const Value:Boolean);
  public
    constructor Create(Collection: TCollection); override;
    function GetDisplayName: string; override;
  published
    property FieldName: string read FFieldName write SetFieldName;
    property Caption: string read FCaption write FCaption;
    property Area: TLarPivotArea read FArea write SetArea default paNone;
    property AreaIndex: Integer read FAreaIndex write SetAreaIndex default -1;
    property SummaryType: TLarPivotSummaryType read FSummaryType write FSummaryType default psSum;
    property SortOrder: TLarPivotSortOrder read FSortOrder write FSortOrder default psoNone;
    property Alignment: TLarPivotAlignment read FAlignment write FAlignment default pvaDefault;
    property HeaderAlignment: TLarPivotAlignment read FHeaderAlignment write FHeaderAlignment default pvaDefault;
    property DisplayFormat: string read FDisplayFormat write FDisplayFormat;
    property Width: Integer read FWidth write FWidth default 100;
    property Visible: Boolean read FVisible write FVisible default True;
    property ShowSubTotal:Boolean read FShowSubTotal write SetShowSubTotal default False;
  end;

  TLarPivotFields = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TLarPivotField;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TLarPivotField;
    function FindField(const AFieldName: string): TLarPivotField;
    procedure NotifyChanged;
    property Items[Index: Integer]: TLarPivotField read GetItem; default;
  end;

implementation

constructor TLarPivotField.Create(Collection: TCollection);
begin
  inherited;
  FArea := paNone;
  FAreaIndex := -1;
  FSummaryType := psSum;
  FSortOrder := psoNone;
  FAlignment := pvaDefault;
  FHeaderAlignment := pvaDefault;
  FWidth := 100;
  FVisible := True;
  FShowSubTotal := False;
end;

procedure TLarPivotField.Changed;
begin
  if Collection is TLarPivotFields then
    TLarPivotFields(Collection).NotifyChanged;
end;

function TLarPivotField.GetDisplayName: string;
begin
  if FCaption <> '' then
    Result := FCaption
  else if FFieldName <> '' then
    Result := FFieldName
  else
    Result := inherited GetDisplayName;
end;

procedure TLarPivotField.SetArea(const Value: TLarPivotArea);
begin
  if FArea <> Value then
  begin
    FArea := Value;
    Changed;
  end;
end;

procedure TLarPivotField.SetAreaIndex(const Value: Integer);
begin
  if FAreaIndex <> Value then
  begin
    FAreaIndex := Value;
    Changed;
  end;
end;

procedure TLarPivotField.SetFieldName(const Value: string);
begin
  if FFieldName <> Value then
  begin
    FFieldName := Value;
    if FCaption = '' then
      FCaption := Value;
    Changed;
  end;
end;

procedure TLarPivotField.SetShowSubTotal(const Value:Boolean);
begin
 if FShowSubTotal=Value then Exit;
 FShowSubTotal:=Value;
 Changed;
end;

constructor TLarPivotFields.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TLarPivotField);
end;

function TLarPivotFields.Add: TLarPivotField;
begin
  Result := TLarPivotField(inherited Add);
end;

function TLarPivotFields.FindField(const AFieldName: string): TLarPivotField;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if SameText(Items[I].FieldName, AFieldName) then
      Exit(Items[I]);
end;

function TLarPivotFields.GetItem(Index: Integer): TLarPivotField;
begin
  Result := TLarPivotField(inherited Items[Index]);
end;

procedure TLarPivotFields.NotifyChanged;
begin
  Changed;
end;

procedure TLarPivotFields.Update(Item: TCollectionItem);
begin
  inherited;
end;

end.
