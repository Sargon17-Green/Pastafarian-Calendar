package pastafari

import pastafari.monster._
import pastafari.catalog.SourceLanguageCatalog
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY18: offset del catalogo congelato 1-based/0-based. */
object Stage36Tests {
  private var passed=0
  private var failed=0
  private val Huge=(BigInt(1)<<16384)+623
  private val Catalog=SourceLanguageCatalog.Months
  private val All=(1 to 47).toVector
  private val First=Vector(1,2,3)
  private val Wrap=Vector(46,47,1)

  private def check(label:String)(f: => Unit):Unit={
    try {f;passed+=1;println("PASS — "+label)}
    catch {case ex:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+ex.getMessage)
      ex.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(f: => Unit):Unit={
    var found=false
    try f catch {case _:IllegalArgumentException=>found=true}
    truth(found,label+": input illegale accettato")
  }
  private def rejectState(label:String)(f: => Unit):Unit={
    var found=false
    try f catch {case _:IllegalStateException=>found=true}
    truth(found,label+": stato manomesso accettato")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }
  private def old(indices:Vector[Int]=First):
      LegacySourceCatalogMismatchResult =
    LegacySourceCatalogMismatchAdapter.oldSourceCatalogMismatch(indices)
  private def oracle(indices:Vector[Int]):Vector[String]=
    indices.map(i=>SourceLanguageCatalog.month(i).italian)
  private def independentWrong(indices:Vector[Int]):Vector[String]=
    indices.map(i=>Catalog(i%Catalog.size).italian)
  private def ready(indices:Vector[Int]=First):BaseMonsterContext={
    val c=BaseMonsterContext(43,-Huge)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"
    c.catalogMonthIndices=Some(indices)
    new Discovery18SourceCatalogMismatchHandler(new BaseMetricsShell).handle(c)
    c
  }

  def main(args:Array[String]):Unit={
    check("il catalogo sorgente dei mesi ha 47 voci esatte"){
      eqv(Catalog.size,47,"Cardinalita'")
    }
    check("ogni voce ha indice canonico 1..47 in ordine"){
      eqv(Catalog.map(_.canonicalIndex),All,"Identità")
    }
    check("la versione del catalogo congelato è esposta"){
      truth(SourceLanguageCatalog.Version.nonEmpty,"Versione")
      eqv(old().frozenCatalogVersion,SourceLanguageCatalog.Version,"Versione")
    }
    check("il primo nome corretto è argilla"){
      eqv(SourceLanguageCatalog.month(1).italian,"argilla","Nome")
    }
    check("il secondo nome corretto è melagrana"){
      eqv(SourceLanguageCatalog.month(2).italian,"melagrana","Nome")
    }
    check("l'ultimo nome corretto è sabbia"){
      eqv(SourceLanguageCatalog.month(47).italian,"sabbia","Nome")
    }
    check("l'errore del primo mese restituisce melagrana"){
      eqv(old().legacyItalianMonthNames.head,"melagrana","Legacy")
    }
    check("il vecchio vettore per 1,2,3 restituisce 2,3,4"){
      eqv(old().legacyItalianMonthNames,
        Vector("melagrana","gomito","invidia"),"Cicatrice")
    }
    check("il mese 47 ruota al nome argilla"){
      eqv(old(Wrap).legacyItalianMonthNames(1),"argilla","Rotazione")
    }
    check("il mese 46 usa erroneamente sabbia"){
      eqv(old(Wrap).legacyItalianMonthNames.head,"sabbia","Indice")
    }
    check("il mese 1 dopo il giro usa ancora melagrana"){
      eqv(old(Wrap).legacyItalianMonthNames.last,"melagrana","Indice")
    }
    check("il 47 rimane il massimo ID ammesso"){
      eqv(old(Vector(45,46,47)).canonicalMonthIndices,
        Vector(45,46,47),"Limite")
    }
    check("la selezione diagnostica conserva gli ID canonici originali"){
      for(v<-Vector(First,Wrap,All))
        eqv(old(v).canonicalMonthIndices,v,"Input")
    }
    check("la lunghezza dei nomi è identica ai mesi richiesti"){
      for(n<-3 to 47)
        eqv(old(All.take(n)).legacyItalianMonthNames.size,n,"Lunghezza")
    }
    check("la rotazione difettosa è una permutazione dei 47 nomi"){
      val wrong=old(All).legacyItalianMonthNames
      eqv(wrong.distinct.length,47,"Unicita'")
      eqv(wrong.toSet,Catalog.map(_.italian).toSet,"Insieme")
    }
    check("la rotazione difettosa non modifica il catalogo congelato"){
      val before=Catalog
      old(First);old(Wrap);old(All)
      eqv(SourceLanguageCatalog.Months,before,"Immutabile")
    }
    check("la formula storica coincide con una lettura modulo 47"){
      for(v<-Vector(First,Wrap,All))
        eqv(old(v).legacyItalianMonthNames,independentWrong(v),
          "Posizione storica")
    }
    check("tutti i 47 singoli indici hanno un nome legacy differente"){
      val observed=All.map(i=>old(Vector(i,if(i==1)2 else 1,
        if(i==3)4 else 3)).legacyItalianMonthNames.head)
      eqv(observed.distinct.size,47,"Uno per indice")
    }
    check("il ponte legacy è deterministico senza stato globale"){
      val a=old(All)
      for(i<-1 to 128)old(All.drop(i%43).take(3))
      eqv(old(All),a,"Deterministico")
    }
    check("4096 permutazioni sintetiche seguono la formula storica"){
      val rng=new Random(36102026L)
      for(i<-1 to 4096){
        val n=3+rng.nextInt(45)
        val selected=rng.shuffle(All).take(n)
        eqv(old(selected).legacyItalianMonthNames,
          independentWrong(selected),"Campione "+i)
      }
    }
    check("4096 permutazioni non alterano gli indici richiesti"){
      val rng=new Random(18361026L)
      for(i<-1 to 4096){
        val n=3+rng.nextInt(45)
        val selected=rng.shuffle(All).take(n)
        eqv(old(selected).canonicalMonthIndices,selected,
          "Identità "+i)
      }
    }
    check("il catalogo presenta nomi testuali distinti"){
      eqv(Catalog.map(_.italian).distinct.size,47,"Nomi")
    }
    check("ogni nome canonico corretto è stabile"){
      for(i<-1 to 47)
        eqv(oracle(Vector(i)).head,Catalog(i-1).italian,"Oracolo "+i)
    }
    check("il nome storico dell'ID n è il nome canonico dell'ID n+1"){
      for(i<-1 to 46){
        val v=Vector(i,if(i==1)2 else 1,if(i==3)4 else 3)
        eqv(old(v).legacyItalianMonthNames.head,
          SourceLanguageCatalog.month(i+1).italian,"Scarto "+i)
      }
    }
    check("il solo ID 47 salta al primo nome"){
      eqv(old(Vector(47,1,2)).legacyItalianMonthNames.head,
        SourceLanguageCatalog.month(1).italian,"Scarto finale")
    }
    check("il confronto corretto mostra scarto per tutti i 47 ID"){
      for(i<-1 to 47){
        val v=Vector(i,if(i==1)2 else 1,if(i==3)4 else 3)
        truth(old(v).legacyItalianMonthNames.head!=
          oracle(v).head,"Divergenza "+i)
      }
    }
    check("il risultato storico non cambia al variare del giorno esterno"){
      val m=new BaseMonsterManager
      val a=m.discover18SourceCatalogMismatch(0,0,First)
      val b=m.discover18SourceCatalogMismatch(0,123456789,First)
      eqv(a.legacyItalianMonthNames,b.legacyItalianMonthNames,"Giorno")
    }
    check("la PATCH17 seleziona indici distinti prima del lookup diagnostico"){
      val m=new BaseMonsterManager
      val selected=m.patch17DistinctMonthName(1,2,3,1)
      val r=m.discover18SourceCatalogMismatch(1,2,
        selected.correctedCanonicalNameIndices)
      eqv(r.canonicalMonthIndices,Vector(1,2,3),"Indici PATCH17")
      eqv(r.legacyItalianMonthNames,Vector("melagrana","gomito","invidia"),
        "Nomi spostati")
    }
    check("il massimo rango BigInt da PATCH17 resta ordinato fino al catalogo"){
      val m=new BaseMonsterManager
      val rank=NormativeOracle.fallingFactorial(47,47)
      val selected=m.patch17DistinctMonthName(Huge,-Huge,47,rank)
      val report=m.discover18SourceCatalogMismatch(Huge,-Huge,
        selected.correctedCanonicalNameIndices)
      eqv(report.canonicalMonthIndices,All.reverse,"Ordine")
      eqv(report.legacyItalianMonthNames,independentWrong(All.reverse),
        "Nomi sbagliati")
    }
    check("il mapping storico non dipende dal rango BigInt dopo PATCH17"){
      val m=new BaseMonsterManager
      for(rank<-Vector[BigInt](1,2,47,
        NormativeOracle.fallingFactorial(47,47))){
        val p=m.patch17DistinctMonthName(0,0,47,rank)
        val r=m.discover18SourceCatalogMismatch(0,0,
          p.correctedCanonicalNameIndices)
        eqv(r.legacyItalianMonthNames,
          independentWrong(p.correctedCanonicalNameIndices),"Rank "+rank)
      }
    }
    check("la sequenza minima di 3 indici distinti è accettata"){
      eqv(old(Vector(5,1,47)).legacyItalianMonthNames.size,3,"Minimo")
    }
    check("la sequenza di 47 indici distinti è accettata"){
      eqv(old(All).legacyItalianMonthNames.size,47,"Massimo")
    }
    check("due nomi canonici uguali vengono rifiutati"){
      rejectArg("Doppio"){old(Vector(1,1,2))}
    }
    check("tre nomi tutti uguali vengono rifiutati"){
      rejectArg("Triplo"){old(Vector(1,1,1))}
    }
    check("vettore con meno di 3 mesi viene rifiutato"){
      rejectArg("Due"){old(Vector(1,2))}
      rejectArg("Vuoto"){old(Vector.empty)}
    }
    check("vettore con più di 47 mesi viene rifiutato"){
      rejectArg("Quarantotto"){old(All:+47)}
    }
    check("indice zero viene rifiutato"){
      rejectArg("Zero"){old(Vector(0,1,2))}
    }
    check("indice negativo viene rifiutato"){
      rejectArg("Negativo"){old(Vector(-1,1,2))}
    }
    check("indice 48 viene rifiutato"){
      rejectArg("48"){old(Vector(1,2,48))}
    }
    check("il manager presenta trace, versione e metriche esatte"){
      val m=new BaseMonsterManager
      val r=m.discover18SourceCatalogMismatch(Huge,-Huge,First)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Domanda")
      eqv(r.canonicalMonthIndices,First,"Selezione")
      eqv(r.frozenCatalogVersion,SourceLanguageCatalog.Version,"Versione")
      eqv(r.legacyItalianMonthNames,
        Vector("melagrana","gomito","invidia"),"Nomi")
      eqv(r.phase,"DISCOVERY_18_SOURCE_CATALOG_MISMATCH","Fase")
      eqv(r.status,"LEGACY_SOURCE_CATALOG_MISMATCH_READY","Status")
      eqv(r.trace,Vector("BOOT","DISCOVERY_18_SOURCE_CATALOG_MISMATCH"),
        "Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery18.source.catalog.calls"),BigInt(1),
        "Discovery")
    }
    check("la stessa istanza manager non altera report precedenti"){
      val m=new BaseMonsterManager
      val a=m.discover18SourceCatalogMismatch(1,2,First)
      val b=m.discover18SourceCatalogMismatch(3,4,Wrap)
      eqv(a.legacyItalianMonthNames,
        Vector("melagrana","gomito","invidia"),"Primo")
      eqv(b.legacyItalianMonthNames,independentWrong(Wrap),"Secondo")
      eqv(m.metricsSnapshot("discovery18.source.catalog.calls"),BigInt(2),
        "Metriche")
    }
    check("due manager tengono metriche e stato separati"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      eqv(a.discover18SourceCatalogMismatch(1,2,First).legacyItalianMonthNames,
        independentWrong(First),"A")
      eqv(b.discover18SourceCatalogMismatch(3,4,Wrap).legacyItalianMonthNames,
        independentWrong(Wrap),"B")
      eqv(a.metricsSnapshot("discovery18.source.catalog.calls"),BigInt(1),
        "Counter A")
      eqv(b.metricsSnapshot("discovery18.source.catalog.calls"),BigInt(1),
        "Counter B")
    }
    check("handler rifiuta contesto senza bootstrap"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"
      rejectState("Nessun BOOT"){
        new Discovery18SourceCatalogMismatchHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta bootstrap senza ID canonici"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"
      rejectState("Senza input"){
        new Discovery18SourceCatalogMismatchHandler(new BaseMetricsShell).handle(c)}
      truth(c.catalogLegacyItalianNames.isEmpty,"Nessun output")
    }
    check("handler rifiuta una seconda discovery"){
      val c=ready()
      rejectState("Seconda"){
        new Discovery18SourceCatalogMismatchHandler(new BaseMetricsShell).handle(c)}
    }
    check("validator indipendente accetta input autentico"){
      new BaseValidationManager().requireDiscovery18Ready(ready())
    }
    check("validator indipendente accetta tutti i conteggi 3..47"){
      val v=new BaseValidationManager
      for(n<-3 to 47)v.requireDiscovery18Ready(ready(All.take(n)))
    }
    check("validator accetta tutte le rotazioni su 47 mesi"){
      val v=new BaseValidationManager
      for(offset<-0 until 47)
        v.requireDiscovery18Ready(ready(All.drop(offset)++All.take(offset)))
    }
    check("validator rifiuta nome legacy falsificato"){
      val c=ready()
      c.catalogLegacyItalianNames=Some(Vector("argilla","gomito","invidia"))
      rejectState("Nome"){new BaseValidationManager().requireDiscovery18Ready(c)}
    }
    check("validator rifiuta il numero di nomi errato"){
      val c=ready()
      c.catalogLegacyItalianNames=Some(Vector("melagrana"))
      rejectState("Lunghezza"){new BaseValidationManager().requireDiscovery18Ready(c)}
    }
    check("validator rifiuta versione catalogo falsificata"){
      val c=ready()
      c.catalogFrozenVersion=Some("9999")
      rejectState("Versione"){new BaseValidationManager().requireDiscovery18Ready(c)}
    }
    check("validator rifiuta indici cambiati dopo discovery"){
      val c=ready()
      c.catalogMonthIndices=Some(Vector(1,2,4))
      rejectState("Input"){new BaseValidationManager().requireDiscovery18Ready(c)}
    }
    check("validator rifiuta snapshot falsificata"){
      val c=ready()
      c.catalogInputSnapshot=Some(Vector(1,2,4))
      rejectState("Snapshot"){new BaseValidationManager().requireDiscovery18Ready(c)}
    }
    check("validator rifiuta snapshot assente"){
      val c=ready()
      c.catalogInputSnapshot=None
      rejectState("Mancante"){new BaseValidationManager().requireDiscovery18Ready(c)}
    }
    check("validator rifiuta output storico assente"){
      val c=ready()
      c.catalogLegacyItalianNames=None
      rejectState("Senza output"){new BaseValidationManager().requireDiscovery18Ready(c)}
    }
    check("validator rifiuta stato, trace e fase falsificati"){
      val c=ready()
      val v=new BaseValidationManager
      c.status="BOOTSTRAPPED"
      rejectState("Status"){v.requireDiscovery18Ready(c)}
      c.status="LEGACY_SOURCE_CATALOG_MISMATCH_READY"
      c.branchTrace.remove(1)
      rejectState("Trace"){v.requireDiscovery18Ready(c)}
      c.branchTrace.append("DISCOVERY_18_SOURCE_CATALOG_MISMATCH")
      c.phase="PATCH_18_SOURCE_CATALOG_MISMATCH"
      rejectState("Phase"){v.requireDiscovery18Ready(c)}
    }
    check("le 17 PATCH precedenti restano operative"){
      val m=new BaseMonsterManager
      val mod=NormativeOracle.M
      val foundation=NormativeOracle.FoundationDay
      val A=Vector.fill(84)(1)++Vector.fill(84)(2)++Vector.fill(84)(3)
      val B=Vector(1,2)++Vector.fill(83)(1)++
        Vector.fill(83)(2)++Vector.fill(84)(3)
      val C=Vector(1,1,2)++Vector.fill(82)(1)++
        Vector.fill(83)(2)++Vector.fill(84)(3)
      eqv(m.patch01Save(0,0,mod).patchedOutput,mod,"P01")
      eqv(m.patch02DayTag(foundation,foundation,foundation).patchedTag,
        BigInt(1),"P02")
      eqv(m.patch03Distance(foundation,foundation).patchedDistance,
        BigInt(1),"P03")
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
      eqv(m.patch15DaywiseWeaving(0,0,Vector(A,C,B),2,2).correctedDayInMonth,
        1,"P15")
      eqv(m.patch16ContiguousMonthDay(0,0,C,2).correctedDayInMonth,1,"P16")
      eqv(m.patch17DistinctMonthName(0,0,3,1).correctedCanonicalNameIndices,
        Vector(1,2,3),"P17")
    }
    check("oracolo test-only, catalogo intatto e nessuna PATCH18"){
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo test-only")
      truth(sources.contains("def oldSourceCatalogMismatch("),"Cicatrice")
      truth(!sources.contains("def sourceCatalogIndexPatch("),"PATCH18 anticipata")
      eqv(SourceLanguageCatalog.Months,Catalog,"Catalogo immutabile")
    }
    check("metadati Stage36 preservano Stage35"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=36"),"Stage")
      truth(st.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
      truth(st.contains("CURRENT_PATCH=17"),"Patch precedente")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"RED")
      truth(st.contains("STAGE_35_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_71_PASS_0_FAIL"),
        "PATCH17 certificata")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(done==35 || done==36,"Sequenza")
    }

    Vector(
      ("INDEX1_ITALIAN_NAME",First),
      ("INDEX47_WRAP",Wrap),
      ("INDEX1_TO_47",All)
    ).foreach { case (label,indices) =>
      check("equivalenza normativa catalogo "+label){
        val r=new BaseMonsterManager().discover18SourceCatalogMismatch(
          43,-Huge,indices)
        eqv(r.legacyItalianMonthNames,oracle(indices),
          "Indice canonico convertito male: "+label)
      }
    }
    println("\nRISULTATO STADIO 36: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
