program stage01_tests;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

uses
  SysUtils,
  BigInt,
  SourceLanguageCatalog,
  MonsterBootstrap,
  PastafariCalendar,
  NormativeOracle;

var
  Passed, Failed: Integer;

procedure Fail(const Name, ExpectedValue, ActualValue: string);
begin
  Inc(Failed);
  Writeln('FALHA: ', Name);
  Writeln('  esperado: ', ExpectedValue);
  Writeln('  obtido:   ', ActualValue);
end;

procedure Pass(const Name: string);
begin
  Inc(Passed);
  Writeln('OK: ', Name);
end;

procedure AssertEqualText(const Name, ExpectedValue, ActualValue: string);
begin
  if ExpectedValue = ActualValue then Pass(Name)
  else Fail(Name, ExpectedValue, ActualValue);
end;

procedure AssertTrue(const Name: string; Value: Boolean);
begin
  if Value then Pass(Name)
  else Fail(Name, 'TRUE', 'FALSE');
end;

procedure AssertBig(const Name, ExpectedValue: string; const ActualValue: TBigInt);
begin
  AssertEqualText(Name, ExpectedValue, BigToDecimal(ActualValue));
end;

procedure AssertOrder(const Name: string; const Order: TBowlOrder; A1, A2, A3, A4, A5, A6: Integer);
var
  ActualValue, ExpectedValue: string;
begin
  ActualValue := IntToStr(Order[1]) + ',' + IntToStr(Order[2]) + ',' + IntToStr(Order[3]) + ',' +
                 IntToStr(Order[4]) + ',' + IntToStr(Order[5]) + ',' + IntToStr(Order[6]);
  ExpectedValue := IntToStr(A1) + ',' + IntToStr(A2) + ',' + IntToStr(A3) + ',' +
                   IntToStr(A4) + ',' + IntToStr(A5) + ',' + IntToStr(A6);
  AssertEqualText(Name, ExpectedValue, ActualValue);
end;

procedure TestBigInt;
var
  A, B, Q, R: TBigInt;
begin
  A := BigFromDecimal('999999999999999999');
  B := BigFromDecimal('1000000001');
  AssertBig('BigInt soma', '1000000001000000000', BigAdd(A, B));
  AssertBig('BigInt subtração', '999999998999999998', BigSubtract(A, B));
  AssertBig('BigInt multiplicação simples', '121932631112635269', BigMultiply(BigFromDecimal('123456789'), BigFromDecimal('987654321')));
  BigDivModPositive(BigFromDecimal('12345678901234567890'), BigFromDecimal('97'), Q, R);
  AssertBig('BigInt quociente', '127275040218913071', Q);
  AssertBig('BigInt resto', '3', R);
  AssertBig('BigInt módulo euclidiano negativo', '94', BigRegularModPositive(BigFromInt64(-3), BigFromInt64(97)));
end;

procedure TestConstantsAndSave;
var
  M: TBigInt;
begin
  M := NormativeM;
  AssertBig('M', M_DECIMAL, M);
  AssertBig('diferença Tablets-Foundation', '14777149', BigSubtract(TabletsDay, FoundationDay));
  AssertBig('SAVE(1)', '1', NormativeSave(BigOne));
  AssertBig('SAVE(M-1)', '170141183460469231731687303715884105726', NormativeSave(BigSubtractInt64(M, 1)));
  AssertBig('SAVE(M)', M_DECIMAL, NormativeSave(M));
  AssertBig('SAVE(M+1)', '1', NormativeSave(BigAddInt64(M, 1)));
  AssertBig('SAVE(2M)', M_DECIMAL, NormativeSave(BigMultiplyInt64(M, 2)));
end;

procedure TestDayCounts;
var
  F: TBigInt;
  C: TWorkCounts;
