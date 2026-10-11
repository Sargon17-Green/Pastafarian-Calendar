package pastafari

import pastafari.monster.{
  BaseMetricsShell, BaseMonsterContext, BaseMonsterManager, BaseValidationManager,
  Discovery03DistanceHandler, LegacyDistanceAdapter
}
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 03: esattamente tre divergenze intenzionali del conteggio inclusivo. */
object Stage06Tests {
  private var passed = 0
  private var failed = 0
  private val F = NormativeOracle.FoundationDay

  private def check(name: String)(body: => Unit): Unit = {
    try {
      body
      passed += 1
      println("PASS — " + name)
    } catch {
      case e: Throwable =>
        failed += 1
        println("FAIL — " + name + " — " + e.getMessage)
        e.printStackTrace(System.out)
    }
  }

  private def equal[A](actual: A, expected: A, label: String): Unit =
    if (actual != expected)
      throw new AssertionError(label + ": atteso=" + expected + ", ottenuto=" + actual)

  private def truth(value: Boolean, label: String): Unit =
    if (!value) throw new AssertionError(label)

  private def reject(label: String)(body: => Unit): Unit = {
    var thrown = false
    try body catch { case _: IllegalStateException => thrown = true }
    truth(thrown, label)
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
    check("calcolo legacy conserva zero nello stesso giorno") {
      Vector[BigInt](F, F-1, F+1, 0, -1, BigInt(1)<<4096).foreach { day =>
        equal(LegacyDistanceAdapter.oldDistance(day, day), BigInt(0),
          "Intervallo vuoto legacy")
      }
    }

    check("il legacy conta intervalli e non entrambi gli estremi") {
      val values = Vector[BigInt](-21, -2, -1, 0, 1, 2, 21)
      values.foreach { delta =>
        equal(LegacyDistanceAdapter.oldDistance(F, F+delta), delta.abs, "Distanza " + delta)
      }
    }

    check("il legacy è simmetrico per qualunque ordine temporale") {
      for (a <- -40 to 40; b <- -40 to 40) {
        equal(LegacyDistanceAdapter.oldDistance(F+a, F+b),
          LegacyDistanceAdapter.oldDistance(F+b, F+a), "Simmetria")
      }
    }

    check("il legacy è non negativo e vale zero solo per input uguali") {
      for (a <- -50 to 50; b <- -50 to 50) {
        val d = LegacyDistanceAdapter.oldDistance(BigInt(a), BigInt(b))
        truth(d >= 0, "Distanza negativa")
        equal(d == 0, a == b, "Coincidenza degli input")
      }
    }

    check("invarianza per traslazione dei due giorni") {
      val hugeShift = (BigInt(1)<<8192)+17
      for (a <- -20 to 20; b <- -20 to 20) {
        val original = LegacyDistanceAdapter.oldDistance(BigInt(a), BigInt(b))
        equal(LegacyDistanceAdapter.oldDistance(BigInt(a)+hugeShift, BigInt(b)+hugeShift),
          original, "Traslazione gigante")
      }
    }

    check("additività storica su tre giorni ordinati") {
      for (a <- -12 to 12; b <- a to 12; c <- b to 12) {
        val left = LegacyDistanceAdapter.oldDistance(a, b)
        val right = LegacyDistanceAdapter.oldDistance(b, c)
        equal(left+right, LegacyDistanceAdapter.oldDistance(a, c), "Distanza a tratti")
      }
    }

    check("BigInt oltre 256 bit senza overflow o conversione a Long") {
      Vector(257, 1024, 4096, 16384).foreach { bits =>
        val huge = (BigInt(1)<<bits)+991
        equal(LegacyDistanceAdapter.oldDistance(-huge, huge), BigInt(2)*huge, "Grande")
        equal(LegacyDistanceAdapter.oldDistance(huge, -huge), BigInt(2)*huge, "Inverso")
      }
    }

    check("1024 coppie deterministiche nello spazio arbitrario") {
      val r = new Random(20261011L)
      (1 to 1024).foreach { i =>
        val a = (BigInt(1)<<(r.nextInt(4096)+1)) + BigInt(r.nextLong())
        val b = (BigInt(1)<<(r.nextInt(4096)+1)) + BigInt(r.nextLong())
        val c = if (i%2 == 0) a else -a
        val d = if (i%3 == 0) b else -b
        equal(LegacyDistanceAdapter.oldDistance(c, d), (d-c).abs, "Campione "+i)
      }
    }

    check("esecuzione effettiva manager dispatcher handler con traccia") {
      val manager = new BaseMonsterManager
      val report = manager.discover03Distance(F, F+10)
      equal(report.calculationDay, F, "Giorno del calcolo")
      equal(report.targetDay, F+10, "Giorno chiesto")
      equal(report.legacyDistance, BigInt(10), "Il difetto storico resta")
      equal(report.phase, "DISCOVERY_03_DISTANCE", "Fase")
      equal(report.status, "LEGACY_DISTANCE_READY", "Stato")
      equal(report.trace, Vector("BOOT", "DISCOVERY_03_DISTANCE"), "Traccia")
      equal(manager.metricsSnapshot("base.bootstrap.calls"), BigInt(1), "Bootstrap")
      equal(manager.metricsSnapshot("discovery03.distance.calls"), BigInt(1), "Handler reale")
    }

    check("cambiando l'ordine dei giorni cambia solo lo snapshot input") {
      val manager = new BaseMonsterManager
      val forward = manager.discover03Distance(-1000, 250)
      val reverse = manager.discover03Distance(250, -1000)
      equal(forward.legacyDistance, reverse.legacyDistance, "Distanza")
      equal(forward.calculationDay, BigInt(-1000), "Ordine originale")
      equal(reverse.calculationDay, BigInt(250), "Ordine invertito")
      equal(forward.trace, reverse.trace, "Percorso identico")
    }

    check("isolamento di invocazioni, report immutabili e metriche solo osservative") {
      val manager = new BaseMonsterManager
      val a = manager.discover03Distance(77, 77)
      val b = manager.discover03Distance(77, 80)
      equal(a.legacyDistance, BigInt(0), "Primo snapshot")
      equal(b.legacyDistance, BigInt(3), "Secondo snapshot")
      equal(a.targetDay, BigInt(77), "Snapshot inalterato")
      equal(manager.metricsSnapshot("discovery03.distance.calls"), BigInt(2), "Metriche")
    }

    check("readiness e handler rifiutano contesti non validi") {
      val validation = new BaseValidationManager
      val incomplete = BaseMonsterContext(1,2)
      incomplete.phase = "DISCOVERY_03_DISTANCE"
      incomplete.status = "LEGACY_DISTANCE_READY"
      reject("Output assente") { validation.requireDiscovery03Ready(incomplete) }
      val handler = new Discovery03DistanceHandler(new BaseMetricsShell)
      reject("Bootstrap assente") { handler.handle(incomplete) }
      val forged = BaseMonsterContext(1,2)
      forged.status = "BOOTSTRAPPED"
      forged.branchTrace.append("BOOT")
      forged.legacyDistanceOutput = Some(1)
      reject("Output legacy già calcolato") { handler.handle(forged) }
    }

    check("le patch 01 e 02 restano normative in produzione") {
      val manager = new BaseMonsterManager
      val modulo = NormativeOracle.M
      equal(manager.patch01Save(0,0,modulo).patchedOutput,modulo,"SAVE corretto")
      equal(manager.patch01Save(0,0,modulo).legacyOutput,BigInt(0),"Scar SAVE")
      equal(manager.patch02DayTag(0,0,F).patchedTag,BigInt(1),"Fondazione corretta")
      equal(manager.discover02DayTag(0,0,F).legacyTag,BigInt(0),"Scar day tag")
    }

    check("nessun oracolo di test e nessuna correzione dello stadio 7") {
      val stream = Files.walk(root().resolve("src/main/scala"))
      val code = try stream.iterator().asScala
        .filter(p => Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p => new String(Files.readAllBytes(p), StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!code.contains("NormativeOracle"), "Oracolo non ammesso in produzione")
      truth(code.contains("(targetDay - calculationDay).abs"), "Formula legacy mancante")
      val metadata = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = metadata.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      if (currentStage < 7)
        truth(!code.contains("distancePatch"), "PATCH 03 prematura")
      else
        truth(code.contains("distancePatch"), "PATCH 03 deve essere presente")
    }

    check("metadati dello stadio 6 dichiarano EXPECTED_RED") {
      val stage = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = stage.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      truth(currentStage >= 6, "La discovery deve restare disponibile")
      if (currentStage == 6) {
        truth(stage.contains("CURRENT_KIND=DISCOVERY"), "Tipo inesatto")
        truth(stage.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"), "Discovery RED")
      }
      val last = stage.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("LAST_COMPLETED_STAGE mancante"))
      truth(last >= 5 && last <= currentStage, "La storia non deve anticipare lo stadio corrente")
    }

    val manager = new BaseMonsterManager
    val enormous = (BigInt(1)<<16384)+123456789
    Vector(
      ("stesso giorno", F, F),
      ("giorni contigui", F, F+1),
      ("intervallo enorme", -enormous, enormous)
    ).foreach { case (name, c, t) =>
      check("equivalenza normativa distanza " + name) {
        val actual = manager.discover03Distance(c,t).legacyDistance
        val expected = NormativeOracle.workCounts(c,t).distance
        equal(actual, expected, "Scarto storico "+name)
      }
    }
    println("\nRISULTATO STADIO 6: "+passed+" PASS, "+failed+" FAIL")
    if (failed != 0) sys.exit(1)
  }
}
