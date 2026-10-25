package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH25: il giorno annuale corrente, non il valore cached. */
object Stage51Tests {
  private var passed=0
  private var failed=0
  private val Gaps=Vector.fill(6)(42)
  private val Blocks=Vector.fill(84)(1)++Vector.fill(84)(2)++
    Vector.fill(84)(3)
  private val Woven=Vector.tabulate(252)(i=>i%3+1)
  private val Huge=(BigInt(1)<<16384)+51
  private def robin(months:Int,days:Int):Vector[Int]={
    val q=days/months;val rem=days%months
    val counts=Vector.tabulate(months)(i=>q+(if(i>=months-rem)1 else 0))
    (0 until counts.max).toVector.flatMap(k=>
      (1 to months).collect{case id if counts(id-1)>k=>id})
  }
  private val Maximum=robin(47,5778)
  private def check(label:String)(run: => Unit):Unit={
    try{run;passed+=1;println("PASS — "+label)}
    catch{case e:Throwable=>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
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
  private def patch(
    g:Vector[Int]=Gaps,w:Vector[Int]=Blocks,d:Int=43
  ):Patch25GateStartMonthCacheResult =
    Patch25GateStartMonthCacheWrapper.gateCacheMonthPatch(g,w,d)
  // Independent test-only oracle, no production adapter calls.
  private def oracle(w:Vector[Int],d:Int):(Int,Int)={
    val month=w(d)
    var ordinal=0
    var i=0
    while(i<=d){
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
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_25_GATE_START_MONTH_CACHE"
    c.gateCacheGaps=Some(Gaps)
    c.gateCacheAnnualWeaving=Some(Blocks)
    c.gateCacheDayOffset=Some(43)
    val metrics=new BaseMetricsShell
    new Discovery25GateStartMonthCacheHandler(metrics).handle(c)
    new BaseValidationManager().requireDiscovery25Ready(c)
    c.phase="PATCH_25_GATE_START_MONTH_CACHE"
    new Patch25GateStartMonthCacheHandler(metrics).handle(c)
    c
  }
  def main(args:Array[String]):Unit={
    check("sei gate con 42 giorni ciascuno sono validi"){
      eqv(Gaps.sum,252,"Gaps")
    }
    check("tessitura contigua di 3 mesi valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Blocks))
    }
    check("tessitura intercalata di 3 mesi valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Woven))
    }
    check("tessitura massima di 47 mesi valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Maximum))
    }
    check("giorno zero ha mese uno e ordinal uno"){
      eqv((patch(d=0).correctedMonthId,patch(d=0).correctedDayInMonth),
        (1,1),"Primo")
    }
    check("giorno 1 della prima porta conta due"){
      val r=patch(d=1)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(1,2),"Secondo")
    }
    check("giorno 41 chiude prima porta con ordinal 42"){
      eqv(patch(d=41).correctedDayInMonth,42,"Ultimo")
    }
    check("giorno 42 inizia seconda porta con ordinal 43"){
      eqv(patch(d=42).correctedDayInMonth,43,"Nuova porta")
    }
    check("giorno 43 ha ordinal 44, non cache 43"){
      val r=patch()
      eqv((r.correctedMonthId,r.correctedDayInMonth),(1,44),"Corretto")
      eqv(r.historical.legacyDayInMonth,43,"Vecchio")
    }
    check("giorno 83 chiude primo mese"){
      eqv((patch(d=83).correctedMonthId,patch(d=83).correctedDayInMonth),
        (1,84),"Fine mese")
    }
    check("giorno 84 inizia il secondo mese"){
      eqv((patch(d=84).correctedMonthId,patch(d=84).correctedDayInMonth),
        (2,1),"Nuovo mese")
    }
    check("giorno 85 è secondo nel secondo mese"){
      eqv(patch(d=85).correctedDayInMonth,2,"Mese secondo")
    }
    check("giorno 126 apre quarta porta con ordinal 43"){
      eqv(patch(d=126).correctedDayInMonth,43,"Quarta porta")
    }
    check("giorno 127 progredisce al 44"){
      eqv(patch(d=127).correctedDayInMonth,44,"Quarta porta")
    }
    check("giorno 168 è primo nel terzo mese"){
      eqv((patch(d=168).correctedMonthId,patch(d=168).correctedDayInMonth),
        (3,1),"Terzo mese")
    }
    check("giorno 210 è 43esimo del terzo mese"){
      eqv(patch(d=210).correctedDayInMonth,43,"Sesta porta")
    }
    check("ultimo giorno è mese tre ordinal 84"){
      val r=patch(d=251)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(3,84),"Fine anno")
      eqv(r.historical.legacyDayInMonth,43,"Cache vecchia")
    }
    check("intercalato giorno uno seleziona mese due"){
      eqv((patch(w=Woven,d=1).correctedMonthId,
        patch(w=Woven,d=1).correctedDayInMonth),(2,1),"Woven")
    }
    check("intercalato giorno quattro seleziona seconda comparsa"){
      eqv((patch(w=Woven,d=4).correctedMonthId,
        patch(w=Woven,d=4).correctedDayInMonth),(2,2),"Woven")
    }
    check("intercalato giorno 84 conta mese uno 29 volte"){
      eqv(patch(w=Woven,d=84).correctedDayInMonth,29,"Woven")
    }
    check("intercalato fine anno è mese tre ordinal 84"){
      val r=patch(w=Woven,d=251)
      eqv((r.correctedMonthId,r.correctedDayInMonth),(3,84),"Woven")
    }
    check("cicatrice primo giorno del gate coincide con norma"){
      for(d<-Vector(0,42,84,126,168,210)){
        val r=patch(d=d)
        eqv((r.historical.legacyMonthId,r.historical.legacyDayInMonth),
          (r.correctedMonthId,r.correctedDayInMonth),"Gate "+d)
      }
    }
    check("cicatrice intercalata del primo gate resta immobile"){
      val r=patch(w=Woven,d=1)
      eqv((r.historical.legacyMonthId,r.historical.legacyDayInMonth),
        (1,1),"Old")
      eqv((r.correctedMonthId,r.correctedDayInMonth),(2,1),"Norma")
    }
    check("cicatrice secondo gate resta al giorno 42"){
      val r=patch(d=43)
      eqv(r.historical.gateStartDayOffset,42,"Start")
      eqv(r.historical.gateId,2,"Gate")
    }
    check("tutti i 252 giorni a blocchi coincidono con oracolo"){
      for(d<-0 until 252){
        val r=patch(d=d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(Blocks,d),"Giorno "+d)
      }
    }
    check("tutti i 252 giorni intercalati coincidono con oracolo"){
      for(d<-0 until 252){
        val r=patch(w=Woven,d=d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(Woven,d),"Giorno "+d)
      }
    }
    check("5778 giorni massimi in punti distribuiti ed estremi"){
      val gaps=Vector.fill(6)(963)
      val offsets=(0 until 5778 by 29).toVector :+ 5777
      for(d<-offsets){
        val r=patch(gaps,Maximum,d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(Maximum,d),"Massimo "+d)
      }
    }
    check("47 varchi minimi 42 giorni con 17 mesi"){
      val gaps=Vector.fill(47)(42)
      val weave=robin(17,gaps.sum)
      for(d<-Vector(0,41,42,43,600,1000,1973)){
        val r=patch(gaps,weave,d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(weave,d),"Giorno "+d)
      }
    }
    check("tutte le cardinalità gate 6..47 valide"){
      for(n<-6 to 47){
        val g=Vector.fill(n)(42)
        val days=g.sum
        val w=robin(math.max(3,(days+122)/123),days)
        val d=days-1
        eqv((patch(g,w,d).correctedMonthId,
          patch(g,w,d).correctedDayInMonth),oracle(w,d),"Gate "+n)
      }
    }
    check("4096 vettori randomizzati deterministici"){
      val rng=new Random(51202026L)
      for(k<-1 to 4096){
        val n=6+rng.nextInt(42)
        val g=Vector.fill(n)(42+rng.nextInt(41))
        val days=g.sum
        val m=math.max(3,(days+122)/123)
        val w=robin(m,days)
        val d=rng.nextInt(days)
        val r=patch(g,w,d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(w,d),"Corretto "+k)
        eqv((r.historical.legacyMonthId,r.historical.legacyDayInMonth),
          oracle(w,r.historical.gateStartDayOffset),"Legacy "+k)
      }
    }
    check("4096 richieste su due manager isolati"){
      val rng=new Random(51212026L)
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      for(k<-1 to 4096){
        val n=6+rng.nextInt(42)
        val g=Vector.fill(n)(42+rng.nextInt(41))
        val days=g.sum
        val m=math.max(3,(days+122)/123)
        val w=robin(m,days)
        val d=rng.nextInt(days)
        val mm=if(k%2==0)a else b
        val r=mm.patch25GateStartMonthCache(k,-Huge,g,w,d)
        eqv((r.correctedMonthId,r.correctedDayInMonth),
          oracle(w,d),"Manager "+k)
      }
      eqv(a.metricsSnapshot("patch25.gate.cache.calls"),
        BigInt(2048),"Manager A")
      eqv(b.metricsSnapshot("patch25.gate.cache.calls"),
        BigInt(2048),"Manager B")
    }
    check("wrapper conserva il report dell'adapter originale"){
      for((g,w,d)<-Vector(
        (Gaps,Blocks,43),(Gaps,Woven,1),
        (Vector.fill(47)(42),robin(17,1974),1973))) {
        val r=patch(g,w,d)
        eqv(r.historical,
          LegacyGateStartMonthCacheAdapter.oldGateStartMonthCache(g,w,d),
          "Legacy")
      }
    }
    check("input e snapshot restituiti sono inalterati"){
      val r=patch()
      eqv(r.historical.gateGaps,Gaps,"Gaps")
      eqv(r.historical.annualWeaving,Blocks,"Weave")
      eqv(r.historical.dayOffset,43,"Offset")
    }
    check("manager preserva i BigInt originali"){
      val r=new BaseMonsterManager().patch25GateStartMonthCache(
        Huge,-Huge,Gaps,Blocks,43)
      eqv((r.calculationDay,r.targetDay),(Huge,-Huge),"BigInt")
    }
    check("manager pubblica la trace completa"){
      val r=new BaseMonsterManager().patch25GateStartMonthCache(
        1,2,Gaps,Blocks,43)
      eqv(r.trace,Vector("BOOT",
        "DISCOVERY_25_GATE_START_MONTH_CACHE",
        "PATCH_25_GATE_START_MONTH_CACHE"),"Trace")
      eqv(r.status,"PATCH_25_READY","Stato")
      truth(r.patchApplied,"Flag")
    }
    check("manager contabilizza bootstrap e entrambe fasi"){
      val m=new BaseMonsterManager
      m.patch25GateStartMonthCache(1,2,Gaps,Blocks,43)
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery25.gate.cache.calls"),
        BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch25.gate.cache.calls"),BigInt(1),"Patch")
    }
    check("report emesso rimane immutabile"){
      val m=new BaseMonsterManager
      val first=m.patch25GateStartMonthCache(1,2,Gaps,Blocks,43)
      val frozen=first.copy()
      m.patch25GateStartMonthCache(3,4,Gaps,Woven,251)
      eqv(first,frozen,"Report")
    }
    check("due manager separati non condividono metriche"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      a.patch25GateStartMonthCache(1,2,Gaps,Blocks,43)
      b.patch25GateStartMonthCache(3,4,Gaps,Woven,251)
      eqv(a.metricsSnapshot("patch25.gate.cache.calls"),BigInt(1),"A")
      eqv(b.metricsSnapshot("patch25.gate.cache.calls"),BigInt(1),"B")
    }
    check("rifiuta cinque gate"){
      val g=Vector.fill(5)(52)
      rejectArg("Gate"){patch(g,robin(3,g.sum),2)}
    }
    check("rifiuta quarantotto gate"){
      val g=Vector.fill(48)(42)
      rejectArg("Gate"){patch(g,robin(17,g.sum),2)}
    }
    check("rifiuta gap sotto 42"){
      rejectArg("Gap"){patch(Vector(41,42,42,42,42,43),Blocks,2)}
    }
    check("rifiuta gap sopra 963"){
      rejectArg("Gap"){patch(Vector(964,42,42,42,42,42),Blocks,2)}
    }
    check("rifiuta tessitura di un giorno più corta"){
      rejectArg("Weave"){patch(Gaps,Blocks.take(251),2)}
    }
    check("rifiuta tessitura con due soli mesi"){
      rejectArg("Months"){patch(Gaps,
        Vector.tabulate(252)(i=>i%2+1),2)}
    }
    check("rifiuta tessitura con apertura non ordinata"){
      rejectArg("Opening"){patch(Gaps,Woven.updated(0,2),2)}
    }
    check("rifiuta giorno negativo"){
      rejectArg("Offset"){patch(d = -1)}
    }
    check("rifiuta giorno immediatamente dopo fine anno"){
      rejectArg("Offset"){patch(d=252)}
    }
    check("validator indipendente accetta contesto PATCH25"){
      new BaseValidationManager().requirePatch25Ready(ready())
    }
    check("validator rifiuta ID mese patch falsificato"){
      val c=ready();c.patch25CurrentMonthId=Some(2)
      rejectState("Month"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("validator rifiuta ordinal patch falsificato"){
      val c=ready();c.patch25CurrentDayInMonth=Some(1)
      rejectState("Ordinal"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("validator rifiuta ID gate cached falsificato"){
      val c=ready();c.legacyGateCacheGateId=Some(3)
      rejectState("Gate"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("validator rifiuta start cached falsificato"){
      val c=ready();c.legacyGateCacheStart=Some(0)
      rejectState("Start"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("validator rifiuta mese cached falsificato"){
      val c=ready();c.legacyGateCacheMonthId=Some(2)
      rejectState("Legacy month"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("validator rifiuta ordinal cached falsificato"){
      val c=ready();c.legacyGateCacheOrdinal=Some(1)
      rejectState("Legacy ordinal"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("validator rifiuta snapshot mutata"){
      val c=ready();c.gateCacheDayOffset=Some(44)
      rejectState("Snapshot"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("validator rifiuta trace aggiuntiva"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("validator rifiuta stato manomesso"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Status"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("validator rifiuta patch flag tolto"){
      val c=ready();c.patch25Applied=false
      rejectState("Flag"){new BaseValidationManager()
        .requirePatch25Ready(c)}
    }
    check("handler rifiuta salto della discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_25_GATE_START_MONTH_CACHE"
      c.gateCacheGaps=Some(Gaps)
      c.gateCacheAnnualWeaving=Some(Blocks)
      c.gateCacheDayOffset=Some(43)
      rejectState("Discovery"){new Patch25GateStartMonthCacheHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patch25CurrentMonthId.isEmpty,"No output")
    }
    check("handler evita pubblicazione su input cambiati"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_25_GATE_START_MONTH_CACHE"
      c.gateCacheGaps=Some(Gaps)
      c.gateCacheAnnualWeaving=Some(Blocks)
      c.gateCacheDayOffset=Some(43)
      new Discovery25GateStartMonthCacheHandler(
        new BaseMetricsShell).handle(c)
      c.phase="PATCH_25_GATE_START_MONTH_CACHE"
      c.gateCacheDayOffset=Some(44)
      rejectState("Snapshot"){new Patch25GateStartMonthCacheHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patch25CurrentMonthId.isEmpty && !c.patch25Applied,
        "Atomic")
    }
    check("DISCOVERY25 resta interrogabile senza PATCH25"){
      val r=new BaseMonsterManager().discover25GateStartMonthCache(
        1,2,Gaps,Blocks,43)
      eqv((r.legacyMonthId,r.legacyDayInMonth),(1,43),"Cicatrice")
    }
    check("PATCH24 e PATCH25 concordano su tutti i giorni dell'anno"){
      // Stesso calendario sintetico, due percorsi indipendenti
      // di correzione dell'offset locale e della cache del varco.
      val previous=new BaseMonsterManager
      val current=new BaseMonsterManager
      for(w<-Vector(Blocks,Woven);d<-0 until 252){
        val r24=previous.patch24CutletLocalMonthLookup(
          1,2,Gaps,Vector.fill(6)(1),w,d)
        val r25=current.patch25GateStartMonthCache(
          3,4,Gaps,w,d)
        val expected=oracle(w,d)
        eqv((r24.correctedMonthId,r24.correctedDayInMonth),
          expected,"PATCH24 "+d)
        eqv((r25.correctedMonthId,r25.correctedDayInMonth),
          (r24.correctedMonthId,r24.correctedDayInMonth),
          "PATCH25 contro PATCH24 "+d)
      }
    }
    check("oracolo normativo esclusivamente nei test"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val code=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!code.contains("NormativeOracle"),"Solo test")
      truth(code.contains("def gateCacheMonthPatch("),"PATCH25")
    }
    check("Stage50 mantiene le tre cicatrici certificate"){
      val text=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(text.contains(
        "STAGE_50_NATIVE_VERIFICATION=PASS_EXPECTED_RED_44_PASS_3_FAIL"),
        "RED Stage50")
      val current=text.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      val completed=text.linesIterator.find(
        _.startsWith("LAST_COMPLETED_STAGE="))
        .get.split("=",2)(1).toInt
      truth(current>=51 && completed>=50 && completed<=current,
        "Stage51 corrente")
      if(completed>=51 || current>51)
        truth(text.contains(
          "STAGE_51_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_64_PASS_0_FAIL"),
          "Firma storica PATCH25 certificata")
    }
    println("\nRISULTATO STADIO 51: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