begin
  F := FoundationDay;
  AssertBig('dayCount Foundation', '1', DayCount(F));
  AssertBig('dayCount Foundation+1', '3', DayCount(BigAddInt64(F, 1)));
  AssertBig('dayCount Foundation-1', '2', DayCount(BigSubtractInt64(F, 1)));
  C := WorkCounts(F, F);
  AssertBig('workCounts action', '1', C.Action);
  AssertBig('workCounts target', '1', C.Target);
  AssertBig('workCounts distance', '1', C.Distance);
  AssertBig('workCounts connection', '2', C.Connection);
  AssertBig('workCounts direction', '2', C.Direction);
end;

procedure TestPermutation;
begin
  AssertOrder('permutação rank 1', BowlOrderFromNumber(1), 1, 2, 3, 4, 5, 6);
  AssertOrder('permutação rank 720', BowlOrderFromNumber(720), 6, 5, 4, 3, 2, 1);
  AssertOrder('drop múltiplo de 720', BowlOrderFromDrop(BigFromInt64(720)), 6, 5, 4, 3, 2, 1);
end;

procedure TestCatalog;
begin
  AssertTrue('catálogo congelado', SourceLanguageCatalogIsFrozen);
  AssertTrue('autoverificação do catálogo', SourceLanguageCatalogSelfCheck);
  AssertEqualText('catálogo de costeletas índice 12', 'trigo', UTF8Encode(CutletNameByCanonicalIndex(12)));
  AssertEqualText('catálogo de meses índice 44', 'sal', UTF8Encode(MonthNameByCanonicalIndex(44)));
  AssertEqualText('catálogo de meses índice 32', 'a porta fechada', UTF8Encode(MonthNameByCanonicalIndex(32)));
end;

procedure TestDistinctUnrank;
var
  X: TIntArray;
begin
  X := UnrankDistinctIndices(4, 3, BigOne);
  AssertTrue('unrank distinto primeiro comprimento', Length(X) = 3);
  AssertTrue('unrank distinto primeiro valor', (X[0] = 1) and (X[1] = 2) and (X[2] = 3));
  X := UnrankDistinctIndices(4, 3, FallingFactorial(4, 3));
  AssertTrue('unrank distinto último valor', (X[0] = 4) and (X[1] = 3) and (X[2] = 2));
end;

procedure TestNeutralMonsterShell;
var
  R: TBootstrapResult;
begin
  R := BootstrapProbe(FoundationDay, FoundationDay);
  AssertTrue('contexto bootstrap concluído', R.ContextCompleted);
  AssertEqualText('versão do catálogo no bootstrap', SOURCE_LANGUAGE_CATALOG_VERSION, R.SourceCatalogVersion);
end;

procedure TestSauceDeterminism;
var
  S1, S2: TSauceResult;
  I: Integer;
begin
  S1 := Sauce(FoundationDay, FoundationDay);
  S2 := Sauce(FoundationDay, FoundationDay);
  for I := 1 to 6 do
    AssertEqualText('determinismo da taça ' + IntToStr(I), BigToDecimal(S1.Bowls[I]), BigToDecimal(S2.Bowls[I]));
  for I := 1 to 6 do
    AssertTrue('ordem 46 contém identificador ' + IntToStr(I),
      (S1.OrderAtDrop46[1] = I) or (S1.OrderAtDrop46[2] = I) or (S1.OrderAtDrop46[3] = I) or
      (S1.OrderAtDrop46[4] = I) or (S1.OrderAtDrop46[5] = I) or (S1.OrderAtDrop46[6] = I));
end;

begin
  Passed := 0;
  Failed := 0;
  try
    TestBigInt;
    TestConstantsAndSave;
    TestDayCounts;
    TestPermutation;
    TestCatalog;
    TestDistinctUnrank;
    TestNeutralMonsterShell;
    TestSauceDeterminism;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCEÇÃO NÃO TRATADA: ', E.ClassName, ': ', E.Message);
    end;
  end;

  Writeln;
  Writeln('Resumo: ', Passed, ' passaram; ', Failed, ' falharam.');
  if Failed <> 0 then Halt(1);
  Halt(0);
end.
