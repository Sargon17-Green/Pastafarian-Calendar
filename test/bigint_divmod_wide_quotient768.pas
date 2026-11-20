program bigint_divmod_wide_quotient768;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ 48 Python-int vectors with 768-digit A, 384-digit B and Q.
  Eight checks per pair exercise the direct DivMod API and FloorDiv. }
uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 48;
  ExpectedChecks = 384;

var
  Cases, Passed, Failed: Integer;

procedure Check(const Name: string; OK: Boolean);
begin
  if OK then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA wide quotient768 caso ', Cases, ': ', Name);
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

procedure CheckVector(const F: TStringList);
var
  A, B, Q, R, FloorQ, Rebuilt: TBigInt;
begin
  if F.Count <> 5 then
    raise EConvertError.Create('wide quotient768 TSV exige cinco campos.');
  if not ((F[0] = 'SPARSE_EXACT') or (F[0] = 'SPARSE_ONE') or
          (F[0] = 'DENSE_EXACT') or (F[0] = 'DENSE_MAX_REM') or
          (F[0] = 'NINES_ONE') or (F[0] = 'ALTERNATING_HALF')) then
    raise EConvertError.Create('Grupo wide quotient768 desconhecido.');
  A := BigFromDecimal(F[1]);
  B := BigFromDecimal(F[2]);
  BigDivModPositive(A, B, Q, R);
  FloorQ := BigFloorDivPositive(A, B);
  Rebuilt := BigAdd(BigMultiply(Q, B), R);
  Check('quociente divmod Python-int', BigToDecimal(Q) = F[3]);
  Check('resto divmod Python-int', BigToDecimal(R) = F[4]);
  Check('quociente floor Python-int', BigToDecimal(FloorQ) = F[3]);
  Check('identidade Euclidiana', BigCompare(Rebuilt, A) = 0);
  Check('representacoes canonicas', CanonicalNonnegative(Q) and
        CanonicalNonnegative(R) and CanonicalNonnegative(FloorQ));
  Check('0 <= resto < divisor',
        (BigCompare(R, BigZero) >= 0) and (BigCompare(R, B) < 0));
  Check('dividendo preservado', BigToDecimal(A) = F[1]);
  Check('divisor preservado', BigToDecimal(B) = F[2]);
end;

procedure RunVectors;
var
  InputFile: TextFile;
  Line: string;
  F: TStringList;
begin
  F := TStringList.Create;
  try
    F.Delimiter := #9;
    F.StrictDelimiter := True;
    AssignFile(InputFile, 'bigint_divmod_wide_quotient768.tsv');
    Reset(InputFile);
    try
      while not EOF(InputFile) do
      begin
        ReadLn(InputFile, Line);
        if Line = '' then Continue;
        F.DelimitedText := Line;
        Inc(Cases);
        CheckVector(F);
      end;
    finally
      CloseFile(InputFile);
    end;
  finally
    F.Free;
  end;
end;

begin
  Cases := 0;
  Passed := 0;
  Failed := 0;
  try
    RunVectors;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO wide quotient768: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo BigDivMod wide quotient768: ', Cases, ' casos; ',
          Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
