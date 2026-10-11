package pastafari

import pastafari.monster.{BaseMonsterManager, LegacyArithmeticAdapter}
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._

/**
 * DISCOVERY 01: il confronto con SAVE DEVE fallire su M, 2M e 3M.
 * Il processo termina con codice non nullo, per distinguere la discovery
 * storica dalla regressione corretta che sarà aggiunta nello stadio 3.
 */
object Stage02Tests {
  private var passed = 0
  private var failed = 0
  private val M = NormativeOracle.M

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

  private def projectRoot(): Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null) p = p.getParent
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del progetto non trovata.")
    p
  }

  def main(args: Array[String]): Unit = {
    check("dominio del residuo euclideo legacy") {
      val xs = Vector(BigInt(0), BigInt(1), BigInt(-1), M, 2*M, 3*M, M+1, -M, -M-1)
      xs.foreach { x =>
        val r = LegacyArithmeticAdapter.oldRemainder(x)
        truth(r >= 0 && r < M, "Residuo fuori dominio per " + x)
        truth((x-r) % M == 0, "Classe di congruenza errata per " + x)
      }
      equal(LegacyArithmeticAdapter.oldRemainder(2*M), BigInt(0), "Multiplo di M")
    }

    check("aritmetica oltre i 256 bit senza conversione a Long") {
      val huge = (BigInt(1) << 8192) + 123456789
      val xs = Vector(huge, -huge, huge * M, -huge * M)
      xs.foreach { x =>
        val r = LegacyArithmeticAdapter.oldRemainder(x)
        truth(r >= 0 && r < M && (x-r) % M == 0, "Residuo grande errato")
      }
    }

    check("percorso reale e isolamento dello stato per invocazione") {
      val manager = new BaseMonsterManager
      val a = manager.discover01Remainder(10, 20, M)
      val b = manager.discover01Remainder(30, 40, M+1)
      equal(a.input, M, "Operando prima invocazione")
      equal(b.input, M+1, "Operando seconda invocazione")
      equal(a.legacyOutput, BigInt(0), "Uscita legacy prima invocazione")
      equal(b.legacyOutput, BigInt(1), "Uscita legacy seconda invocazione")
      equal(a.trace, Vector("BOOT", "DISCOVERY_01_REMAINDER"), "Trace prima invocazione")
      equal(b.trace, Vector("BOOT", "DISCOVERY_01_REMAINDER"), "Trace seconda invocazione")
      equal(a.status, "LEGACY_REMAINDER_READY", "Status pronto")
      equal(manager.metricsSnapshot.getOrElse("discovery01.remainder.calls", BigInt(0)),
        BigInt(2), "Metrica puramente osservativa")
    }

    check("l'output legacy non dipende dai due giorni") {
      val manager = new BaseMonsterManager
      val first = manager.discover01Remainder(0, 0, -1)
      val second = manager.discover01Remainder(9000, -5000, -1)
      equal(first.legacyOutput, second.legacyOutput, "Purezza della funzione legacy")
      equal(first.legacyOutput, M-1, "Residuo negativo")
    }

    check("nessuna chiamata dell'oracolo nel codice di produzione") {
      val stream = Files.walk(projectRoot().resolve("src/main/scala"))
      val sources = try stream.iterator().asScala
        .filter(p => Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p => new String(Files.readAllBytes(p), StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"), "L'oracolo non può entrare in produzione")
      val metadata = new String(Files.readAllBytes(projectRoot().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val stage = metadata.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE assente"))
      if (stage == 2) {
        truth(!sources.contains("savePatch"), "PATCH 01 non può essere anticipato")
      } else {
        truth(sources.contains("savePatch"), "PATCH 01 deve esistere dagli stadi successivi")
      }
    }

    check("stadio 2 dichiarato senza completamento prematuro") {
      val text = new String(Files.readAllBytes(projectRoot().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val stage = text.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE assente"))
      truth(stage >= 2, "La prova storica richiede uno stadio >= 2")
      if (stage == 2) {
        truth(text.contains("CURRENT_KIND=DISCOVERY"), "Tipo di stadio inesatto")
        truth(text.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"), "Deve essere rosso")
      } else {
        truth(text.contains("LAST_COMPLETED_STAGE="), "Manca la storia degli stadi")
      }
    }

    val manager = new BaseMonsterManager
    Vector(
      ("M", M),
      ("2M", 2*M),
      ("3M", 3*M),
      ("M+1", M+1)
    ).foreach { case (name, input) =>
      check("equivalenza normativa SAVE(" + name + ")") {
        val production = manager.discover01Remainder(10, 20, input).legacyOutput
        val expected = NormativeOracle.save(input)
        equal(production, expected, "Divergenza storica " + name)
      }
    }

    println("\nRISULTATO STADIO 2: " + passed + " PASS, " + failed + " FAIL")
    if (failed != 0) sys.exit(1)
  }
}
