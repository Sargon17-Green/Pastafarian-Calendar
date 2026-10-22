package pastafari

import pastafari.monster._
import pastafari.catalog.SourceLanguageCatalog
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY21: la cicatrice del nome ricavato dal resto del giorno. */
object Stage42Tests {
  private var passed=0
  private var failed=0
  private val Six=Vector.fill(6)(42)
  private val Parts=Vector.fill(6)(1)
  private val Names=(1 to 6).toVector
  private val Seventeen=Vector.fill(17)(42)
  private val Parts17=Vector.fill(17)(1)
  private val Names17=(1 to 17).toVector
  private val Huge=(BigInt(1)<<16384)+42

  private def check(label:String)(f: => Unit):Unit={
    try {f;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
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
  private def old(
    g:Vector[Int]=Six,p:Vector[Int]=Parts,
    ids:Vector[Int]=Names,d:Int=1
  ):LegacyDayIndexedCutletNameResult =
    LegacyDayIndexedCutletNameAdapter.oldDayIndexedCutletName(g,p,ids,d)

  // Oracolo test-only: selezione dalla somma degli intervalli
  // delle porte, non dal resto del giorno, adapter o manager.
  private def normative(
    g:Vector[Int],p:Vector[Int],ids:Vector[Int],d:Int
  ):String={
    var start=0
    var gate=0
    for((n,index)<-p.zipWithIndex) {
      var duration=0
      var k=0
      while(k<n){duration+=g(gate);gate+=1;k+=1}
      if(d>=start && d<start+duration) {
        val matches=SourceLanguageCatalog.Cutlets.filter(
          _.canonicalIndex==ids(index))
        eqv(matches.size,1,"Nome canonico univoco")
        return matches.head.italian
      }
      start+=duration
    }
    throw new AssertionError("Il giorno non appartiene ad alcuna cotoletta")
  }
  private def ready():BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_21_DAY_INDEXED_CUTLET_NAME"
    c.cutletNameGateGaps=Some(Six)
    c.cutletNamePartition=Some(Parts)
    c.cutletCanonicalNameIndices=Some(Names)
    c.cutletNameDayOffset=Some(1)
    new Discovery21DayIndexedCutletNameHandler(
      new BaseMetricsShell).handle(c)
    c
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir"))
      .toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&
       p.getParent!=null)p=p.getParent
    p
  }

