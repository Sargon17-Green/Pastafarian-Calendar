program bigint_to_decimal_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$ENDIF}
{ Stage 1: independent Python-int oracle; direct canonical limbs to decimal. }
uses SysUtils, Classes, BigInt;

const
  ExpectedCases = 96;
  ChecksPerCase = 12;
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

function IsCanonical(const A: TBigInt): Boolean;
var
  I: Integer;
begin
  if Length(A.Digits) = 0 then Exit(A.Sign = 0);
  if (A.Sign <> -1) and (A.Sign <> 1) then Exit(False);
  if A.Digits[High(A.Digits)] = 0 then Exit(False);
  for I := 0 to High(A.Digits) do
    if UInt64(A.Digits[I]) >= BIG_BASE then Exit(False);
  Result := True;
end;

procedure CheckCase(const Fields: TStringList);
var
  A, CloneValue: TBigInt;
  Parts: TStringList;
  I: Integer;
  ExpectedText, AbsoluteText, NegativeText: string;
begin
  if Fields.Count <> 7 then
    raise EConvertError.Create('TSV exige sete campos');
  if not ((Fields[0] = 'SMALL') or (Fields[0] = 'RADIX') or
          (Fields[0] = 'SPARSE') or (Fields[0] = 'DENSE')) then
    raise EConvertError.Create('Grupo desconhecido');
  Parts := TStringList.Create;
  try
    Parts.Delimiter := ',';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := Fields[2];
    A.Sign := StrToInt(Fields[1]);
    SetLength(A.Digits, Parts.Count);
    for I := 0 to Parts.Count - 1 do
      A.Digits[I] := UInt32(StrToQWord(Parts[I]));

    ExpectedText := Fields[3];
    AbsoluteText := Fields[4];
    NegativeText := Fields[5];

    Check('formato decimal independente', BigToDecimal(A) = ExpectedText);
    Check('valor absoluto', BigToDecimal(BigAbs(A)) = AbsoluteText);
    Check('negativo', BigToDecimal(BigNegate(A)) = NegativeText);
    Check('sinal', A.Sign = StrToInt(Fields[1]));
    Check('numero de limbs', Length(A.Digits) = StrToInt(Fields[6]));
    Check('representacao canonica', IsCanonical(A));
    Check('comparacao com reparsing', BigCompare(A, BigFromDecimal(ExpectedText)) = 0);
    Check('ida e volta', BigToDecimal(BigFromDecimal(ExpectedText)) = ExpectedText);
    CloneValue := BigClone(A);
    Check('clone antes da mutacao', BigToDecimal(CloneValue) = ExpectedText);
    CloneValue.Digits[0] := UInt32((UInt64(CloneValue.Digits[0]) + 1) mod BIG_BASE);
    Check('clone alterado', BigToDecimal(CloneValue) <> ExpectedText);
    Check('original sem alias', BigToDecimal(A) = ExpectedText);
    Check('somar zero', BigToDecimal(BigAdd(A, BigZero)) = ExpectedText);
  finally
    Parts.Free;
  end;
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
    AssignFile(Input, 'bigint_to_decimal_vectors.tsv');
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
  Writeln('Resumo BigToDecimal: ', Cases, ' casos; ', Passed,
          ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or
     (Failed <> 0) then Halt(1);
end.
