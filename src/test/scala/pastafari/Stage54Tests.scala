package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.util.Random

/** DISCOVERY27: oracolo aggregato indipendente dal legacy. */
object Stage54Tests {
  private var passed=0
  private var failed=0
  private val Nine=Vector.fill(9)(42)
  private val Part=Vector(2,1,2,1,1,2)
  private val Huge=(BigInt(1)<<16384)+54
  private def check(label:String)(body: => Unit):Unit={
    try{body;passed+=1;println("PASS — "+label)}
    catch{case e:Throwable=>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)
    }
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(body: => Unit):Unit={
    var caught=false
    try body catch{case _:IllegalArgumentException=>caught=true}
    truth(caught,label)
  }
  private def rejectState(label:String)(body: => Unit):Unit={
    var caught=false
    try body catch{case _:IllegalStateException=>caught=true}
    truth(caught,label)
  }
  private def oracle(g:Vector[Int],p:Vector[Int],c:Int):Int={
    var start=0
    for(i<-0 until c-1)start+=p(i)
    var span=0
    for(i<-0 until p(c-1))span+=g(start+i)
    span
  }
  private def run(g:Vector[Int]=Nine,p:Vector[Int]=Part,c:Int=1):
      Discovery27CutletSpanReport=
    new BaseMonsterManager().discover27CutletSpan(Huge,-Huge,g,p,c)
  private def ready():BaseMonsterContext={
    val ctx=BaseMonsterContext(Huge,-Huge)
    ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
    ctx.phase="DISCOVERY_27_CUTLET_SPAN"
    ctx.cutletSpanGaps=Some(Nine)
    ctx.cutletSpanPartition=Some(Part)
    ctx.cutletSpanIndex=Some(1)
    new Discovery27CutletSpanHandler(new BaseMetricsShell).handle(ctx)
    ctx
  }
  def main(args:Array[String]):Unit={
    // Atteso: CUTLET1, CUTLET3, CUTLET6 rossi; 2,4,5 verdi.
    for((c,want)<-Vector((1,84),(2,42),(3,84),(4,42),(5,42),(6,84))){
      val label="CUTLET"+c
      check("equivalenza normativa "+label){
        eqv(oracle(Nine,Part,c),want,"Oracle "+label)
        eqv(run(c=c).legacySpan,want,"Assunzione gate singolo: "+label)
      }
    }
    check("oracolo test-only sei lunghezze"){
      eqv((1 to 6).map(c=>oracle(Nine,Part,c)).toVector,
        Vector(84,42,84,42,42,84),"Oracle")
    }
    check("oracolo copre 378 giorni"){
      eqv((1 to 6).map(c=>oracle(Nine,Part,c)).sum,378,"Anno")
    }
    check("cicatrice una porta per gruppo"){
      for(c<-1 to 6)eqv(run(c=c).legacySpan,42,"Scar "+c)
    }
    check("partizione alternativa non altera la cicatrice"){
      val alt=Vector(1,2,1,2,1,2)
      truth(oracle(Nine,Part,1)!=oracle(Nine,alt,1),"Metamorfismo")
      eqv(run(p=alt).legacySpan,run().legacySpan,"Scar")
    }
    check("anno minimo 252"){
      val g=Vector.fill(6)(42);val p=Vector.fill(6)(1)
      for(c<-1 to 6)eqv(run(g,p,c).legacySpan,oracle(g,p,c),"Min")
    }
    check("anno massimo 5778"){
      val g=Vector.fill(6)(963);val p=Vector.fill(6)(1)
      for(c<-1 to 6)eqv(run(g,p,c).legacySpan,oracle(g,p,c),"Max")
      eqv(g.sum,5778,"Anno")
    }
    check("diciassette cotolette quarantasette porte"){
      val p=Vector.fill(16)(1) :+ 31
      val g=Vector.fill(47)(42)
      eqv(p.sum,47,"Gruppi")
      eqv(oracle(g,p,17),1302,"Span")
      eqv(run(g,p,17).legacySpan,42,"Scar")
    }
    check("2048 partizioni deterministiche"){
      val rng=new Random(54202026L)
      var multigate=0
      for(i<-1 to 2048){
        val c=6+rng.nextInt(12)
        val n=c+rng.nextInt(48-c)
        val a=Array.fill(c)(1)
        for(k<-0 until n-c)a(rng.nextInt(c))+=1
        val p=a.toVector
        val g=Vector.fill(n)(42+rng.nextInt(59))
        val index=1+rng.nextInt(c)
        eqv(run(g,p,index).legacySpan,g(index-1),"Legacy "+i)
        eqv((1 to c).map(j=>oracle(g,p,j)).sum,g.sum,"Oracle "+i)
        if(p(index-1)>1)multigate+=1
      }
      truth(multigate>0,"Campioni multi-gate")
    }
    check("BigInt e input snapshot"){
      val r=run(c=3)
      eqv((r.calculationDay,r.targetDay),(Huge,-Huge),"BigInt")
      eqv((r.gateGaps,r.cutletPartition,r.cutletIndex),(Nine,Part,3),"Input")
    }
    check("trace e status"){
      val r=run()
      eqv(r.trace,Vector("BOOT","DISCOVERY_27_CUTLET_SPAN"),"Trace")
      eqv(r.status,"LEGACY_CUTLET_SPAN_READY","Status")
    }
    check("metriche di dispatch"){
      val m=new BaseMonsterManager
      m.discover27CutletSpan(1,2,Nine,Part,1)
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery27.cutlet.span.calls"),BigInt(1),"Stage54")
    }
    check("manager isolati"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      for(i<-1 to 20)(if(i%2==0)a else b).
        discover27CutletSpan(i,-Huge,Nine,Part,1)
      eqv(a.metricsSnapshot("discovery27.cutlet.span.calls"),BigInt(10),"A")
      eqv(b.metricsSnapshot("discovery27.cutlet.span.calls"),BigInt(10),"B")
    }
    check("report immutabile"){
      val m=new BaseMonsterManager
      val r=m.discover27CutletSpan(1,2,Nine,Part,1)
      val snapshot=r.copy()
      m.discover27CutletSpan(3,4,Nine,Part,6)
      eqv(r,snapshot,"Report")
    }
    check("rifiuta cinque cotolette"){
      rejectArg("5"){run(Vector.fill(6)(42),Vector(2,1,1,1,1),1)}
    }
    check("rifiuta diciotto cotolette"){
      rejectArg("18"){run(Vector.fill(18)(42),Vector.fill(18)(1),1)}
    }
    check("rifiuta cinque porte"){
      rejectArg("5"){run(Vector.fill(5)(42),Vector.fill(5)(1),1)}
    }
    check("rifiuta quarantotto porte"){
      rejectArg("48"){run(Vector.fill(48)(42),Vector.fill(6)(8),1)}
    }
    check("rifiuta gap 41"){
      rejectArg("41"){run(Nine.updated(0,41),Part,1)}
    }
    check("rifiuta gap 964"){
      rejectArg("964"){run(Nine.updated(0,964),Part,1)}
    }
    check("rifiuta anno sopra 5778"){
      rejectArg("6741"){run(Vector.fill(7)(963),Vector(2,1,1,1,1,1),1)}
    }
    check("rifiuta partizione incompleta"){
      rejectArg("6"){run(Nine,Vector.fill(6)(1),1)}
    }
    check("rifiuta gruppo zero"){
      rejectArg("0"){run(Nine,Vector(3,0,1,1,2,2),1)}
    }
    check("rifiuta indice zero"){
      rejectArg("0"){run(c=0)}
    }
    check("rifiuta indice sette"){
      rejectArg("7"){run(c=7)}
    }
    check("validator accetta contesto completo"){
      new BaseValidationManager().requireDiscovery27Ready(ready())
    }
    check("validator rifiuta legacy falso"){
      val ctx=ready();ctx.cutletSpanLegacyLength=Some(84)
      rejectState("Scar"){new BaseValidationManager().requireDiscovery27Ready(ctx)}
    }
    check("validator rifiuta snapshot falso"){
      val ctx=ready();ctx.cutletSpanIndex=Some(2)
      rejectState("Snapshot"){new BaseValidationManager().requireDiscovery27Ready(ctx)}
    }
    check("validator rifiuta trace falsa"){
      val ctx=ready();ctx.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager().requireDiscovery27Ready(ctx)}
    }
    check("validator rifiuta status falso"){
      val ctx=ready();ctx.status="PATCH_27_READY"
      rejectState("Status"){new BaseValidationManager().requireDiscovery27Ready(ctx)}
    }
    check("handler non pubblica input mancante"){
      val ctx=BaseMonsterContext(1,2)
      ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
      ctx.phase="DISCOVERY_27_CUTLET_SPAN";ctx.cutletSpanGaps=Some(Nine)
      rejectState("Incomplete"){new Discovery27CutletSpanHandler(
        new BaseMetricsShell).handle(ctx)}
      truth(ctx.cutletSpanLegacyLength.isEmpty &&
        ctx.cutletSpanSnapshot.isEmpty,"Atomicita")
    }
    check("Stage53 e cicatrice Stage52 intatti; no PATCH27"){
      var root=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
      while(!Files.exists(root.resolve("DEVELOPMENT_STAGE.md")) && root.getParent!=null)
        root=root.getParent
      val st=new String(Files.readAllBytes(root.resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("STAGE_53_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_42_PASS_0_FAIL"),"53")
      truth(st.contains("STAGE_52_NATIVE_VERIFICATION=PASS_EXPECTED_RED_44_PASS_3_FAIL"),"52")
      truth(st.contains("CURRENT_STAGE=54") && st.contains("CURRENT_PATCH=26") &&
        st.contains("STAGE_54_PATCH_27_INTRODUCED=NO"),"54")
    }
    println("\nRISULTATO STADIO 54: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
