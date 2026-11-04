program bigint_regular_mod_signed_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Independent Stage 1 signed Euclidean-modulo QA.
  Oracle quotient and remainder are checked against Python int.
  Not a reconstruction of the missing October historical patches. }
uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 96;
  ExpectedChecks = 384;

var
  Cases, Passed, Failed: Integer;

procedure Check(const Name: string; Condition: Boolean);
begin
  if Condition then Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA caso ', Cases, ': ', Name);
  end;
end;

function CanonicalRemainder(const R: TBigInt): Boolean;
var
  I: Integer;
begin
  if Length(R.Digits) = 0 then Exit(R.Sign = 0);
  if (R.Sign <> 1) or (R.Digits[High(R.Digits)] = 0) then
    Exit(False);
  for I := 0 to High(R.Digits) do
    if UInt64(R.Digits[I]) >= BIG_BASE then Exit(False);
  Result := True;
end;

procedure CheckCase(const Fields: TStringList);
var
  A, D, R, OracleQ, Rebuilt: TBigInt;
  Category: string;
begin
  if Fields.Count <> 5 then
    raise EConvertError.Create('TSV exige cinco campos');
  Category := Fields[0];
  if not ((Category = 'NEG_EXACT') or (Category = 'NEG_REM') or
          (Category = 'POS') or (Category = 'ZERO')) then
    raise EConvertError.Create('Categoria invalida');
  A := BigFromDecimal(Fields[1]);
  D := BigFromDecimal(Fields[2]);
  OracleQ := BigFromDecimal(Fields[3]);
  R := BigRegularModPositive(A, D);
  Rebuilt := BigAdd(BigMultiply(OracleQ, D), R);

  Check('resto decimal exato', BigToDecimal(R) = Fields[4]);
  Check('intervalo euclidiano', (R.Sign >= 0) and (BigCompare(R,D) < 0));
  Check('A = q*D + r com quociente-oraculo', BigCompare(Rebuilt,A) = 0);
  Check('digitos canonicos de base 10^9', CanonicalRemainder(R));
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
    AssignFile(F, 'bigint_regular_mod_signed_vectors.tsv');
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
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo modulo assinado: ', Cases, ' casos; ',
    Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
