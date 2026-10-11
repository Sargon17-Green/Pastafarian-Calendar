package pastafari

import pastafari.monster.{
  BaseMetricsShell, BaseMonsterContext, BaseMonsterDispatcher, BaseMonsterManager,
  BaseBootstrapHandler, BaseValidationManager, LegacyArithmeticAdapter,
  Patch01SaveWrapper, Patch01SaveHandler
}
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

object Stage03Tests {
  private val M: BigInt = NormativeOracle.M
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

  private def expectThrows[E <: Throwable: reflect.ClassTag](label: String)(work: => Unit): Unit = {
    val wanted = implicitly[reflect.ClassTag[E]].runtimeClass
    var seen = false
    try work catch {
      case e: Throwable =>
        if (!wanted.isInstance(e)) throw new AssertionError(label + ": tipo di eccezione inatteso", e)
        seen = true
    }
    truth(seen, label + ": eccezione assente")
  }

  private def projectRoot(): Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null) p = p.getParent
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del progetto non trovata.")
    p
  }

  def main(args: Array[String]): Unit = {
    check("cicatrice legacy preservata sui bordi") {
      equal(LegacyArithmeticAdapter.oldRemainder(M), BigInt(0), "oldRemainder(M)")
      equal(LegacyArithmeticAdapter.oldRemainder(2*M), BigInt(0), "oldRemainder(2M)")
      equal(LegacyArithmeticAdapter.oldRemainder(-M), BigInt(0), "oldRemainder(-M)")
      equal(LegacyArithmeticAdapter.oldRemainder(M+1), BigInt(1), "oldRemainder(M+1)")
      equal(LegacyArithmeticAdapter.oldRemainder(-1), M-1, "oldRemainder(-1)")
    }

    check("patch esatta per zero e multipli positivi e negativi") {
      val multiples = Vector(-7, -3, -2, -1, 0, 1, 2, 3, 7, 101)
      multiples.foreach { k =>
        val x = M * k
        equal(Patch01SaveWrapper.savePatch(x), M, "SAVE(" + k + "M)")
        equal(LegacyArithmeticAdapter.oldRemainder(x), BigInt(0),
          "Residuo legacy per " + k + "M")
      }
    }

    check("patch non tocca residui non nulli") {
      Vector[BigInt](1, -1, M-1, M+1, -M-1, 2*M-1, 2*M+1).foreach { x =>
        val legacy = LegacyArithmeticAdapter.oldRemainder(x)
        truth(legacy != 0, "Caso costruito con residuo zero")
        equal(Patch01SaveWrapper.savePatch(x), legacy, "Residuo non nullo " + x)
      }
    }

    check("equivalenza normativa esaustiva su finestre cicliche") {
      for (k <- -125 to 125; offset <- -3 to 3) {
        val x = M * k + offset
        equal(Patch01SaveWrapper.savePatch(x), NormativeOracle.save(x), "Finestra " + k + ":" + offset)
      }
    }

    check("equivalenza normativa con interi oltre 256 bit") {
      val huge = (BigInt(1) << 8192) + 123456789
      val values = Vector(huge, -huge, huge*M, -huge*M, huge*M-1, -huge*M+1,
        M * (BigInt(1) << 4096), -M * (BigInt(1) << 4096))
      values.foreach { x =>
        equal(Patch01SaveWrapper.savePatch(x), NormativeOracle.save(x), "Grande intero")
      }
    }

    check("campionamento deterministico di interi arbitrari") {
      val random = new Random(20261011L)
      (1 to 512).foreach { i =>
        val bytes = Array.ofDim[Byte](1 + random.nextInt(256))
        random.nextBytes(bytes)
        val x = BigInt(bytes) + M * BigInt(i - 257)
        equal(Patch01SaveWrapper.savePatch(x), NormativeOracle.save(x), "Campione " + i)
      }
    }

    check("percorso di produzione attraversa davvero l'adattatore legacy") {
      val manager = new BaseMonsterManager
      val result = manager.patch01Save(10, 20, M)
      equal(result.input, M, "Input")
      equal(result.legacyOutput, BigInt(0), "Lettura legacy non corretta")
      equal(result.patchedOutput, M, "Valore corretto")
      equal(result.trace, Vector("BOOT", "DISCOVERY_01_REMAINDER", "PATCH_01_SAVE"),
        "Traccia effettiva")
      equal(result.phase, "PATCH_01_SAVE", "Fase")
      equal(result.status, "PATCH_01_READY", "Stato")
      truth(result.patchApplied, "Flag di patch")
      equal(manager.metricsSnapshot.getOrElse("base.bootstrap.calls", BigInt(0)), BigInt(1),
        "Bootstrap")
      equal(manager.metricsSnapshot.getOrElse("discovery01.remainder.calls", BigInt(0)),
        BigInt(1), "Handler legacy chiamato")
      equal(manager.metricsSnapshot.getOrElse("patch01.save.calls", BigInt(0)),
        BigInt(1), "Handler patch chiamato")
    }

    check("diagnostica storica resta eseguibile dopo PATCH 01") {
      val manager = new BaseMonsterManager
      val diagnostic = manager.discover01Remainder(3, 2, 3*M)
      val patched = manager.patch01Save(3, 2, 3*M)
      equal(diagnostic.legacyOutput, BigInt(0), "Diagnostica legacy")
      equal(diagnostic.trace, Vector("BOOT", "DISCOVERY_01_REMAINDER"), "Traccia storica")
      equal(patched.legacyOutput, diagnostic.legacyOutput, "La cicatrice è la stessa")
      equal(patched.patchedOutput, M, "Patch in produzione")
      equal(manager.metricsSnapshot("discovery01.remainder.calls"), BigInt(2),
        "Entrambe le vie esercitano legacy")
    }

    check("indipendenza tra invocazioni e snapshot stabili") {
      val manager = new BaseMonsterManager
      val a = manager.patch01Save(-100, 100, M)
      val b = manager.patch01Save(100, -100, M+1)
      equal(a.patchedOutput, M, "Prima invocazione")
      equal(b.patchedOutput, BigInt(1), "Seconda invocazione")
      equal(a.input, M, "Primo snapshot immutato")
      equal(a.legacyOutput, BigInt(0), "Legacy primo snapshot immutato")
      equal(a.trace, b.trace, "Percorso deterministico")
      equal(manager.metricsSnapshot("patch01.save.calls"), BigInt(2), "Metrica")
    }

    check("controllo di readiness rifiuta stati falsificati") {
      val validator = new BaseValidationManager
      val incomplete = BaseMonsterContext(1, 1)
      incomplete.phase = "PATCH_01_SAVE"
      incomplete.status = "PATCH_01_READY"
      incomplete.patch01Applied = true
      expectThrows[IllegalStateException]("Manca la prova della fase legacy") {
        validator.requirePatch01Ready(incomplete)
      }
      val handler = new Patch01SaveHandler(new BaseMetricsShell)
      expectThrows[IllegalStateException]("Non si può saltare la discovery") {
        handler.handle(BaseMonsterContext(1, 1))
      }
    }

    check("invarianti dispatcher e flusso dei fallimenti") {
      val metrics = new BaseMetricsShell
      expectThrows[IllegalArgumentException]("Due handler per una fase") {
        new BaseMonsterDispatcher(Vector(new BaseBootstrapHandler(metrics),
          new BaseBootstrapHandler(metrics)))
      }
      expectThrows[IllegalStateException]("Fase senza handler") {
        new BaseMonsterDispatcher(Vector(new BaseBootstrapHandler(metrics)))
          .dispatch(BaseMonsterContext(1, 1, phase = "SCONOSCIUTA"))
      }
    }

    check("isolamento dell'oracolo e divieto delle patch future") {
      val stream = Files.walk(projectRoot().resolve("src/main/scala"))
      val content = try stream.iterator().asScala
        .filter(p => Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p => new String(Files.readAllBytes(p), StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!content.contains("NormativeOracle"), "Oracle test-only nel codice di produzione")
      truth(content.contains("LegacyArithmeticAdapter.oldRemainder(x)"),
        "Il wrapper deve eseguire il vero residuo legacy")
      val currentText = new String(Files.readAllBytes(projectRoot().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = currentText.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      if (currentStage < 4) {
        truth(!content.contains("oldDayTag"), "Nessun codice di DISCOVERY 02 prematuro")
      } else {
        truth(content.contains("oldDayTag"), "DISCOVERY 02 deve essere presente")
      }
      val status = new String(Files.readAllBytes(projectRoot().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(currentStage >= 3, "PATCH 01 richiede uno stadio almeno 3")
      if (currentStage == 3) {
        truth(status.contains("CURRENT_PATCH=01"), "Patch corrente dichiarata")
        truth(status.contains("EXPECTED_REPOSITORY_STATE=GREEN"), "Stadio PATCH verde")
      } else {
        truth(status.contains("LAST_COMPLETED_STAGE="), "La storia degli stadi deve essere preservata")
      }
    }

    println("\nRISULTATO STADIO 3: " + passed + " PASS, " + failed + " FAIL")
    if (failed != 0) sys.exit(1)
  }
}
