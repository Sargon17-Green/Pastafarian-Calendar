program bigint_min_max_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Independent Python integer oracle for signed BigMin/BigMax selection. }
uses SysUtils, Classes, BigInt;
const ExpectedCases=96; ExpectedChecks=960;
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

procedure CheckCase(const Fields:TStringList);
var A,B,Small,Large,SmallReversed,LargeReversed:TBigInt;
begin
  if Fields.Count<>5 then raise EConvertError.Create('TSV: cinco campos');
  if not ((Fields[0]='EQUAL') or (Fields[0]='POSITIVE') or
          (Fields[0]='NEGATIVE') or (Fields[0]='OPPOSITE') or
          (Fields[0]='ZERO') or (Fields[0]='RADIX')) then
    raise EConvertError.Create('Categoria desconhecida');
  A:=BigFromDecimal(Fields[1]); B:=BigFromDecimal(Fields[2]);
  Small:=BigMin(A,B); Large:=BigMax(A,B);
  SmallReversed:=BigMin(B,A); LargeReversed:=BigMax(B,A);
  Check('minimo decimal',BigToDecimal(Small)=Fields[3]);
  Check('maximo decimal',BigToDecimal(Large)=Fields[4]);
  Check('minimo comutativo',BigToDecimal(SmallReversed)=Fields[3]);
  Check('maximo comutativo',BigToDecimal(LargeReversed)=Fields[4]);
  Check('minimo <= A',BigCompare(Small,A)<=0);
  Check('minimo <= B',BigCompare(Small,B)<=0);
  Check('maximo >= A',BigCompare(Large,A)>=0);
  Check('maximo >= B',BigCompare(Large,B)>=0);
  Check('minimo canonico',Canonical(Small));
  Check('maximo canonico',Canonical(Large));
end;

procedure RunVectors;
var F:TextFile; Line:string; Fields:TStringList;
begin
  Fields:=TStringList.Create;
  try
    Fields.Delimiter:=#9; Fields.StrictDelimiter:=True;
    AssignFile(F,'bigint_min_max_vectors.tsv'); Reset(F);
    try while not EOF(F) do begin
      ReadLn(F,Line);
      if Line='' then Continue;
      Fields.DelimitedText:=Line;
      Inc(Cases); CheckCase(Fields);
    end; finally CloseFile(F); end;
  finally Fields.Free; end;
end;

begin
  Cases:=0;Passed:=0;Failed:=0;
  try RunVectors
  except on E:Exception do begin
    Inc(Failed); Writeln('EXCECAO: ',E.ClassName,': ',E.Message);
  end; end;
  Writeln('Resumo BigMin/BigMax: ',Cases,' casos; ',Passed,
    ' verificacoes OK; ',Failed,' falhas.');
  if (Cases<>ExpectedCases) or (Passed<>ExpectedChecks) or (Failed<>0) then Halt(1);
end.
