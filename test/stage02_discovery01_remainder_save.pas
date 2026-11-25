program stage02_discovery01_remainder_save;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$ENDIF}

uses
  SysUtils, Classes, BigInt;

const
  EXPECTED_M = '170141183460469231731687303715884105727';
  EXPECTED_HEADER =
    'case' + #9 + 'input' + #9 + 'modulus' + #9 +
    'legacy_remainder' + #9 + 'save_result' + #9 + 'classification';
  EXPECTED_CASES: array[0..3] of string =
    ('ZERO', 'M', '2M', 'M_PLUS_1');
  EXPECTED_RED_COUNT = 3;
  EXPECTED_MATCH_COUNT = 1;

var
  Passed, Failed, RedCount, MatchCount: Integer;
  Lines, Parts: TStringList;
  I: Integer;
  X, M, Actual, LegacyExpected, SaveExpected, ExpectedInput: TBigInt;
  CaseName, Classification, ExpectedClassification: string;

procedure Check(const Name: string; Condition: Boolean);
begin
  if Condition then
  begin
    Inc(Passed);
    Writeln('PASS: ', Name);
  end
  else
  begin
    Inc(Failed);
    Writeln('FAIL: ', Name);
  end;
end;

function ExpectedInputFor(const Name: string; const Modulus: TBigInt): TBigInt;
begin
  if Name = 'ZERO' then
    Exit(BigZero);
  if Name = 'M' then
    Exit(BigClone(Modulus));
  if Name = '2M' then
    Exit(BigMultiplyInt64(Modulus, 2));
  if Name = 'M_PLUS_1' then
    Exit(BigAddInt64(Modulus, 1));
  raise Exception.Create('Caso desconhecido: ' + Name);
end;

function ExpectedClassificationFor(const Name: string): string;
begin
  if (Name = 'ZERO') or (Name = 'M') or (Name = '2M') then
    Exit('EXPECTED_RED');
  if Name = 'M_PLUS_1' then
    Exit('MATCH');
  raise Exception.Create('Classificação desconhecida: ' + Name);
end;

begin
  Passed := 0;
  Failed := 0;
  RedCount := 0;
  MatchCount := 0;
  Lines := TStringList.Create;
  Parts := TStringList.Create;
  try
    try
      Writeln('DISCOVERY01_LEGACY_PATH=BigRegularModPositive');
      if ParamCount <> 1 then
        raise Exception.Create('Uso: stage02_discovery01_remainder_save <oracle.tsv>');

      Lines.LoadFromFile(ParamStr(1));
      if Lines.Count > 0 then
        Check('header', Lines[0] = EXPECTED_HEADER)
      else
        Check('header', False);
      Check('exact row count', Lines.Count = 5);
      if Lines.Count <> 5 then
        raise Exception.Create('TSV deve conter exatamente quatro casos.');

      Parts.Delimiter := #9;
      Parts.StrictDelimiter := True;

      for I := 1 to 4 do
      begin
        Parts.DelimitedText := Lines[I];
        Check('column count row ' + IntToStr(I), Parts.Count = 6);
        if Parts.Count <> 6 then
          raise Exception.Create('Largura inválida na linha ' + IntToStr(I));

        CaseName := Parts[0];
        Check('case order ' + IntToStr(I), CaseName = EXPECTED_CASES[I - 1]);

        X := BigFromDecimal(Parts[1]);
        M := BigFromDecimal(Parts[2]);
        LegacyExpected := BigFromDecimal(Parts[3]);
        SaveExpected := BigFromDecimal(Parts[4]);
        Classification := Parts[5];

        Check('normative modulus ' + CaseName, BigToDecimal(M) = EXPECTED_M);
        ExpectedInput := ExpectedInputFor(CaseName, M);
        Check('input vector ' + CaseName, BigCompare(X, ExpectedInput) = 0);

        { This is the real production primitive, not a copied test implementation. }
        Actual := BigRegularModPositive(X, M);
        Check('live legacy primitive ' + CaseName,
          BigCompare(Actual, LegacyExpected) = 0);
        Check('legacy remainder range ' + CaseName,
          (BigCompare(Actual, BigZero) >= 0) and
          (BigCompare(Actual, M) < 0));
        Check('SAVE result range ' + CaseName,
          (BigCompare(SaveExpected, BigOne) >= 0) and
          (BigCompare(SaveExpected, M) <= 0));

        ExpectedClassification := ExpectedClassificationFor(CaseName);
        Check('classification label ' + CaseName,
          Classification = ExpectedClassification);

        if Classification = 'EXPECTED_RED' then
        begin
          Inc(RedCount);
          Check('expected RED ' + CaseName,
            BigCompare(Actual, SaveExpected) <> 0);
        end
        else if Classification = 'MATCH' then
        begin
          Inc(MatchCount);
          Check('matching control ' + CaseName,
            BigCompare(Actual, SaveExpected) = 0);
        end
        else
          raise Exception.Create('Rótulo de classificação inválido: ' + Classification);

        Writeln('DISCOVERY01_CASE=', CaseName,
          ' INPUT=', Parts[1],
          ' LEGACY_ACTUAL=', BigToDecimal(Actual),
          ' SAVE_EXPECTED=', BigToDecimal(SaveExpected),
          ' CLASSIFICATION=', Classification);
      end;

      Check('expected RED count', RedCount = EXPECTED_RED_COUNT);
      Check('matching control count', MatchCount = EXPECTED_MATCH_COUNT);
      Check('total classified cases', (RedCount + MatchCount) = 4);
    except
      on E: Exception do
      begin
        Inc(Failed);
        Writeln('EXCEPTION=', E.ClassName, ': ', E.Message);
      end;
    end;
  finally
    Parts.Free;
    Lines.Free;
  end;

  Writeln('DISCOVERY01_CASES=', RedCount + MatchCount);
  Writeln('DISCOVERY01_EXPECTED_RED_COUNT=', RedCount);
  Writeln('DISCOVERY01_MATCH_COUNT=', MatchCount);
  Writeln('DISCOVERY01_CHECKS_PASSED=', Passed);
  Writeln('DISCOVERY01_CHECKS_FAILED=', Failed);
  if Failed = 0 then
    Writeln('DISCOVERY01_RESULT=EXPECTED_RED_CONFIRMED')
  else
    Writeln('DISCOVERY01_RESULT=FAIL');

  if Failed <> 0 then
    Halt(1);
  Halt(0);
end.
