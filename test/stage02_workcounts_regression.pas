program stage02_workcounts_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$ENDIF}
uses SysUtils, Classes, BigInt, Stage02WorkCounts;
const
  ExpectedCases = 96;
  ChecksPerCase = 15;
  NegativeCases = 9;
  ExpectedChecks = ExpectedCases * ChecksPerCase + NegativeCases;
  ExpectedHeader = 'group'#9'calculation_day'#9'target_day'#9'action'#9'target'#9'distance'#9'connection'#9'direction';
var
  Cases, Passed, Failed, InvalidRejected: Integer;
  Groups: array[0..5] of Integer;
procedure Check(const LabelText: string; OK: Boolean);
begin
  if OK then Inc(Passed)
  else begin
    Inc(Failed);
    Writeln('FAIL CASE=', Cases, ' CHECK=', LabelText);
  end;
end;
function GroupIndex(const S: string): Integer;
begin
  if S = 'EQUAL' then Exit(0);
  if S = 'ADJACENT' then Exit(1);
  if S = 'FORWARD' then Exit(2);
  if S = 'REVERSE' then Exit(3);
  if S = 'INTEGER_BOUNDARY' then Exit(4);
  if S = 'HUGE' then Exit(5);
  raise EConvertError.Create('Unknown oracle group');
end;
procedure CheckCase(const Fields: TStringList);
var
  A, B, Delta: TBigInt;
  C, ReverseC: TWorkCounts;
  ReverseDirection: Integer;
begin
  if Fields.Count <> 8 then
    raise EConvertError.Create('TSV must have eight fields');
  Inc(Groups[GroupIndex(Fields[0])]);
  A := ParseCanonicalDay(Fields[1]);
  B := ParseCanonicalDay(Fields[2]);
  C := ComputeWorkCountsDecimal(Fields[1], Fields[2]);
  ReverseC := ComputeWorkCounts(B, A);
  Inc(Cases);
  Check('oracle.action', BigToDecimal(C.Action) = Fields[3]);
  Check('oracle.target', BigToDecimal(C.Target) = Fields[4]);
  Check('oracle.distance', BigToDecimal(C.Distance) = Fields[5]);
  Check('oracle.connection', BigToDecimal(C.Connection) = Fields[6]);
  Check('oracle.direction', IntToStr(C.Direction) = Fields[7]);
  Check('reverse.distance', BigCompare(C.Distance, ReverseC.Distance) = 0);
  Check('reverse.connection', BigCompare(C.Connection, ReverseC.Connection) = 0);
  Check('reverse.action', BigCompare(C.Action, ReverseC.Target) = 0);
  Check('reverse.target', BigCompare(C.Target, ReverseC.Action) = 0);
  ReverseDirection := 4 - C.Direction;
  Check('reverse.direction', ReverseC.Direction = ReverseDirection);
  Check('sum.connection', BigCompare(C.Connection, BigAdd(C.Action, C.Target)) = 0);
  Delta := BigSubtract(B, A);
  Check('metric.distance', BigCompare(C.Distance, BigAdd(BigAbs(Delta), BigOne)) = 0);
  Check('positive.action', BigCompare(C.Action, BigZero) > 0);
  Check('positive.target', BigCompare(C.Target, BigZero) > 0);
  Check('positive.distance', BigCompare(C.Distance, BigZero) > 0);
end;
procedure CheckInvalid(const S: string);
var Rejected: Boolean; Parsed: TBigInt;
begin
  Rejected := False;
  try
    Parsed := ParseCanonicalDay(S);
    if BigIsZero(Parsed) then Rejected := False;
  except
    on E: EConvertError do Rejected := True;
  end;
  if Rejected then Inc(InvalidRejected);
  Check('reject-invalid-decimal', Rejected);
end;
procedure ReadVectors(const Path: string);
var Lines, Fields: TStringList; I: Integer;
begin
  Lines := TStringList.Create;
  Fields := TStringList.Create;
  try
    Lines.LoadFromFile(Path);
    if (Lines.Count <> ExpectedCases + 1) or
       (Lines[0] <> ExpectedHeader) then
      raise EConvertError.Create('TSV header or row count mismatch');
    Fields.Delimiter := #9;
    Fields.StrictDelimiter := True;
    for I := 1 to Lines.Count - 1 do
    begin
      Fields.DelimitedText := Lines[I];
      CheckCase(Fields);
    end;
  finally
    Fields.Free;
    Lines.Free;
  end;
end;
var I: Integer;
begin
  Cases := 0; Passed := 0; Failed := 0; InvalidRejected := 0;
  for I := 0 to 5 do Groups[I] := 0;
  try
    if ParamCount <> 1 then
      raise EConvertError.Create('Expected canonical TSV path argument');
    ReadVectors(ParamStr(1));
    CheckInvalid('');
    CheckInvalid('+');
    CheckInvalid('-0');
    CheckInvalid('01');
    CheckInvalid(' 1');
    CheckInvalid('1 ');
    CheckInvalid('1.0');
    CheckInvalid('--1');
    CheckInvalid(#$D9#$A1);
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('STAGE02_EXCEPTION=', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('STAGE02_CASES=', Cases);
  Writeln('STAGE02_FIELD_CHECKS=', Cases * 5);
  Writeln('STAGE02_METAMORPHIC_CHECKS=', Cases * 10);
  Writeln('STAGE02_INVALID_REJECTED=', InvalidRejected);
  Writeln('STAGE02_TOTAL_CHECKS_PASSED=', Passed);
  Writeln('STAGE02_TOTAL_CHECKS_EXPECTED=', ExpectedChecks);
  Writeln('STAGE02_FAILURES=', Failed);
  for I := 0 to 5 do
    Writeln('STAGE02_GROUP_', I, '=', Groups[I]);
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or
      (Failed <> 0) or (InvalidRejected <> NegativeCases) then Halt(1);
  for I := 0 to 5 do
    if Groups[I] <> 16 then Halt(1);
end.
