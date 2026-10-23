package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY23: mesi intercalati contro l'assunzione di blocchi. */
object Stage46Tests {
  private var passed=0
  private var failed=0
  private val Blocks=Vector.fill(84)(1)++Vector.fill(84)(2)++
    Vector.fill(84)(3)
  private val Woven=Vector.tabulate(252)(i=>i%3+1)
  private val Huge=(BigInt(1)<<16384)+46
  private def robin(m:Int,days:Int):Vector[Int]={
    val q=days/m;val r=days%m
    val counts=Vector.tabulate(m)(i=>q+(if(i>=m-r)1 else 0))
    (0 until counts.max).toVector.flatMap(j=>
      (1 to m).collect{case id if counts(id-1)>j=>id})
  }
  private val W47=robin(47,252)
  private val WMax=robin(47,5778)
  private def check(label:String)(body: => Unit):Unit={
    try{body;passed+=1;println("PASS — "+label)}
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
  private def old(
    w:Vector[Int]=Woven,d:Int=1
  ):LegacyContiguousMonthResult =
    LegacyContiguousMonthAdapter.oldContiguousDayInMonth(w,d)
  private def norm(w:Vector[Int],d:Int):Int={
    val id=w(d)
    var seen=0;var j=0
    while(j<=d) {
      if(w(j)==id)seen+=1
      j+=1
    }
    seen
  }
  private def ready():BaseMonsterContext={
    val ctx=BaseMonsterContext(Huge,-Huge)
    ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
    ctx.phase="DISCOVERY_23_CONTIGUOUS_MONTH_ASSUMPTION"
    ctx.monthBlockWeaving=Some(Woven)
    ctx.monthBlockDayOffset=Some(1)
    new Discovery23ContiguousMonthHandler(
      new BaseMetricsShell).handle(ctx)
    ctx
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir"))
      .toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&
       p.getParent!=null)p=p.getParent
    p
  }
  def main(args:Array[String]):Unit={
    check("tessitura di blocchi è valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Blocks))
    }
    check("tessitura alternata è valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Woven))
    }
    check("47 mesi di anno minimo sono validi"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(W47))
    }
    check("47 mesi di anno massimo sono validi"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(WMax))
    }
    check("anno minimo contiene 252 giorni"){
      eqv(Woven.size,252,"Anno")
    }
    check("anno massimo contiene 5778 giorni"){
      eqv(WMax.size,5778,"Anno")
    }
    check("durate dei mesi ricavate dalla tessitura"){
      eqv(old().monthLengths,Vector(84,84,84),"Durate")
    }
    check("mese del giorno proviene dalla tessitura"){
      eqv(old().selectedMonthId,2,"Mese")
    }
    check("legacy giorno zero è uno"){
      eqv(old(d=0).legacyDayInMonth,1,"Inizio")
    }
    check("legacy primo giorno del secondo mese alternato è negativo"){
      eqv(old().legacyDayInMonth,-82,"Cicatrice")
    }
    check("legacy primo giorno del terzo mese alternato è negativo"){
      eqv(old(d=2).legacyDayInMonth,-165,"Cicatrice")
    }
    check("un blocco contiguo inizia il mese 2 da uno"){
      eqv(old(Blocks,84).legacyDayInMonth,1,"Blocco")
    }
    check("un blocco contiguo inizia il mese 3 da uno"){
      eqv(old(Blocks,168).legacyDayInMonth,1,"Blocco")
    }
    check("tutti i giorni dei blocchi coincidono con la norma"){
      for(d<-0 until 252)
        eqv(old(Blocks,d).legacyDayInMonth,norm(Blocks,d),
          "Blocco "+d)
    }
    check("in un mese alternato lo storico segue i prefissi"){
      for(d<-0 until 252) {
        val r=old(d=d)
        val expected=d-r.monthLengths.take(r.selectedMonthId-1).sum+1
        eqv(r.legacyDayInMonth,expected,"Giorno "+d)
      }
    }
    check("tutti i giorni dell'anno massimo preservano la cicatrice"){
      val lengths=Vector.tabulate(47)(j=>WMax.count(_==j+1))
      // Un campionamento distribuito evita di ricontare 47 durate
      // per ciascuno dei 5778 giorni; gli estremi sono espliciti.
      val offsets=(0 until WMax.size by 17).toVector :+ (WMax.size-1)
      for(d<-offsets) {
        val r=old(WMax,d)
        eqv(r.monthLengths,lengths,"Durate "+d)
        eqv(r.legacyDayInMonth,
          d-lengths.take(WMax(d)-1).sum+1,"Legacy "+d)
      }
    }
    check("i 3..47 mesi sintetici rispettano la firma legacy"){
      for(months<-3 to 47) {
        val w=robin(months,252)
        val counts=Vector.tabulate(months)(j=>w.count(_==j+1))
        for(d<-0 until w.size by 5) {
          val r=old(w,d)
          eqv(r.legacyDayInMonth,
            d-counts.take(w(d)-1).sum+1,"Numero "+months)
        }
      }
    }
    check("1024 vettori deterministici senza contaminazione"){
      val rng=new Random(46202026L)
      for(k<-1 to 1024){
        val months=3+rng.nextInt(45)
        val w=robin(months,252)
        val d=rng.nextInt(w.size)
        val result=old(w,d)
        eqv(result.selectedMonthId,w(d),"Mese "+k)
        eqv(result.legacyDayInMonth,
          d-result.monthLengths.take(w(d)-1).sum+1,"Giorno "+k)
      }
    }
    check("tutti gli input sono preservati nel report"){
      val r=old()
      eqv(r.annualWeaving,Woven,"Weaving")
      eqv(r.dayOffset,1,"Offset")
      eqv(r.monthLengths,Vector(84,84,84),"Count")
    }
    check("report del manager conserva numeri BigInt grandi"){
      val r=new BaseMonsterManager()
        .discover23ContiguousMonthAssumption(Huge,-Huge,Woven,1)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Target")
    }
    check("manager conserva trace e stato"){
      val r=new BaseMonsterManager()
        .discover23ContiguousMonthAssumption(1,2,Woven,1)
      eqv(r.phase,"DISCOVERY_23_CONTIGUOUS_MONTH_ASSUMPTION","Fase")
      eqv(r.status,"LEGACY_CONTIGUOUS_MONTH_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_23_CONTIGUOUS_MONTH_ASSUMPTION"),"Trace")
    }
    check("metriche indipendenti per due manager"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      a.discover23ContiguousMonthAssumption(1,2,Woven,1)
      b.discover23ContiguousMonthAssumption(3,4,Blocks,84)
      eqv(a.metricsSnapshot("discovery23.contiguous.month.calls"),BigInt(1),"A")
      eqv(b.metricsSnapshot("discovery23.contiguous.month.calls"),BigInt(1),"B")
    }
    check("report immutabile dopo riuso manager"){
      val m=new BaseMonsterManager
      val a=m.discover23ContiguousMonthAssumption(1,2,Woven,1)
      val before=a.copy()
      m.discover23ContiguousMonthAssumption(3,4,Blocks,84)
      eqv(a,before,"Immutabilità")
    }
    check("rifiuta anno da 251 giorni"){
      rejectArg("Anno"){old(Woven.take(251),1)}
    }
    check("rifiuta mese da 124 giorni"){
      rejectArg("Mese"){old(Vector.fill(124)(1)++
        Vector.fill(64)(2)++Vector.fill(64)(3),1)}
    }
    check("rifiuta meno di tre mesi"){
      rejectArg("Mesi"){old(Vector.tabulate(252)(i=>i%2+1),1)}
    }
    check("rifiuta più di 47 mesi"){
      rejectArg("Mesi"){old(Vector.tabulate(288)(i=>i%48+1),1)}
    }
    check("rifiuta apertura non ordinata"){
      rejectArg("Apertura"){old(Woven.updated(0,2),1)}
    }
    check("rifiuta offset negativo"){
      rejectArg("Indice"){old(d = -1)}
    }
    check("rifiuta offset uguale alla durata dell'anno"){
      rejectArg("Indice"){old(d=252)}
    }
    check("validator accetta lo stato integro"){
      new BaseValidationManager().requireDiscovery23Ready(ready())
    }
    check("validator rifiuta giorno legacy falsificato"){
      val c=ready();c.legacyMonthBlockOrdinal=Some(1)
      rejectState("Legacy"){new BaseValidationManager()
        .requireDiscovery23Ready(c)}
    }
    check("validator rifiuta mese legacy falsificato"){
      val c=ready();c.legacyMonthBlockMonthId=Some(1)
      rejectState("Mese"){new BaseValidationManager()
        .requireDiscovery23Ready(c)}
    }
    check("validator rifiuta lunghezze legacy falsificate"){
      val c=ready();c.legacyMonthBlockLengths=Some(Vector(1,2,3))
      rejectState("Durate"){new BaseValidationManager()
        .requireDiscovery23Ready(c)}
    }
    check("validator rifiuta snapshot alterata"){
      val c=ready();c.monthBlockDayOffset=Some(2)
      rejectState("Snapshot"){new BaseValidationManager()
        .requireDiscovery23Ready(c)}
    }
    check("validator rifiuta trace extra"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager()
        .requireDiscovery23Ready(c)}
    }
    check("validator rifiuta status alterato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Status"){new BaseValidationManager()
        .requireDiscovery23Ready(c)}
    }
    check("handler rifiuta un contesto non inizializzato"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_23_CONTIGUOUS_MONTH_ASSUMPTION"
      c.monthBlockWeaving=Some(Woven)
      c.monthBlockDayOffset=Some(1)
      rejectState("Bootstrap"){new Discovery23ContiguousMonthHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.legacyMonthBlockOrdinal.isEmpty,"Output non pubblicato")
    }
    check("nessun oracolo di test nell'implementazione"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val code=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!code.contains("NormativeOracle"),"Solo test")
    }
    check("Stage45 firmato e PATCH23 non anticipata"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains("STAGE_45_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_44_PASS_0_FAIL"),
        "Firma Stage45")
      truth(st.contains("CURRENT_STAGE=46"),"Stage46")
      truth(st.contains("LAST_COMPLETED_STAGE=45"),"Ultimo")
      val walk=Files.walk(root().resolve("src/main/scala"))
      val code=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!code.contains("def contiguousMonthPatch("),"PATCH23 assente")
    }
    // Solo queste tre equivalenze normative sono EXPECTED_RED.
    Vector(
      ("WOVEN_MONTH2_FIRST",Woven,1),
      ("WOVEN_MONTH3_SECOND",Woven,5),
      ("WOVEN_MONTH1_LAST",Woven,249)
    ).foreach{case (label,w,d)=>
      check("equivalenza normativa "+label){
        val r=new BaseMonsterManager()
          .discover23ContiguousMonthAssumption(Huge,-Huge,w,d)
        eqv(r.legacyDayInMonth,norm(w,d),
          "Assunzione di contiguità: "+label)
      }
    }
    println("\nRISULTATO STADIO 46: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
