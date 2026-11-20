program bigint_floor_div_positive_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Independent Stage 1 QA for BigFloorDivPositive.
  Expected quotients and remainders come from Python arbitrary-precision integers. }

uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 96;
  ExpectedChecks = 3043;

var
  Cases, PerturbedCases, DecrementedCases, Passed, Failed: Integer;

procedure Check(const Name: string; OK: Boolean);
begin
  if OK then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA caso ', Cases + PerturbedCases + DecrementedCases, ': ', Name);
  end;
end;

function IsCanonicalNonnegative(const A: TBigInt): Boolean;
var
  I: Integer;
begin
  if A.Sign = 0 then
    Exit(Length(A.Digits) = 0);
  if A.Sign <> 1 then
    Exit(False);
  if Length(A.Digits) = 0 then
    Exit(False);
  if A.Digits[High(A.Digits)] = 0 then
    Exit(False);
  for I := 0 to High(A.Digits) do
    if UInt64(A.Digits[I]) >= BIG_BASE then
      Exit(False);
  Result := True;
end;

procedure CheckVector(const Fields: TStringList);
var
  A, B, Q, Product, NextProduct, Residual: TBigInt;
  ExpectedQ, ExpectedR: string;
begin
  if Fields.Count <> 5 then
    raise EConvertError.Create('TSV exige cinco campos.');
  if not ((Fields[0] = 'SMALL_UNIT') or (Fields[0] = 'LESS') or
          (Fields[0] = 'RADIX') or (Fields[0] = 'EXACT') or
          (Fields[0] = 'MAX_REM') or (Fields[0] = 'DENSE')) then
    raise EConvertError.Create('Grupo desconhecido.');

  A := BigFromDecimal(Fields[1]);
  B := BigFromDecimal(Fields[2]);
  ExpectedQ := Fields[3];
  ExpectedR := Fields[4];

  Q := BigFloorDivPositive(A, B);
  Product := BigMultiply(Q, B);
  NextProduct := BigMultiply(BigAdd(Q, BigOne), B);
  Residual := BigSubtract(A, Product);

  Check('quociente decimal independente', BigToDecimal(Q) = ExpectedQ);
  Check('resto decimal independente', BigToDecimal(Residual) = ExpectedR);
  Check('quociente canonico nao negativo', IsCanonicalNonnegative(Q));
  Check('resto canonico nao negativo', IsCanonicalNonnegative(Residual));
  Check('resto menor que divisor', BigCompare(Residual, B) < 0);
  Check('Q vezes B nao excede A', BigCompare(Product, A) <= 0);
  Check('(Q+1) vezes B excede A', BigCompare(NextProduct, A) > 0);
  Check('dividendo preservado', BigToDecimal(A) = Fields[1]);
  Check('divisor preservado', BigToDecimal(B) = Fields[2]);
  Check('predicado de resto zero', BigIsZero(Residual) = (ExpectedR = '0'));
end;

{ Verify that the quotient has no mutable digit aliases with either input.
  Uses the independently generated quotient oracle from the existing TSV. }
procedure MutateForIsolation(var X: TBigInt);
begin
  if Length(X.Digits) = 0 then
  begin
    X.Sign := 1;
    SetLength(X.Digits, 1);
    X.Digits[0] := 1;
  end
  else if X.Digits[0] = UInt32(BIG_BASE - 1) then
    X.Digits[0] := 0
  else
    X.Digits[0] := X.Digits[0] + 1;
end;

procedure CheckIsolation(const Fields: TStringList);
var
  A, B, Q: TBigInt;
begin
  A := BigFromDecimal(Fields[1]);
  B := BigFromDecimal(Fields[2]);
  Q := BigFloorDivPositive(A, B);
  MutateForIsolation(Q);
  Check('mutacao do quociente preserva dividendo',
    BigToDecimal(A) = Fields[1]);
  Check('mutacao do quociente preserva divisor',
    BigToDecimal(B) = Fields[2]);

  Q := BigFloorDivPositive(A, B);
  MutateForIsolation(A);
  Check('mutacao do dividendo preserva quociente',
    BigToDecimal(Q) = Fields[3]);
  MutateForIsolation(B);
  Check('mutacao do divisor preserva quociente',
    BigToDecimal(Q) = Fields[3]);
end;

{ Stage 1 metamorphic QA on Python-int quotient/remainder oracles:
  floor((A + k*B)/B) = Q + k, residual stays R (k=1,17).
  floor((2*A)/(2*B)) = Q, residual becomes 2*R.
  Inputs remain at most 406 decimal digits before scaling. }
procedure CheckAffineRelations(const Fields: TStringList);
var
  A, B, ExpectedQ, ExpectedR: TBigInt;
  ShiftedA, ShiftedQ, ScaledA, ScaledB, ScaledQ, Residual: TBigInt;
