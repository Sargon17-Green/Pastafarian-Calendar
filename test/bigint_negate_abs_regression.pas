program bigint_negate_abs_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Independent Python-int TSV oracle plus mutation-isolation / canonical-form
  assertions. No expected value is computed via the Pascal BigInt operators. }
uses SysUtils, Classes, BigInt;

const
  ExpectedCases = 96;
  ChecksPerOperation = 12;
  ExpectedChecks = ExpectedCases * ChecksPerOperation * 2;

type
  TOperation = (opNegate, opAbs);

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

function Apply(const X: TBigInt; Op: TOperation): TBigInt;
begin
  if Op = opNegate then Result := BigNegate(X)
  else Result := BigAbs(X);
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
  begin
    { Direct limb edit detects shallow dynamic-array clones. }
    X.Digits[0] := UInt32((UInt64(X.Digits[0]) + 1) mod BIG_BASE);
    X.Sign := -X.Sign;
  end;
end;

procedure Audit(const Source, Wanted, DoubleWanted: string; Op: TOperation);
var
  A, AliasInput, R, Again: TBigInt;
begin
  A := BigFromDecimal(Source);
  Check('entrada canonica', Canonical(A));
  R := Apply(A, Op);
  Check('resultado numerico independente', BigToDecimal(R) = Wanted);
  Check('resultado canonico', Canonical(R));
  Check('entrada preservada apos chamada', BigToDecimal(A) = Source);
  Again := Apply(R, Op);
  Check('involucao ou idempotencia', BigToDecimal(Again) = DoubleWanted);
  Check('composicao canonica', Canonical(Again));

  Mutate(R);
  Check('mutacao do retorno efetiva', BigToDecimal(R) <> Wanted);
  Check('mutacao do retorno preserva entrada', BigToDecimal(A) = Source);

  R := Apply(A, Op);
  Mutate(A);
  Check('mutacao da entrada efetiva', BigToDecimal(A) <> Source);
  Check('mutacao da entrada preserva retorno', BigToDecimal(R) = Wanted);

  A := BigFromDecimal(Source);
  AliasInput := A;
  R := Apply(A, Op);
  Mutate(AliasInput);
  Check('mutacao de alias efetiva', BigToDecimal(AliasInput) <> Source);
  Check('retorno separado de alias da entrada', BigToDecimal(R) = Wanted);
end;

procedure CheckCase(const Fields: TStringList);
begin
  if Fields.Count <> 4 then
    raise EConvertError.Create('TSV precisa de quatro campos');
  if not ((Fields[0] = 'ZERO') or (Fields[0] = 'TIE') or
          (Fields[0] = 'SMALL') or (Fields[0] = 'RADIX_LO') or
          (Fields[0] = 'RADIX_HI') or (Fields[0] = 'LONG')) then
    raise EConvertError.Create('Categoria desconhecida');
  Audit(Fields[1], Fields[2], Fields[1], opNegate);
  Audit(Fields[1], Fields[3], Fields[3], opAbs);
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
    AssignFile(F, 'bigint_negate_abs_vectors.tsv');
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
    RunVectors
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo BigNegate/BigAbs: ', Cases, ' casos; ', Passed,
          ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
