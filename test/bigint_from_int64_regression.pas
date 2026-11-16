program bigint_from_int64_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Signed Int64 constructor: independent Python-int oracle, canonical shape,
  exact round-trip, opposite, magnitude, successor, and clone isolation. }
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
  Value: Int64;
  A, Parsed, Clone, Magnitude, Opposite, Successor: TBigInt;
begin
  if Fields.Count <> 5 then
    raise EConvertError.Create('TSV precisa de cinco campos');
  if not ((Fields[0] = 'ZERO') or (Fields[0] = 'SMALL') or
          (Fields[0] = 'RADIX') or (Fields[0] = 'POW2') or
          (Fields[0] = 'LIMIT')) then
    raise EConvertError.Create('Categoria desconhecida');
  Value := StrToInt64(Fields[1]);
  A := BigFromInt64(Value);
  Check('decimal do construtor', BigToDecimal(A) = Fields[1]);
  Check('representacao canonica', Canonical(A));
  Check('sinal exato', ((Value = 0) and (A.Sign = 0)) or
        ((Value < 0) and (A.Sign = -1)) or
        ((Value > 0) and (A.Sign = 1)));
  Check('ate tres limbs', Length(A.Digits) <= 3);
  Parsed := BigFromDecimal(Fields[1]);
  Check('comparacao com parser decimal', BigCompare(A, Parsed) = 0);
  Check('parser preserva decimal', BigToDecimal(Parsed) = Fields[1]);
  Magnitude := BigAbs(A);
  Check('magnitude por oracle Python', BigToDecimal(Magnitude) = Fields[2]);
  Opposite := BigNegate(A);
  Check('oposto por oracle Python', BigToDecimal(Opposite) = Fields[3]);
  Successor := BigAdd(A, BigOne);
  Check('sucessor por oracle Python', BigToDecimal(Successor) = Fields[4]);
  Check('sucessor canonico', Canonical(Successor));
  Check('round-trip Int64', BigToInt64Exact(A) = Value);
  Clone := BigClone(A);
  Check('clone antes de mutacao', BigToDecimal(Clone) = Fields[1]);
  Mutate(Clone);
  Check('mutacao de clone efetiva', BigToDecimal(Clone) <> Fields[1]);
  Check('construtor isolado de clone', BigToDecimal(A) = Fields[1]);
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
    AssignFile(F, 'bigint_from_int64_vectors.tsv');
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
  Writeln('Resumo BigFromInt64: ', Cases, ' casos; ', Passed,
          ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
