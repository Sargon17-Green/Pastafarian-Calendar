program bigint_regular_mod_zero_unit;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Branch-only Stage 1 edge QA. Python-int generates the quotient and remainder;
  this source does not recover historical October source patches. }
uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 48;
  ExpectedChecks = 384;

var
  Cases, Passed, Failed: Integer;

procedure Check(const Caption: string; OK: Boolean);
begin
  if OK then Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA zero-unit caso ', Cases, ': ', Caption);
  end;
end;

procedure CheckCase(const Fields: TStringList);
var
  A, D, QOracle, R, Rebuilt, ShiftPlus, ShiftMinus: TBigInt;
  Category: string;
begin
  if Fields.Count <> 5 then
    raise EConvertError.Create('TSV requer cinco campos');
  Category := Fields[0];
  if not ((Category = 'UNIT_POS') or (Category = 'UNIT_NEG') or
          (Category = 'ZERO_BELOW') or (Category = 'ZERO_ABOVE')) then
    raise EConvertError.Create('Categoria invalida');
  A := BigFromDecimal(Fields[1]);
  D := BigFromDecimal(Fields[2]);
  QOracle := BigFromDecimal(Fields[3]);
  R := BigRegularModPositive(A, D);
  Rebuilt := BigAdd(BigMultiply(QOracle, D), R);
  ShiftPlus := BigRegularModPositive(BigAdd(A, D), D);
  ShiftMinus := BigRegularModPositive(BigSubtract(A, D), D);

  Check('resto exato Python-int', BigToDecimal(R) = Fields[4]);
  Check('sinal zero canonico', R.Sign = 0);
  Check('nenhum digito para zero', Length(R.Digits) = 0);
  Check('intervalo 0 <= R < D', (BigCompare(R, BigZero) >= 0) and
    (BigCompare(R, D) < 0));
  Check('identidade A=Q*D+R', BigCompare(Rebuilt, A) = 0);
  Check('invariancia A+D', BigCompare(ShiftPlus, R) = 0);
  Check('invariancia A-D', BigCompare(ShiftMinus, R) = 0);
  Check('operandos preservados', (BigToDecimal(A) = Fields[1]) and
    (BigToDecimal(D) = Fields[2]));
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
    AssignFile(F, 'bigint_regular_mod_zero_unit.tsv');
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
  Writeln('Resumo modulo zero-unit: ', Cases, ' casos; ',
    Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
