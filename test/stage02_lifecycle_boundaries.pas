program stage02_lifecycle_boundaries;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
uses SysUtils, Classes, BigInt, MonsterBootstrap, Stage02WorkCounts, PastafariCalendar;

const
  ExpectedNilMessage: RawByteString = 'Contexto de invoca'#$C3#$A7#$C3#$A3'o ausente.';
  ExpectedVectors = 96;
  ExpectedContexts = ExpectedVectors * 2;
  ChecksPerContext = 19;
  ExpectedMatrixChecks = ExpectedContexts * ChecksPerContext;
  ExpectedBoundaryChecks = 6;
  ExpectedTotalChecks = ExpectedMatrixChecks + ExpectedBoundaryChecks;
  ExpectedHeader = 'group'#9'calculation_day'#9'target_day'#9'action'#9'target'#9'distance'#9'connection'#9'direction';

type
  TContextPath = (cpManagerCompleted, cpFailedSentinel);

var
  Vectors, Contexts, MatrixExecuted, MatrixPassed: Integer;
  BoundaryExecuted, BoundaryPassed, Failures: Integer;

procedure Check(const Name: string; Condition, Boundary: Boolean);
begin
  if Boundary then
    Inc(BoundaryExecuted)
  else
    Inc(MatrixExecuted);
  if Condition then
  begin
    if Boundary then Inc(BoundaryPassed) else Inc(MatrixPassed);
  end
  else
  begin
    Inc(Failures);
    Writeln('STAGE02_LIFECYCLE_FAIL VECTOR=', Vectors,
      ' CONTEXT=', Contexts, ' CHECK=', Name);
  end;
end;

function CloneMetrics(const Input: TMetricArray): TMetricArray;
var I: Integer;
begin
  SetLength(Result, Length(Input));
  for I := 0 to High(Input) do
  begin
    Result[I].Name := Input[I].Name;
    Result[I].Value := Input[I].Value;
  end;
end;

function CloneLogs(const Input: TLogArray): TLogArray;
var I: Integer;
begin
  SetLength(Result, Length(Input));
  for I := 0 to High(Input) do
    Result[I] := Input[I];
end;

function EqualMetrics(const A, B: TMetricArray): Boolean;
var I: Integer;
begin
  if Length(A) <> Length(B) then Exit(False);
  for I := 0 to High(A) do
    if (A[I].Name <> B[I].Name) or (A[I].Value <> B[I].Value) then
      Exit(False);
  Result := True;
end;

function EqualLogs(const A, B: TLogArray): Boolean;
var I: Integer;
begin
  if Length(A) <> Length(B) then Exit(False);
  for I := 0 to High(A) do
    if A[I] <> B[I] then Exit(False);
  Result := True;
end;

function CompletedPrecondition(C: TMonsterContext): Boolean;
begin
  Result := False;
  if (C.Phase <> mpCompleted) or (C.Status <> msCompleted) or
     (C.RetryBudget <> 0) or (C.LastErrorCode <> '') or
     (Length(C.Metrics) <> 2) or (Length(C.Logs) <> 1) then Exit;
  Result :=
    (C.Metrics[0].Name = 'bootstrap.calls') and
    (C.Metrics[0].Value = 1) and
    (C.Metrics[1].Name = 'bootstrap.completed') and
    (C.Metrics[1].Value = 1) and
    (C.Logs[0] = 'bootstrap:dispatch');
end;

function FailedSentinelPrecondition(C: TMonsterContext): Boolean;
begin
  Result := False;
  if (C.Phase <> mpFailed) or (C.Status <> msFailed) or
     (C.RetryBudget <> 7) or (C.LastErrorCode <> 'E_TEST') or
     (Length(C.Metrics) <> 2) or (Length(C.Logs) <> 1) then Exit;
  Result :=
    (C.Metrics[0].Name = 'sentinel.attempts') and
    (C.Metrics[0].Value = 7) and
    (C.Metrics[1].Name = 'sentinel.failures') and
    (C.Metrics[1].Value = -4) and
    (C.Logs[0] = 'sentinel:failure');
end;

