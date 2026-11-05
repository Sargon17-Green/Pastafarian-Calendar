program bigint_multiply_long_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Independent Python-int fixture; not reconstruction of October historical patches. }
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

function CorrectSign(const A,B,P:TBigInt):Boolean;
begin
  if (A.Sign=0) or (B.Sign=0) then
    Result:=(P.Sign=0) and (Length(P.Digits)=0)
  else
    Result:=(P.Sign=A.Sign*B.Sign) and (Length(P.Digits)>0);
end;

procedure TestCase(const F:TStringList);
var A,B,P,ReverseP:TBigInt; Cat:string;
begin
  if F.Count<>4 then raise EConvertError.Create('TSV: 4 campos necessarios');
  Cat:=F[0];
  if not ((Cat='PP') or (Cat='PN') or (Cat='NP') or
          (Cat='NN') or (Cat='ZERO') or (Cat='LIMB')) then
    raise EConvertError.Create('Categoria invalida');
  A:=BigFromDecimal(F[1]);
  B:=BigFromDecimal(F[2]);
  P:=BigMultiply(A,B);
  ReverseP:=BigMultiply(B,A);
  Check('produto decimal',BigToDecimal(P)=F[3]);
  Check('representacao canonica radix 10^9',Canonical(P));
  Check('comutatividade',BigCompare(P,ReverseP)=0);
  Check('sinal e zero',CorrectSign(A,B,P));
end;

procedure RunVectors;
var F:TextFile; Line:string; Fields:TStringList;
begin
  Fields:=TStringList.Create;
  try
    Fields.StrictDelimiter:=True;
    Fields.Delimiter:=#9;
    AssignFile(F,'bigint_multiply_long_vectors.tsv');
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
  Cases:=0;Passed:=0;Failed:=0;
  try RunVectors;
  except on E:Exception do begin
    Inc(Failed);Writeln('EXCECAO: ',E.ClassName,': ',E.Message);
  end;end;
  Writeln('Resumo BigMultiply longo: ',Cases,' casos; ',Passed,
          ' verificacoes OK; ',Failed,' falhas.');
  if (Cases<>ExpectedCases) or (Passed<>ExpectedChecks) or (Failed<>0) then Halt(1);
end.
