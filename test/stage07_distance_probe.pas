program stage07_distance_probe;
{$MODE OBJFPC}{$H+}
uses SysUtils, Classes, BigInt, Stage02WorkCounts, PastafariCalendar, MonsterBootstrap, Stage07SeededLegacy;
const Header = 'c'#9't'#9'action'#9'target'#9'distance'#9'connection'#9'direction';
var Lines, Fields: TStringList;
    I, Cases, Mismatches: Integer;
    C, T: TBigInt;
    A, B, D, L: TWorkCounts;
    Context: TMonsterContext;
    Expected: string;
    OutFile: Text;
function TupleText(const W: TWorkCounts): string;
begin
  Result := BigToDecimal(W.Action)+#9+BigToDecimal(W.Target)+#9+
    BigToDecimal(W.Distance)+#9+BigToDecimal(W.Connection)+#9+IntToStr(W.Direction);
end;
begin
  if ParamCount<>2 then Halt(2);
  Cases:=0; Mismatches:=0;
  Lines:=TStringList.Create; Fields:=TStringList.Create;
  try
    Lines.LoadFromFile(ParamStr(1));
    if (Lines.Count<>8101) or (Lines[0]<>Header) then Halt(2);
    Fields.Delimiter:=#9; Fields.StrictDelimiter:=True;
    Assign(OutFile,ParamStr(2)); Rewrite(OutFile);
    try
      Writeln(OutFile,'c'#9't'#9'direct_action'#9'direct_target'#9'direct_distance'#9'direct_connection'#9'direct_direction'#9+
        'decimal_action'#9'decimal_target'#9'decimal_distance'#9'decimal_connection'#9'decimal_direction'#9+
        'context_action'#9'context_target'#9'context_distance'#9'context_connection'#9'context_direction'#9+
        'legacy_action'#9'legacy_target'#9'legacy_distance'#9'legacy_connection'#9'legacy_direction');
      for I:=1 to Lines.Count-1 do
      begin
        Fields.DelimitedText:=Lines[I];
        if Fields.Count<>7 then Halt(2);
        C:=ParseCanonicalDay(Fields[0]); T:=ParseCanonicalDay(Fields[1]);
        A:=ComputeWorkCounts(C,T);
        B:=ComputeWorkCountsDecimal(Fields[0],Fields[1]);
        Context:=TMonsterContext.Create(C,T);
        try D:=WorkCountsForContext(Context); finally Context.Free; end;
        L:=ComputeWorkCountsSeededLegacy(C,T);
        Expected:=Fields[2]+#9+Fields[3]+#9+Fields[4]+#9+Fields[5]+#9+Fields[6];
        Writeln(OutFile,Fields[0],#9,Fields[1],#9,TupleText(A),#9,TupleText(B),#9,TupleText(D),#9,TupleText(L));
        Inc(Cases);
        if (TupleText(A)<>Expected) or (TupleText(B)<>Expected) or (TupleText(D)<>Expected) then Inc(Mismatches);
      end;
    finally Close(OutFile); end;
  finally Fields.Free; Lines.Free; end;
  Writeln('STAGE07_NATIVE_ROWS=',Cases);
  Writeln('STAGE07_NATIVE_MISMATCH_ROWS=',Mismatches);
  if Mismatches<>0 then Halt(1);
end.
