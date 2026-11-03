program bigint_conversion_exact_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Stage 1: exact machine-width conversions, independently checked against
  Python's unbounded integers. Not historical patch reconstruction. }

uses
  SysUtils, Classes, BigInt;

const
  ExpectedRows = 418;
  ExpectedChecks = 752;

var
  Passed, Failed, Cases: Integer;

procedure Check(const LabelText: string; Condition: Boolean);
begin
  if Condition then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHA: ', LabelText);
  end;
end;

procedure CheckVector(const Fields: TStringList);
var
  A, RoundTripped: TBigInt;
  Kind: Char;
  InputValue, ExpectedValue, ActualValue: string;
  Value64: Int64;
  Value32: UInt32;
  RaisedRange: Boolean;
begin
  if (Fields.Count <> 3) or (Length(Fields[0]) <> 1) then
    raise EConvertError.Create('TSV invalido: tres campos obrigatorios.');
  Kind := Fields[0][1];
  if not (Kind in ['I', 'U']) then
    raise EConvertError.Create('Tipo de conversao desconhecido.');
  InputValue := Fields[1];
  ExpectedValue := Fields[2];
  A := BigFromDecimal(InputValue);
  ActualValue := '';
  RaisedRange := False;
  try
    if Kind = 'I' then
    begin
      Value64 := BigToInt64Exact(A);
      ActualValue := IntToStr(Value64);
    end
    else
    begin
      Value32 := BigToUInt32Exact(A);
      ActualValue := IntToStr(Int64(Value32));
    end;
  except
    on E: ERangeError do RaisedRange := True;
    on E: Exception do
    begin
      Writeln('EXCECAO INESPERADA: ', E.ClassName, ': ', E.Message);
      Check('classe de excecao para ' + InputValue, False);
      Exit;
    end;
  end;

  if ExpectedValue = 'ERangeError' then
  begin
    Check('ERangeError esperado ' + InputValue, RaisedRange);
    Exit;
  end;

  Check('conversao exata ' + InputValue,
    (not RaisedRange) and (ActualValue = ExpectedValue));
  if RaisedRange then
  begin
    Check('round-trip indisponivel ' + InputValue, False);
    Check('representacao indisponivel ' + InputValue, False);
    Exit;
  end;
  if Kind = 'I' then
    RoundTripped := BigFromInt64(Value64)
  else
    RoundTripped := BigFromUInt64(UInt64(Value32));
  Check('round-trip comparacao ' + InputValue,
    BigCompare(RoundTripped, A) = 0);
  Check('round-trip decimal ' + InputValue,
    BigToDecimal(RoundTripped) = ExpectedValue);
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
    AssignFile(F, 'bigint_conversion_exact_vectors.tsv');
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Line = '' then Continue;
        Fields.DelimitedText := Line;
        Inc(Cases);
        CheckVector(Fields);
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
    RunVectors;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCECAO FATAL: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo conversoes exatas: ', Cases, ' vetores; ',
    Passed, ' verificacoes OK; ', Failed, ' falhas.');
  if (Cases <> ExpectedRows) or (Passed <> ExpectedChecks)
    or (Failed <> 0) then Halt(1);
end.
