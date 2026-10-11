package pastafari

import pastafari.monster.{
  BaseMetricsShell, BaseMonsterContext, BaseMonsterManager, BaseMonsterDispatcher,
  BaseValidationManager, BaseBootstrapHandler, Discovery02DayTagHandler,
  LegacyDayTagAdapter, Patch02DayTagWrapper, Patch02DayTagHandler
}
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 02: test nativi, tutti verdi, con la diagnosi RED intatta. */
object Stage05Tests {
  private val F = NormativeOracle.FoundationDay
  private var passed = 0
  private var failed = 0

  private def check(name: String)(work: => Unit): Unit = {
    try {
      work
      passed += 1
      println("PASS — " + name)
    } catch {
      case e: Throwable =>
        failed += 1
        println("FAIL — " + name + " — " + e.getMessage)
        e.printStackTrace(System.out)
    }
  }

  private def equal[A](actual: A, expected: A, what: String): Unit =
    if (actual != expected)
      throw new AssertionError(what + ": atteso=" + expected + ", ottenuto=" + actual)

  private def truth(value: Boolean, what: String): Unit =
    if (!value) throw new AssertionError(what)

  private def mustReject(what: String)(work: => Unit): Unit = {
    var rejected = false
    try work catch { case _: IllegalStateException => rejected = true }
    truth(rejected, what + ": chiamata irregolare accettata")
  }

