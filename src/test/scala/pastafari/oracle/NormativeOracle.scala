package pastafari.oracle

import pastafari.catalog.SourceLanguageCatalog
import scala.collection.mutable

object NormativeOracle {
  val TabletsDay: BigInt = BigInt(-278522)
  val FoundationDay: BigInt = BigInt(-15055671)
  val M: BigInt = (BigInt(1) << 127) - 1

  val GateGapMin: Int = 42
  val GateGapMax: Int = 963
  val YearMinDays: Int = 252
  val YearMaxDays: Int = 5778
  val MinCutlets: Int = 6
  val MaxCutlets: Int = 17
  val MinMonths: Int = 3
  val MaxMonths: Int = 47
  val MinMonthDays: Int = 4
  val MaxMonthDays: Int = 123

  val SealGateGap: Int = 1
  val SealYear5000: Int = 10
  val SealNextYear: Int = 11
  val SealPreviousYear: Int = 12
  val SealCutletCount: Int = 20
  val SealCutletPartition: Int = 21
  val SealCutletNames: Int = 22
  val SealMonthCount: Int = 30
  val SealMonthLengths: Int = 31
  val SealMonthWeaving: Int = 32
  val SealMonthNames: Int = 33

  val Wheat = 0
  val Barley = 1
  val Salt = 2
  val Bitter = 3
  val Red = 4

  final case class WorkCounts(action: BigInt, target: BigInt, distance: BigInt, connection: BigInt, direction: BigInt)
  final case class SauceResult(bowls: Vector[BigInt], orderAtDrop46: Vector[Int])
  final case class AnswerStream(first: BigInt, directionStep: Int)
  final case class Year(number: BigInt, openGateIndex: BigInt, closeGateIndex: BigInt, openGateDay: BigInt, closeGateDay: BigInt)
  final case class Cutlet(canonicalNameIndex: Int, openGateIndex: BigInt, closeGateIndex: BigInt, firstDay: BigInt, lastDay: BigInt)
  final case class YearStructure(
    cutletCount: Int,
    cutletPartition: Vector[Int],
    cutletNameIndices: Vector[Int],
    cutlets: Vector[Cutlet],
    monthCount: Int,
    monthLengths: Vector[Int],
    monthWeaving: Vector[Int],
    monthNameIndices: Vector[Int]
  )
  final case class CalendarDate(yearNumber: BigInt, cutletName: String, dayInCutlet: BigInt, monthName: String, dayInMonth: Int)

  private val HiddenCoeff: Vector[Vector[Int]] = Vector(
    Vector(3, 4, 6, 8),
    Vector(5, 7, 10, 12),
    Vector(7, 10, 14, 16),
    Vector(9, 13, 18, 20),
    Vector(11, 16, 22, 24),
    Vector(13, 19, 26, 28),
    Vector(15, 22, 30, 32)
  )

  private val HiddenGrindStone: Vector[Int] = Vector(Wheat, Barley, Salt, Bitter, Red, Wheat, Barley)

  private val VisibleGrinds: Vector[(Int, Int, Int, Int, Int)] = Vector(
    (3, 5, 7, 11, Wheat),
    (5, 7, 11, 13, Barley),
    (7, 11, 13, 17, Salt),
    (11, 13, 17, 19, Bitter),
    (13, 17, 19, 23, Red),
    (17, 19, 23, 29, Wheat),
    (19, 23, 29, 31, Barley),
    (23, 29, 31, 37, Salt),
    (29, 31, 37, 41, Bitter),
    (31, 37, 41, 43, Red),
    (37, 41, 43, 47, Wheat)
  )

  private val BowlPrime: Vector[Int] = Vector(17, 19, 23, 29, 31, 37)
  private val BowlStirStoneByPosition: Vector[Int] = Vector(Wheat, Barley, Salt, Bitter, Red, Wheat)

  def regularMod(x: BigInt, d: BigInt): BigInt = {
    require(d >= 1, "Il divisore deve essere positivo.")
    val r = x % d
    if (r.signum < 0) r + d else r
  }

  def save(x: BigInt): BigInt = BigInt(1) + regularMod(x - 1, M)

  def ceilDiv(a: BigInt, b: BigInt): BigInt = {
    require(a >= 0 && b >= 1, "Argomenti non validi per la divisione arrotondata verso l'alto.")
    (a + b - 1) / b
  }

  def wrap1(position: Int, size: Int): Int = {
    require(size >= 1, "La dimensione deve essere positiva.")
    (((position - 1) % size) + size) % size + 1
  }

  def dayCount(day: BigInt): BigInt = {
    if (day == FoundationDay) BigInt(1)
    else if (day > FoundationDay) BigInt(2) * (day - FoundationDay) + 1
    else BigInt(2) * (FoundationDay - day)
  }

