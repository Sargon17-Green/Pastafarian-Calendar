program bigint_divmod_oracle_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

{ Independent Stage 1 reference vectors, calculated with arbitrary-precision
  integer arithmetic and separately checked against Python integer divmod.
  This does not reconstruct or authenticate historical patch files. }

uses SysUtils, BigInt;

type
  TDivCase = record
    A, B, Q, R: string;
  end;
  TModCase = record
    A, D, R: string;
  end;

const
  DivCases: array[0..23] of TDivCase = (
    (A: '0'; B: '1'; Q: '0'; R: '0'),
    (A: '1'; B: '1'; Q: '1'; R: '0'),
    (A: '1'; B: '1000000000'; Q: '0'; R: '1'),
    (A: '1000000000'; B: '999999999'; Q: '1'; R: '1'),
    (A: '1000000000000000000'; B: '1000000001'; Q: '999999999'; R: '1'),
    (A: '999999999999999999'; B: '1000000000'; Q: '999999999'; R: '999999999'),
    (A: '1000000000000000000000000000000000000'; B: '999999999999999999'; Q: '1000000000000000001'; R: '1'),
    (A: '999999999999999999999999999999999999'; B: '1000000000000000001'; Q: '999999999999999999'; R: '0'),
    (A: '1000000000000000000000000000000000000000000000000000000000000000123456789'; B: '1000000000000000000000000000000000001'; Q: '999999999999999999999999999999999999'; R: '123456790'),
    (A: '999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999'; B: '1000000000000000000000000000000000000000000019'; Q: '999999999999999999999999999999999999999999981'; R: '360'),
    (A: '999999911'; B: '13'; Q: '76923070'; R: '1'),
    (A: '999999998765344'; B: '1000000000104'; Q: '999'; R: '999998661448'),
    (A: '999999999999997530777'; B: '100000000000000000000205'; Q: '0'; R: '999999999999997530777'),
    (A: '999999999999999999996296210'; B: '100306'; Q: '9969493350347935317890'; R: '21870'),
    (A: '999999999999999999999999995061643'; B: '10000000407'; Q: '99999995930000165648993'; R: '2575921492'),
    (A: '999999999999999999999999999999993827076'; B: '1000000000000508'; Q: '999999999999492000000000'; R: '258063993827076'),
    (A: '999999999999999999999999999999999999992592509'; B: '100000000000000000609'; Q: '9999999999999999939100000'; R: '37080692509'),
    (A: '999999999999999999999999999999999999999999991357942'; B: '10000000000000000000000710'; Q: '99999999999999999999992899'; R: '9999999999999999996399652'),
    (A: '999999999999999999999999999999999999999999999999990123375'; B: '1000000000000000000000000000811'; Q: '999999999999999999999999999'; R: '188999999999999999999990124186'),
    (A: '999999999999999999999999999999999999999999999999999999988888808'; B: '100000000000000000000000000000000912'; Q: '9999999999999999999999999999'; R: '99990879999999999999999999988889720'),
    (A: '999999999999999999999999999999999999999999999999999999999999987654241'; B: '10000000000000000000000000000000000001013'; Q: '99999999999999999999999999999'; R: '9999999898699999999999999999999987655254'),
    (A: '999999999999999999999999999999999999999999999999999999999999999999986419674'; B: '1000000000000000000000000000000000000000001114'; Q: '999999999999999999999999999999'; R: '999999999998885999999999999999999999986420788'),
    (A: '999999999999999999999999999999999999999999999999999999999999999999999999985185107'; B: '100000000000000000000000000000000000000000000001215'; Q: '9999999999999999999999999999999'; R: '99999999999999987849999999999999999999999985186322'),
    (A: '999999999999999999999999999999999999999999999999999999999999999999999999999999983950540'; B: '10000000000000000000000000000000000000000000000000001316'; Q: '99999999999999999999999999999999'; R: '9999999999999999999868399999999999999999999999983951856')
  );
  ModCases: array[0..7] of TModCase = (
    (A: '-1'; D: '1000000000'; R: '999999999'),
    (A: '-1000000000'; D: '1000000000'; R: '0'),
    (A: '-1000000001'; D: '1000000000'; R: '999999999'),
    (A: '-1000000000000000000000000000000000001'; D: '1000000000000000001'; R: '999999999999999999'),
    (A: '-1000000000000000000000000000000000000000000000000000000000000'; D: '999999999999999999999999999999'; R: '999999999999999999999999999998'),
    (A: '-3'; D: '2'; R: '1'),
    (A: '-999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999'; D: '1000000000000000000000000000000000000000000019'; R: '999999999999999999999999999999999999999999659'),
    (A: '0'; D: '1'; R: '0')
  );

var
  Passed, Failed: Integer;

procedure CheckDivision(const C: TDivCase; CaseNumber: Integer);
var
  A, B, Q, R, Rebuilt: TBigInt;
  Ok: Boolean;
begin
  A := BigFromDecimal(C.A);
  B := BigFromDecimal(C.B);
  BigDivModPositive(A, B, Q, R);
  Rebuilt := BigAdd(BigMultiply(B, Q), R);
  Ok := (BigToDecimal(Q) = C.Q) and
        (BigToDecimal(R) = C.R) and
        (BigCompare(Rebuilt, A) = 0) and
        (R.Sign >= 0) and (BigCompare(R, B) < 0);
  if Ok then Inc(Passed) else
  begin
    Inc(Failed);
    Writeln('FALHA DIV ', CaseNumber, ' Q=', BigToDecimal(Q),
      ' R=', BigToDecimal(R), ' esperado=', C.Q, '/', C.R);
  end;
end;

procedure CheckModulo(const C: TModCase; CaseNumber: Integer);
var
  A, D, R: TBigInt;
begin
  A := BigFromDecimal(C.A);
  D := BigFromDecimal(C.D);
  R := BigRegularModPositive(A, D);
  if (BigToDecimal(R) = C.R) and (R.Sign >= 0) and
     (BigCompare(R, D) < 0) then Inc(Passed) else
  begin
    Inc(Failed);
    Writeln('FALHA MOD ', CaseNumber, ' R=', BigToDecimal(R),
      ' esperado=', C.R);
  end;
end;

procedure CheckInvalidPositiveDividend;
var
  Q, R: TBigInt;
begin
  try
    BigDivModPositive(BigFromInt64(-1), BigOne, Q, R);
    Inc(Failed);
    Writeln('FALHA: negative dividend accepted');
  except
    on E: ERangeError do Inc(Passed);
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('FALHA: ', E.ClassName);
    end;
  end;
end;

procedure CheckZeroDivisor;
var
  Q, R: TBigInt;
begin
  try
    BigDivModPositive(BigOne, BigZero, Q, R);
    Inc(Failed);
    Writeln('FALHA: zero divisor accepted');
  except
    on E: EDivByZero do Inc(Passed);
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('FALHA: ', E.ClassName);
    end;
  end;
end;

var
  I: Integer;
begin
  Passed := 0;
  Failed := 0;
  try
    for I := Low(DivCases) to High(DivCases) do
      CheckDivision(DivCases[I], I);
    for I := Low(ModCases) to High(ModCases) do
      CheckModulo(ModCases[I], I);
    CheckInvalidPositiveDividend;
    CheckZeroDivisor;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCEÇÃO NÃO TRATADA: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo DivMod: ', Passed, ' passaram; ', Failed, ' falharam.');
  if (Passed <> 34) or (Failed <> 0) then Halt(1);
end.
