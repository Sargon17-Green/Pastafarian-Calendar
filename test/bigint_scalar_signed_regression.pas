program bigint_scalar_signed_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Independent Python-int fixture; scalar Int64 API differential. }
uses SysUtils, Classes, BigInt;
const ExpectedCases=96; ExpectedChecks=384;
var Cases, Passed, Failed: Integer;
procedure Check(const Name: string; Condition: Boolean);
begin
  if Condition then Inc(Passed) else begin
    Inc(Failed); Writeln('FALHA caso ',Cases,': ',Name);
  end;
end;
function Canonical(const X: TBigInt): Boolean;
var I: Integer;
begin
  if Length(X.Digits)=0 then Exit(X.Sign=0);
  if ((X.Sign<>1) and (X.Sign<>-1)) or
     (X.Digits[High(X.Digits)]=0) then Exit(False);
  for I:=0 to High(X.Digits) do
    if UInt64(X.Digits[I])>=BIG_BASE then Exit(False);
  Result:=True;
end;
procedure TestCase(const F: TStringList);
var A, SumValue, Difference: TBigInt; B: Int64;
begin
  if F.Count<>5 then raise EConvertError.Create('TSV: cinco campos obrigatorios');
  if not ((F[0]='MIN_EDGE') or (F[0]='MAX_EDGE') or
          (F[0]='NEAR_ZERO') or (F[0]='RADIX_BOUND') or
          (F[0]='BORROW_CARRY') or (F[0]='SIGN_CANCEL')) then
    raise EConvertError.Create('Categoria invalida');
  A:=BigFromDecimal(F[1]);
  B:=StrToInt64(F[2]);
  SumValue:=BigAddInt64(A,B);
  Difference:=BigSubtractInt64(A,B);
  Check('soma decimal',BigToDecimal(SumValue)=F[3]);
  Check('soma canonica radix 10^9',Canonical(SumValue));
  Check('diferenca decimal',BigToDecimal(Difference)=F[4]);
  Check('diferenca canonica radix 10^9',Canonical(Difference));
end;
procedure RunVectors;
var F: TextFile; Line: string; Fields: TStringList;
begin
  Fields:=TStringList.Create;
  try
    Fields.StrictDelimiter:=True; Fields.Delimiter:=#9;
    AssignFile(F,'bigint_scalar_signed_vectors.tsv');
    Reset(F);
    try
      while not EOF(F) do begin
        ReadLn(F,Line);
        if Line='' then Continue;
        Fields.DelimitedText:=Line;
        Inc(Cases); TestCase(Fields);
      end;
    finally CloseFile(F); end;
  finally Fields.Free; end;
end;
begin
  Cases:=0; Passed:=0; Failed:=0;
  try RunVectors;
  except on E: Exception do begin
    Inc(Failed); Writeln('EXCECAO: ',E.ClassName,': ',E.Message);
  end; end;
  Writeln('Resumo BigAddInt64/BigSubtractInt64: ',Cases,' casos; ',
          Passed,' verificacoes OK; ',Failed,' falhas.');
  if (Cases<>ExpectedCases) or (Passed<>ExpectedChecks) or (Failed<>0) then Halt(1);
end.
