import Std
import PastafariLean.SourceLanguageCatalog

namespace PastafariLean.NormativeOracle

open PastafariLean

abbrev Day := Int

private def pow2 (n : Nat) : Int := (2 : Int) ^ n

def M : Int := pow2 127 - 1

def tabletsDay : Day := -278522

def foundationDay : Day := -15055671

def yearMinDays : Int := 252

def yearMaxDays : Int := 5778

def gateGapMin : Int := 42

def gateGapMax : Int := 963

def minCutlets : Nat := 6

def maxCutlets : Nat := 17

def minMonths : Nat := 3

def maxMonths : Nat := 47

def minMonthDays : Nat := 4

def maxMonthDays : Nat := 123

private def natToInt (n : Nat) : Int := Int.ofNat n

private def intToNat (x : Int) : Nat := x.toNat

private def absInt (x : Int) : Int := if x < 0 then -x else x

private def minNat (a b : Nat) : Nat := if a < b then a else b

private def maxNat (a b : Nat) : Nat := if a < b then b else a

private def ceilDivNat (a b : Nat) : Nat :=
  if b == 0 then 0 else (a + b - 1) / b

private def wrap1 (position size : Nat) : Nat :=
  if size == 0 then 0 else ((position + size - 1) % size) + 1

private def get1 [Inhabited α] (a : Array α) (i : Nat) : α :=
  a[i - 1]!

private def set1 [Inhabited α] (a : Array α) (i : Nat) (v : α) : Array α :=
  a.set! (i - 1) v

private def regularMod (x d : Int) : Int :=
  if d <= 0 then 0 else x % d


def save (x : Int) : Int :=
  1 + regularMod (x - 1) M


def dayCount (day : Day) : Int :=
  if day == foundationDay then
    1
  else if day > foundationDay then
    2 * (day - foundationDay) + 1
  else
    2 * (foundationDay - day)

structure WorkCounts where
  action : Int
  target : Int
  distance : Int
  connection : Int
  direction : Int
  deriving Repr, BEq


def workCounts (calculationDay targetDay : Day) : WorkCounts :=
  let c := dayCount calculationDay
  let t := dayCount targetDay
  let distance := absInt (targetDay - calculationDay) + 1
  let connection := c + t
  let direction := if targetDay < calculationDay then 1 else if targetDay == calculationDay then 2 else 3
  { action := c, target := t, distance, connection, direction }

structure Stone where
  wheat : Int
  barley : Int
  salt : Int
  bitter : Int
  red : Int
  deriving Repr, BEq, Inhabited

private def firstStone : Stone := {
  wheat := 17
  barley := 29
  salt := 43
  bitter := 71
  red := 101
}

private def nextStone (i : Nat) (old : Stone) : Stone := {
  wheat := save (old.wheat * old.wheat + 3 * old.barley + natToInt i)
  barley := save (old.barley * old.barley + 5 * old.salt + old.wheat)
  salt := save (old.salt * old.salt + 7 * old.bitter + old.barley)
  bitter := save (old.bitter * old.bitter + 11 * old.red + old.salt)
  red := save (old.red * old.red + 13 * old.wheat + old.bitter)
}


def buildStones : Array Stone := Id.run do
  let mut out := #[firstStone]
  let mut current := firstStone
  for i in [2:47] do
    current := nextStone i current
    out := out.push current
  return out


def stones : Array Stone := buildStones

private def stoneValue (s : Stone) (kind : Nat) : Int :=
  match kind with
  | 1 => s.wheat
  | 2 => s.barley
  | 3 => s.salt
  | 4 => s.bitter
  | 5 => s.red
  | _ => 0

private def hiddenCoefficients : Array (Int × Int × Int × Int) := #[
  (3, 4, 6, 8),
  (5, 7, 10, 12),
  (7, 10, 14, 16),
  (9, 13, 18, 20),
  (11, 16, 22, 24),
  (13, 19, 26, 28),
  (15, 22, 30, 32)
]

private def hiddenGrindStone : Array Nat := #[1, 2, 3, 4, 5, 1, 2]


def buildHiddenDrops (counts : WorkCounts) : Array Int := Id.run do
  let mut hidden := #[]
  for k0 in [0:7] do
    let k := k0 + 1
    let coeff := hiddenCoefficients[k0]!
    let a := coeff.1
    let b := coeff.2.1
    let c := coeff.2.2.1
    let d := coeff.2.2.2
    let st := stones[k0]!
    let mut x := counts.action
      + a * counts.target
      + b * counts.distance
      + c * counts.connection
      + d * counts.direction
      + st.wheat + st.barley + st.salt + st.bitter + st.red
    x := save x
    for g0 in [0:7] do
      let g := g0 + 1
      let oldX := x
      let kind := hiddenGrindStone[g0]!
      x := save (oldX * oldX + 3 * oldX + stoneValue st kind + natToInt g)
    hidden := hidden.push x
  return hidden

