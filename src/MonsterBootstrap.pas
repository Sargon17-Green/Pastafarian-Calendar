unit MonsterBootstrap;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  SysUtils, BigInt;

type
  TMonsterPhase = (mpEntry, mpValidation, mpDispatch, mpCompleted, mpFailed);
  TMonsterStatus = (msNew, msRunning, msCompleted, msFailed);

  TMetricEntry = record
    Name: string;
    Value: Int64;
  end;

  TMetricArray = array of TMetricEntry;
  TLogArray = array of UnicodeString;

  TMonsterContext = class
  public
    CalculationDay: TBigInt;
    TargetDay: TBigInt;
    Phase: TMonsterPhase;
    Status: TMonsterStatus;
    RetryBudget: Integer;
    Metrics: TMetricArray;
    Logs: TLogArray;
    LastErrorCode: string;
    constructor Create(const ACalculationDay, ATargetDay: TBigInt);
  end;

  TMetricsManager = class
  public
    procedure Increment(Context: TMonsterContext; const Name: string);
  end;

  TValidationManager = class
  public
    procedure RequireContextOwned(Context: TMonsterContext);
  end;

  TMonsterDispatcher = class
  public
    procedure DispatchBootstrap(Context: TMonsterContext);
  end;

  TMonsterManager = class
  private
    FMetrics: TMetricsManager;
    FValidation: TValidationManager;
    FDispatcher: TMonsterDispatcher;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ExecuteBootstrap(Context: TMonsterContext);
  end;

implementation

constructor TMonsterContext.Create(const ACalculationDay, ATargetDay: TBigInt);
begin
  inherited Create;
  CalculationDay := BigClone(ACalculationDay);
  TargetDay := BigClone(ATargetDay);
  Phase := mpEntry;
  Status := msNew;
  RetryBudget := 0;
  SetLength(Metrics, 0);
  SetLength(Logs, 0);
  LastErrorCode := '';
end;

procedure TMetricsManager.Increment(Context: TMonsterContext; const Name: string);
var
  I, N: Integer;
begin
  for I := 0 to High(Context.Metrics) do
    if Context.Metrics[I].Name = Name then
    begin
      Inc(Context.Metrics[I].Value);
      Exit;
    end;
  N := Length(Context.Metrics);
  SetLength(Context.Metrics, N + 1);
  Context.Metrics[N].Name := Name;
  Context.Metrics[N].Value := 1;
end;

procedure TValidationManager.RequireContextOwned(Context: TMonsterContext);
begin
  if Context = nil then
    raise Exception.Create('Contexto de invocação ausente.');
end;

procedure TMonsterDispatcher.DispatchBootstrap(Context: TMonsterContext);
var
  N: Integer;
begin
  Context.Phase := mpDispatch;
  Context.Status := msRunning;
  N := Length(Context.Logs);
  SetLength(Context.Logs, N + 1);
  Context.Logs[N] := 'bootstrap:dispatch';
end;

constructor TMonsterManager.Create;
begin
  inherited Create;
  FMetrics := TMetricsManager.Create;
  FValidation := TValidationManager.Create;
  FDispatcher := TMonsterDispatcher.Create;
end;

destructor TMonsterManager.Destroy;
begin
  FDispatcher.Free;
  FValidation.Free;
  FMetrics.Free;
  inherited Destroy;
end;

procedure TMonsterManager.ExecuteBootstrap(Context: TMonsterContext);
begin
  FValidation.RequireContextOwned(Context);
  Context.Phase := mpValidation;
  FMetrics.Increment(Context, 'bootstrap.calls');
  FDispatcher.DispatchBootstrap(Context);
  Context.Phase := mpCompleted;
  Context.Status := msCompleted;
  FMetrics.Increment(Context, 'bootstrap.completed');
end;

end.
