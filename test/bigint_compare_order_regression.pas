program bigint_compare_order_regression;
{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}
{ Python integer oracle for signed and absolute ordering, 96 independent vectors. }
uses SysUtils, Classes, BigInt;
const ExpectedCases=96; ExpectedChecks=768;
var Cases,Passed,Failed:Integer;
procedure Check(const LabelText:string; OK:Boolean);
begin
  if OK then Inc(Passed) else begin
    Inc(Failed); Writeln('FALHA caso ',Cases,': ',LabelText);
  end;
end;
procedure CheckCase(const F:TStringList);
var A,B:TBigInt; WantSigned,WantAbs:Integer;
begin
  if F.Count<>5 then raise EConvertError.Create('TSV: cinco campos');
  if not ((F[0]='EQUAL') or (F[0]='ADJACENT') or (F[0]='OPPOSITE') or
          (F[0]='ZERO') or (F[0]='RADIX_LOW') or (F[0]='RADIX_HIGH')) then
    raise EConvertError.Create('Categoria desconhecida');
  A:=BigFromDecimal(F[1]); B:=BigFromDecimal(F[2]);
  WantSigned:=StrToInt(F[3]); WantAbs:=StrToInt(F[4]);
  Check('comparacao assinada',BigCompare(A,B)=WantSigned);
  Check('comparacao absoluta',BigCompareAbs(A,B)=WantAbs);
  Check('antissimetria assinada',BigCompare(B,A)=-WantSigned);
  Check('antissimetria absoluta',BigCompareAbs(B,A)=-WantAbs);
  Check('negacao reversa',BigCompare(BigNegate(B),BigNegate(A))=WantSigned);
  Check('magnitude invariante',BigCompareAbs(BigNegate(A),BigNegate(B))=WantAbs);
  Check('reflexividade assinada',BigCompare(A,A)=0);
  Check('reflexividade absoluta',BigCompareAbs(B,B)=0);
end;
procedure RunVectors;
var F:TextFile; Line:string; Fields:TStringList;
begin
  Fields:=TStringList.Create;
  try
    Fields.Delimiter:=#9; Fields.StrictDelimiter:=True;
    AssignFile(F,'bigint_compare_order_vectors.tsv'); Reset(F);
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
  end; end;
  Writeln('Resumo BigCompare/BigCompareAbs: ',Cases,' casos; ',Passed,
    ' verificacoes OK; ',Failed,' falhas.');
  if (Cases<>ExpectedCases) or (Passed<>ExpectedChecks) or (Failed<>0) then Halt(1);
end.
