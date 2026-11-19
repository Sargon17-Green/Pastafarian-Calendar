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
  ExpectedChecks = 1347;

var
  Cases, Passed, Failed: Integer;

procedure Check(const Name: string; OK: Boolean);
begin
  if OK then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA caso ', Cases, ': ', Name);
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
  Passed := 0;
  Failed := 0;
  try
    RunVectors;
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

  Writeln('Resumo BigFloorDivPositive: ', Cases, ' casos; ',
    Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
