package pastafari

import pastafari.monster._
import pastafari.catalog.SourceLanguageCatalog
import scala.util.Random
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._

/** DISCOVERY19: il nome del mese NON dipende dall'offset del giorno. */
object Stage38Tests {
  private var passed=0
  private var failed=0
  private val A=Vector.fill(84)(1)++Vector.fill(84)(2)++Vector.fill(84)(3)
  private val B=Vector(1,2)++Vector.fill(83)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val C=Vector(1,1,2)++Vector.fill(82)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val Q=(1 to 47).flatMap(i=>Vector.fill(6)(i)).toVector
  private val First=Vector(1,2,3)
  private val All=(1 to 47).toVector
  private val Huge=(BigInt(1)<<16384)+3800

  private def check(label:String)(run: => Unit):Unit={
    try {run;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[T](got:T,want:T,label:String):Unit={
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(run: => Unit):Unit={
    var rejected=false
    try run catch {case _:IllegalArgumentException=>rejected=true}
    truth(rejected,label+": valore illecito accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var rejected=false
    try run catch {case _:IllegalStateException=>rejected=true}
    truth(rejected,label+": stato falsificato accettato")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }
  private def old(w:Vector[Int]=A,ids:Vector[Int]=First,day:Int=0)
      :LegacyDayIndexedMonthNameResult =
    LegacyDayIndexedMonthNameAdapter.oldDayIndexedMonthName(w,ids,day)
  // Oracolo indipendente, ESCLUSIVAMENTE nei test: il mese e'
  // l'elemento della tessitura del giorno, non il resto del giorno.
  private def reference(w:Vector[Int],ids:Vector[Int],day:Int):String={
    val selected=w(day)
    val nameId=ids(selected-1)
    val options=SourceLanguageCatalog.Months.filter(_.canonicalIndex==nameId)
    eqv(options.size,1,"ID canonico unico")
    options.head.italian
  }
  private def legacyReference(ids:Vector[Int],day:Int):String={
    val chosen=ids(day%ids.size)
    SourceLanguageCatalog.Months.find(_.canonicalIndex==chosen).get.italian
  }
  private def ready(
    w:Vector[Int]=A,ids:Vector[Int]=First,day:Int=1
  ):BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_19_DAY_INDEXED_MONTH_NAME"
    c.dayNameWeaving=Some(w)
    c.dayNameCanonicalIndices=Some(ids)
    c.dayNameOffset=Some(day)
    new Discovery19DayIndexedMonthNameHandler(new BaseMetricsShell).handle(c)
    c
  }
  private def uniform(n:Int):Vector[Int]={
    val days=math.max(6,(252+n-1)/n)
    (1 to n).flatMap(i=>Vector.fill(days)(i)).toVector
  }

  def main(args:Array[String]):Unit={
    check("catalogo italiano congelato conserva i 47 ID"){
      eqv(SourceLanguageCatalog.Months.map(_.canonicalIndex),All,"ID")
    }
    check("catalogo congelato conserva i nomi dei primi tre mesi"){
      eqv(First.map(i=>SourceLanguageCatalog.month(i).italian),
        Vector("argilla","melagrana","gomito"),"Nomi")
    }
    check("la tessitura A è valida nel dominio 252"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(A))
      eqv(A.length,252,"Giorni")
    }
    check("la tessitura B è valida con intercalazione"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(B))
      eqv(B(1),2,"Intercalazione")
    }
    check("la tessitura C è valida con apertura 1-2-1"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(C))
      eqv(C.take(4),Vector(1,1,2,1),"Prefisso")
    }
    check("47 mesi di sei giorni producono 282 giorni validi"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(Q))
      eqv(Q.length,282,"Giorni")
    }
    check("giorno iniziale coincide per caso col nome corretto"){
      eqv(old().legacyItalianMonthName,"argilla","Primo giorno")
      eqv(old().legacyItalianMonthName,reference(A,First,0),"Coincidenza")
    }
    check("giorno uno del mese uno cambia nome nel vecchio percorso"){
      val r=old(A,First,1)
      eqv(r.selectedMonthId,1,"Mese reale")
      eqv(r.legacyNameSlot,1,"Slot sbagliato")
      eqv(r.legacyItalianMonthName,"melagrana","Nome sbagliato")
    }
    check("giorno due della tessitura C appartiene al mese due"){
      val r=old(C,First,2)
      eqv(r.selectedMonthId,2,"Mese")
      eqv(r.legacyNameSlot,2,"Slot errato")
      eqv(r.legacyItalianMonthName,"gomito","Nome storico")
    }
    check("giorno 46 su 47 nomi punta erroneamente all'ultimo nome"){
      val r=old(Q,All,46)
      eqv(r.selectedMonthId,8,"Mese reale")
      eqv(r.legacyNameSlot,46,"Ultimo slot")
      eqv(r.legacyItalianMonthName,"sabbia","Nome errato")
    }
    check("l'identità dei nomi canonici è immutata"){
      val before=SourceLanguageCatalog.Months
      old(Q,All,46);old(C,First,2)
      eqv(SourceLanguageCatalog.Months,before,"Catalogo")
    }
    check("il percorso storico non riusa la rotazione di DISCOVERY18"){
      val r=old(A,First,0)
      eqv(r.legacyItalianMonthName,"argilla","PATCH18 disponibile")
      truth(r.legacyItalianMonthName!=
        LegacySourceCatalogMismatchAdapter.oldSourceCatalogMismatch(First)
          .legacyItalianMonthNames.head,"Difetti distinti")
    }
    check("il legacy conserva il vettore annuale e gli ID richiesti"){
      val r=old(C,First,2)
      eqv(r.annualWeaving,C,"Tessitura")
      eqv(r.canonicalMonthNameIndices,First,"ID")
      eqv(r.dayOffset,2,"Giorno")
    }
    check("il legacy riporta la versione congelata del catalogo"){
      eqv(old().frozenCatalogVersion,SourceLanguageCatalog.Version,
        "Versione")
    }
    check("tutti i 252 giorni in A hanno lo slot day modulo 3"){
      for(day<-0 until 252)
        eqv(old(A,First,day).legacyNameSlot,day%3,"Slot "+day)
    }
    check("tutti i 252 giorni in C hanno nome storico riproducibile"){
      for(day<-0 until 252)
        eqv(old(C,First,day).legacyItalianMonthName,
          legacyReference(First,day),"Giorno "+day)
    }
    check("tutti i 252 giorni in B conservano il vero ID del mese"){
      for(day<-0 until 252)
        eqv(old(B,First,day).selectedMonthId,B(day),"Mese "+day)
    }
    check("tutte le 45 cardinalità dei mesi da 3 a 47 sono accettate"){
      for(n<-3 to 47){
        val w=uniform(n)
        val ids=All.take(n)
        val r=old(w,ids,w.size-1)
        eqv(r.legacyItalianMonthName,
          legacyReference(ids,w.size-1),"Conteggio "+n)
      }
    }
    check("i 47 nomi sono distinti anche dopo il ponte storico"){
      val names=(0 until 47).map(day=>old(Q,All,day)
        .legacyItalianMonthName).toVector
      eqv(names.distinct.length,47,"Unicità dei nomi")
    }
    check("il vecchio nome dipende dal giorno anche per il medesimo mese"){
      val a=old(A,First,0)
      val b=old(A,First,1)
      eqv(a.selectedMonthId,b.selectedMonthId,"Stesso mese")
      truth(a.legacyItalianMonthName!=b.legacyItalianMonthName,
        "Cambio di nome scorretto")
    }
    check("1024 permutazioni di nomi mantengono il difetto riproducibile"){
      val rng=new Random(38102026L)
      for(i<-1 to 1024){
        val names=rng.shuffle(All).take(3).toVector
        val day=rng.nextInt(252)
        val r=old(C,names,day)
        eqv(r.legacyItalianMonthName,
          legacyReference(names,day),"Legacy "+i)
        eqv(r.selectedMonthId,C(day),"Weave "+i)
      }
    }
    check("intercalazione non altera il nome quando offset e ID coincidono"){
      for(w<-Vector(A,B,C)){
        val r=old(w,First,0)
        eqv(r.legacyItalianMonthName,reference(w,First,0),"Giorno zero")
      }
    }
    check("nessun output dipende da manager usati in precedenza"){
      val before=old(C,First,2)
      val m=new BaseMonsterManager
      m.discover19DayIndexedMonthName(1,2,A,First,1)
      m.discover19DayIndexedMonthName(3,4,Q,All,46)
      eqv(old(C,First,2),before,"Determinismo")
    }
    check("rifiuta meno di tre nomi"){
      rejectArg("Due nomi"){old(A,Vector(1,2),1)}
    }
    check("rifiuta duplicati tra indici canonici"){
      rejectArg("Ripetizione"){old(A,Vector(1,1,2),1)}
    }
    check("rifiuta nome canonico ID zero"){
      rejectArg("Zero"){old(A,Vector(0,2,3),1)}
    }
    check("rifiuta nome canonico ID 48"){
      rejectArg("Fuori catalogo"){old(A,Vector(1,2,48),1)}
    }
    check("rifiuta un offset negativo"){
      rejectArg("Negativo"){old(A,First,-1)}
    }
    check("rifiuta un offset a fine anno"){
      rejectArg("Fine"){old(A,First,252)}
    }
    check("rifiuta una tessitura annuale troppo corta"){
      rejectArg("Breve"){old(Vector(1,2,3),First,0)}
    }
    check("rifiuta mesi senza durata minima"){
      rejectArg("Durata"){old(Vector.fill(250)(1)++Vector(2,3),
        First,0)}
    }
    check("rifiuta tessitura con ordine di apertura errato"){
      rejectArg("Ordine"){old(Vector.fill(84)(2)++
        Vector.fill(84)(1)++Vector.fill(84)(3),First,0)}
    }
    check("report del manager preserva numeri e trace"){
      val m=new BaseMonsterManager
      val r=m.discover19DayIndexedMonthName(Huge,-Huge,C,First,2)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Domanda")
      eqv(r.annualWeaving,C,"Tessitura")
      eqv(r.canonicalMonthNameIndices,First,"Nomi")
      eqv(r.selectedMonthId,2,"Mese")
      eqv(r.legacyNameSlot,2,"Slot")
      eqv(r.legacyItalianMonthName,"gomito","Storico")
      eqv(r.phase,"DISCOVERY_19_DAY_INDEXED_MONTH_NAME","Fase")
      eqv(r.status,"LEGACY_DAY_INDEXED_MONTH_NAME_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_19_DAY_INDEXED_MONTH_NAME"),
        "Trace")
      eqv(m.metricsSnapshot("discovery19.day.name.calls"),BigInt(1),
        "Contatore")
    }
    check("due istanze manager mantengono metriche isolate"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      a.discover19DayIndexedMonthName(1,2,A,First,1)
      b.discover19DayIndexedMonthName(3,4,C,First,2)
      eqv(a.metricsSnapshot("discovery19.day.name.calls"),BigInt(1),"A")
      eqv(b.metricsSnapshot("discovery19.day.name.calls"),BigInt(1),"B")
    }
    check("il validator indipendente approva un contesto intatto"){
      new BaseValidationManager().requireDiscovery19Ready(ready())
    }
    check("il validator rifiuta un nome storico alterato"){
      val c=ready();c.dayNameLegacyItalian=Some("argilla")
      rejectState("Nome"){new BaseValidationManager()
        .requireDiscovery19Ready(c)}
    }
    check("il validator rifiuta lo slot storico alterato"){
      val c=ready();c.dayNameLegacySlot=Some(0)
      rejectState("Slot"){new BaseValidationManager()
        .requireDiscovery19Ready(c)}
    }
    check("il validator rifiuta il mese tessuto alterato"){
      val c=ready();c.dayNameLegacyMonthId=Some(2)
      rejectState("Mese"){new BaseValidationManager()
        .requireDiscovery19Ready(c)}
    }
    check("il validator rifiuta snapshot alterata"){
      val c=ready();c.dayNameOffset=Some(2)
      rejectState("Offset"){new BaseValidationManager()
        .requireDiscovery19Ready(c)}
    }
    check("il validator rifiuta versione congelata alterata"){
      val c=ready();c.dayNameFrozenVersion=Some("wrong")
      rejectState("Versione"){new BaseValidationManager()
        .requireDiscovery19Ready(c)}
    }
    check("il validator rifiuta una trace compromessa"){
      val c=ready();c.branchTrace.append("EXTRA")
      rejectState("Trace"){new BaseValidationManager()
        .requireDiscovery19Ready(c)}
    }
    check("il validator rifiuta input duplicati dopo la discovery"){
      val c=ready();c.dayNameCanonicalIndices=Some(Vector(1,1,3))
      rejectState("Duplicati"){new BaseValidationManager()
        .requireDiscovery19Ready(c)}
    }
    check("il handler rifiuta bootstrap inesistente"){
      val c=BaseMonsterContext(1,2)
      c.dayNameWeaving=Some(A)
      c.dayNameCanonicalIndices=Some(First)
      c.dayNameOffset=Some(1)
      c.phase="DISCOVERY_19_DAY_INDEXED_MONTH_NAME"
      rejectState("BOOT"){new Discovery19DayIndexedMonthNameHandler(
        new BaseMetricsShell).handle(c)}
    }
    check("la fase discovery non pubblica alcun campo patch19"){
      val c=ready()
      truth(c.dayNameLegacyItalian.nonEmpty,"Output storico")
      truth(!c.status.contains("PATCH_19"),"Patch assente")
      val s=Files.walk(root().resolve("src/main/scala"))
      val sources=try s.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally s.close()
      truth(!sources.contains("def dayIndexedNamePatch("),"PATCH19 anticipata")
      truth(!sources.contains("NormativeOracle"),"Oracolo nel codice")
    }
    check("metadati Stage38 mantengono Stage37 certificato"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=38"),"Stage 38")
      truth(st.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
      truth(st.contains("CURRENT_PATCH=18"),"Patch non introdotta")
      truth(st.contains(
        "STAGE_37_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_63_PASS_0_FAIL"),
        "Stage37 conservato")
      val n=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .get.split("=",2)(1).toInt
      truth(n==37 || n==38,"Sequenza")
    }

    // Tre equivalenze normative impossibili nel vecchio modello.
    Vector(
      ("DAY1_MONTH1",A,First,1),
      ("INTERLEAVED_DAY2_MONTH2",C,First,2),
      ("MONTH47_DAY46",Q,All,46)
    ).foreach { case (label,weave,names,day) =>
      check("equivalenza normativa nome "+label){
        val r=new BaseMonsterManager().discover19DayIndexedMonthName(
          Huge,-Huge,weave,names,day)
        eqv(r.legacyItalianMonthName,reference(weave,names,day),
          "Nome ricalcolato dal giorno anziché dal mese: "+label)
      }
    }

    println("\nRISULTATO STADIO 38: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