begin
  A := BigFromDecimal(Fields[1]);
  B := BigFromDecimal(Fields[2]);
  ExpectedQ := BigFromDecimal(Fields[3]);
  ExpectedR := BigFromDecimal(Fields[4]);

  ShiftedA := BigAdd(A, B);
  ShiftedQ := BigFloorDivPositive(ShiftedA, B);
  Check('translacao por B: quociente', 
    BigCompare(ShiftedQ, BigAdd(ExpectedQ, BigOne)) = 0);
  Residual := BigSubtract(ShiftedA, BigMultiply(ShiftedQ, B));
  Check('translacao por B: resto', BigCompare(Residual, ExpectedR) = 0);

  ShiftedA := BigAdd(A, BigMultiplyUInt32(B, 17));
  ShiftedQ := BigFloorDivPositive(ShiftedA, B);
  Check('translacao por 17B: quociente',
    BigCompare(ShiftedQ, BigAdd(ExpectedQ, BigFromInt64(17))) = 0);
  Residual := BigSubtract(ShiftedA, BigMultiply(ShiftedQ, B));
  Check('translacao por 17B: resto', BigCompare(Residual, ExpectedR) = 0);

  ScaledA := BigMultiplyUInt32(A, 2);
  ScaledB := BigMultiplyUInt32(B, 2);
  ScaledQ := BigFloorDivPositive(ScaledA, ScaledB);
  Check('escala por dois: quociente', BigCompare(ScaledQ, ExpectedQ) = 0);
  Residual := BigSubtract(ScaledA, BigMultiply(ScaledQ, ScaledB));
  Check('escala por dois: resto',
    BigCompare(Residual, BigMultiplyUInt32(ExpectedR, 2)) = 0);
end;


{ Independent threshold QA derived from Python-int quotient/remainder oracles.
  If A=Q*B+R (0<=R<B), the last dividend with quotient Q is
  L=A+(B-1-R)=(Q+1)*B-1, and the first with quotient Q+1 is
  U=A+(B-R)=(Q+1)*B. These inputs are always nonnegative,
  including B=1 and A=0. The boundary is checked on all 96 vectors. }
procedure CheckQuotientThresholds(const Fields: TStringList);
var
  A, B, ExpectedQ, ExpectedR, MaxR: TBigInt;
  LastA, FirstA, LastQ, FirstQ: TBigInt;
begin
  A := BigFromDecimal(Fields[1]);
  B := BigFromDecimal(Fields[2]);
  ExpectedQ := BigFromDecimal(Fields[3]);
  ExpectedR := BigFromDecimal(Fields[4]);
  MaxR := BigSubtract(B, BigOne);

  LastA := BigAdd(A, BigSubtract(MaxR, ExpectedR));
  LastQ := BigFloorDivPositive(LastA, B);
  Check('limiar anterior: quociente Q',
    BigCompare(LastQ, ExpectedQ) = 0);
  Check('limiar anterior: resto B-1',
    BigCompare(BigSubtract(LastA, BigMultiply(LastQ, B)), MaxR) = 0);

  FirstA := BigAdd(A, BigSubtract(B, ExpectedR));
  FirstQ := BigFloorDivPositive(FirstA, B);
  Check('limiar seguinte: quociente Q+1',
    BigCompare(FirstQ, BigAdd(ExpectedQ, BigOne)) = 0);
  Check('limiar seguinte: resto zero',
    BigIsZero(BigSubtract(FirstA, BigMultiply(FirstQ, B))));
end;


{ The divisor+1 expectations are calculated by Python's divmod(A,B+1),
  without algebraic transformation of the original quotient or remainder.
  The TSV is generated at test execution; it is not a tracked source file. }
procedure CheckPerturbedVector(const Fields: TStringList);
var
  A, B, Q, Residual: TBigInt;
begin
  if Fields.Count <> 5 then
    raise EConvertError.Create('TSV divisor+1 exige cinco campos.');
  if not ((Fields[0] = 'SMALL_UNIT') or (Fields[0] = 'LESS') or
          (Fields[0] = 'RADIX') or (Fields[0] = 'EXACT') or
          (Fields[0] = 'MAX_REM') or (Fields[0] = 'DENSE')) then
    raise EConvertError.Create('Grupo divisor+1 desconhecido.');

  A := BigFromDecimal(Fields[1]);
  B := BigFromDecimal(Fields[2]);
  Q := BigFloorDivPositive(A, B);
  Residual := BigSubtract(A, BigMultiply(Q, B));

  Check('divisor+1: quociente Python-int independente',
    BigToDecimal(Q) = Fields[3]);
  Check('divisor+1: resto Python-int independente',
    BigToDecimal(Residual) = Fields[4]);
  Check('divisor+1: quociente e resto canonicos',
    IsCanonicalNonnegative(Q) and IsCanonicalNonnegative(Residual));
  Check('divisor+1: resto no intervalo [0,B)',
    (BigCompare(Residual, BigZero) >= 0) and
    (BigCompare(Residual, B) < 0));
end;

procedure RunPerturbedVectors;
var
  F: TextFile;
  Line: string;
  Fields: TStringList;
