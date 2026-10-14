package pastafari

import pastafari.monster._
import pastafari.catalog.SourceLanguageCatalog
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 18: indici canonici 1..47 risolti nel catalogo italiano immutato. */
object Stage37Tests {
  private var passed=0
  private var failed=0
  private val Huge=(BigInt(1)<<16384)+37
  private val Catalog=SourceLanguageCatalog.Months
  private val All=(1 to 47).toVector
  private val First=Vector(1,2,3)
  private val Wrap=Vector(46,47,1)
  private val Last=Vector(45,46,47)

  private def check(label:String)(run: => Unit):Unit={
    try {run;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)
      throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(run: => Unit):Unit={
    var got=false
    try run catch {case _:IllegalArgumentException=>got=true}
    truth(got,label+": valore illegale accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var got=false
    try run catch {case _:IllegalStateException=>got=true}
    truth(got,label+": stato illegale accettato")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }

  private def oracle(ids:Vector[Int]):Vector[String]=
    ids.map(i=>SourceLanguageCatalog.month(i).italian)

  // Riferimento test-only indipendente dal wrapper PATCH18:
  // percorre il catalogo e confronta canonicalIndex, non usa i-1.
  private def independent(ids:Vector[Int]):Vector[String]={
    ids.map { id =>
      val matches=Catalog.filter(_.canonicalIndex==id)
      eqv(matches.size,1,"ID presente una volta")
      matches.head.italian
    }
  }

  private def patched(ids:Vector[Int]=First):Patch18SourceCatalogResult=
    Patch18SourceCatalogWrapper.sourceCatalogIndexPatch(ids)

  private def ready(ids:Vector[Int]=First):BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"
    c.catalogMonthIndices=Some(ids)
    new Discovery18SourceCatalogMismatchHandler(new BaseMetricsShell).handle(c)
    c.phase="PATCH_18_SOURCE_CATALOG_INDEX"
    new Patch18SourceCatalogHandler(new BaseMetricsShell).handle(c)
    c
  }

  def main(args:Array[String]):Unit={
    check("catalogo italiano contiene esattamente 47 nomi"){
      eqv(Catalog.length,47,"Lunghezza")
    }
    check("indici canonici nel catalogo sono precisamente 1..47"){
      eqv(Catalog.map(_.canonicalIndex),All,"Indice")
    }
    check("il catalogo congelato espone la versione prevista"){
      truth(SourceLanguageCatalog.Version.nonEmpty,"Versione presente")
    }
    check("il primo indice è argilla, non melagrana"){
      eqv(patched().correctedItalianMonthNames.head,"argilla","Mese uno")
    }
    check("il secondo indice è melagrana"){
      eqv(patched().correctedItalianMonthNames(1),"melagrana","Mese due")
    }
    check("il terzo indice è gomito"){
      eqv(patched().correctedItalianMonthNames(2),"gomito","Mese tre")
    }
    check("ultimi nomi corretti 45,46,47 sono pera, arco, sabbia"){
      eqv(patched(Last).correctedItalianMonthNames,
        Vector("pera","arco","sabbia"),"Ultimi nomi")
    }
    check("46,47,1 mantengono arco, sabbia, argilla"){
      eqv(patched(Wrap).correctedItalianMonthNames,
        Vector("arco","sabbia","argilla"),"Nomi normativi")
    }
    check("il nome dell'ID 47 non torna alla prima posizione"){
      eqv(patched(Wrap).correctedItalianMonthNames(1),"sabbia","Ultimo")
    }
    check("il nome dell'ID 1 resta il primo dopo una rotazione"){
      eqv(patched(Wrap).correctedItalianMonthNames.last,"argilla","Primo")
    }
    check("l'indice 46 non slitta verso 47"){
      eqv(patched(Wrap).correctedItalianMonthNames.head,"arco","46")
    }
    check("il vecchio primo indice rimane melagrana"){
      eqv(patched().historical.legacyItalianMonthNames.head,
        "melagrana","Legacy")
    }
    check("il vecchio ID 47 rimane argilla"){
      eqv(patched(Wrap).historical.legacyItalianMonthNames(1),
        "argilla","Legacy 47")
    }
    check("il vecchio vettore 1,2,3 mantiene lo slittamento"){
      eqv(patched().historical.legacyItalianMonthNames,
        Vector("melagrana","gomito","invidia"),"Legacy")
    }
    check("l'intero catalogo è riportato nell'ordine corretto"){
      eqv(patched(All).correctedItalianMonthNames,Catalog.map(_.italian),
        "Tutti i nomi")
    }
    check("il vecchio catalogo completo resta ruotato di un nome"){
      eqv(patched(All).historical.legacyItalianMonthNames,
        Catalog.tail.map(_.italian)++Vector(Catalog.head.italian),
        "Legacy completo")
    }
    check("l'identità degli indici non viene alterata dalla patch"){
      for(ids<-Vector(First,Last,Wrap,All))
        eqv(patched(ids).historical.canonicalMonthIndices,ids,"Indice")
    }
    check("la versione del catalogo resta identica al legacy"){
      for(ids<-Vector(First,Last,Wrap,All))
        eqv(patched(ids).historical.frozenCatalogVersion,
          SourceLanguageCatalog.Version,"Versione")
    }
    check("tutti i 47 indici mappano al nome di canonicalIndex"){
      for(i<-1 to 47){
        val ids=Vector(i)+:Vector.empty[Vector[Int]]
        val valid=if(i<=45)Vector(i,i+1,i+2)
          else if(i==46)Vector(46,47,1)
          else Vector(47,1,2)
        val pos=valid.indexOf(i)
        eqv(patched(valid).correctedItalianMonthNames(pos),
          independent(Vector(i)).head,"Indice "+i)
      }
    }
    check("il wrapper coincide con l'oracolo per gruppi estremi"){
      for(ids<-Vector(First,Wrap,Last,All))
        eqv(patched(ids).correctedItalianMonthNames,oracle(ids),"Nomi")
    }
    check("il wrapper coincide col riferimento indipendente per 3..47 mesi"){
      for(n<-3 to 47){
        val ids=(1 to n).toVector
        eqv(patched(ids).correctedItalianMonthNames,
          independent(ids),"Conteggio "+n)
      }
    }
    check("47 mesi non contengono mai un nome duplicato"){
      val names=patched(All).correctedItalianMonthNames
      eqv(names.distinct.size,47,"Unicità")
    }
    check("qualsiasi sequenza lecita mantiene cardinalità e unicità"){
      for(n<-3 to 47){
        val names=patched((1 to n).toVector).correctedItalianMonthNames
        eqv(names.length,n,"Lunghezza "+n)
        eqv(names.distinct.length,n,"Unici "+n)
      }
    }
    check("la patch non cambia le voci del catalogo sorgente"){
      val original=Catalog
      patched(All)
      eqv(SourceLanguageCatalog.Months,original,"Catalogo")
    }
    check("il risultato rimane stabile dopo richieste intercalate"){
      val r=patched(Wrap)
      for(n<-3 to 47)patched((1 to n).toVector)
      eqv(patched(Wrap),r,"Determinismo")
    }
    check("l'output vecchio è sempre il vero adapter legacy"){
      for(ids<-Vector(First,Wrap,Last,All))
        eqv(patched(ids).historical,
          LegacySourceCatalogMismatchAdapter.oldSourceCatalogMismatch(ids),
          "Cicatrice")
    }
    check("4096 permutazioni riproducibili restituiscono i nomi esatti"){
      val random=new Random(37102026L)
      for(i<-1 to 4096){
        val ids=random.shuffle(All).take(3+random.nextInt(45)).toVector
        val got=patched(ids)
        eqv(got.correctedItalianMonthNames,
          independent(ids),"Oracolo "+i)
        eqv(got.historical.legacyItalianMonthNames,
          ids.map(id=>Catalog(id%47).italian),"Legacy "+i)
      }
    }
    check("4096 permutazioni non contaminano la scelta in due manager"){
      val random=new Random(18371026L)
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      for(i<-1 to 4096){
        val ids=random.shuffle(All).take(3+random.nextInt(45)).toVector
        val m=if(i%2==0)a else b
        val r=m.patch18SourceCatalogIndex(i,-Huge,ids)
        eqv(r.correctedItalianMonthNames,independent(ids),"Report "+i)
        eqv(r.legacyItalianMonthNames,
          ids.map(id=>Catalog(id%47).italian),"Legacy "+i)
      }
      eqv(a.metricsSnapshot("patch18.source.catalog.calls"),
        BigInt(2048),"Manager A")
      eqv(b.metricsSnapshot("patch18.source.catalog.calls"),
        BigInt(2048),"Manager B")
    }
    check("integrazione PATCH17 usa indici selezionati dal rango"){
      val m=new BaseMonsterManager
      for(rank<-1 to 20){
        val selected=m.patch17DistinctMonthName(0,0,3,rank)
        val names=m.patch18SourceCatalogIndex(0,0,
          selected.correctedCanonicalNameIndices)
        eqv(names.correctedItalianMonthNames,
          oracle(selected.correctedCanonicalNameIndices),
          "Rango "+rank)
      }
    }
    check("indice 47 scelto via PATCH17 porta davvero a sabbia"){
      val ids=new BaseMonsterManager().patch17DistinctMonthName(
        0,0,47,1).correctedCanonicalNameIndices
      eqv(patched(ids).correctedItalianMonthNames.last,"sabbia",
        "Ultimo mese")
    }
    check("il vecchio valore può differire da ogni nome corretto"){
      for(i<-1 to 47){
        val ids=if(i<=45)Vector(i,i+1,i+2)
          else if(i==46)Wrap else Vector(47,1,2)
        val r=patched(ids);val position=ids.indexOf(i)
        truth(r.correctedItalianMonthNames(position)!=
          r.historical.legacyItalianMonthNames(position),
          "Divergenza "+i)
      }
    }
    check("rifiuta catalogo di soli due indici"){
      rejectArg("Due"){patched(Vector(1,2))}
    }
    check("rifiuta vettore vuoto"){
      rejectArg("Vuoto"){patched(Vector.empty)}
    }
    check("rifiuta vettore più lungo di 47"){
      rejectArg("Lungo"){patched(All:+1)}
    }
    check("rifiuta indici canonici duplicati"){
      rejectArg("Duplicato"){patched(Vector(1,1,2))}
    }
    check("rifiuta ID 0"){
      rejectArg("Zero"){patched(Vector(0,1,2))}
    }
    check("rifiuta ID 48"){
      rejectArg("Fuori"){patched(Vector(1,2,48))}
    }
    check("rifiuta indice negativo"){
      rejectArg("Negativo"){patched(Vector(-1,1,2))}
    }
    check("il manager pubblica entrambe le versioni nella stessa trace"){
      val m=new BaseMonsterManager
      val r=m.patch18SourceCatalogIndex(Huge,-Huge,Wrap)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Target")
      eqv(r.canonicalMonthIndices,Wrap,"ID")
      eqv(r.frozenCatalogVersion,SourceLanguageCatalog.Version,"Versione")
      eqv(r.legacyItalianMonthNames,
        Vector("sabbia","argilla","melagrana"),"Vecchi")
      eqv(r.correctedItalianMonthNames,
        Vector("arco","sabbia","argilla"),"Corretti")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_18_SOURCE_CATALOG_INDEX","Fase")
      eqv(r.status,"PATCH_18_READY","Stato")
      eqv(r.trace,Vector("BOOT",
        "DISCOVERY_18_SOURCE_CATALOG_MISMATCH",
        "PATCH_18_SOURCE_CATALOG_INDEX"),"Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery18.source.catalog.calls"),
        BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch18.source.catalog.calls"),
        BigInt(1),"Patch")
    }
    check("un manager riutilizzato mantiene report precedenti"){
      val m=new BaseMonsterManager
      val first=m.patch18SourceCatalogIndex(1,2,First)
      val second=m.patch18SourceCatalogIndex(3,4,Wrap)
      eqv(first.correctedItalianMonthNames,
        Vector("argilla","melagrana","gomito"),"Primo")
      eqv(first.legacyItalianMonthNames,
        Vector("melagrana","gomito","invidia"),"Storico")
      eqv(second.correctedItalianMonthNames,
        Vector("arco","sabbia","argilla"),"Secondo")
      eqv(m.metricsSnapshot("patch18.source.catalog.calls"),BigInt(2),
        "Metriche")
    }
    check("due manager hanno metriche indipendenti"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      a.patch18SourceCatalogIndex(1,2,First)
      b.patch18SourceCatalogIndex(3,4,Wrap)
      eqv(a.metricsSnapshot("patch18.source.catalog.calls"),BigInt(1),"A")
      eqv(b.metricsSnapshot("patch18.source.catalog.calls"),BigInt(1),"B")
    }
    check("manager di sola discovery conserva il valore storico"){
      val m=new BaseMonsterManager
      val old=m.discover18SourceCatalogMismatch(1,2,First)
      val now=m.patch18SourceCatalogIndex(1,2,First)
      eqv(old.legacyItalianMonthNames,now.legacyItalianMonthNames,"Legacy")
      truth(old.legacyItalianMonthNames!=
        now.correctedItalianMonthNames,"Divergenza")
    }
    check("handler rifiuta contesto mai bootstrapped"){
      val c=BaseMonsterContext(1,2)
      c.phase="PATCH_18_SOURCE_CATALOG_INDEX"
      rejectState("Nessun BOOT"){
        new Patch18SourceCatalogHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta bootstrap privo della discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_18_SOURCE_CATALOG_INDEX"
      rejectState("Nessuna discovery"){
        new Patch18SourceCatalogHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta applicazione ripetuta"){
      val c=ready()
      rejectState("Due patch"){
        new Patch18SourceCatalogHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta una cicatrice falsificata senza pubblicare output"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"
      c.catalogMonthIndices=Some(First)
      new Discovery18SourceCatalogMismatchHandler(new BaseMetricsShell)
        .handle(c)
      c.phase="PATCH_18_SOURCE_CATALOG_INDEX"
      c.catalogLegacyItalianNames=Some(Vector("argilla","gomito","invidia"))
      rejectState("Manomissione legacy"){
        new Patch18SourceCatalogHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedCatalogItalianNames.isEmpty,"Nessun output")
      truth(!c.patch18Applied,"Nessun flag")
    }
    check("handler rifiuta gli indici mutati anche se primo nome coincide"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"
      c.catalogMonthIndices=Some(First)
      new Discovery18SourceCatalogMismatchHandler(new BaseMetricsShell)
        .handle(c)
      c.phase="PATCH_18_SOURCE_CATALOG_INDEX"
      c.catalogMonthIndices=Some(Vector(1,2,4))
      rejectState("ID post-hoc"){
        new Patch18SourceCatalogHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedCatalogItalianNames.isEmpty,"Nessuna pubblicazione")
    }
    check("validator accetta una patch autentica"){
      new BaseValidationManager().requirePatch18Ready(ready(First))
    }
    check("validator accetta nomi finali di ogni mese"){
      val v=new BaseValidationManager
      for(n<-3 to 47)
        v.requirePatch18Ready(ready((1 to n).toVector))
    }
    check("validator accetta i casi di rotazione e catalogo completo"){
      val v=new BaseValidationManager
      for(ids<-Vector(First,Wrap,Last,All))
        v.requirePatch18Ready(ready(ids))
    }
    check("validator accetta 128 vettori aleatori deterministici"){
      val v=new BaseValidationManager
      val rng=new Random(182018L)
      for(i<-1 to 128)
        v.requirePatch18Ready(ready(
          rng.shuffle(All).take(3+rng.nextInt(45)).toVector))
    }
    check("validator rifiuta il nome corretto falsificato"){
      val c=ready(First)
      c.patchedCatalogItalianNames=Some(
        Vector("argilla","gomito","melagrana"))
      rejectState("Nomi"){new BaseValidationManager().requirePatch18Ready(c)}
    }
    check("validator rifiuta il nome storico falsificato"){
      val c=ready(First)
      c.catalogLegacyItalianNames=Some(
        Vector("argilla","gomito","invidia"))
      rejectState("Legacy"){new BaseValidationManager().requirePatch18Ready(c)}
    }
    check("validator rifiuta il catalogo/versione falsificata"){
      val c=ready(First)
      c.catalogFrozenVersion=Some("0000-invalid")
      rejectState("Versione"){new BaseValidationManager().requirePatch18Ready(c)}
    }
    check("validator rifiuta gli indici mutati"){
      val c=ready(First)
      c.catalogMonthIndices=Some(Vector(1,2,4))
      rejectState("ID"){new BaseValidationManager().requirePatch18Ready(c)}
    }
    check("validator rifiuta snapshot mutata"){
      val c=ready(First)
      c.catalogInputSnapshot=Some(Vector(1,2,4))
      rejectState("Snapshot"){new BaseValidationManager().requirePatch18Ready(c)}
    }
    check("validator rifiuta snapshot assente"){
      val c=ready(First)
      c.catalogInputSnapshot=None
      rejectState("Assente"){new BaseValidationManager().requirePatch18Ready(c)}
    }
    check("validator rifiuta output patch mancante"){
      val c=ready(First)
      c.patchedCatalogItalianNames=None
      rejectState("Vuoto"){new BaseValidationManager().requirePatch18Ready(c)}
    }
    check("validator rifiuta i nomi patch duplicati"){
      val c=ready(First)
      c.patchedCatalogItalianNames=Some(Vector("argilla","argilla","gomito"))
      rejectState("Duplicato"){new BaseValidationManager().requirePatch18Ready(c)}
    }
    check("validator rifiuta flag status phase e trace alterati"){
      val c=ready(First)
      val v=new BaseValidationManager
      c.patch18Applied=false
      rejectState("Flag"){v.requirePatch18Ready(c)}
      c.patch18Applied=true
      c.status="LEGACY_SOURCE_CATALOG_MISMATCH_READY"
      rejectState("Status"){v.requirePatch18Ready(c)}
      c.status="PATCH_18_READY"
      c.branchTrace.remove(1)
      rejectState("Trace"){v.requirePatch18Ready(c)}
      c.branchTrace.insert(1,"DISCOVERY_18_SOURCE_CATALOG_MISMATCH")
      c.phase="DISCOVERY_18_SOURCE_CATALOG_MISMATCH"
      rejectState("Phase"){v.requirePatch18Ready(c)}
    }
    check("le diciassette patch precedenti restano operative"){
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
    check("oracolo test-only, cicatrice viva e nessuna Stage38"){
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo test-only")
      truth(sources.contains("def oldSourceCatalogMismatch("),"Cicatrice")
      truth(sources.contains("def sourceCatalogIndexPatch("),"PATCH18")
      truth(!sources.contains("oldCutletNameIndexRotated"),"Stage38 futura")
      eqv(SourceLanguageCatalog.Months,Catalog,"Catalogo intatto")
    }
    check("metadati Stage37 conservano Stage36 e lo stato GREEN"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      truth(current>=37,"Stage")
      if(current==37)truth(st.contains("CURRENT_KIND=PATCH"),"Patch")
      truth(st.contains("CURRENT_PATCH=18"),"Patch 18")
      truth(st.contains("STAGE_36_NATIVE_VERIFICATION=PASS_EXPECTED_RED_59_PASS_3_FAIL"),
        "Discovery18 storica")
      truth(st.contains("STAGE_35_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_71_PASS_0_FAIL"),
        "Patch17 storica")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(done>=36 && done<=current,"Sequenza")
    }
    println("\nRISULTATO STADIO 37: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