  private def projectRoot(): java.nio.file.Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null) {
      p = p.getParent
    }
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("La radice del progetto non è stata trovata.")
    p
  }

  def main(args: Array[String]): Unit = {
    check("oldDayTag resta una cicatrice identica allo stadio 4") {
      equal(LegacyDayTagAdapter.oldDayTag(F), BigInt(0), "F")
      equal(LegacyDayTagAdapter.oldDayTag(F-1), BigInt(2), "F-1")
      equal(LegacyDayTagAdapter.oldDayTag(F+1), BigInt(2), "F+1")
      equal(LegacyDayTagAdapter.oldDayTag(F-2), BigInt(4), "F-2")
      equal(LegacyDayTagAdapter.oldDayTag(F+2), BigInt(4), "F+2")
    }

    check("PATCH 02 corregge i cinque casi canonici") {
      Vector[BigInt](-2, -1, 0, 1, 2).foreach { offset =>
        val day = F + offset
        equal(Patch02DayTagWrapper.dayTagPatch(day),
          NormativeOracle.dayCount(day), "Offset " + offset)
      }
    }

    check("PATCH 02 aggiunge uno solo al lato non anteriore") {
      Vector[BigInt](-20, -2, -1, 0, 1, 2, 20).foreach { offset =>
        val day = F + offset
        val expected = if (offset >= 0) BigInt(1) else BigInt(0)
        equal(Patch02DayTagWrapper.dayTagPatch(day) -
          LegacyDayTagAdapter.oldDayTag(day), expected, "Delta per " + offset)
      }
    }

    check("nessuna alterazione legacy nei giorni anteriori") {
      (1 to 2000).foreach { distance =>
        val d = F - distance
        equal(Patch02DayTagWrapper.dayTagPatch(d),
          LegacyDayTagAdapter.oldDayTag(d), "Passato " + distance)
      }
    }

    check("corrispondenza esaustiva su 8193 giorni intorno alla Fondazione") {
      (-4096 to 4096).foreach { offset =>
        val day = F + BigInt(offset)
        equal(Patch02DayTagWrapper.dayTagPatch(day),
          NormativeOracle.dayCount(day), "Giorno " + offset)
      }
    }

    check("parità normativa e disgiunzione dei due lati") {
      (1 to 2000).foreach { distance =>
        val past = Patch02DayTagWrapper.dayTagPatch(F-BigInt(distance))
        val future = Patch02DayTagWrapper.dayTagPatch(F+BigInt(distance))
        equal(past, BigInt(2)*distance, "Pari passato")
        equal(future, BigInt(2)*distance+1, "Dispari futuro")
        truth(past != future, "Collisione storica non corretta")
      }
      equal(Patch02DayTagWrapper.dayTagPatch(F), BigInt(1), "Fondazione è dispari")
    }

    check("nessun overflow su valori più grandi di 256 bit") {
      Vector(256, 1024, 4096, 16384).foreach { bits =>
        val d = (BigInt(1) << bits) + 23456789
        Vector(F-d, F+d, F-1-d, F+1+d).foreach { day =>
          equal(Patch02DayTagWrapper.dayTagPatch(day), NormativeOracle.dayCount(day),
            "BigInt di " + bits + " bit")
        }
      }
    }

    check("campionamento deterministico di 512 date grandi e firmate") {
      val random = new Random(20261011L)
      (1 to 512).foreach { i =>
        val magnitude = BigInt(1) << (1 + random.nextInt(8192))
        val offset = magnitude + BigInt(random.nextLong()).abs + i
        val day = if (i % 2 == 0) F+offset else F-offset
        equal(Patch02DayTagWrapper.dayTagPatch(day), NormativeOracle.dayCount(day),
          "Campione " + i)
      }
    }

    check("percorso produzione completo con doppio output ed evidenza") {
      val manager = new BaseMonsterManager
      val r = manager.patch02DayTag(100, 200, F+2)
      equal(r.queriedDay, F+2, "Giorno chiesto")
      equal(r.legacyTag, BigInt(4), "Cicatrice precedente")
      equal(r.patchedTag, BigInt(5), "PATCH 02")
      truth(r.patchApplied, "Flag della patch")
      equal(r.phase, "PATCH_02_DAY_TAG", "Fase")
      equal(r.status, "PATCH_02_READY", "Stato")
      equal(r.trace, Vector("BOOT", "DISCOVERY_02_DAY_TAG", "PATCH_02_DAY_TAG"),
        "La discovery deve essere attraversata prima della patch")
      equal(manager.metricsSnapshot("base.bootstrap.calls"), BigInt(1), "Bootstrap")
      equal(manager.metricsSnapshot("discovery02.daytag.calls"), BigInt(1), "Handler discovery")
      equal(manager.metricsSnapshot("patch02.daytag.calls"), BigInt(1), "Handler patch")
    }

    check("diagnostica RED della discovery ancora reale e osservabile") {
      val manager = new BaseMonsterManager
      val old = manager.discover02DayTag(10, 20, F)
      val corrected = manager.patch02DayTag(10, 20, F)
      equal(old.legacyTag, BigInt(0), "Vecchio output")
      equal(corrected.legacyTag, old.legacyTag, "Cicatrice conservata")
      equal(corrected.patchedTag, BigInt(1), "Output normativo")
      equal(old.trace, Vector("BOOT", "DISCOVERY_02_DAY_TAG"), "Traccia diagnostica")
      equal(manager.metricsSnapshot("discovery02.daytag.calls"), BigInt(2),
        "La discovery è realmente attraversata in entrambe le vie")
    }

    check("isolamento di due invocazioni e snapshot immutati") {
      val manager = new BaseMonsterManager
      val a = manager.patch02DayTag(1, 2, F)
      val b = manager.patch02DayTag(3, 4, F-1)
      equal(a.legacyTag, BigInt(0), "Output storico A")
      equal(a.patchedTag, BigInt(1), "Output A")
      equal(b.legacyTag, BigInt(2), "Output storico B")
      equal(b.patchedTag, BigInt(2), "Output B")
      equal(a.queriedDay, F, "Input A")
      equal(a.trace, b.trace, "Percorsi identici")
      equal(manager.metricsSnapshot("patch02.daytag.calls"), BigInt(2), "Metriche")
    }

    check("giorno interrogato separato dal calculationDay e targetDay") {
      val extreme = BigInt(1) << 4096
      val manager = new BaseMonsterManager
      val a = manager.patch02DayTag(0, 0, F+10)
      val b = manager.patch02DayTag(extreme, -extreme, F+10)
      equal(a.patchedTag, b.patchedTag, "Indipendenza dal contesto di lavoro")
      equal(a.legacyTag, b.legacyTag, "Output legacy indipendente")
    }

    check("validator rifiuta contesti incompleti o falsificati") {
      val validator = new BaseValidationManager
      val c = BaseMonsterContext(1, 1)
      c.phase = "PATCH_02_DAY_TAG"
      c.status = "PATCH_02_READY"
      c.patch02Applied = true
      mustReject("Output non inizializzati") { validator.requirePatch02Ready(c) }
      c.legacyDayTagInput = Some(F+1)
      c.legacyDayTagOutput = Some(2)
      c.patchedDayTagOutput = Some(3)
      c.branchTrace.appendAll(Seq("BOOT", "DISCOVERY_02_DAY_TAG", "PATCH_02_DAY_TAG"))
      validator.requirePatch02Ready(c)
      c.patchedDayTagOutput = Some(4)
      mustReject("Output corretto alterato") { validator.requirePatch02Ready(c) }
      c.patchedDayTagOutput = Some(3)
      c.branchTrace.remove(1)
      mustReject("Discovery saltata") { validator.requirePatch02Ready(c) }
    }

    check("handler PATCH 02 non può saltare la discovery") {
      val handler = new Patch02DayTagHandler(new BaseMetricsShell)
      mustReject("Nessun Bootstrap") { handler.handle(BaseMonsterContext(1, 1)) }
      val c = BaseMonsterContext(1, 1)
      c.status = "LEGACY_DAY_TAG_READY"
      c.legacyDayTagInput = Some(F)
      c.legacyDayTagOutput = Some(0)
      mustReject("Traccia mancante") { handler.handle(c) }
      truth(c.patchedDayTagOutput.isEmpty && !c.patch02Applied,
        "Rifiuto senza effetti sul contesto")
    }

    check("il dispatcher non registra due handler della stessa fase") {
      val m = new BaseMetricsShell
      var rejected = false
      try {
        new BaseMonsterDispatcher(Vector(new BaseBootstrapHandler(m),
          new BaseBootstrapHandler(m)))
      } catch { case _: IllegalArgumentException => rejected = true }
      truth(rejected, "Dispatcher accetta fasi duplicate")
    }

    check("PATCH 01 e cicatrice aritmetica restano verificabili") {
      val manager = new BaseMonsterManager
      val r = manager.patch01Save(F, F, NormativeOracle.M)
      equal(r.legacyOutput, BigInt(0), "SAVE antico")
      equal(r.patchedOutput, NormativeOracle.M, "SAVE normativo")
      equal(manager.discover01Remainder(F,F,NormativeOracle.M).legacyOutput,
        BigInt(0), "Diagnostica storica 01")
    }

    check("nessun oracolo di test né logica di stadio 6 nel prodotto") {
      val stream = Files.walk(projectRoot().resolve("src/main/scala"))
      val sources = try stream.iterator().asScala
        .filter(p => Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p => new String(Files.readAllBytes(p), StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"), "Oracle vietato in produzione")
      truth(sources.contains("LegacyDayTagAdapter.oldDayTag(day)"),
        "Il wrapper deve eseguire il vero legacy helper")
      val state = new String(Files.readAllBytes(projectRoot().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      if (currentStage < 6)
        truth(!sources.contains("oldDistance"), "DISCOVERY 03 non può comparire prima del tempo")
      else
        truth(sources.contains("oldDistance"), "DISCOVERY 03 deve conservare la sua cicatrice")
    }

    check("stadio 5 corretto, senza certificazione anticipata") {
      val state = new String(Files.readAllBytes(projectRoot().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      truth(currentStage >= 5, "La PATCH 02 richiede almeno lo stadio 5")
      if (currentStage == 5) {
        truth(state.contains("CURRENT_KIND=PATCH"), "Tipo")
        truth(state.contains("CURRENT_PATCH=02"), "Numero PATCH")
        truth(state.contains("EXPECTED_REPOSITORY_STATE=GREEN"), "Verde normativo")
      }
      val last = state.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("Stadio precedente assente"))
      truth(last >= 4 && last <= currentStage, "La storia deve conservare PATCH 02 senza anticipare il futuro")
    }

    println("\nRISULTATO STADIO 5: " + passed + " PASS, " + failed + " FAIL")
    if (failed != 0) sys.exit(1)
  }
}
