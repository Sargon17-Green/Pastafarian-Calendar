package pastafari.monster

import scala.collection.mutable

final case class BaseMonsterContext(
  calculationDay: BigInt,
  targetDay: BigInt,
  var phase: String = "BOOT",
  var subPhase: Int = 0,
  var mode: String = "BASE",
  var status: String = "NEW",
  branchTrace: mutable.ArrayBuffer[String] = mutable.ArrayBuffer.empty[String],
  diagnostics: mutable.ArrayBuffer[String] = mutable.ArrayBuffer.empty[String],
  var legacyRemainderInput: Option[BigInt] = None,
  var legacyRemainderOutput: Option[BigInt] = None,
  var patchedSaveOutput: Option[BigInt] = None,
  var patch01Applied: Boolean = false,
  var legacyDayTagInput: Option[BigInt] = None,
  var legacyDayTagOutput: Option[BigInt] = None,
  var patchedDayTagOutput: Option[BigInt] = None,
  var patch02Applied: Boolean = false,
  var legacyDistanceOutput: Option[BigInt] = None,
  var patchedDistanceOutput: Option[BigInt] = None,
  var patch03Applied: Boolean = false,
  var legacyStoneRowsOutput: Option[Vector[Vector[BigInt]]] = None,
  var patchedStoneRowsOutput: Option[Vector[Vector[BigInt]]] = None,
  var patch04Applied: Boolean = false,
  var priorHiddenInput: Option[Vector[BigInt]] = None,
  var priorVisibleInput: Option[Vector[BigInt]] = None,
  var priorIndexInput: Option[Int] = None,
  var priorLagInput: Option[Int] = None,
  var legacyPriorOutput: Option[BigInt] = None,
  var patchedPriorOutput: Option[BigInt] = None,
  var patch05Applied: Boolean = false,
  var grindStepInput: Option[Int] = None,
  var grindValueInput: Option[BigInt] = None,
  var grindPrev1Input: Option[BigInt] = None,
  var grindPrev3Input: Option[BigInt] = None,
  var grindPrev7Input: Option[BigInt] = None,
  var grindStonesInput: Option[Vector[BigInt]] = None,
  var legacyGrindRuleOutput: Option[LegacyGrindRule] = None,
  var legacyGrindOutput: Option[BigInt] = None,
  var patchedGrindRuleOutput: Option[LegacyGrindRule] = None,
  var patchedGrindOutput: Option[BigInt] = None,
  var patch06Applied: Boolean = false,
  var permutationRankInput: Option[Int] = None,
  var legacyPermutationOutput: Option[Vector[Int]] = None,
  var patchedPermutationOutput: Option[Vector[Int]] = None,
  var patch07Applied: Boolean = false,
  var bowlStepInput: Option[Int] = None,
  var bowlRankInput: Option[Int] = None,
  var bowlInput: Option[Vector[BigInt]] = None,
  var bowlDropInput: Option[BigInt] = None,
  var bowlStonesInput: Option[Vector[BigInt]] = None,
  var legacyBowlOrderOutput: Option[Vector[Int]] = None,
  var legacyBowlPoursOutput: Option[Vector[BigInt]] = None,
  var legacyBowlOutput: Option[Vector[BigInt]] = None,
  var patchedBowlOutput: Option[Vector[BigInt]] = None,
  var patch08Applied: Boolean = false,
  var postStirInput: Option[Vector[BigInt]] = None,
  var legacyVaultRounds: Option[Vector[LegacyVaultRound]] = None,
  var legacyVaultOutput: Option[Vector[BigInt]] = None
)

final class BaseMetricsShell {
  private val counters = mutable.Map.empty[String, BigInt]

  def bump(name: String): Unit = {
    counters.update(name, counters.getOrElse(name, BigInt(0)) + 1)
  }

  def snapshot: Map[String, BigInt] = counters.toMap
}

final class BaseValidationManager {
  def requireFreshContext(ctx: BaseMonsterContext): Unit = {
    if (ctx.status != "NEW") {
      throw new IllegalStateException("Il contesto di base non è nuovo.")
    }
    if (ctx.branchTrace.nonEmpty) {
      throw new IllegalStateException("La traccia di un contesto nuovo deve essere vuota.")
    }
  }


