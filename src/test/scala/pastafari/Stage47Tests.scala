package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH23: il giorno nel mese attraversa intercalazioni reali. */
object Stage47Tests {
  private var passed=0
  private var failed=0
  private val Blocks=Vector.fill(84)(1)++Vector.fill(84)(2)++
    Vector.fill(84)(3)
  private val Woven=Vector.tabulate(252)(i=>i%3+1)
  private val Huge=(BigInt(1)<<16384)+47
  private def robin(m:Int,days:Int):Vector[Int]={
    val q=days/m
    val rem=days%m
    val counts=Vector.tabulate(m)(i=>q+(if(i>=m-rem)1 else 0))
    (0 until counts.max).toVector.flatMap(k=>
      (1 to m).collect {case id if counts(id-1)>k=>id})
  }
  private val W47=robin(47,252)
  private val WMax=robin(47,5778)

  private def check(name:String)(body: => Unit):Unit={
    try {body;passed+=1;println("PASS — "+name)}
    catch {case e:Throwable=>
      failed+=1;println("FAIL — "+name+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[T](actual:T,expected:T,label:String):Unit={
    if(actual!=expected)throw new AssertionError(
      label+": atteso="+expected+", ottenuto="+actual)
  }
  private def truth(value:Boolean,label:String):Unit={
    if(!value)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(work: => Unit):Unit={
    var denied=false
    try work catch {case _:IllegalArgumentException=>denied=true}
    truth(denied,label)
  }
  private def rejectState(label:String)(work: => Unit):Unit={
    var denied=false
    try work catch {case _:IllegalStateException=>denied=true}
    truth(denied,label)
  }
  private def old(w:Vector[Int]=Woven,d:Int=1):
      LegacyContiguousMonthResult =
    LegacyContiguousMonthAdapter.oldContiguousDayInMonth(w,d)
  private def patched(w:Vector[Int]=Woven,d:Int=1):
      Patch23ContiguousMonthResult =
    Patch23ContiguousMonthWrapper.contiguousMonthPatch(w,d)

  // Oracle indipendente test-only: conta le occorrenze del mese
  // nell'intero prefisso, senza usare alcuna funzione di produzione.
  private def oracle(w:Vector[Int],d:Int):Int={
    var total=0
    var index=0
    val month=w(d)
    while(index<=d) {
      if(w(index)==month)total+=1
      index+=1
    }
    total
  }
  private def root():java.nio.file.Path={
    var path=Paths.get(System.getProperty("user.dir"))
      .toAbsolutePath.normalize()
    while(!Files.exists(path.resolve("DEVELOPMENT_STAGE.md")) &&
      path.getParent!=null)path=path.getParent
    path
  }
  private def ready(w:Vector[Int]=Woven,d:Int=1):
      BaseMonsterContext = {
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_23_CONTIGUOUS_MONTH_ASSUMPTION"
    c.monthBlockWeaving=Some(w)
    c.monthBlockDayOffset=Some(d)
    val metrics=new BaseMetricsShell
    new Discovery23ContiguousMonthHandler(metrics).handle(c)
    new BaseValidationManager().requireDiscovery23Ready(c)
    c.phase="PATCH_23_CONTIGUOUS_MONTH_ASSUMPTION"
    new Patch23ContiguousMonthHandler(metrics).handle(c)
    c
  }

  def main(args:Array[String]):Unit={
    check("tre mesi con blocchi consecutivi formano un anno valido"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Blocks))
    }
    check("tre mesi alternati formano un anno valido"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Woven))
    }
    check("47 mesi in 252 giorni sono validi"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(W47))
    }
    check("47 mesi in 5778 giorni sono validi"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(WMax))
    }
    check("giorno zero apre il primo mese"){
      eqv(patched(d=0).correctedDayInMonth,1,"Inizio")
    }
    check("giorno 1 apre il secondo mese"){
      eqv(patched(d=1).correctedDayInMonth,1,"Secondo")
    }
    check("giorno 2 apre il terzo mese"){
      eqv(patched(d=2).correctedDayInMonth,1,"Terzo")
    }
    check("giorno 3 è la seconda occorrenza del primo mese"){
      eqv(patched(d=3).correctedDayInMonth,2,"Primo")
    }
    check("giorno 4 è la seconda occorrenza del secondo mese"){
      eqv(patched(d=4).correctedDayInMonth,2,"Secondo")
    }
    check("giorno 5 è la seconda occorrenza del terzo mese"){
      eqv(patched(d=5).correctedDayInMonth,2,"Terzo")
    }
    check("giorno 249 è 84esimo giorno del mese uno"){
      eqv(patched(d=249).correctedDayInMonth,84,"Fine mese 1")
    }
    check("giorno 251 è 84esimo giorno del mese tre"){
      eqv(patched(d=251).correctedDayInMonth,84,"Fine mese 3")
    }
    check("giorno 84 è primo giorno del secondo blocco"){
      eqv(patched(Blocks,84).correctedDayInMonth,1,"Blocco 2")
    }
    check("giorno 168 è primo giorno del terzo blocco"){
      eqv(patched(Blocks,168).correctedDayInMonth,1,"Blocco 3")
    }
    check("giorno finale di blocchi consecutivi è 84"){
      eqv(patched(Blocks,251).correctedDayInMonth,84,"Blocco 3")
    }
    check("tutti i 252 giorni alternati coincidono con l'oracolo"){
      for(d<-0 until Woven.size)
        eqv(patched(Woven,d).correctedDayInMonth,
          oracle(Woven,d),"Giorno "+d)
    }
    check("tutti i 252 giorni contigui coincidono con l'oracolo"){
      for(d<-0 until Blocks.size)
        eqv(patched(Blocks,d).correctedDayInMonth,
          oracle(Blocks,d),"Giorno "+d)
    }
    check("i 47 mesi di anno minimo coincidono ogni giorno"){
      for(d<-0 until W47.size)
        eqv(patched(W47,d).correctedDayInMonth,
          oracle(W47,d),"Giorno "+d)
    }
    check("l'anno massimo coincide in punti distribuiti e finale"){
      val days=(0 until WMax.size by 13).toVector :+ (WMax.size-1)
      for(d<-days)
        eqv(patched(WMax,d).correctedDayInMonth,
          oracle(WMax,d),"Giorno "+d)
    }
    check("per mesi 3..47 le durate e i contatori sono coerenti"){
      for(n<-3 to 47){
        val w=robin(n,252)
        for(d<-0 until 252 by 9)
          eqv(patched(w,d).correctedDayInMonth,
            oracle(w,d),"Numero "+n+" giorno "+d)
      }
    }
    check("il risultato preserva la cicatrice negativa del mese due"){
      val r=patched()
      eqv(r.historical.legacyDayInMonth,-82,"Vecchio")
      eqv(r.correctedDayInMonth,1,"Nuovo")
    }
    check("il risultato preserva la cicatrice negativa del mese tre"){
      val r=patched(d=2)
      eqv(r.historical.legacyDayInMonth,-165,"Vecchio")
      eqv(r.correctedDayInMonth,1,"Nuovo")
    }
    check("su blocchi consecutivi il vecchio e il nuovo coincidono"){
      for(d<-0 until Blocks.size by 7){
        val r=patched(Blocks,d)
        eqv(r.historical.legacyDayInMonth,r.correctedDayInMonth,
          "Blocco "+d)
      }
    }
    check("il wrapper invoca realmente l'adapter storico"){
      for((w,d)<-Vector((Woven,1),(Woven,5),
        (Woven,249),(Blocks,84),(W47,251))){
        eqv(patched(w,d).historical,
          LegacyContiguousMonthAdapter.oldContiguousDayInMonth(w,d),
          "Adapter")
      }
    }
    check("la risposta non muta gli input"){
      val r=patched()
      eqv(r.historical.annualWeaving,Woven,"Weaving")
      eqv(r.historical.dayOffset,1,"Indice")
      eqv(r.historical.monthLengths,Vector(84,84,84),"Lunghezze")
    }
    check("4096 permutazioni di 3..47 mesi con offset deterministici"){
      val rng=new Random(47202026L)
      for(i<-1 to 4096){
        val months=3+rng.nextInt(45)
        val w=robin(months,252)
        val d=rng.nextInt(w.size)
        val r=patched(w,d)
        eqv(r.correctedDayInMonth,oracle(w,d),"Corretto "+i)
        val before=r.historical.monthLengths.take(w(d)-1).sum
        eqv(r.historical.legacyDayInMonth,
          d-before+1,"Storico "+i)
      }
    }
    check("4096 richieste su due manager con metriche isolate"){
      val rng=new Random(47212026L)
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      for(i<-1 to 4096){
        val months=3+rng.nextInt(45)
        val w=robin(months,252)
        val d=rng.nextInt(w.size)
        val manager=if(i%2==0)a else b
        val r=manager.patch23ContiguousMonthAssumption(
          BigInt(i),-Huge,w,d)
        eqv(r.correctedDayInMonth,oracle(w,d),"Manager "+i)
      }
      eqv(a.metricsSnapshot("patch23.contiguous.month.calls"),
        BigInt(2048),"A")
      eqv(b.metricsSnapshot("patch23.contiguous.month.calls"),
        BigInt(2048),"B")
    }
    check("date BigInt di lunghezza oltre 128 bit sono inalterate"){
      val r=new BaseMonsterManager().patch23ContiguousMonthAssumption(
        Huge,-Huge,Woven,1)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Bersaglio")
    }
    check("manager registra boot discovery patch nella stessa trace"){
      val r=new BaseMonsterManager().patch23ContiguousMonthAssumption(
        1,2,Woven,1)
      eqv(r.trace,Vector("BOOT",
        "DISCOVERY_23_CONTIGUOUS_MONTH_ASSUMPTION",
        "PATCH_23_CONTIGUOUS_MONTH_ASSUMPTION"),"Trace")
      eqv(r.status,"PATCH_23_READY","Status")
      truth(r.patchApplied,"Flag")
    }
    check("manager registra le metriche delle due fasi"){
      val m=new BaseMonsterManager
      m.patch23ContiguousMonthAssumption(1,2,Woven,1)
      eqv(m.metricsSnapshot("discovery23.contiguous.month.calls"),
        BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch23.contiguous.month.calls"),
        BigInt(1),"Patch")
    }
    check("i report già restituiti restano immutabili"){
      val m=new BaseMonsterManager
      val r=m.patch23ContiguousMonthAssumption(1,2,Woven,1)
      val frozen=r.copy()
      m.patch23ContiguousMonthAssumption(3,4,Blocks,84)
      eqv(r,frozen,"Immutabile")
    }
    check("due manager non condividono contatori"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      a.patch23ContiguousMonthAssumption(1,2,Woven,1)
      b.patch23ContiguousMonthAssumption(3,4,Woven,4)
      eqv(a.metricsSnapshot("patch23.contiguous.month.calls"),
        BigInt(1),"A")
      eqv(b.metricsSnapshot("patch23.contiguous.month.calls"),
        BigInt(1),"B")
    }
    check("rifiuta durata annua inferiore a 252"){
      rejectArg("Anno"){patched(Woven.take(251),1)}
    }
    check("rifiuta mese con 124 giorni"){
      rejectArg("Mese"){patched(Vector.fill(124)(1)++
        Vector.fill(64)(2)++Vector.fill(64)(3),1)}
    }
    check("rifiuta meno di tre mesi"){
      rejectArg("Mesi"){patched(Vector.tabulate(252)(i=>i%2+1),1)}
    }
    check("rifiuta più di 47 mesi"){
      rejectArg("Mesi"){patched(Vector.tabulate(288)(i=>i%48+1),1)}
    }
    check("rifiuta apertura fuori ordine"){
      rejectArg("Apertura"){patched(Woven.updated(0,2),1)}
    }
    check("rifiuta offset negativo"){
      rejectArg("Negativo"){patched(d = -1)}
    }
    check("rifiuta offset pari alla lunghezza dell'anno"){
      rejectArg("Fine"){patched(d=252)}
    }
    check("validator indipendente accetta stato integro"){
      new BaseValidationManager().requirePatch23Ready(ready())
    }
    check("validator indipendente respinge giorno patch falsificato"){
      val c=ready();c.patch23CorrectedDayInMonth=Some(2)
      rejectState("Patch"){new BaseValidationManager()
        .requirePatch23Ready(c)}
    }
    check("validator indipendente respinge giorno legacy falsificato"){
      val c=ready();c.legacyMonthBlockOrdinal=Some(1)
      rejectState("Legacy"){new BaseValidationManager()
        .requirePatch23Ready(c)}
    }
    check("validator indipendente respinge ID legacy falsificato"){
      val c=ready();c.legacyMonthBlockMonthId=Some(1)
      rejectState("Mese"){new BaseValidationManager()
        .requirePatch23Ready(c)}
    }
    check("validator indipendente respinge durate falsificate"){
      val c=ready();c.legacyMonthBlockLengths=Some(Vector(1,2,3))
      rejectState("Lunghezze"){new BaseValidationManager()
        .requirePatch23Ready(c)}
    }
    check("validator indipendente respinge snapshot modificata"){
      val c=ready();c.monthBlockDayOffset=Some(2)
      rejectState("Snapshot"){new BaseValidationManager()
        .requirePatch23Ready(c)}
    }
    check("validator indipendente respinge trace extra"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager()
        .requirePatch23Ready(c)}
    }
    check("validator indipendente respinge status errato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Status"){new BaseValidationManager()
        .requirePatch23Ready(c)}
    }
    check("validator indipendente respinge flag rimosso"){
      val c=ready();c.patch23Applied=false
      rejectState("Flag"){new BaseValidationManager()
        .requirePatch23Ready(c)}
    }
    check("handler non permette di saltare DISCOVERY23"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_23_CONTIGUOUS_MONTH_ASSUMPTION"
      c.monthBlockWeaving=Some(Woven)
      c.monthBlockDayOffset=Some(1)
      rejectState("Bootstrap"){new Patch23ContiguousMonthHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patch23CorrectedDayInMonth.isEmpty,"Nessun output")
    }
    check("handler non pubblica se la snapshot cambia"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_23_CONTIGUOUS_MONTH_ASSUMPTION"
      c.monthBlockWeaving=Some(Woven)
      c.monthBlockDayOffset=Some(1)
      new Discovery23ContiguousMonthHandler(
        new BaseMetricsShell).handle(c)
      c.phase="PATCH_23_CONTIGUOUS_MONTH_ASSUMPTION"
      c.monthBlockDayOffset=Some(4)
      rejectState("Snapshot"){new Patch23ContiguousMonthHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patch23CorrectedDayInMonth.isEmpty &&
        !c.patch23Applied,"Pubblicazione atomica")
    }
    check("la cicatrice DISCOVERY23 resta osservabile da sola"){
      val r=new BaseMonsterManager().discover23ContiguousMonthAssumption(
        1,2,Woven,1)
      eqv(r.legacyDayInMonth,-82,"Cicatrice")
    }
    check("PATCH22 preserva l'ordinale corretto sulla tessitura"){
      val r=new BaseMonsterManager().patch22MonthOrdinalGlobalDay(
        1,2,Woven,4)
      eqv(r.correctedDayInMonth,2,"PATCH22")
    }
    check("nessun oracolo test-only è usato dalla produzione"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val text=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!text.contains("NormativeOracle"),"Solo test")
      truth(text.contains("def contiguousMonthPatch("),"PATCH23")
    }
    check("Stage46 mantiene le tre divergenze certificate"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains(
        "STAGE_46_NATIVE_VERIFICATION=PASS_EXPECTED_RED_40_PASS_3_FAIL"),
        "Stage46")
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      val done=st.linesIterator.find(
        _.startsWith("LAST_COMPLETED_STAGE="))
        .get.split("=",2)(1).toInt
      truth(current>=47 && done>=46 && done<=current,
        "Stage47 aperto")
    }
    println("\nRISULTATO STADIO 47: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
