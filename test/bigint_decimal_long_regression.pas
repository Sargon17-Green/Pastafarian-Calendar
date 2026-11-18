program bigint_decimal_long_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Stage1: 96 independent decimal parser oracle rows; bounded up to 511 digits. }
uses SysUtils, Classes, BigInt;

const
  ExpectedCases = 96;
  ChecksPerCase = 14;
  ExpectedChecks = ExpectedCases * ChecksPerCase;

var
  Cases, Passed, Failed: Integer;

procedure Check(const LabelText: string; OK: Boolean);
begin
  if OK then Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA caso ', Cases, ': ', LabelText);
  end;
end;

function Canonical(const X: TBigInt): Boolean;
var
  I: Integer;
begin
  if Length(X.Digits) = 0 then Exit(X.Sign = 0);
  if (X.Sign <> -1) and (X.Sign <> 1) then Exit(False);
  if X.Digits[High(X.Digits)] = 0 then Exit(False);
  for I := 0 to High(X.Digits) do
    if UInt64(X.Digits[I]) >= BIG_BASE then Exit(False);
  Result := True;
end;

procedure Mutate(var X: TBigInt);
begin
  if Length(X.Digits) = 0 then
  begin
    SetLength(X.Digits, 1);
    X.Digits[0] := 1;
    X.Sign := 1;
  end
  else
    X.Digits[0] := UInt32((UInt64(X.Digits[0]) + 1) mod BIG_BASE);
end;

procedure CheckCase(const Fields: TStringList);
var
  A, CopyValue: TBigInt;
  Canon, Raw: string;
begin
  if Fields.Count <> 9 then
    raise EConvertError.Create('TSV exige nove campos');
  if not ((Fields[0] = 'ZERO') or (Fields[0] = 'SMALL') or
          (Fields[0] = 'RADIX') or (Fields[0] = 'LONG') or
          (Fields[0] = 'LEADING')) then
    raise EConvertError.Create('Categoria desconhecida');
  Raw := Fields[1];
  Canon := Fields[2];
  A := BigFromDecimal(Raw);
  Check('valor canonico', BigToDecimal(A) = Canon);
  Check('sinal independente', A.Sign = StrToInt(Fields[7]));
  Check('estrutura canonica', Canonical(A));
  Check('numero de limbs', Length(A.Digits) = StrToInt(Fields[8]));
  Check('valor absoluto', BigToDecimal(BigAbs(A)) = Fields[3]);
  Check('negacao', BigToDecimal(BigNegate(A)) = Fields[4]);
  Check('sucessor', BigToDecimal(BigAdd(A, BigOne)) = Fields[5]);
  Check('predecessor', BigToDecimal(BigSubtract(A, BigOne)) = Fields[6]);
  Check('dupla negacao', BigToDecimal(BigNegate(BigNegate(A))) = Canon);
  Check('reparse/comparacao', BigCompare(A, BigFromDecimal(Canon)) = 0);
  Check('reparse/decimal', BigToDecimal(BigFromDecimal(Canon)) = Canon);
  CopyValue := BigClone(A);
  Check('clone inicial', BigToDecimal(CopyValue) = Canon);
  Mutate(CopyValue);
  Check('clone alterado', BigToDecimal(CopyValue) <> Canon);
  Check('isolamento original', BigToDecimal(A) = Canon);
end;

procedure RunVectors;
var
  Input: TextFile;
  Line: string;
  Fields: TStringList;
begin
  Fields := TStringList.Create;
  try
    Fields.Delimiter := #9;
    Fields.StrictDelimiter := True;
    AssignFile(Input, 'bigint_decimal_long_vectors.tsv');
    Reset(Input);
    try
      while not EOF(Input) do
      begin
        ReadLn(Input, Line);
        if Line = '' then Continue;
        Fields.DelimitedText := Line;
        Inc(Cases);
        CheckCase(Fields);
      end;
    finally
      CloseFile(Input);
    end;
  finally
    Fields.Free;
  end;
end;

begin
  Cases := 0; Passed := 0; Failed := 0;
  try
    RunVectors
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo BigFromDecimal longo: ', Cases, ' casos; ', Passed,
          ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or
     (Failed <> 0) then Halt(1);
end.
