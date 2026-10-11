package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 06: 20 prove verdi e tre confronti normativi volutamente rossi. */
object Stage12Tests {
  private var passed = 0
  private var failed = 0
  private val M = NormativeOracle.M
  private val StoneSample = Vector[BigInt](19, 23, 29, 31, 37)
  private val Rules = Vector(
    LegacyGrindRule(3, 5, 7, 11, 0),
    LegacyGrindRule(5, 7, 11, 13, 1),
    LegacyGrindRule(7, 11, 13, 17, 2),
    LegacyGrindRule(11, 13, 17, 19, 3),
    LegacyGrindRule(13, 17, 19, 23, 4),
    LegacyGrindRule(17, 19, 23, 29, 0),
    LegacyGrindRule(19, 23, 29, 31, 1),
    LegacyGrindRule(23, 29, 31, 37, 2),
    LegacyGrindRule(29, 31, 37, 41, 3),
    LegacyGrindRule(31, 37, 41, 43, 4),
    LegacyGrindRule(37, 41, 43, 47, 0)
  )

  private def check(name: String)(body: => Unit): Unit = {
    try {
      body
      passed += 1
      println("PASS — " + name)
    } catch {
      case error: Throwable =>
        failed += 1
        println("FAIL — " + name + " — " + error.getMessage)
        error.printStackTrace(System.out)
    }
  }
  private def eqv[A](actual: A, expected: A, name: String): Unit =
    if (actual != expected) throw new AssertionError(
      name + ": atteso=" + expected + ", ottenuto=" + actual)
  private def truth(ok: Boolean, name: String): Unit =
    if (!ok) throw new AssertionError(name)
  private def rejectsArgument(name: String)(body: => Unit): Unit = {
    var rejected = false
    try body catch { case _: IllegalArgumentException => rejected = true }
    truth(rejected, name)
  }
  private def rejectsState(name: String)(body: => Unit): Unit = {
    var rejected = false
    try body catch { case _: IllegalStateException => rejected = true }
    truth(rejected, name)
  }
  private def correctGrind(step: Int, old: BigInt, p1: BigInt,
                           p3: BigInt, p7: BigInt, stones: Vector[BigInt]): BigInt = {
    val rule = Rules(step - 1)
    NormativeOracle.save(old * old + rule.a * old + rule.b * p1 +
      rule.c * p3 + rule.d * p7 + stones(rule.stoneKind))
  }
  private def root(): Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null)
      p = p.getParent
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del progetto non trovata")
    p
  }

  def main(args: Array[String]): Unit = {
    check("il catalogo legacy include dodici record, sentinel più undici macinature") {
      eqv(LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL.length, 12, "Dimensione")
      eqv(Rules.length, 11, "Contratto dei passaggi visibili")
    }

    check("il sentinel è un vero record neutro all'indice zero") {
      eqv(LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL.head,
        LegacyGrindRule(0, 0, 0, 0, 0), "Sentinel")
      eqv(LegacyGrindTableAdapter.legacyGrindRule(1),
        LegacyGrindRule(0, 0, 0, 0, 0), "Prima lettura storica")
    }

    check("la riga normativa numero uno è fisicamente nell'indice uno") {
      eqv(LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL(1), Rules.head,
        "Primo record normativo non perso")
    }

    check("la riga normativa undici esiste all'indice undici ma non viene letta") {
      eqv(LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL(11), Rules.last,
        "Ultima riga normativa")
      eqv(LegacyGrindTableAdapter.legacyGrindRule(11), Rules(9),
        "Ultimo record letto")
    }

    check("tutte le undici letture storiche sono esattamente spostate di una riga") {
      (1 to 11).foreach { step =>
        eqv(LegacyGrindTableAdapter.legacyGrindRule(step),
          LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL(step - 1),
          "Indice legacy " + step)
      }
    }

    check("tutti i coefficienti reali restano copiati nel catalogo senza distorsione") {
      eqv(LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL.tail, Rules,
        "Regole normative presenti ma indicizzate male")
    }

    check("la prima macinatura legacy produce 68 con i dati di prova") {
      eqv(LegacyGrindTableAdapter.legacyGrind(1, 7, 11, 13, 17, StoneSample),
        BigInt(68), "7 al quadrato più la pietra 19")
    }

    check("il primo calcolo normativo con gli stessi dati produce 422") {
      eqv(correctGrind(1, 7, 11, 13, 17, StoneSample),
        BigInt(422), "Coefficenti 3 5 7 11")
    }

    check("le altre dieci macinature usano sempre una regola precedente") {
      (2 to 11).foreach { step =>
        eqv(LegacyGrindTableAdapter.legacyGrindRule(step), Rules(step - 2),
          "Slittamento del passo " + step)
      }
    }

    check("tutti gli undici output legacy rispettano SAVE anche senza equivalenza") {
      for (step <- 1 to 11; i <- -10 to 10) {
        val result = LegacyGrindTableAdapter.legacyGrind(
          step, BigInt(i), BigInt(2*i), BigInt(3*i), BigInt(5*i), StoneSample)
        truth(result >= 1 && result <= M, "Residuo fuori limite")
      }
    }

    check("il calcolo legacy richiama SAVE positivo su multipli del modulo") {
      val r = LegacyGrindTableAdapter.legacyGrind(1, 0, 0, 0, 0,
        Vector[BigInt](M, 1, 1, 1, 1))
      eqv(r, M, "Valore zero rappresentato da M")
    }

    check("aritmetica BigInt signed senza overflow oltre sedicimila bit") {
      val huge = (BigInt(1) << 16384) + 777
      for (step <- 1 to 11) {
        val rule = LegacyGrindTableAdapter.legacyGrindRule(step)
        val expected = NormativeOracle.save(
          huge * huge + rule.a * huge + rule.b * (-huge) +
            rule.c * (huge + 1) + rule.d * (-huge - 2) +
            Vector[BigInt](1, 2, 3, 4, 5)(rule.stoneKind))
        eqv(LegacyGrindTableAdapter.legacyGrind(step, huge, -huge,
          huge + 1, -huge - 2, Vector[BigInt](1, 2, 3, 4, 5)),
          expected, "BigInt macinatura " + step)
      }
    }

    check("campionamento deterministico di 256 macinature storiche") {
      val rng = new Random(20261011L)
      (1 to 256).foreach { n =>
        val step = rng.nextInt(11) + 1
        val old = (BigInt(1) << (rng.nextInt(2048) + 1)) + n
        val p1 = -old + n
        val p3 = old - 2 * n
        val p7 = -old - 3 * n
        val rule = LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL(step - 1)
        val expected = NormativeOracle.save(old * old + rule.a * old + rule.b * p1 +
          rule.c * p3 + rule.d * p7 + StoneSample(rule.stoneKind))
        eqv(LegacyGrindTableAdapter.legacyGrind(step, old, p1, p3, p7, StoneSample),
          expected, "Campione " + n)
      }
    }

    check("il helper storico rifiuta gli indici al di fuori di uno a undici") {
      Vector(-100, -1, 0, 12, 100).foreach { step =>
        rejectsArgument("Passo " + step) {
          LegacyGrindTableAdapter.legacyGrindRule(step)
        }
      }
    }

    check("il helper storico rifiuta una riga di pietre malformata") {
      rejectsArgument("Quattro pietre") {
        LegacyGrindTableAdapter.legacyGrind(1, 7, 11, 13, 17, StoneSample.take(4))
      }
      rejectsArgument("Sei pietre") {
        LegacyGrindTableAdapter.legacyGrind(11, 7, 11, 13, 17, StoneSample :+ BigInt(41))
      }
    }

    check("manager e dispatcher attraversano realmente la DISCOVERY 06") {
      val manager = new BaseMonsterManager
      val result = manager.discover06Grind(123, -456, 6, 7, 11, 13, 17, StoneSample)
      eqv(result.calculationDay, BigInt(123), "Calculation day")
      eqv(result.targetDay, BigInt(-456), "Target day")
      eqv(result.step, 6, "Numero della macinatura")
      eqv(result.legacyRule, Rules(4), "Regola precedente")
      eqv(result.legacyValue,
        LegacyGrindTableAdapter.legacyGrind(6, 7, 11, 13, 17, StoneSample), "Risultato reale")
      eqv(result.stones, StoneSample, "Snapshot delle pietre")
      eqv(result.trace, Vector("BOOT", "DISCOVERY_06_GRIND"), "Traccia")
      eqv(result.status, "LEGACY_GRIND_READY", "Stato")
      eqv(manager.metricsSnapshot("base.bootstrap.calls"), BigInt(1), "Bootstrap")
      eqv(manager.metricsSnapshot("discovery06.grind.calls"), BigInt(1), "Handler")
    }

    check("report indipendenti fra chiamate, metrica solo osservativa") {
      val manager = new BaseMonsterManager
      val a = manager.discover06Grind(1, 2, 1, 7, 11, 13, 17, StoneSample)
      val b = manager.discover06Grind(3, 4, 11, 7, 11, 13, 17, StoneSample)
      eqv(a.legacyValue, BigInt(68), "Primo snapshot")
      eqv(b.legacyRule, Rules(9), "Ultimo snapshot")
      eqv(a.calculationDay, BigInt(1), "Input A")
      eqv(b.calculationDay, BigInt(3), "Input B")
      eqv(manager.metricsSnapshot("discovery06.grind.calls"), BigInt(2), "Metriche")
    }

    check("validatore rifiuta output assente, trace falsa e catalogo alterato") {
      val v = new BaseValidationManager
      val c = BaseMonsterContext(1, 2)
      c.phase = "DISCOVERY_06_GRIND"
      c.status = "LEGACY_GRIND_READY"
      rejectsState("Output assente") { v.requireDiscovery06Ready(c) }
      c.grindStepInput = Some(1)
      c.grindValueInput = Some(7)
      c.grindPrev1Input = Some(11)
      c.grindPrev3Input = Some(13)
      c.grindPrev7Input = Some(17)
      c.grindStonesInput = Some(StoneSample)
      c.legacyGrindRuleOutput = Some(LegacyGrindTableAdapter.legacyGrindRule(1))
      c.legacyGrindOutput = Some(BigInt(68))
      rejectsState("Traccia falsa") { v.requireDiscovery06Ready(c) }
      c.branchTrace.appendAll(Seq("BOOT", "DISCOVERY_06_GRIND"))
      v.requireDiscovery06Ready(c)
      c.legacyGrindRuleOutput = Some(Rules.head)
      rejectsState("Catalogo manomesso") { v.requireDiscovery06Ready(c) }
    }

    check("handler non ammette bypass del Bootstrap o doppia esecuzione") {
      val h = new Discovery06GrindHandler(new BaseMetricsShell)
      val c = BaseMonsterContext(1, 2)
      rejectsState("Bootstrap non eseguito") { h.handle(c) }
      c.status = "BOOTSTRAPPED"
      c.branchTrace.append("BOOT")
      c.grindStepInput = Some(1)
      c.grindValueInput = Some(7)
      c.grindPrev1Input = Some(11)
      c.grindPrev3Input = Some(13)
      c.grindPrev7Input = Some(17)
      c.grindStonesInput = Some(StoneSample)
      h.handle(c)
      rejectsState("Seconda esecuzione") { h.handle(c) }
      eqv(c.legacyGrindOutput, Some(BigInt(68)), "Output inalterato")
    }

    check("PATCH 01–05 restano percorribili e normative") {
      val m = new BaseMonsterManager
      val foundation = NormativeOracle.FoundationDay
      eqv(m.patch01Save(0, 0, M).patchedOutput, M, "SAVE")
      eqv(m.patch02DayTag(foundation, foundation, foundation).patchedTag,
        BigInt(1), "Etichetta del giorno")
      eqv(m.patch03Distance(foundation, foundation).patchedDistance,
        BigInt(1), "Distanza")
      eqv(m.patch04Stones(0, 0).patchedStoneRows, NormativeOracle.Stones,
        "Pietre di tutte le righe")
      val hidden = Vector[BigInt](101, 202, 303, 404, 505, 606, 707)
      val legacy = m.discover05Prior(0, 0, hidden, Vector.empty, 1, 7).legacyValue
      val patched = m.patch05Prior(0, 0, hidden, Vector.empty, 1, 7).patchedValue
      eqv(legacy, BigInt(606), "Lettura legacy precedente")
      eqv(patched, BigInt(707), "Lettura patched precedente")
    }

    check("nessun oracolo in produzione e nessuna PATCH 06 anticipata") {
      val stream = Files.walk(root().resolve("src/main/scala"))
      val sources = try stream.iterator().asScala
        .filter(p => Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p => new String(Files.readAllBytes(p), StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"), "Oracolo test-only")
      truth(sources.contains("GRIND_TABLE_WITH_SENTINEL"), "Cicatrice assente")
      truth(!sources.contains("grindPatch"), "PATCH 06 anticipata")
    }

    check("metadati dello stadio 12 dichiarano discovery intenzionalmente RED") {
      val st = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=12"), "Stadio")
      truth(st.contains("CURRENT_KIND=DISCOVERY"), "Tipo")
      truth(st.contains("CURRENT_PATCH=05"), "Patch precedente")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"), "Rosso atteso")
      val completed = st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("LAST_COMPLETED_STAGE assente"))
      truth(completed == 11 || completed == 12, "Nessuna certificazione prematura")
    }

    val manager = new BaseMonsterManager
    Vector(("passo primo", 1), ("passo sesto", 6), ("passo undicesimo", 11))
      .foreach { case (label, step) =>
        check("equivalenza normativa macinatura " + label) {
          val actual = manager.discover06Grind(
            0, 0, step, 7, 11, 13, 17, StoneSample).legacyValue
          val expected = correctGrind(step, 7, 11, 13, 17, StoneSample)
          eqv(actual, expected, "Sentinel sposta il catalogo: " + label)
        }
      }

    println("\nRISULTATO STADIO 12: " + passed + " PASS, " + failed + " FAIL")
    if (failed != 0) sys.exit(1)
  }
}
