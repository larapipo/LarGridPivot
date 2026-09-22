from pathlib import Path
p=Path('Source/LarGridPivot.Grid.pas')
s=p.read_text(encoding='utf-8')
# Correct coordinate mapping: frozen row area must not receive horizontal scroll offset.
old=""" CX:=AX+FHScrollPos; CY:=AY+FVScrollPos;
 for VI in FViewInfo.Items do
  if (VI.Kind in [pvekRowValue,pvekDataCell,pvekTotalCell,pvekGrandTotalCell]) and VI.Contains(CX,CY) then Exit(VI);"""
new=""" CY:=AY+FVScrollPos;
 for VI in FViewInfo.Items do begin
  if VI.Kind=pvekRowValue then CX:=AX else CX:=AX+FHScrollPos;
  if (VI.Kind in [pvekRowValue,pvekDataCell,pvekTotalCell,pvekGrandTotalCell]) and VI.Contains(CX,CY) then Exit(VI);
 end;"""
assert old in s
s=s.replace(old,new,1)
# Selection invalidation: repaint only result body, not field panel/header; avoids visible flicker.
s=s.replace("""procedure TLarGridPivot.ClearCellSelection;
begin FSelectedCells.Clear; FSelectionAnchor:=''; Invalidate; end;""","""procedure TLarGridPivot.ClearCellSelection;
var R:TRect;
begin
 FSelectedCells.Clear; FSelectionAnchor:='';
 if HandleAllocated then begin
  R:=Rect(0,EffectiveFieldAreaHeight+(FViewInfo.HeaderLevels*FHeaderHeight),ClientWidth,ClientHeight);
  InvalidateRect(Handle,@R,False);
 end else Invalidate;
end;""",1)
s=s.replace(""" FSelectionAnchor:=K; Invalidate;
end;

procedure TLarGridPivot.SelectCellsInRect""",""" FSelectionAnchor:=K;
 if HandleAllocated then begin
  R:=AItem.Bounds;
  OffsetRect(R,-FHScrollPos,-FVScrollPos);
  if AItem.Kind=pvekRowValue then OffsetRect(R,FHScrollPos,0);
  InvalidateRect(Handle,@R,False);
 end else Invalidate;
end;

procedure TLarGridPivot.SelectCellsInRect""",1)
# add R declaration to SelectCell
s=s.replace("var K:string; I:Integer;\nbegin\n if AItem=nil", "var K:string; I:Integer; R:TRect;\nbegin\n if AItem=nil",1)
# Rect selection uses frozen row x coordinate and invalidates body once without erasing background.
old2="""procedure TLarGridPivot.SelectCellsInRect(const ARect:TRect;AAdd:Boolean);
var VI:TLarPivotViewItem; R:TRect;
begin
 FSelectedCells.Clear;
 if AAdd then FSelectedCells.Assign(FSelectionBase);
 for VI in FViewInfo.Items do
  if VI.Kind in [pvekRowValue,pvekDataCell,pvekTotalCell,pvekGrandTotalCell] then begin
   R:=VI.Bounds;
   if (R.Right>ARect.Left) and (R.Left<ARect.Right) and (R.Bottom>ARect.Top) and (R.Top<ARect.Bottom) then
    FSelectedCells.Add(CellSelectionKey(VI));
  end;
 Invalidate;
end;"""
new2="""procedure TLarGridPivot.SelectCellsInRect(const ARect:TRect;AAdd:Boolean);
var VI:TLarPivotViewItem; R,PaintR:TRect;
begin
 FSelectedCells.Clear;
 if AAdd then FSelectedCells.Assign(FSelectionBase);
 for VI in FViewInfo.Items do
  if VI.Kind in [pvekRowValue,pvekDataCell,pvekTotalCell,pvekGrandTotalCell] then begin
   R:=VI.Bounds;
   { Row hierarchy is frozen horizontally; compare it in screen-X coordinates. }
   if VI.Kind=pvekRowValue then OffsetRect(R,FHScrollPos,0);
   if (R.Right>ARect.Left) and (R.Left<ARect.Right) and (R.Bottom>ARect.Top) and (R.Top<ARect.Bottom) then
    FSelectedCells.Add(CellSelectionKey(VI));
  end;
 if HandleAllocated then begin
  PaintR:=Rect(0,EffectiveFieldAreaHeight+(FViewInfo.HeaderLevels*FHeaderHeight),ClientWidth,ClientHeight);
  InvalidateRect(Handle,@PaintR,False);
 end else Invalidate;
end;"""
assert old2 in s
s=s.replace(old2,new2,1)
# Start and drag coordinates: screen X + content Y, so frozen hierarchy and scrolling data share one selection rectangle.
s=s.replace("FSelectionStart:=Point(X+FHScrollPos,Y+FVScrollPos);","FSelectionStart:=Point(X,Y+FVScrollPos);",1)
s=s.replace("""FSelectionRect:=Rect(Min(FSelectionStart.X,X+FHScrollPos),Min(FSelectionStart.Y,Y+FVScrollPos),
    Max(FSelectionStart.X,X+FHScrollPos)+1,Max(FSelectionStart.Y,Y+FVScrollPos)+1);""","""FSelectionRect:=Rect(Min(FSelectionStart.X,X),Min(FSelectionStart.Y,Y+FVScrollPos),
    Max(FSelectionStart.X,X)+1,Max(FSelectionStart.Y,Y+FVScrollPos)+1);""",1)
p.write_text(s,encoding='utf-8')