  def workCounts(calculationDay: BigInt, targetDay: BigInt): WorkCounts = {
    val c = dayCount(calculationDay)
    val t = dayCount(targetDay)
    val distance = (targetDay - calculationDay).abs + 1
    val connection = c + t
    val direction = if (targetDay < calculationDay) 1 else if (targetDay == calculationDay) 2 else 3
    WorkCounts(c, t, distance, connection, direction)
  }

  lazy val Stones: Vector[Vector[BigInt]] = buildStones()

  def buildStones(): Vector[Vector[BigInt]] = {
    val table = mutable.ArrayBuffer.empty[Vector[BigInt]]
    table += Vector(BigInt(17), BigInt(29), BigInt(43), BigInt(71), BigInt(101))
    var i = 2
    while (i <= 46) {
      val old = table(i - 2)
      val nextWheat = save(old(Wheat) * old(Wheat) + 3 * old(Barley) + i)
      val nextBarley = save(old(Barley) * old(Barley) + 5 * old(Salt) + old(Wheat))
      val nextSalt = save(old(Salt) * old(Salt) + 7 * old(Bitter) + old(Barley))
      val nextBitter = save(old(Bitter) * old(Bitter) + 11 * old(Red) + old(Salt))
      val nextRed = save(old(Red) * old(Red) + 13 * old(Wheat) + old(Bitter))
      table += Vector(nextWheat, nextBarley, nextSalt, nextBitter, nextRed)
      i += 1
    }
    table.toVector
  }

  def buildHiddenDrops(counts: WorkCounts, stones: Vector[Vector[BigInt]] = Stones): Vector[BigInt] = {
    Vector.tabulate(7) { zeroK =>
      val k = zeroK + 1
      val coeff = HiddenCoeff(zeroK)
      val s = stones(zeroK)
      var x = counts.action + coeff(0) * counts.target + coeff(1) * counts.distance + coeff(2) * counts.connection + coeff(3) * counts.direction
      x += s.sum
      x = save(x)
      var grind = 1
      while (grind <= 7) {
        val oldX = x
        x = save(oldX * oldX + 3 * oldX + s(HiddenGrindStone(grind - 1)) + grind)
        grind += 1
      }
      x
    }
  }

  def buildVisibleDrops(counts: WorkCounts, hidden: Vector[BigInt], stones: Vector[Vector[BigInt]] = Stones): Vector[BigInt] = {
    require(hidden.length == 7, "Servono esattamente sette gocce nascoste.")
    val timeline = mutable.Map.empty[Int, BigInt]
    var k = 1
    while (k <= 7) {
      timeline.update(1 - k, hidden(k - 1))
      k += 1
    }
    val visible = mutable.ArrayBuffer.empty[BigInt]
    var i = 1
    while (i <= 46) {
      val prev1 = timeline(i - 1)
      val prev3 = timeline(i - 3)
      val prev7 = timeline(i - 7)
      val stone = stones(i - 1)
      var x = save(
        stone(Wheat) * counts.action +
          stone(Barley) * counts.target +
          stone(Salt) * counts.distance +
          stone(Bitter) * counts.connection +
          stone(Red) * counts.direction +
          prev1 + 3 * prev3 + 5 * prev7 + i
      )
      var grind = 0
      while (grind < VisibleGrinds.length) {
        val (a, b, c, d, kind) = VisibleGrinds(grind)
        val oldX = x
        x = save(oldX * oldX + a * oldX + b * prev1 + c * prev3 + d * prev7 + stone(kind))
        grind += 1
      }
      timeline.update(i, x)
      visible += x
      i += 1
    }
    visible.toVector
  }

  def factorial(n: Int): BigInt = {
    require(n >= 0, "Il fattoriale richiede un intero non negativo.")
    var r = BigInt(1)
    var i = 2
    while (i <= n) {
      r *= i
      i += 1
    }
    r
  }

  def permutationUnrank1(rank1: BigInt, itemsAscending: Vector[Int]): Vector[Int] = {
    require(rank1 >= 1 && rank1 <= factorial(itemsAscending.length), "Rango di permutazione fuori intervallo.")
    var rank0 = rank1 - 1
    val remaining = mutable.ArrayBuffer(itemsAscending: _*)
    val result = mutable.ArrayBuffer.empty[Int]
    var slotsLeft = remaining.length
    while (slotsLeft >= 1) {
      val block = factorial(slotsLeft - 1)
      val q = (rank0 / block).toInt
      rank0 = regularMod(rank0, block)
      result += remaining(q)
      remaining.remove(q)
      slotsLeft -= 1
    }
    result.toVector
  }

