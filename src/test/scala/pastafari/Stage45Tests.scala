package pastafari

import pastafari.monster._
import java.nio.file.{Files,Paths}
import java.nio.charset.StandardCharsets
import scala.jdk.CollectionConverters._
import scala.util.Random

object Stage45Tests {
  private var passed=0
  private var failed=0
  private val Interleaved=Vector.tabulate(252)(i=>i%3+1)
  private val Contiguous=Vector.fill(84)(1)++Vector.fill(84)(2)++
    Vector.fill(84)(3)
  private val Huge=(BigInt(1)<<16384)+45
  private def robin(n:Int,total:Int):Vector[Int]={
    val q=total/n
    val r=total%n
    val counts=Vector.tabulate(n)(i=>q+(if(i>=n-r)1 else 0))
    (0 until counts.max).toVector.flatMap(k=>
      (1 to n).collect{case id if counts(id-1)>k=>id})
  }
  private val Max=robin(47,5778)
  private def check(label:String)(test: => Unit):Unit={
    try{test;passed+=1;println("PASS — "+label)}
    catch{case e:Throwable=>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](a:A,b:A,label:String):Unit={
    if(a!=b)throw new AssertionError(
      label+": atteso="+b+", ottenuto="+a)
  }
  private def truth(v:Boolean,label:String):Unit={
    if(!v)throw new AssertionError(label)
  }
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
  private def patched(
    w:Vector[Int]=Interleaved,d:Int=1
  ):Patch22MonthOrdinalGlobalDayResult =
    Patch22MonthOrdinalGlobalDayWrapper.monthOrdinalPatch(w,d)
  private def oracle(w:Vector[Int],d:Int):Int={
    val id=w(d)
    var count=0
    for(k<-0 to d)if(w(k)==id)count+=1
    count
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir"))
      .toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) &&
       p.getParent!=null)p=p.getParent
    p
  }
  private def ready():BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_22_MONTH_ORDINAL_GLOBAL_DAY"
    c.monthOrdinalWeaving=Some(Interleaved)
    c.monthOrdinalDayOffset=Some(1)
    val m=new BaseMetricsShell
    new Discovery22MonthOrdinalGlobalDayHandler(m).handle(c)
    new BaseValidationManager().requireDiscovery22Ready(c)
    c.phase="PATCH_22_MONTH_ORDINAL_GLOBAL_DAY"
    new Patch22MonthOrdinalGlobalDayHandler(m).handle(c)
    c
  }
  def main(args:Array[String]):Unit={
    check("giorno zero nel primo mese è uno"){
      eqv(patched(d=0).correctedDayInMonth,1,"Prima")
    }
    check("giorno uno nel secondo mese è uno"){
      eqv(patched().correctedDayInMonth,1,"Intercalato")
    }
    check("giorno due nel terzo mese è uno"){
      eqv(patched(d=2).correctedDayInMonth,1,"Terzo")
    }
    check("giorno tre riapre la seconda occorrenza del primo mese"){
      eqv(patched(d=3).correctedDayInMonth,2,"Primo")
    }
    check("giorno quattro è la seconda occorrenza del secondo mese"){
      eqv(patched(d=4).correctedDayInMonth,2,"Secondo")
    }
    check("giorno 83 è il 28esimo giorno del terzo mese"){
      eqv(patched(d=83).correctedDayInMonth,28,"Terzo")
    }
    check("giorno 84 è il 29esimo giorno del primo mese"){
      eqv(patched(d=84).correctedDayInMonth,29,"Primo")
    }
    check("giorno finale intercalato è l'84esimo giorno del terzo"){
      eqv(patched(d=251).correctedDayInMonth,84,"Ultimo")
    }
    check("giorno 84 in mese contiguo due inizia da uno"){
      eqv(patched(Contiguous,84).correctedDayInMonth,1,"Confine")
    }
    check("giorno 168 in mese contiguo tre inizia da uno"){
      eqv(patched(Contiguous,168).correctedDayInMonth,1,"Confine")
    }
    check("giorno 251 del terzo mese contiguo termina a 84"){
      eqv(patched(Contiguous,251).correctedDayInMonth,84,"Ultimo")
    }
    check("tutti i giorni dell'anno 252 intercalato concordano"){
      for(d<-0 until 252)
        eqv(patched(d=d).correctedDayInMonth,
          oracle(Interleaved,d),"Giorno "+d)
    }
    check("tutti i giorni dell'anno contiguo concordano"){
      for(d<-0 until 252)
        eqv(patched(Contiguous,d).correctedDayInMonth,
          oracle(Contiguous,d),"Giorno "+d)
    }
    check("tutti i giorni dell'anno massimo concordano"){
      for(d<-0 until 5778)
        eqv(patched(Max,d).correctedDayInMonth,
          oracle(Max,d),"Giorno "+d)
    }
    check("ogni cardinalità 3..47 supporta giorni intercalati"){
      for(n<-3 to 47) {
        val w=robin(n,252)
        for(d<-0 until 252 by 3)
          eqv(patched(w,d).correctedDayInMonth,
            oracle(w,d),"Mese "+n+" giorno "+d)
      }
    }
    check("la risposta storica resta il giorno assoluto"){
      val r=patched(d=1)
      eqv(r.historical.legacyDayInMonth,2,"Legacy")
      eqv(r.correctedDayInMonth,1,"Norma")
    }
    check("lo storico in mese secondo contiguo è 85"){
      eqv(patched(Contiguous,84).historical.legacyDayInMonth,
        85,"Cicatrice")
    }
    check("la cicatrice nell'ultimo giorno resta 252"){
      eqv(patched(d=251).historical.legacyDayInMonth,252,"Legacy")
    }
    check("il wrapper contiene il report storico effettivo"){
      for((w,d)<-Vector((Interleaved,1),(Interleaved,251),
        (Contiguous,84),(Max,5777))){
        eqv(patched(w,d).historical,
          LegacyMonthOrdinalGlobalDayAdapter.oldMonthOrdinalGlobalDay(w,d),
          "Adapter")
      }
    }
    check("4096 vettori pseudo-casuali e risultati normativi"){
      val rng=new Random(45202026L)
      for(k<-1 to 4096) {
        val n=3+rng.nextInt(45)
        val w=robin(n,252)
        val d=rng.nextInt(252)
        val r=patched(w,d)
        eqv(r.correctedDayInMonth,oracle(w,d),"Campione "+k)
        eqv(r.historical.legacyDayInMonth,d+1,"Storico "+k)
      }
    }
    check("manager conserva BigInt oltre 128 bit"){
      val r=new BaseMonsterManager().patch22MonthOrdinalGlobalDay(
        Huge,-Huge,Interleaved,1)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Target")
    }
    check("manager esegue boot discovery patch nello stesso contesto"){
      val r=new BaseMonsterManager().patch22MonthOrdinalGlobalDay(
        1,2,Interleaved,1)
      eqv(r.trace,Vector("BOOT",
        "DISCOVERY_22_MONTH_ORDINAL_GLOBAL_DAY",
        "PATCH_22_MONTH_ORDINAL_GLOBAL_DAY"),"Trace")
      eqv(r.status,"PATCH_22_READY","Status")
      truth(r.patchApplied,"Flag")
    }
    check("manager contabilizza entrambe le fasi una volta"){
      val m=new BaseMonsterManager
      m.patch22MonthOrdinalGlobalDay(1,2,Interleaved,1)
      eqv(m.metricsSnapshot("discovery22.month.ordinal.calls"),
        BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch22.month.ordinal.calls"),
        BigInt(1),"Patch")
    }
    check("report conservato dopo seconda chiamata"){
      val m=new BaseMonsterManager
      val a=m.patch22MonthOrdinalGlobalDay(1,2,Interleaved,1)
      val before=a.copy()
      m.patch22MonthOrdinalGlobalDay(3,4,Interleaved,42)
      eqv(a,before,"Immutabile")
    }
    check("due manager tengono metriche separate"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      a.patch22MonthOrdinalGlobalDay(1,2,Interleaved,1)
      b.patch22MonthOrdinalGlobalDay(3,4,Interleaved,4)
      eqv(a.metricsSnapshot("patch22.month.ordinal.calls"),
        BigInt(1),"A")
      eqv(b.metricsSnapshot("patch22.month.ordinal.calls"),
        BigInt(1),"B")
    }
    check("rifiuta mese di soli tre giorni"){
      // Quattro mesi: 3+83+83+83=252. Tutti gli altri
      // vincoli sono leciti; fallisce solo il limite minimo 4.
      val w=Vector.fill(3)(1)++Vector.fill(83)(2)++
        Vector.fill(83)(3)++Vector.fill(83)(4)
      eqv(w.size,252,"Durata annuale")
      eqv((2 to 4).map(id=>w.count(_==id)).toVector,
        Vector(83,83,83),"Altri mesi")
      rejectArg("Mese"){patched(w,1)}
    }
    check("rifiuta un anno corto"){
      rejectArg("Anno"){patched(Interleaved.take(251),1)}
    }
    check("rifiuta indice negativo"){
      rejectArg("Offset"){patched(d = -1)}
    }
    check("rifiuta offset a 252"){
      rejectArg("Offset"){patched(d=252)}
    }
    check("rifiuta quattro e oltre 47 mesi"){
      rejectArg("Mesi"){patched(Vector.tabulate(288)(i=>i%48+1),1)}
    }
    check("validator accetta un risultato integro"){
      new BaseValidationManager().requirePatch22Ready(ready())
    }
    check("validator rifiuta giorno corretto falsificato"){
      val c=ready();c.patchedDayInMonth=Some(2)
      rejectState("Corretto"){new BaseValidationManager()
        .requirePatch22Ready(c)}
    }
    check("validator rifiuta giorno legacy falsificato"){
      val c=ready();c.legacyDayInMonth=Some(1)
      rejectState("Storico"){new BaseValidationManager()
        .requirePatch22Ready(c)}
    }
    check("validator rifiuta mese legacy falsificato"){
      val c=ready();c.legacyMonthOrdinalMonthId=Some(1)
      rejectState("Mese"){new BaseValidationManager()
        .requirePatch22Ready(c)}
    }
    check("validator rifiuta snapshot falsificata"){
      val c=ready();c.monthOrdinalDayOffset=Some(2)
      rejectState("Snapshot"){new BaseValidationManager()
        .requirePatch22Ready(c)}
    }
    check("validator rifiuta trace manomessa"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager()
        .requirePatch22Ready(c)}
    }
    check("validator rifiuta status manomesso"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Status"){new BaseValidationManager()
        .requirePatch22Ready(c)}
    }
    check("validator rifiuta flag rimosso"){
      val c=ready();c.patch22Applied=false
      rejectState("Flag"){new BaseValidationManager()
        .requirePatch22Ready(c)}
    }
    check("handler respinge salto discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_22_MONTH_ORDINAL_GLOBAL_DAY"
      c.monthOrdinalWeaving=Some(Interleaved)
      c.monthOrdinalDayOffset=Some(1)
      rejectState("Bootstrap"){new Patch22MonthOrdinalGlobalDayHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patchedDayInMonth.isEmpty,"Pubblicazione")
    }
    check("handler rifiuta snapshot manomessa senza pubblicare"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_22_MONTH_ORDINAL_GLOBAL_DAY"
      c.monthOrdinalWeaving=Some(Interleaved)
      c.monthOrdinalDayOffset=Some(1)
      new Discovery22MonthOrdinalGlobalDayHandler(
        new BaseMetricsShell).handle(c)
      c.phase="PATCH_22_MONTH_ORDINAL_GLOBAL_DAY"
      c.monthOrdinalDayOffset=Some(4)
      rejectState("Snapshot"){new Patch22MonthOrdinalGlobalDayHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patchedDayInMonth.isEmpty && !c.patch22Applied,
        "Atomico")
    }
    check("discovery22 mantiene tre fallimenti intenzionali"){
      val m=new BaseMonsterManager
      val r=m.discover22MonthOrdinalGlobalDay(1,2,Contiguous,84)
      eqv(r.legacyDayInMonth,85,"Cicatrice")
    }
    check("PATCH21 continua a produrre nome corretto"){
      val r=new BaseMonsterManager().patch21DayIndexedCutletName(
        1,2,Vector.fill(6)(42),Vector.fill(6)(1),
        (1 to 6).toVector,42)
      eqv(r.correctedCanonicalNameId,2,"PATCH21")
    }
    check("nessun oracolo di test appare nel codice produttivo"){
      val stream=Files.walk(root().resolve("src/main/scala"))
      val code=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!code.contains("NormativeOracle"),"Test only")
      truth(code.contains("def monthOrdinalPatch("),"PATCH22")
    }
    check("Stage44 mantiene RED certificato"){
      val state=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(state.contains(
        "STAGE_44_NATIVE_VERIFICATION=PASS_EXPECTED_RED_42_PASS_3_FAIL"),
        "Stage44")
      val current=state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      truth(current>=45,"Stage45 corrente")
    }
    println("\nRISULTATO STADIO 45: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
