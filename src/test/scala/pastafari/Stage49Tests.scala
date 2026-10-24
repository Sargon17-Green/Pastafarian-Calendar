package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH24: ricerca del mese mediante indice annuo assoluto. */
object Stage49Tests {
  private var passed=0
  private var failed=0
  private val Gaps=Vector.fill(6)(42)
  private val Parts=Vector.fill(6)(1)
  private val Blocks=Vector.fill(84)(1)++Vector.fill(84)(2)++
    Vector.fill(84)(3)
  private val Interleaved=Vector.tabulate(252)(d=>d%3+1)
  private val Gaps17=Vector.fill(17)(42)
  private val Parts17=Vector.fill(17)(1)
  private val Huge=(BigInt(1)<<16384)+49
  private def robin(n:Int,total:Int):Vector[Int]={
    val per=total/n;val extra=total%n
    val sizes=Vector.tabulate(n)(i=>per+(if(i>=n-extra)1 else 0))
    (0 until sizes.max).toVector.flatMap(j=>
      (1 to n).collect {case id if sizes(id-1)>j=>id})
  }
  private val Weave17=robin(6,714)
  private val WeaveMax=robin(47,5778)

  private def check(label:String)(f: => Unit):Unit={
    try {f;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](a:A,b:A,label:String):Unit={
    if(a!=b)throw new AssertionError(
      label+": atteso="+b+", ottenuto="+a)
  }
  private def truth(x:Boolean,label:String):Unit={
    if(!x)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(body: => Unit):Unit={
    var done=false
    try body catch {case _:IllegalArgumentException=>done=true}
    truth(done,label)
  }
  private def rejectState(label:String)(body: => Unit):Unit={
    var done=false
    try body catch {case _:IllegalStateException=>done=true}
    truth(done,label)
  }
  private def patch24(
    g:Vector[Int]=Gaps,p:Vector[Int]=Parts,
    w:Vector[Int]=Blocks,d:Int=84
  ):Patch24CutletLocalMonthResult =
    Patch24CutletLocalMonthWrapper.cutletLocalMonthPatch(g,p,w,d)

  // Test-only: non chiama adapter o wrapper della produzione.
  private def oracle(w:Vector[Int],d:Int):(Int,Int)={
    val month=w(d)
    var ordinal=0
    var i=0
    while(i<=d) {
      if(w(i)==month)ordinal+=1
      i+=1
    }
    (month,ordinal)
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&
       p.getParent!=null)p=p.getParent
    p
  }
  private def ready():BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_24_CUTLET_LOCAL_MONTH_LOOKUP"
    c.crossGateGaps=Some(Gaps)
    c.crossCutletPartition=Some(Parts)
    c.crossAnnualWeaving=Some(Blocks)
    c.crossYearDayOffset=Some(84)
    val met=new BaseMetricsShell
    new Discovery24CutletLocalMonthHandler(met).handle(c)
    new BaseValidationManager().requireDiscovery24Ready(c)
    c.phase="PATCH_24_CUTLET_LOCAL_MONTH_LOOKUP"
    new Patch24CutletLocalMonthHandler(met).handle(c)
    c
  }
  def main(args:Array[String]):Unit={
    check("giorno zero è primo giorno del primo mese"){
      val r=patch24(d=0)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(1,1),"Start")
    }
    check("giorno 41 chiude la prima cotoletta senza errore"){
      val r=patch24(d=41)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(1,42),"End")
    }
    check("giorno 42 entra nella seconda cotoletta ma non cambia mese"){
      val r=patch24(d=42)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(1,43),"Second")
    }
    check("giorno 83 termina il primo mese"){
      val r=patch24(d=83)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(1,84),"End")
    }
    check("giorno 84 apre mese due all'inizio cotoletta tre"){
      val r=patch24()
      eqv((r.correctedMonthId,r.correctedDayInMonth),(2,1),"Month2")
    }
    check("giorno 126 è 43esimo nel mese due"){
      val r=patch24(d=126)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(2,43),"Month2")
    }
    check("giorno 168 apre mese tre"){
      val r=patch24(d=168)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(3,1),"Month3")
    }
    check("giorno 210 è 43esimo nel mese tre"){
      val r=patch24(d=210)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(3,43),"Month3")
    }
    check("ultimo giorno anno è 84esimo del terzo mese"){
      val r=patch24(d=251)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(3,84),"End")
    }
    check("intercalazione mese due alla prima comparsa"){
      val r=patch24(w=Interleaved,d=1)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(2,1),"Weave")
    }
    check("intercalazione mese due alla seconda comparsa"){
      val r=patch24(w=Interleaved,d=4)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(2,2),"Weave")
    }
    check("intercalazione nel giorno 84 conta 29 presenze mese uno"){
      val r=patch24(w=Interleaved,d=84)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(1,29),"Weave")
    }
    check("intercalazione ultimo giorno è mese tre giorno 84"){
      val r=patch24(w=Interleaved,d=251)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(3,84),"Weave")
    }
    check("nella prima cotoletta legacy e patch coincidono"){
      for(d<-0 until 42) {
        val r=patch24(d=d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          (r.historical.legacyMonthId,r.historical.legacyDayInMonth),
          "Before cutlet boundary "+d)
      }
    }
    check("cicatrice terza cotoletta mantiene mese uno"){
      val r=patch24()
      eqv((r.historical.legacyMonthId,r.historical.legacyDayInMonth),
        (1,1),"Legacy")
      eqv((r.correctedMonthId,r.correctedDayInMonth),(2,1),"Correct")
    }
    check("cicatrice quarta cotoletta mantiene mese uno"){
      val r=patch24(d=126)
      eqv((r.historical.legacyMonthId,r.historical.legacyDayInMonth),
        (1,1),"Legacy")
      eqv((r.correctedMonthId,r.correctedDayInMonth),(2,43),"Correct")
    }
    check("cicatrice ultimo giorno ritorna alla prima cotoletta"){
      val r=patch24(d=251)
      eqv((r.historical.legacyMonthId,r.historical.legacyDayInMonth),
        (1,42),"Legacy")
      eqv((r.correctedMonthId,r.correctedDayInMonth),(3,84),"Correct")
    }
    check("il wrapper esegue il vero adapter storico"){
      for((g,p,w,d)<-Vector(
        (Gaps,Parts,Blocks,84),(Gaps,Parts,Blocks,126),
        (Gaps,Parts,Interleaved,251),(Gaps17,Parts17,Weave17,672))) {
        eqv(patch24(g,p,w,d).historical,
          LegacyCutletLocalMonthAdapter.oldCutletLocalMonthLookup(
            g,p,w,d),"Historical adapter")
      }
    }
    check("tutti i 252 giorni di tre mesi consecutivi"){
      for(d<-0 until 252) {
        val r=patch24(d=d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(Blocks,d),"Date "+d)
      }
    }
    check("tutti i 252 giorni di tre mesi intercalati"){
      for(d<-0 until 252) {
        val r=patch24(w=Interleaved,d=d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(Interleaved,d),"Date "+d)
      }
    }
    check("17 cotolette: inizio e fine di ogni segmento"){
      for(k<-0 until 17;d<-Vector(k*42, k*42+41)) {
        val r=patch24(Gaps17,Parts17,Weave17,d)
        eqv(r.historical.cutletId,k+1,"Cutlet "+k)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(Weave17,d),"Year day "+d)
      }
    }
    check("anno massimo in punti distribuiti ed estremo"){
      val g=Vector.fill(6)(963)
      val days=(0 until 5778 by 139).toVector :+ 5777
      for(d<-days) {
        val r=patch24(g,Parts,WeaveMax,d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(WeaveMax,d),"Max "+d)
      }
    }
    check("4096 partizioni casuali deterministiche valide"){
      val rng=new Random(49202026L)
      for(i<-1 to 4096) {
        val n=6+rng.nextInt(12)
        val extras=rng.nextInt(8)
        val cutlet=rng.nextInt(n)
        val partition=Vector.tabulate(n)(k=>if(k==cutlet)1+extras else 1)
        val gaps=Vector.fill(n+extras)(42+rng.nextInt(35))
        val days=gaps.sum
        val months=math.max(3,(days+122)/123)
        val weave=robin(months,days)
        val day=rng.nextInt(days)
        val result=patch24(gaps,partition,weave,day)
        eqv((result.correctedMonthId,result.correctedDayInMonth),
          oracle(weave,day),"Oracle "+i)
        val old=result.historical
        eqv((old.legacyMonthId,old.legacyDayInMonth),
          oracle(weave,old.cutletLocalOffset),"Legacy "+i)
      }
    }
    check("4096 richieste alternate tra due manager"){
      val rng=new Random(49212026L)
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      for(i<-1 to 4096) {
        val n=6+rng.nextInt(12)
        val extras=rng.nextInt(8)
        val index=rng.nextInt(n)
        val partition=Vector.tabulate(n)(k=>if(k==index)1+extras else 1)
        val gaps=Vector.fill(n+extras)(42+rng.nextInt(35))
        val days=gaps.sum
        val weave=robin(math.max(3,(days+122)/123),days)
        val day=rng.nextInt(days)
        val manager=if(i%2==0)a else b
        val r=manager.patch24CutletLocalMonthLookup(
          i,-Huge,gaps,partition,weave,day)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(weave,day),"Manager "+i)
      }
      eqv(a.metricsSnapshot("patch24.cutlet.month.calls"),
        BigInt(2048),"A")
      eqv(b.metricsSnapshot("patch24.cutlet.month.calls"),
        BigInt(2048),"B")
    }
    check("i BigInt del chiamante sono restituiti esattamente"){
      val r=new BaseMonsterManager().patch24CutletLocalMonthLookup(
        Huge,-Huge,Gaps,Parts,Blocks,84)
      eqv((r.calculationDay,r.targetDay),(Huge,-Huge),"BigInt")
    }
    check("trace attraversa bootstrap discovery e patch"){
      val r=new BaseMonsterManager().patch24CutletLocalMonthLookup(
        1,2,Gaps,Parts,Blocks,84)
      eqv(r.trace,Vector("BOOT",
        "DISCOVERY_24_CUTLET_LOCAL_MONTH_LOOKUP",
        "PATCH_24_CUTLET_LOCAL_MONTH_LOOKUP"),"Trace")
      eqv(r.status,"PATCH_24_READY","Status")
      truth(r.patchApplied,"Flag")
    }
    check("metriche di bootstrap discovery patch aumentano una volta"){
      val m=new BaseMonsterManager
      m.patch24CutletLocalMonthLookup(1,2,Gaps,Parts,Blocks,84)
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery24.cutlet.local.month.calls"),
        BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch24.cutlet.month.calls"),BigInt(1),"Patch")
    }
    check("riuso manager non cambia il report restituito"){
      val m=new BaseMonsterManager
      val r=m.patch24CutletLocalMonthLookup(1,2,Gaps,Parts,Blocks,84)
      val before=r.copy()
      m.patch24CutletLocalMonthLookup(3,4,Gaps,Parts,Blocks,126)
      eqv(r,before,"Immutability")
    }
    check("due manager mantengono metriche isolate"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      a.patch24CutletLocalMonthLookup(1,2,Gaps,Parts,Blocks,84)
      b.patch24CutletLocalMonthLookup(3,4,Gaps,Parts,Interleaved,251)
      eqv(a.metricsSnapshot("patch24.cutlet.month.calls"),BigInt(1),"A")
      eqv(b.metricsSnapshot("patch24.cutlet.month.calls"),BigInt(1),"B")
    }
    check("rifiuta cinque cotolette"){
      rejectArg("Cinque"){patch24(p=Vector(1,1,1,1,2))}
    }
    check("rifiuta diciotto cotolette"){
      val g=Vector.fill(18)(42)
      val w=robin(7,g.sum)
      rejectArg("Diciotto"){patch24(g,Vector.fill(18)(1),w,42)}
    }
    check("rifiuta gap più corto di 42"){
      rejectArg("Gap"){patch24(g=Vector(41,42,42,42,42,43))}
    }
    check("rifiuta gap più lungo di 963"){
      rejectArg("Gap"){patch24(g=Vector(964,42,42,42,42,42))}
    }
    check("rifiuta partizione incompleta"){
      rejectArg("Partizione"){patch24(p=Vector(1,1,1,1,1,2))}
    }
    check("rifiuta tessitura annuale tronca"){
      rejectArg("Weaving"){patch24(w=Blocks.take(251))}
    }
    check("rifiuta tessitura con primo mese fuori ordine"){
      rejectArg("Apertura"){patch24(w=Interleaved.updated(0,2))}
    }
    check("rifiuta giorno assoluto negativo"){
      rejectArg("Offset"){patch24(d = -1)}
    }
    check("rifiuta giorno esattamente dopo fine anno"){
      rejectArg("Offset"){patch24(d=252)}
    }
    check("validator accetta un risultato completo"){
      new BaseValidationManager().requirePatch24Ready(ready())
    }
    check("validator rifiuta ID di mese corretto falsificato"){
      val c=ready();c.patch24MonthId=Some(1)
      rejectState("Month"){new BaseValidationManager().requirePatch24Ready(c)}
    }
    check("validator rifiuta ordinale corretto falsificato"){
      val c=ready();c.patch24DayInMonth=Some(2)
      rejectState("Ordinal"){new BaseValidationManager().requirePatch24Ready(c)}
    }
    check("validator rifiuta mese storico falsificato"){
      val c=ready();c.crossLegacyMonthId=Some(2)
      rejectState("Legacy month"){new BaseValidationManager()
        .requirePatch24Ready(c)}
    }
    check("validator rifiuta ordinale storico falsificato"){
      val c=ready();c.crossLegacyMonthOrdinal=Some(2)
      rejectState("Legacy ordinal"){new BaseValidationManager()
        .requirePatch24Ready(c)}
    }
    check("validator rifiuta ID di cotoletta falsificato"){
      val c=ready();c.crossLegacyCutletId=Some(2)
      rejectState("Cutlet"){new BaseValidationManager()
        .requirePatch24Ready(c)}
    }
    check("validator rifiuta offset locale falsificato"){
      val c=ready();c.crossLegacyLocalOffset=Some(1)
      rejectState("Local"){new BaseValidationManager()
        .requirePatch24Ready(c)}
    }
    check("validator rifiuta snapshot falsificata"){
      val c=ready();c.crossYearDayOffset=Some(85)
      rejectState("Snapshot"){new BaseValidationManager()
        .requirePatch24Ready(c)}
    }
    check("validator rifiuta trace extra"){
      val c=ready();c.branchTrace.append("EXTRA")
      rejectState("Trace"){new BaseValidationManager().requirePatch24Ready(c)}
    }
    check("validator rifiuta status alterato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Status"){new BaseValidationManager().requirePatch24Ready(c)}
    }
    check("validator rifiuta flag di patch rimosso"){
      val c=ready();c.patch24Applied=false
      rejectState("Flag"){new BaseValidationManager().requirePatch24Ready(c)}
    }
    check("handler impedisce di saltare la discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_24_CUTLET_LOCAL_MONTH_LOOKUP"
      c.crossGateGaps=Some(Gaps);c.crossCutletPartition=Some(Parts)
      c.crossAnnualWeaving=Some(Blocks)
      c.crossYearDayOffset=Some(84)
      rejectState("Discovery"){new Patch24CutletLocalMonthHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patch24MonthId.isEmpty,"No publish")
    }
    check("handler non pubblica output se snapshot cambia"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_24_CUTLET_LOCAL_MONTH_LOOKUP"
      c.crossGateGaps=Some(Gaps);c.crossCutletPartition=Some(Parts)
      c.crossAnnualWeaving=Some(Blocks)
      c.crossYearDayOffset=Some(84)
      new Discovery24CutletLocalMonthHandler(
        new BaseMetricsShell).handle(c)
      c.phase="PATCH_24_CUTLET_LOCAL_MONTH_LOOKUP"
      c.crossYearDayOffset=Some(85)
      rejectState("Snapshot"){new Patch24CutletLocalMonthHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patch24MonthId.isEmpty && !c.patch24Applied,
        "Atomic")
    }
    check("DISCOVERY24 resta accessibile senza PATCH24"){
      val r=new BaseMonsterManager().discover24CutletLocalMonthLookup(
        1,2,Gaps,Parts,Blocks,84)
      eqv((r.legacyMonthId,r.legacyDayInMonth),(1,1),"Legacy")
    }
    check("PATCH23 conserva ancora l'ordinale intercalato"){
      val r=new BaseMonsterManager().patch23ContiguousMonthAssumption(
        1,2,Interleaved,4)
      eqv(r.correctedDayInMonth,2,"PATCH23")
    }
    check("nessun oracolo normativo in codice di produzione"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val src=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!src.contains("NormativeOracle"),"Test-only")
      truth(src.contains("def cutletLocalMonthPatch("),"PATCH24")
    }
    check("Stage48 RED rimane certificato nel registro"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains(
        "STAGE_48_NATIVE_VERIFICATION=PASS_EXPECTED_RED_44_PASS_3_FAIL"),
        "Stage48")
      val curr=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      truth(curr>=49,"Stage49")
    }
    println("\nRISULTATO STADIO 49: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
