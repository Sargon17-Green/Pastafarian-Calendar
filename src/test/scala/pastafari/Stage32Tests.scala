package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 16: il vecchio giorno mensile presume mesi contigui. */
object Stage32Tests {
  private var passed=0
  private var failed=0
  private val A=Vector.fill(84)(1)++Vector.fill(84)(2)++Vector.fill(84)(3)
  private val C=Vector(1,1,2)++Vector.fill(82)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val B=Vector(1,2)++Vector.fill(83)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val Weaves=Vector(A,C,B)
  private val Huge=BigInt(1)<<16384

  private def check(label:String)(f: => Unit):Unit={
    try {f;passed+=1;println("PASS — "+label)}
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
    var got=false
    try run catch {case _:IllegalArgumentException=>got=true}
    truth(got,label+": parametro invalido accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var got=false
    try run catch {case _:IllegalStateException=>got=true}
    truth(got,label+": falsificazione accettata")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }

  // Oracolo test-only: un giorno mensile è l'occorrenza dell'ID
  // nell'intero prefisso, non l'offset dentro un blocco immaginario.
  private def normative(w:Vector[Int],d:Int):Int={
    val m=w(d)
    (0 to d).count(i=>w(i)==m)
  }
  private def historical(w:Vector[Int]=A,d:Int=0):
      LegacyContiguousMonthDayResult =
    LegacyContiguousMonthDayAdapter.oldContiguousMonthDayGuess(w,d)

  private def ready(w:Vector[Int]=A,d:Int=0):BaseMonsterContext={
    val ctx=BaseMonsterContext(43,-Huge)
    ctx.status="BOOTSTRAPPED"
    ctx.branchTrace.append("BOOT")
    ctx.phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"
    ctx.contiguousAnnualWeaving=Some(w)
    ctx.contiguousDayOffset=Some(d)
    new Discovery16ContiguousMonthDayHandler(new BaseMetricsShell).handle(ctx)
    ctx
  }

  private def singleInsertion(position:Int):Vector[Int]=
    Vector.fill(position)(1)++Vector(2)++
      Vector.fill(84-position)(1)++
      Vector.fill(83)(2)++Vector.fill(84)(3)

  def main(args:Array[String]):Unit={
    check("la tessitura diagnostica copre 252 giorni"){
      eqv(A.size,252,"A")
      eqv(B.size,252,"B")
      eqv(C.size,252,"C")
    }
    check("tutte le tessiture diagnostiche sono valide"){
      Weaves.foreach(w=>LegacyDaywiseWeavingAdapter.validateCandidates(
        Vector(w)))
    }
    check("l'anno senza intrecci è interpretato esattamente al primo giorno"){
      val x=historical()
      eqv(x.selectedMonthId,1,"Mese")
      eqv(x.guessedDayInMonth,1,"Giorno")
      eqv(x.assumedMonthStartOffset,0,"Inizio")
    }
    check("il mese uno contiguo finisce al giorno 84"){
      val x=historical(A,83)
      eqv(x.selectedMonthId,1,"Mese")
      eqv(x.guessedDayInMonth,84,"Giorno")
    }
    check("il mese due contiguo riparte a uno"){
      val x=historical(A,84)
      eqv(x.selectedMonthId,2,"Mese")
      eqv(x.assumedMonthStartOffset,84,"Offset immaginario")
      eqv(x.guessedDayInMonth,1,"Giorno")
    }
    check("il mese tre contiguo riparte a uno"){
      val x=historical(A,168)
      eqv(x.selectedMonthId,3,"Mese")
      eqv(x.assumedMonthStartOffset,168,"Offset")
      eqv(x.guessedDayInMonth,1,"Giorno")
    }
    check("l'ultimo giorno contiguo coincide con la norma"){
      eqv(historical(A,251).guessedDayInMonth,84,"Ultimo")
    }
    check("la prima apertura del mese due in C avviene al giorno due"){
      val x=historical(C,2)
      eqv(x.selectedMonthId,2,"Mese")
      eqv(x.assumedMonthStartOffset,84,"Inizio immaginario")
      eqv(x.guessedDayInMonth,-81,"Contatore negativo legacy")
      eqv(normative(C,2),1,"Contatore vero")
    }
    check("il ritorno del mese uno in C incrementa falsamente l'offset"){
      val x=historical(C,3)
      eqv(x.selectedMonthId,1,"Mese")
      eqv(x.guessedDayInMonth,4,"Legacy")
      eqv(normative(C,3),3,"Oracolo")
    }
    check("il mese due in B inizia al giorno uno"){
      val x=historical(B,1)
      eqv(x.selectedMonthId,2,"Mese")
      eqv(x.guessedDayInMonth,-82,"Legacy")
      eqv(normative(B,1),1,"Oracolo")
    }
    check("il ritorno del mese uno in B provoca un salto spurio"){
      eqv(historical(B,2).guessedDayInMonth,3,"Legacy")
      eqv(normative(B,2),2,"Norma")
    }
    check("le durate dei mesi diagnostici sono tre volte 84"){
      for(w<-Weaves)eqv(historical(w,0).monthLengths,
        Vector(84,84,84),"Durate")
    }
    check("l'offset immaginario dipende dal mese e non dal giorno"){
      for(w<-Weaves;day<-Vector(0,1,2,3,83,84,85,167,168,251)){
        val x=historical(w,day)
        eqv(x.assumedMonthStartOffset,(x.selectedMonthId-1)*84,"Offset")
      }
    }
    check("il vecchio contatore è deterministico per tutti i 756 giorni"){
      for(w<-Weaves;day<-0 until 252){
        val x=historical(w,day)
        eqv(x.guessedDayInMonth,
          day-x.assumedMonthStartOffset+1,"Formula legacy")
      }
    }
    check("nell'anno senza intrecci il legacy coincide sempre con l'oracolo"){
      for(day<-0 until 252)
        eqv(historical(A,day).guessedDayInMonth,normative(A,day),
          "Giorno "+day)
    }
    check("il difetto non altera l'ID del mese già scelto"){
      for(w<-Weaves;day<-0 until 252)
        eqv(historical(w,day).selectedMonthId,w(day),"ID stabile")
    }
    check("un mese non può avere giorno vero negativo nella tessitura"){
      for(w<-Weaves;day<-0 until 252)
        truth(normative(w,day)>=1,"Giorno positivo")
    }
    check("un mese intercalato può ottenere un giorno legacy negativo"){
      truth(historical(C,2).guessedDayInMonth<0,"C mese due")
      truth(historical(B,1).guessedDayInMonth<0,"B mese due")
    }
    check("la cicatrice non riordina mai i 252 ID dei mesi"){
      for(w<-Weaves;day<-0 until 252)
        eqv(historical(w,day).annualWeaving,w,"Candidato invariato")
    }
    check("il report non cambia dopo richieste intercalate"){
      val first=historical(C,2)
      for(i<-0 until 252)historical(B,i)
      eqv(historical(C,2),first,"Ripetibilità")
    }
    check("il codice lascia invariato il vettore in input"){
      val original=Weaves
      historical(C,2)
      historical(B,1)
      eqv(Weaves,original,"Nessuna mutazione")
    }
    check("il mese contiguo supporta tre mesi da 123 giorni"){
      val w=Vector.fill(123)(1)++Vector.fill(123)(2)++
        Vector.fill(123)(3)
      eqv(historical(w,368).guessedDayInMonth,123,"Contatore")
    }
    check("l'anno con 47 mesi mantiene le lunghezze individuali"){
      val w=(1 to 47).flatMap(m=>Vector.fill(6)(m)).toVector
      val x=historical(w,281)
      eqv(x.selectedMonthId,47,"Mese 47")
      eqv(x.monthLengths,Vector.fill(47)(6),"Durate")
      eqv(x.guessedDayInMonth,6,"Giorno")
    }
    check("l'anno massimo ha 5778 giorni senza overflow"){
      val w=(1 to 46).flatMap(m=>Vector.fill(123)(m)).toVector++
        Vector.fill(120)(47)
      val x=historical(w,5777)
      eqv(w.length,5778,"Massimo")
      eqv(x.selectedMonthId,47,"Mese")
      eqv(x.guessedDayInMonth,120,"Contatore legacy")
    }
    check("4096 campioni deterministici rispettano la formula legacy"){
      val rng=new Random(32102026L)
      for(i<-1 to 4096){
        val p=1+rng.nextInt(80)
        val w=singleInsertion(p)
        val d=rng.nextInt(252)
        val old=historical(w,d)
        val expectedStart=w.take(d+1).last match {
          case 1=>0
          case 2=>84
          case 3=>168
        }
        eqv(old.guessedDayInMonth,d-expectedStart+1,
          "Campione "+i)
        eqv(old.selectedMonthId,w(d),"ID "+i)
      }
    }
    check("le aperture con un mese oltre 123 giorni sono rifiutate"){
      for(p<-124 to 140)
        rejectArg("Posizione "+p){historical(singleInsertion(p),0)}
    }
    check("durate fuori 4..123 sono rifiutate"){
      val invalid=Vector(1,2,3)++Vector.fill(249)(3)
      rejectArg("Mese troppo breve"){historical(invalid,0)}
    }
    check("l'anno troppo corto è rifiutato"){
      rejectArg("Corto"){historical(Vector(1,2,3),0)}
    }
    check("l'anno troppo lungo è rifiutato"){
      val w=(1 to 47).flatMap(x=>Vector.fill(123)(x)).toVector
      rejectArg("Troppo lungo"){historical(w,0)}
    }
    check("i mesi aperti fuori ordine sono rifiutati"){
      val w=Vector.fill(84)(1)++Vector.fill(84)(3)++
        Vector.fill(84)(2)
      rejectArg("Ordine"){historical(w,0)}
    }
    check("le chiusure dei mesi fuori ordine sono rifiutate"){
      val w=Vector(1,2)++Vector.fill(83)(2)++
        Vector.fill(83)(1)++Vector.fill(84)(3)
      rejectArg("Chiusura"){historical(w,0)}
    }
    check("un ID mese mancante è rifiutato"){
      val w=Vector.fill(84)(1)++Vector.fill(84)(3)++
        Vector.fill(84)(4)
      rejectArg("Manca due"){historical(w,0)}
    }
    check("i giorni negativi vengono rifiutati"){
      rejectArg("Negativo"){historical(A,-1)}
    }
    check("i giorni oltre la fine dell'anno vengono rifiutati"){
      rejectArg("Fine"){historical(A,252)}
    }
    check("un vettore vuoto è rifiutato"){
      rejectArg("Vuoto"){historical(Vector.empty,0)}
    }
    check("la gestione di BigInt arbitrari preserva i giorni di calcolo"){
      val m=new BaseMonsterManager
      val r=m.discover16ContiguousMonthDay(Huge,-Huge,C,2)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Target")
      eqv(r.legacyDayInMonth,-81,"Legacy")
    }
    check("il manager pubblica giorno, mese, lunghezze e trace"){
      val m=new BaseMonsterManager
      val r=m.discover16ContiguousMonthDay(43,-9181,C,2)
      eqv(r.calculationDay,BigInt(43),"Calcolo")
      eqv(r.targetDay,BigInt(-9181),"Target")
      eqv(r.annualWeaving,C,"Tessitura")
      eqv(r.dayOffset,2,"Offset")
      eqv(r.monthLengths,Vector(84,84,84),"Durate")
      eqv(r.selectedMonthId,2,"Mese")
      eqv(r.assumedMonthStartOffset,84,"Inizio")
      eqv(r.legacyDayInMonth,-81,"Vecchio contatore")
      eqv(r.phase,"DISCOVERY_16_CONTIGUOUS_MONTH_DAY","Fase")
      eqv(r.status,"LEGACY_CONTIGUOUS_MONTH_DAY_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_16_CONTIGUOUS_MONTH_DAY"),"Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery16.contiguous.month.day.calls"),
        BigInt(1),"Discovery")
    }
    check("due manager non condividono metriche o stato"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      eqv(a.discover16ContiguousMonthDay(1,2,C,2).legacyDayInMonth,-81,"A")
      eqv(b.discover16ContiguousMonthDay(3,4,A,84).legacyDayInMonth,1,"B")
      eqv(a.metricsSnapshot("discovery16.contiguous.month.day.calls"),
        BigInt(1),"Metrica A")
      eqv(b.metricsSnapshot("discovery16.contiguous.month.day.calls"),
        BigInt(1),"Metrica B")
    }
    check("lo stesso manager conserva report precedenti"){
      val m=new BaseMonsterManager
      val a=m.discover16ContiguousMonthDay(1,2,C,2)
      val b=m.discover16ContiguousMonthDay(3,4,B,1)
      eqv(a.legacyDayInMonth,-81,"A immutabile")
      eqv(b.legacyDayInMonth,-82,"B")
      eqv(m.metricsSnapshot("discovery16.contiguous.month.day.calls"),
        BigInt(2),"Due chiamate")
    }
    check("handler rifiuta contesto senza Bootstrap"){
      val ctx=BaseMonsterContext(1,2)
      ctx.phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"
      rejectState("Non bootstrap"){
        new Discovery16ContiguousMonthDayHandler(new BaseMetricsShell).handle(ctx)}
    }
    check("handler rifiuta Bootstrap privo di input"){
      val ctx=BaseMonsterContext(1,2)
      ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
      ctx.phase="DISCOVERY_16_CONTIGUOUS_MONTH_DAY"
      ctx.contiguousAnnualWeaving=Some(C)
      rejectState("Senza giorno"){
        new Discovery16ContiguousMonthDayHandler(new BaseMetricsShell).handle(ctx)}
      truth(ctx.legacyContiguousDayInMonth.isEmpty,"Nessun output")
    }
    check("handler non consente una seconda applicazione"){
      val ctx=ready(C,2)
      rejectState("Ripetizione"){
        new Discovery16ContiguousMonthDayHandler(new BaseMetricsShell).handle(ctx)}
    }
    check("validator indipendente accetta un contesto completo"){
      new BaseValidationManager().requireDiscovery16Ready(ready(C,2))
    }
    check("validator indipendente accetta tutte le frontiere mensili"){
      val v=new BaseValidationManager
      for(w<-Weaves;d<-Vector(0,1,2,3,83,84,85,167,168,251))
        v.requireDiscovery16Ready(ready(w,d))
    }
    check("validator rifiuta contatore legacy falsificato"){
      val ctx=ready(C,2)
      ctx.legacyContiguousDayInMonth=Some(1)
      rejectState("Contatore"){new BaseValidationManager().requireDiscovery16Ready(ctx)}
    }
    check("validator rifiuta mese selezionato falsificato"){
      val ctx=ready(C,2)
      ctx.legacyContiguousSelectedMonthId=Some(1)
      rejectState("Mese"){new BaseValidationManager().requireDiscovery16Ready(ctx)}
    }
    check("validator rifiuta lunghezze dei mesi falsificate"){
      val ctx=ready(C,2)
      ctx.legacyContiguousMonthLengths=Some(Vector(83,85,84))
      rejectState("Durate"){new BaseValidationManager().requireDiscovery16Ready(ctx)}
    }
    check("validator rifiuta offset d'inizio immaginario falsificato"){
      val ctx=ready(C,2)
      ctx.legacyContiguousAssumedStartOffset=Some(3)
      rejectState("Inizio"){new BaseValidationManager().requireDiscovery16Ready(ctx)}
    }
    check("validator rifiuta giorno alterato dopo la discovery"){
      val ctx=ready(C,2)
      ctx.contiguousDayOffset=Some(3)
      rejectState("Giorno"){new BaseValidationManager().requireDiscovery16Ready(ctx)}
    }
    check("validator rifiuta tessitura mutata dopo la discovery"){
      val ctx=ready(C,2)
      ctx.contiguousAnnualWeaving=Some(B)
      rejectState("Tessitura"){new BaseValidationManager().requireDiscovery16Ready(ctx)}
    }
    check("validator rifiuta una snapshot alterata"){
      val ctx=ready(C,2)
      ctx.contiguousInputSnapshot=Some((C,3))
      rejectState("Snapshot"){new BaseValidationManager().requireDiscovery16Ready(ctx)}
    }
    check("validator rifiuta snapshot assente"){
      val ctx=ready(C,2)
      ctx.contiguousInputSnapshot=None
      rejectState("Vuota"){new BaseValidationManager().requireDiscovery16Ready(ctx)}
    }
    check("validator rifiuta output assente"){
      val ctx=ready(C,2)
      ctx.legacyContiguousDayInMonth=None
      rejectState("Mancante"){new BaseValidationManager().requireDiscovery16Ready(ctx)}
    }
    check("validator rifiuta status, phase e trace alterati"){
      val ctx=ready(C,2)
      val v=new BaseValidationManager
      ctx.status="BOOTSTRAPPED"
      rejectState("Status"){v.requireDiscovery16Ready(ctx)}
      ctx.status="LEGACY_CONTIGUOUS_MONTH_DAY_READY"
      ctx.branchTrace.remove(1)
      rejectState("Trace"){v.requireDiscovery16Ready(ctx)}
      ctx.branchTrace.append("DISCOVERY_16_CONTIGUOUS_MONTH_DAY")
      ctx.phase="PATCH_16_CONTIGUOUS_MONTH_DAY"
      rejectState("Phase"){v.requireDiscovery16Ready(ctx)}
    }
    check("PATCH15 conserva la tessitura e calcola correttamente il contatore"){
      val m=new BaseMonsterManager
      val report=m.patch15DaywiseWeaving(1,2,Weaves,2,2)
      eqv(report.fixedAnnualWeaving,C,"Una sola tessitura")
      eqv(report.correctedMonthId,2,"Mese")
      eqv(report.correctedDayInMonth,1,"Norma")
    }
    check("le quindici patch precedenti continuano a funzionare"){
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
    check("nessun oracolo in produzione e nessuna PATCH 16 anticipata"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val source=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!source.contains("NormativeOracle"),"Oracolo test-only")
      truth(source.contains("def oldContiguousMonthDayGuess("),"Cicatrice")
      truth(!source.contains("def contiguousMonthDayPatch("),"PATCH 16 prematura")
    }
    check("metadati Stage32 preservano la certificazione Stage31"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=32"),"Stage32")
      truth(st.contains("CURRENT_KIND=DISCOVERY"),"DISCOVERY")
      truth(st.contains("CURRENT_PATCH=15"),"PATCH15 preservata")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"RED")
      truth(st.contains("STAGE_31_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_66_PASS_0_FAIL"),
        "Stage31 certificato")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(done==31 || done==32,"Sequenza")
    }

    Vector(
      ("C giorno2",C,2),
      ("C giorno3",C,3),
      ("B giorno1",B,1)
    ).foreach { case (label,w,day) =>
      check("equivalenza normativa contatore "+label){
        val r=new BaseMonsterManager().discover16ContiguousMonthDay(
          43,-Huge,w,day)
        eqv(r.legacyDayInMonth,normative(w,day),
          "Mese contiguo errato: "+label)
      }
    }
    println("\nRISULTATO STADIO 32: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