  def requireDiscovery09Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_09_VAULT" ||
        ctx.status != "LEGACY_VAULT_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT","DISCOVERY_09_VAULT") ||
        ctx.postStirInput.isEmpty || ctx.legacyVaultRounds.isEmpty ||
        ctx.legacyVaultOutput.isEmpty) {
      throw new IllegalStateException("DISCOVERY 09 richiede dodici giri completi.")
    }
    val initial = ctx.postStirInput.get
    val rounds = ctx.legacyVaultRounds.get
    val output = ctx.legacyVaultOutput.get
    if (initial.length != 6 || rounds.length != 12 ||
        output.length != 6 || output != rounds.last.bowls ||
        rounds.map(_.step) != (1 to 12).toVector ||
        rounds.exists(r => r.bowls.length != 6 ||
          r.order.sorted != Vector(1,2,3,4,5,6) ||
          r.bowls.exists(x => x < 1 || x > ((BigInt(1)<<127)-1)))) {
      throw new IllegalStateException("Registro storico incompleto o incoerente.")
    }
    // La validazione conferma tutte le dodici istantanee diagnostiche;
    // la corrispondenza normativa è verificata solo nei test.
    val rebuilt = LegacyVaultAdapter.vaultOld(initial)
    if (rebuilt.rounds != rounds || rebuilt.bowls != output) {
      throw new IllegalStateException("Le tracce del caveau storico sono contraffatte.")
    }
  }

  def requirePatch08Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_08_BOWL_FREEZE" ||
        ctx.status != "PATCH_08_READY" ||
        ctx.branchTrace.toVector != Vector(
          "BOOT", "DISCOVERY_08_BOWL_ALIAS", "PATCH_08_BOWL_FREEZE") ||
        ctx.bowlStepInput.isEmpty || ctx.bowlRankInput.isEmpty ||
        ctx.bowlInput.isEmpty || ctx.bowlDropInput.isEmpty ||
        ctx.bowlStonesInput.isEmpty || ctx.legacyBowlOrderOutput.isEmpty ||
        ctx.legacyBowlPoursOutput.isEmpty || ctx.legacyBowlOutput.isEmpty ||
        ctx.patchedBowlOutput.isEmpty || !ctx.patch08Applied) {
      throw new IllegalStateException("PATCH 08 richiede la discovery nella stessa invocazione.")
    }
    val step = ctx.bowlStepInput.get
    val rank = ctx.bowlRankInput.get
    val old = ctx.bowlInput.get
    val stones = ctx.bowlStonesInput.get
    val drop = ctx.bowlDropInput.get
    val order = ctx.legacyBowlOrderOutput.get
    val pours = ctx.legacyBowlPoursOutput.get
    val legacy = ctx.legacyBowlOutput.get
    val patched = ctx.patchedBowlOutput.get
    if (step < 1 || step > 46 || rank < 1 || rank > 720 ||
        old.length != 6 || stones.length != 5 || pours.length != 6 ||
        order.length != 6 || order.sorted != Vector(1,2,3,4,5,6) ||
        legacy.length != 6 || patched.length != 6) {
      throw new IllegalStateException("Dimensione, indice o ordine PATCH 08 non valido.")
    }
    // Verifica fattoriale, getti e ricorrenza indipendente dal wrapper.
    val expectedOrder = Patch07PermutationWrapper.permutationPatch(rank)
    if (order != expectedOrder)
      throw new IllegalStateException("Ordine delle ciotole manomesso.")
    val expectedPours = Vector.tabulate[BigInt](6) { index =>
      if (index >= 3) BigInt(0)
      else Patch01SaveWrapper.savePatch(
        drop*drop + stones(index)*old(order(index)-1) +
        (3 + 2*index)*step)
    }
    if (pours != expectedPours)
      throw new IllegalStateException("I getti non vengono dall'istantanea vecchia.")
    val stoneKinds = Vector(0,1,2,3,4,0)
    val values = Vector.newBuilder[(Int,BigInt)]
    for (position <- 1 to 6) {
      val current = order(position-1)-1
      val previous = order((position+4)%6)-1
      val following = order(position%6)-1
      val sum = old(current) + 2*old(previous) + 3*old(following) +
        pours(position-1) + drop + stones(stoneKinds(position-1))
      val value = Patch01SaveWrapper.savePatch(
        sum*sum + 5*old(previous)*old(following) + step*position)
      values += ((current,value))
    }
    val frozen = values.result().sortBy(_._1).map(_._2)
    val historical = LegacyBowlAliasAdapter.bowlAlias(old,drop,stones,step,rank)
    if (frozen != patched || historical.order != order ||
        historical.pours != pours || historical.bowls != legacy)
      throw new IllegalStateException("Output normativo o cicatrice storica falsificati.")
  }

  def requireDiscovery08Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_08_BOWL_ALIAS" ||
        ctx.status != "LEGACY_BOWL_ALIAS_READY" ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_08_BOWL_ALIAS") ||
        ctx.bowlStepInput.isEmpty || ctx.bowlRankInput.isEmpty ||
        ctx.bowlInput.isEmpty || ctx.bowlDropInput.isEmpty ||
        ctx.bowlStonesInput.isEmpty || ctx.legacyBowlOrderOutput.isEmpty ||
        ctx.legacyBowlPoursOutput.isEmpty || ctx.legacyBowlOutput.isEmpty) {
      throw new IllegalStateException("La mescolatura legacy non è pronta.")
    }
    val step = ctx.bowlStepInput.get
    val rank = ctx.bowlRankInput.get
    val original = ctx.bowlInput.get
    val stones = ctx.bowlStonesInput.get
    val order = ctx.legacyBowlOrderOutput.get
    val pours = ctx.legacyBowlPoursOutput.get
    val result = ctx.legacyBowlOutput.get
    if (step < 1 || step > 46 || rank < 1 || rank > 720 ||
        original.length != 6 || stones.length != 5 ||
        order.length != 6 || order.sorted != Vector(1,2,3,4,5,6) ||
        pours.length != 6 || result.length != 6 ||
        result.exists(x => x < 1 || x > ((BigInt(1) << 127)-1)) ||
        order != Patch07PermutationWrapper.permutationPatch(rank)) {
      throw new IllegalStateException("Parametri o rango della mescolatura incoerenti.")
    }
    val expected = LegacyBowlAliasAdapter.bowlAlias(
      original, ctx.bowlDropInput.get, stones, step, rank)
    if (expected.order != order || expected.pours != pours ||
        expected.bowls != result) {
      throw new IllegalStateException("Risultato o getti della mescolatura falsificati.")
    }
  }

  def requirePatch07Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_07_PERMUTATION" ||
        ctx.status != "PATCH_07_READY" ||
        ctx.permutationRankInput.isEmpty ||
        ctx.legacyPermutationOutput.isEmpty ||
        ctx.patchedPermutationOutput.isEmpty ||
        !ctx.patch07Applied ||
        ctx.branchTrace.toVector != Vector(
          "BOOT", "DISCOVERY_07_PERMUTATION", "PATCH_07_PERMUTATION")) {
      throw new IllegalStateException(
        "PATCH 07 richiede la discovery e il risultato nello stesso contesto.")
    }
    val rank = ctx.permutationRankInput.get
    if (rank < 1 || rank > 720 ||
        ctx.legacyPermutationOutput.get !=
          LegacyPermutationAdapter.oldPermutationUnrank0(rank)) {
      throw new IllegalStateException("La prova della permutazione legacy è incoerente.")
    }

    // Validazione indipendente dalla formula del wrapper: unranking 1-based
    // sul sistema fattoriale, con rango ridotto a zero UNA SOLA volta.
    var rest = rank - 1
    val factorials = Vector(1, 1, 2, 6, 24, 120, 720)
    val remaining = scala.collection.mutable.ArrayBuffer(1, 2, 3, 4, 5, 6)
    val answer = Vector.newBuilder[Int]
    for (slots <- 6 to 1 by -1) {
      val block = factorials(slots - 1)
      val index = rest / block
      rest = rest % block
      answer += remaining.remove(index)
    }
    val normative = answer.result()
    if (remaining.nonEmpty || rest != 0 ||
        ctx.patchedPermutationOutput.get != normative ||
        normative.sorted != Vector(1, 2, 3, 4, 5, 6)) {
      throw new IllegalStateException("Permutazione PATCH 07 alterata o non normativa.")
    }
  }

  def requireDiscovery07Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_07_PERMUTATION" ||
        ctx.status != "LEGACY_PERMUTATION_READY" ||
        ctx.permutationRankInput.isEmpty ||
        ctx.legacyPermutationOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_07_PERMUTATION")) {
      throw new IllegalStateException("La permutazione legacy non è pronta.")
    }
    val rank = ctx.permutationRankInput.get
    val out = ctx.legacyPermutationOutput.get
    if (rank < 1 || rank > 720 || out.length != 6 ||
        out.sorted != Vector(1, 2, 3, 4, 5, 6) ||
        out != LegacyPermutationAdapter.oldPermutationUnrank0(rank)) {
      throw new IllegalStateException("La permutazione legacy non corrisponde al suo rango.")
    }
  }

  def requirePatch06Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_06_GRIND" || ctx.status != "PATCH_06_READY" ||
        ctx.grindStepInput.isEmpty || ctx.grindValueInput.isEmpty ||
        ctx.grindPrev1Input.isEmpty || ctx.grindPrev3Input.isEmpty ||
        ctx.grindPrev7Input.isEmpty || ctx.grindStonesInput.isEmpty ||
        ctx.legacyGrindRuleOutput.isEmpty || ctx.legacyGrindOutput.isEmpty ||
        ctx.patchedGrindRuleOutput.isEmpty || ctx.patchedGrindOutput.isEmpty ||
        !ctx.patch06Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_06_GRIND", "PATCH_06_GRIND")) {
      throw new IllegalStateException("La PATCH 06 richiede la discovery nello stesso contesto.")
    }
    val step = ctx.grindStepInput.get
    val stones = ctx.grindStonesInput.get
    if (step < 1 || step > 11 || stones.length != 5)
      throw new IllegalStateException("Parametri di macinatura PATCH 06 non validi.")
    val table = LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL
    if (table.length != 12 ||
        ctx.legacyGrindRuleOutput.get != table(step - 1) ||
        ctx.patchedGrindRuleOutput.get != table(step))
      throw new IllegalStateException("Letture di macinatura legacy e patched incoerenti.")

    def evaluate(rule: LegacyGrindRule): BigInt =
      Patch01SaveWrapper.savePatch(
        ctx.grindValueInput.get * ctx.grindValueInput.get +
          rule.a * ctx.grindValueInput.get +
          rule.b * ctx.grindPrev1Input.get +
          rule.c * ctx.grindPrev3Input.get +
          rule.d * ctx.grindPrev7Input.get + stones(rule.stoneKind)
      )

    if (ctx.legacyGrindOutput.get != evaluate(table(step - 1)) ||
        ctx.patchedGrindOutput.get != evaluate(table(step))) {
      throw new IllegalStateException("Risultato di macinatura falsificato o non normativo.")
    }
  }

  def requireDiscovery06Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_06_GRIND" ||
        ctx.status != "LEGACY_GRIND_READY" ||
        ctx.grindStepInput.isEmpty || ctx.grindValueInput.isEmpty ||
        ctx.grindPrev1Input.isEmpty || ctx.grindPrev3Input.isEmpty ||
        ctx.grindPrev7Input.isEmpty || ctx.grindStonesInput.isEmpty ||
        ctx.legacyGrindRuleOutput.isEmpty || ctx.legacyGrindOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_06_GRIND")) {
      throw new IllegalStateException("La macinatura legacy non è pronta.")
    }
    val step = ctx.grindStepInput.get
    if (step < 1 || step > 11 || ctx.grindStonesInput.get.length != 5 ||
        ctx.legacyGrindRuleOutput.get != LegacyGrindTableAdapter.legacyGrindRule(step)) {
      throw new IllegalStateException("Catalogo dei macinamenti legacy incoerente.")
    }
  }

  def requirePatch05Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_05_PRIOR" ||
        ctx.status != "PATCH_05_READY" ||
        ctx.priorHiddenInput.isEmpty || ctx.priorVisibleInput.isEmpty ||
        ctx.priorIndexInput.isEmpty || ctx.priorLagInput.isEmpty ||
        ctx.legacyPriorOutput.isEmpty || ctx.patchedPriorOutput.isEmpty ||
        !ctx.patch05Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_05_PRIOR", "PATCH_05_PRIOR")) {
      throw new IllegalStateException("La PATCH 05 non è pronta nella stessa invocazione.")
    }
    val hidden = ctx.priorHiddenInput.get
    val visible = ctx.priorVisibleInput.get
    val index = ctx.priorIndexInput.get
    val lag = ctx.priorLagInput.get
    if (hidden.length != 7 || index < 1 || index > 47 ||
        visible.length != index - 1 || !Set(1, 3, 7).contains(lag)) {
      throw new IllegalStateException("Finestra temporale PATCH 05 non valida.")
    }
    val expectedPosition = index - lag
    val expected =
      if (expectedPosition <= 0) hidden(-expectedPosition)
      else visible(expectedPosition - 1)
    if (ctx.patchedPriorOutput.get != expected ||
        ctx.legacyPriorOutput.get != LegacyPriorAdapter.legacyPrior(hidden, visible, index, lag)) {
      throw new IllegalStateException("La PATCH 05 non corrisponde alle due letture attese.")
    }
  }

  def requireDiscovery05Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_05_PRIOR" ||
        ctx.status != "LEGACY_PRIOR_READY" ||
        ctx.priorHiddenInput.isEmpty || ctx.priorVisibleInput.isEmpty ||
        ctx.priorIndexInput.isEmpty || ctx.priorLagInput.isEmpty ||
        ctx.legacyPriorOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_05_PRIOR")) {
      throw new IllegalStateException("Registro temporale legacy non pronto.")
    }
    if (ctx.priorHiddenInput.get.length != 7 ||
        ctx.priorIndexInput.get < 1 || ctx.priorIndexInput.get > 47 ||
        ctx.priorVisibleInput.get.length != ctx.priorIndexInput.get - 1 ||
        !Set(1, 3, 7).contains(ctx.priorLagInput.get)) {
      throw new IllegalStateException("Dati temporali della discovery incoerenti.")
    }
  }

  def requirePatch04Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_04_STONES" ||
        ctx.status != "PATCH_04_READY" ||
        ctx.legacyStoneRowsOutput.isEmpty ||
        ctx.patchedStoneRowsOutput.isEmpty ||
        !ctx.patch04Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_04_STONES", "PATCH_04_STONES")) {
      throw new IllegalStateException("La PATCH 04 delle pietre non è pronta.")
    }
    val legacy = ctx.legacyStoneRowsOutput.get
    val corrected = ctx.patchedStoneRowsOutput.get
    if (legacy.length != 46 || legacy.exists(_.length != 5) ||
        corrected.length != 46 || corrected.exists(_.length != 5) ||
        corrected != Patch04StonesWrapper.stonesPatch(legacy)) {
      throw new IllegalStateException(
        "La PATCH 04 deve ricostruire le righe dallo snapshot precedente."
      )
    }
  }

  def requireDiscovery04Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_04_STONES" ||
        ctx.status != "LEGACY_STONES_READY" ||
        ctx.legacyStoneRowsOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_04_STONES")) {
      throw new IllegalStateException("La tabella legacy delle pietre non è pronta.")
    }
    val rows = ctx.legacyStoneRowsOutput.get
    if (rows.length != 46 || rows.exists(_.length != 5)) {
      throw new IllegalStateException("Forma della tabella legacy delle pietre non valida.")
    }
  }

  def requirePatch03Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_03_DISTANCE" ||
        ctx.status != "PATCH_03_READY" ||
        ctx.legacyDistanceOutput.isEmpty ||
        ctx.patchedDistanceOutput.isEmpty ||
        !ctx.patch03Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_03_DISTANCE", "PATCH_03_DISTANCE")) {
      throw new IllegalStateException("La distanza PATCH 03 non è pronta.")
    }
    if (ctx.legacyDistanceOutput.get < 0 ||
        ctx.patchedDistanceOutput.get != ctx.legacyDistanceOutput.get + 1) {
      throw new IllegalStateException("PATCH 03 deve aggiungere esattamente un giorno.")
    }
  }

  def requireDiscovery03Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_03_DISTANCE" ||
        ctx.status != "LEGACY_DISTANCE_READY" ||
        ctx.legacyDistanceOutput.isEmpty ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_03_DISTANCE")) {
      throw new IllegalStateException("La distanza legacy non è pronta nel contesto corrente.")
    }
  }

  def requirePatch02Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_02_DAY_TAG" ||
        ctx.status != "PATCH_02_READY" ||
        ctx.legacyDayTagInput.isEmpty ||
        ctx.legacyDayTagOutput.isEmpty ||
        ctx.patchedDayTagOutput.isEmpty ||
        !ctx.patch02Applied ||
        ctx.branchTrace.toVector != Vector("BOOT", "DISCOVERY_02_DAY_TAG", "PATCH_02_DAY_TAG")) {
      throw new IllegalStateException("Il PATCH 02 non è pronto nel contesto corrente.")
    }
    // Convalida indipendente del delta locale, senza usare l'oracolo di test.
    val expectedIncrement =
      if (ctx.legacyDayTagInput.get >= BigInt(-15055671)) BigInt(1) else BigInt(0)
    if (ctx.patchedDayTagOutput.get != ctx.legacyDayTagOutput.get + expectedIncrement) {
      throw new IllegalStateException("Il PATCH 02 ha alterato la cicatrice in modo non consentito.")
    }
  }

  def requireDiscovery02Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_02_DAY_TAG" ||
        ctx.status != "LEGACY_DAY_TAG_READY" ||
        ctx.legacyDayTagInput.isEmpty ||
        ctx.legacyDayTagOutput.isEmpty ||
        ctx.branchTrace.lastOption != Some("DISCOVERY_02_DAY_TAG")) {
      throw new IllegalStateException("La nota del giorno legacy non è pronta.")
    }
  }

  def requirePatch01Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "PATCH_01_SAVE" ||
        ctx.status != "PATCH_01_READY" ||
        ctx.legacyRemainderInput.isEmpty ||
        ctx.legacyRemainderOutput.isEmpty ||
        ctx.patchedSaveOutput.isEmpty ||
        !ctx.patch01Applied ||
        ctx.branchTrace.lastOption != Some("PATCH_01_SAVE")) {
      throw new IllegalStateException("Il PATCH 01 non è pronto nel contesto corrente.")
    }
  }

  def requireDiscovery01Ready(ctx: BaseMonsterContext): Unit = {
    if (ctx.phase != "DISCOVERY_01_REMAINDER" ||
        ctx.status != "LEGACY_REMAINDER_READY" ||
        ctx.legacyRemainderInput.isEmpty ||
        ctx.legacyRemainderOutput.isEmpty) {
      throw new IllegalStateException("Il residuo legacy non è pronto nel contesto corrente.")
    }
  }
}