  def bowlOrderFromNumber(orderNumber: Int): Vector[Int] = {
    require(orderNumber >= 1 && orderNumber <= 720, "Numero d'ordine delle ciotole fuori intervallo.")
    permutationUnrank1(BigInt(orderNumber), Vector(1, 2, 3, 4, 5, 6))
  }

  def bowlOrderFromDrop(dropValue: BigInt): Vector[Int] = {
    val orderNumber = (regularMod(dropValue - 1, BigInt(720)) + 1).toInt
    bowlOrderFromNumber(orderNumber)
  }

  def initialBowls(counts: WorkCounts): Vector[BigInt] = {
    Vector.tabulate(6) { zeroId =>
      val bowlId = zeroId + 1
      val s = counts.action + counts.target * bowlId + counts.distance + counts.connection + counts.direction + BigInt(BowlPrime(zeroId)).pow(2)
      save(s * s + bowlId)
    }
  }

  def applyVisibleDropsToBowls(initial: Vector[BigInt], visible: Vector[BigInt], stones: Vector[Vector[BigInt]] = Stones): (Vector[BigInt], Vector[Int]) = {
    require(initial.length == 6 && visible.length == 46, "Dimensioni non valide per l'elaborazione delle ciotole.")
    var bowls = initial
    var orderAtDrop46 = Vector.empty[Int]
    var i = 1
    while (i <= 46) {
      val drop = visible(i - 1)
      val order = bowlOrderFromDrop(drop)
      val old = bowls
      val pour = Array.fill[BigInt](6)(BigInt(0))
      val firstBowl = order(0)
      val secondBowl = order(1)
      val thirdBowl = order(2)
      pour(0) = save(drop * drop + stones(i - 1)(Wheat) * old(firstBowl - 1) + 3 * i)
      pour(1) = save(drop * drop + stones(i - 1)(Barley) * old(secondBowl - 1) + 5 * i)
      pour(2) = save(drop * drop + stones(i - 1)(Salt) * old(thirdBowl - 1) + 7 * i)
      val nextBowls = Array.fill[BigInt](6)(BigInt(0))
      var position = 1
      while (position <= 6) {
        val bowlId = order(position - 1)
        val prevId = order(wrap1(position - 1, 6) - 1)
        val nextId = order(wrap1(position + 1, 6) - 1)
        val stoneKind = BowlStirStoneByPosition(position - 1)
        val s = old(bowlId - 1) + 2 * old(prevId - 1) + 3 * old(nextId - 1) + pour(position - 1) + drop + stones(i - 1)(stoneKind)
        nextBowls(bowlId - 1) = save(s * s + 5 * old(prevId - 1) * old(nextId - 1) + i * position)
        position += 1
      }
      bowls = nextBowls.toVector
      if (i == 46) orderAtDrop46 = order
      i += 1
    }
    (bowls, orderAtDrop46)
  }

  def postStir12(initial: Vector[BigInt]): Vector[BigInt] = {
    require(initial.length == 6, "Servono sei ciotole.")
    var bowls = initial
    var stir = 1
    while (stir <= 12) {
      val old = bowls
      val savedBowlSum = save(old.sum + 149 * stir)
      val orderNumber = (regularMod(savedBowlSum - 1, BigInt(720)) + 1).toInt
      val order = bowlOrderFromNumber(orderNumber)
      val nextBowls = Array.fill[BigInt](6)(BigInt(0))
      var position = 1
      while (position <= 6) {
        val bowlId = order(position - 1)
        val prevId = order(wrap1(position - 1, 6) - 1)
        val nextId = order(wrap1(position + 1, 6) - 1)
        val s = old(bowlId - 1) + 3 * old(prevId - 1) + 5 * old(nextId - 1) + savedBowlSum + stir + position * position
        nextBowls(bowlId - 1) = save(s * s + 7 * old(prevId - 1) * old(nextId - 1))
        position += 1
      }
      bowls = nextBowls.toVector
      stir += 1
    }
    bowls
  }

  def sauce(calculationDay: BigInt, targetDay: BigInt): SauceResult = {
    val counts = workCounts(calculationDay, targetDay)
    val hidden = buildHiddenDrops(counts)
    val visible = buildVisibleDrops(counts, hidden)
    val initial = initialBowls(counts)
    val (afterDrops, orderAt46) = applyVisibleDropsToBowls(initial, visible)
    SauceResult(postStir12(afterDrops), orderAt46)
  }

  def nextBowlInDrop46Order(sauceResult: SauceResult, queriedBowlId: Int): Int = {
    val p = sauceResult.orderAtDrop46.indexOf(queriedBowlId)
    require(p >= 0, "La ciotola interrogata deve apparire nell'ordine della goccia 46.")
    sauceResult.orderAtDrop46((p + 1) % 6)
  }

