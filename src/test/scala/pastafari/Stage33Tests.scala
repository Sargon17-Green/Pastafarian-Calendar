package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 16: il giorno nel mese conta il vero prefisso annuale. */
object Stage33Tests {
  private var passed=0
  private var failed=0
  private val A=Vector.fill(84)(1)++Vector.fill(84)(2)++Vector.fill(84)(3)
  private val C=Vector(1,1,2)++Vector.fill(82)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val B=Vector(1,2)++Vector.fill(83)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val Weaves=Vector(A,C,B)
  private val Huge=(BigInt(1)<<16384)+723

  private def check(label:String)(run: => Unit):Unit={
    try {run;passed+=1;println("PASS — "+label)}
    catch {case error:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+error.getMessage)
      error.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(run: => Unit):Unit={
    var caught=false
    try run catch {case _:IllegalArgumentException=>caught=true}
    truth(caught,label+": argomento illegale accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var caught=false
    try run catch {case _:IllegalStateException=>caught=true}
    truth(caught,label+": contesto illegale accettato")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }

  // Riferimento esclusivamente test: il numero del giorno mensile
  // non deriva da una fittizia data d'inizio del mese contiguo.
  private def normDay(w:Vector[Int],day:Int):Int={
    val month=w(day)
    var n=0
    var i=0
    while(i<=day){
      if(w(i)==month)n+=1
      i+=1
    }
    n
  }
  private def patched(w:Vector[Int]=A,day:Int=0):
      Patch16ContiguousMonthDayResult=
    Patch16ContiguousMonthDayWrapper.contiguousMonthDayPatch(w,day)
  private def ready(w:Vector[Int]=A,day:Int=0):BaseMonsterContext={
    val ctx=BaseMonsterContext(43,-Huge)
    ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
    ctx.phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"
    ctx.contiguousAnnualWeaving=Some(w)
    ctx.contiguousDayOffset=Some(day)
    new Discovery16ContiguousMonthDayHandler(new BaseMetricsShell).handle(ctx)
    ctx.phase="PATCH_16_CONTIGUOUS_MONTH_DAY"
    new Patch16ContiguousMonthDayHandler(new BaseMetricsShell).handle(ctx)
    ctx
  }
  private def singleInsertion(position:Int):Vector[Int]=
    Vector.fill(position)(1)++Vector(2)++
    Vector.fill(84-position)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)

  def main(args:Array[String]):Unit={
    check("giorno zero di A è il primo giorno del primo mese"){
      val r=patched()
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,1,"Giorno")
      eqv(r.historical.guessedDayInMonth,1,"Legacy")
    }
    check("il giorno 83 di A finisce il mese uno"){
      val r=patched(A,83)
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,84,"Giorno")
    }
    check("il giorno 84 di A inaugura il mese due"){
      val r=patched(A,84)
      eqv(r.correctedMonthId,2,"Mese")
      eqv(r.correctedDayInMonth,1,"Primo")
    }
    check("il giorno 167 di A conclude il mese due"){
      val r=patched(A,167)
      eqv(r.correctedMonthId,2,"Mese")
      eqv(r.correctedDayInMonth,84,"Ultimo")
    }
    check("il giorno 168 di A inaugura il mese tre"){
      val r=patched(A,168)
      eqv(r.correctedMonthId,3,"Mese")
      eqv(r.correctedDayInMonth,1,"Primo")
    }
    check("l'ultimo giorno A ha numero mensile 84"){
      val r=patched(A,251)
      eqv(r.correctedMonthId,3,"Mese")
      eqv(r.correctedDayInMonth,84,"Giorno")
    }
    check("il difetto C giorno due resta negativo nel legacy"){
      val r=patched(C,2)
      eqv(r.historical.guessedDayInMonth,-81,"Storico")
      eqv(r.correctedMonthId,2,"Mese")
      eqv(r.correctedDayInMonth,1,"Giorno corretto")
    }
    check("il difetto C giorno tre mostra mese uno con terzo giorno"){
      val r=patched(C,3)
      eqv(r.historical.guessedDayInMonth,4,"Storico")
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,3,"Giorno corretto")
    }
    check("il difetto B giorno uno resta -82 nel legacy"){
      val r=patched(B,1)
      eqv(r.historical.guessedDayInMonth,-82,"Storico")
      eqv(r.correctedMonthId,2,"Mese")
      eqv(r.correctedDayInMonth,1,"Giorno corretto")
    }
    check("B giorno due torna al mese uno senza saltare contatore"){
      val r=patched(B,2)
      eqv(r.historical.guessedDayInMonth,3,"Storico")
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,2,"Corretto")
    }
    check("primo giorno mensile C dopo l'intreccio è 1"){
      eqv(patched(C,2).correctedDayInMonth,1,"Mese due")
    }
    check("il primo giorno del mese tre è sempre 1"){
      for(w<-Weaves){
        val at=w.indexOf(3)
        eqv(patched(w,at).correctedDayInMonth,1,"Mese tre")
      }
    }
    check("A contigua coincide con l'output storico per tutti i giorni"){
      for(day<-0 until 252){
        val r=patched(A,day)
        eqv(r.correctedDayInMonth,r.historical.guessedDayInMonth,
          "Giorno "+day)
      }
    }
    check("tutti i 756 mesi selezionati coincidono con la tessitura"){
      for(w<-Weaves;day<-0 until 252)
        eqv(patched(w,day).correctedMonthId,w(day),"ID")
    }
    check("tutti i 756 giorni mensili coincidono col conto normativo"){
      for(w<-Weaves;day<-0 until 252)
        eqv(patched(w,day).correctedDayInMonth,normDay(w,day),
          "Giorno "+day)
    }
    check("tutti i 756 risultati storici preservano il helper originale"){
      for(w<-Weaves;day<-0 until 252)
        eqv(patched(w,day).historical,
          LegacyContiguousMonthDayAdapter.oldContiguousMonthDayGuess(w,day),
          "Giorno "+day)
    }
    check("per ogni mese il conteggio corretto è 1..84 senza lacune"){
      for(w<-Weaves;month<-1 to 3) {
        val counts=(0 until 252).filter(day=>w(day)==month)
          .map(day=>patched(w,day).correctedDayInMonth).toVector
        eqv(counts,(1 to 84).toVector,"Mese "+month)
      }
    }
    check("i 252 giorni hanno contatori compresi fra 1 e 84"){
      for(w<-Weaves;day<-0 until 252){
        val n=patched(w,day).correctedDayInMonth
        truth(n>=1 && n<=84,"Contatore fuori range")
      }
    }
    check("il valore correttivo non dipende da chiamate intercalate"){
      val original=patched(C,2)
      for(day<-0 until 252)patched(B,day)
      eqv(patched(C,2),original,"Risultato invariato")
    }
    check("nessun input sintetico viene mutato dal calcolo"){
      val input=Weaves
      patched(C,2);patched(B,1)
      eqv(Weaves,input,"Input")
    }
    check("anno di 369 giorni con mesi da 123 giorni"){
      val w=Vector.fill(123)(1)++Vector.fill(123)(2)++
        Vector.fill(123)(3)
      val r=patched(w,368)
      eqv(r.correctedMonthId,3,"Mese")
      eqv(r.correctedDayInMonth,123,"Giorno")
    }
    check("anno di 282 giorni con 47 mesi da sei giorni"){
      val w=(1 to 47).flatMap(id=>Vector.fill(6)(id)).toVector
      val r=patched(w,281)
      eqv(r.correctedMonthId,47,"Mese")
      eqv(r.correctedDayInMonth,6,"Giorno")
    }
    check("anno massimo inclusivo di 5778 giorni"){
      val w=(1 to 46).flatMap(id=>Vector.fill(123)(id)).toVector++
        Vector.fill(120)(47)
      val r=patched(w,5777)
      eqv(w.length,5778,"Limite")
      eqv(r.correctedMonthId,47,"Mese")
      eqv(r.correctedDayInMonth,120,"Giorno")
    }
    check("l'anno massimo con mese intercalato usa il prefisso effettivo"){
      val base=(1 to 46).flatMap(id=>Vector.fill(123)(id)).toVector++
        Vector.fill(120)(47)
      // Sposta il primo giorno del mese 47 fra gli ultimi due
      // giorni del mese 46 mantenendo aperture e chiusure ordinate.
      val displaced=base.patch(5656,Vector(47),0).patch(5658,Nil,1)
      // Se risulta un intreccio valido, controlla il prefisso
      // con il riferimento indipendente, senza dedurre la data da
      // un indice contiguo.
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(displaced))
      val d=displaced.indexOf(47)
      eqv(patched(displaced,d).correctedDayInMonth,normDay(displaced,d),
        "Primo giorno 47")
    }
    check("famiglia con 24 tessiture legali restituisce prefissi corretti"){
      val family=(1 to 24).reverse.map(singleInsertion).toVector
      for(w<-family;d<-Vector(0,1,2,3,83,84,85,167,168,251)){
        val r=patched(w,d)
        eqv(r.correctedDayInMonth,normDay(w,d),"Intercalati")
      }
    }
    check("4096 campioni riproducibili di tessiture intercalate"){
      val rng=new Random(33102026L)
      for(i<-1 to 4096){
        val pos=1+rng.nextInt(83)
        val w=singleInsertion(pos)
        val day=rng.nextInt(w.size)
        val r=patched(w,day)
        eqv(r.correctedMonthId,w(day),"Mese "+i)
        eqv(r.correctedDayInMonth,normDay(w,day),"Contatore "+i)
        eqv(r.historical.guessedDayInMonth,
          day-r.historical.assumedMonthStartOffset+1,"Legacy "+i)
      }
    }
    check("una sola tessitura scelta mantiene immutata la sequenza"){
      for(w<-Weaves;d<-Vector(0,1,2,3,83,84,167,168,251))
        eqv(patched(w,d).historical.annualWeaving,w,"Fissa")
    }
    check("famiglia con tre mesi di durata quattro non arriva a 252"){
      val w=Vector.fill(4)(1)++Vector.fill(4)(2)++
        Vector.fill(4)(3)
      rejectArg("Anno troppo breve"){patched(w,0)}
    }
    check("famiglia con 47 mesi da 123 supera 5778"){
      val w=(1 to 47).flatMap(id=>Vector.fill(123)(id)).toVector
      rejectArg("Anno eccessivo"){patched(w,0)}
    }
    check("rifiuto di una tessitura vuota"){
      rejectArg("Vuota"){patched(Vector.empty,0)}
    }
    check("rifiuto del giorno negativo"){
      rejectArg("Negativo"){patched(A,-1)}
    }
    check("rifiuto del giorno uguale alla lunghezza"){
      rejectArg("Oltre"){patched(A,252)}
    }
    check("rifiuto dell'ID mese mancante"){
      val bad=Vector.fill(84)(1)++Vector.fill(84)(3)++
        Vector.fill(84)(4)
      rejectArg("Mese 2 mancante"){patched(bad,0)}
    }
    check("rifiuto dell'apertura del mese fuori ordine"){
      val bad=Vector.fill(84)(1)++Vector.fill(84)(3)++
        Vector.fill(84)(2)
      rejectArg("Apertura"){patched(bad,0)}
    }
    check("rifiuto della chiusura mensile fuori ordine"){
      val bad=Vector(1,2)++Vector.fill(83)(2)++
        Vector.fill(83)(1)++Vector.fill(84)(3)
      rejectArg("Chiusura"){patched(bad,0)}
    }
    check("rifiuto di un mese troppo corto"){
      val bad=Vector(1,2,3)++Vector.fill(249)(3)
      rejectArg("Durata"){patched(bad,0)}
    }
    check("rifiuto di un mese oltre 123 giorni"){
      val bad=Vector.fill(124)(1)++Vector.fill(64)(2)++
        Vector.fill(64)(3)
      rejectArg("Durata"){patched(bad,0)}
    }
    check("il manager attraversa BOOT, DISCOVERY 16 e PATCH 16"){
      val m=new BaseMonsterManager
      val r=m.patch16ContiguousMonthDay(Huge,-Huge,C,2)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Bersaglio")
      eqv(r.annualWeaving,C,"Tessitura")
      eqv(r.dayOffset,2,"Giorno")
      eqv(r.monthLengths,Vector(84,84,84),"Durate")
      eqv(r.legacySelectedMonthId,2,"Vecchio mese")
      eqv(r.legacyAssumedMonthStartOffset,84,"Offset storico")
      eqv(r.legacyDayInMonth,-81,"Legacy")
      eqv(r.correctedMonthId,2,"Mese corretto")
      eqv(r.correctedDayInMonth,1,"Giorno corretto")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_16_CONTIGUOUS_MONTH_DAY","Phase")
      eqv(r.status,"PATCH_16_READY","Status")
      eqv(r.trace,Vector("BOOT","DISCOVERY_16_CONTIGUOUS_MONTH_DAY",
        "PATCH_16_CONTIGUOUS_MONTH_DAY"),"Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery16.contiguous.month.day.calls"),
        BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch16.contiguous.month.day.calls"),
        BigInt(1),"Patch")
    }
    check("le richieste successive preservano report precedenti"){
      val m=new BaseMonsterManager
      val r=m.patch16ContiguousMonthDay(1,2,C,2)
      val s=m.patch16ContiguousMonthDay(3,4,B,1)
      eqv(r.correctedDayInMonth,1,"Primo")
      eqv(r.legacyDayInMonth,-81,"Storico")
      eqv(s.legacyDayInMonth,-82,"Secondo storico")
      eqv(m.metricsSnapshot("patch16.contiguous.month.day.calls"),
        BigInt(2),"Due")
    }
    check("due manager possiedono stati e metriche separati"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      eqv(a.patch16ContiguousMonthDay(1,2,C,3).correctedDayInMonth,3,"A")
      eqv(b.patch16ContiguousMonthDay(3,4,B,1).correctedDayInMonth,1,"B")
      eqv(a.metricsSnapshot("patch16.contiguous.month.day.calls"),BigInt(1),"M1")
      eqv(b.metricsSnapshot("patch16.contiguous.month.day.calls"),BigInt(1),"M2")
    }
    check("manager riutilizzato restituisce tutti i 252 giorni corretti"){
      val m=new BaseMonsterManager
      for(d<-0 until 252){
        val r=m.patch16ContiguousMonthDay(0,0,C,d)
        eqv(r.correctedDayInMonth,normDay(C,d),"Giorno "+d)
      }
      eqv(m.metricsSnapshot("patch16.contiguous.month.day.calls"),
        BigInt(252),"Metriche")
    }
    check("il manager di sola discovery conserva il risultato sbagliato"){
      val m=new BaseMonsterManager
      val old=m.discover16ContiguousMonthDay(0,0,C,2)
      val now=m.patch16ContiguousMonthDay(0,0,C,2)
      eqv(old.legacyDayInMonth,now.legacyDayInMonth,"Cicatrice")
      truth(now.correctedDayInMonth!=now.legacyDayInMonth,"Divergenza")
    }
    check("handler rifiuta un contesto senza Bootstrap"){
      val c=BaseMonsterContext(1,2)
      c.phase="PATCH_16_CONTIGUOUS_MONTH_DAY"
      rejectState("Senza BOOT"){
        new Patch16ContiguousMonthDayHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta Bootstrap senza discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_16_CONTIGUOUS_MONTH_DAY"
      rejectState("Senza input"){
        new Patch16ContiguousMonthDayHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta l'applicazione ripetuta"){
      val c=ready(C,2)
      rejectState("Doppio"){
        new Patch16ContiguousMonthDayHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta cicatrice falsificata senza scrivere output"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"
      c.contiguousAnnualWeaving=Some(C);c.contiguousDayOffset=Some(2)
      new Discovery16ContiguousMonthDayHandler(new BaseMetricsShell).handle(c)
      c.phase="PATCH_16_CONTIGUOUS_MONTH_DAY"
      c.legacyContiguousDayInMonth=Some(1)
      rejectState("Falsificata"){
        new Patch16ContiguousMonthDayHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedContiguousMonthId.isEmpty,"Nessun mese")
      truth(c.patchedContiguousDayInMonth.isEmpty,"Nessun giorno")
      truth(!c.patch16Applied,"Nessun flag")
    }
    check("handler rifiuta input mutato anche se il mese rimane invariato"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"
      c.contiguousAnnualWeaving=Some(A);c.contiguousDayOffset=Some(0)
      new Discovery16ContiguousMonthDayHandler(new BaseMetricsShell).handle(c)
      c.phase="PATCH_16_CONTIGUOUS_MONTH_DAY"
      c.contiguousDayOffset=Some(1)
      rejectState("Giorno dopo discovery"){
        new Patch16ContiguousMonthDayHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedContiguousDayInMonth.isEmpty,"Output non pubblicato")
    }
    check("validator indipendente accetta un contesto corretto"){
      new BaseValidationManager().requirePatch16Ready(ready(C,2))
    }
    check("validator accetta tutti i confini per tre tessiture"){
      val v=new BaseValidationManager
      for(w<-Weaves;d<-Vector(0,1,2,3,83,84,85,167,168,251))
        v.requirePatch16Ready(ready(w,d))
    }
    check("validator accetta ogni giorno per una tessitura intercalata"){
      val v=new BaseValidationManager
      for(d<-0 until 252)v.requirePatch16Ready(ready(C,d))
    }
    check("validator rifiuta un giorno PATCH falsificato"){
      val c=ready(C,2);c.patchedContiguousDayInMonth=Some(2)
      rejectState("PATCH giorno"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta un mese PATCH falsificato"){
      val c=ready(C,2);c.patchedContiguousMonthId=Some(1)
      rejectState("PATCH mese"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta un giorno legacy falsificato"){
      val c=ready(C,2);c.legacyContiguousDayInMonth=Some(1)
      rejectState("Legacy giorno"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta lunghezze legacy falsificate"){
      val c=ready(C,2);c.legacyContiguousMonthLengths=Some(Vector(83,85,84))
      rejectState("Durate"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta il mese legacy falsificato"){
      val c=ready(C,2);c.legacyContiguousSelectedMonthId=Some(1)
      rejectState("Legacy mese"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta l'offset legacy falsificato"){
      val c=ready(C,2);c.legacyContiguousAssumedStartOffset=Some(0)
      rejectState("Inizio"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta il giorno dopo la discovery modificato"){
      val c=ready(A,0);c.contiguousDayOffset=Some(1)
      rejectState("Giorno"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta la tessitura dopo la discovery modificata"){
      val c=ready(A,0);c.contiguousAnnualWeaving=Some(B)
      rejectState("Tessitura"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta snapshot mutata"){
      val c=ready(C,2);c.contiguousInputSnapshot=Some((C,3))
      rejectState("Snapshot"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta snapshot mancante"){
      val c=ready(C,2);c.contiguousInputSnapshot=None
      rejectState("Vuota"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta il giorno corretto mancante"){
      val c=ready(C,2);c.patchedContiguousDayInMonth=None
      rejectState("Nessun output"){new BaseValidationManager().requirePatch16Ready(c)}
    }
    check("validator rifiuta flag stato fase e trace falsificati"){
      val c=ready(C,2)
      val v=new BaseValidationManager
      c.patch16Applied=false
      rejectState("Flag"){v.requirePatch16Ready(c)}
      c.patch16Applied=true
      c.status="LEGACY_CONTIGUOUS_MONTH_DAY_READY"
      rejectState("Status"){v.requirePatch16Ready(c)}
      c.status="PATCH_16_READY"
      c.branchTrace.remove(1)
      rejectState("Trace"){v.requirePatch16Ready(c)}
      c.branchTrace.insert(1,"DISCOVERY_16_CONTIGUOUS_MONTH_DAY")
      c.phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"
      rejectState("Fase"){v.requirePatch16Ready(c)}
    }
    check("le quindici PATCH normative precedenti mantengono la regressione"){
      val m=new BaseMonsterManager
      val mod=NormativeOracle.M
      val f=NormativeOracle.FoundationDay
      eqv(m.patch01Save(0,0,mod).patchedOutput,mod,"P01")
      eqv(m.patch02DayTag(f,f,f).patchedTag,BigInt(1),"P02")
      eqv(m.patch03Distance(f,f).patchedDistance,BigInt(1),"P03")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"P04")
      eqv(m.patch05Prior(0,0,Vector[BigInt](1,2,3,4,5,6,7),
        Vector.empty,1,7).patchedValue,BigInt(7),"P05")
      eqv(m.patch06Grind(0,0,1,7,11,13,17,
        Vector[BigInt](19,23,29,31,37)).patchedValue,BigInt(422),"P06")
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,
        Vector(6,5,4,3,2,1),"P07")
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),
        37,Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"P08")
      eqv(m.patch09Vault(0,0,Vector[BigInt](11,13,17,19,23,29)).patchedBowls,
        NormativeOracle.postStir12(Vector[BigInt](11,13,17,19,23,29)),"P09")
      eqv(m.patch10Order46(0,0,1,720,1).correctedNextBowl,6,"P10")
      eqv(m.patch11ShortPick(0,0,mod,1,5).patchedRank,BigInt(1),"P11")
      eqv(m.patch12YearCeiling(0,0,Vector.fill(6)(963)).patchedAccepted,
        true,"P12")
      eqv(m.patch13YearJump(0,601,0,Vector(400,500,600,700,800),
        Vector(600,700,800,900,1000)).correctedYearOffset,BigInt(1),"P13")
      eqv(m.patch14VirtualGateList(0,0,17,3,BigInt(1)<<64,
        (BigInt(1)<<32)+1).patchedSelectedGateIndex,
        BigInt(17)+((BigInt(1)<<32)*3),"P14")
      eqv(m.patch15DaywiseWeaving(0,0,Weaves,2,2).correctedDayInMonth,1,"P15")
    }
    check("oracolo solo nei test, cicatrice viva e nessuno Stage34"){
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo")
      truth(sources.contains("def oldContiguousMonthDayGuess("),"Cicatrice")
      truth(sources.contains("def contiguousMonthDayPatch("),"PATCH 16")
      truth(!sources.contains("oldMonthNameDuplicated"),"Stage34 futura")
    }
    check("metadati Stage33 conservano la certificazione Stage32"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=33"),"Stage33")
      truth(st.contains("CURRENT_KIND=PATCH"),"PATCH")
      truth(st.contains("CURRENT_PATCH=16"),"PATCH 16")
      truth(st.contains("STAGE_32_NATIVE_VERIFICATION=PASS_EXPECTED_RED_58_PASS_3_FAIL"),
        "DISCOVERY 16 storica")
      truth(st.contains("STAGE_31_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_66_PASS_0_FAIL"),
        "PATCH 15 storica")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(done==32 || done==33,"Sequenza")
    }
    println("\nRISULTATO STADIO 33: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
