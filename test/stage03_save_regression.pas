program stage03_save_regression;

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
  EXPECTED_CASES = 128;
  EXPECTED_RED_COUNT = 17;
  EXPECTED_MATCH_COUNT = 111;

var
  Passed, Failed, RedCount, MatchCount: Integer;
  Lines, Parts, SeenNames, SeenInputs: TStringList;
  I: Integer;
  X, M, LegacyActual, LegacyExpected, SaveActual, SaveExpected: TBigInt;
  PlusM, MinusM, PeriodicPlus, PeriodicMinus: TBigInt;
  CaseName, Classification, ExpectedClassification: string;

procedure Check(const Name: string; Condition: Boolean);
begin
  if Condition then
    Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FAIL: ', Name);
  end;
end;

function ClassificationFor(const LegacyValue, SavedValue: TBigInt): string;
begin
  if BigCompare(LegacyValue, SavedValue) <> 0 then
    Result := 'EXPECTED_RED'
  else
    Result := 'MATCH';
end;

begin
  Passed := 0;
  Failed := 0;
  RedCount := 0;
  MatchCount := 0;
  Lines := TStringList.Create;
  Parts := TStringList.Create;
  SeenNames := TStringList.Create;
  SeenInputs := TStringList.Create;
  try
    try
      Writeln('STAGE03_LEGACY_PATH=BigRegularModPositive');
      Writeln('STAGE03_PRODUCTION_PATH=BigSave');
      if ParamCount <> 1 then
        raise Exception.Create('Usage: stage03_save_regression <oracle.tsv>');

      Lines.LoadFromFile(ParamStr(1));
      if Lines.Count > 0 then
        Check('header', Lines[0] = EXPECTED_HEADER)
      else
        Check('header', False);
      Check('exact row count', Lines.Count = EXPECTED_CASES + 1);
      if Lines.Count <> EXPECTED_CASES + 1 then
        raise Exception.Create('TSV must contain exactly 128 data rows.');

      Parts.Delimiter := #9;
      Parts.StrictDelimiter := True;

      for I := 1 to EXPECTED_CASES do
      begin
        Parts.DelimitedText := Lines[I];
        Check('column count row ' + IntToStr(I), Parts.Count = 6);
        if Parts.Count <> 6 then
          raise Exception.Create('Invalid TSV width at row ' + IntToStr(I));

        CaseName := Parts[0];
        Check('non-empty case name row ' + IntToStr(I), CaseName <> '');
        Check('unique case name row ' + IntToStr(I), SeenNames.IndexOf(CaseName) < 0);
        Check('unique input row ' + IntToStr(I), SeenInputs.IndexOf(Parts[1]) < 0);
        SeenNames.Add(CaseName);
        SeenInputs.Add(Parts[1]);

        X := BigFromDecimal(Parts[1]);
        M := BigFromDecimal(Parts[2]);
        LegacyExpected := BigFromDecimal(Parts[3]);
        SaveExpected := BigFromDecimal(Parts[4]);
        Classification := Parts[5];

        Check('normative modulus row ' + IntToStr(I),
          BigToDecimal(M) = EXPECTED_M);

        { Preserve and verify the old ordinary-remainder primitive. }
        LegacyActual := BigRegularModPositive(X, M);
        Check('legacy remainder row ' + IntToStr(I),
          BigCompare(LegacyActual, LegacyExpected) = 0);
        Check('legacy remainder range row ' + IntToStr(I),
          (BigCompare(LegacyActual, BigZero) >= 0) and
          (BigCompare(LegacyActual, M) < 0));

        { Exercise the new production SAVE implementation. }
        SaveActual := BigSave(X);
        Check('production SAVE row ' + IntToStr(I),
          BigCompare(SaveActual, SaveExpected) = 0);
        Check('SAVE range row ' + IntToStr(I),
          (BigCompare(SaveActual, BigOne) >= 0) and
          (BigCompare(SaveActual, M) <= 0));

        ExpectedClassification := ClassificationFor(LegacyExpected, SaveExpected);
        Check('classification row ' + IntToStr(I),
          Classification = ExpectedClassification);
        if Classification = 'EXPECTED_RED' then
          Inc(RedCount)
        else if Classification = 'MATCH' then
          Inc(MatchCount)
        else
          raise Exception.Create('Invalid classification at row ' + IntToStr(I));

        { SAVE is periodic with period M for positive and negative inputs. }
        PlusM := BigAdd(X, M);
        MinusM := BigSubtract(X, M);
        PeriodicPlus := BigSave(PlusM);
        PeriodicMinus := BigSave(MinusM);
        Check('SAVE periodic +M row ' + IntToStr(I),
          BigCompare(PeriodicPlus, SaveActual) = 0);
        Check('SAVE periodic -M row ' + IntToStr(I),
          BigCompare(PeriodicMinus, SaveActual) = 0);
      end;

      Check('expected RED count', RedCount = EXPECTED_RED_COUNT);
      Check('matching control count', MatchCount = EXPECTED_MATCH_COUNT);
      Check('total classified rows',
        (RedCount + MatchCount) = EXPECTED_CASES);
    except
      on E: Exception do
      begin
        Inc(Failed);
        Writeln('EXCEPTION=', E.ClassName, ': ', E.Message);
      end;
    end;
  finally
    SeenInputs.Free;
    SeenNames.Free;
    Parts.Free;
    Lines.Free;
  end;

  Writeln('STAGE03_CASES=', EXPECTED_CASES);
  Writeln('STAGE03_EXPECTED_RED_COUNT=', RedCount);
  Writeln('STAGE03_MATCH_COUNT=', MatchCount);
  Writeln('STAGE03_CHECKS_PASSED=', Passed);
  Writeln('STAGE03_CHECKS_FAILED=', Failed);
  if Failed = 0 then
    Writeln('STAGE03_RESULT=PASS')
  else
    Writeln('STAGE03_RESULT=FAIL');

  if Failed <> 0 then
    Halt(1);
  Halt(0);
end.