final case class WrappedMonsterError(messageItalian: String, cause: Throwable)
  extends RuntimeException(messageItalian, cause)

object BaseErrorWrapper {
  def wrap(where: String, error: Throwable): WrappedMonsterError =
    WrappedMonsterError("Errore deterministico nello strato di base: " + where, error)
}

trait BasePhaseHandler {
  def phase: String
  def handle(ctx: BaseMonsterContext): Unit
}

final class BaseMonsterDispatcher(handlers: Vector[BasePhaseHandler]) {
  private val byPhase: Map[String, BasePhaseHandler] = {
    val pairs = handlers.map(h => h.phase -> h)
    if (pairs.map(_._1).distinct.size != pairs.size) {
      throw new IllegalArgumentException("Ogni fase di base deve avere un solo handler.")
    }
    pairs.toMap
  }

  def dispatch(ctx: BaseMonsterContext): Unit = {
    val handler = byPhase.getOrElse(
      ctx.phase,
      throw new IllegalStateException("Fase di base non registrata: " + ctx.phase)
    )
    handler.handle(ctx)
  }
}

final class BaseBootstrapHandler(metrics: BaseMetricsShell) extends BasePhaseHandler {
  override val phase: String = "BOOT"

  override def handle(ctx: BaseMonsterContext): Unit = {
    ctx.branchTrace.append("BOOT")
    metrics.bump("base.bootstrap.calls")
    ctx.status = "BOOTSTRAPPED"
  }
}

