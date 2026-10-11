package pastafari

import pastafari.monster.{
  BaseMetricsShell, BaseMonsterContext, BaseMonsterManager, BaseValidationManager,
  Discovery04StonesHandler, LegacyStoneMutationAdapter, Patch01SaveWrapper
}
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._

/** DISCOVERY 04: 18 verifiche verdi e 3 divergenze normative intenzionali. */
object Stage08Tests {
  private var passed = 0
  private var failed = 0
  private val M = NormativeOracle.M

  private def check(label: String)(body: => Unit): Unit = {
    try {
      body
      passed += 1
      println("PASS — " + label)
    } catch {
      case e: Throwable =>
        failed += 1
        println("FAIL — " + label + " — " + e.getMessage)
        e.printStackTrace(System.out)
    }
  }
  private def eqv[A](actual: A, expected: A, label: String): Unit =
    if (actual != expected) throw new AssertionError(
      label + ": atteso=" + expected + ", ottenuto=" + actual)
  private def truth(v: Boolean, label: String): Unit =
    if (!v) throw new AssertionError(label)
  private def reject(label: String)(body: => Unit): Unit = {
    var rejected = false
    try body catch { case _: IllegalStateException => rejected = true }
    truth(rejected, label + ": stato non valido accettato")
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
    check("la prima riga rimane la stessa pietra iniziale") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      eqv(rows.head, Vector[BigInt](17,29,43,71,101), "Cinque pietre iniziali")
    }

