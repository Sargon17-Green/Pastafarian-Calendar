program bigint_from_uint64_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Independent Python-int fixture, canonical limbs, roundtrip and deep-clone QA. }
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

function Canonical(const X: TBigInt): Boolean;
var
  I: Integer;
begin
  if Length(X.Digits) = 0 then Exit(X.Sign = 0);
  if (X.Sign <> 1) and (X.Sign <> -1) then Exit(False);
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
  Value, Rebuilt: UInt64;
  A, Parsed, Clone, PlusOne: TBigInt;
  I: Integer;
begin
  if Fields.Count <> 4 then
    raise EConvertError.Create('TSV precisa de quatro campos');
  if not ((Fields[0] = 'ZERO') or (Fields[0] = 'SMALL') or
          (Fields[0] = 'RADIX') or (Fields[0] = 'POW2') or
          (Fields[0] = 'MAX')) then
    raise EConvertError.Create('Categoria desconhecida');
  Value := StrToQWord('$' + Fields[1]);
  A := BigFromUInt64(Value);
  Check('decimal do construtor', BigToDecimal(A) = Fields[2]);
  Check('representacao canonica', Canonical(A));
  Check('ate tres limbs', Length(A.Digits) <= 3);
  Check('sinal do UInt64', ((Value = 0) and (A.Sign = 0)) or
                         ((Value <> 0) and (A.Sign = 1)));
  Parsed := BigFromDecimal(Fields[2]);
  Check('igualdade com parser independente', BigCompare(A, Parsed) = 0);
  Check('parser preserva decimal', BigToDecimal(Parsed) = Fields[2]);
  Clone := BigClone(A);
  Check('clone antes de mutacao', BigToDecimal(Clone) = Fields[2]);
  Mutate(Clone);
  Check('mutacao de clone efetiva', BigToDecimal(Clone) <> Fields[2]);
  Check('construtor isolado de clone', BigToDecimal(A) = Fields[2]);
  PlusOne := BigAdd(A, BigOne);
  Check('sucessor por oracle Python', BigToDecimal(PlusOne) = Fields[3]);
  Check('sucessor canonico', Canonical(PlusOne));
  Rebuilt := 0;
  for I := High(A.Digits) downto 0 do
    Rebuilt := Rebuilt * BIG_BASE + UInt64(A.Digits[I]);
  Check('recomposicao de limbs em UInt64', Rebuilt = Value);
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
    AssignFile(F, 'bigint_from_uint64_vectors.tsv');
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
  Writeln('Resumo BigFromUInt64: ', Cases, ' casos; ', Passed,
          ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
