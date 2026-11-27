program stage05_foundation_tag_legacy;
{$MODE OBJFPC}{$H+}
uses SysUtils, Classes, BigInt, Stage02WorkCounts;
const Header = 'day'#9'tag'#9'inverse_day'#9'side';
var Lines, Fields: TStringList; I, Cases, Reds, Matches, Failures: Integer;
    D: TBigInt; Actual, Expected, FixedTag: string;
begin
  if ParamCount <> 1 then Halt(2);
  Cases := 0; Reds := 0; Matches := 0; Failures := 0;
  Lines := TStringList.Create; Fields := TStringList.Create;
  try
    Lines.LoadFromFile(ParamStr(1));
    if (Lines.Count <> 1073) or (Lines[0] <> Header) then Halt(2);
    Fields.Delimiter := #9; Fields.StrictDelimiter := True;
    for I := 1 to Lines.Count-1 do
    begin
      Fields.DelimitedText := Lines[I];
      if Fields.Count <> 4 then Halt(2);
      Inc(Cases);
      D := ParseCanonicalDay(Fields[0]); Expected := Fields[1];
      Actual := BigToDecimal(CountForDaySeededLegacy(D));
      FixedTag := BigToDecimal(CountForDay(D));
      if FixedTag <> Expected then Inc(Failures);
      if Fields[0] = '-15055671' then
      begin
        if (Actual = '0') and (Expected = '1') and (FixedTag = '1') then
        begin
          Inc(Reds);
          Writeln('SEEDED_LEGACY_RED day=-15055671 expected=1 legacy=0 fixed=1');
        end
        else Inc(Failures);
      end
      else if Actual = Expected then Inc(Matches)
      else Inc(Failures);
    end;
  finally
    Fields.Free; Lines.Free;
  end;
  Writeln('STAGE05_LEGACY_CASES=', Cases);
  Writeln('STAGE05_LEGACY_EXPECTED_RED=', Reds);
  Writeln('STAGE05_LEGACY_MATCH=', Matches);
  Writeln('STAGE05_FAILURES=', Failures);
  if (Cases <> 1072) or (Reds <> 1) or (Matches <> 1071) or (Failures <> 0) then Halt(1);
end.