structure VisibleGrind where
  a : Int
  b : Int
  c : Int
  d : Int
  kind : Nat
  deriving Repr, Inhabited

private def visibleGrinds : Array VisibleGrind := #[
  { a := 3, b := 5, c := 7, d := 11, kind := 1 },
  { a := 5, b := 7, c := 11, d := 13, kind := 2 },
  { a := 7, b := 11, c := 13, d := 17, kind := 3 },
  { a := 11, b := 13, c := 17, d := 19, kind := 4 },
  { a := 13, b := 17, c := 19, d := 23, kind := 5 },
  { a := 17, b := 19, c := 23, d := 29, kind := 1 },
  { a := 19, b := 23, c := 29, d := 31, kind := 2 },
  { a := 23, b := 29, c := 31, d := 37, kind := 3 },
  { a := 29, b := 31, c := 37, d := 41, kind := 4 },
  { a := 31, b := 37, c := 41, d := 43, kind := 5 },
  { a := 37, b := 41, c := 43, d := 47, kind := 1 }
]

private def timelinePrior (hidden visible : Array Int) (i back : Nat) : Int :=
  if i > back then
    visible[i - back - 1]!
  else
    let k := back - i + 1
    hidden[k - 1]!


def buildVisibleDrops (counts : WorkCounts) (hidden : Array Int) : Array Int := Id.run do
  let mut visible := #[]
  for i0 in [0:46] do
    let i := i0 + 1
    let p1 := timelinePrior hidden visible i 1
    let p3 := timelinePrior hidden visible i 3
    let p7 := timelinePrior hidden visible i 7
    let st := stones[i0]!
    let mut x := save (
      st.wheat * counts.action
      + st.barley * counts.target
      + st.salt * counts.distance
      + st.bitter * counts.connection
      + st.red * counts.direction
      + p1 + 3 * p3 + 5 * p7 + natToInt i)
    for g0 in [0:11] do
      let row := visibleGrinds[g0]!
      let oldX := x
      x := save (
        oldX * oldX
        + row.a * oldX
        + row.b * p1
        + row.c * p3
        + row.d * p7
        + stoneValue st row.kind)
    visible := visible.push x
  return visible

private def factorial : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * factorial n

private def removeAt (xs : Array Nat) (idx : Nat) : Array Nat := Id.run do
  let mut out := #[]
  for i in [0:xs.size] do
    if i != idx then
      out := out.push xs[i]!
  return out


def permutationUnrank1 (rank1 : Nat) : Array Nat := Id.run do
  let mut rank0 := rank1 - 1
  let mut remaining : Array Nat := #[1, 2, 3, 4, 5, 6]
  let mut result := #[]
  while remaining.size > 0 do
    let block := factorial (remaining.size - 1)
    let q := if block == 0 then 0 else rank0 / block
    rank0 := if block == 0 then 0 else rank0 % block
    result := result.push remaining[q]!
    remaining := removeAt remaining q
  return result


def bowlOrderFromDrop (dropValue : Int) : Array Nat :=
  let orderNumber := intToNat (regularMod (dropValue - 1) 720 + 1)
  permutationUnrank1 orderNumber

private def bowlPrimes : Array Int := #[17, 19, 23, 29, 31, 37]
private def bowlStirStoneByPosition : Array Nat := #[1, 2, 3, 4, 5, 1]


def initialBowls (counts : WorkCounts) : Array Int := Id.run do
  let mut bowls := #[]
  for id0 in [0:6] do
    let id := id0 + 1
    let p := bowlPrimes[id0]!
    let s := counts.action
      + counts.target * natToInt id
      + counts.distance
      + counts.connection
      + counts.direction
      + p * p
    bowls := bowls.push (save (s * s + natToInt id))
  return bowls

