program bigint_signed_arithmetic_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Stage 1: signed, arbitrary-precision arithmetic checked against fixed vectors.
  References are verified independently by Python's arbitrary-precision int.
  Historical 12/13 October patches are NOT reconstructed or authenticated. }

uses
  SysUtils, Classes, BigInt;

const
  ExpectedCases = 64;
  ExpectedChecks = ExpectedCases * 4;

var
  Passed, Failed, Cases: Integer;

procedure CheckText(const LabelText, ExpectedValue, ActualValue: string);
begin
  if ExpectedValue = ActualValue then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA ', LabelText, ': esperado=', ExpectedValue,
      ' obtido=', ActualValue);
  end;
end;

procedure CheckCase(const Fields: TStringList; CaseNo: Integer);
var
  A, B: TBigInt;
  Cmp: Integer;
begin
  if Fields.Count <> 6 then
    raise EConvertError.Create('Vetor TSV inválido: número de campos.');
  A := BigFromDecimal(Fields[0]);
  B := BigFromDecimal(Fields[1]);
  CheckText('soma ' + IntToStr(CaseNo), Fields[2],
    BigToDecimal(BigAdd(A, B)));
  CheckText('subtração ' + IntToStr(CaseNo), Fields[3],
    BigToDecimal(BigSubtract(A, B)));
  CheckText('multiplicação ' + IntToStr(CaseNo), Fields[4],
    BigToDecimal(BigMultiply(A, B)));
  Cmp := BigCompare(A, B);
  CheckText('comparação ' + IntToStr(CaseNo), Fields[5],
    IntToStr(Cmp));
end;

procedure RunCases;
var
  F: TextFile;
  Line: string;
  Fields: TStringList;
begin
  Fields := TStringList.Create;
  try
    Fields.StrictDelimiter := True;
    Fields.Delimiter := #9;
    AssignFile(F, 'bigint_signed_arithmetic_vectors.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then Continue;
        Inc(Cases);
        Fields.DelimitedText := Line;
        CheckCase(Fields, Cases);
      end;
    finally
      CloseFile(F);
    end;
  finally
    Fields.Free;
  end;
end;

begin
  Passed := 0;
  Failed := 0;
  Cases := 0;
  try
    RunCases;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCEÇÃO: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo aritmética com sinal: ', Cases, ' casos; ',
    Passed, ' passaram; ', Failed, ' falharam.');
  if (Cases <> ExpectedCases) or (Passed <> ExpectedChecks)
    or (Failed <> 0) then Halt(1);
end.
