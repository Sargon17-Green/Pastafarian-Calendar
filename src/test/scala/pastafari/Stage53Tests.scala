package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.util.Random

/** PATCH26: corregge la proiezione gate -> cotoletta e conserva il legacy. */
object Stage53Tests {
  private var passed=0
  private var failed=0
  private val Nine=Vector.fill(9)(42)
  private val Part=Vector(2,1,2,1,1,2)
  private val Huge=(BigInt(1)<<16384)+53
  private def check(label:String)(f: => Unit):Unit={
    try{f;passed+=1;println("PASS — "+label)}
    catch{case e:Throwable=>failed+=1;println("FAIL — "+label+" — "+e.getMessage);e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(b:Boolean,label:String):Unit={if(!b)throw new AssertionError(label)}
  private def rejectArg(label:String)(f: => Unit):Unit={
    var denied=false
    try f catch{case _:IllegalArgumentException=>denied=true}
    truth(denied,label)
  }
  private def rejectState(label:String)(f: => Unit):Unit={
    var denied=false
    try f catch{case _:IllegalStateException=>denied=true}
    truth(denied,label)
  }
  private def patch(g:Vector[Int]=Nine,p:Vector[Int]=Part,d:Int=42):
      Patch26GateToCutletProjectionResult=
    Patch26GateToCutletProjectionWrapper.gateToCutletPatch(g,p,d)
  // Test-only oracle: procedura diversa dal wrapper, nessuna dipendenza production.
  private def oracle(g:Vector[Int],p:Vector[Int],d:Int):(Int,Int)={
    var start=0;var gate=0
    for((n,i)<-p.zipWithIndex){
      var length=0
      for(k<-0 until n)length+=g(gate+k)
      if(d>=start && d<start+length)return (i+1,d-start+1)
      start+=length
      gate+=n
    }
    throw new AssertionError("Oracolo: giorno non trovato")
  }
  private def ready():BaseMonsterContext={
    val ctx=BaseMonsterContext(Huge,-Huge)
    ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
    ctx.gateProjectionGaps=Some(Nine)
    ctx.gateProjectionPartition=Some(Part)
    ctx.gateProjectionDayOffset=Some(42)
    ctx.phase="DISCOVERY_26_GATE_TO_CUTLET_PROJECTION"
    val metrics=new BaseMetricsShell
    new Discovery26GateToCutletProjectionHandler(metrics).handle(ctx)
    new BaseValidationManager().requireDiscovery26Ready(ctx)
    ctx.phase="PATCH_26_GATE_TO_CUTLET_PROJECTION"
    new Patch26GateToCutletProjectionHandler(metrics).handle(ctx)
    ctx
  }
  def main(args:Array[String]):Unit={
    check("primo giorno cotoletta uno"){
      eqv((patch(d=0).correctedCutletId,patch(d=0).correctedDayInCutlet),(1,1),"Inizio")
    }
    check("ultimo giorno gate uno nella prima cotoletta"){
      eqv((patch(d=41).correctedCutletId,patch(d=41).correctedDayInCutlet),(1,42),"Confine")
    }
    check("gate due appartiene alla prima cotoletta"){
      eqv((patch(d=42).correctedCutletId,patch(d=42).correctedDayInCutlet),(1,43),"GATE2")
    }
    check("ultimo giorno della prima cotoletta"){
      eqv((patch(d=83).correctedCutletId,patch(d=83).correctedDayInCutlet),(1,84),"Fine")
    }
    check("gate tre apre la seconda cotoletta"){
      eqv((patch(d=84).correctedCutletId,patch(d=84).correctedDayInCutlet),(2,1),"Seconda")
    }
    check("gate cinque appartiene alla terza cotoletta"){
      eqv((patch(d=168).correctedCutletId,patch(d=168).correctedDayInCutlet),(3,43),"GATE5")
    }
    check("gate nove appartiene alla sesta cotoletta"){
      eqv((patch(d=336).correctedCutletId,patch(d=336).correctedDayInCutlet),(6,43),"GATE9")
    }
    check("ultimo giorno del calendario"){
      eqv((patch(d=377).correctedCutletId,patch(d=377).correctedDayInCutlet),(6,84),"Fine")
    }
    check("legacy GATE2 conservato"){
      val r=patch(d=42);eqv((r.historical.legacyCutletId,r.historical.legacyDayInCutlet),(2,1),"Scar")
    }
    check("legacy GATE5 conservato"){
      val r=patch(d=168);eqv((r.historical.legacyCutletId,r.historical.legacyDayInCutlet),(5,1),"Scar")
    }
    check("legacy GATE9 conservato"){
      val r=patch(d=336);eqv((r.historical.legacyCutletId,r.historical.legacyDayInCutlet),(9,1),"Scar")
    }
    check("legacy non modificato dal wrapper"){
      for(d<-0 until Nine.sum by 7)
        eqv(patch(d=d).historical,
          LegacyGateToCutletProjectionAdapter.oldGateToCutletProjection(Nine,Part,d),"Scar "+d)
    }
    check("tutti i 378 giorni e confini"){
      for(d<-0 until Nine.sum){
        val r=patch(d=d)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),oracle(Nine,Part,d),"Giorno "+d)
      }
    }
    check("sei gate e sei cotolette singole"){
      val g=Vector.fill(6)(42);val p=Vector.fill(6)(1)
      for(d<-0 until g.sum)eqv((patch(g,p,d).correctedCutletId,
        patch(g,p,d).correctedDayInCutlet),oracle(g,p,d),"Giorno "+d)
    }
    check("diciassette cotolette e quarantasette gate"){
      val g=Vector.fill(47)(42);val p=Vector(8,8,8,8,8,7)
      for(d<-0 until g.sum by 11)
        eqv((patch(g,p,d).correctedCutletId,patch(g,p,d).correctedDayInCutlet),
          oracle(g,p,d),"Giorno "+d)
    }
    check("anno massimo 5778 giorni"){
      val g=Vector.fill(6)(963);val p=Vector.fill(6)(1)
      for(d<-Vector(0,962,963,5776,5777))
        eqv((patch(g,p,d).correctedCutletId,patch(g,p,d).correctedDayInCutlet),
          oracle(g,p,d),"Massimo "+d)
    }
    check("2048 partizioni deterministiche"){
      val rng=new Random(53202026L)
      for(i<-1 to 2048){
        val n=6+rng.nextInt(12)
        val extra=rng.nextInt(48-n)
        val group=rng.nextInt(n)
        val p=Vector.fill(n)(1).updated(group,1+extra)
        val g=Vector.fill(n+extra)(42+rng.nextInt(31))
        val day=rng.nextInt(g.sum)
        val r=patch(g,p,day)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),oracle(g,p,day),"Input "+i)
      }
    }
    check("metamorfismo: partizione diversa cambia la proiezione"){
      val p2=Vector(1,1,1,1,1,4)
      truth(oracle(Nine,Part,168)!=oracle(Nine,p2,168),"Partizione")
      eqv(patch(Nine,Part,168).historical,patch(Nine,p2,168).historical.copy(
        cutletPartition=Part),"Cicatrice per gate")
    }
    check("input snapshot e BigInt conservati"){
      val r=new BaseMonsterManager().patch26GateToCutletProjection(Huge,-Huge,Nine,Part,42)
      eqv((r.calculationDay,r.targetDay),(Huge,-Huge),"BigInt")
      eqv((r.gateGaps,r.cutletPartition,r.dayOffset),(Nine,Part,42),"Snapshot")
    }
    check("trace e status di tre fasi"){
      val r=new BaseMonsterManager().patch26GateToCutletProjection(1,2,Nine,Part,42)
      eqv(r.trace,Vector("BOOT","DISCOVERY_26_GATE_TO_CUTLET_PROJECTION",
        "PATCH_26_GATE_TO_CUTLET_PROJECTION"),"Trace")
      eqv(r.status,"PATCH_26_READY","Status")
      truth(r.patchApplied,"Flag")
    }
    check("metriche per tre fasi"){
      val m=new BaseMonsterManager
      m.patch26GateToCutletProjection(1,2,Nine,Part,42)
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery26.gate.cutlet.calls"),BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch26.gate.cutlet.calls"),BigInt(1),"Patch")
    }
    check("manager separati isolati"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      for(i<-1 to 100)(if(i%2==0)a else b).patch26GateToCutletProjection(
        i,-Huge,Nine,Part,i%378)
      eqv(a.metricsSnapshot("patch26.gate.cutlet.calls"),BigInt(50),"A")
      eqv(b.metricsSnapshot("patch26.gate.cutlet.calls"),BigInt(50),"B")
    }
    check("report gia emesso non muta"){
      val m=new BaseMonsterManager
      val r=m.patch26GateToCutletProjection(1,2,Nine,Part,42)
      val frozen=r.copy()
      m.patch26GateToCutletProjection(3,4,Nine,Part,336)
      eqv(r,frozen,"Report")
    }
    check("scoperta storica interrogabile separatamente"){
      val r=new BaseMonsterManager().discover26GateToCutletProjection(1,2,Nine,Part,42)
      eqv((r.legacyCutletId,r.legacyDayInCutlet),(2,1),"Legacy")
    }
    check("rifiuta meno di sei cotolette"){
      rejectArg("Cinque"){patch(Vector.fill(6)(42),Vector(2,1,1,1,1),42)}
    }
    check("rifiuta piu di diciassette cotolette"){
      rejectArg("Diciotto"){patch(Vector.fill(18)(42),Vector.fill(18)(1),42)}
    }
    check("rifiuta quarantotto gate"){
      rejectArg("48"){patch(Vector.fill(48)(42),Vector.fill(6)(8),42)}
    }
    check("rifiuta gap troppo corto"){
      rejectArg("41"){patch(Nine.updated(0,41),Part,42)}
    }
    check("rifiuta gap troppo lungo"){
      rejectArg("964"){patch(Nine.updated(0,964),Part,42)}
    }
    check("rifiuta partizione incompleta"){
      rejectArg("Partizione"){patch(Nine,Vector(1,1,1,1,1,1),42)}
    }
    check("rifiuta partizione zero"){
      rejectArg("Zero"){patch(Nine,Vector(3,0,1,1,2,2),42)}
    }
    check("rifiuta giorno negativo"){
      rejectArg("Negativo"){patch(d = -1)}
    }
    check("rifiuta giorno fuori dall'anno"){
      rejectArg("Fine"){patch(d = 378)}
    }
    check("validator indipendente accetta PATCH26"){
      new BaseValidationManager().requirePatch26Ready(ready())
    }
    check("validator rifiuta cutlet falsificata"){
      val c=ready();c.patch26CutletId=Some(2)
      rejectState("ID"){new BaseValidationManager().requirePatch26Ready(c)}
    }
    check("validator rifiuta giorno locale falsificato"){
      val c=ready();c.patch26DayInCutlet=Some(1)
      rejectState("Ordinal"){new BaseValidationManager().requirePatch26Ready(c)}
    }
    check("validator rifiuta legacy falsificato"){
      val c=ready();c.gateProjectionLegacyGateId=Some(3)
      rejectState("Scar"){new BaseValidationManager().requirePatch26Ready(c)}
    }
    check("validator rifiuta snapshot alterata"){
      val c=ready();c.gateProjectionDayOffset=Some(43)
      rejectState("Snapshot"){new BaseValidationManager().requirePatch26Ready(c)}
    }
    check("validator rifiuta trace alterata"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager().requirePatch26Ready(c)}
    }
    check("validator rifiuta flag patch mancante"){
      val c=ready();c.patch26Applied=false
      rejectState("Flag"){new BaseValidationManager().requirePatch26Ready(c)}
    }
    check("handler richiede discovery e non pubblica su input mutato"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.gateProjectionGaps=Some(Nine);c.gateProjectionPartition=Some(Part)
      c.gateProjectionDayOffset=Some(42)
      c.phase="DISCOVERY_26_GATE_TO_CUTLET_PROJECTION"
      new Discovery26GateToCutletProjectionHandler(new BaseMetricsShell).handle(c)
      c.phase="PATCH_26_GATE_TO_CUTLET_PROJECTION"
      c.gateProjectionDayOffset=Some(43)
      rejectState("Mutazione"){new Patch26GateToCutletProjectionHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patch26CutletId.isEmpty && !c.patch26Applied,"Atomicita")
    }
    check("Stage52 resta EXPECTED_RED e PATCH26 presente"){
      var root=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
      while(!Files.exists(root.resolve("DEVELOPMENT_STAGE.md")) && root.getParent!=null)
        root=root.getParent
      val st=new String(Files.readAllBytes(root.resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("STAGE_52_NATIVE_VERIFICATION=PASS_EXPECTED_RED_44_PASS_3_FAIL"),"Stage52")
      truth(st.contains("CURRENT_STAGE=53"),"Stage53")
      truth(st.contains("CURRENT_PATCH=26"),"PATCH26")
    }
    println("\nRISULTATO STADIO 53: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