private def stirDropRound (bowls : Array Int) (drop : Int) (i : Nat) (st : Stone)
    (order : Array Nat) : Array Int := Id.run do
  let old := bowls
  let firstBowl := get1 order 1
  let secondBowl := get1 order 2
  let thirdBowl := get1 order 3
  let mut pour : Array Int := #[0, 0, 0, 0, 0, 0]
  pour := set1 pour 1 (save (drop * drop + st.wheat * get1 old firstBowl + 3 * natToInt i))
  pour := set1 pour 2 (save (drop * drop + st.barley * get1 old secondBowl + 5 * natToInt i))
  pour := set1 pour 3 (save (drop * drop + st.salt * get1 old thirdBowl + 7 * natToInt i))
  let mut nextBowls := old
  for pos0 in [0:6] do
    let position := pos0 + 1
    let bowlId := get1 order position
    let prevId := get1 order (wrap1 (position + 5) 6)
    let nextId := get1 order (wrap1 (position + 1) 6)
    let stoneKind := bowlStirStoneByPosition[pos0]!
    let s := get1 old bowlId
      + 2 * get1 old prevId
      + 3 * get1 old nextId
      + get1 pour position
      + drop
      + stoneValue st stoneKind
    let v := save (s * s + 5 * get1 old prevId * get1 old nextId + natToInt i * natToInt position)
    nextBowls := set1 nextBowls bowlId v
  return nextBowls

structure BowlDropResult where
  bowls : Array Int
  orderAtDrop46 : Array Nat
  deriving Repr


def applyVisibleDropsToBowls (startBowls visible : Array Int) : BowlDropResult := Id.run do
  let mut bowls := startBowls
  let mut orderAt46 : Array Nat := #[]
  for i0 in [0:46] do
    let i := i0 + 1
    let drop := visible[i0]!
    let order := bowlOrderFromDrop drop
    bowls := stirDropRound bowls drop i stones[i0]! order
    if i == 46 then
      orderAt46 := order
  return { bowls, orderAtDrop46 := orderAt46 }



def savedStirSum (bowls : Array Int) (stir : Nat) : Int :=
  save (
    get1 bowls 1 + get1 bowls 2 + get1 bowls 3 + get1 bowls 4 + get1 bowls 5 + get1 bowls 6
    + 149 * natToInt stir)

def postStir12 (startBowls : Array Int) : Array Int := Id.run do
  let mut bowls := startBowls
  for stir0 in [0:12] do
    let stir := stir0 + 1
    let old := bowls
    let savedBowlSum := savedStirSum old stir
    let orderNumber := intToNat (regularMod (savedBowlSum - 1) 720 + 1)
    let order := permutationUnrank1 orderNumber
    let mut nextBowls := old
    for pos0 in [0:6] do
      let position := pos0 + 1
      let bowlId := get1 order position
      let prevId := get1 order (wrap1 (position + 5) 6)
      let nextId := get1 order (wrap1 (position + 1) 6)
      let s := get1 old bowlId
        + 3 * get1 old prevId
        + 5 * get1 old nextId
        + savedBowlSum
        + natToInt stir
        + natToInt (position * position)
      let v := save (s * s + 7 * get1 old prevId * get1 old nextId)
      nextBowls := set1 nextBowls bowlId v
    bowls := nextBowls
  return bowls

structure SauceResult where
  bowls : Array Int
  orderAtDrop46 : Array Nat
  deriving Repr


def sauce (calculationDay targetDay : Day) : SauceResult :=
  let counts := workCounts calculationDay targetDay
  let hidden := buildHiddenDrops counts
  let visible := buildVisibleDrops counts hidden
  let initial := initialBowls counts
  let afterDrops := applyVisibleDropsToBowls initial visible
  let finalBowls := postStir12 afterDrops.bowls
  { bowls := finalBowls, orderAtDrop46 := afterDrops.orderAtDrop46 }

structure AnswerStream where
  first : Int
  directionStep : Int
  deriving Repr, BEq

private def indexOfNat (xs : Array Nat) (needle : Nat) : Nat := Id.run do
  let mut found := 0
  let mut done := false
  for i in [0:xs.size] do
    if !done && xs[i]! == needle then
      found := i
      done := true
  return found


def nextBowlInDrop46Order (s : SauceResult) (queriedBowlId : Nat) : Nat :=
  let p0 := indexOfNat s.orderAtDrop46 queriedBowlId
  s.orderAtDrop46[(p0 + 1) % 6]!


def askBowl (s : SauceResult) (queriedBowlId : Nat) (seal : Int) : AnswerStream :=
  let nextId := nextBowlInDrop46Order s queriedBowlId
  let first := save (
    (get1 s.bowls queriedBowlId + seal + 181) * (get1 s.bowls queriedBowlId + seal + 181)
    + 179 * get1 s.bowls nextId
    + seal)
  let directionNumber := save (
    (first + seal + 194) * (first + seal + 194)
    + 193 * first
    + 197 * get1 s.bowls 6)
  let step := if regularMod directionNumber 2 == 1 then 1 else -1
  { first, directionStep := step }


