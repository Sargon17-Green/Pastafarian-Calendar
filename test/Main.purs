module Test.Main where

import Prelude

import Data.Array as Array
import Data.Foldable (traverse_)
import Effect (Effect)
import Effect.Console as Console
import Effect.Exception (error, throw)
import Pastafari.Stage01Suite (Check, allPassed, checks)

report :: Check -> Effect Unit
report x =
  if x.passed then Console.log ("ठीक: " <> x.label)
  else Console.log ("असफल: " <> x.label)

main :: Effect Unit
main = do
  traverse_ report checks
  if allPassed checks then
    Console.log ("Stage 1 का सबै " <> show (Array.length checks) <> " परीक्षण सफल भए।")
  else
    throw (error "Stage 1 परीक्षण असफल भयो।")