    check("la seconda riga conserva il frumento normativo") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      eqv(rows(1)(0), BigInt(378), "Prima pietra della seconda riga")
      eqv(rows(1)(0), NormativeOracle.Stones(1)(0), "Frumento")
    }

    check("l'orzo della seconda riga legge il frumento già aggiornato") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      eqv(rows(1)(1), BigInt(1434), "Orzo sequenziale")
    }

    check("il sale della seconda riga legge l'orzo già aggiornato") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      eqv(rows(1)(2), BigInt(3780), "Sale sequenziale")
    }

    check("46 righe esatte di cinque pietre ciascuna") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      eqv(rows.length, 46, "Numero righe")
      truth(rows.forall(_.length == 5), "Cinque colonne in ogni riga")
    }

    check("valori delle pietre sempre nell'intervallo di SAVE") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      truth(rows.flatten.forall(n => n >= 1 && n <= M), "SAVE fra 1 e M")
    }

    check("ricorrenza legacy verificata sui cinque registri") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      (1 until rows.length).foreach { index =>
        val before = rows(index-1)
        val after = rows(index)
        val rowNumber = index + 1
        val wheat = NormativeOracle.save(before(0)*before(0)+3*before(1)+rowNumber)
        val barley = NormativeOracle.save(before(1)*before(1)+5*before(2)+wheat)
        val salt = NormativeOracle.save(before(2)*before(2)+7*before(3)+barley)
        val bitter = NormativeOracle.save(before(3)*before(3)+11*before(4)+salt)
        val red = NormativeOracle.save(before(4)*before(4)+13*wheat+bitter)
        eqv(after, Vector(wheat,barley,salt,bitter,red), "Riga legacy "+rowNumber)
      }
    }

    check("ogni riga emessa resta uno snapshot e non un alias mutabile") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      eqv(rows.head,Vector[BigInt](17,29,43,71,101),"Riga 1 invariata")
      eqv(rows(1)(1),BigInt(1434),"Riga 2 invariata")
      truth(rows.head != rows.last, "Righe autonome")
    }

    check("due costruzioni autonome restituiscono valori deterministici") {
      eqv(LegacyStoneMutationAdapter.mutateStonesWrong(),
        LegacyStoneMutationAdapter.mutateStonesWrong(),"Esecuzione ripetibile")
    }

    check("l'errore non è overflow di interi né residuo euclideo") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      eqv(rows(1)(1),Patch01SaveWrapper.savePatch(29*29+5*43+378),
        "Legacy usa SAVE patched correttamente")
      truth(rows(1)(1) < M, "Nessun wrap sul caso di divergenza")
    }

    check("la prima divergenza inizia dopo il primo aggiornamento in-place") {
      val rows = LegacyStoneMutationAdapter.mutateStonesWrong()
      eqv(rows(1)(0),NormativeOracle.Stones(1)(0),"Frumento conserva il vecchio stato")
      truth(rows(1)(1) != NormativeOracle.Stones(1)(1),"L'orzo deve divergere")
    }

    check("il percorso attivo usa manager dispatcher handler legacy") {
      val m = new BaseMonsterManager
      val report = m.discover04Stones(100,200)
      eqv(report.calculationDay,BigInt(100),"Giorno del calcolo")
      eqv(report.targetDay,BigInt(200),"Giorno chiesto")
      eqv(report.legacyStoneRows.length,46,"Righe")
      eqv(report.legacyStoneRows(1)(1),BigInt(1434),"Output non corretto")
      eqv(report.phase,"DISCOVERY_04_STONES","Fase")
      eqv(report.status,"LEGACY_STONES_READY","Stato")
      eqv(report.trace,Vector("BOOT","DISCOVERY_04_STONES"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery04.stones.calls"),BigInt(1),"Handler reale")
    }

    check("i due giorni di lavoro non influenzano le pietre") {
      val m = new BaseMonsterManager
      val a = m.discover04Stones(0,0)
      val huge=BigInt(1)<<4096
      val b = m.discover04Stones(-huge,huge)
      eqv(a.legacyStoneRows,b.legacyStoneRows,"Tabella deterministica")
      eqv(a.calculationDay,BigInt(0),"Input A immutato")
      eqv(b.targetDay,huge,"Input B immutato")
    }

    check("stato delle invocazioni isolato e snapshot stabili") {
      val m = new BaseMonsterManager
      val a = m.discover04Stones(-100,200)
      val b = m.discover04Stones(300,-400)
      eqv(a.legacyStoneRows,b.legacyStoneRows,"Stesse pietre")
      eqv(a.calculationDay,BigInt(-100),"Snapshot A")
      eqv(b.calculationDay,BigInt(300),"Snapshot B")
      eqv(m.metricsSnapshot("discovery04.stones.calls"),BigInt(2),"Due chiamate")
    }

    check("validazione rifiuta output o traccia incompleti") {
      val v = new BaseValidationManager
      val c = BaseMonsterContext(1,2)
      c.phase="DISCOVERY_04_STONES"
      c.status="LEGACY_STONES_READY"
      reject("Nessuna tabella") { v.requireDiscovery04Ready(c) }
      c.legacyStoneRowsOutput=Some(Vector(Vector[BigInt](17,29,43,71,101)))
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_04_STONES"))
      reject("Forma incompleta") { v.requireDiscovery04Ready(c) }
      c.legacyStoneRowsOutput=Some(Vector.fill(46)(Vector.fill[BigInt](5)(1)))
      v.requireDiscovery04Ready(c)
      c.branchTrace.remove(0)
      reject("Traccia incompleta") { v.requireDiscovery04Ready(c) }
    }

    check("handler non accetta stati precedenti contraffatti") {
      val handler = new Discovery04StonesHandler(new BaseMetricsShell)
      val forged = BaseMonsterContext(1,2)
      reject("Nessun Bootstrap") { handler.handle(forged) }
      forged.status="BOOTSTRAPPED"
      forged.branchTrace.append("BOOT")
      forged.legacyStoneRowsOutput=Some(Vector.empty)
      reject("Output preesistente") { handler.handle(forged) }
      truth(forged.branchTrace.toVector==Vector("BOOT"),"Nessuna traccia artificiale")
    }

    check("le tre patch precedenti e le loro cicatrici rimangono") {
      val m = new BaseMonsterManager
      val F = NormativeOracle.FoundationDay
      eqv(m.discover01Remainder(0,0,M).legacyOutput,BigInt(0),"Scar SAVE")
      eqv(m.patch01Save(0,0,M).patchedOutput,M,"PATCH 01")
      eqv(m.discover02DayTag(F,F,F).legacyTag,BigInt(0),"Scar giornata")
      eqv(m.patch02DayTag(F,F,F).patchedTag,BigInt(1),"PATCH 02")
      eqv(m.discover03Distance(F,F).legacyDistance,BigInt(0),"Scar distanza")
      eqv(m.patch03Distance(F,F).patchedDistance,BigInt(1),"PATCH 03")
    }

    check("solo Scala nel prodotto, oracolo separato e nessuna PATCH 04") {
      val stream = Files.walk(root().resolve("src/main/scala"))
      val text = try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(text.contains("mutateStonesWrong"),"Legacy in produzione")
      truth(!text.contains("NormativeOracle"),"Oracolo non ammesso nel prodotto")
      val state = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      if (currentStage < 9)
        truth(!text.contains("stonesPatch"),"PATCH 04 prematura")
      else
        truth(text.contains("stonesPatch"),"PATCH 04 deve essere disponibile")
    }

    check("metadati dello stadio 8 coerenti con EXPECTED_RED") {
      val status = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = status.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      truth(currentStage >= 8,"DISCOVERY 04 non deve scomparire")
      if (currentStage == 8) {
        truth(status.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
        truth(status.contains("CURRENT_PATCH=03"),"Ultima patch precedente")
        truth(status.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"Rosso deliberato")
      } else {
        truth(status.contains("STAGE_08_NATIVE_VERIFICATION=PASS_EXPECTED_RED_19_PASS_3_FAIL"),
          "Certificazione storica di DISCOVERY 04 mancante")
      }
      val last = status.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("Ultimo stadio assente"))
      truth(last >= 7 && last <= currentStage,"Ordine di completamento coerente")
    }

    val manager = new BaseMonsterManager
    Vector(
      ("riga02 orzo", 1, 1),
      ("riga02 sale", 1, 2),
      ("riga03 frumento", 2, 0)
    ).foreach { case (label,row,col) =>
      check("equivalenza normativa pietra " + label) {
        val wrong = manager.discover04Stones(0,0).legacyStoneRows(row)(col)
        val normative = NormativeOracle.Stones(row)(col)
        eqv(wrong,normative,"Divergenza storica "+label)
      }
    }
    println("\nRISULTATO STADIO 8: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
