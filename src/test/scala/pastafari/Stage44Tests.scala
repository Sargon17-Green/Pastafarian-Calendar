package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY22: il mese intercalato non conta giorni assoluti. */
object Stage44Tests {
  private var passed=0
  private var failed=0
  private val Contiguous=Vector.fill(84)(1)++Vector.fill(84)(2)++
    Vector.fill(84)(3)
  private val Interleaved=Vector.tabulate(252)(i=>i%3+1)
  private val Huge=(BigInt(1)<<16384)+44

  // Costruttore test-only per tessiture valide con aperture e
  // chiusure ordinate: eventuali eccedenze vanno ai mesi finali.
  private def roundRobin(months:Int,total:Int):Vector[Int]={
    val q=total/months
    val r=total%months
    val counts=Vector.tabulate(months)(i=>
      q+(if(i>=months-r)1 else 0))
    (0 until counts.max).toVector.flatMap(k=>
      (1 to months).collect {case id if counts(id-1)>k=>id})
  }
  private val FortySeven=roundRobin(47,252)
  private val Maximum=roundRobin(47,5778)

  private def check(label:String)(test: => Unit):Unit={
    try {test;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable=>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(x:Boolean,label:String):Unit={
    if(!x)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(test: => Unit):Unit={
    var rejected=false
    try test catch{case _:IllegalArgumentException=>rejected=true}
    truth(rejected,label)
  }
  private def rejectState(label:String)(test: => Unit):Unit={
    var rejected=false
    try test catch{case _:IllegalStateException=>rejected=true}
    truth(rejected,label)
  }
  private def old(
    w:Vector[Int]=Interleaved,d:Int=1
  ):LegacyMonthOrdinalGlobalDayResult =
    LegacyMonthOrdinalGlobalDayAdapter.oldMonthOrdinalGlobalDay(w,d)
  private def manager(
    w:Vector[Int]=Interleaved,d:Int=1
  ):Discovery22MonthOrdinalGlobalDayReport =
    new BaseMonsterManager().discover22MonthOrdinalGlobalDay(
      Huge,-Huge,w,d)

  // Un oracolo solo per i test: conta esclusivamente il mese
  // bersaglio fra i giorni 0..d, mai d+1 indiscriminato.
  private def normative(w:Vector[Int],d:Int):Int={
    val id=w(d)
    var ordinal=0
    var index=0
    while(index<=d){
      if(w(index)==id) ordinal+=1
      index+=1
    }
    ordinal
  }
  private def ready():BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_22_MONTH_ORDINAL_GLOBAL_DAY"
    c.monthOrdinalWeaving=Some(Interleaved)
    c.monthOrdinalDayOffset=Some(1)
    new Discovery22MonthOrdinalGlobalDayHandler(
      new BaseMetricsShell).handle(c)
    c
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir"))
      .toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) &&
       p.getParent!=null)p=p.getParent
    p
  }
  def main(args:Array[String]):Unit={
    check("i tre mesi contigui rispettano la lunghezza minima"){
      eqv(Contiguous.length,252,"Anno")
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Contiguous))
    }
    check("la tessitura intercalata 1-2-3 è valida"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Interleaved))
    }
    check("47 mesi occupano 252 giorni"){
      eqv(FortySeven.length,252,"Anno minimo")
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(FortySeven))
    }
    check("47 mesi occupano al massimo 5778 giorni"){
      eqv(Maximum.length,5778,"Anno massimo")
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Maximum))
    }
    check("il primo giorno della prima mensilità è uno"){
      val r=old(d=0)
      eqv(r.selectedMonthId,1,"Mese")
      eqv(r.legacyDayInMonth,1,"Giorno")
    }
    check("il secondo giorno ha posizione storica due"){
      val r=old()
      eqv(r.selectedMonthId,2,"Mese")
      eqv(r.legacyDayInMonth,2,"Cicatrice")
    }
    check("l'ultimo giorno ha posizione storica 252"){
      eqv(old(d=251).legacyDayInMonth,252,"Giorno")
    }
    check("il mese corrente è sempre quello della tessitura"){
      for(d<-0 until 252){
        eqv(old(d=d).selectedMonthId,Interleaved(d),"Mese "+d)
      }
    }
    check("ogni giorno storico restituisce offset + 1"){
      for(d<-0 until 252){
        eqv(old(d=d).legacyDayInMonth,d+1,"Offset "+d)
      }
    }
    check("ogni giorno contiguo restituisce il mese corretto"){
      for(d<-0 until 252)
        eqv(old(Contiguous,d).selectedMonthId,Contiguous(d),"Mese "+d)
    }
    check("gli 84 giorni del primo mese contiguo coincidono"){
      for(d<-0 until 84)
        eqv(old(Contiguous,d).legacyDayInMonth,
          normative(Contiguous,d),"Giorno "+d)
    }
    check("la cicatrice riemerge al confine del secondo mese"){
      eqv(old(Contiguous,84).legacyDayInMonth,85,"Secondo mese")
      eqv(normative(Contiguous,84),1,"Norma")
    }
    check("la durata di ogni mese resta tra 4 e 123"){
      for(w<-Vector(Contiguous,Interleaved,FortySeven,Maximum);
          id<-1 to w.max){
        val n=w.count(_==id)
        truth(n>=4 && n<=123,"Durata "+id)
      }
    }
    check("tutti i 3..47 mesi producono tessiture valide"){
      for(months<-3 to 47){
        val w=roundRobin(months,252)
        LegacyDaywiseWeavingAdapter.validateCandidates(Vector(w))
      }
    }
    check("la tessitura massima riporta 5778 nel giorno finale"){
      eqv(old(Maximum,5777).legacyDayInMonth,5778,"Massimo")
    }
    check("1024 tessiture con offset casuali restano deterministiche"){
      val rng=new Random(44202026L)
      for(k<-1 to 1024){
        val n=3+rng.nextInt(45)
        val w=roundRobin(n,252)
        val d=rng.nextInt(252)
        val r=old(w,d)
        eqv(r.legacyDayInMonth,d+1,"Giorno "+k)
        eqv(r.selectedMonthId,w(d),"Mese "+k)
      }
    }
    check("report conserva interamente input e identità"){
      val r=old()
      eqv(r.annualWeaving,Interleaved,"Tessitura")
      eqv(r.dayOffset,1,"Offset")
    }
    check("manager conserva grandi BigInt"){
      val r=manager()
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Target")
    }
    check("manager conserva fase e trace"){
      val r=manager()
      eqv(r.phase,"DISCOVERY_22_MONTH_ORDINAL_GLOBAL_DAY","Fase")
      eqv(r.status,"LEGACY_MONTH_ORDINAL_READY","Stato")
      eqv(r.trace,
        Vector("BOOT","DISCOVERY_22_MONTH_ORDINAL_GLOBAL_DAY"),"Trace")
    }
    check("manager ha metriche isolate"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      a.discover22MonthOrdinalGlobalDay(1,2,Interleaved,1)
      b.discover22MonthOrdinalGlobalDay(3,4,Contiguous,84)
      eqv(a.metricsSnapshot("discovery22.month.ordinal.calls"),BigInt(1),"A")
      eqv(b.metricsSnapshot("discovery22.month.ordinal.calls"),BigInt(1),"B")
    }
    check("i report non cambiano dopo due richieste"){
      val m=new BaseMonsterManager
      val a=m.discover22MonthOrdinalGlobalDay(1,2,Interleaved,1)
      val snapshot=a.copy()
      m.discover22MonthOrdinalGlobalDay(3,4,Interleaved,4)
      eqv(a,snapshot,"Report")
    }
    check("rifiuta un anno sotto 252 giorni"){
      rejectArg("Corto"){old(Vector.tabulate(251)(i=>i%3+1),1)}
    }
    check("rifiuta un anno superiore a 5778 giorni"){
      rejectArg("Lungo"){old(Maximum:+1,1)}
    }
    check("rifiuta due soli mesi"){
      rejectArg("Mesi"){old(Vector.tabulate(252)(i=>i%2+1),1)}
    }
    check("rifiuta quarantotto mesi"){
      rejectArg("Mesi"){old(Vector.tabulate(288)(i=>i%48+1),1)}
    }
    check("rifiuta durata mese sotto quattro"){
      rejectArg("Durata"){old(Vector.fill(3)(1)++
        Vector.fill(123)(2)++Vector.fill(126)(3),1)}
    }
    check("rifiuta durata mese sopra 123"){
      rejectArg("Durata"){old(Vector.fill(124)(1)++
        Vector.fill(64)(2)++Vector.fill(64)(3),1)}
    }
    check("rifiuta apertura dei mesi fuori ordine"){
      rejectArg("Apertura"){old(Interleaved.updated(0,2),1)}
    }
    check("rifiuta chiusura dei mesi fuori ordine"){
      // Tutti i mesi durano 84 giorni e sono aperti 1,2,3,
      // ma la chiusura avviene 1,3,2: test esclusivo d'ordine.
      val w=Vector(1,2,3)++Vector.fill(83)(1)++
        Vector.fill(83)(3)++Vector.fill(83)(2)
      rejectArg("Chiusura"){old(w,1)}
    }
    check("rifiuta offset negativo"){
      rejectArg("Offset"){old(d = -1)}
    }
    check("rifiuta offset alla fine esatta"){
      rejectArg("Offset"){old(d=252)}
    }
    check("validator indipendente accetta stato integro"){
      new BaseValidationManager().requireDiscovery22Ready(ready())
    }
    check("validator rifiuta mese storico falso"){
      val c=ready();c.legacyMonthOrdinalMonthId=Some(1)
      rejectState("Mese"){new BaseValidationManager()
        .requireDiscovery22Ready(c)}
    }
    check("validator rifiuta giorno storico falso"){
      val c=ready();c.legacyDayInMonth=Some(1)
      rejectState("Giorno"){new BaseValidationManager()
        .requireDiscovery22Ready(c)}
    }
    check("validator rifiuta snapshot alterata"){
      val c=ready();c.monthOrdinalDayOffset=Some(2)
      rejectState("Snapshot"){new BaseValidationManager()
        .requireDiscovery22Ready(c)}
    }
    check("validator rifiuta trace ulteriore"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager()
        .requireDiscovery22Ready(c)}
    }
    check("validator rifiuta stato non finale"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Stato"){new BaseValidationManager()
        .requireDiscovery22Ready(c)}
    }
    check("handler non consente di saltare bootstrap"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_22_MONTH_ORDINAL_GLOBAL_DAY"
      c.monthOrdinalWeaving=Some(Interleaved)
      c.monthOrdinalDayOffset=Some(1)
      rejectState("Bootstrap"){new Discovery22MonthOrdinalGlobalDayHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.legacyDayInMonth.isEmpty,"Output non pubblicato")
    }
    check("il validator non usa la norma per falsificare legacy"){
      val c=ready();c.legacyDayInMonth=Some(normative(Interleaved,1))
      rejectState("Legacy"){new BaseValidationManager()
        .requireDiscovery22Ready(c)}
    }
    check("nessun oracolo di test compare nel codice produttivo"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val code=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!code.contains("NormativeOracle"),"Oracolo test-only")
    }
    check("Stage43 è già certificato nel ledger"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains(
        "STAGE_43_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_55_PASS_0_FAIL"),
        "Firma Stage43")
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .get.split("=",2)(1).toInt
      truth(current>=44 && done>=44 && done<=current,
        "Stadio 44 certificato")
    }
    check("nessuna PATCH22 è stata anticipata"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val code=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      if(current==44)
        truth(!code.contains("def monthOrdinalPatch("),"PATCH22 assente")
      else
        truth(code.contains("def monthOrdinalPatch("),"PATCH22 successiva")
    }
    // Solo queste tre equivalenze normative falliscono volutamente.
    Vector(
      ("SECOND_MONTH_START",Contiguous,84),
      ("INTERLEAVED_MONTH2_SECOND_OCCURRENCE",Interleaved,4),
      ("FINAL_MONTH_YEAR_END",Interleaved,251)
    ).foreach {case (label,w,d) =>
      check("equivalenza normativa giorno "+label){
        val actual=new BaseMonsterManager()
          .discover22MonthOrdinalGlobalDay(Huge,-Huge,w,d)
        eqv(actual.legacyDayInMonth,normative(w,d),
          "Giorno assoluto invece dell'occorrenza: "+label)
      }
    }
    println("\nRISULTATO STADIO 44: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
