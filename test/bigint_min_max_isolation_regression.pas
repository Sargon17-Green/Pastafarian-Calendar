program bigint_min_max_isolation_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Isolation contract for BigMin/BigMax: a returned value must not share
  mutable limbs with either input, including calls with the same input twice.
  Expected numeric selections come from independently verified Python-int TSV. }
uses SysUtils, Classes, BigInt;

const
  ExpectedCases = 96;
  ChecksPerCase = 42;
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
    { Direct limb mutation exposes shallow copies of dynamic arrays.
      Also flip the sign so the change is observable on every nonzero case. }
    X.Digits[0] := UInt32((UInt64(X.Digits[0]) + 1) mod BIG_BASE);
    X.Sign := -X.Sign;
  end;
end;

procedure Audit(const SA, SB, Wanted: string; DoMin, SwapInputs: Boolean);
var
  A, B, R: TBigInt;
begin
  A := BigFromDecimal(SA);
  B := BigFromDecimal(SB);

  if DoMin then
  begin
    if SwapInputs then R := BigMin(B, A)
    else R := BigMin(A, B);
  end
  else
  begin
    if SwapInputs then R := BigMax(B, A)
    else R := BigMax(A, B);
  end;
  Check('resultado inicial', BigToDecimal(R) = Wanted);
  Mutate(R);
  Check('mutacao do retorno e efetiva', BigToDecimal(R) <> Wanted);
  Check('retorno nao altera entrada A', BigToDecimal(A) = SA);
  Check('retorno nao altera entrada B', BigToDecimal(B) = SB);

  if DoMin then
  begin
    if SwapInputs then R := BigMin(B, A)
    else R := BigMin(A, B);
  end
  else
  begin
    if SwapInputs then R := BigMax(B, A)
    else R := BigMax(A, B);
  end;
  Mutate(A);
  Check('mutacao A e efetiva', BigToDecimal(A) <> SA);
  Check('mutacao A nao altera retorno', BigToDecimal(R) = Wanted);
  Mutate(B);
  Check('mutacao B e efetiva', BigToDecimal(B) <> SB);
  Check('mutacao B nao altera retorno', BigToDecimal(R) = Wanted);
end;

procedure AuditSameInput(const S: string; DoMin: Boolean);
var
  A, R: TBigInt;
begin
  A := BigFromDecimal(S);
  if DoMin then R := BigMin(A, A)
  else R := BigMax(A, A);
  Check('mesma entrada: valor inicial', BigToDecimal(R) = S);
  Mutate(R);
  Check('mesma entrada: mutacao do retorno efetiva', BigToDecimal(R) <> S);
  Check('mesma entrada: entrada preservada', BigToDecimal(A) = S);

  if DoMin then R := BigMin(A, A)
  else R := BigMax(A, A);
  Mutate(A);
  Check('mesma entrada: mutacao da entrada efetiva', BigToDecimal(A) <> S);
  Check('mesma entrada: retorno preservado', BigToDecimal(R) = S);
end;

procedure CheckCase(const Fields: TStringList);
begin
  if Fields.Count <> 5 then
    raise EConvertError.Create('TSV precisa de cinco campos');
  Audit(Fields[1], Fields[2], Fields[3], True, False);
  Audit(Fields[1], Fields[2], Fields[4], False, False);
  Audit(Fields[1], Fields[2], Fields[3], True, True);
  Audit(Fields[1], Fields[2], Fields[4], False, True);
  AuditSameInput(Fields[1], True);
  AuditSameInput(Fields[2], False);
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
    AssignFile(F, 'bigint_min_max_vectors.tsv');
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
  Writeln('Resumo BigMin/BigMax isolamento: ', Cases,
          ' casos; ', Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or
     (Passed <> ExpectedChecks) or (Failed <> 0) then Halt(1);
end.
