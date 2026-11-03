program bigint_input_contract_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Stage 1 input-domain and representation contract.
  Independent expected values are checked with Python integer arithmetic.
  This is NOT a reconstruction of the historical October patches. }

uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 88;
  ExpectedAssertions = 186;

var
  Passed, Failed, Cases: Integer;

procedure AssertTrue(const LabelText: string; Condition: Boolean);
begin
  if Condition then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA: ', LabelText);
  end;
end;

procedure CheckCanonical(const InputValue, ExpectedValue: string);
var
  A: TBigInt;
  ExpectedSign: ShortInt;
  NormalStructure: Boolean;
begin
  A := BigFromDecimal(InputValue);
  if ExpectedValue = '0' then
    ExpectedSign := 0
  else if ExpectedValue[1] = '-' then
    ExpectedSign := -1
  else
    ExpectedSign := 1;
  NormalStructure := (Length(A.Digits) = 0);
  if ExpectedSign <> 0 then NormalStructure := Length(A.Digits) > 0;
  AssertTrue('decimal canonico ' + InputValue,
    BigToDecimal(A) = ExpectedValue);
  AssertTrue('sinal canonico ' + InputValue,
    A.Sign = ExpectedSign);
  AssertTrue('estrutura do zero ' + InputValue,
    NormalStructure);
  AssertTrue('dupla negacao ' + InputValue,
    BigToDecimal(BigNegate(BigNegate(A))) = ExpectedValue);
end;

procedure CheckInvalidDecimal(const InputValue: string);
var
  A: TBigInt;
  Caught: Boolean;
begin
  Caught := False;
  try
    A := BigFromDecimal(InputValue);
    Writeln('Entrada indevida aceita: ', BigToDecimal(A));
  except
    on E: EConvertError do Caught := True;
    on E: Exception do
      Writeln('Excecao inesperada: ', E.ClassName);
  end;
  AssertTrue('decimal invalido', Caught);
end;

procedure CheckInvalidDivisor(const Numerator, Denominator: string);
var
  A, D, Q, R: TBigInt;
  Caught: Boolean;
begin
  A := BigFromDecimal(Numerator);
  D := BigFromDecimal(Denominator);
  Caught := False;
  try
    BigDivModPositive(A, D, Q, R);
  except
    on E: EDivByZero do Caught := True;
    on E: Exception do
      Writeln('DivMod excecao inesperada: ', E.ClassName);
  end;
  AssertTrue('divisor nao positivo em DivMod', Caught);
  Caught := False;
  try
    R := BigRegularModPositive(A, D);
  except
    on E: EDivByZero do Caught := True;
    on E: Exception do
      Writeln('Modulo excecao inesperada: ', E.ClassName);
  end;
  AssertTrue('divisor nao positivo em modulo', Caught);
end;

procedure CheckInvalidDividend(const Numerator, Denominator: string);
var
  A, D, Q, R: TBigInt;
  Caught: Boolean;
begin
  A := BigFromDecimal(Numerator);
  D := BigFromDecimal(Denominator);
  Caught := False;
  try
    BigDivModPositive(A, D, Q, R);
  except
    on E: ERangeError do Caught := True;
    on E: Exception do
      Writeln('Dividendo excecao inesperada: ', E.ClassName);
  end;
  AssertTrue('dividendo negativo em DivMod', Caught);
end;

procedure CheckModulo(const Numerator, Denominator, ExpectedValue: string);
var
  A, D, R: TBigInt;
begin
  A := BigFromDecimal(Numerator);
  D := BigFromDecimal(Denominator);
  R := BigRegularModPositive(A, D);
  AssertTrue('modulo euclidiano valor', BigToDecimal(R) = ExpectedValue);
  AssertTrue('modulo euclidiano limites',
    (R.Sign >= 0) and (BigCompare(R, D) < 0));
end;

procedure RunVectors;
var
  F: TextFile;
  Line, A, B, ExpectedValue: string;
  Parts: TStringList;
begin
  Parts := TStringList.Create;
  try
    Parts.Delimiter := #9;
    Parts.StrictDelimiter := True;
    AssignFile(F, 'bigint_input_contract_vectors.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then Continue;
        Parts.DelimitedText := Line;
        if Parts.Count <> 4 then
          raise EConvertError.Create('Vetor TSV com numero incorreto de campos.');
        Inc(Cases);
        A := Parts[1];
        B := Parts[2];
        ExpectedValue := Parts[3];
        if A = '@EMPTY@' then A := '';
        case Parts[0][1] of
          'C': CheckCanonical(A, ExpectedValue);
          'E': CheckInvalidDecimal(A);
          'X': CheckInvalidDivisor(A, B);
          'N': CheckInvalidDividend(A, B);
          'R': CheckModulo(A, B, ExpectedValue);
        else
          raise EConvertError.Create('Tipo de vetor desconhecido.');
        end;
      end;
    finally
      CloseFile(F);
    end;
  finally
    Parts.Free;
  end;
end;

begin
  Passed := 0;
  Failed := 0;
  Cases := 0;
  try
    RunVectors;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO FATAL: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo contrato de entrada: ', Cases, ' casos; ',
    Passed, ' assercoes passaram; ', Failed, ' falharam.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedAssertions)
    or (Failed <> 0) then Halt(1);
end.