begin
  Fields := TStringList.Create;
  try
    Fields.Delimiter := #9;
    Fields.StrictDelimiter := True;
    AssignFile(F, 'bigint_floor_div_positive_divisor_plus_one.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then
          Continue;
        Fields.DelimitedText := Line;
        Inc(PerturbedCases);
        CheckPerturbedVector(Fields);
      end;
    finally
      CloseFile(F);
    end;
  finally
    Fields.Free;
  end;
end;

{ Python divmod(A,B-1) supplies an independent oracle for positive B-1.
  Exactly eight original B=1 cases are excluded. }
procedure CheckDecrementedVector(const Fields: TStringList);
var
  A, B, Q, Residual: TBigInt;
begin
  if Fields.Count <> 5 then
    raise EConvertError.Create('TSV divisor-1 exige cinco campos.');
  if not ((Fields[0] = 'SMALL_UNIT') or (Fields[0] = 'LESS') or
          (Fields[0] = 'RADIX') or (Fields[0] = 'EXACT') or
          (Fields[0] = 'MAX_REM') or (Fields[0] = 'DENSE')) then
    raise EConvertError.Create('Grupo divisor-1 desconhecido.');

  A := BigFromDecimal(Fields[1]);
  B := BigFromDecimal(Fields[2]);
  Q := BigFloorDivPositive(A, B);
  Residual := BigSubtract(A, BigMultiply(Q, B));

  Check('divisor-1: quociente Python-int independente',
    BigToDecimal(Q) = Fields[3]);
  Check('divisor-1: resto Python-int independente',
    BigToDecimal(Residual) = Fields[4]);
  Check('divisor-1: quociente e resto canonicos',
    IsCanonicalNonnegative(Q) and IsCanonicalNonnegative(Residual));
  Check('divisor-1: resto no intervalo [0,B)',
    (BigCompare(Residual, BigZero) >= 0) and
    (BigCompare(Residual, B) < 0));
end;

procedure RunDecrementedVectors;
var
  F: TextFile;
  Line: string;
  Fields: TStringList;
begin
  Fields := TStringList.Create;
  try
    Fields.Delimiter := #9;
    Fields.StrictDelimiter := True;
    AssignFile(F, 'bigint_floor_div_positive_divisor_minus_one.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then
          Continue;
        Fields.DelimitedText := Line;
        Inc(DecrementedCases);
        CheckDecrementedVector(Fields);
      end;
    finally
      CloseFile(F);
    end;
  finally
    Fields.Free;
  end;
end;

procedure RunVectors;
var
  F: TextFile;
  Line: string;
  Fields: TStringList;
begin
  Fields := TStringList.Create;
  try
    Fields.Delimiter := #9;
    Fields.StrictDelimiter := True;
    AssignFile(F, 'bigint_floor_div_positive_vectors.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then
          Continue;
        Fields.DelimitedText := Line;
        Inc(Cases);
        CheckVector(Fields);
        CheckIsolation(Fields);
        CheckAffineRelations(Fields);
        CheckQuotientThresholds(Fields);
      end;
    finally
      CloseFile(F);
    end;
  finally
    Fields.Free;
  end;
end;

procedure CheckExpectedRangeError;
var
  Q: TBigInt;
  Raised: Boolean;
begin
  Raised := False;
  try
    Q := BigFloorDivPositive(BigFromInt64(-1), BigOne);
  except
    on E: ERangeError do
      Raised := True;
    on E: Exception do
    begin
      Check('dividendo negativo gera ERangeError', False);
      Exit;
    end;
  end;
  Check('dividendo negativo gera ERangeError', Raised);
end;

procedure CheckExpectedDivByZero(const Name: string; const A, B: TBigInt);
var
  Q: TBigInt;
  Raised: Boolean;
begin
  Raised := False;
  try
    Q := BigFloorDivPositive(A, B);
  except
    on E: EDivByZero do
      Raised := True;
    on E: Exception do
    begin
      Check(Name, False);
      Exit;
    end;
  end;
  Check(Name, Raised);
end;

begin
  Cases := 0;
  PerturbedCases := 0;
  DecrementedCases := 0;
  Passed := 0;
  Failed := 0;
  try
    RunVectors;
    RunPerturbedVectors;
    RunDecrementedVectors;
    CheckExpectedRangeError;
    CheckExpectedDivByZero('divisor zero gera EDivByZero', BigOne, BigZero);
    CheckExpectedDivByZero('divisor negativo gera EDivByZero',
      BigOne, BigFromInt64(-1));
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO: ', E.ClassName, ': ', E.Message);
    end;
  end;

  Writeln('Resumo BigFloorDivPositive: ', Cases, ' casos base; ',
    PerturbedCases, ' casos divisor+1; ', DecrementedCases,
    ' casos divisor-1; ', Passed, ' verificacoes OK; ',
    Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (PerturbedCases <> ExpectedCases) or
     (DecrementedCases <> 88) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
