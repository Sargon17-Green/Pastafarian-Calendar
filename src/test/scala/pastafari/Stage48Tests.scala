package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY24: usa erroneamente il giorno della cotoletta
  * per cercare un mese nella tessitura annuale.
  */
object Stage48Tests {
  private var passed=0
  private var failed=0
  private val Gaps=Vector.fill(6)(42)
  private val Cuts=Vector.fill(6)(1)
  private val Woven=Vector.tabulate(252)(d=>d%3+1)
  private val Blocks=Vector.fill(84)(1)++Vector.fill(84)(2)++
    Vector.fill(84)(3)
  private val Seventeen=Vector.fill(17)(42)
  private val SeventeenParts=Vector.fill(17)(1)
  private val Huge=(BigInt(1)<<16384)+48
  private def robin(n:Int,total:Int):Vector[Int]={
    val q=total/n
    val rem=total%n
    val counts=Vector.tabulate(n)(i=>q+(if(i>=n-rem)1 else 0))
    (0 until counts.max).toVector.flatMap(k=>
      (1 to n).collect {case id if counts(id-1)>k=>id})
  }
  private def check(label:String)(f: => Unit):Unit={
    try {f;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable=>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(f: => Unit):Unit={
    var caught=false
    try f catch {case _:IllegalArgumentException=>caught=true}
    truth(caught,label)
  }
  private def rejectState(label:String)(f: => Unit):Unit={
    var caught=false
    try f catch {case _:IllegalStateException=>caught=true}
    truth(caught,label)
  }
  private def old(g:Vector[Int]=Gaps,p:Vector[Int]=Cuts,
    w:Vector[Int]=Blocks,d:Int=84):LegacyCutletLocalMonthResult =
    LegacyCutletLocalMonthAdapter.oldCutletLocalMonthLookup(g,p,w,d)

  // Oracolo indipendente: la coordinata del mese e' quella
  // dell'anno, mai il giorno locale della cotoletta.
  private def normative(w:Vector[Int],d:Int):(Int,Int)={
    val id=w(d)
    var ordinal=0
    var i=0
    while(i<=d) {
      if(w(i)==id)ordinal+=1
      i+=1
    }
    (id,ordinal)
  }
  private def ready():BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_24_CUTLET_LOCAL_MONTH_LOOKUP"
    c.crossGateGaps=Some(Gaps)
    c.crossCutletPartition=Some(Cuts)
    c.crossAnnualWeaving=Some(Blocks)
    c.crossYearDayOffset=Some(84)
    new Discovery24CutletLocalMonthHandler(
      new BaseMetricsShell).handle(c)
    c
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir"))
      .toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }

  def main(args:Array[String]):Unit={
    check("durata delle sei porte è 252 giorni"){
      eqv(Gaps.sum,252,"Durata")
    }
    check("sei cotolette complete coprono esattamente le porte"){
      eqv(Cuts.sum,Gaps.length,"Partizione")
    }
    check("la tessitura a tre blocchi è annualmente valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Blocks))
    }
    check("la tessitura alternata è annualmente valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Woven))
    }
    check("la tessitura a diciassette porte è valida"){
      val w=robin(6,Seventeen.sum)
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(w))
    }
    check("giorno zero usa la prima cotoletta e il primo mese"){
      val r=old(d=0)
      eqv((r.cutletId,r.cutletLocalOffset,r.legacyMonthId,
        r.legacyDayInMonth),(1,0,1,1),"Inizio")
    }
    check("giorno 41 non attraversa confine di cotoletta"){
      val r=old(d=41)
      eqv((r.cutletId,r.cutletLocalOffset,r.legacyMonthId,
        r.legacyDayInMonth),(1,41,1,42),"Fine")
    }
    check("giorno 42 apre la seconda cotoletta"){
      val r=old(d=42)
      eqv((r.cutletId,r.cutletLocalOffset),(2,0),"Nuovo inizio")
    }
    check("giorno 84 apre la terza cotoletta"){
      val r=old()
      eqv((r.cutletId,r.cutletLocalOffset),(3,0),"Terza")
    }
    check("giorno 126 apre la quarta cotoletta"){
      eqv((old(d=126).cutletId,old(d=126).cutletLocalOffset),
        (4,0),"Quarta")
    }
    check("giorno 210 apre la sesta cotoletta"){
      eqv((old(d=210).cutletId,old(d=210).cutletLocalOffset),
        (6,0),"Sesta")
    }
    check("il giorno finale ha offset locale 41"){
      val r=old(d=251)
      eqv((r.cutletId,r.cutletLocalOffset),(6,41),"Fine anno")
    }
    check("la cicatrice del giorno 84 rilegge il primo mese"){
      eqv((old().legacyMonthId,old().legacyDayInMonth),
        (1,1),"Nome legacy")
    }
    check("la cicatrice del giorno 126 rilegge primo mese"){
      eqv((old(d=126).legacyMonthId,old(d=126).legacyDayInMonth),
        (1,1),"Primo mese")
    }
    check("su prima cotoletta il legacy coincide con la norma"){
      for(d<-0 until 42){
        val r=old(d=d)
        eqv((r.legacyMonthId,r.legacyDayInMonth),
          normative(Blocks,d),"Prima "+d)
      }
    }
    check("tutti gli inizi di cotoletta tornano al prefisso zero"){
      for(k<-1 until 6){
        val r=old(d=k*42)
        eqv(r.cutletLocalOffset,0,"Inizio "+k)
        eqv(r.legacyDayInMonth,1,"Legacy "+k)
      }
    }
    check("il giorno locale usa sempre una posizione valida"){
      for(d<-0 until 252){
        val r=old(d=d)
        truth(r.cutletLocalOffset>=0 &&
          r.cutletLocalOffset<Blocks.length,"Dominio")
      }
    }
    check("tutti i 252 giorni riproducono il vecchio percorso"){
      for(d<-0 until 252){
        val r=old(d=d)
        val slot=d%42
        eqv(r.cutletLocalOffset,slot,"Slot "+d)
        eqv(r.legacyMonthId,Blocks(slot),"Mese "+d)
      }
    }
    check("17 cotolette con sei mesi conservano la cicatrice"){
      val w=robin(6,Seventeen.sum)
      for(d<-0 until w.length by 19){
        val r=old(Seventeen,SeventeenParts,w,d)
        eqv(r.cutletId,d/42+1,"Cutlet "+d)
        eqv(r.cutletLocalOffset,d%42,"Local "+d)
        eqv(r.legacyMonthId,w(d%42),"Legacy "+d)
      }
    }
    check("4096 vettori randomizzati deterministici"){
      val rng=new Random(48202026L)
      for(k<-1 to 4096){
        val n=6+rng.nextInt(12)
        val g=Vector.fill(n)(42+rng.nextInt(31))
        val p=Vector.fill(n)(1)
        val days=g.sum
        val months=math.max(3,(days+122)/123)
        val w=robin(months,days)
        val d=rng.nextInt(days)
        val r=old(g,p,w,d)
        val expectedCutlet=1+g.scanLeft(0)(_+_).init.tail.count(_<=d)
        val start=g.take(expectedCutlet-1).sum
        val local=d-start
        eqv((r.cutletId,r.cutletLocalOffset),
          (expectedCutlet,local),"Boundary "+k)
        eqv((r.legacyMonthId,r.legacyDayInMonth),
          normative(w,local),"Legacy "+k)
      }
    }
    check("nessuna mutazione degli input del report"){
      val r=old()
      eqv(r.gateGaps,Gaps,"Gaps")
      eqv(r.cutletPartition,Cuts,"Partizione")
      eqv(r.annualWeaving,Blocks,"Tessitura")
      eqv(r.yearDayOffset,84,"Offset")
    }
    check("il manager conserva due BigInt di oltre 128 bit"){
      val r=new BaseMonsterManager().discover24CutletLocalMonthLookup(
        Huge,-Huge,Gaps,Cuts,Blocks,84)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Bersaglio")
    }
    check("il manager riproduce fase trace e stato"){
      val r=new BaseMonsterManager().discover24CutletLocalMonthLookup(
        1,2,Gaps,Cuts,Blocks,84)
      eqv(r.phase,"DISCOVERY_24_CUTLET_LOCAL_MONTH_LOOKUP","Fase")
      eqv(r.status,"LEGACY_CUTLET_LOCAL_MONTH_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_24_CUTLET_LOCAL_MONTH_LOOKUP"),
        "Trace")
    }
    check("metriche dei manager isolate"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      a.discover24CutletLocalMonthLookup(1,2,Gaps,Cuts,Blocks,84)
      b.discover24CutletLocalMonthLookup(3,4,Gaps,Cuts,Woven,126)
      eqv(a.metricsSnapshot("discovery24.cutlet.local.month.calls"),
        BigInt(1),"A")
      eqv(b.metricsSnapshot("discovery24.cutlet.local.month.calls"),
        BigInt(1),"B")
    }
    check("riuso manager non modifica report restituito"){
      val m=new BaseMonsterManager
      val first=m.discover24CutletLocalMonthLookup(
        1,2,Gaps,Cuts,Blocks,84)
      val before=first.copy()
      m.discover24CutletLocalMonthLookup(3,4,Gaps,Cuts,Blocks,126)
      eqv(first,before,"Immutabile")
    }
    check("rifiuta cinque cotolette"){
      rejectArg("Cinque"){old(p=Vector(1,1,1,1,2))}
    }
    check("rifiuta diciotto cotolette"){
      val g=Vector.fill(18)(42)
      val w=robin(7,g.sum)
      rejectArg("Diciotto"){old(g,Vector.fill(18)(1),w,1)}
    }
    check("rifiuta intervallo di porta 41"){
      val g=Vector(41,42,42,42,42,43)
      rejectArg("Porta"){old(g,Cuts,Blocks,1)}
    }
    check("rifiuta intervallo di porta 964"){
      val g=Vector(964,42,42,42,42,42)
      rejectArg("Porta"){old(g,Cuts,Blocks,1)}
    }
    check("rifiuta tessitura più corta dell'anno"){
      rejectArg("Tessitura"){old(w=Blocks.take(251))}
    }
    check("rifiuta offset negativo"){
      rejectArg("Negativo"){old(d = -1)}
    }
    check("rifiuta offset al termine esclusivo"){
      rejectArg("Fine"){old(d=252)}
    }
    check("rifiuta tessitura con apertura non ordinata"){
      rejectArg("Apertura"){old(w=Woven.updated(0,2))}
    }
    check("validator indipendente accetta report integro"){
      new BaseValidationManager().requireDiscovery24Ready(ready())
    }
    check("validator rifiuta ID cutlet falsificato"){
      val c=ready();c.crossLegacyCutletId=Some(2)
      rejectState("Cutlet"){new BaseValidationManager()
        .requireDiscovery24Ready(c)}
    }
    check("validator rifiuta slot locale falsificato"){
      val c=ready();c.crossLegacyLocalOffset=Some(1)
      rejectState("Local"){new BaseValidationManager()
        .requireDiscovery24Ready(c)}
    }
    check("validator rifiuta mese falsificato"){
      val c=ready();c.crossLegacyMonthId=Some(2)
      rejectState("Month"){new BaseValidationManager()
        .requireDiscovery24Ready(c)}
    }
    check("validator rifiuta giorno nel mese falsificato"){
      val c=ready();c.crossLegacyMonthOrdinal=Some(2)
      rejectState("Ordinal"){new BaseValidationManager()
        .requireDiscovery24Ready(c)}
    }
    check("validator rifiuta snapshot falsificata"){
      val c=ready();c.crossYearDayOffset=Some(85)
      rejectState("Snapshot"){new BaseValidationManager()
        .requireDiscovery24Ready(c)}
    }
    check("validator rifiuta trace falsificata"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager()
        .requireDiscovery24Ready(c)}
    }
    check("validator rifiuta status falsificato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Stato"){new BaseValidationManager()
        .requireDiscovery24Ready(c)}
    }
    check("handler rifiuta bootstrap incompleto"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_24_CUTLET_LOCAL_MONTH_LOOKUP"
      c.crossGateGaps=Some(Gaps)
      c.crossCutletPartition=Some(Cuts)
      c.crossAnnualWeaving=Some(Blocks)
      c.crossYearDayOffset=Some(84)
      rejectState("Bootstrap"){new Discovery24CutletLocalMonthHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.crossLegacyMonthId.isEmpty,"No publish")
    }
    check("nessun oracolo dei test nel codice di produzione"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val source=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!source.contains("NormativeOracle"),"Oracle test-only")
    }
    check("Stage47 firmato e PATCH24 non anticipata"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains(
        "STAGE_47_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_54_PASS_0_FAIL"),
        "Stage47")
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .get.split("=",2)(1).toInt
      truth(current>=48 && done>=48 && done<=current,
        "Firma Stage48 conservata")
      truth(st.contains(
        "STAGE_48_NATIVE_VERIFICATION=PASS_EXPECTED_RED_44_PASS_3_FAIL"),
        "Stage48 intenzionale")
      val walk=Files.walk(root().resolve("src/main/scala"))
      val source=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      if(current==48)
        truth(!source.contains("def cutletLocalMonthPatch("),"PATCH24 assente")
      else
        truth(source.contains("def cutletLocalMonthPatch("),"PATCH24 successiva")
    }
    // SOLO queste tre equivalenze normative falliscono intenzionalmente.
    Vector(
      ("CUTLET3_MONTH2_NAME",Blocks,84,"MONTH"),
      ("CUTLET4_MONTH2_ORDINAL",Blocks,126,"ORDINAL"),
      ("CUTLET6_YEAR_END",Blocks,251,"ORDINAL")
    ).foreach {case (tag,w,d,kind) =>
      check("equivalenza normativa "+tag){
        val r=new BaseMonsterManager().discover24CutletLocalMonthLookup(
          Huge,-Huge,Gaps,Cuts,w,d)
        val norm=normative(w,d)
        if(kind=="MONTH")
          eqv(r.legacyMonthId,norm._1,
            "Coordinate anno/cotoletta: "+tag)
        else
          eqv(r.legacyDayInMonth,norm._2,
            "Coordinate anno/cotoletta: "+tag)
      }
    }
    println("\nRISULTATO STADIO 48: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