final class BaseMonsterManager {
  private val metrics = new BaseMetricsShell
  private val validation = new BaseValidationManager
  private val dispatcher = new BaseMonsterDispatcher(Vector(
    new BaseBootstrapHandler(metrics),
    new Discovery01RemainderHandler(metrics),
    new Patch01SaveHandler(metrics),
    new Discovery02DayTagHandler(metrics),
    new Patch02DayTagHandler(metrics),
    new Discovery03DistanceHandler(metrics),
    new Patch03DistanceHandler(metrics),
    new Discovery04StonesHandler(metrics),
    new Patch04StonesHandler(metrics),
    new Discovery05PriorHandler(metrics),
    new Patch05PriorHandler(metrics),
    new Discovery06GrindHandler(metrics),
    new Patch06GrindHandler(metrics),
    new Discovery07PermutationHandler(metrics),
    new Patch07PermutationHandler(metrics),
    new Discovery08BowlAliasHandler(metrics),
    new Patch08BowlHandler(metrics),
    new Discovery09VaultHandler(metrics)
  ))

  def bootstrap(calculationDay: BigInt, targetDay: BigInt): BaseMonsterContext = {
    val ctx = BaseMonsterContext(calculationDay, targetDay)
    try {
      validation.requireFreshContext(ctx)
      dispatcher.dispatch(ctx)
      ctx
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("bootstrap", e)
    }
  }

