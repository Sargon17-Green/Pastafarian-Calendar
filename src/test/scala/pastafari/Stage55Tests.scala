package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.util.Random

/** PATCH27: oracle test-only su prefissi; validator di produzione usa
  * un terzo algoritmo, non questo oracle e non il wrapper.
  */
object Stage55Tests {
  private var passed=0
  private var failed=0
  private val Nine=Vector.fill(9)(42)
  private val Part=Vector(2,1,2,1,1,2)
  private val Huge=(BigInt(1)<<16384)+55
  private def check(label:String)(body: => Unit):Unit={
    try{body;passed+=1;println("PASS — "+label)}
    catch{case e:Throwable=>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)
    }
  }
  private def eqv[A](actual:A,expected:A,label:String):Unit={
    if(actual!=expected)throw new AssertionError(
      label+": atteso="+expected+", ottenuto="+actual)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(body: => Unit):Unit={
    var caught=false
    try body catch{
      case _:IllegalArgumentException=>caught=true
      case e:WrappedMonsterError if
        e.getCause.isInstanceOf[IllegalArgumentException]=>caught=true
    }
    truth(caught,label)
  }
  private def rejectState(label:String)(body: => Unit):Unit={
    var caught=false
    try body catch{case _:IllegalStateException=>caught=true}
    truth(caught,label)
  }
  private def oracle(g:Vector[Int],p:Vector[Int],c:Int):Int={
    val prefix=p.scanLeft(0)(_+_)
    val first=prefix(c-1)
    val last=prefix(c)
    var result=0
    for(k<-first until last)result+=g(k)
    result
  }
  private def run(g:Vector[Int]=Nine,p:Vector[Int]=Part,c:Int=1):
      Patch27CutletSpanReport=
    new BaseMonsterManager().patch27CutletSpan(Huge,-Huge,g,p,c)
  private def ready():BaseMonsterContext={
    val ctx=BaseMonsterContext(Huge,-Huge)
    ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
    ctx.cutletSpanGaps=Some(Nine)
    ctx.cutletSpanPartition=Some(Part)
    ctx.cutletSpanIndex=Some(3)
    ctx.phase="DISCOVERY_27_CUTLET_SPAN"
    val metrics=new BaseMetricsShell
    new Discovery27CutletSpanHandler(metrics).handle(ctx)
    new BaseValidationManager().requireDiscovery27Ready(ctx)
    ctx.phase="PATCH_27_CUTLET_SPAN"
    new Patch27CutletSpanHandler(metrics).handle(ctx)
    ctx
  }
  def main(args:Array[String]):Unit={
    check("sei cotolette valori normativi"){
      eqv((1 to 6).map(c=>run(c=c).correctedSpan).toVector,
        Vector(84,42,84,42,42,84),"Sei valori")
    }
    check("somma lunghezze anno 378"){
      eqv((1 to 6).map(c=>run(c=c).correctedSpan).sum,378,"Anno")
    }
    check("CUTLET1 corretto 84"){eqv(run(c=1).correctedSpan,84,"1")}
    check("CUTLET3 corretto 84"){eqv(run(c=3).correctedSpan,84,"3")}
    check("CUTLET6 corretto 84"){eqv(run(c=6).correctedSpan,84,"6")}
    check("cotolette singole 2,4,5"){
      for(c<-Vector(2,4,5))eqv(run(c=c).correctedSpan,42,"Single "+c)
    }
    check("cicatrice legacy invariata"){
      for(c<-1 to 6)eqv(run(c=c).legacySpan,42,"Legacy "+c)
    }
    check("report conserva divergenza storica"){
      val r=run(c=3);eqv((r.legacySpan,r.correctedSpan),(42,84),"Scar")
    }
    check("sei porte sei cotolette minimo"){
      val g=Vector.fill(6)(42);val p=Vector.fill(6)(1)
      for(c<-1 to 6)eqv(run(g,p,c).correctedSpan,42,"Minimum "+c)
    }
    check("sei porte anno massimo 5778"){
      val g=Vector.fill(6)(963);val p=Vector.fill(6)(1)
      for(c<-1 to 6)eqv(run(g,p,c).correctedSpan,963,"Maximum "+c)
    }
    check("quarantasette porte diciassette cotolette"){
      val g=Vector.fill(47)(42);val p=Vector.fill(16)(1) :+ 31
      eqv(run(g,p,17).correctedSpan,1302,"Ultima")
      eqv(run(g,p,17).legacySpan,42,"Scar")
    }
    check("partizione diversa modifica norma non legacy"){
      val alt=Vector(1,2,1,2,1,2)
      truth(oracle(Nine,Part,1)!=oracle(Nine,alt,1),"Metamorfismo")
      eqv(run(p=alt).legacySpan,run().legacySpan,"Legacy")
      eqv(run(p=alt).correctedSpan,oracle(Nine,alt,1),"Norma")
    }
    check("2048 partizioni seminate indipendenti"){
      val rng=new Random(55202026L)
      var multi=0
      for(i<-1 to 2048){
        val c=6+rng.nextInt(12)
        val n=c+rng.nextInt(48-c)
        val groups=Array.fill(c)(1)
        for(k<-0 until n-c)groups(rng.nextInt(c))+=1
        val p=groups.toVector
        val g=Vector.fill(n)(42+rng.nextInt(59))
        val index=1+rng.nextInt(c)
        val r=run(g,p,index)
        eqv(r.correctedSpan,oracle(g,p,index),"Sample "+i)
        eqv(r.legacySpan,g(index-1),"Scar "+i)
        eqv((1 to c).map(j=>oracle(g,p,j)).sum,g.sum,"Partition "+i)
        if(p(index-1)>1)multi+=1
      }
      truth(multi>0,"Campioni multi-gate")
    }
    check("snapshot di input e BigInt"){
      val r=run(c=3)
      eqv((r.calculationDay,r.targetDay),(Huge,-Huge),"BigInt")
      eqv((r.gateGaps,r.cutletPartition,r.cutletIndex),(Nine,Part,3),"Input")
    }
    check("trace e status patch"){
      val r=run()
      eqv(r.trace,Vector("BOOT","DISCOVERY_27_CUTLET_SPAN",
        "PATCH_27_CUTLET_SPAN"),"Trace")
      eqv(r.phase,"PATCH_27_CUTLET_SPAN","Phase")
      eqv(r.status,"PATCH_27_READY","Status")
      truth(r.patchApplied,"Flag")
    }
    check("metriche bootstrap discovery patch"){
      val m=new BaseMonsterManager
      m.patch27CutletSpan(1,2,Nine,Part,1)
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery27.cutlet.span.calls"),BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch27.cutlet.span.calls"),BigInt(1),"Patch")
    }
    check("manager indipendenti"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      for(i<-1 to 20)(if(i%2==0)a else b).
        patch27CutletSpan(i,-Huge,Nine,Part,1)
      eqv(a.metricsSnapshot("patch27.cutlet.span.calls"),BigInt(10),"A")
      eqv(b.metricsSnapshot("patch27.cutlet.span.calls"),BigInt(10),"B")
    }
    check("report immutabile"){
      val m=new BaseMonsterManager
      val r=m.patch27CutletSpan(1,2,Nine,Part,1)
      val frozen=r.copy()
      m.patch27CutletSpan(3,4,Nine,Part,6)
      eqv(r,frozen,"Report")
    }
    check("discovery27 resta interrogabile"){
      val r=new BaseMonsterManager().discover27CutletSpan(1,2,Nine,Part,3)
      eqv(r.legacySpan,42,"Legacy")
      eqv(r.trace,Vector("BOOT","DISCOVERY_27_CUTLET_SPAN"),"Trace")
    }
    check("rifiuta cinque o diciotto cotolette"){
      rejectArg("5"){run(Vector.fill(6)(42),Vector(2,1,1,1,1),1)}
      rejectArg("18"){run(Vector.fill(18)(42),Vector.fill(18)(1),1)}
    }
    check("rifiuta cinque o quarantotto gate"){
      rejectArg("5"){run(Vector.fill(5)(42),Vector.fill(5)(1),1)}
      rejectArg("48"){run(Vector.fill(48)(42),Vector.fill(6)(8),1)}
    }
    check("rifiuta gap 41 o 964"){
      rejectArg("41"){run(Nine.updated(0,41),Part,1)}
      rejectArg("964"){run(Nine.updated(0,964),Part,1)}
    }
    check("rifiuta anno e partizione incompleta"){
      rejectArg("5779"){run(Vector.fill(7)(963),Vector(2,1,1,1,1,1),1)}
      rejectArg("Incomplete"){run(Nine,Vector.fill(6)(1),1)}
    }
    check("rifiuta gruppo zero"){
      rejectArg("Zero"){run(Nine,Vector(3,0,1,1,2,2),1)}
    }
    check("rifiuta indici 0 e 7"){
      rejectArg("0"){run(c=0)}
      rejectArg("7"){run(c=7)}
    }
    check("validator autonomo accetta patch"){
      new BaseValidationManager().requirePatch27Ready(ready())
    }
    check("validator rifiuta lunghezza falsificata"){
      val ctx=ready();ctx.patch27CorrectedLength=Some(42)
      rejectState("Correct"){new BaseValidationManager().requirePatch27Ready(ctx)}
    }
    check("validator rifiuta legacy falsificato"){
      val ctx=ready();ctx.cutletSpanLegacyLength=Some(84)
      rejectState("Legacy"){new BaseValidationManager().requirePatch27Ready(ctx)}
    }
    check("validator rifiuta snapshot falsificata"){
      val ctx=ready();ctx.cutletSpanPartition=Some(Vector(1,2,1,2,1,2))
      rejectState("Snapshot"){new BaseValidationManager().requirePatch27Ready(ctx)}
    }
    check("validator rifiuta trace falsificata"){
      val ctx=ready();ctx.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager().requirePatch27Ready(ctx)}
    }
    check("validator rifiuta status falsificato"){
      val ctx=ready();ctx.status="LEGACY_CUTLET_SPAN_READY"
      rejectState("Status"){new BaseValidationManager().requirePatch27Ready(ctx)}
    }
    check("validator rifiuta flag mancante"){
      val ctx=ready();ctx.patch27Applied=false
      rejectState("Flag"){new BaseValidationManager().requirePatch27Ready(ctx)}
    }
    check("handler evita pubblicazione dopo mutazione"){
      val ctx=BaseMonsterContext(1,2)
      ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
      ctx.cutletSpanGaps=Some(Nine);ctx.cutletSpanPartition=Some(Part)
      ctx.cutletSpanIndex=Some(1);ctx.phase="DISCOVERY_27_CUTLET_SPAN"
      new Discovery27CutletSpanHandler(new BaseMetricsShell).handle(ctx)
      ctx.phase="PATCH_27_CUTLET_SPAN";ctx.cutletSpanIndex=Some(2)
      rejectState("Mutazione"){
        new Patch27CutletSpanHandler(new BaseMetricsShell).handle(ctx)
      }
      truth(ctx.patch27CorrectedLength.isEmpty && !ctx.patch27Applied,"Atomicita")
    }
    check("nessuna regressione Stage54 e Stage53"){
      var root=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
      while(!Files.exists(root.resolve("DEVELOPMENT_STAGE.md")) &&
            root.getParent!=null)root=root.getParent
      val st=new String(Files.readAllBytes(root.resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("STAGE_54_NATIVE_VERIFICATION=PASS_EXPECTED_RED_29_PASS_3_FAIL"),"54")
      truth(st.contains("STAGE_53_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_42_PASS_0_FAIL"),"53")
      truth(st.contains("CURRENT_STAGE=55") && st.contains("CURRENT_PATCH=27") &&
        st.contains("LAST_COMPLETED_STAGE=54"),"55")
    }
    println("\nRISULTATO STADIO 55: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