procedure SetFailedSentinels(C: TMonsterContext);
begin
  C.Phase := mpFailed;
  C.Status := msFailed;
  C.RetryBudget := 7;
  SetLength(C.Metrics, 2);
  C.Metrics[0].Name := 'sentinel.attempts';
  C.Metrics[0].Value := 7;
  C.Metrics[1].Name := 'sentinel.failures';
  C.Metrics[1].Value := -4;
  SetLength(C.Logs, 1);
  C.Logs[0] := 'sentinel:failure';
  C.LastErrorCode := 'E_TEST';
end;

procedure RunPath(const Fields: TStringList; Path: TContextPath);
var
  C: TMonsterContext;
  Manager: TMonsterManager;
  Counts: TWorkCounts;
  BeforePhase: TMonsterPhase;
  BeforeStatus: TMonsterStatus;
  BeforeRetry: Integer;
  BeforeMetrics: TMetricArray;
  BeforeLogs: TLogArray;
  BeforeError: string;
  Precondition: Boolean;
begin
  C := TMonsterContext.Create(
    ParseCanonicalDay(Fields[1]), ParseCanonicalDay(Fields[2]));
  Manager := nil;
  try
    if Path = cpManagerCompleted then
    begin
      Manager := TMonsterManager.Create;
      Manager.ExecuteBootstrap(C);
      Precondition := CompletedPrecondition(C);
    end
    else
    begin
      SetFailedSentinels(C);
      Precondition := FailedSentinelPrecondition(C);
    end;

    BeforePhase := C.Phase;
    BeforeStatus := C.Status;
    BeforeRetry := C.RetryBudget;
    BeforeMetrics := CloneMetrics(C.Metrics);
    BeforeLogs := CloneLogs(C.Logs);
    BeforeError := C.LastErrorCode;

    Inc(Contexts);
    Check('path.precondition', Precondition, False);
    Counts := WorkCountsForContext(C);
    Check('oracle.action', BigToDecimal(Counts.Action) = Fields[3], False);
    Check('oracle.target', BigToDecimal(Counts.Target) = Fields[4], False);
    Check('oracle.distance', BigToDecimal(Counts.Distance) = Fields[5], False);
    Check('oracle.connection', BigToDecimal(Counts.Connection) = Fields[6], False);
    Check('oracle.direction', IntToStr(Counts.Direction) = Fields[7], False);
    Check('input.calculation', BigToDecimal(C.CalculationDay) = Fields[1], False);
    Check('input.target', BigToDecimal(C.TargetDay) = Fields[2], False);
    Check('state.phase', C.Phase = BeforePhase, False);
    Check('state.status', C.Status = BeforeStatus, False);
    Check('state.retry', C.RetryBudget = BeforeRetry, False);
    Check('state.metrics', EqualMetrics(C.Metrics, BeforeMetrics), False);
    Check('state.logs', EqualLogs(C.Logs, BeforeLogs), False);
    Check('state.error', C.LastErrorCode = BeforeError, False);

    C.CalculationDay := BigFromInt64(23);
    C.TargetDay := BigFromInt64(-23);
  finally
    Manager.Free;
    C.Free;
  end;

  Check('detached.action', BigToDecimal(Counts.Action) = Fields[3], False);
  Check('detached.target', BigToDecimal(Counts.Target) = Fields[4], False);
  Check('detached.distance', BigToDecimal(Counts.Distance) = Fields[5], False);
  Check('detached.connection', BigToDecimal(Counts.Connection) = Fields[6], False);
  Check('detached.direction', IntToStr(Counts.Direction) = Fields[7], False);
end;

procedure CheckNilContexts;
var
  Rejected, CorrectMessage: Boolean;
  Counts: TWorkCounts;
  Manager: TMonsterManager;
begin
  Rejected := False;
  CorrectMessage := False;
  try
    Counts := WorkCountsForContext(nil);
    if Counts.Direction = -999 then Rejected := False;
  except
    on E: Exception do
    begin
      Rejected := True;
      CorrectMessage := RawByteString(E.Message) = ExpectedNilMessage;
    end;
  end;
  Check('nil.workcounts.rejected', Rejected, True);
  Check('nil.workcounts.message', CorrectMessage, True);

  Rejected := False;
  CorrectMessage := False;
  Manager := TMonsterManager.Create;
  try
    try
      Manager.ExecuteBootstrap(nil);
    except
      on E: Exception do
      begin
        Rejected := True;
        CorrectMessage := RawByteString(E.Message) = ExpectedNilMessage;
      end;
    end;
  finally
    Manager.Free;
  end;
  Check('nil.manager.rejected', Rejected, True);
  Check('nil.manager.message', CorrectMessage, True);
