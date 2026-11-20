program bigint_floor_div_positive_boundary512;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Independent Python-int divmod(A,B) oracle: 96 cases, 4 checks each.
  Valid input domain is A>=0, B>0, each at most 512 decimal digits. }
uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 96;
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
    Writeln('FALHA boundary512 caso ', Cases, ': ', Name);
  end;
end;

function CanonicalNonnegative(const X: TBigInt): Boolean;
var
  I: Integer;
begin
  if X.Sign = 0 then
    Exit(Length(X.Digits) = 0);
  if (X.Sign <> 1) or (Length(X.Digits) = 0) then
    Exit(False);
  if X.Digits[High(X.Digits)] = 0 then
    Exit(False);
  for I := 0 to High(X.Digits) do
    if UInt64(X.Digits[I]) >= BIG_BASE then
      Exit(False);
  Result := True;
end;

procedure CheckVector(const F: TStringList);
var
  A, B, Q, R: TBigInt;
begin
  if F.Count <> 5 then
    raise EConvertError.Create('boundary512 TSV exige cinco campos.');
  if not ((F[0] = 'ZERO_SMALL') or (F[0] = 'LESS_THAN') or
          (F[0] = 'RADIX_EDGE') or (F[0] = 'EXACT') or
          (F[0] = 'MAX_REM') or (F[0] = 'DENSE')) then
    raise EConvertError.Create('Grupo boundary512 desconhecido.');
  A := BigFromDecimal(F[1]);
  B := BigFromDecimal(F[2]);
  Q := BigFloorDivPositive(A, B);
  R := BigSubtract(A, BigMultiply(Q, B));
  Check('quociente Python-int', BigToDecimal(Q) = F[3]);
  Check('resto Python-int', BigToDecimal(R) = F[4]);
  Check('representacao canonica', CanonicalNonnegative(Q) and CanonicalNonnegative(R));
  Check('0 <= resto < divisor',
    (BigCompare(R, BigZero) >= 0) and (BigCompare(R, B) < 0));
end;

procedure RunVectors;
var
  InputFile: TextFile;
  Line: string;
  F: TStringList;
begin
  F := TStringList.Create;
  try
    F.Delimiter := #9;
    F.StrictDelimiter := True;
    AssignFile(InputFile, 'bigint_floor_div_positive_boundary512.tsv');
    Reset(InputFile);
    try
      while not EOF(InputFile) do
      begin
        ReadLn(InputFile, Line);
        if Line = '' then Continue;
        F.DelimitedText := Line;
        Inc(Cases);
        CheckVector(F);
      end;
    finally
      CloseFile(InputFile);
    end;
  finally
    F.Free;
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
      Writeln('EXCECAO boundary512: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo BigFloorDivPositive boundary512: ', Cases, ' casos; ',
          Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks) or (Failed <> 0) then
    Halt(1);
end.
