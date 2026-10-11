package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.file.{Files, Paths}
import java.nio.charset.StandardCharsets
import scala.jdk.CollectionConverters._

/** DISCOVERY 05: l'errore i-6 al posto di i-7 resta deliberatamente RED. */
object Stage10Tests {
  private var passed=0
  private var failed=0
  private val H=Vector[BigInt](101,202,303,404,505,606,707)
  private val V=Vector.tabulate[BigInt](46)(i=>BigInt(2000+i))
  private val F=NormativeOracle.FoundationDay

  private def check(name:String)(f: => Unit):Unit = try {
    f; passed+=1; println("PASS — "+name)
  } catch {
    case e:Throwable =>
      failed+=1; println("FAIL — "+name+" — "+e.getMessage)
      e.printStackTrace(System.out)
  }
  private def eqv[A](got:A, expected:A, name:String):Unit =
    if(got!=expected)throw new AssertionError(name+": atteso="+expected+", ottenuto="+got)
  private def truth(v:Boolean,name:String):Unit =
    if(!v)throw new AssertionError(name)
  private def rejectArg(name:String)(f: => Unit):Unit = {
    var rejected=false
    try f catch { case _:IllegalArgumentException=>rejected=true }
    truth(rejected,name)
  }
  private def rejectState(name:String)(f: => Unit):Unit = {
    var rejected=false
    try f catch { case _:IllegalStateException=>rejected=true }
    truth(rejected,name)
  }
  private def canonical(h:Vector[BigInt],v:Vector[BigInt],i:Int,lag:Int):BigInt = {
    val k=i-lag
    if(k<=0)h(-k) else v(k-1)
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice mancante")
    p
  }