  def askBowl(sauceResult: SauceResult, queriedBowlId: Int, seal: Int): AnswerStream = {
    require(queriedBowlId >= 1 && queriedBowlId <= 6, "Identificatore della ciotola non valido.")
    val nextId = nextBowlInDrop46Order(sauceResult, queriedBowlId)
    val q = sauceResult.bowls(queriedBowlId - 1)
    val n = sauceResult.bowls(nextId - 1)
    val first = save((q + seal + 181).pow(2) + 179 * n + seal)
    val directionNumber = save((first + seal + 1 + 193).pow(2) + 193 * first + 197 * sauceResult.bowls(5))
    val step = if (regularMod(directionNumber, BigInt(2)) == 1) 1 else -1
    AnswerStream(first, step)
  }

  def answerAt(stream: AnswerStream, k: BigInt): BigInt =
    BigInt(1) + regularMod(stream.first - 1 + stream.directionStep * k, M)

  def chooseRankShort(stream: AnswerStream, n: BigInt): BigInt = {
    require(n >= 1 && n <= M, "La selezione corta richiede 1 <= N <= M.")
    val acceptanceLimit = (M / n) * n
    var k = BigInt(0)
    while (true) {
      val x = answerAt(stream, k)
      if (x <= acceptanceLimit) return regularMod(x - 1, n) + 1
      k += 1
    }
    BigInt(0)
  }

  def smallestPowerCount(base: BigInt, n: BigInt): (Int, BigInt) = {
    require(base >= 1 && n >= 1, "Base e dimensione devono essere positive.")
    var k = 1
    var space = base
    while (space < n) {
      k += 1
      space *= base
    }
    (k, space)
  }

  def chooseRankWide(stream: AnswerStream, n: BigInt): BigInt = {
    require(n > M, "La selezione larga richiede N > M.")
    val (k, space) = smallestPowerCount(M, n)
    var wide = BigInt(1)
    var weight = BigInt(1)
    var j = 0
    while (j < k) {
      wide += (answerAt(stream, BigInt(j)) - 1) * weight
      weight *= M
      j += 1
    }
    val acceptanceLimit = (space / n) * n
    while (wide > acceptanceLimit) {
      wide = BigInt(1) + regularMod(wide - 1 + stream.directionStep, space)
    }
    regularMod(wide - 1, n) + 1
  }

  def chooseRank(stream: AnswerStream, n: BigInt): BigInt = {
    require(n >= 1, "La famiglia ordinata non può essere vuota.")
    if (n <= M) chooseRankShort(stream, n) else chooseRankWide(stream, n)
  }

  def fallingFactorial(n: Int, k: Int): BigInt = {
    require(k >= 0 && k <= n, "Parametri non validi per il fattoriale decrescente.")
    var r = BigInt(1)
    var j = 0
    while (j < k) {
      r *= (n - j)
      j += 1
    }
    r
  }

  def unrankDistinctIndices(masterSize: Int, k: Int, rank1: BigInt): Vector[Int] = {
    require(k >= 0 && k <= masterSize, "Numero di nomi distinto non valido.")
    val total = fallingFactorial(masterSize, k)
    require(rank1 >= 1 && rank1 <= total, "Rango dei nomi fuori intervallo.")
    val remaining = mutable.ArrayBuffer((1 to masterSize): _*)
    val out = mutable.ArrayBuffer.empty[Int]
    var r = rank1
    var position = 1
    while (position <= k) {
      val suffixLength = k - position
      val block = fallingFactorial(remaining.length - 1, suffixLength)
      var candidate = 0
      var chosen = false
      while (candidate < remaining.length && !chosen) {
        if (r > block) r -= block
        else {
          out += remaining(candidate)
          remaining.remove(candidate)
          chosen = true
        }
        candidate += 1
      }
      position += 1
    }
    out.toVector
  }

  trait OrderedFamily[A] {
    def count(): BigInt
    def unrank1(rank1: BigInt): A
  }

  final class BoundedCompositionFamily(total: Int, slots: Int, lo: Int, hi: Int) extends OrderedFamily[Vector[Int]] {
    require(total >= 0 && slots >= 0 && lo >= 0 && hi >= lo, "Parametri non validi per la famiglia di composizioni limitate.")
    private val memo = mutable.Map.empty[(Int, Int), BigInt]

    private def countSuffix(rem: Int, k: Int): BigInt = {
      if (k == 0) return if (rem == 0) BigInt(1) else BigInt(0)
      if (rem < k * lo || rem > k * hi) return BigInt(0)
      memo.getOrElseUpdate((rem, k), {
        var s = BigInt(0)
        var x = lo
        while (x <= hi) {
          s += countSuffix(rem - x, k - 1)
          x += 1
        }
        s
      })
    }

    override def count(): BigInt = countSuffix(total, slots)

