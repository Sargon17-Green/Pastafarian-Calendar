unit PastafariCalendar;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  BigInt, MonsterBootstrap, Stage02WorkCounts;

type
  TStoneSnapshot = array[1..5] of TBigInt;
  TStoneSnapshotTable = array[1..46] of TStoneSnapshot;

  TBootstrapResult = record
    ContextCompleted: Boolean;
    SourceCatalogVersion: string;
  end;

function BootstrapProbe(const CalculationDay, TargetDay: TBigInt): TBootstrapResult;
function WorkCountsForContext(Context: TMonsterContext): TWorkCounts;

{ Stage09: all cells read the immutable preceding row. }
function StoneSnapshot: TStoneSnapshotTable;

implementation

uses
  SourceLanguageCatalog, SysUtils;

function BootstrapProbe(const CalculationDay, TargetDay: TBigInt): TBootstrapResult;
var
  Context: TMonsterContext;
  Manager: TMonsterManager;
begin
  Context := TMonsterContext.Create(CalculationDay, TargetDay);
  Manager := TMonsterManager.Create;
  try
    Manager.ExecuteBootstrap(Context);
    Result.ContextCompleted := Context.Status = msCompleted;
    Result.SourceCatalogVersion := SOURCE_LANGUAGE_CATALOG_VERSION;
  finally
    Manager.Free;
    Context.Free;
  end;
end;

function WorkCountsForContext(Context: TMonsterContext): TWorkCounts;
begin
  if Context = nil then
    raise Exception.Create('Contexto de invocação ausente.');
  Result := ComputeWorkCounts(Context.CalculationDay, Context.TargetDay);
end;


function StoneSnapshot: TStoneSnapshotTable;
const
  Seeds: array[1..5] of Integer = (17, 29, 43, 71, 101);
  Coefficients: array[1..5] of Integer = (3, 5, 7, 11, 13);
var
  Row, Kind, Neighbour: Integer;
  Extra, Raw: TBigInt;
begin
  for Kind := 1 to 5 do
    Result[1][Kind] := BigFromInt64(Seeds[Kind]);
  for Row := 2 to 46 do
    for Kind := 1 to 5 do
    begin
      Neighbour := (Kind mod 5) + 1;
      if Kind = 1 then
        Extra := BigFromInt64(Row)
      else
        Extra := Result[Row - 1][Kind - 1];
      Raw := BigAdd(BigAdd(BigSquare(Result[Row - 1][Kind]),
        BigMultiplyInt64(Result[Row - 1][Neighbour], Coefficients[Kind])), Extra);
      Result[Row][Kind] := BigSave(Raw);
    end;
end;

end.
