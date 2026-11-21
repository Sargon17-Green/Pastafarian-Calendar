program bigint_regular_mod_subdivisor;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Branch-only Stage1 QA for the previously uncovered 0<abs(A)<D case.
  Expected q,r are generated independently by Python integers.
  This is not provenance for the original October source patches. }
uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 48;
  ExpectedChecks = 390;

var
  Cases, Passed, Failed: Integer;

procedure Check(const LabelText: string; OK: Boolean);
begin
  if OK then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA subdivisor caso ', Cases, ': ', LabelText);
  end;
end;

function CanonicalPositive(const X: TBigInt): Boolean;
var
  I: Integer;
begin
  if (X.Sign <> 1) or (Length(X.Digits) = 0) then
    Exit(False);
  if X.Digits[High(X.Digits)] = 0 then
    Exit(False);
  for I := 0 to High(X.Digits) do
    if UInt64(X.Digits[I]) >= BIG_BASE then
      Exit(False);
  Result := True;
end;

procedure CheckCase(const F: TStringList);
var
  A, D, OracleQ, R, RMirror, Derived, Rebuilt: TBigInt;
  IsNegative: Boolean;
begin
  if F.Count <> 5 then
    raise EConvertError.Create('TSV exige cinco campos');
  if not ((F[0] = 'POS_TINY') or (F[0] = 'NEG_TINY') or
          (F[0] = 'POS_NEAR') or (F[0] = 'NEG_NEAR')) then
    raise EConvertError.Create('Categoria TSV invalida');
  A := BigFromDecimal(F[1]);
  D := BigFromDecimal(F[2]);
  OracleQ := BigFromDecimal(F[3]);
  IsNegative := A.Sign < 0;
  R := BigRegularModPositive(A, D);
  RMirror := BigRegularModPositive(BigNegate(A), D);
  Rebuilt := BigAdd(BigMultiply(OracleQ, D), R);
  if IsNegative then
    Derived := BigSubtract(D, BigAbs(A))
  else
    Derived := BigClone(A);

  Check('resto Python-int exato', BigToDecimal(R) = F[4]);
  Check('resto estritamente positivo', R.Sign = 1);
  Check('resto canonico base 10^9', CanonicalPositive(R));
  Check('intervalo 0 < R < D', (BigCompare(R, BigZero) > 0) and
    (BigCompare(R, D) < 0));
  Check('A = floor(A/D)*D + R', BigCompare(Rebuilt, A) = 0);
  Check('modulos espelhados somam D', BigCompare(BigAdd(R, RMirror), D) = 0);
  Check('operadores preservados', (BigToDecimal(A) = F[1]) and
    (BigToDecimal(D) = F[2]));
  Check('resto derivado pelo modulo positivo',
    BigCompare(R, Derived) = 0);
end;

procedure ExpectInvalidMod(const AText, DText: string);
var
  Value: TBigInt;
begin
  try
    Value := BigRegularModPositive(BigFromDecimal(AText),
      BigFromDecimal(DText));
    Check('modulo divisor invalido rejeitado', False);
  except
    on E: EDivByZero do Check('modulo divisor invalido rejeitado', True);
    on E: Exception do Check('modulo tipo da excecao', False);
  end;
end;

procedure ExpectInvalidDivMod(const AText, DText: string;
  NegativeDividend: Boolean);
var
  Q, R: TBigInt;
begin
  try
    BigDivModPositive(BigFromDecimal(AText), BigFromDecimal(DText), Q, R);
    Check('divmod dominio invalido rejeitado', False);
  except
    on E: ERangeError do
      Check('divmod negativo rejeitado', NegativeDividend);
    on E: EDivByZero do
      Check('divmod divisor invalido rejeitado', not NegativeDividend);
    on E: Exception do Check('divmod tipo da excecao', False);
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
    Fields.StrictDelimiter := True;
    Fields.Delimiter := #9;
    AssignFile(F, 'bigint_regular_mod_subdivisor.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then Continue;
        Fields.DelimitedText := Line;
        Inc(Cases);
        CheckCase(Fields);
      end;
    finally
      CloseFile(F);
    end;
  finally
    Fields.Free;
  end;
end;

begin
  Cases := 0;
  Passed := 0;
  Failed := 0;
  try
    RunVectors;
    { Six domain checks not covered by the signed TSV oracle. }
    ExpectInvalidMod('1', '0');
    ExpectInvalidMod('-1', '0');
    ExpectInvalidMod('0', '-1');
    ExpectInvalidMod('-1', '-1');
    ExpectInvalidDivMod('-1000000000000000001', '1000000003', True);
    ExpectInvalidDivMod('1', '-7', False);
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo modulo subdivisor: ', Cases, ' casos; ',
    Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
