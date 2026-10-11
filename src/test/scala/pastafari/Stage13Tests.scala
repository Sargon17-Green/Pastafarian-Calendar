package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 06: il sentinel e il vecchio errore di indice restano accessibili. */
object Stage13Tests {
  private var passed = 0
  private var failed = 0
  private val M = NormativeOracle.M
  private val Stones = Vector[BigInt](19, 23, 29, 31, 37)
  // Tabella attesa del contratto, definita in TEST e non dedotta dal prodotto.
  private val Expected = Vector(
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
      case e: Throwable =>
        failed += 1
        println("FAIL — " + name + " — " + e.getMessage)
        e.printStackTrace(System.out)
    }
  }
  private def eqv[A](actual: A, expected: A, what: String): Unit =
    if (actual != expected)
      throw new AssertionError(what + ": atteso=" + expected + ", ottenuto=" + actual)
  private def truth(ok: Boolean, what: String): Unit =
    if (!ok) throw new AssertionError(what)
  private def rejectsArg(what: String)(body: => Unit): Unit = {
    var threw = false
    try body catch { case _: IllegalArgumentException => threw = true }
    truth(threw, what + " non rifiutato")
  }
  private def rejectsState(what: String)(body: => Unit): Unit = {
    var threw = false
    try body catch { case _: IllegalStateException => threw = true }
    truth(threw, what + " non rifiutato")
  }
  private def expectedGrind(step: Int, x: BigInt, p1: BigInt, p3: BigInt,
                            p7: BigInt, stones: Vector[BigInt]): BigInt = {
    val r = Expected(step - 1)
    NormativeOracle.save(x * x + r.a * x + r.b * p1 +
      r.c * p3 + r.d * p7 + stones(r.stoneKind))
  }
  private def projectRoot(): Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null)
      p = p.getParent
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del repository assente")
    p
  }
  private def prepared(step: Int): BaseMonsterContext = {
    val c = BaseMonsterContext(1, 2)
    c.status = "BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.grindStepInput = Some(step)
    c.grindValueInput = Some(7)
    c.grindPrev1Input = Some(11)
    c.grindPrev3Input = Some(13)
    c.grindPrev7Input = Some(17)
    c.grindStonesInput = Some(Stones)
    c.phase = "DISCOVERY_06_GRIND"
    new Discovery06GrindHandler(new BaseMetricsShell).handle(c)
    c.phase = "PATCH_06_GRIND"
    c
  }

  def main(args: Array[String]): Unit = {
    check("la tabella sentinel originale resta immutata") {
      eqv(LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL.length, 12, "Dodici voci")
      eqv(LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL.head,
        LegacyGrindRule(0,0,0,0,0), "Sentinel")
      eqv(LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL.tail, Expected,
        "Undici voci corrette già presenti")
    }

    check("la lookup storica sbaglia ogni indice da uno a undici") {
      (1 to 11).foreach { step =>
        eqv(LegacyGrindTableAdapter.legacyGrindRule(step),
          LegacyGrindTableAdapter.GRIND_TABLE_WITH_SENTINEL(step - 1),
          "Lookup historica " + step)
      }
    }

    check("la nuova lookup restituisce tutte le undici regole normative") {
      (1 to 11).foreach { step =>
        eqv(Patch06GrindWrapper.rulePatch(step), Expected(step - 1), "Regola " + step)
      }
    }

    check("prima regola: 422 corretto contro 68 storico") {
      eqv(LegacyGrindTableAdapter.legacyGrind(1,7,11,13,17,Stones),
        BigInt(68), "Cicatrice")
      eqv(Patch06GrindWrapper.grindPatch(1,7,11,13,17,Stones),
        BigInt(422), "PATCH 06")
    }

    check("sesta e undicesima regola: tutti gli output corretti") {
      for (step <- Vector(6,11)) {
        val corrected = Patch06GrindWrapper.grindPatch(step,7,11,13,17,Stones)
        val legacy = LegacyGrindTableAdapter.legacyGrind(step,7,11,13,17,Stones)
        eqv(corrected, expectedGrind(step,7,11,13,17,Stones),
          "Riferimento macinatura " + step)
        truth(legacy != corrected, "La cicatrice non deve sparire")
      }
    }

    check("i numeri 1..11 producono uscite normative con la stessa pietra") {
      (1 to 11).foreach { step =>
        eqv(Patch06GrindWrapper.grindPatch(step,7,11,13,17,Stones),
          expectedGrind(step,7,11,13,17,Stones), "Macinatura " + step)
      }
    }

    check("confronto esaustivo su undici passi e numeri signed piccoli") {
      for (step <- 1 to 11; n <- -120 to 120) {
        val x = BigInt(n)
        eqv(Patch06GrindWrapper.grindPatch(step,x,2*x+1,3*x-1,-5*x,Stones),
          expectedGrind(step,x,2*x+1,3*x-1,-5*x,Stones),
          "Passo=" + step + " numero=" + n)
      }
    }

    check("cinque pietre distinte sono lette con il loro indice normativo") {
      val distinct = Vector[BigInt](19,41,113,251,521)
      (1 to 11).foreach { step =>
        eqv(Patch06GrindWrapper.grindPatch(step,0,0,0,0,distinct),
          NormativeOracle.save(distinct(Expected(step-1).stoneKind)),
          "Pietra al passo " + step)
      }
    }

    check("ogni macinatura restituisce un numero SAVE compreso tra uno e M") {
      for (step <- 1 to 11; n <- -100 to 100) {
        val x = BigInt(n)
        val result = Patch06GrindWrapper.grindPatch(step,x,-x,x*2,-x*3,Stones)
        truth(result>=1 && result<=M,"Dominio SAVE")
      }
    }

    check("SAVE positivo conserva M al posto del residuo nullo") {
      val stones = Vector[BigInt](M, M, M, M, M)
      for (step <- 1 to 11) {
        eqv(Patch06GrindWrapper.grindPatch(step,0,0,0,0,stones),
          M,"Moltipli di M al passo " + step)
      }
    }

    check("interi giganteschi con segno e senza overflow") {
      val large = (BigInt(1) << 16384) + 1447
      for (step <- 1 to 11; sign <- Vector(-1,1)) {
        val x = large * sign
        eqv(Patch06GrindWrapper.grindPatch(step,x,-x,x+1,-x-2,Stones),
          expectedGrind(step,x,-x,x+1,-x-2,Stones),"BigInt " + step)
      }
    }

    check("campione deterministico di 512 macinature firmate") {
      val rng = new Random(20261011L)
      (1 to 512).foreach { i =>
        val step = rng.nextInt(11)+1
        val x = (BigInt(1) << (rng.nextInt(4096)+1)) + i
        val signed = if (i%2 == 0) x else -x
        val p1 = signed+11*i
        val p3 = -signed-13*i
        val p7 = signed-17*i
        eqv(Patch06GrindWrapper.grindPatch(step,signed,p1,p3,p7,Stones),
          expectedGrind(step,signed,p1,p3,p7,Stones),"Campione "+i)
      }
    }

    check("manager esegue realmente BOOT, DISCOVERY 06 e PATCH 06") {
      val m = new BaseMonsterManager
      val r = m.patch06Grind(123, -456, 1, 7,11,13,17,Stones)
      eqv(r.calculationDay, BigInt(123), "Calculation")
      eqv(r.targetDay, BigInt(-456), "Target")
      eqv(r.step, 1, "Step")
      eqv(r.legacyRule, LegacyGrindRule(0,0,0,0,0), "Regola legacy")
      eqv(r.patchedRule, Expected.head, "Regola nuova")
      eqv(r.legacyValue, BigInt(68), "Valore antico")
      eqv(r.patchedValue, BigInt(422), "Valore corretto")
      truth(r.patchApplied, "Flag applicata")
      eqv(r.phase, "PATCH_06_GRIND", "Fase")
      eqv(r.status, "PATCH_06_READY", "Prontezza")
      eqv(r.trace, Vector("BOOT","DISCOVERY_06_GRIND","PATCH_06_GRIND"), "Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery06.grind.calls"),BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch06.grind.calls"),BigInt(1),"Patch")
    }

    check("diagnostica della DISCOVERY 06 resta RED anche dopo PATCH 06") {
      val m = new BaseMonsterManager
      (1 to 11).foreach { step =>
        val old=m.discover06Grind(1,2,step,7,11,13,17,Stones)
        val fixed=m.patch06Grind(1,2,step,7,11,13,17,Stones)
        eqv(old.legacyValue,fixed.legacyValue,"Cicatrice "+step)
        eqv(fixed.patchedValue,expectedGrind(step,7,11,13,17,Stones),
          "Riferimento "+step)
        eqv(old.trace,Vector("BOOT","DISCOVERY_06_GRIND"),"Diagnosi "+step)
      }
    }

    check("nessun output di altri giorni modifica la macinatura") {
      val m=new BaseMonsterManager
      val huge=BigInt(1)<<8192
      val a=m.patch06Grind(0,0,6,7,11,13,17,Stones)
      val b=m.patch06Grind(huge,-huge,6,7,11,13,17,Stones)
      eqv(a.patchedValue,b.patchedValue,"Contesto indipendente")
      eqv(a.legacyValue,b.legacyValue,"Cicatrice indipendente")
    }

    check("snapshot immutabili e invocazioni indipendenti") {
      val m=new BaseMonsterManager
      val a=m.patch06Grind(1,2,1,7,11,13,17,Stones)
      val b=m.patch06Grind(3,4,11,8,11,13,17,Stones)
      eqv(a.legacyValue,BigInt(68),"Snapshot antico")
      eqv(a.patchedValue,BigInt(422),"Snapshot nuovo")
      truth(b.patchedValue!=a.patchedValue,"B deve differire")
      eqv(m.metricsSnapshot("patch06.grind.calls"),BigInt(2),"Metriche")
    }

    check("input fuori 1..11 non sono accettati dalla lookup e dal wrapper") {
      for(step <- Vector(-3, -1, 0, 12, 15, 100)) {
        rejectsArg("Lookup "+step){Patch06GrindWrapper.rulePatch(step)}
        rejectsArg("Macinatura "+step){Patch06GrindWrapper.grindPatch(step,7,11,13,17,Stones)}
      }
    }

    check("riga di pietre malformata non viene silenziosamente corretta") {
      rejectsArg("Mancano pietre") {
        Patch06GrindWrapper.grindPatch(1,7,11,13,17,Stones.take(4))
      }
      rejectsArg("Pietre in eccesso") {
        Patch06GrindWrapper.grindPatch(11,7,11,13,17,Stones :+ BigInt(41))
      }
    }

    check("handler richiede Bootstrap e discovery nello stesso contesto") {
      val h=new Patch06GrindHandler(new BaseMetricsShell)
      rejectsState("Contesto vergine"){h.handle(BaseMonsterContext(1,2))}
      val c=BaseMonsterContext(1,2)
      c.status="LEGACY_GRIND_READY"
      c.grindStepInput=Some(1)
      c.grindValueInput=Some(7)
      c.grindPrev1Input=Some(11)
      c.grindPrev3Input=Some(13)
      c.grindPrev7Input=Some(17)
      c.grindStonesInput=Some(Stones)
      c.legacyGrindRuleOutput=Some(LegacyGrindRule(0,0,0,0,0))
      c.legacyGrindOutput=Some(68)
      rejectsState("Traccia vuota"){h.handle(c)}
      truth(c.patchedGrindOutput.isEmpty && !c.patch06Applied,"Rifiuto atomico")
    }

    check("handler rifiuta la seconda applicazione e preserva la prima") {
      val h=new Patch06GrindHandler(new BaseMetricsShell)
      val c=prepared(1)
      h.handle(c)
      val before=c.patchedGrindOutput
      rejectsState("Doppia PATCH 06"){h.handle(c)}
      eqv(c.patchedGrindOutput,before,"Output inalterato")
    }

    check("validator rifiuta stato falso e output patched alterato") {
      val v=new BaseValidationManager
      val c=prepared(6)
      c.status="PATCH_06_READY"
      c.branchTrace.append("PATCH_06_GRIND")
      c.patch06Applied=true
      rejectsState("Manca output"){v.requirePatch06Ready(c)}
      c.patchedGrindRuleOutput=Some(Expected(5))
      c.patchedGrindOutput=Some(expectedGrind(6,7,11,13,17,Stones))
      v.requirePatch06Ready(c)
      c.patchedGrindOutput=Some(999)
      rejectsState("Output falso"){v.requirePatch06Ready(c)}
    }

    check("validator rifiuta regola scambiata e vecchio risultato falsificato") {
      val v=new BaseValidationManager
      val c=prepared(6)
      new Patch06GrindHandler(new BaseMetricsShell).handle(c)
      v.requirePatch06Ready(c)
      c.patchedGrindRuleOutput=Some(Expected(4))
      rejectsState("Rule falsa"){v.requirePatch06Ready(c)}
      c.patchedGrindRuleOutput=Some(Expected(5))
      c.legacyGrindOutput=Some(999)
      rejectsState("Scar falsa"){v.requirePatch06Ready(c)}
    }

    check("validator rifiuta la traccia senza discovery") {
      val v=new BaseValidationManager
      val c=prepared(1)
      new Patch06GrindHandler(new BaseMetricsShell).handle(c)
      c.branchTrace.remove(1)
      rejectsState("Traccia manomessa"){v.requirePatch06Ready(c)}
    }

    check("PATCH 01–05 e cicatrici precedenti sopravvivono") {
      val m=new BaseMonsterManager
      val f=NormativeOracle.FoundationDay
      eqv(m.patch01Save(0,0,M).patchedOutput,M,"SAVE")
      eqv(m.patch02DayTag(f,f,f).patchedTag,BigInt(1),"giorno")
      eqv(m.patch03Distance(f,f).patchedDistance,BigInt(1),"distanza")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"pietre")
      val h=Vector[BigInt](101,202,303,404,505,606,707)
      eqv(m.patch05Prior(0,0,h,Vector.empty,1,7).patchedValue,BigInt(707),"prior")
      eqv(m.discover05Prior(0,0,h,Vector.empty,1,7).legacyValue,
        BigInt(606),"Cicatrice prior")
    }

    check("nessun oracolo nel prodotto e nessuna logica Stage14") {
      val stream=Files.walk(projectRoot().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracle test-only")
      truth(sources.contains("LegacyGrindTableAdapter.legacyGrind("),
        "Il wrapper deve attraversare la cicatrice vera")
      truth(sources.contains("GRIND_TABLE_WITH_SENTINEL(step)"),
        "Il wrapper usa la regola dopo il sentinel")
      truth(!sources.contains("bowlAlias"),"Logica futura delle alias bowl anticipata")
    }

    check("metadati Stage13 veritieri e non certificati anticipatamente") {
      val text=new String(Files.readAllBytes(projectRoot().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = text.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE assente"))
      truth(currentStage >= 13,"PATCH 06 deve restare disponibile")
      if (currentStage == 13) {
        truth(text.contains("CURRENT_KIND=PATCH"),"Patch")
        truth(text.contains("CURRENT_PATCH=06"),"Patch 06")
        truth(text.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"Green")
      } else {
        truth(text.contains("STAGE_13_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_26_PASS_0_FAIL"),
          "Certificazione storica Stage13 conservata")
      }
      val completed=text.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("LAST_COMPLETED_STAGE mancante"))
      truth(completed>=12 && completed<=currentStage,"Ordine certificati storico")
    }

    println("\nRISULTATO STADIO 13: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0) sys.exit(1)
  }
}