  def discover01Remainder(calculationDay: BigInt, targetDay: BigInt, input: BigInt): Discovery01Report = {
    // La stessa invocazione possiede sia lo stato BOOT sia quello DISCOVERY 01.
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.legacyRemainderInput = Some(input)
    ctx.phase = "DISCOVERY_01_REMAINDER"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery01Ready(ctx)
      Discovery01Report(
        input = ctx.legacyRemainderInput.get,
        legacyOutput = ctx.legacyRemainderOutput.get,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery01", e)
    }
  }

  def patch01Save(calculationDay: BigInt, targetDay: BigInt, input: BigInt): Patch01SaveReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.legacyRemainderInput = Some(input)
    ctx.phase = "DISCOVERY_01_REMAINDER"
    try {
      // La cicatrice storica viene percorsa davvero prima del wrapper PATCH 01.
      dispatcher.dispatch(ctx)
      validation.requireDiscovery01Ready(ctx)
      ctx.phase = "PATCH_01_SAVE"
      dispatcher.dispatch(ctx)
      validation.requirePatch01Ready(ctx)
      Patch01SaveReport(
        input = ctx.legacyRemainderInput.get,
        legacyOutput = ctx.legacyRemainderOutput.get,
        patchedOutput = ctx.patchedSaveOutput.get,
        patchApplied = ctx.patch01Applied,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch01", e)
    }
  }

