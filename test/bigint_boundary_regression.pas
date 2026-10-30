program bigint_boundary_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Independent Stage 1 BigInt boundary coverage.
  This suite does not claim byte identity with the 2026-10-12 patch. }

uses
  SysUtils, BigInt;

var
  Passed, Failed: Integer;

procedure Pass(const Name: string);
begin
  Inc(Passed);
  Writeln('OK: ', Name);
end;

procedure Fail(const Name, ExpectedValue, ActualValue: string);
begin
  Inc(Failed);
  Writeln('FALHA: ', Name);
  Writeln('  esperado: ', ExpectedValue);
  Writeln('  obtido:   ', ActualValue);
end;

procedure CheckText(const Name, ExpectedValue, ActualValue: string);
begin
  if ExpectedValue = ActualValue then
    Pass(Name)
  else
    Fail(Name, ExpectedValue, ActualValue);
end;

procedure CheckBig(const Name, ExpectedValue: string; const ActualValue: TBigInt);
begin
  CheckText(Name, ExpectedValue, BigToDecimal(ActualValue));
end;

procedure CheckInt64Overflow;
var
  Value: Int64;
begin
  try
    Value := BigToInt64Exact(BigFromDecimal('9223372036854775808'));
    Fail('Int64 acima do máximo rejeitado', 'ERangeError', IntToStr(Value));
  except
    on E: ERangeError do Pass('Int64 acima do máximo rejeitado');
    on E: Exception do Fail('Int64 acima do máximo rejeitado', 'ERangeError', E.ClassName);
  end;
end;

procedure CheckUInt32Overflow;
var
  Value: UInt32;
begin
  try
    Value := BigToUInt32Exact(BigFromDecimal('4294967296'));
    Fail('UInt32 acima do máximo rejeitado', 'ERangeError', IntToStr(Int64(Value)));
  except
    on E: ERangeError do Pass('UInt32 acima do máximo rejeitado');
    on E: Exception do Fail('UInt32 acima do máximo rejeitado', 'ERangeError', E.ClassName);
  end;
end;

procedure RunCases;
var
  Q, R: TBigInt;
begin
  CheckBig('Int64 mínimo construtor', '-9223372036854775808', BigFromInt64(Low(Int64)));
  CheckBig('Int64 máximo construtor', '9223372036854775807', BigFromInt64(High(Int64)));
  CheckBig('UInt64 máximo construtor', '18446744073709551615', BigFromUInt64(High(UInt64)));
  CheckBig('zero negativo normalizado', '0', BigFromDecimal('-000000000000000000000'));
  CheckBig('carry uma casa base 10^9', '1000000000',
    BigAdd(BigFromDecimal('999999999'), BigOne));
  CheckBig('carry entre múltiplas casas', '1000000000000000000',
    BigAdd(BigFromDecimal('999999999999999999'), BigOne));
  CheckBig('borrow entre múltiplas casas', '999999999999999999',
    BigSubtract(BigFromDecimal('1000000000000000000'), BigOne));
  CheckBig('subtração com sinal', '-12',
    BigSubtract(BigFromInt64(-5), BigFromInt64(7)));
  CheckBig('multiplicação perto da base', '999999998000000001',
    BigSquare(BigFromDecimal('999999999')));
  CheckBig('multiplicação por Int64 mínimo', '-9223372036854775808',
    BigMultiplyInt64(BigOne, Low(Int64)));
  BigDivModPositive(BigFromDecimal('1000000000000000000'),
    BigFromDecimal('1000000000'), Q, R);
  CheckBig('quociente sem resto', '1000000000', Q);
  CheckBig('resto zero', '0', R);
  BigDivModPositive(BigFromDecimal('999999999999999999'),
    BigFromDecimal('1000000000'), Q, R);
  CheckBig('quociente com resto na fronteira', '999999999', Q);
  CheckBig('resto na fronteira', '999999999', R);
  CheckBig('módulo euclidiano negativo', '999999999',
    BigRegularModPositive(BigFromInt64(-1), BigFromDecimal('1000000000')));
  CheckBig('módulo negativo divisível', '0',
    BigRegularModPositive(BigFromInt64(-1000000000), BigFromDecimal('1000000000')));
  CheckText('UInt32 máximo conversão exata', '4294967295',
    IntToStr(Int64(BigToUInt32Exact(BigFromDecimal('4294967295')))));
  CheckInt64Overflow;
  CheckUInt32Overflow;
end;

begin
  Passed := 0;
  Failed := 0;
  try
    RunCases;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCEÇÃO NÃO TRATADA: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo BigInt: ', Passed, ' passaram; ', Failed, ' falharam.');
  if (Passed <> 19) or (Failed <> 0) then Halt(1);
end.