    override def unrank1(rank1: BigInt): Vector[Int] = {
      require(rank1 >= 1 && rank1 <= count(), "Rango della composizione limitata fuori intervallo.")
      var r = rank1
      var rem = total
      var remainingSlots = slots
      val out = mutable.ArrayBuffer.empty[Int]
      while (remainingSlots > 0) {
        var x = lo
        var chosen = false
        while (x <= hi && !chosen) {
          val block = countSuffix(rem - x, remainingSlots - 1)
          if (r > block) r -= block
          else {
            out += x
            rem -= x
            remainingSlots -= 1
            chosen = true
          }
          x += 1
        }
        if (!chosen) throw new IllegalStateException("Impossibile aprire il rango della composizione limitata.")
      }
      out.toVector
    }
  }

  final class CutletPartitionFamily(gaps: Int, cutletCount: Int, requiredBoundary: Option[Int]) extends OrderedFamily[Vector[Int]] {
    require(gaps >= cutletCount && cutletCount >= 1, "Parametri non validi per la partizione delle cotolette.")
    private val memo = mutable.Map.empty[(Int, Int, Int, Boolean), BigInt]

    private def countState(rem: Int, slots: Int, cumulative: Int, hitBoundary: Boolean): BigInt = {
      if (slots == 0) {
        if (rem != 0) return BigInt(0)
        return if (requiredBoundary.isEmpty || hitBoundary) BigInt(1) else BigInt(0)
      }
      if (rem < slots) return BigInt(0)
      val key = (rem, slots, cumulative, hitBoundary)
      memo.getOrElseUpdate(key, {
        var total = BigInt(0)
        val maxX = rem - (slots - 1)
        var x = 1
        while (x <= maxX) {
          val nextCumulative = cumulative + x
          var nextHit = hitBoundary
          var legal = true
          requiredBoundary.foreach { boundary =>
            if (!hitBoundary) {
              if (nextCumulative == boundary) nextHit = true
              else if (nextCumulative > boundary) legal = false
            }
          }
          if (legal) total += countState(rem - x, slots - 1, nextCumulative, nextHit)
          x += 1
        }
        total
      })
    }

    override def count(): BigInt = countState(gaps, cutletCount, 0, hitBoundary = false)

    override def unrank1(rank1: BigInt): Vector[Int] = {
      require(rank1 >= 1 && rank1 <= count(), "Rango della partizione delle cotolette fuori intervallo.")
      var r = rank1
      var rem = gaps
      var slots = cutletCount
      var cumulative = 0
      var hit = false
      val out = mutable.ArrayBuffer.empty[Int]
      while (slots > 0) {
        val maxX = rem - (slots - 1)
        var x = 1
        var chosen = false
        while (x <= maxX && !chosen) {
          val nextCumulative = cumulative + x
          var nextHit = hit
          var legal = true
          requiredBoundary.foreach { boundary =>
            if (!hit) {
              if (nextCumulative == boundary) nextHit = true
              else if (nextCumulative > boundary) legal = false
            }
          }
          if (legal) {
            val block = countState(rem - x, slots - 1, nextCumulative, nextHit)
            if (r > block) r -= block
            else {
              out += x
              rem -= x
              slots -= 1
              cumulative = nextCumulative
              hit = nextHit
              chosen = true
            }
          }
          x += 1
        }
        if (!chosen) throw new IllegalStateException("Impossibile aprire il rango della partizione delle cotolette.")
      }
      out.toVector
    }
  }

  final case class WeaveState(remaining: Vector[Int], openedUpTo: Int, closedUpTo: Int)

  final class WeavingFamily(lengths: Vector[Int]) extends OrderedFamily[Vector[Int]] {
    require(lengths.nonEmpty && lengths.forall(_ >= 1), "Le lunghezze dei mesi devono essere positive.")
    private val m = lengths.length
    private val memo = mutable.Map.empty[WeaveState, BigInt]
    private val initial = WeaveState(lengths, 0, 0)

    private def legalMove(state: WeaveState, j: Int): Boolean = {
      val idx = j - 1
      if (state.remaining(idx) == 0) return false
      val alreadyOpened = state.remaining(idx) < lengths(idx)
      if (!alreadyOpened && j != state.openedUpTo + 1) return false
      val willClose = state.remaining(idx) == 1
      if (willClose && j != state.closedUpTo + 1) return false
      true
    }

    private def applyMove(state: WeaveState, j: Int): WeaveState = {
      val idx = j - 1
      var opened = state.openedUpTo
      var closed = state.closedUpTo
      if (state.remaining(idx) == lengths(idx)) opened = j
      val nextRemaining = state.remaining.updated(idx, state.remaining(idx) - 1)
      if (nextRemaining(idx) == 0) closed = j
      WeaveState(nextRemaining, opened, closed)
    }