def answerAt (stream : AnswerStream) (k : Nat) : Int :=
  1 + regularMod (stream.first - 1 + stream.directionStep * natToInt k) M


def chooseRankShort (stream : AnswerStream) (n : Nat) : Nat := Id.run do
  if n == 0 then
    return 0
  let nInt := natToInt n
  let limit := (M / nInt) * nInt
  let mut k := 0
  let mut answer := answerAt stream 0
  while answer > limit do
    k := k + 1
    answer := answerAt stream k
  return intToNat (regularMod (answer - 1) nInt + 1)


def chooseRankWide (stream : AnswerStream) (n : Nat) : Nat := Id.run do
  if n == 0 then
    return 0
  let nInt := natToInt n
  let mut places := 1
  let mut space := M
  while space < nInt do
    places := places + 1
    space := space * M
  let mut wide := 1
  let mut weight := 1
  for j in [0:places] do
    wide := wide + (answerAt stream j - 1) * weight
    weight := weight * M
  let limit := (space / nInt) * nInt
  while wide > limit do
    wide := 1 + regularMod (wide - 1 + stream.directionStep) space
  return intToNat (regularMod (wide - 1) nInt + 1)


def chooseRank (stream : AnswerStream) (n : Nat) : Nat :=
  if natToInt n <= M then chooseRankShort stream n else chooseRankWide stream n


def fallingFactorial (n k : Nat) : Nat := Id.run do
  let mut out := 1
  for j in [0:k] do
    out := out * (n - j)
  return out


def unrankDistinctIndices (n k rank1 : Nat) : Array Nat := Id.run do
  let mut remaining := #[]
  for i in [1:n+1] do
    remaining := remaining.push i
  let mut out := #[]
  let mut r := rank1
  for position0 in [0:k] do
    let suffixLength := k - position0 - 1
    let block := fallingFactorial (remaining.size - 1) suffixLength
    let mut chosen := 0
    let mut chosenSet := false
    for candidate0 in [0:remaining.size] do
      if !chosenSet then
        if r > block then
          r := r - block
        else
          chosen := candidate0
          chosenSet := true
    out := out.push remaining[chosen]!
    remaining := removeAt remaining chosen
  return out

structure BoundedKey where
  rem : Nat
  slots : Nat
  deriving BEq, Hashable

abbrev BoundedMemo := Std.HashMap BoundedKey Nat

partial def countBoundedM (lo hi : Nat) (rem slots : Nat) : StateM BoundedMemo Nat := do
  if slots == 0 then
    return if rem == 0 then 1 else 0
  if rem < slots * lo || rem > slots * hi then
    return 0
  let key : BoundedKey := { rem, slots }
  let memo ← get
  match memo.get? key with
  | some v => return v
  | none =>
      let mut total := 0
      for x in [lo:hi+1] do
        if x <= rem then
          total := total + (← countBoundedM lo hi (rem - x) (slots - 1))
      modify (fun m => m.insert key total)
      return total


def countBoundedCompositions (total slots lo hi : Nat) : Nat :=
  (countBoundedM lo hi total slots).run ∅ |>.1

partial def unrankBoundedCompositionM (total slots lo hi rank1 : Nat) : StateM BoundedMemo (Array Nat) := do
  let mut r := rank1
  let mut rem := total
  let mut left := slots
  let mut out := #[]
  while left > 0 do
    let mut chosen := lo
    let mut found := false
    for x in [lo:hi+1] do
      if !found && x <= rem then
        let count ← countBoundedM lo hi (rem - x) (left - 1)
        if r > count then
          r := r - count
        else
          chosen := x
          found := true
    out := out.push chosen
    rem := rem - chosen
    left := left - 1
  return out


def unrankBoundedComposition (total slots lo hi rank1 : Nat) : Array Nat :=
  (unrankBoundedCompositionM total slots lo hi rank1).run ∅ |>.1
structure CutletKey where
  rem : Nat
  slots : Nat
  cumulative : Nat
  hitBoundary : Bool
  deriving BEq, Hashable

abbrev CutletMemo := Std.HashMap CutletKey Nat