  def discover02DayTag(calculationDay: BigInt, targetDay: BigInt, day: BigInt): Discovery02DayTagReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.legacyDayTagInput = Some(day)
    ctx.phase = "DISCOVERY_02_DAY_TAG"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery02Ready(ctx)
      Discovery02DayTagReport(
        queriedDay = ctx.legacyDayTagInput.get,
        legacyTag = ctx.legacyDayTagOutput.get,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery02", e)
    }
  }

  def patch02DayTag(calculationDay: BigInt, targetDay: BigInt, day: BigInt): Patch02DayTagReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.legacyDayTagInput = Some(day)
    ctx.phase = "DISCOVERY_02_DAY_TAG"
    try {
      // Stessa invocazione: la cicatrice storica deve essere osservata prima della patch.
      dispatcher.dispatch(ctx)
      validation.requireDiscovery02Ready(ctx)
      ctx.phase = "PATCH_02_DAY_TAG"
      dispatcher.dispatch(ctx)
      validation.requirePatch02Ready(ctx)
      Patch02DayTagReport(
        queriedDay = ctx.legacyDayTagInput.get,
        legacyTag = ctx.legacyDayTagOutput.get,
        patchedTag = ctx.patchedDayTagOutput.get,
        patchApplied = ctx.patch02Applied,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch02", e)
    }
  }

  def discover03Distance(calculationDay: BigInt, targetDay: BigInt): Discovery03DistanceReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.phase = "DISCOVERY_03_DISTANCE"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery03Ready(ctx)
      Discovery03DistanceReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        legacyDistance = ctx.legacyDistanceOutput.get,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery03", e)
    }
  }

  def patch03Distance(calculationDay: BigInt, targetDay: BigInt): Patch03DistanceReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.phase = "DISCOVERY_03_DISTANCE"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery03Ready(ctx)
      ctx.phase = "PATCH_03_DISTANCE"
      dispatcher.dispatch(ctx)
      validation.requirePatch03Ready(ctx)
      Patch03DistanceReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        legacyDistance = ctx.legacyDistanceOutput.get,
        patchedDistance = ctx.patchedDistanceOutput.get,
        patchApplied = ctx.patch03Applied,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch03", e)
    }
  }

  def discover04Stones(calculationDay: BigInt, targetDay: BigInt): Discovery04StonesReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.phase = "DISCOVERY_04_STONES"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery04Ready(ctx)
      Discovery04StonesReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        legacyStoneRows = ctx.legacyStoneRowsOutput.get,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery04", e)
    }
  }

  def patch04Stones(calculationDay: BigInt, targetDay: BigInt): Patch04StonesReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.phase = "DISCOVERY_04_STONES"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery04Ready(ctx)
      ctx.phase = "PATCH_04_STONES"
      dispatcher.dispatch(ctx)
      validation.requirePatch04Ready(ctx)
      Patch04StonesReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        legacyStoneRows = ctx.legacyStoneRowsOutput.get,
        patchedStoneRows = ctx.patchedStoneRowsOutput.get,
        patchApplied = ctx.patch04Applied,
        phase = ctx.phase,
        status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch04", e)
    }
  }

  def discover05Prior(
    calculationDay: BigInt, targetDay: BigInt,
    hiddenDrops: Vector[BigInt], visibleDropsSoFar: Vector[BigInt],
    index: Int, lag: Int
  ): Discovery05PriorReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.priorHiddenInput = Some(hiddenDrops)
    ctx.priorVisibleInput = Some(visibleDropsSoFar)
    ctx.priorIndexInput = Some(index)
    ctx.priorLagInput = Some(lag)
    ctx.phase = "DISCOVERY_05_PRIOR"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery05Ready(ctx)
      Discovery05PriorReport(
        ctx.calculationDay, ctx.targetDay,
        ctx.priorHiddenInput.get, ctx.priorVisibleInput.get,
        ctx.priorIndexInput.get, ctx.priorLagInput.get,
        ctx.legacyPriorOutput.get, ctx.phase, ctx.status,
        ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery05", e)
    }
  }

  def patch05Prior(
    calculationDay: BigInt, targetDay: BigInt,
    hiddenDrops: Vector[BigInt], visibleDropsSoFar: Vector[BigInt],
    index: Int, lag: Int
  ): Patch05PriorReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.priorHiddenInput = Some(hiddenDrops)
    ctx.priorVisibleInput = Some(visibleDropsSoFar)
    ctx.priorIndexInput = Some(index)
    ctx.priorLagInput = Some(lag)
    ctx.phase = "DISCOVERY_05_PRIOR"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery05Ready(ctx)
      ctx.phase = "PATCH_05_PRIOR"
      dispatcher.dispatch(ctx)
      validation.requirePatch05Ready(ctx)
      Patch05PriorReport(
        ctx.calculationDay, ctx.targetDay,
        ctx.priorHiddenInput.get, ctx.priorVisibleInput.get,
        ctx.priorIndexInput.get, ctx.priorLagInput.get,
        ctx.legacyPriorOutput.get, ctx.patchedPriorOutput.get,
        ctx.patch05Applied, ctx.phase, ctx.status,
        ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch05", e)
    }
  }

  def discover06Grind(
    calculationDay: BigInt, targetDay: BigInt, step: Int,
    oldValue: BigInt, previous1: BigInt, previous3: BigInt,
    previous7: BigInt, stones: Vector[BigInt]
  ): Discovery06GrindReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.grindStepInput = Some(step)
    ctx.grindValueInput = Some(oldValue)
    ctx.grindPrev1Input = Some(previous1)
    ctx.grindPrev3Input = Some(previous3)
    ctx.grindPrev7Input = Some(previous7)
    ctx.grindStonesInput = Some(stones)
    ctx.phase = "DISCOVERY_06_GRIND"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery06Ready(ctx)
      Discovery06GrindReport(
        calculationDay = ctx.calculationDay, targetDay = ctx.targetDay,
        step = ctx.grindStepInput.get, oldValue = ctx.grindValueInput.get,
        previous1 = ctx.grindPrev1Input.get, previous3 = ctx.grindPrev3Input.get,
        previous7 = ctx.grindPrev7Input.get, stones = ctx.grindStonesInput.get,
        legacyRule = ctx.legacyGrindRuleOutput.get, legacyValue = ctx.legacyGrindOutput.get,
        phase = ctx.phase, status = ctx.status, trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery06", e)
    }
  }

  def patch06Grind(
    calculationDay: BigInt, targetDay: BigInt, step: Int,
    oldValue: BigInt, previous1: BigInt, previous3: BigInt,
    previous7: BigInt, stones: Vector[BigInt]
  ): Patch06GrindReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.grindStepInput = Some(step)
    ctx.grindValueInput = Some(oldValue)
    ctx.grindPrev1Input = Some(previous1)
    ctx.grindPrev3Input = Some(previous3)
    ctx.grindPrev7Input = Some(previous7)
    ctx.grindStonesInput = Some(stones)
    ctx.phase = "DISCOVERY_06_GRIND"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery06Ready(ctx)
      ctx.phase = "PATCH_06_GRIND"
      dispatcher.dispatch(ctx)
      validation.requirePatch06Ready(ctx)
      Patch06GrindReport(
        calculationDay = ctx.calculationDay, targetDay = ctx.targetDay,
        step = ctx.grindStepInput.get, oldValue = ctx.grindValueInput.get,
        previous1 = ctx.grindPrev1Input.get, previous3 = ctx.grindPrev3Input.get,
        previous7 = ctx.grindPrev7Input.get, stones = ctx.grindStonesInput.get,
        legacyRule = ctx.legacyGrindRuleOutput.get, legacyValue = ctx.legacyGrindOutput.get,
        patchedRule = ctx.patchedGrindRuleOutput.get, patchedValue = ctx.patchedGrindOutput.get,
        patchApplied = ctx.patch06Applied,
        phase = ctx.phase, status = ctx.status, trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch06", e)
    }
  }

  def discover07Permutation(
    calculationDay: BigInt, targetDay: BigInt, rank1: Int
  ): Discovery07PermutationReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.permutationRankInput = Some(rank1)
    ctx.phase = "DISCOVERY_07_PERMUTATION"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery07Ready(ctx)
      Discovery07PermutationReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        requestedRank1 = ctx.permutationRankInput.get,
        legacyPermutation = ctx.legacyPermutationOutput.get,
        phase = ctx.phase, status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("discovery07", e)
    }
  }

  def patch07Permutation(
    calculationDay: BigInt, targetDay: BigInt, rank1: Int
  ): Patch07PermutationReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.permutationRankInput = Some(rank1)
    ctx.phase = "DISCOVERY_07_PERMUTATION"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery07Ready(ctx)
      ctx.phase = "PATCH_07_PERMUTATION"
      dispatcher.dispatch(ctx)
      validation.requirePatch07Ready(ctx)
      Patch07PermutationReport(
        calculationDay = ctx.calculationDay,
        targetDay = ctx.targetDay,
        requestedRank1 = ctx.permutationRankInput.get,
        legacyPermutation = ctx.legacyPermutationOutput.get,
        patchedPermutation = ctx.patchedPermutationOutput.get,
        patchApplied = ctx.patch07Applied,
        phase = ctx.phase, status = ctx.status,
        trace = ctx.branchTrace.toVector
      )
    } catch {
      case e: Throwable => throw BaseErrorWrapper.wrap("patch07", e)
    }
  }

  def discover08BowlAlias(
    calculationDay: BigInt, targetDay: BigInt,
    initial: Vector[BigInt], drop: BigInt,
    stones: Vector[BigInt], step: Int, rank1: Int
  ): Discovery08BowlAliasReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.bowlInput = Some(initial)
    ctx.bowlDropInput = Some(drop)
    ctx.bowlStonesInput = Some(stones)
    ctx.bowlStepInput = Some(step)
    ctx.bowlRankInput = Some(rank1)
    ctx.phase = "DISCOVERY_08_BOWL_ALIAS"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery08Ready(ctx)
      Discovery08BowlAliasReport(
        ctx.calculationDay,ctx.targetDay,ctx.bowlInput.get,
        ctx.bowlDropInput.get,ctx.bowlStonesInput.get,ctx.bowlStepInput.get,
        ctx.bowlRankInput.get,ctx.legacyBowlOrderOutput.get,
        ctx.legacyBowlPoursOutput.get,ctx.legacyBowlOutput.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("discovery08",error)
    }
  }

  def patch08Bowls(
    calculationDay: BigInt, targetDay: BigInt,
    initial: Vector[BigInt], drop: BigInt,
    stones: Vector[BigInt], step: Int, rank1: Int
  ): Patch08BowlReport = {
    val ctx = bootstrap(calculationDay, targetDay)
    ctx.bowlInput = Some(initial)
    ctx.bowlDropInput = Some(drop)
    ctx.bowlStonesInput = Some(stones)
    ctx.bowlStepInput = Some(step)
    ctx.bowlRankInput = Some(rank1)
    ctx.phase = "DISCOVERY_08_BOWL_ALIAS"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery08Ready(ctx)
      ctx.phase = "PATCH_08_BOWL_FREEZE"
      dispatcher.dispatch(ctx)
      validation.requirePatch08Ready(ctx)
      Patch08BowlReport(
        ctx.calculationDay,ctx.targetDay,ctx.bowlInput.get,
        ctx.bowlDropInput.get,ctx.bowlStonesInput.get,
        ctx.bowlStepInput.get,ctx.bowlRankInput.get,
        ctx.legacyBowlOrderOutput.get,ctx.legacyBowlPoursOutput.get,
        ctx.legacyBowlOutput.get,ctx.patchedBowlOutput.get,
        ctx.patch08Applied,ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("patch08",error)
    }
  }


  def discover09Vault(
    calculationDay: BigInt, targetDay: BigInt,
    bowlsAfterDrops: Vector[BigInt]
  ): Discovery09VaultReport = {
    val ctx = bootstrap(calculationDay,targetDay)
    ctx.postStirInput = Some(bowlsAfterDrops)
    ctx.phase = "DISCOVERY_09_VAULT"
    try {
      dispatcher.dispatch(ctx)
      validation.requireDiscovery09Ready(ctx)
      Discovery09VaultReport(
        ctx.calculationDay,ctx.targetDay,ctx.postStirInput.get,
        ctx.legacyVaultRounds.get,ctx.legacyVaultOutput.get,
        ctx.phase,ctx.status,ctx.branchTrace.toVector
      )
    } catch {
      case error: Throwable => throw BaseErrorWrapper.wrap("discovery09",error)
    }
  }

  def metricsSnapshot: Map[String, BigInt] = metrics.snapshot
}
