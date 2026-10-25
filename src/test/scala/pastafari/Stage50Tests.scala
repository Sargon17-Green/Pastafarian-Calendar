package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY25: la cache del varco non può sostituire il giorno. */
object Stage50Tests {
  private var passed=0
  private var failed=0
  private val Gaps=Vector.fill(6)(42)
  private val Blocks=Vector.fill(84)(1)++Vector.fill(84)(2)++
    Vector.fill(84)(3)
  private val Woven=Vector.tabulate(252)(i=>i%3+1)
  private val Huge=(BigInt(1)<<16384)+50
  private def robin(months:Int,days:Int):Vector[Int]={
    val q=days/months;val r=days%months
    val counts=Vector.tabulate(months)(j=>
      q+(if(j>=months-r)1 else 0))
    (0 until counts.max).toVector.flatMap(k=>
      (1 to months).collect{case id if counts(id-1)>k=>id})
  }
  private val Maximum=robin(47,5778)
  private def check(label:String)(run: => Unit):Unit={
    try{run;passed+=1;println("PASS — "+label)}
    catch{case err:Throwable=>
      failed+=1;println("FAIL — "+label+" — "+err.getMessage)
      err.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(v:Boolean,label:String):Unit={
    if(!v)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(run: => Unit):Unit={
    var denied=false
    try run catch{case _:IllegalArgumentException=>denied=true}
    truth(denied,label)
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var denied=false
    try run catch{case _:IllegalStateException=>denied=true}
    truth(denied,label)
  }
  private def old(g:Vector[Int]=Gaps,w:Vector[Int]=Blocks,d:Int=43):
      LegacyGateStartMonthCacheResult =
    LegacyGateStartMonthCacheAdapter.oldGateStartMonthCache(g,w,d)
  private def normative(w:Vector[Int],d:Int):(Int,Int)={
    val month=w(d)
    var ordinal=0
    var i=0
    while(i<=d) {
      if(w(i)==month)ordinal+=1
      i+=1
    }
    (month,ordinal)
  }
  private def ready():BaseMonsterContext={
    val ctx=BaseMonsterContext(Huge,-Huge)
    ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
    ctx.phase="DISCOVERY_25_GATE_START_MONTH_CACHE"
    ctx.gateCacheGaps=Some(Gaps)
    ctx.gateCacheAnnualWeaving=Some(Blocks)
    ctx.gateCacheDayOffset=Some(43)
    new Discovery25GateStartMonthCacheHandler(
      new BaseMetricsShell).handle(ctx)
    ctx
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir"))
      .toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) &&
       p.getParent!=null)p=p.getParent
    p
  }
  def main(args:Array[String]):Unit={
    check("sei varchi coprono l'anno minimo"){
      eqv(Gaps.sum,252,"Totale")
    }
    check("tessitura consecutiva valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Blocks))
    }
    check("tessitura intercalata valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Woven))
    }
    check("tessitura 47 mesi anno massimo valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Maximum))
    }
    check("giorno zero usa il primo gate"){
      val r=old(d=0)
      eqv((r.gateId,r.gateStartDayOffset,r.legacyMonthId,
        r.legacyDayInMonth),(1,0,1,1),"Primo")
    }
    check("giorno 41 riusa la cache della prima porta"){
      val r=old(d=41)
      eqv((r.gateId,r.gateStartDayOffset,r.legacyDayInMonth),
        (1,0,1),"Stale")
    }
    check("giorno 42 apre la seconda porta"){
      val r=old(d=42)
      eqv((r.gateId,r.gateStartDayOffset,r.legacyDayInMonth),
        (2,42,43),"Confine")
    }
    check("giorno 43 riusa giorno 42"){
      val r=old()
      eqv((r.gateId,r.gateStartDayOffset,r.legacyDayInMonth),
        (2,42,43),"Cache")
    }
    check("giorno 84 apre la terza porta e mese due"){
      val r=old(d=84)
      eqv((r.gateId,r.gateStartDayOffset,r.legacyMonthId,
        r.legacyDayInMonth),(3,84,2,1),"Gate3")
    }
    check("giorno 126 apre quarta porta"){
      val r=old(d=126)
      eqv((r.gateId,r.gateStartDayOffset,r.legacyMonthId,
        r.legacyDayInMonth),(4,126,2,43),"Gate4")
    }
    check("ultimo giorno usa cache del giorno 210"){
      val r=old(d=251)
      eqv((r.gateId,r.gateStartDayOffset,r.legacyMonthId,
        r.legacyDayInMonth),(6,210,3,43),"YearEnd")
    }
    check("primo giorno dopo un gate coincide con la norma"){
      for(d<-Vector(0,42,84,126,168,210)) {
        val r=old(d=d)
        eqv((r.legacyMonthId,r.legacyDayInMonth),
          normative(Blocks,d),"Gate "+d)
      }
    }
    check("la cache della prima porta coincide per tutti i suoi giorni"){
      for(d<-0 until 42) {
        val r=old(d=d)
        eqv((r.legacyMonthId,r.legacyDayInMonth),
          normative(Blocks,0),"Cache "+d)
      }
    }
    check("la cache usa sempre un offset minore o uguale al giorno"){
      for(d<-0 until 252) {
        val r=old(d=d)
        truth(r.gateStartDayOffset<=d,"Offset "+d)
      }
    }
    check("tutti i 252 giorni mantengono il valore storico"){
      for(d<-0 until 252) {
        val r=old(d=d)
        val start=(d/42)*42
        eqv(r.gateStartDayOffset,start,"Start "+d)
        eqv((r.legacyMonthId,r.legacyDayInMonth),
          normative(Blocks,start),"Cached "+d)
      }
    }
    check("cache intercalata cambia solo al confine della porta"){
      for(d<-0 until 252) {
        val r=old(w=Woven,d=d)
        val start=(d/42)*42
        eqv((r.legacyMonthId,r.legacyDayInMonth),
          normative(Woven,start),"Woven "+d)
      }
    }
    check("tutti i gate del massimo 5778 hanno estremi validi"){
      val maxGaps=Vector.fill(6)(963)
      for(d<-Vector(0,962,963,1925,1926,4815,5777)) {
        val r=old(maxGaps,Maximum,d)
        eqv(r.gateId,d/963+1,"Gate "+d)
        eqv(r.gateStartDayOffset,(d/963)*963,"Start "+d)
      }
    }
    check("tutti i 47 varchi minimi sono verificabili"){
      val gaps=Vector.fill(47)(42)
      val w=robin(17,gaps.sum)
      for(d<-Vector(0,41,42,1000,1973)) {
        val r=old(gaps,w,d)
        eqv(r.gateId,d/42+1,"Gate "+d)
      }
    }
    check("1024 ingressi deterministici su 6..17 porte"){
      val rng=new Random(50202026L)
      for(k<-1 to 1024) {
        val n=6+rng.nextInt(12)
        val g=Vector.fill(n)(42+rng.nextInt(47))
        val days=g.sum
        val months=math.max(3,(days+122)/123)
        val weave=robin(months,days)
        val d=rng.nextInt(days)
        val r=old(g,weave,d)
        eqv((r.legacyMonthId,r.legacyDayInMonth),
          normative(weave,r.gateStartDayOffset),"Cache "+k)
      }
    }
    check("la risposta non muta i vettori sorgente"){
      val r=old()
      eqv(r.gateGaps,Gaps,"Gaps")
      eqv(r.annualWeaving,Blocks,"Weave")
      eqv(r.dayOffset,43,"Day")
    }
    check("il report del manager conserva i BigInt grandi"){
      val r=new BaseMonsterManager().discover25GateStartMonthCache(
        Huge,-Huge,Gaps,Blocks,43)
      eqv((r.calculationDay,r.targetDay),(Huge,-Huge),"BigInt")
    }
    check("manager attraversa boot e discovery"){
      val r=new BaseMonsterManager().discover25GateStartMonthCache(
        1,2,Gaps,Blocks,43)
      eqv(r.trace,Vector("BOOT",
        "DISCOVERY_25_GATE_START_MONTH_CACHE"),"Trace")
      eqv(r.status,"LEGACY_GATE_START_CACHE_READY","Status")
    }
    check("due manager hanno contatori indipendenti"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      a.discover25GateStartMonthCache(1,2,Gaps,Blocks,43)
      b.discover25GateStartMonthCache(3,4,Gaps,Blocks,84)
      eqv(a.metricsSnapshot("discovery25.gate.cache.calls"),
        BigInt(1),"A")
      eqv(b.metricsSnapshot("discovery25.gate.cache.calls"),
        BigInt(1),"B")
    }
    check("report precedente rimane immutabile"){
      val m=new BaseMonsterManager
      val a=m.discover25GateStartMonthCache(1,2,Gaps,Blocks,43)
      val copy=a.copy()
      m.discover25GateStartMonthCache(3,4,Gaps,Blocks,84)
      eqv(a,copy,"Immutable")
    }
    check("rifiuta cinque porte"){
      val gaps=Vector.fill(5)(52)
      rejectArg("Cinque"){old(gaps,robin(3,gaps.sum),2)}
    }
    check("rifiuta quarantotto porte"){
      val gaps=Vector.fill(48)(42)
      rejectArg("Quarantotto"){old(gaps,robin(17,gaps.sum),2)}
    }
    check("rifiuta intervalli sotto 42"){
      val gaps=Vector(41,42,42,42,42,43)
      rejectArg("Gaps"){old(gaps,Blocks,1)}
    }
    check("rifiuta intervalli sopra 963"){
      val gaps=Vector(964,42,42,42,42,42)
      rejectArg("Gaps"){old(gaps,Blocks,1)}
    }
    check("rifiuta weaving di 251 giorni"){
      rejectArg("Weave"){old(Gaps,Blocks.take(251),1)}
    }
    check("rifiuta weaving con 2 mesi"){
      rejectArg("Months"){old(Gaps,Vector.tabulate(252)(i=>i%2+1),1)}
    }
    check("rifiuta apertura fuori ordine"){
      rejectArg("Start"){old(Gaps,Woven.updated(0,2),1)}
    }
    check("rifiuta giorno negativo"){
      rejectArg("Day"){old(d = -1)}
    }
    check("rifiuta giorno pari al limite dell'anno"){
      rejectArg("Day"){old(d=252)}
    }
    check("validator indipendente accetta stato valido"){
      new BaseValidationManager().requireDiscovery25Ready(ready())
    }
    check("validator rifiuta ID gate alterato"){
      val c=ready();c.legacyGateCacheGateId=Some(3)
      rejectState("Gate"){new BaseValidationManager()
        .requireDiscovery25Ready(c)}
    }
    check("validator rifiuta inizio gate alterato"){
      val c=ready();c.legacyGateCacheStart=Some(0)
      rejectState("Start"){new BaseValidationManager()
        .requireDiscovery25Ready(c)}
    }
    check("validator rifiuta mese cached alterato"){
      val c=ready();c.legacyGateCacheMonthId=Some(2)
      rejectState("Month"){new BaseValidationManager()
        .requireDiscovery25Ready(c)}
    }
    check("validator rifiuta ordinale cached alterato"){
      val c=ready();c.legacyGateCacheOrdinal=Some(1)
      rejectState("Ordinal"){new BaseValidationManager()
        .requireDiscovery25Ready(c)}
    }
    check("validator rifiuta snapshot mutata"){
      val c=ready();c.gateCacheDayOffset=Some(44)
      rejectState("Snapshot"){new BaseValidationManager()
        .requireDiscovery25Ready(c)}
    }
    check("validator rifiuta trace aggiuntiva"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager()
        .requireDiscovery25Ready(c)}
    }
    check("validator rifiuta status alterato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Status"){new BaseValidationManager()
        .requireDiscovery25Ready(c)}
    }
    check("handler respinge salto del bootstrap"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_25_GATE_START_MONTH_CACHE"
      c.gateCacheGaps=Some(Gaps)
      c.gateCacheAnnualWeaving=Some(Blocks)
      c.gateCacheDayOffset=Some(43)
      rejectState("Boot"){new Discovery25GateStartMonthCacheHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.legacyGateCacheMonthId.isEmpty,"No output")
    }
    check("l'oracolo normativo non è nel codice produttivo"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val src=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!src.contains("NormativeOracle"),"Test only")
    }
    check("Stage49 resta certificato e PATCH25 non anticipata"){
      val s=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(s.contains(
        "STAGE_49_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_55_PASS_0_FAIL"),
        "Stage49")
      truth(s.contains("LAST_COMPLETED_STAGE=49"),"Completed")
      truth(s.contains("CURRENT_STAGE=50"),"Current")
      val walk=Files.walk(root().resolve("src/main/scala"))
      val src=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!src.contains("def gateCacheMonthPatch("),"PATCH25 assente")
    }
    // Tre fallimenti intenzionali, soltanto questi.
    Vector(
      ("GATE1_DAY1_MONTH",Woven,1,"MONTH"),
      ("GATE2_DAY43_ORDINAL",Blocks,43,"ORDINAL"),
      ("GATE6_YEAR_END_ORDINAL",Blocks,251,"ORDINAL")
    ).foreach{case (tag,weave,d,kind)=>
      check("equivalenza normativa "+tag){
        val r=new BaseMonsterManager().discover25GateStartMonthCache(
          Huge,-Huge,Gaps,weave,d)
        val expect=normative(weave,d)
        if(kind=="MONTH")
          eqv(r.legacyMonthId,expect._1,"Cache di varco: "+tag)
        else
          eqv(r.legacyDayInMonth,expect._2,"Cache di varco: "+tag)
      }
    }
    println("\nRISULTATO STADIO 50: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
