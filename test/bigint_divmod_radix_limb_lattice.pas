program bigint_divmod_radix_limb_lattice;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Independent Python-int oracle for quotient limbs 0 and 10^9-1,
  radix-adjacent divisors, remainder=0/max/near-boundary.
  This is new QA; it does not authenticate 2026-10-12/13 source patches. }
uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 48;
  ChecksPerCase = 10;
  ExpectedChecks = ExpectedCases * ChecksPerCase;

var
  Cases, Passed, Failed: Integer;

procedure Check(const LabelText: string; OK: Boolean);
begin
  if OK then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA radix lattice caso ', Cases, ': ', LabelText);
  end;
end;

function CanonicalNonnegative(const X: TBigInt): Boolean;
var
  I: Integer;
begin
  if X.Sign = 0 then
    Exit(Length(X.Digits) = 0);
  if (X.Sign <> 1) or (Length(X.Digits) = 0) then
    Exit(False);
  if X.Digits[High(X.Digits)] = 0 then
    Exit(False);
  for I := 0 to High(X.Digits) do
    if UInt64(X.Digits[I]) >= BIG_BASE then
      Exit(False);
  Result := True;
end;

function HasQuotientLattice(const Q: TBigInt): Boolean;
var
  I: Integer;
  HasZero, HasMax: Boolean;
begin
  if (Length(Q.Digits) < 11) or (Length(Q.Digits) > 18) then
    Exit(False);
  HasZero := False;
  HasMax := False;
  for I := 0 to High(Q.Digits) - 1 do
  begin
    if Q.Digits[I] = 0 then HasZero := True;
    if UInt64(Q.Digits[I]) = BIG_BASE - 1 then HasMax := True;
  end;
  Result := HasZero and HasMax;
end;

procedure CheckVector(const F: TStringList);
var
  A, B, Q, R, FloorQ, Rebuilt: TBigInt;
begin
  if F.Count <> 5 then
    raise EConvertError.Create('TSV radix lattice exige cinco campos.');
  if not ((F[0] = 'ZERO_GAPS') or (F[0] = 'MAX_RUN') or
          (F[0] = 'CROSS_SPAN') or (F[0] = 'BELOW_POWER') or
          (F[0] = 'ABOVE_POWER') or (F[0] = 'R_NEAR_POWER')) then
    raise EConvertError.Create('Grupo radix lattice desconhecido.');
  A := BigFromDecimal(F[1]);
  B := BigFromDecimal(F[2]);
  BigDivModPositive(A, B, Q, R);
  FloorQ := BigFloorDivPositive(A, B);
  Rebuilt := BigAdd(BigMultiply(Q, B), R);
  Check('quociente Python-int', BigToDecimal(Q) = F[3]);
  Check('resto Python-int', BigToDecimal(R) = F[4]);
  Check('piso Python-int', BigToDecimal(FloorQ) = F[3]);
  Check('identidade euclidiana', BigCompare(Rebuilt, A) = 0);
  Check('intervalo do resto', (BigCompare(R, BigZero) >= 0) and
        (BigCompare(R, B) < 0));
  Check('quociente canonico', CanonicalNonnegative(Q));
  Check('resto canonico', CanonicalNonnegative(R));
  Check('dividendo preservado', BigToDecimal(A) = F[1]);
  Check('divisor preservado', BigToDecimal(B) = F[2]);
  Check('limbos zero/max internos', HasQuotientLattice(Q));
end;

procedure ExecuteVectors;
var
  F: TextFile;
  Line: string;
  Fields: TStringList;
begin
  Fields := TStringList.Create;
  try
    Fields.Delimiter := #9;
    Fields.StrictDelimiter := True;
    AssignFile(F, 'bigint_divmod_radix_limb_lattice.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then Continue;
        Fields.DelimitedText := Line;
        Inc(Cases);
        CheckVector(Fields);
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
    ExecuteVectors;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO radix lattice: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo BigDivMod radix lattice: ', Cases, ' casos; ',
          Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
