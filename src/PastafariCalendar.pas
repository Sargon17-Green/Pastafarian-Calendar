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

  THiddenDropTrace = array[1..7, 0..7] of TBigInt;
  THiddenDropHistory = array[-6..0] of TBigInt;

  TBootstrapResult = record
    ContextCompleted: Boolean;
    SourceCatalogVersion: string;
  end;

function BootstrapProbe(const CalculationDay, TargetDay: TBigInt): TBootstrapResult;
function WorkCountsForContext(Context: TMonsterContext): TWorkCounts;

{ Stage09: all cells read the immutable preceding row. }
function StoneSnapshot: TStoneSnapshotTable;

{ Stage10: caminho ativo para descoberta; ordem cronologica intencionalmente errada. }
function HiddenDropHistory(const CalculationDay, TargetDay: TBigInt;
  out Trace: THiddenDropTrace): THiddenDropHistory;

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

function HiddenDropHistory(const CalculationDay, TargetDay: TBigInt;
  out Trace: THiddenDropTrace): THiddenDropHistory;
var
  Counts: TWorkCounts;
  Stones: TStoneSnapshotTable;
  X, Raw: TBigInt;
  K, R, J: Integer;
begin
  Counts := ComputeWorkCounts(CalculationDay, TargetDay);
  Stones := StoneSnapshot;
  for K := 1 to 7 do
  begin
    Raw := BigClone(Counts.Action);
    Raw := BigAdd(Raw, BigMultiplyInt64(Counts.Target, 2*K+1));
    Raw := BigAdd(Raw, BigMultiplyInt64(Counts.Distance, 3*K+1));
    Raw := BigAdd(Raw, BigMultiplyInt64(Counts.Connection, 4*K+2));
    Raw := BigAddInt64(Raw, (4*K+4)*Counts.Direction);
    for J := 1 to 5 do
      Raw := BigAdd(Raw, Stones[K][J]);
    X := BigSave(Raw);
    Trace[K][0] := X;
    for R := 1 to 7 do
    begin
      Raw := BigAdd(BigSquare(X), BigMultiplyInt64(X, 3));
      Raw := BigAdd(Raw, Stones[K][((R-1) mod 5)+1]);
      X := BigSave(BigAddInt64(Raw, R));
      Trace[K][R] := X;
    end;
    { DEFEITO INJETADO INTENCIONALMENTE, Stage10, 2026-11-28.
      Autorizacao explicita do utilizador. Nao e defeito historico.
      Guarda k=1 na posicao -6 e k=7 na posicao 0.
      A regra normativa seria posicao 1-K; Stage11 nao autorizado. }
    Result[K-7] := X;
  end;
end;

end.