    private def countState(state: WeaveState): BigInt = {
      if (state.remaining.forall(_ == 0)) return BigInt(1)
      memo.getOrElseUpdate(state, {
        var total = BigInt(0)
        var j = 1
        while (j <= m) {
          if (legalMove(state, j)) total += countState(applyMove(state, j))
          j += 1
        }
        total
      })
    }

    override def count(): BigInt = countState(initial)

    override def unrank1(rank1: BigInt): Vector[Int] = {
      require(rank1 >= 1 && rank1 <= count(), "Rango della tessitura dei mesi fuori intervallo.")
      var state = initial
      var r = rank1
      val out = mutable.ArrayBuffer.empty[Int]
      val targetLength = lengths.sum
      while (out.length < targetLength) {
        var j = 1
        var chosen = false
        while (j <= m && !chosen) {
          if (legalMove(state, j)) {
            val next = applyMove(state, j)
            val block = countState(next)
            if (r > block) r -= block
            else {
              out += j
              state = next
              chosen = true
            }
          }
          j += 1
        }
        if (!chosen) throw new IllegalStateException("Impossibile aprire il rango della tessitura dei mesi.")
      }
      out.toVector
    }
  }

  final class GateEngine {
    private val gates = mutable.Map[BigInt, BigInt](BigInt(0) -> FoundationDay)
    private var minKnown: BigInt = 0
    private var maxKnown: BigInt = 0

    def gate(index: BigInt): BigInt = ensureGateIndex(index)

    def positiveGateGap(n: BigInt): Int = {
      require(n >= 1, "L'indice del divario positivo deve essere almeno uno.")
      val r = sauce(FoundationDay, FoundationDay + n)
      val stream = askBowl(r, 1, SealGateGap)
      41 + chooseRank(stream, BigInt(922)).toInt
    }

    def negativeGateGap(n: BigInt): Int = {
      require(n >= 1, "L'indice del divario negativo deve essere almeno uno.")
      val r = sauce(FoundationDay, FoundationDay - n)
      val stream = askBowl(r, 1, SealGateGap)
      41 + chooseRank(stream, BigInt(922)).toInt
    }

    def ensureGateIndex(k: BigInt): BigInt = {
      if (k > maxKnown) {
        var n = maxKnown + 1
        while (n <= k) {
          gates.update(n, gates(n - 1) + positiveGateGap(n))
          maxKnown = n
          n += 1
        }
      }
      if (k < minKnown) {
        var n = minKnown - 1
        while (n >= k) {
          gates.update(n, gates(n + 1) - negativeGateGap((-n).abs))
          minKnown = n
          n -= 1
        }
      }
      gates(k)
    }

    def ensureGatesCover(lowDay: BigInt, highDay: BigInt): Unit = {
      require(lowDay <= highDay, "Intervallo dei giorni non valido.")
      while (gates(minKnown) > lowDay) ensureGateIndex(minKnown - 1)
      while (gates(maxKnown) < highDay) ensureGateIndex(maxKnown + 1)
    }

    def gateIndexAtOrBefore(day: BigInt): BigInt = {
      ensureGatesCover(day, day)
      var lo = minKnown
      var hi = maxKnown
      while (lo < hi) {
        val mid = lo + (hi - lo + 1) / 2
        if (gates(mid) <= day) lo = mid else hi = mid - 1
      }
      lo
    }

    def exactGateIndex(day: BigInt): Option[BigInt] = {
      val i = gateIndexAtOrBefore(day)
      if (gates(i) == day) Some(i) else None
    }

    def yearLength(openIndex: BigInt, closeIndex: BigInt): BigInt = gate(closeIndex) - gate(openIndex)

    def validYearPair(openIndex: BigInt, closeIndex: BigInt): Boolean = {
      if (closeIndex - openIndex < 6) false
      else {
        val length = yearLength(openIndex, closeIndex)
        length >= YearMinDays && length <= YearMaxDays
      }
    }

    private def localGeneratedIndices: Vector[BigInt] = {
      val start = minKnown
      val end = maxKnown
      val out = mutable.ArrayBuffer.empty[BigInt]
      var i = start
      while (i <= end) {
        out += i
        i += 1
      }
      out.toVector
    }

