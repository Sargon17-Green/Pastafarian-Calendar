program bigint_scalar_square_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Independent Stage 1 QA for Int64/UInt32 scalar multiplication and square.
  TSV results are checked by Python unbounded integers before native tests.
  These are new tests, not a reconstruction of October source patches. }
uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 128;
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
    Writeln('FALHA caso ', Cases, ': ', Name);
  end;
end;

function IsCanonical(const A: TBigInt): Boolean;
var
  I: Integer;
begin
  if A.Sign = 0 then
    Exit(Length(A.Digits) = 0);
  if (A.Sign <> -1) and (A.Sign <> 1) then
    Exit(False);
  if Length(A.Digits) = 0 then
    Exit(False);
  if A.Digits[High(A.Digits)] = 0 then
    Exit(False);
  for I := 0 to High(A.Digits) do
    if UInt64(A.Digits[I]) >= BIG_BASE then
      Exit(False);
  Result := True;
end;

procedure CheckVector(const Fields: TStringList);
var
  A, Actual, Alternate: TBigInt;
  Scalar64: Int64;
  Scalar32: QWord;
  Kind: string;
begin
  if Fields.Count <> 4 then
    raise EConvertError.Create('TSV: quatro campos obrigatorios.');
  Kind := Fields[0];
  A := BigFromDecimal(Fields[1]);
  if Kind = 'M' then
  begin
    Scalar64 := StrToInt64(Fields[2]);
    Actual := BigMultiplyInt64(A, Scalar64);
    Alternate := BigMultiply(A, BigFromInt64(Scalar64));
  end
  else if Kind = 'U' then
  begin
    Scalar32 := StrToQWord(Fields[2]);
    if Scalar32 > High(UInt32) then
      raise ERangeError.Create('Escalar UInt32 invalido.');
    Actual := BigMultiplyUInt32(A, UInt32(Scalar32));
    Alternate := BigMultiply(A, BigFromUInt64(Scalar32));
  end
  else if Kind = 'S' then
  begin
    if Fields[2] <> '0' then
      raise EConvertError.Create('O campo escalar de quadrado deve ser zero.');
    Actual := BigSquare(A);
    Alternate := BigMultiply(A, A);
  end
  else
    raise EConvertError.Create('Operacao desconhecida.');

  Check('resultado decimal contra oracle', BigToDecimal(Actual) = Fields[3]);
  Check('equivalencia interna multiplicativa', BigCompare(Actual, Alternate) = 0);
  Check('todos os digitos na base canonica', IsCanonical(Actual));
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
    AssignFile(F, 'bigint_scalar_square_vectors.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then
          Continue;
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
    RunVectors;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo escalar/quadrado: ', Cases, ' casos; ',
    Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
