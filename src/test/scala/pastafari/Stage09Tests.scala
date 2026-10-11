package pastafari

import pastafari.monster.{
  BaseMonsterManager, BaseMonsterContext, BaseValidationManager, BaseMetricsShell,
  LegacyStoneMutationAdapter, Patch04StonesWrapper, Patch04StonesHandler,
  Discovery04StonesHandler, Patch01SaveWrapper
}
import pastafari.oracle.NormativeOracle
import java.nio.file.{Files, Paths}
import java.nio.charset.StandardCharsets
import scala.jdk.CollectionConverters._

/** PATCH 04: certificazione completa di 46 righe e mantenimento del legacy RED. */
object Stage09Tests {
  private var passed = 0
  private var failed = 0

  private def check(label: String)(body: => Unit): Unit = {
    try {
      body
      passed += 1
      println("PASS — " + label)
    } catch {
      case ex: Throwable =>
        failed += 1
        println("FAIL — " + label + " — " + ex.getMessage)
        ex.printStackTrace(System.out)
    }
  }
  private def eqv[A](actual: A, expected: A, label: String): Unit =
    if (actual != expected) throw new AssertionError(
      label + ": atteso=" + expected + ", ottenuto=" + actual)
  private def truth(ok: Boolean, label: String): Unit =
    if (!ok) throw new AssertionError(label)
  private def rejectState(label: String)(body: => Unit): Unit = {
    var rejected = false
    try body catch { case _: IllegalStateException => rejected = true }
    truth(rejected, label + ": stato scorretto accettato")
  }
  private def rejectArgument(label: String)(body: => Unit): Unit = {
    var rejected = false
    try body catch { case _: IllegalArgumentException => rejected = true }
    truth(rejected, label + ": forma scorretta accettata")
  }
  private def root(): java.nio.file.Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null) p=p.getParent
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice non trovata")
    p
  }

  def main(args: Array[String]): Unit = {
    val legacy = LegacyStoneMutationAdapter.mutateStonesWrong()

    check("la diagnosi legacy mantiene 46 righe e la cicatrice") {
      eqv(legacy.length,46,"Righe")
      eqv(legacy(1)(1),BigInt(1434),"Orzo erroneo")
      eqv(legacy(1)(2),BigInt(3780),"Sale erroneo")
      eqv(legacy(2)(0),BigInt(147189),"Frumento erroneo")
    }

    check("la patch parte esattamente dalle cinque pietre legacy iniziali") {
      val corrected=Patch04StonesWrapper.stonesPatch(legacy)
      eqv(corrected.head,legacy.head,"Pietre originali")
      eqv(corrected.head,Vector[BigInt](17,29,43,71,101),"Seme canonico")
    }

    check("la seconda riga corregge tutte e cinque le pietre") {
      val corrected=Patch04StonesWrapper.stonesPatch(legacy)
      eqv(corrected(1),Vector[BigInt](378,1073,2375,6195,10493),"Riga 2 esatta")
      eqv(corrected(1),NormativeOracle.Stones(1),"Riga 2 normativa")
    }

    check("la terza riga non eredita la corruzione in-place") {
      val corrected=Patch04StonesWrapper.stonesPatch(legacy)
      eqv(corrected(2),NormativeOracle.Stones(2),"Riga 3 normativa")
      eqv(corrected(2)(0),BigInt(146106),"Frumento della riga 3")
      truth(corrected(2)(0) != legacy(2)(0),"Cicatrice eliminata dall'uscita patched")
    }

    check("tutte le 230 pietre di 46 righe coincidono con l'oracolo") {
      eqv(Patch04StonesWrapper.stonesPatch(legacy),NormativeOracle.Stones,
        "Tabella normativa completa")
    }

    check("dimensioni della tabella patched esatte e costanti") {
      val corrected=Patch04StonesWrapper.stonesPatch(legacy)
      eqv(corrected.length,46,"Righe")
      truth(corrected.forall(_.length == 5),"Cinque pietre per riga")
    }

    check("ogni valore patched appartiene all'intervallo SAVE 1..M") {
      val corrected=Patch04StonesWrapper.stonesPatch(legacy)
      truth(corrected.flatten.forall(x=>x >= 1 && x <= NormativeOracle.M),
        "Pietre modulari positive")
    }

    check("ogni transizione rilegge tutti i cinque valori congelati") {
      val corrected=Patch04StonesWrapper.stonesPatch(legacy)
      (1 until corrected.length).foreach { i =>
        val old=corrected(i-1)
        val row=i+1
        val expected=Vector(
          Patch01SaveWrapper.savePatch(old(0)*old(0)+3*old(1)+row),
          Patch01SaveWrapper.savePatch(old(1)*old(1)+5*old(2)+old(0)),
          Patch01SaveWrapper.savePatch(old(2)*old(2)+7*old(3)+old(1)),
          Patch01SaveWrapper.savePatch(old(3)*old(3)+11*old(4)+old(2)),
          Patch01SaveWrapper.savePatch(old(4)*old(4)+13*old(0)+old(3))
        )
        eqv(corrected(i),expected,"Ricorrenza alla riga "+row)
      }
    }

    check("la prima componente e la seconda divergono dalla cicatrice al punto previsto") {
      val corrected=Patch04StonesWrapper.stonesPatch(legacy)
      eqv(corrected(1)(0),legacy(1)(0),"Frumento iniziale non divergente")
      truth(corrected(1)(1)!=legacy(1)(1),"Orzo divergente")
      truth(corrected(1)(2)!=legacy(1)(2),"Sale divergente")
    }

    check("la correzione non modifica l'output storico di DISCOVERY 04") {
      val before=legacy
      val corrected=Patch04StonesWrapper.stonesPatch(before)
      eqv(before,LegacyStoneMutationAdapter.mutateStonesWrong(),"Legacy conservato")
      truth(corrected!=before,"La patch deve produrre un valore distinto")
      eqv(before(1)(1),BigInt(1434),"Valore storico dopo patch")
    }

    check("le righe legacy successive alla prima non sono fonti corrette") {
      val poisoned=legacy.updated(1,Vector.fill[BigInt](5)(1))
        .updated(12,Vector.fill[BigInt](5)(NormativeOracle.M))
      eqv(Patch04StonesWrapper.stonesPatch(poisoned),
        Patch04StonesWrapper.stonesPatch(legacy),"Ricostruzione dal solo seme")
    }

    check("ripetizioni della patch producono risultati indipendenti") {
      val expected=Patch04StonesWrapper.stonesPatch(legacy)
      (1 to 32).foreach { _ =>
        eqv(Patch04StonesWrapper.stonesPatch(
          LegacyStoneMutationAdapter.mutateStonesWrong()),expected,"Determinismo")
      }
    }

    check("ogni riga patched è uno snapshot immutabile") {
      val corrected=Patch04StonesWrapper.stonesPatch(legacy)
      eqv(corrected(0),Vector[BigInt](17,29,43,71,101),"Riga iniziale invariata")
      truth(corrected.head != corrected.last,"Righe non aliasate")
      eqv(corrected(1),Vector[BigInt](378,1073,2375,6195,10493),"Riga due invariata")
    }

    check("rifiuto di tabella legacy vuota o parziale") {
      rejectArgument("Vuota") { Patch04StonesWrapper.stonesPatch(Vector.empty) }
      rejectArgument("Una riga") { Patch04StonesWrapper.stonesPatch(Vector(legacy.head)) }
      rejectArgument("45 righe") { Patch04StonesWrapper.stonesPatch(legacy.take(45)) }
    }

    check("rifiuto di numero sbagliato di pietre in una riga") {
      val malformed=legacy.updated(17,Vector[BigInt](1,2,3,4))
      rejectArgument("Riga di quattro pietre") {
        Patch04StonesWrapper.stonesPatch(malformed)
      }
    }

    check("rifiuto del seme iniziale alterato") {
      val corruptSeed=legacy.updated(0,Vector[BigInt](18,29,43,71,101))
      rejectArgument("Seme alterato") {
        Patch04StonesWrapper.stonesPatch(corruptSeed)
      }
    }

    check("manager attraversa realmente BOOT discovery e patch nello stesso contesto") {
      val m=new BaseMonsterManager
      val r=m.patch04Stones(17,-29)
      eqv(r.calculationDay,BigInt(17),"Calculation day")
      eqv(r.targetDay,BigInt(-29),"Target day")
      eqv(r.legacyStoneRows(1)(1),BigInt(1434),"Cicatrice presente")
      eqv(r.patchedStoneRows(1)(1),BigInt(1073),"Patch attiva")
      truth(r.patchApplied,"Flag PATCH 04")
      eqv(r.phase,"PATCH_04_STONES","Fase")
      eqv(r.status,"PATCH_04_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_04_STONES","PATCH_04_STONES"),
        "Sequenza di handler")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery04.stones.calls"),BigInt(1),"Handler legacy")
      eqv(m.metricsSnapshot("patch04.stones.calls"),BigInt(1),"Handler corretto")
    }

    check("il percorso corretto restituisce le stesse 230 pietre dell'oracolo") {
      val r=new BaseMonsterManager().patch04Stones(0,0)
      eqv(r.patchedStoneRows,NormativeOracle.Stones,"Manager normativo")
    }

    check("il percorso diagnostico continua a mostrare la tabella sbagliata") {
      val m=new BaseMonsterManager
      val old=m.discover04Stones(0,0)
      val patched=m.patch04Stones(0,0)
      eqv(old.legacyStoneRows,patched.legacyStoneRows,"Legacy immutato")
      truth(old.legacyStoneRows!=patched.patchedStoneRows,"Errore storico distinto")
      eqv(old.trace,Vector("BOOT","DISCOVERY_04_STONES"),"Traccia diagnostica")
      eqv(m.metricsSnapshot("discovery04.stones.calls"),BigInt(2),
        "Entrambi i percorsi attraversano la discovery")
    }

    check("giorni arbitrari non modificano le pietre deterministiche") {
      val huge=(BigInt(1)<<16384)+123
      val m=new BaseMonsterManager
      val a=m.patch04Stones(0,0)
      val b=m.patch04Stones(-huge,huge)
      eqv(a.patchedStoneRows,b.patchedStoneRows,"Indipendenza dai giorni")
      eqv(a.legacyStoneRows,b.legacyStoneRows,"Cicatrice deterministica")
      eqv(a.calculationDay,BigInt(0),"Primo report immutato")
      eqv(b.targetDay,huge,"Secondo report immutato")
    }

    check("isolamento di invocazioni e metriche osservative") {
      val m=new BaseMonsterManager
      val first=m.patch04Stones(1,2)
      val second=m.patch04Stones(3,4)
      eqv(first.calculationDay,BigInt(1),"Primo giorno preservato")
      eqv(second.calculationDay,BigInt(3),"Secondo giorno preservato")
      eqv(first.patchedStoneRows,second.patchedStoneRows,"Valori coerenti")
      eqv(m.metricsSnapshot("patch04.stones.calls"),BigInt(2),"Due patch")
      eqv(m.metricsSnapshot("discovery04.stones.calls"),BigInt(2),"Due discovery")
    }

    check("validator rifiuta flag, traccia e risultato manomessi") {
      val validation=new BaseValidationManager
      val c=BaseMonsterContext(1,2)
      c.phase="PATCH_04_STONES"
      c.status="PATCH_04_READY"
      c.patch04Applied=true
      rejectState("Output mancante") { validation.requirePatch04Ready(c) }
      c.legacyStoneRowsOutput=Some(legacy)
      c.patchedStoneRowsOutput=Some(Patch04StonesWrapper.stonesPatch(legacy))
      rejectState("Traccia assente") { validation.requirePatch04Ready(c) }
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_04_STONES","PATCH_04_STONES"))
      validation.requirePatch04Ready(c)
      c.patchedStoneRowsOutput=Some(c.patchedStoneRowsOutput.get.updated(
        1,Vector.fill[BigInt](5)(1)))
      rejectState("Output manomesso") { validation.requirePatch04Ready(c) }
      c.patchedStoneRowsOutput=Some(Patch04StonesWrapper.stonesPatch(legacy))
      c.patch04Applied=false
      rejectState("Flag assente") { validation.requirePatch04Ready(c) }
    }

    check("handler impedisce bypass della discovery e doppia applicazione") {
      val handler=new Patch04StonesHandler(new BaseMetricsShell)
      val unready=BaseMonsterContext(1,2)
      rejectState("Senza bootstrap") { handler.handle(unready) }
      val fake=BaseMonsterContext(1,2)
      fake.status="LEGACY_STONES_READY"
      fake.legacyStoneRowsOutput=Some(legacy)
      rejectState("Traccia assente") { handler.handle(fake) }
      truth(fake.patchedStoneRowsOutput.isEmpty && !fake.patch04Applied,
        "Nessun effetto in caso di rifiuto")
      val real=BaseMonsterContext(1,2)
      real.status="BOOTSTRAPPED"
      real.branchTrace.append("BOOT")
      new Discovery04StonesHandler(new BaseMetricsShell).handle(real)
      real.phase="PATCH_04_STONES"
      handler.handle(real)
      rejectState("Doppia invocazione") { handler.handle(real) }
    }

    check("le patch 01 02 e 03 restano con i relativi difetti visibili") {
      val m=new BaseMonsterManager
      val mod=NormativeOracle.M
      val F=NormativeOracle.FoundationDay
      eqv(m.discover01Remainder(0,0,mod).legacyOutput,BigInt(0),"SAVE antico")
      eqv(m.patch01Save(0,0,mod).patchedOutput,mod,"SAVE corretto")
      eqv(m.discover02DayTag(F,F,F).legacyTag,BigInt(0),"Tag antico")
      eqv(m.patch02DayTag(F,F,F).patchedTag,BigInt(1),"Tag corretto")
      eqv(m.discover03Distance(F,F).legacyDistance,BigInt(0),"Distanza antica")
      eqv(m.patch03Distance(F,F).patchedDistance,BigInt(1),"Distanza corretta")
    }

    check("oracolo solo nel test, helper legacy intatto e nessuna discovery futura") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo vietato nel prodotto")
      truth(sources.contains("LegacyStoneMutationAdapter.mutateStonesWrong()"),
        "Il helper storico deve restare eseguito")
      truth(sources.contains("Patch04StonesWrapper.stonesPatch("),
        "La correzione deve essere separata")
      val state = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      if (currentStage < 10)
        truth(!sources.contains("legacyPrior"),"DISCOVERY 05 anticipata")
      else
        truth(sources.contains("legacyPrior"),"DISCOVERY 05 mancante")
    }

    check("metadati dello stadio 9 verdi e certificazioni conservate") {
      val state=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      truth(currentStage >= 9,"PATCH 04 deve essere disponibile")
      if (currentStage == 9) {
        truth(state.contains("CURRENT_KIND=PATCH"),"Tipo")
        truth(state.contains("CURRENT_PATCH=04"),"Patch corrente")
        truth(state.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"Stato GREEN")
      } else {
        truth(state.contains("STAGE_09_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_26_PASS_0_FAIL"),
          "Certificazione storica PATCH 04 mancante")
      }
      truth(state.contains("STAGE_08_NATIVE_VERIFICATION=PASS_EXPECTED_RED_19_PASS_3_FAIL"),
        "DISCOVERY 04 storica conservata")
      val completed=state.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("LAST_COMPLETED_STAGE assente"))
      truth(completed >= 8 && completed <= currentStage,"Ordine storico non valido")
    }

    println("\nRISULTATO STADIO 9: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
