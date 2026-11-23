program stage02_context_integration;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$ENDIF}
uses SysUtils, Classes, BigInt, MonsterBootstrap, Stage02WorkCounts, PastafariCalendar;
const
  ExpectedCases = 96;
  ChecksPerCase = 18;
  NilChecks = 2;
  ExpectedChecks = ExpectedCases * ChecksPerCase + NilChecks;
  ExpectedHeader = 'group'#9'calculation_day'#9'target_day'#9'action'#9'target'#9'distance'#9'connection'#9'direction';
var
  Cases, Passed, Failed: Integer;

procedure Check(const LabelText: string; OK: Boolean);
begin
  if OK then Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('STAGE02_CONTEXT_FAIL CASE=', Cases, ' CHECK=', LabelText);
  end;
end;

procedure CheckCase(const Fields: TStringList);
var
  Context: TMonsterContext;
  Counts: TWorkCounts;
begin
  if Fields.Count <> 8 then
    raise EConvertError.Create('TSV deve conter oito campos.');
  Context := TMonsterContext.Create(
    ParseCanonicalDay(Fields[1]), ParseCanonicalDay(Fields[2]));
  try
    Counts := WorkCountsForContext(Context);
    Inc(Cases);
    Check('oracle.action', BigToDecimal(Counts.Action) = Fields[3]);
    Check('oracle.target', BigToDecimal(Counts.Target) = Fields[4]);
    Check('oracle.distance', BigToDecimal(Counts.Distance) = Fields[5]);
    Check('oracle.connection', BigToDecimal(Counts.Connection) = Fields[6]);
    Check('oracle.direction', IntToStr(Counts.Direction) = Fields[7]);
    Check('owner.calculation', BigToDecimal(Context.CalculationDay) = Fields[1]);
    Check('owner.target', BigToDecimal(Context.TargetDay) = Fields[2]);
    Check('context.phase', Context.Phase = mpEntry);
    Check('context.status', Context.Status = msNew);
    Check('context.retry', Context.RetryBudget = 0);
    Check('context.metrics', Length(Context.Metrics) = 0);
    Check('context.logs', Length(Context.Logs) = 0);
    Check('context.error', Context.LastErrorCode = '');
    Context.CalculationDay := BigFromInt64(23);
    Context.TargetDay := BigFromInt64(-23);
  finally
    Context.Free;
  end;
  Check('detached.action', BigToDecimal(Counts.Action) = Fields[3]);
  Check('detached.target', BigToDecimal(Counts.Target) = Fields[4]);
  Check('detached.distance', BigToDecimal(Counts.Distance) = Fields[5]);
  Check('detached.connection', BigToDecimal(Counts.Connection) = Fields[6]);
  Check('detached.direction', IntToStr(Counts.Direction) = Fields[7]);
end;

procedure CheckNilContext;
var
  Rejected, MessageCorrect: Boolean;
  Counts: TWorkCounts;
begin
  Rejected := False;
  MessageCorrect := False;
  try
    Counts := WorkCountsForContext(nil);
    if Counts.Direction = 0 then Rejected := False;
  except
    on E: Exception do
    begin
      Rejected := True;
      MessageCorrect := E.Message = 'Contexto de invocação ausente.';
    end;
  end;
  Check('nil.rejected', Rejected);
  Check('nil.message', MessageCorrect);
end;

procedure ReadVectors(const Path: string);
var
  Lines, Fields: TStringList;
  I: Integer;
begin
  Lines := TStringList.Create;
  Fields := TStringList.Create;
  try
    Lines.LoadFromFile(Path);
    if (Lines.Count <> ExpectedCases + 1) or (Lines[0] <> ExpectedHeader) then
      raise EConvertError.Create('Cabeçalho ou número de linhas incorreto.');
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

begin
  Cases := 0;
  Passed := 0;
  Failed := 0;
  try
    if ParamCount <> 1 then
      raise EConvertError.Create('É obrigatório indicar o TSV independente.');
    ReadVectors(ParamStr(1));
    CheckNilContext;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('STAGE02_CONTEXT_EXCEPTION=', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('STAGE02_CONTEXT_CASES=', Cases);
  Writeln('STAGE02_CONTEXT_TOTAL_CHECKS_PASSED=', Passed);
  Writeln('STAGE02_CONTEXT_TOTAL_CHECKS_EXPECTED=', ExpectedChecks);
  Writeln('STAGE02_CONTEXT_FAILURES=', Failed);
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