partial def countCutletM (required : Option Nat) (rem slots cumulative : Nat) (hitBoundary : Bool) : StateM CutletMemo Nat := do
  if slots == 0 then
    if rem != 0 then
      return 0
    match required with
    | none => return 1
    | some _ => return if hitBoundary then 1 else 0
  if rem < slots then
    return 0
  let key : CutletKey := { rem, slots, cumulative, hitBoundary }
  let memo ← get
  match memo.get? key with
  | some v => return v
  | none =>
      let mut total := 0
      let maxX := rem - (slots - 1)
      for x in [1:maxX+1] do
        let nextCumulative := cumulative + x
        let mut nextHit := hitBoundary
        let mut allowed := true
        match required with
        | none => pure ()
        | some boundary =>
            if !hitBoundary then
              if nextCumulative == boundary then
                nextHit := true
              else if nextCumulative > boundary then
                allowed := false
        if allowed then
          total := total + (← countCutletM required (rem - x) (slots - 1) nextCumulative nextHit)
      modify (fun m => m.insert key total)
      return total


def countCutletPartitions (gaps cutletCount : Nat) (required : Option Nat) : Nat :=
  (countCutletM required gaps cutletCount 0 false).run ∅ |>.1

partial def unrankCutletPartitionM (gaps cutletCount rank1 : Nat) (required : Option Nat) : StateM CutletMemo (Array Nat) := do
  let mut r := rank1
  let mut rem := gaps
  let mut slots := cutletCount
  let mut cumulative := 0
  let mut hit := false
  let mut out := #[]
  while slots > 0 do
    let maxX := rem - (slots - 1)
    let mut chosen := 1
    let mut chosenHit := hit
    let mut found := false
    for x in [1:maxX+1] do
      if !found then
        let nextCumulative := cumulative + x
        let mut nextHit := hit
        let mut allowed := true
        match required with
        | none => pure ()
        | some boundary =>
            if !hit then
              if nextCumulative == boundary then
                nextHit := true
              else if nextCumulative > boundary then
                allowed := false
        if allowed then
          let block ← countCutletM required (rem - x) (slots - 1) nextCumulative nextHit
          if r > block then
            r := r - block
          else
            chosen := x
            chosenHit := nextHit
            found := true
    out := out.push chosen
    rem := rem - chosen
    cumulative := cumulative + chosen
    hit := chosenHit
    slots := slots - 1
  return out


def unrankCutletPartition (gaps cutletCount rank1 : Nat) (required : Option Nat) : Array Nat :=
  (unrankCutletPartitionM gaps cutletCount rank1 required).run ∅ |>.1
structure WeaveState where
  remaining : Array Nat
  openedUpTo : Nat
  closedUpTo : Nat
  deriving BEq, Hashable

private def allZero (xs : Array Nat) : Bool := Id.run do
  let mut yes := true
  for i in [0:xs.size] do
    if xs[i]! != 0 then
      yes := false
  return yes

private def sumNatArray (xs : Array Nat) : Nat := Id.run do
  let mut total := 0
  for x in xs do
    total := total + x
  return total

private def legalWeaveMove (lengths : Array Nat) (state : WeaveState) (j : Nat) : Bool :=
  if j == 0 || j > state.remaining.size then
    false
  else
    let remaining := get1 state.remaining j
    if remaining == 0 then
      false
    else
      let alreadyOpened := remaining < get1 lengths j
      if !alreadyOpened && j != state.openedUpTo + 1 then
        false
      else
        let willClose := remaining == 1
        if willClose && j != state.closedUpTo + 1 then false else true

private def applyWeaveMove (lengths : Array Nat) (state : WeaveState) (j : Nat) : WeaveState :=
  let firstUse := get1 state.remaining j == get1 lengths j
  let opened := if firstUse then j else state.openedUpTo
  let remaining := set1 state.remaining j (get1 state.remaining j - 1)
  let closed := if get1 remaining j == 0 then j else state.closedUpTo
  { remaining, openedUpTo := opened, closedUpTo := closed }

abbrev WeaveMemo := Std.HashMap WeaveState Nat

partial def countWeavingsM (lengths : Array Nat) (state : WeaveState) : StateM WeaveMemo Nat := do
  if allZero state.remaining then
    return 1
  let memo ← get
  match memo.get? state with
  | some v => return v
  | none =>
      let mut total := 0
      for j in [1:lengths.size+1] do
        if legalWeaveMove lengths state j then
          total := total + (← countWeavingsM lengths (applyWeaveMove lengths state j))
      modify (fun m => m.insert state total)
      return total

private def initialWeaveState (lengths : Array Nat) : WeaveState :=
  { remaining := lengths, openedUpTo := 0, closedUpTo := 0 }


def countWeavings (lengths : Array Nat) : Nat :=
  (countWeavingsM lengths (initialWeaveState lengths)).run ∅ |>.1

