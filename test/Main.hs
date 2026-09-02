module Main (main) where

import Control.Monad (forM_, unless)
import Data.List (nub)
import BootstrapFixtures
import Pastafari.MonsterBase (MonsterError(..))
import Pastafari.NormativeOracle
import Pastafari.SourceLanguageCatalog
import Pastafari.SpaghettiMonster (calendarDateSpaghetti)

assertTrue :: String -> Bool -> IO ()
assertTrue label condition = unless condition (error ("SELHÁNÍ: " ++ label))

assertEqual :: (Eq a, Show a) => String -> a -> a -> IO ()
assertEqual label expected actual =
  unless (expected == actual)
    (error ("SELHÁNÍ: " ++ label ++ "; očekáváno " ++ show expected ++ ", získáno " ++ show actual))

main :: IO ()
main = do
  testConstants
  testSave
  testDayCounts
  testWorkCounts
  testStones
  testPermutation
  testSelections
  testDistinctUnrank
  testBoundedCompositions
  testCutletPartitions
  testWeavings
  testCatalog
  testMonsterSkeleton
  putStrLn "Všechny testy první fáze prošly."

testConstants :: IO ()
testConstants = do
  assertEqual "rozdíl mezi dnem desek a dnem založení" 14777149 (tabletsDay - foundationDay)
  assertEqual "hodnota M" 170141183460469231731687303715884105727 m

testSave :: IO ()
testSave =
  forM_ saveFixtures $ \(input, expected) ->
    assertEqual ("SAVE pro " ++ show input) expected (save input)

testDayCounts :: IO ()
testDayCounts =
  forM_ dayCountFixtures $ \(day, expected) ->
    assertEqual ("číslování dne " ++ show day) expected (dayCount day)

testWorkCounts :: IO ()
testWorkCounts = do
  assertEqual "počty v den založení"
    (WorkCounts 1 1 1 2 2)
    (workCounts foundationDay foundationDay)
  assertEqual "počty den po založení"
    (WorkCounts 1 3 2 4 3)
    (workCounts foundationDay (foundationDay + 1))
  assertEqual "počty přes založení"
    (WorkCounts 3 2 3 5 1)
    (workCounts (foundationDay + 1) (foundationDay - 1))

testStones :: IO ()
testStones = do
  assertEqual "počet řádků kamenů" 46 (length buildStones)
  assertEqual "první řádek kamenů" (Stone 17 29 43 71 101) (head buildStones)
  assertEqual "druhý řádek kamenů" (Stone 378 1073 2375 6195 10493) (buildStones !! 1)

testPermutation :: IO ()
testPermutation = do
  assertEqual "první pořadí misek" [1,2,3,4,5,6] (bowlOrderFromDrop 1)
  assertEqual "sedmisté dvacáté pořadí misek" [6,5,4,3,2,1] (bowlOrderFromDrop 720)
  assertEqual "zabalení pořadí po 720" [1,2,3,4,5,6] (bowlOrderFromDrop 721)

testSelections :: IO ()
testSelections = do
  let forwardOne = AnswerStream 1 1
      forwardLast = AnswerStream m 1
  assertEqual "krátký výběr z jediné možnosti" 1 (chooseRankShort forwardOne 1)
  assertEqual "krátký výběr na hranici M" 1 (chooseRankShort forwardOne m)
  assertEqual "odmítnutí posledního lichého zbytku při N=2" 1 (chooseRankShort forwardLast 2)
  assertEqual "široký výběr M+1" (m + 1) (chooseRankWide forwardOne (m + 1))
  assertEqual "široký výběr M na druhou" (m + 1) (chooseRankWide forwardOne (m * m))
  assertEqual "široký výběr M na druhou plus jedna" (m - 1) (chooseRankWide forwardOne (m * m + 1))

testDistinctUnrank :: IO ()
testDistinctUnrank = do
  let expected = [[1,2],[1,3],[2,1],[2,3],[3,1],[3,2]]
      actual = [unrankDistinctIndices 3 2 r | r <- [1..6]]
  assertEqual "lexikografické odrankování různých názvů" expected actual
  assertEqual "počet částečných permutací" 6 (fallingFactorial 3 2)

testBoundedCompositions :: IO ()
testBoundedCompositions = do
  assertEqual "počet omezených kompozic" 4 (countBoundedCompositions 5 2 1 4)
  forM_ boundedCompositionFixtures $ \(rank, expected) ->
    assertEqual ("omezená kompozice pořadí " ++ show rank)
      expected
      (unrankBoundedComposition 5 2 1 4 rank)

testCutletPartitions :: IO ()
testCutletPartitions = do
  assertEqual "počet dělení s povinnou vnitřní hranicí" 4 (countCutletPartitions 6 3 (Just 3))
  forM_ cutletPartitionFixtures $ \(rank, expected) ->
    assertEqual ("dělení kotlet pořadí " ++ show rank)
      expected
      (unrankCutletPartition 6 3 (Just 3) rank)

testWeavings :: IO ()
testWeavings = do
  assertEqual "počet malých legálních propletení" 2 (countWeavings [2,2])
  forM_ weavingFixtures $ \(rank, expected) ->
    assertEqual ("propletení pořadí " ++ show rank) expected (unrankWeaving [2,2] rank)
  assertEqual "jediné propletení dvou jednovýskytových měsíců" [1,2] (unrankWeaving [1,1] 1)

testCatalog :: IO ()
testCatalog = do
  let cutletIndices = map canonicalIndex cutletCatalog
      monthIndices = map canonicalIndex monthCatalog
  assertEqual "počet českých názvů kotlet" 17 (length cutletCatalog)
  assertEqual "počet českých názvů měsíců" 47 (length monthCatalog)
  assertEqual "indexy kotlet jsou přesně 1 až 17" [1..17] cutletIndices
  assertEqual "indexy měsíců jsou přesně 1 až 47" [1..47] monthIndices
  assertEqual "indexy kotlet se neopakují" 17 (length (nub cutletIndices))
  assertEqual "indexy měsíců se neopakují" 47 (length (nub monthIndices))
  assertEqual "pšenice je dvanáctá kotleta" (Just "pšenice") (cutletNameByIndex 12)
  assertEqual "sůl je čtyřicátý čtvrtý měsíc" (Just "sůl") (monthNameByIndex 44)
  assertEqual "verze katalogu" "cs-stage01-v1" catalogFrozenVersion
  assertTrue "řazení katalogu není odvozeno z české abecedy" (map czechText cutletCatalog /= quickSortText (map czechText cutletCatalog))
  where
    quickSortText [] = []
    quickSortText (x:xs) = quickSortText [y | y <- xs, y <= x] ++ [x] ++ quickSortText [y | y <- xs, y > x]

testMonsterSkeleton :: IO ()
testMonsterSkeleton =
  assertEqual "produkční kostra nesmí v první fázi předstírat hotový výsledek"
    (Left (StageNotAvailable 1))
    (calendarDateSpaghetti foundationDay foundationDay)
