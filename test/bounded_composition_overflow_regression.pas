program bounded_composition_overflow_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

uses
  SysUtils, BigInt, NormativeOracle, NormativeFamilies;

var
  Passed, Failed: Integer;

function EqualIndices(const Actual: TIntArray; const Expected: array of Integer): Boolean;
var
  I: Integer;
begin
  if Length(Actual) <> Length(Expected) then Exit(False);
  for I := 0 to High(Expected) do
    if Actual[I] <> Expected[I] then Exit(False);
  Result := True;
end;

procedure CheckFamily(const LabelText: string; Total, Slots, LoValue, HiValue: Integer;
  const ExpectedCount: string; const First, Last: array of Integer);
var
  Family: TBoundedCompositionFamily;
  Count: TBigInt;
  Good: Boolean;
begin
  Family := TBoundedCompositionFamily.Create(Total, Slots, LoValue, HiValue);
  try
    Count := Family.CountAll;
    Good := BigToDecimal(Count) = ExpectedCount;
    if Good and (ExpectedCount <> '0') then
      Good := EqualIndices(Family.Unrank1(BigOne), First) and
              EqualIndices(Family.Unrank1(Count), Last);
    if Good then
    begin
      Inc(Passed);
      Writeln('OK: ', LabelText);
    end
    else
    begin
      Inc(Failed);
      Writeln('FALHA: ', LabelText, ' count=', BigToDecimal(Count));
    end;
  finally
    Family.Free;
  end;
end;

procedure CheckOversizeReject;
var
  Family: TBoundedCompositionFamily;
begin
  Family := nil;
  try
    try
      Family := TBoundedCompositionFamily.Create(High(Integer), 1, 0, High(Integer));
      Inc(Failed);
      Writeln('FALHA: excessive memo dimensions accepted');
    except
      on E: ERangeError do
      begin
        Inc(Passed);
        Writeln('OK: excessive memo dimensions rejected');
      end;
    end;
  finally
    Family.Free;
  end;
end;

begin
  Passed := 0;
  Failed := 0;
  try
    CheckFamily('large Hi, total 1', 1, 2, 0, High(Integer), '2', [0, 1], [1, 0]);
    CheckFamily('large Hi, total 3', 3, 2, 0, High(Integer), '4', [0, 3], [3, 0]);
    CheckFamily('ordinary bounded lexicographic family', 5, 3, 1, 3, '6',
      [1, 1, 3], [3, 1, 1]);
    CheckFamily('empty composition', 0, 0, 0, High(Integer), '1', [], []);
    CheckFamily('zero total two slots', 0, 2, 0, High(Integer), '1', [0, 0], [0, 0]);
    CheckFamily('no valid all-positive composition', 1, 2, 1, High(Integer), '0', [], []);
    CheckOversizeReject;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('EXCEÇÃO NÃO TRATADA: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('Resumo: ', Passed, ' passaram; ', Failed, ' falharam.');
  if Failed <> 0 then Halt(1);
end.