partial def unrankWeavingM (lengths : Array Nat) (rank1 : Nat) : StateM WeaveMemo (Array Nat) := do
  let mut state := initialWeaveState lengths
  let mut r := rank1
  let mut out := #[]
  let totalDays := sumNatArray lengths
  while out.size < totalDays do
    let mut chosen := 0
    let mut chosenState := state
    let mut found := false
    for j in [1:lengths.size+1] do
      if !found && legalWeaveMove lengths state j then
        let next := applyWeaveMove lengths state j
        let block ← countWeavingsM lengths next
        if r > block then
          r := r - block
        else
          chosen := j
          chosenState := next
          found := true
    out := out.push chosen
    state := chosenState
  return out


def unrankWeaving (lengths : Array Nat) (rank1 : Nat) : Array Nat :=
  (unrankWeavingM lengths rank1).run ∅ |>.1
def positiveGateGap (n : Nat) : Int :=
  let r := sauce foundationDay (foundationDay + natToInt n)
  let stream := askBowl r 1 1
  41 + natToInt (chooseRank stream 922)


def negativeGateGap (n : Nat) : Int :=
  let r := sauce foundationDay (foundationDay - natToInt n)
  let stream := askBowl r 1 1
  41 + natToInt (chooseRank stream 922)

structure GateWindow where
  minIndex : Int
  days : Array Int
  deriving Repr

private def gateWindowMaxIndex (w : GateWindow) : Int :=
  w.minIndex + natToInt (w.days.size - 1)

private def gateWindowFirstDay (w : GateWindow) : Int := w.days[0]!
private def gateWindowLastDay (w : GateWindow) : Int := w.days[w.days.size - 1]!

private def gateAt (w : GateWindow) (index : Int) : Int :=
  let offset := intToNat (index - w.minIndex)
  w.days[offset]!


