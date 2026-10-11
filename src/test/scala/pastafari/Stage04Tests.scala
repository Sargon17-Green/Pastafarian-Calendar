package pastafari

import pastafari.monster.{
  BaseMetricsShell, BaseMonsterContext, BaseMonsterManager, BaseValidationManager,
  Discovery02DayTagHandler, LegacyDayTagAdapter
}
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._

/**
 * DISCOVERY 02: dodici controlli ordinari PASS e cinque confronti:
 * due PASS prima della Fondazione; tre FAIL intenzionali da Fondazione.
 */
object Stage04Tests {
  private val F = NormativeOracle.FoundationDay
  private var passed = 0
  private var failed = 0

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

  private def truth(cond: Boolean, label: String): Unit =
    if (!cond) throw new AssertionError(label)

  private def expectIllegal(label: String)(body: => Unit): Unit = {
    var thrown = false
    try body catch { case _: IllegalStateException => thrown = true }
    truth(thrown, label)
  }

  private def projectRoot(): Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null) p = p.getParent
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del progetto non trovata.")
    p
  }

  def main(args: Array[String]): Unit = {
    check("formula legacy conservata ai cinque bordi") {
      equal(LegacyDayTagAdapter.oldDayTag(F), BigInt(0), "Fondazione")
      equal(LegacyDayTagAdapter.oldDayTag(F-1), BigInt(2), "F-1")
      equal(LegacyDayTagAdapter.oldDayTag(F+1), BigInt(2), "F+1")
      equal(LegacyDayTagAdapter.oldDayTag(F-2), BigInt(4), "F-2")
      equal(LegacyDayTagAdapter.oldDayTag(F+2), BigInt(4), "F+2")
    }

    check("collisione simmetrica del tag antico") {
      Vector[BigInt](1, 2, 3, 10, 777, 2000000000L).foreach { d =>
        equal(LegacyDayTagAdapter.oldDayTag(F-d), LegacyDayTagAdapter.oldDayTag(F+d),
          "Distanza " + d)
      }
    }

    check("dominio legacy pari e non negativo") {
      for (d <- -256 to 256) {
        val tag = LegacyDayTagAdapter.oldDayTag(F+BigInt(d))
        truth(tag >= 0 && tag % 2 == 0, "Tag illegale")
      }
    }

    check("monotonia rispetto alla distanza assoluta") {
      for (d <- 0 to 128) {
        equal(LegacyDayTagAdapter.oldDayTag(F+BigInt(d)), BigInt(2)*d, "Positivo")
        equal(LegacyDayTagAdapter.oldDayTag(F-BigInt(d)), BigInt(2)*d, "Negativo")
      }
    }

    check("interi arbitrari oltre 256 bit") {
      val big = (BigInt(1) << 8192) + 73
      equal(LegacyDayTagAdapter.oldDayTag(F+big), 2*big, "Futuro enorme")
      equal(LegacyDayTagAdapter.oldDayTag(F-big), 2*big, "Passato enorme")
    }

    check("percorso manager dispatcher handler realmente eseguito") {
      val manager = new BaseMonsterManager
      val r = manager.discover02DayTag(100, 200, F+2)
      equal(r.queriedDay, F+2, "Giorno")
      equal(r.legacyTag, BigInt(4), "Output antico")
      equal(r.phase, "DISCOVERY_02_DAY_TAG", "Fase")
      equal(r.status, "LEGACY_DAY_TAG_READY", "Stato")
      equal(r.trace, Vector("BOOT", "DISCOVERY_02_DAY_TAG"), "Traccia")
      equal(manager.metricsSnapshot("discovery02.daytag.calls"), BigInt(1), "Contatore reale")
    }

    check("invocazioni isolate e snapshot stabili") {
      val manager = new BaseMonsterManager
      val a = manager.discover02DayTag(1, 2, F)
      val b = manager.discover02DayTag(-100, -200, F-1000)
      equal(a.legacyTag, BigInt(0), "Primo")
      equal(b.legacyTag, BigInt(2000), "Secondo")
      equal(a.queriedDay, F, "Snapshot")
      equal(manager.metricsSnapshot("base.bootstrap.calls"), BigInt(2), "Bootstrap")
      equal(manager.metricsSnapshot("discovery02.daytag.calls"), BigInt(2), "Invocazioni")
    }

    check("il giorno chiesto resta distinto dai due giorni di lavoro") {
      val manager = new BaseMonsterManager
      val a = manager.discover02DayTag(1, 2, F+1)
      val b = manager.discover02DayTag(BigInt(1)<<2048, -(BigInt(1)<<2048), F+1)
      equal(a.legacyTag, b.legacyTag, "Indipendenza")
    }

    check("precondizioni dello stato non aggirabili") {
      val validator = new BaseValidationManager
      val ctx = BaseMonsterContext(1, 2)
      ctx.phase = "DISCOVERY_02_DAY_TAG"
      ctx.status = "LEGACY_DAY_TAG_READY"
      expectIllegal("Output assente") { validator.requireDiscovery02Ready(ctx) }
      val handler = new Discovery02DayTagHandler(new BaseMetricsShell)
      expectIllegal("Bootstrap richiesto") { handler.handle(ctx) }
      val ctx2 = BaseMonsterContext(1, 2)
      ctx2.status = "BOOTSTRAPPED"
      ctx2.branchTrace.append("BOOT")
      expectIllegal("Input richiesto") { handler.handle(ctx2) }
    }

    check("la PATCH 01 precedente resta normativa") {
      val manager = new BaseMonsterManager
      val p = manager.patch01Save(F, F, NormativeOracle.M)
      equal(p.legacyOutput, BigInt(0), "Scar di SAVE")
      equal(p.patchedOutput, NormativeOracle.M, "PATCH 01")
      equal(manager.discover01Remainder(F, F, NormativeOracle.M).legacyOutput,
        BigInt(0), "Diagnostico vecchio")
    }

    check("nessun oracle in produzione e nessuna PATCH 02") {
      val stream = Files.walk(projectRoot().resolve("src/main/scala"))
      val code = try stream.iterator().asScala
        .filter(p => Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p => new String(Files.readAllBytes(p), StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!code.contains("NormativeOracle"), "Oracle vietato in produzione")
      truth(!code.contains("oldDayTagPatch"), "PATCH 02 non deve esistere")
      truth(code.contains("BigInt(2) * (day - FoundationDayOld).abs"), "Formula legacy")
    }

    check("metadati dello stadio dichiarano EXPECTED_RED") {
      val text = new String(Files.readAllBytes(projectRoot().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(text.contains("CURRENT_STAGE=4"), "Fase")
      truth(text.contains("CURRENT_KIND=DISCOVERY"), "Tipologia")
      truth(text.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"), "Rosso atteso")
      truth(text.contains("LAST_COMPLETED_STAGE=3"), "Stadio 3 completo")
    }

    val manager = new BaseMonsterManager
    Vector(
      ("Fondazione-2", F-2),
      ("Fondazione-1", F-1),
      ("Fondazione", F),
      ("Fondazione+1", F+1),
      ("Fondazione+2", F+2)
    ).foreach { case (name, day) =>
      check("equivalenza normativa giorno " + name) {
        equal(manager.discover02DayTag(F, F, day).legacyTag,
          NormativeOracle.dayCount(day), "Divergenza storica " + name)
      }
    }

    println("\nRISULTATO STADIO 4: " + passed + " PASS, " + failed + " FAIL")
    if (failed != 0) sys.exit(1)
  }
}
