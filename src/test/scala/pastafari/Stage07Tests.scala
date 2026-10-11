package pastafari

import pastafari.monster.{
  BaseMetricsShell, BaseMonsterContext, BaseMonsterManager, BaseMonsterDispatcher,
  BaseBootstrapHandler, BaseValidationManager, LegacyDistanceAdapter,
  Patch03DistanceWrapper, Patch03DistanceHandler, Discovery03DistanceHandler
}
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

object Stage07Tests {
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
  private def eqv[A](actual: A, expected: A, label: String): Unit =
    if (actual != expected) throw new AssertionError(
      label + ": atteso=" + expected + ", ottenuto=" + actual)
  private def truth(value: Boolean, label: String): Unit =
    if (!value) throw new AssertionError(label)
  private def reject(label: String)(work: => Unit): Unit = {
    var seen = false
    try work catch { case _: IllegalStateException => seen = true }
    truth(seen, label + ": precondizione non applicata")
  }
  private def root(): Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null) p = p.getParent
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice non trovata")
    p
  }

  def main(args: Array[String]): Unit = {
    check("cicatrice oldDistance immutata nei tre casi storici") {
      eqv(LegacyDistanceAdapter.oldDistance(F,F), BigInt(0), "Stesso giorno")
      eqv(LegacyDistanceAdapter.oldDistance(F,F+1), BigInt(1), "Adiacenti")
      eqv(LegacyDistanceAdapter.oldDistance(F+3,F), BigInt(3), "Inversione")
    }

    check("stesso giorno deve contare come uno anche per valori grandi") {
      Vector[BigInt](F,F-1,F+1,0,-1,BigInt(1)<<8192).foreach { d =>
        eqv(Patch03DistanceWrapper.distancePatch(d,d),BigInt(1),"Stesso giorno")
      }
    }

    check("due giorni contigui in entrambi gli ordini") {
      Vector[BigInt](F,-2,-1,0,1,2,BigInt(1)<<4096).foreach { d =>
        eqv(Patch03DistanceWrapper.distancePatch(d,d+1),BigInt(2),"Avanti")
        eqv(Patch03DistanceWrapper.distancePatch(d+1,d),BigInt(2),"Indietro")
      }
    }

    check("coppie ai confini di Fondazione e zero") {
      val days=Vector[BigInt](F-2,F-1,F,F+1,F+2,-1,0,1)
      for(a <- days; b <- days) eqv(Patch03DistanceWrapper.distancePatch(a,b),
        NormativeOracle.workCounts(a,b).distance,"Bordi")
    }

    check("finestra esaustiva di 66049 coppie temporali") {
      for(a <- -128 to 128; b <- -128 to 128) {
        val c=F+BigInt(a)
        val t=F+BigInt(b)
        eqv(Patch03DistanceWrapper.distancePatch(c,t),
          NormativeOracle.workCounts(c,t).distance,"Coppia "+a+":"+b)
      }
    }

    check("delta esatto di uno sopra il vecchio adattatore") {
      for(a <- -100 to 100; b <- -100 to 100) {
        val c=BigInt(a)
        val t=BigInt(b)
        eqv(Patch03DistanceWrapper.distancePatch(c,t)-LegacyDistanceAdapter.oldDistance(c,t),
          BigInt(1),"Delta")
      }
    }

    check("simmetria normativa della distanza") {
      for(a <- -50 to 50; b <- -50 to 50) {
        val c=BigInt(a)
        val t=BigInt(b)
        eqv(Patch03DistanceWrapper.distancePatch(c,t),
          Patch03DistanceWrapper.distancePatch(t,c),"Simmetria")
      }
    }

    check("invarianza per traslazione di 8192 bit") {
      val shift=(BigInt(1)<<8192)+343
      for(a <- -20 to 20; b <- -20 to 20) {
        val expected=Patch03DistanceWrapper.distancePatch(BigInt(a),BigInt(b))
        eqv(Patch03DistanceWrapper.distancePatch(BigInt(a)+shift,BigInt(b)+shift),
          expected,"Traslazione")
      }
    }

    check("interi arbitrari firmati oltre sedicimila bit") {
      Vector(257,1024,8192,16384).foreach { bits =>
        val x=(BigInt(1)<<bits)+97531
        Vector((x,-x),(-x,x),(x,x),(x+1,x),(-x-1,x)).foreach { case (c,t) =>
          eqv(Patch03DistanceWrapper.distancePatch(c,t),
            NormativeOracle.workCounts(c,t).distance,"BigInt "+bits)
        }
      }
    }

    check("1024 coppie pseudo casuali deterministiche") {
      val random=new Random(20261011L)
      (1 to 1024).foreach { k =>
        val a=(BigInt(1)<<(random.nextInt(4096)+1))+BigInt(random.nextLong())
        val b=(BigInt(1)<<(random.nextInt(4096)+1))+BigInt(random.nextLong())
        val c=if(k%2==0)a else -a
        val t=if(k%3==0)b else -b
        eqv(Patch03DistanceWrapper.distancePatch(c,t),
          NormativeOracle.workCounts(c,t).distance,"Campione "+k)
      }
    }

    check("manager dispatcher e handler legacy e patch eseguiti realmente") {
      val m=new BaseMonsterManager
      val r=m.patch03Distance(F,F+7)
      eqv(r.calculationDay,F,"Input 1")
      eqv(r.targetDay,F+7,"Input 2")
      eqv(r.legacyDistance,BigInt(7),"Legacy")
      eqv(r.patchedDistance,BigInt(8),"Patched")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_03_DISTANCE","Fase")
      eqv(r.status,"PATCH_03_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_03_DISTANCE","PATCH_03_DISTANCE"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery03.distance.calls"),BigInt(1),"Legacy reale")
      eqv(m.metricsSnapshot("patch03.distance.calls"),BigInt(1),"Patch reale")
    }

    check("diagnostica storica resta RED dopo la correzione") {
      val m=new BaseMonsterManager
      val old=m.discover03Distance(F,F)
      val repaired=m.patch03Distance(F,F)
      eqv(old.legacyDistance,BigInt(0),"Diagnostico")
      eqv(repaired.legacyDistance,old.legacyDistance,"Cicatrice")
      eqv(repaired.patchedDistance,BigInt(1),"Normativa")
      eqv(old.trace,Vector("BOOT","DISCOVERY_03_DISTANCE"),"Traccia")
      eqv(m.metricsSnapshot("discovery03.distance.calls"),BigInt(2),"Handler due volte")
    }

    check("stato semantico isolato e report immutabili per invocazione") {
      val m=new BaseMonsterManager
      val a=m.patch03Distance(5,5)
      val b=m.patch03Distance(-100,100)
      eqv(a.legacyDistance,BigInt(0),"Legacy a")
      eqv(a.patchedDistance,BigInt(1),"Patch a")
      eqv(b.legacyDistance,BigInt(200),"Legacy b")
      eqv(b.patchedDistance,BigInt(201),"Patch b")
      eqv(a.targetDay,BigInt(5),"Snapshot")
      eqv(a.trace,b.trace,"Tracce")
      eqv(m.metricsSnapshot("patch03.distance.calls"),BigInt(2),"Contatore")
    }

    check("validator rifiuta flag traccia output e delta errati") {
      val v=new BaseValidationManager
      val c=BaseMonsterContext(1,2)
      c.phase="PATCH_03_DISTANCE"
      c.status="PATCH_03_READY"
      c.patch03Applied=true
      reject("Manca output") { v.requirePatch03Ready(c) }
      c.legacyDistanceOutput=Some(1)
      c.patchedDistanceOutput=Some(2)
      reject("Manca traccia") { v.requirePatch03Ready(c) }
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_03_DISTANCE","PATCH_03_DISTANCE"))
      v.requirePatch03Ready(c)
      c.patchedDistanceOutput=Some(1)
      reject("Delta sbagliato") { v.requirePatch03Ready(c) }
      c.patchedDistanceOutput=Some(2)
      c.patch03Applied=false
      reject("Flag falso") { v.requirePatch03Ready(c) }
      c.patch03Applied=true
      c.legacyDistanceOutput=Some(-1)
      reject("Legacy negativo") { v.requirePatch03Ready(c) }
    }

    check("handler non permette di saltare né ripetere la discovery") {
      val m=new BaseMetricsShell
      val handler=new Patch03DistanceHandler(m)
      reject("Nessun bootstrap") { handler.handle(BaseMonsterContext(1,2)) }
      val forged=BaseMonsterContext(1,2)
      forged.status="LEGACY_DISTANCE_READY"
      forged.legacyDistanceOutput=Some(1)
      reject("Traccia mancante") { handler.handle(forged) }
      truth(forged.patchedDistanceOutput.isEmpty && !forged.patch03Applied,
        "Nessun effetto dopo rifiuto")
      val valid=BaseMonsterContext(1,2)
      valid.status="BOOTSTRAPPED"
      valid.branchTrace.append("BOOT")
      new Discovery03DistanceHandler(m).handle(valid)
      valid.phase="PATCH_03_DISTANCE"
      handler.handle(valid)
      reject("Handler doppio") { handler.handle(valid) }
    }

    check("dispatcher rifiuta fasi doppie") {
      val m=new BaseMetricsShell
      var rejected=false
      try new BaseMonsterDispatcher(Vector(new BaseBootstrapHandler(m),
        new BaseBootstrapHandler(m))) catch {
        case _: IllegalArgumentException => rejected=true
      }
      truth(rejected,"Dispatcher duplicato")
    }

    check("PATCH 01 ed errore SAVE storici preservati") {
      val m=new BaseMonsterManager
      val modulo=NormativeOracle.M
      eqv(m.discover01Remainder(1,2,modulo).legacyOutput,BigInt(0),"Scar 01")
      eqv(m.patch01Save(1,2,modulo).patchedOutput,modulo,"Patch 01")
    }

    check("PATCH 02 ed errore di Fondazione storici preservati") {
      val m=new BaseMonsterManager
      eqv(m.discover02DayTag(F,F,F).legacyTag,BigInt(0),"Scar 02")
      eqv(m.patch02DayTag(F,F,F).patchedTag,BigInt(1),"Patch 02")
    }

    check("oracolo fuori da produzione e nessuna logica Stage08") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val code=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!code.contains("NormativeOracle"),"Oracolo test-only")
      truth(code.contains("LegacyDistanceAdapter.oldDistance(calculationDay, targetDay) + 1"),
        "Il wrapper deve usare il legacy reale")
      val state = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE assente"))
      if (currentStage < 8)
        truth(!code.contains("mutateStonesWrong"),"DISCOVERY 04 prematura")
      else
        truth(code.contains("mutateStonesWrong"),"DISCOVERY 04 deve essere presente")
    }

    check("metadati PATCH 03 verdi e ordine dei certificati") {
      val stage=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = stage.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE assente"))
      truth(currentStage >= 7,"PATCH 03 deve esistere dagli stadi successivi")
      if (currentStage == 7) {
        truth(stage.contains("CURRENT_KIND=PATCH"),"Tipo")
        truth(stage.contains("CURRENT_PATCH=03"),"Patch")
        truth(stage.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"Stato")
      } else {
        truth(stage.contains("STAGE_07_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_20_PASS_0_FAIL"),
          "Certificazione storica della PATCH 03 conservata")
      }
      val last=stage.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("Ultimo stadio non dichiarato"))
      truth(last >= 6 && last <= currentStage,"Ordine di completamento preservato")
    }

    println("\nRISULTATO STADIO 7: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