def ensureGatesCover (lowDay highDay : Int) : GateWindow := Id.run do
  let mut w : GateWindow := { minIndex := 0, days := #[foundationDay] }
  while gateWindowFirstDay w > lowDay do
    let newIndex := w.minIndex - 1
    let magnitude := intToNat (-newIndex)
    let newDay := gateWindowFirstDay w - negativeGateGap magnitude
    w := { minIndex := newIndex, days := #[newDay] ++ w.days }
  while gateWindowLastDay w < highDay do
    let newIndex := gateWindowMaxIndex w + 1
    let gap := positiveGateGap (intToNat newIndex)
    let newDay := gateWindowLastDay w + gap
    w := { minIndex := w.minIndex, days := w.days.push newDay }
  return w


def gateIndexAtOrBefore (day : Int) : Int :=
  let w := ensureGatesCover day day
  Id.run do
    let mut answer := w.minIndex
    for i in [0:w.days.size] do
      if w.days[i]! <= day then
        answer := w.minIndex + natToInt i
    return answer


def exactGateIndex (day : Int) : Option Int :=
  let i := gateIndexAtOrBefore day
  let w := ensureGatesCover day day
  if gateAt w i == day then some i else none

structure Year where
  number : Int
  openGateIndex : Int
  closeGateIndex : Int
  openGateDay : Int
  closeGateDay : Int
  deriving Repr, BEq, Inhabited

private def validYearPairDays (openIndex closeIndex openDay closeDay : Int) : Bool :=
  let gaps := closeIndex - openIndex
  let len := closeDay - openDay
  gaps >= 6 && yearMinDays <= len && len <= yearMaxDays

private def yearLess (a b : Year) : Bool :=
  let la := a.closeGateDay - a.openGateDay
  let lb := b.closeGateDay - b.openGateDay
  if la < lb then true else if la > lb then false else a.openGateDay < b.openGateDay

private def insertYear (x : Year) : List Year → List Year
  | [] => [x]
  | y :: ys => if yearLess x y then x :: y :: ys else y :: insertYear x ys

private def sortYears (xs : List Year) : List Year :=
  xs.foldl (fun acc x => insertYear x acc) []


def year5000 (calculationDay : Int) : Year :=
  let w := ensureGatesCover (calculationDay - yearMaxDays) (calculationDay + yearMaxDays)
  let candidates := Id.run do
    let mut out : List Year := []
    for oi in [0:w.days.size] do
      for cj in [oi+1:w.days.size] do
        let openDay := w.days[oi]!
        let closeDay := w.days[cj]!
        let openIndex := w.minIndex + natToInt oi
        let closeIndex := w.minIndex + natToInt cj
        if validYearPairDays openIndex closeIndex openDay closeDay && openDay < calculationDay && calculationDay <= closeDay then
          out := { number := 5000, openGateIndex := openIndex, closeGateIndex := closeIndex, openGateDay := openDay, closeGateDay := closeDay } :: out
    return out
  let sorted := (sortYears candidates).toArray
  let r := sauce calculationDay calculationDay
  let stream := askBowl r 1 10
  let rank := chooseRank stream sorted.size
  sorted[rank - 1]!


def nextYear (calculationDay : Int) (knownYear : Year) : Year :=
  let w := ensureGatesCover knownYear.closeGateDay (knownYear.closeGateDay + yearMaxDays + gateGapMax)
  let openIndex := knownYear.closeGateIndex
  let openDay := knownYear.closeGateDay
  let candidates := Id.run do
    let mut out := #[]
    let mut closeIndex := openIndex + 1
    let mut done := false
    while !done do
      let closeDay := gateAt w closeIndex
      if closeDay - openDay > yearMaxDays then
        done := true
      else
        if validYearPairDays openIndex closeIndex openDay closeDay then
          out := out.push closeIndex
        closeIndex := closeIndex + 1
    return out
  let r := sauce calculationDay openDay
  let stream := askBowl r 1 11
  let rank := chooseRank stream candidates.size
  let closeIndex := candidates[rank - 1]!
  let closeDay := gateAt w closeIndex
  { number := knownYear.number + 1, openGateIndex := openIndex, closeGateIndex, openGateDay := openDay, closeGateDay := closeDay }


def previousYear (calculationDay : Int) (knownYear : Year) : Year :=
  let w := ensureGatesCover (knownYear.openGateDay - yearMaxDays - gateGapMax) knownYear.openGateDay
  let closeIndex := knownYear.openGateIndex
  let closeDay := knownYear.openGateDay
  let candidates := Id.run do
    let mut out := #[]
    let mut openIndex := closeIndex - 1
    let mut done := false
    while !done do
      let openDay := gateAt w openIndex
      if closeDay - openDay > yearMaxDays then
        done := true
      else
        if validYearPairDays openIndex closeIndex openDay closeDay then
          out := out.push openIndex
        openIndex := openIndex - 1
    return out
  let r := sauce calculationDay closeDay
  let stream := askBowl r 1 12
  let rank := chooseRank stream candidates.size
  let openIndex := candidates[rank - 1]!
  let openDay := gateAt w openIndex
  { number := knownYear.number - 1, openGateIndex := openIndex, closeGateIndex, openGateDay := openDay, closeGateDay := closeDay }

partial def findTargetYear (calculationDay targetDay : Int) : Year := Id.run do
  let mut y := year5000 calculationDay
  while targetDay > y.closeGateDay do
    y := nextYear calculationDay y
  while targetDay <= y.openGateDay do
    y := previousYear calculationDay y
  return y

private def yearGateGapCount (year : Year) : Nat :=
  intToNat (year.closeGateIndex - year.openGateIndex)

private def chooseCutletCount (structureSauce : SauceResult) (year : Year) : Nat := Id.run do
  let gaps := yearGateGapCount year
  let mut candidates := #[]
  for k in [6:18] do
    if k <= gaps then
      candidates := candidates.push k
  let stream := askBowl structureSauce 2 20
  let rank := chooseRank stream candidates.size
  return candidates[rank - 1]!

private def requiredCutletBoundary (calculationDay : Int) (year : Year) : Option Nat :=
  match exactGateIndex calculationDay with
  | none => none
  | some g =>
      if year.openGateIndex < g && g < year.closeGateIndex then
        some (intToNat (g - year.openGateIndex))
      else
        none

private def chooseCutletPartition (calculationDay : Int) (structureSauce : SauceResult) (year : Year) (cutletCount : Nat) : Array Nat :=
  let gaps := yearGateGapCount year
  let required := requiredCutletBoundary calculationDay year
  let count := countCutletPartitions gaps cutletCount required
  let stream := askBowl structureSauce 2 21
  let rank := chooseRank stream count
  unrankCutletPartition gaps cutletCount rank required

private def chooseCutletNameIndices (structureSauce : SauceResult) (cutletCount : Nat) : Array Nat :=
  let n := fallingFactorial 17 cutletCount
  let stream := askBowl structureSauce 5 22
  let rank := chooseRank stream n
  unrankDistinctIndices 17 cutletCount rank

structure Cutlet where
  canonicalNameIndex : Nat
  openGateIndex : Int
  closeGateIndex : Int
  firstDay : Int
  lastDay : Int
  deriving Repr, BEq, Inhabited

private def materializeCutlets (year : Year) (partition names : Array Nat) : Array Cutlet :=
  let w := ensureGatesCover year.openGateDay year.closeGateDay
  Id.run do
    let mut cursor := year.openGateIndex
    let mut out := #[]
    for i in [0:partition.size] do
      let openIndex := cursor
      let closeIndex := cursor + natToInt partition[i]!
      out := out.push {
        canonicalNameIndex := names[i]!
        openGateIndex := openIndex
        closeGateIndex := closeIndex
        firstDay := gateAt w openIndex + 1
        lastDay := gateAt w closeIndex
      }
      cursor := closeIndex
    return out

private def chooseMonthCount (structureSauce : SauceResult) (year : Year) : Nat :=
  let len := intToNat (year.closeGateDay - year.openGateDay)
  let low := ceilDivNat len 123
  let high := minNat 47 (len / 4)
  let choices := high - low + 1
  let stream := askBowl structureSauce 3 30
  low + chooseRank stream choices - 1

private def chooseMonthLengths (structureSauce : SauceResult) (year : Year) (monthCount : Nat) : Array Nat :=
  let len := intToNat (year.closeGateDay - year.openGateDay)
  let count := countBoundedCompositions len monthCount 4 123
  let stream := askBowl structureSauce 3 31
  let rank := chooseRank stream count
  unrankBoundedComposition len monthCount 4 123 rank

private def chooseMonthWeaving (structureSauce : SauceResult) (lengths : Array Nat) : Array Nat :=
  let count := countWeavings lengths
  let stream := askBowl structureSauce 4 32
  let rank := chooseRank stream count
  unrankWeaving lengths rank

private def chooseMonthNameIndices (structureSauce : SauceResult) (monthCount : Nat) : Array Nat :=
  let n := fallingFactorial 47 monthCount
  let stream := askBowl structureSauce 5 33
  let rank := chooseRank stream n
  unrankDistinctIndices 47 monthCount rank

structure YearStructure where
  cutletCount : Nat
  cutletPartition : Array Nat
  cutletNameIndices : Array Nat
  cutlets : Array Cutlet
  monthCount : Nat
  monthLengths : Array Nat
  monthWeaving : Array Nat
  monthNameIndices : Array Nat
  deriving Repr


def buildYearStructure (calculationDay : Int) (year : Year) : YearStructure :=
  let firstDay := year.openGateDay + 1
  let r := sauce calculationDay firstDay
  let cutletCount := chooseCutletCount r year
  let cutletPartition := chooseCutletPartition calculationDay r year cutletCount
  let cutletNameIndices := chooseCutletNameIndices r cutletCount
  let cutlets := materializeCutlets year cutletPartition cutletNameIndices
  let monthCount := chooseMonthCount r year
  let monthLengths := chooseMonthLengths r year monthCount
  let monthWeaving := chooseMonthWeaving r monthLengths
  let monthNameIndices := chooseMonthNameIndices r monthCount
  { cutletCount, cutletPartition, cutletNameIndices, cutlets, monthCount, monthLengths, monthWeaving, monthNameIndices }

private def findCutlet (cutlets : Array Cutlet) (targetDay : Int) : Cutlet := Id.run do
  let mut result := cutlets[0]!
  let mut found := false
  for c in cutlets do
    if !found && c.firstDay <= targetDay && targetDay <= c.lastDay then
      result := c
      found := true
  return result

structure CalendarDateResult where
  yearNumber : Int
  cutletName : String
  dayInCutlet : Int
  monthName : String
  dayInMonth : Nat
  deriving Repr, BEq


def calendarDate (calculationDay targetDay : Int) : CalendarDateResult :=
  let year := findTargetYear calculationDay targetDay
  let structure := buildYearStructure calculationDay year
  let cutlet := findCutlet structure.cutlets targetDay
  let dayInCutlet := targetDay - cutlet.firstDay + 1
  let yearOffset0 := intToNat (targetDay - (year.openGateDay + 1))
  let monthId := structure.monthWeaving[yearOffset0]!
  let monthCanonicalIndex := get1 structure.monthNameIndices monthId
  let monthName := (monthNameByCanonicalIndex monthCanonicalIndex).getD ""
  let cutletName := (cutletNameByCanonicalIndex cutlet.canonicalNameIndex).getD ""
  let dayInMonth := Id.run do
    let mut count := 0
    for p in [0:yearOffset0+1] do
      if structure.monthWeaving[p]! == monthId then
        count := count + 1
    return count
  { yearNumber := year.number, cutletName, dayInCutlet, monthName, dayInMonth }

end PastafariLean.NormativeOracle
