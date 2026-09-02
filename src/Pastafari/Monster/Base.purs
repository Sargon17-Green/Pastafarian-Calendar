module Pastafari.Monster.Base
  ( MonsterContext
  , MonsterError(..)
  , MonsterMetric
  , MonsterPhase(..)
  , MonsterStatus(..)
  , initialContext
  , validateBootstrapContext
  , dispatchBootstrap
  , recordMetric
  ) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Pastafari.BigInteger (Big)

data MonsterPhase = Boot | Validate | Idle

derive instance eqMonsterPhase :: Eq MonsterPhase

data MonsterStatus = New | Ready | Failed

derive instance eqMonsterStatus :: Eq MonsterStatus

data MonsterError = MonsterError String

derive instance eqMonsterError :: Eq MonsterError

type MonsterMetric =
  { key :: String
  , value :: Int
  }

type MonsterContext =
  { calculationDay :: Big
  , targetDay :: Big
  , phase :: MonsterPhase
  , status :: MonsterStatus
  , branchTrace :: Array String
  , metrics :: Array MonsterMetric
  , validationFailures :: Array String
  }

initialContext :: Big -> Big -> MonsterContext
initialContext calculationDay targetDay =
  { calculationDay
  , targetDay
  , phase: Boot
  , status: New
  , branchTrace: [ "BOOT" ]
  , metrics: []
  , validationFailures: []
  }

recordMetric :: String -> MonsterContext -> MonsterContext
recordMetric key ctx = ctx { metrics = Array.snoc ctx.metrics { key, value: 1 } }

validateBootstrapContext :: MonsterContext -> Either MonsterError MonsterContext
validateBootstrapContext ctx =
  if ctx.phase == Boot && ctx.status == New then
    Right (ctx { phase = Validate, branchTrace = Array.snoc ctx.branchTrace "VALIDATE" })
  else
    Left (MonsterError "BOOTSTRAP_CONTEXT_INVALID")

dispatchBootstrap :: MonsterContext -> Either MonsterError MonsterContext
dispatchBootstrap ctx = do
  checked <- validateBootstrapContext ctx
  pure
    (recordMetric "bootstrap.dispatch"
      (checked
        { phase = Idle
        , status = Ready
        , branchTrace = Array.snoc checked.branchTrace "IDLE"
        }))