end;

procedure CheckConstructorOwnership;
const
  TextA = '123456789012345678901234567890';
  TextB = '-98765432109876543210987654321';
var
  A, B: TBigInt;
  C: TMonsterContext;
begin
  A := BigFromDecimal(TextA);
  B := BigFromDecimal(TextB);
  C := TMonsterContext.Create(A, B);
  try
    A.Digits[0] := 42;
    A.Sign := -1;
    B.Digits[0] := 17;
    B.Sign := 1;
    Check('constructor.clone.calculation',
      BigToDecimal(C.CalculationDay) = TextA, True);
    Check('constructor.clone.target',
      BigToDecimal(C.TargetDay) = TextB, True);
  finally
    C.Free;
  end;
end;

procedure ReadVectors(const FileName: string);
var
  Lines, Fields, PairKeys: TStringList;
  I: Integer;
begin
  Lines := TStringList.Create;
  Fields := TStringList.Create;
  PairKeys := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    if (Lines.Count <> ExpectedVectors + 1) or
       (Lines[0] <> ExpectedHeader) then
      raise EConvertError.Create('Cabeçalho ou número de vetores inválido.');
    Fields.Delimiter := #9;
    Fields.StrictDelimiter := True;
    PairKeys.Sorted := True;
    PairKeys.Duplicates := dupError;
    for I := 1 to Lines.Count - 1 do
    begin
      Fields.DelimitedText := Lines[I];
      if Fields.Count <> 8 then
        raise EConvertError.Create('TSV com número de campos inválido.');
      PairKeys.Add(Fields[1] + '|' + Fields[2]);
      Inc(Vectors);
      RunPath(Fields, cpManagerCompleted);
      RunPath(Fields, cpFailedSentinel);
    end;
    if PairKeys.Count <> ExpectedVectors then
      raise EConvertError.Create('Vetores duplicados.');
  finally
    PairKeys.Free;
    Fields.Free;
    Lines.Free;
  end;
end;

begin
  Vectors := 0;
  Contexts := 0;
  MatrixExecuted := 0;
  MatrixPassed := 0;
  BoundaryExecuted := 0;
  BoundaryPassed := 0;
  Failures := 0;
  try
    if ParamCount <> 1 then
      raise EConvertError.Create('É obrigatório indicar o TSV independente.');
    ReadVectors(ParamStr(1));
    CheckNilContexts;
    CheckConstructorOwnership;
  except
    on E: Exception do
    begin
      Inc(Failures);
      Writeln('STAGE02_LIFECYCLE_EXCEPTION=', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('STAGE02_LIFECYCLE_VECTORS=', Vectors);
  Writeln('STAGE02_LIFECYCLE_CONTEXTS=', Contexts);
  Writeln('STAGE02_LIFECYCLE_MATRIX_CHECKS_PASSED=', MatrixPassed);
  Writeln('STAGE02_LIFECYCLE_MATRIX_CHECKS_EXECUTED=', MatrixExecuted);
  Writeln('STAGE02_LIFECYCLE_NEGATIVE_CHECKS_PASSED=', BoundaryPassed);
  Writeln('STAGE02_LIFECYCLE_NEGATIVE_CHECKS_EXECUTED=', BoundaryExecuted);
  Writeln('STAGE02_LIFECYCLE_TOTAL_CHECKS_PASSED=', MatrixPassed + BoundaryPassed);
  Writeln('STAGE02_LIFECYCLE_TOTAL_CHECKS_EXPECTED=', ExpectedTotalChecks);
  Writeln('STAGE02_LIFECYCLE_FAILURES=', Failures);
  if (Vectors <> ExpectedVectors) or (Contexts <> ExpectedContexts) or
     (MatrixExecuted <> ExpectedMatrixChecks) or
     (MatrixPassed <> ExpectedMatrixChecks) or
     (BoundaryExecuted <> ExpectedBoundaryChecks) or
     (BoundaryPassed <> ExpectedBoundaryChecks) or
     (Failures <> 0) then Halt(1);
end.
