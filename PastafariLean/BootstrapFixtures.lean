import PastafariLean.SourceLanguageCatalog
import PastafariLean.NormativeOracle
import PastafariLean.MonsterBase

namespace PastafariLean.BootstrapFixtures

open PastafariLean
open PastafariLean.NormativeOracle

structure BooleanFixture where
  name : String
  passed : Bool
  deriving Repr

private def stoneFixture : Bool :=
  let s := stones[1]!
  s.wheat == 378 &&
  s.barley == 1073 &&
  s.salt == 2375 &&
  s.bitter == 6195 &&
  s.red == 10493

private def catalogFixture : Bool :=
  sourceLanguageCatalogIsValid &&
  cutletNameByCanonicalIndex 12 == some "hvete" &&
  cutletNameByCanonicalIndex 17 == some "den tomme krukken" &&
  monthNameByCanonicalIndex 1 == some "leire" &&
  monthNameByCanonicalIndex 32 == some "den lukkede døren" &&
  monthNameByCanonicalIndex 47 == some "sand"

private def permutationFixture : Bool :=
  permutationUnrank1 1 == #[1, 2, 3, 4, 5, 6] &&
  permutationUnrank1 720 == #[6, 5, 4, 3, 2, 1]

private def boundedFixture : Bool :=
  countBoundedCompositions 7 2 2 5 == 4 &&
  unrankBoundedComposition 7 2 2 5 3 == #[4, 3]

private def cutletPartitionFixture : Bool :=
  countCutletPartitions 5 2 none == 4 &&
  countCutletPartitions 5 2 (some 2) == 1 &&
  unrankCutletPartition 5 2 1 (some 2) == #[2, 3]

private def weavingFixture : Bool :=
  countWeavings #[1, 1] == 1 &&
  unrankWeaving #[1, 1] 1 == #[1, 2] &&
  countWeavings #[2, 2] == 2 &&
  unrankWeaving #[2, 2] 1 == #[1, 1, 2, 2] &&
  unrankWeaving #[2, 2] 2 == #[1, 2, 1, 2]

private def shortSelectionFixture : Bool :=
  let stream : AnswerStream := { first := M, directionStep := -1 }
  chooseRankShort stream 3 == 3

private def wideSelectionFixture : Bool :=
  let stream : AnswerStream := { first := 1, directionStep := 1 }
  let n := M.toNat + 1
  chooseRankWide stream n == n

private def baseDispatcherFixture : Bool :=
  match bootstrapDispatchToCompletion foundationDay foundationDay with
  | .error _ => false
  | .ok ctx =>
      ctx.phase == .finished &&
      ctx.status == "FERDIG" &&
      ctx.branchTrace == #["ENTRY_TO_VALIDATE", "VALIDATE_TO_READY", "READY_TO_FINISHED"] &&
      ctx.semanticCommitVersion == 0


def fixtures : Array BooleanFixture := #[
  { name := "Katalogen er frosset og indeksstabil", passed := catalogFixture },
  { name := "SAVE håndterer nullresten normativt", passed := save M == M && save (2 * M) == M && save (M + 1) == 1 },
  { name := "Dagtellingen rundt grunnleggelsen er eksakt", passed := dayCount foundationDay == 1 && dayCount (foundationDay - 1) == 2 && dayCount (foundationDay + 1) == 3 },
  { name := "Arbeidstelling ved samme dag er eksakt", passed := workCounts foundationDay foundationDay == { action := 1, target := 1, distance := 1, connection := 2, direction := 2 } },
  { name := "A1 bruker det lagrede røresummet med 149 ganger røringen", passed := savedStirSum #[1, 2, 3, 4, 5, 6] 1 == 170 },
  { name := "Andre steinrad bruker ett gammelt øyeblikksbilde", passed := stoneFixture },
  { name := "Permutasjonsrangene 1 og 720 er eksakte", passed := permutationFixture },
  { name := "Kort avvisningsvalg bruker samme svarring", passed := shortSelectionFixture },
  { name := "Bredt valg beholder det brede tallet", passed := wideSelectionFixture },
  { name := "Bundne komposisjoner telles og åpnes leksikografisk", passed := boundedFixture },
  { name := "Kotelettgrensen filtreres uten å endre leksikografisk orden", passed := cutletPartitionFixture },
  { name := "Månedsveving telles og åpnes som et helt vev", passed := weavingFixture },
  { name := "Den nøytrale dispatcheren fullfører uten fremtidige lapper", passed := baseDispatcherFixture }
]


def fixturesPass : Bool := Id.run do
  let mut ok := true
  for f in fixtures do
    if !f.passed then
      ok := false
  return ok

end PastafariLean.BootstrapFixtures