  def main(args:Array[String]):Unit = {
    check("le sette gocce nascoste hanno indici zero fino a meno sei") {
      eqv(LegacyPriorAdapter.legacyPrior(H,Vector.empty,1,1),H(0),"Indice zero")
      eqv(canonical(H,V,1,7),H(6),"Indice meno sei")
    }
    check("ritardo uno normativo per tutte le 47 posizioni") {
      (1 to 47).foreach { i =>
        eqv(LegacyPriorAdapter.legacyPrior(H,V.take(i-1),i,1),
          canonical(H,V,i,1),"posizione "+i)
      }
    }
    check("ritardo tre normativo per tutte le 47 posizioni") {
      (1 to 47).foreach { i =>
        eqv(LegacyPriorAdapter.legacyPrior(H,V.take(i-1),i,3),
          canonical(H,V,i,3),"posizione "+i)
      }
    }
    check("il ritardo sette legge esattamente i-6 per ogni posizione") {
      (1 to 47).foreach { i =>
        eqv(LegacyPriorAdapter.legacyPrior(H,V.take(i-1),i,7),
          canonical(H,V,i,6),"indice legacy "+i)
      }
    }
    check("le tre finestre di confine riproducono il difetto storico") {
      eqv(LegacyPriorAdapter.legacyPrior(H,Vector.empty,1,7),H(5),"goccia 1")
      eqv(LegacyPriorAdapter.legacyPrior(H,V.take(6),7,7),V(0),"goccia 7")
      eqv(LegacyPriorAdapter.legacyPrior(H,V,47,7),V(40),"goccia 47")
      truth(H(5)!=H(6),"Valori nascosti distinti")
    }
    check("valori BigInt oltre sedicimila bit restano esatti") {
      val big=(BigInt(1)<<16384)+13
      val h=Vector.tabulate[BigInt](7)(i=>big+i)
      val v=Vector.tabulate[BigInt](46)(i => -big - i)
      eqv(LegacyPriorAdapter.legacyPrior(h,v.take(18),19,7),v(12),"Grande lag7")
      eqv(LegacyPriorAdapter.legacyPrior(h,v.take(18),19,3),v(15),"Grande lag3")
    }
    check("finestra nascosta non esattamente di sette rifiutata") {
      rejectArg("Sei nascosti") { LegacyPriorAdapter.legacyPrior(H.take(6),Vector.empty,1,7) }
      rejectArg("Otto nascosti") { LegacyPriorAdapter.legacyPrior(H:+BigInt(808),Vector.empty,1,7) }
    }
    check("gocce visibili future o mancanti rifiutate") {
      rejectArg("Future") { LegacyPriorAdapter.legacyPrior(H,V.take(1),1,7) }
      rejectArg("Mancanti") { LegacyPriorAdapter.legacyPrior(H,V.take(10),12,7) }
    }
    check("indici temporali fuori 1..47 rifiutati") {
      Vector(-1,0,48).foreach(i=>rejectArg("Indice "+i) {
        LegacyPriorAdapter.legacyPrior(H,Vector.empty,i,7)
      })
    }
    check("solo ritardi uno tre sette ammessi") {
      Vector(-1,0,2,4,6,8).foreach(lag=>rejectArg("Lag "+lag) {
        LegacyPriorAdapter.legacyPrior(H,Vector.empty,1,lag)
      })
    }
    check("manager attraversa il vero handler legacy e produce traccia") {
      val m=new BaseMonsterManager
      val r=m.discover05Prior(11,22,H,V.take(6),7,7)
      eqv(r.legacyValue,V(0),"Lettura errata")
      eqv(r.index,7,"Indice")
      eqv(r.lag,7,"Ritardo")
      eqv(r.calculationDay,BigInt(11),"Calcolo")
      eqv(r.targetDay,BigInt(22),"Domanda")
      eqv(r.hiddenDrops,H,"Input nascosti")
      eqv(r.visibleDropsSoFar,V.take(6),"Input visibili")
      eqv(r.trace,Vector("BOOT","DISCOVERY_05_PRIOR"),"Traccia")
      eqv(r.status,"LEGACY_PRIOR_READY","Stato")
      eqv(m.metricsSnapshot("discovery05.prior.calls"),BigInt(1),"Handler")
    }
    check("validator rifiuta dati assenti o traccia falsa") {
      val v=new BaseValidationManager
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_05_PRIOR"
      c.status="LEGACY_PRIOR_READY"
      rejectState("Senza input") { v.requireDiscovery05Ready(c) }
      c.priorHiddenInput=Some(H); c.priorVisibleInput=Some(Vector.empty)
      c.priorIndexInput=Some(1); c.priorLagInput=Some(7)
      c.legacyPriorOutput=Some(H(5))
      rejectState("Senza traccia") { v.requireDiscovery05Ready(c) }
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_05_PRIOR"))
      v.requireDiscovery05Ready(c)
      c.priorVisibleInput=Some(V.take(1))
      rejectState("Futuro") { v.requireDiscovery05Ready(c) }
    }
    check("handler rifiuta bypass e risultato preesistente") {
      val handler=new Discovery05PriorHandler(new BaseMetricsShell)
      val c=BaseMonsterContext(1,2)
      rejectState("Senza bootstrap") { handler.handle(c) }
      c.status="BOOTSTRAPPED"
      c.branchTrace.append("BOOT")
      c.priorHiddenInput=Some(H); c.priorVisibleInput=Some(Vector.empty)
      c.priorIndexInput=Some(1); c.priorLagInput=Some(7)
      c.legacyPriorOutput=Some(H(5))
      rejectState("Output doppio") { handler.handle(c) }
      eqv(c.branchTrace.toVector,Vector("BOOT"),"Traccia invariata")
    }
    check("patch precedenti e snapshot fra chiamate restano integri") {
      val m=new BaseMonsterManager
      val a=m.discover05Prior(0,0,H,Vector.empty,1,7)
      val b=m.discover05Prior(3,4,H,V.take(10),11,1)
      eqv(a.legacyValue,H(5),"Snapshot A")
      eqv(b.legacyValue,V(9),"Snapshot B")
      eqv(m.metricsSnapshot("discovery05.prior.calls"),BigInt(2),"Metriche")
      eqv(m.patch01Save(0,0,NormativeOracle.M).patchedOutput,NormativeOracle.M,"PATCH 01")
      eqv(m.patch02DayTag(F,F,F).patchedTag,BigInt(1),"PATCH 02")
      eqv(m.patch03Distance(F,F).patchedDistance,BigInt(1),"PATCH 03")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"PATCH 04")
    }
    check("stadio 10 rosso e nessuna patch futura") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      truth(currentStage >= 10,"La DISCOVERY 05 deve essere disponibile")
      if (currentStage == 10) {
        truth(st.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
        truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"Stato")
      } else {
        truth(st.contains("STAGE_10_NATIVE_VERIFICATION=PASS_EXPECTED_RED_15_PASS_3_FAIL"),
          "La firma RED storica deve rimanere certificata")
      }
      val in=Files.walk(root().resolve("src/main/scala"))
      val content=try in.iterator().asScala.filter(Files.isRegularFile(_))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8)).mkString("\n")
      finally in.close()
      truth(!content.contains("NormativeOracle"),"Oracolo nel prodotto")
      truth(content.contains("LegacyPriorAdapter.legacyPrior("),"Helper reale")
      if (currentStage < 11)
        truth(!content.contains("priorPatch"),"PATCH 05 anticipata")
      else
        truth(content.contains("priorPatch"),"PATCH 05 deve essere presente")
    }

    val counts=NormativeOracle.workCounts(F,F+1)
    val hidden=NormativeOracle.buildHiddenDrops(counts)
    val visible=NormativeOracle.buildVisibleDrops(counts,hidden)
    val m=new BaseMonsterManager
    Vector(("goccia 1",1),("goccia 7",7),("goccia 47",47)).foreach { case (label,i) =>
      check("equivalenza normativa prior7 "+label) {
        val wrong=m.discover05Prior(F,F+1,hidden,visible.take(i-1),i,7).legacyValue
        eqv(wrong,canonical(hidden,visible,i,7),"Cicatrice "+label)
      }
    }
    println("\nRISULTATO STADIO 10: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