    def year5000(calculationDay: BigInt): Year = {
      ensureGatesCover(calculationDay - YearMaxDays, calculationDay + YearMaxDays)
      val indices = localGeneratedIndices
      val candidates = mutable.ArrayBuffer.empty[(BigInt, BigInt)]
      var a = 0
      while (a < indices.length) {
        var b = a + 1
        while (b < indices.length) {
          val i = indices(a)
          val j = indices(b)
          val length = gates(j) - gates(i)
          if (length > YearMaxDays && gates(i) < calculationDay) {
            b = indices.length
          } else {
            if (validYearPair(i, j) && gates(i) < calculationDay && calculationDay <= gates(j)) {
              candidates += ((i, j))
            }
            b += 1
          }
        }
        a += 1
      }
      if (candidates.isEmpty) throw new IllegalStateException("Nessuna candidata per l'anno 5000.")
      val ordered = candidates.toVector.sortBy { case (i, j) => (gates(j) - gates(i), gates(i)) }
      val r = sauce(calculationDay, calculationDay)
      val stream = askBowl(r, 1, SealYear5000)
      val rank = chooseRank(stream, BigInt(ordered.length)).toInt
      val (i, j) = ordered(rank - 1)
      Year(BigInt(5000), i, j, gates(i), gates(j))
    }

    def nextYear(calculationDay: BigInt, knownYear: Year): Year = {
      val openIndex = knownYear.closeGateIndex
      val candidates = mutable.ArrayBuffer.empty[BigInt]
      var closeIndex = openIndex + 1
      var done = false
      while (!done) {
        ensureGateIndex(closeIndex)
        val length = gates(closeIndex) - gates(openIndex)
        if (length > YearMaxDays) done = true
        else {
          if (validYearPair(openIndex, closeIndex)) candidates += closeIndex
          closeIndex += 1
        }
      }
      if (candidates.isEmpty) throw new IllegalStateException("Nessuna candidata per l'anno successivo.")
      val ordered = candidates.toVector.sortBy(j => gates(j) - gates(openIndex))
      val r = sauce(calculationDay, gates(openIndex))
      val stream = askBowl(r, 1, SealNextYear)
      val rank = chooseRank(stream, BigInt(ordered.length)).toInt
      val chosen = ordered(rank - 1)
      Year(knownYear.number + 1, openIndex, chosen, gates(openIndex), gates(chosen))
    }

    def previousYear(calculationDay: BigInt, knownYear: Year): Year = {
      val closeIndex = knownYear.openGateIndex
      val candidates = mutable.ArrayBuffer.empty[BigInt]
      var openIndex = closeIndex - 1
      var done = false
      while (!done) {
        ensureGateIndex(openIndex)
        val length = gates(closeIndex) - gates(openIndex)
        if (length > YearMaxDays) done = true
        else {
          if (validYearPair(openIndex, closeIndex)) candidates += openIndex
          openIndex -= 1
        }
      }
      if (candidates.isEmpty) throw new IllegalStateException("Nessuna candidata per l'anno precedente.")
      val ordered = candidates.toVector.sortBy(i => gates(closeIndex) - gates(i))
      val r = sauce(calculationDay, gates(closeIndex))
      val stream = askBowl(r, 1, SealPreviousYear)
      val rank = chooseRank(stream, BigInt(ordered.length)).toInt
      val chosen = ordered(rank - 1)
      Year(knownYear.number - 1, chosen, closeIndex, gates(chosen), gates(closeIndex))
    }

    def findTargetYear(calculationDay: BigInt, targetDay: BigInt): Year = {
      var y = year5000(calculationDay)
      while (targetDay > y.closeGateDay) y = nextYear(calculationDay, y)
      while (targetDay <= y.openGateDay) y = previousYear(calculationDay, y)
      if (!(y.openGateDay < targetDay && targetDay <= y.closeGateDay)) {
        throw new IllegalStateException("Il giorno bersaglio non appartiene all'intervallo aperto-chiuso dell'anno trovato.")
      }
      y
    }

    def chooseCutletCount(structureSauce: SauceResult, year: Year): Int = {
      val gateGaps = (year.closeGateIndex - year.openGateIndex).toInt
      val candidates = (MinCutlets to MaxCutlets).filter(_ <= gateGaps).toVector
      val stream = askBowl(structureSauce, 2, SealCutletCount)
      val rank = chooseRank(stream, BigInt(candidates.length)).toInt
      candidates(rank - 1)
    }

    def chooseCutletPartition(calculationDay: BigInt, structureSauce: SauceResult, year: Year, cutletCount: Int): Vector[Int] = {
      val gaps = (year.closeGateIndex - year.openGateIndex).toInt
      val required = exactGateIndex(calculationDay).flatMap { g =>
        if (year.openGateIndex < g && g < year.closeGateIndex) Some((g - year.openGateIndex).toInt) else None
      }
      val family = new CutletPartitionFamily(gaps, cutletCount, required)
      val stream = askBowl(structureSauce, 2, SealCutletPartition)
      family.unrank1(chooseRank(stream, family.count()))
    }

