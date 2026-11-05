program bigint_add_sub_long_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Independent Python-int fixture; not reconstruction of October patches. }
uses SysUtils, Classes, BigInt;
const ExpectedCases=96; ExpectedChecks=384;
var Cases,Passed,Failed:Integer;
procedure Check(const N:string; C:Boolean);
begin
  if C then Inc(Passed) else begin
    Inc(Failed); Writeln('FALHA caso ',Cases,': ',N);
  end;
end;
function Canonical(const X:TBigInt):Boolean;
var I:Integer;
begin
  if Length(X.Digits)=0 then Exit(X.Sign=0);
  if ((X.Sign<>1) and (X.Sign<>-1)) or
     (X.Digits[High(X.Digits)]=0) then Exit(False);
  for I:=0 to High(X.Digits) do
    if UInt64(X.Digits[I])>=BIG_BASE then Exit(False);
  Result:=True;
end;
procedure TestCase(const F:TStringList);
var A,B,SumValue,Difference:TBigInt; Cat:string;
begin
  if F.Count<>5 then raise EConvertError.Create('TSV: 5 campos necessarios');
  Cat:=F[0];
  if not ((Cat='ADD_PP') or (Cat='ADD_PN') or (Cat='ADD_NP') or
          (Cat='ADD_NN') or (Cat='SUB_BORROW') or (Cat='CANCEL')) then
    raise EConvertError.Create('Categoria invalida');
  A:=BigFromDecimal(F[1]);
  B:=BigFromDecimal(F[2]);
  SumValue:=BigAdd(A,B);
  Difference:=BigSubtract(A,B);
  Check('soma decimal',BigToDecimal(SumValue)=F[3]);
  Check('soma canonica radix 10^9',Canonical(SumValue));
  Check('diferenca decimal',BigToDecimal(Difference)=F[4]);
  Check('diferenca canonica radix 10^9',Canonical(Difference));
end;
procedure RunVectors;
var F:TextFile; Line:string; Fields:TStringList;
begin
  Fields:=TStringList.Create;
  try
    Fields.StrictDelimiter:=True;
    Fields.Delimiter:=#9;
    AssignFile(F,'bigint_add_sub_long_vectors.tsv');
    Reset(F);
    try
      while not EOF(F) do begin
        ReadLn(F,Line);
        if Line='' then Continue;
        Fields.DelimitedText:=Line;
        Inc(Cases);
        TestCase(Fields);
      end;
    finally CloseFile(F); end;
  finally Fields.Free; end;
end;
begin
  Cases:=0; Passed:=0; Failed:=0;
  try RunVectors;
  except on E:Exception do begin
    Inc(Failed); Writeln('EXCECAO: ',E.ClassName,': ',E.Message);
  end; end;
  Writeln('Resumo BigAdd/BigSubtract longo: ',Cases,' casos; ',Passed,
          ' verificacoes OK; ',Failed,' falhas.');
  if (Cases<>ExpectedCases) or (Passed<>ExpectedChecks) or (Failed<>0) then Halt(1);
end.
