program bigint_scalar_multiply_signed_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Independent Python integer oracle for 96 signed Int64 products. }
uses SysUtils, Classes, BigInt;
const ExpectedCases=96; ExpectedChecks=480;
var Cases,Passed,Failed:Integer;
procedure Check(const LabelText:string; OK:Boolean);
begin
  if OK then Inc(Passed) else begin
    Inc(Failed); Writeln('FALHA caso ',Cases,': ',LabelText);
  end;
end;
function Canonical(const X:TBigInt):Boolean;
var I:Integer;
begin
  if Length(X.Digits)=0 then Exit(X.Sign=0);
  if (X.Sign<>1) and (X.Sign<>-1) then Exit(False);
  if X.Digits[High(X.Digits)]=0 then Exit(False);
  for I:=0 to High(X.Digits) do
    if UInt64(X.Digits[I])>=BIG_BASE then Exit(False);
  Result:=True;
end;
procedure CheckCase(const F:TStringList);
var A,P,ReverseP:TBigInt; B:Int64; OracleSign,OracleLimbs:Integer;
begin
  if F.Count<>6 then raise EConvertError.Create('TSV: seis campos');
  if not ((F[0]='MIN_EDGE') or (F[0]='MAX_EDGE') or
          (F[0]='ZERO_FACTOR') or (F[0]='RADIX_LOW') or
          (F[0]='RADIX_HIGH') or (F[0]='SIGN_GRID')) then
    raise EConvertError.Create('Categoria desconhecida');
  A:=BigFromDecimal(F[1]); B:=StrToInt64(F[2]);
  OracleSign:=StrToInt(F[4]); OracleLimbs:=StrToInt(F[5]);
  P:=BigMultiplyInt64(A,B);
  ReverseP:=BigMultiply(BigFromInt64(B),A);
  Check('produto decimal',BigToDecimal(P)=F[3]);
  Check('sinal esperado',P.Sign=OracleSign);
  Check('representacao canonica',Canonical(P));
  Check('numero de limbs',Length(P.Digits)=OracleLimbs);
  Check('comutatividade',BigCompare(P,ReverseP)=0);
end;
procedure RunVectors;
var F:TextFile; Line:string; Fields:TStringList;
begin
  Fields:=TStringList.Create;
  try
    Fields.Delimiter:=#9; Fields.StrictDelimiter:=True;
    AssignFile(F,'bigint_scalar_multiply_signed_vectors.tsv'); Reset(F);
    try while not EOF(F) do begin
      ReadLn(F,Line); if Line='' then Continue;
      Fields.DelimitedText:=Line; Inc(Cases); CheckCase(Fields);
    end; finally CloseFile(F); end;
  finally Fields.Free; end;
end;
begin
  Cases:=0;Passed:=0;Failed:=0;
  try RunVectors
  except on E:Exception do begin
    Inc(Failed); Writeln('EXCECAO: ',E.ClassName,': ',E.Message);
  end;end;
  Writeln('Resumo BigMultiplyInt64: ',Cases,' casos; ',Passed,
    ' verificacoes OK; ',Failed,' falhas.');
  if (Cases<>ExpectedCases) or (Passed<>ExpectedChecks) or (Failed<>0) then Halt(1);
end.
