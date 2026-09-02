unit PastafariCalendar;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  BigInt, MonsterBootstrap;

type
  TBootstrapResult = record
    ContextCompleted: Boolean;
    SourceCatalogVersion: string;
  end;

function BootstrapProbe(const CalculationDay, TargetDay: TBigInt): TBootstrapResult;

implementation

uses
  SourceLanguageCatalog;

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

end.