  def main(args:Array[String]):Unit={
    check("catalogo congelato: 17 nomi indicizzati 1..17"){
      eqv(SourceLanguageCatalog.Cutlets.map(_.canonicalIndex),
        Names17,"Indici")
    }
    check("versione catalogo non vuota"){
      truth(SourceLanguageCatalog.Version.nonEmpty,"Versione")
    }
    check("giorno zero prende il primo nome"){
      eqv(old(d=0).legacyItalianName,"bronzo","Inizio")
    }
    check("giorno uno prende storicamente il secondo nome"){
      eqv(old().legacyItalianName,"volpe","Cicatrice")
    }
    check("giorno 6 riavvolge allo slot zero"){
      eqv(old(d=6).legacyNameSlot,0,"Modulo")
    }
    check("giorno 41 produce lo slot 5"){
      eqv(old(d=41).legacyNameSlot,5,"Modulo")
    }
    check("giorno 42 riavvolge allo slot 0"){
      eqv(old(d=42).legacyNameSlot,0,"Modulo")
    }
    check("il primo giorno della seconda ha nome storico errato"){
      eqv(old(d=42).legacyItalianName,"bronzo","Storico")
    }
    check("17 cotolette coprono 714 giorni"){
      eqv(Seventeen.sum,714,"Totale")
    }
    check("17 cotolette al giorno 42 usano slot 8"){
      eqv(old(Seventeen,Parts17,Names17,42).legacyNameSlot,8,"Slot")
    }
    check("versione catalogo preservata nel report"){
      eqv(old().catalogVersion,SourceLanguageCatalog.Version,"Versione")
    }
    check("permuta reversa seleziona il nome antico previsto"){
      val r=old(Six,Parts,Names.reverse,1)
      eqv(r.legacyCanonicalNameId,5,"ID")
    }
    check("output non cambia i vettori sorgente"){
      val r=old()
      eqv(r.gateGaps,Six,"Gaps")
      eqv(r.cutletPartition,Parts,"Partition")
      eqv(r.canonicalCutletNameIndices,Names,"Names")
    }
    check("tutti i 252 giorni storici seguono il modulo 6"){
      for(d<-0 until Six.sum){
        val r=old(d=d)
        eqv(r.legacyNameSlot,d%6,"Giorno "+d)
        eqv(r.legacyCanonicalNameId,Names(d%6),"ID "+d)
      }
    }
    check("tutti i 714 giorni storici seguono il modulo 17"){
      for(d<-0 until Seventeen.sum)
        eqv(old(Seventeen,Parts17,Names17,d).legacyNameSlot,
          d%17,"Giorno "+d)
    }
    check("4096 permutazioni e offset pseudo-casuali"){
      val rng=new Random(42102026L)
      for(k<-1 to 4096){
        val n=6+rng.nextInt(12)
        val g=Vector.fill(n)(42+rng.nextInt(160))
        val p=Vector.fill(n)(1)
        val ids=rng.shuffle(Names17).take(n).toVector
        val d=rng.nextInt(g.sum)
        val r=old(g,p,ids,d)
        eqv(r.legacyCanonicalNameId,ids(d%n),"ID "+k)
        eqv(r.legacyItalianName,
          SourceLanguageCatalog.Cutlets.find(
            _.canonicalIndex==ids(d%n)).get.italian,"Name "+k)
      }
    }
    check("il nome normativo e storico coincidono talvolta"){
      eqv(old(d=0).legacyItalianName,
        normative(Six,Parts,Names,0),"Giorno zero")
    }
    check("un manager conserva numeri BigInt molto grandi"){
      val r=new BaseMonsterManager().discover21DayIndexedCutletName(
        Huge,-Huge,Six,Parts,Names,1)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Bersaglio")
    }
    check("manager conserva stato e traccia completi"){
      val r=new BaseMonsterManager().discover21DayIndexedCutletName(
        1,2,Six,Parts,Names,1)
      eqv(r.phase,"DISCOVERY_21_DAY_INDEXED_CUTLET_NAME","Fase")
      eqv(r.status,"LEGACY_DAY_INDEXED_CUTLET_NAME_READY","Status")
      eqv(r.trace,Vector("BOOT","DISCOVERY_21_DAY_INDEXED_CUTLET_NAME"),
        "Trace")
      eqv(r.legacyItalianName,"volpe","Nome")
    }
    check("i manager mantengono metriche isolate"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      a.discover21DayIndexedCutletName(1,2,Six,Parts,Names,1)
      b.discover21DayIndexedCutletName(3,4,Six,Parts,Names,42)
      eqv(a.metricsSnapshot("discovery21.cutlet.name.calls"),
        BigInt(1),"A")
      eqv(b.metricsSnapshot("discovery21.cutlet.name.calls"),
        BigInt(1),"B")
    }
    check("il report precedente resta immutato"){
      val m=new BaseMonsterManager
      val first=m.discover21DayIndexedCutletName(
        1,2,Six,Parts,Names,1)
      val frozen=first.copy()
      m.discover21DayIndexedCutletName(3,4,Six,Parts,Names,42)
      eqv(first,frozen,"Report")
    }
    check("rifiuta cinque cotolette"){
      rejectArg("Numero"){old(Six,Vector(1,1,1,1,2),Names,1)}
    }
    check("rifiuta diciotto cotolette"){
      rejectArg("Numero"){old(Vector.fill(18)(42),
        Vector.fill(18)(1),Names17,1)}
    }
    check("rifiuta nomi duplicati"){
      rejectArg("Duplicati"){old(ids=Vector(1,1,2,3,4,5))}
    }
    check("rifiuta ID canonico zero"){
      rejectArg("Zero"){old(ids=Vector(0,2,3,4,5,6))}
    }
    check("rifiuta ID fuori catalogo"){
      rejectArg("Diciotto"){old(ids=Vector(1,2,3,4,5,18))}
    }
    check("rifiuta elenco nomi troppo corto"){
      rejectArg("Lunghezza"){old(ids=Vector(1,2,3))}
    }
    check("rifiuta giorno negativo"){
      rejectArg("Negativo"){old(d = -1)}
    }
    check("rifiuta la fine anno esclusiva"){
      rejectArg("Fine"){old(d=Six.sum)}
    }
    check("rifiuta intervallo inferiore a 42"){
      rejectArg("Minimo"){old(g=Vector(41,42,42,42,42,43))}
    }
    check("rifiuta intervallo superiore a 963"){
      rejectArg("Massimo"){old(g=Vector(964,42,42,42,42,42))}
    }
    check("rifiuta partizione non esaustiva"){
      rejectArg("Partizione"){old(p=Vector(1,1,1,1,1,2))}
    }
    check("validator indipendente accetta la discovery valida"){
      new BaseValidationManager().requireDiscovery21Ready(ready())
    }
    check("validator rifiuta il nome falsificato"){
      val c=ready();c.legacyCutletNameItalian=Some("bronzo")
      rejectState("Nome"){new BaseValidationManager()
        .requireDiscovery21Ready(c)}
    }
    check("validator rifiuta ID storico falsificato"){
      val c=ready();c.legacyCutletNameCanonicalId=Some(1)
      rejectState("ID"){new BaseValidationManager()
        .requireDiscovery21Ready(c)}
    }
    check("validator rifiuta slot storico falsificato"){
      val c=ready();c.legacyCutletNameSlot=Some(0)
      rejectState("Slot"){new BaseValidationManager()
        .requireDiscovery21Ready(c)}
    }
    check("validator rifiuta versione congelata diversa"){
      val c=ready();c.legacyCutletNameCatalogVersion=Some("wrong")
      rejectState("Versione"){new BaseValidationManager()
        .requireDiscovery21Ready(c)}
    }
    check("validator rifiuta snapshot falsificata"){
      val c=ready();c.cutletNameDayOffset=Some(2)
      rejectState("Snapshot"){new BaseValidationManager()
        .requireDiscovery21Ready(c)}
    }
    check("validator rifiuta una trace extra"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager()
        .requireDiscovery21Ready(c)}
    }
    check("validator rifiuta uno stato alterato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Stato"){new BaseValidationManager()
        .requireDiscovery21Ready(c)}
    }
    check("handler rifiuta il salto del bootstrap"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_21_DAY_INDEXED_CUTLET_NAME"
      c.cutletNameGateGaps=Some(Six)
      c.cutletNamePartition=Some(Parts)
      c.cutletCanonicalNameIndices=Some(Names)
      c.cutletNameDayOffset=Some(1)
      rejectState("Bootstrap"){new Discovery21DayIndexedCutletNameHandler(
        new BaseMetricsShell).handle(c)}
    }
    check("nessun oracolo di test nel codice produttivo"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val source=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!source.contains("NormativeOracle"),"Oracolo test-only")
    }
    check("Stage41 rimane certificato, PATCH21 assente"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains(
        "STAGE_41_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_56_PASS_0_FAIL"),
        "Stage41")
      truth(st.contains("CURRENT_STAGE=42"),"Stage42")
      truth(st.contains("LAST_COMPLETED_STAGE=41"),"Ultimo")
      val walk=Files.walk(root().resolve("src/main/scala"))
      val source=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!source.contains("def cutletNamePatch("),"PATCH21 prematura")
    }
    // Le tre divergenze di equivalenza sono DELIBERATE.
    Vector(
      ("DAY1_CUTLET1",Six,Parts,Names,1),
      ("DAY42_CUTLET2",Six,Parts,Names,42),
      ("DAY672_CUTLET17",Seventeen,Parts17,Names17,672)
    ).foreach {case (tag,g,p,n,d) =>
      check("equivalenza normativa nome "+tag){
        val r=new BaseMonsterManager().discover21DayIndexedCutletName(
          Huge,-Huge,g,p,n,d)
        eqv(r.legacyItalianName,normative(g,p,n,d),
          "Nome da giorno anziché cotoletta: "+tag)
      }
    }
    println("\nRISULTATO STADIO 42: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
