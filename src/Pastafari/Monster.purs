module Pastafari.Monster
  ( bootstrapMonster
  ) where

import Data.Either (Either)
import Pastafari.BigInteger (Big)
import Pastafari.Monster.Base (MonsterContext, MonsterError, dispatchBootstrap, initialContext)

bootstrapMonster :: Big -> Big -> Either MonsterError MonsterContext
bootstrapMonster calculationDay targetDay =
  dispatchBootstrap (initialContext calculationDay targetDay)