    def chooseCutletNameIndices(structureSauce: SauceResult, cutletCount: Int): Vector[Int] = {
      val n = fallingFactorial(17, cutletCount)
      val stream = askBowl(structureSauce, 5, SealCutletNames)
      unrankDistinctIndices(17, cutletCount, chooseRank(stream, n))
    }

    def materializeCutlets(year: Year, partition: Vector[Int], names: Vector[Int]): Vector[Cutlet] = {
      require(partition.length == names.length, "Partizione e nomi delle cotolette devono avere la stessa lunghezza.")
      val out = mutable.ArrayBuffer.empty[Cutlet]
      var cursorGate = year.openGateIndex
      var k = 0
      while (k < partition.length) {
        val openIndex = cursorGate
        val closeIndex = cursorGate + partition(k)
        out += Cutlet(names(k), openIndex, closeIndex, gate(openIndex) + 1, gate(closeIndex))
        cursorGate = closeIndex
        k += 1
      }
      out.toVector
    }

    def chooseMonthCount(structureSauce: SauceResult, year: Year): Int = {
      val length = year.closeGateDay - year.openGateDay
      val minMonths = ceilDiv(length, BigInt(MaxMonthDays)).toInt
      val maxMonths = (length / MinMonthDays).min(BigInt(MaxMonths)).toInt
      if (!(MinMonths <= minMonths && minMonths <= maxMonths && maxMonths <= MaxMonths)) {
        throw new IllegalStateException("Limiti del numero di mesi incoerenti.")
      }
      val candidates = (minMonths to maxMonths).toVector
      val stream = askBowl(structureSauce, 3, SealMonthCount)
      candidates(chooseRank(stream, BigInt(candidates.length)).toInt - 1)
    }

    def chooseMonthLengths(structureSauce: SauceResult, year: Year, monthCount: Int): Vector[Int] = {
      val length = (year.closeGateDay - year.openGateDay).toInt
      val family = new BoundedCompositionFamily(length, monthCount, MinMonthDays, MaxMonthDays)
      val stream = askBowl(structureSauce, 3, SealMonthLengths)
      family.unrank1(chooseRank(stream, family.count()))
    }

    def chooseMonthWeaving(structureSauce: SauceResult, monthLengths: Vector[Int]): Vector[Int] = {
      val family = new WeavingFamily(monthLengths)
      val stream = askBowl(structureSauce, 4, SealMonthWeaving)
      family.unrank1(chooseRank(stream, family.count()))
    }

    def chooseMonthNameIndices(structureSauce: SauceResult, monthCount: Int): Vector[Int] = {
      val n = fallingFactorial(47, monthCount)
      val stream = askBowl(structureSauce, 5, SealMonthNames)
      unrankDistinctIndices(47, monthCount, chooseRank(stream, n))
    }

    def buildYearStructure(calculationDay: BigInt, year: Year): YearStructure = {
      val firstDay = year.openGateDay + 1
      val r = sauce(calculationDay, firstDay)
      val cutletCount = chooseCutletCount(r, year)
      val partition = chooseCutletPartition(calculationDay, r, year, cutletCount)
      val cutletNames = chooseCutletNameIndices(r, cutletCount)
      val cutlets = materializeCutlets(year, partition, cutletNames)
      val monthCount = chooseMonthCount(r, year)
      val monthLengths = chooseMonthLengths(r, year, monthCount)
      val monthWeaving = chooseMonthWeaving(r, monthLengths)
      val monthNames = chooseMonthNameIndices(r, monthCount)
      YearStructure(cutletCount, partition, cutletNames, cutlets, monthCount, monthLengths, monthWeaving, monthNames)
    }

    def calendarDate(calculationDay: BigInt, targetDay: BigInt): CalendarDate = {
      val year = findTargetYear(calculationDay, targetDay)
      val structure = buildYearStructure(calculationDay, year)
      val chosenCutlet = structure.cutlets.find(c => c.firstDay <= targetDay && targetDay <= c.lastDay)
        .getOrElse(throw new IllegalStateException("Nessuna cotoletta contiene il giorno bersaglio."))
      val dayInCutlet = targetDay - chosenCutlet.firstDay + 1
      val yearOffset0 = (targetDay - (year.openGateDay + 1)).toInt
      val monthId = structure.monthWeaving(yearOffset0)
      val monthCanonicalIndex = structure.monthNameIndices(monthId - 1)
      var dayInMonth = 0
      var p = 0
      while (p <= yearOffset0) {
        if (structure.monthWeaving(p) == monthId) dayInMonth += 1
        p += 1
      }
      CalendarDate(
        year.number,
        SourceLanguageCatalog.cutlet(chosenCutlet.canonicalNameIndex).italian,
        dayInCutlet,
        SourceLanguageCatalog.month(monthCanonicalIndex).italian,
        dayInMonth
      )
    }
  }
}
