program cutlet_partition_memo_bounds_regression;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

uses
  SysUtils, BigInt, NormativeOracle, NormativeFamilies;

var
  Passed, Failed: Integer;

procedure CheckReject(const LabelText: string; G, K: Integer);
var
  Family: TCutletPartitionFamily;
begin
  Family := nil;
  try
    try
      Family := TCutletPartitionFamily.Create(G, K, -1);
      Inc(Failed);
      Writeln('FALHA: ', LabelText, ' (constructor accepted unsafe dimensions)');
    except
      on E: ERangeError do
      begin
        Inc(Passed);
        Writeln('OK: ', LabelText);
      end;
    end;
  finally
    Family.Free;
  end;
end;

procedure CheckSmallFamily;
var
  Family: TCutletPartitionFamily;
  First, Last: TIntArray;
begin
  Family := TCutletPartitionFamily.Create(3, 2, -1);
  try
    First := Family.Unrank1(BigOne);
    Last := Family.Unrank1(BigFromInt64(2));
    if (BigToDecimal(Family.CountAll) = '2') and
       (Length(First) = 2) and (First[0] = 1) and (First[1] = 2) and
       (Length(Last) = 2) and (Last[0] = 2) and (Last[1] = 1) then
    begin
      Inc(Passed);
      Writeln('OK: small valid partition and both ranks');
    end
    else
    begin
      Inc(Failed);
      Writeln('FALHA: small valid partition');
    end;
  finally
    Family.Free;
  end;
end;

begin
  Passed := 0;
  Failed := 0;
  try
    CheckSmallFamily;
    CheckReject('G=46341 K=2 memo table beyond Integer', 46341, 2);
    CheckReject('G=High(Integer) K=1 arithmetic overflow', High(Integer), 1);
    CheckReject('G=High(Integer) K=High(Integer) arithmetic overflow',
      High(Integer), High(Integer));
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
