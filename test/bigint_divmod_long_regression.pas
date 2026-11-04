program bigint_divmod_long_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Stage 1 independent long-operand DivMod QA.
  Fixed TSV expectations are validated by Python int divmod before execution.
  No claim of reconstructing the original historical October patches. }
uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 96;
  ExpectedChecks = 384;

var
  Passed, Failed, Cases: Integer;

procedure Check(const Name: string; Condition: Boolean);
begin
  if Condition then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA caso ', Cases, ' - ', Name);
  end;
end;

procedure CheckCase(const Parts: TStringList);
var
  A, B, Q, R, Rebuilt: TBigInt;
  Category: string;
begin
  if Parts.Count <> 5 then
    raise EConvertError.Create('TSV: cinco campos obrigatorios');
  Category := Parts[0];
  if not ((Category = 'LT') or (Category = 'EQ') or
          (Category = 'ONE') or (Category = 'EXACT') or
          (Category = 'REM') or (Category = 'LIMB')) then
    raise EConvertError.Create('Categoria TSV invalida');
  A := BigFromDecimal(Parts[1]);
  B := BigFromDecimal(Parts[2]);
  BigDivModPositive(A, B, Q, R);
  Rebuilt := BigAdd(BigMultiply(Q, B), R);

  Check('quociente exato', BigToDecimal(Q) = Parts[3]);
  Check('resto exato', BigToDecimal(R) = Parts[4]);
  Check('identidade A = Q*B + R', BigCompare(Rebuilt, A) = 0);
  Check('resto no intervalo [0,B)',
    (R.Sign >= 0) and (BigCompare(R, B) < 0));
end;

procedure ExecuteVectors;
var
  F: TextFile;
  Line: string;
  Parts: TStringList;
begin
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := #9;
    AssignFile(F, 'bigint_divmod_long_vectors.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then Continue;
        Parts.DelimitedText := Line;
        Inc(Cases);
        CheckCase(Parts);
      end;
    finally
      CloseFile(F);
    end;
  finally
    Parts.Free;
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
      Writeln('EXCECAO: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo DivMod longo: ', Cases, ' casos; ', Passed,
    ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
