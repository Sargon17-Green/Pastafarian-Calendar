module Pastafari.MonsterBase
  ( BasePhase(..)
  , BaseStatus(..)
  , MetricCode(..)
  , DiagnosticCode(..)
  , MonsterError(..)
  , MonsterContext(..)
  , emptyContext
  , validateDays
  , dispatchBase
  , recordMetric
  , renderMonsterErrorCzech
  ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

data BasePhase
  = PhaseEntry
  | PhaseValidated
  | PhaseUnavailable
  deriving (Eq, Ord, Show)

data BaseStatus
  = StatusNew
  | StatusReady
  | StatusStopped
  deriving (Eq, Ord, Show)

data MetricCode
  = MetricInvocation
  | MetricValidation
  | MetricUnavailableReturn
  deriving (Eq, Ord, Show)

data DiagnosticCode
  = DiagnosticBootstrapOnly
  deriving (Eq, Ord, Show)

data MonsterError
  = StageNotAvailable Int
  | BaseInvariantFailure
  deriving (Eq, Ord, Show)

data MonsterContext = MonsterContext
  { calculationDay :: Integer
  , targetDay :: Integer
  , phase :: BasePhase
  , status :: BaseStatus
  , retryBudget :: Int
  , branchTrace :: [BasePhase]
  , metrics :: Map MetricCode Integer
  , diagnostics :: [DiagnosticCode]
  , lastError :: Maybe MonsterError
  } deriving (Eq, Show)

emptyContext :: Integer -> Integer -> MonsterContext
emptyContext cDay tDay = MonsterContext
  { calculationDay = cDay
  , targetDay = tDay
  , phase = PhaseEntry
  , status = StatusNew
  , retryBudget = 0
  , branchTrace = [PhaseEntry]
  , metrics = Map.singleton MetricInvocation 1
  , diagnostics = []
  , lastError = Nothing
  }

validateDays :: MonsterContext -> Either MonsterError MonsterContext
validateDays ctx =
  let next = recordMetric MetricValidation ctx
  in Right next
      { phase = PhaseValidated
      , status = StatusReady
      , branchTrace = branchTrace next ++ [PhaseValidated]
      }

dispatchBase :: MonsterContext -> Either MonsterError MonsterContext
dispatchBase ctx = do
  validated <- validateDays ctx
  let err = StageNotAvailable 1
      _stopped = (recordMetric MetricUnavailableReturn validated)
        { phase = PhaseUnavailable
        , status = StatusStopped
        , diagnostics = diagnostics validated ++ [DiagnosticBootstrapOnly]
        , lastError = Just err
        }
  Left err

recordMetric :: MetricCode -> MonsterContext -> MonsterContext
recordMetric code ctx =
  ctx { metrics = Map.insertWith (+) code 1 (metrics ctx) }

renderMonsterErrorCzech :: MonsterError -> String
renderMonsterErrorCzech (StageNotAvailable n) =
  "Autoritativní produkční cesta ještě není ve fázi " ++ show n ++ " dostupná."
renderMonsterErrorCzech BaseInvariantFailure =
  "Byla porušena základní invariantní podmínka zaváděcí vrstvy."
