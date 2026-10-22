package pastafari

import pastafari.monster._
import pastafari.catalog.SourceLanguageCatalog
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH21: si indicizza il nome con la cotoletta effettiva. */
object Stage43Tests {
  private var passed=0
  private var failed=0
  private val G6=Vector.fill(6)(42)
  private val P6=Vector.fill(6)(1)
  private val I6=(1 to 6).toVector
  private val G17=Vector.fill(17)(42)
  private val P17=Vector.fill(17)(1)
  private val I17=(1 to 17).toVector
  private val Nine=Vector(42,43,44,45,46,47,48,49,50)
  private val NineParts=Vector(2,1,1,1,1,3)
  private val N6=Vector(17,9,1,7,6,13)
  // Fixture italiana test-only, non consultata dal codice di produzione.
  private val FrozenCutletNames=Vector(
    "bronzo",
    "volpe",
    "rene",
    "Lagash",
    "pensiero",
    "quattro parti di nove",
    "Palgurash",
    "cipero",
    "grappolo",
    "scorpione",
    "cenere",
    "frumento",
    "fiume",
    "risata",
    "Akkad",
    "corno",
    "il vaso vuoto"
  )
  private val Huge=(BigInt(1)<<16384)+43

  private def check(label:String)(run: => Unit):Unit={
    try {run;passed+=1;println("PASS — "+label)}
    catch{case e:Throwable=>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](x:A,y:A,label:String):Unit={
    if(x!=y)throw new AssertionError(
      label+": atteso="+y+", ottenuto="+x)
  }
  private def truth(x:Boolean,label:String):Unit={
    if(!x)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(run: => Unit):Unit={
    var caught=false
    try run catch{case _:IllegalArgumentException=>caught=true}
    truth(caught,label)
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var caught=false
    try run catch{case _:IllegalStateException=>caught=true}
    truth(caught,label)
  }
  private def patch(
    g:Vector[Int]=G6,p:Vector[Int]=P6,
    ids:Vector[Int]=I6,d:Int=1
  ):Patch21DayIndexedCutletNameResult =
    Patch21DayIndexedCutletNameWrapper.cutletNamePatch(g,p,ids,d)

  // Oracolo separato: distribuisce ogni intervallo di porta nella
  // cotoletta del gruppo e confronta l'offset con le soglie assolute.
  private def oracle(
    g:Vector[Int],p:Vector[Int],ids:Vector[Int],d:Int
  ):(Int,String)={
    var gate=0
    var day=0
    for((size,i)<-p.zipWithIndex) {
      var length=0
      var j=0
      while(j<size) {
        length+=g(gate)
        gate+=1
        j+=1
      }
      if(d>=day && d<day+length) {
        val id=ids(i)
        val name=FrozenCutletNames(id-1)
        return (id,name)
      }
      day+=length
    }
    throw new AssertionError("Oracolo: giorno privo di cotoletta")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir"))
      .toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) &&
       p.getParent!=null)p=p.getParent
    p
  }
  private def ready(
    g:Vector[Int]=G6,p:Vector[Int]=P6,
    ids:Vector[Int]=I6,d:Int=1
  ):BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_21_DAY_INDEXED_CUTLET_NAME"
    c.cutletNameGateGaps=Some(g)
    c.cutletNamePartition=Some(p)
    c.cutletCanonicalNameIndices=Some(ids)
    c.cutletNameDayOffset=Some(d)
    val metrics=new BaseMetricsShell
    new Discovery21DayIndexedCutletNameHandler(metrics).handle(c)
    new BaseValidationManager().requireDiscovery21Ready(c)
    c.phase="PATCH_21_DAY_INDEXED_CUTLET_NAME"
    new Patch21DayIndexedCutletNameHandler(metrics).handle(c)
    c
  }

  def main(args:Array[String]):Unit={
    check("il catalogo congela 17 nomi canonici"){
      eqv(SourceLanguageCatalog.Cutlets.map(_.canonicalIndex),
        I17,"Catalogo")
      eqv(SourceLanguageCatalog.Cutlets.map(_.italian),
        FrozenCutletNames,"Testi italiani congelati")
    }
    check("giorno zero nomina la prima cotoletta"){
      val r=patch(d=0)
      eqv((r.correctedCanonicalNameId,r.correctedItalianName),
        (1,"bronzo"),"Primo")
    }
    check("giorno 1 nomina ancora la prima cotoletta"){
      val r=patch()
      eqv((r.correctedCanonicalNameId,r.correctedItalianName),
        (1,"bronzo"),"Primo")
    }
    check("giorno 41 conclude la prima cotoletta"){
      eqv(patch(d=41).correctedCanonicalNameId,1,"Fine")
    }
    check("giorno 42 apre la seconda cotoletta"){
      val r=patch(d=42)
      eqv((r.correctedCanonicalNameId,r.correctedItalianName),
        (2,"volpe"),"Secondo")
    }
    check("giorno 43 appartiene ancora alla seconda"){
      eqv(patch(d=43).correctedCanonicalNameId,2,"Continuazione")
    }
    check("giorno 84 apre la terza cotoletta"){
      eqv(patch(d=84).correctedCanonicalNameId,3,"Terzo")
    }
    check("giorno 210 apre la sesta cotoletta"){
      eqv(patch(d=210).correctedCanonicalNameId,6,"Sesto")
    }
    check("ultimo giorno 251 è nella sesta cotoletta"){
      eqv(patch(d=251).correctedCanonicalNameId,6,"Ultimo")
    }
    check("tutti i confini iniziali e finali della famiglia di sei"){
      for(i<-1 until 6) {
        eqv(patch(d=i*42).correctedCanonicalNameId,i+1,"Apertura "+i)
        eqv(patch(d=i*42-1).correctedCanonicalNameId,i,"Chiusura "+i)
      }
    }
    check("tutti i confini di 17 cotolette"){
      for(i<-1 until 17) {
        eqv(patch(G17,P17,I17,i*42).correctedCanonicalNameId,
          i+1,"Apertura "+i)
        eqv(patch(G17,P17,I17,i*42-1).correctedCanonicalNameId,
          i,"Chiusura "+i)
      }
    }
    check("ultimo giorno della 17a cotoletta"){
      eqv(patch(G17,P17,I17,713).correctedCanonicalNameId,17,"Ultimo")
    }
    check("primo nome con permuta selezionata"){
      val r=patch(G6,P6,N6,1)
      eqv((r.correctedCanonicalNameId,r.correctedItalianName),
        (17,"il vaso vuoto"),"Permuta")
    }
    check("nomi permutati all'inizio della seconda cotoletta"){
      eqv(patch(G6,P6,N6,42).correctedCanonicalNameId,9,"Secondo")
    }
    check("nome corretto in partizione su nove intervalli"){
      val g=Nine;val p=NineParts
      eqv(patch(g,p,N6,85).correctedCanonicalNameId,9,"Seconda")
    }
    check("durata massima 5778 ha ultimo nome della sesta"){
      eqv(patch(Vector.fill(6)(963),P6,I6,5777)
        .correctedCanonicalNameId,6,"Massimo")
    }
    check("ogni giorno della durata minima 252 concorda"){
      for(d<-0 until 252){
        val r=patch(d=d)
        eqv((r.correctedCanonicalNameId,r.correctedItalianName),
          oracle(G6,P6,I6,d),"Giorno "+d)
      }
    }
    check("ogni giorno delle 17 cotolette 714 concorda"){
      for(d<-0 until 714) {
        val r=patch(G17,P17,I17,d)
        eqv((r.correctedCanonicalNameId,r.correctedItalianName),
          oracle(G17,P17,I17,d),"Giorno "+d)
      }
    }
    check("ogni giorno della durata massima 5778 concorda"){
      val g=Vector.fill(6)(963)
      for(d<-0 until 5778) {
        val r=patch(g,P6,I6,d)
        eqv((r.correctedCanonicalNameId,r.correctedItalianName),
          oracle(g,P6,I6,d),"Giorno "+d)
      }
    }
    check("ogni giorno della partizione plurivarchi concorda"){
      for(d<-0 until Nine.sum) {
        val r=patch(Nine,NineParts,N6,d)
        eqv((r.correctedCanonicalNameId,r.correctedItalianName),
          oracle(Nine,NineParts,N6,d),"Giorno "+d)
      }
    }
    check("il giorno 1 conserva una cicatrice distinta"){
      val r=patch()
      eqv((r.historical.legacyCanonicalNameId,
        r.historical.legacyItalianName),(2,"volpe"),"Storico")
      eqv((r.correctedCanonicalNameId,r.correctedItalianName),
        (1,"bronzo"),"Norma")
    }
    check("la seconda cotoletta conserva il nome storico difforme"){
      val r=patch(d=42)
      eqv(r.historical.legacyCanonicalNameId,1,"Storico")
      eqv(r.correctedCanonicalNameId,2,"Corretto")
    }
    check("il primo giorno della diciassettesima resta storico"){
      val r=patch(G17,P17,I17,672)
      eqv(r.historical.legacyCanonicalNameId,9,"Storico")
      eqv(r.correctedCanonicalNameId,17,"Corretto")
    }
    check("il wrapper chiama il vero adapter storico"){
      for((g,p,ids,d)<-Vector(
        (G6,P6,I6,1),(G6,P6,I6,42),
        (G17,P17,I17,672),(Nine,NineParts,N6,85))) {
        eqv(patch(g,p,ids,d).historical,
          LegacyDayIndexedCutletNameAdapter.oldDayIndexedCutletName(
            g,p,ids,d),"Cicatrice")
      }
    }
    check("4096 vettori deterministici e permutazioni"){
      val rng=new Random(43102026L)
      for(i<-1 to 4096){
        val n=6+rng.nextInt(12)
        val extras=rng.nextInt(11)
        val focus=rng.nextInt(n)
        val p=Vector.tabulate(n)(i=>if(i==focus)1+extras else 1)
        val g=Vector.fill(n+extras)(42+rng.nextInt(120))
        val ids=rng.shuffle(I17).take(n).toVector
        val d=rng.nextInt(g.sum)
        val actual=patch(g,p,ids,d)
        eqv((actual.correctedCanonicalNameId,actual.correctedItalianName),
          oracle(g,p,ids,d),"Campione "+i)
        eqv(actual.historical.legacyCanonicalNameId,
          ids(d%n),"Vecchio "+i)
      }
    }
    check("4096 richieste su due manager isolati"){
      val rng=new Random(43202026L)
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      for(i<-1 to 4096){
        val n=6+rng.nextInt(12)
        val g=Vector.fill(n)(42+rng.nextInt(180))
        val p=Vector.fill(n)(1)
        val ids=rng.shuffle(I17).take(n).toVector
        val d=rng.nextInt(g.sum)
        val m=if(i%2==0)a else b
        val r=m.patch21DayIndexedCutletName(i,-Huge,g,p,ids,d)
        eqv((r.correctedCanonicalNameId,r.correctedItalianName),
          oracle(g,p,ids,d),"Manager "+i)
      }
      eqv(a.metricsSnapshot("patch21.cutlet.name.calls"),
        BigInt(2048),"A")
      eqv(b.metricsSnapshot("patch21.cutlet.name.calls"),
        BigInt(2048),"B")
    }
    check("manager conserva BigInt oltre 128 bit"){
      val r=new BaseMonsterManager().patch21DayIndexedCutletName(
        Huge,-Huge,G6,P6,I6,1)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Bersaglio")
    }
    check("manager pubblica trace e flag di due fasi"){
      val r=new BaseMonsterManager().patch21DayIndexedCutletName(
        1,2,G6,P6,I6,1)
      eqv(r.trace,Vector("BOOT","DISCOVERY_21_DAY_INDEXED_CUTLET_NAME",
        "PATCH_21_DAY_INDEXED_CUTLET_NAME"),"Trace")
      eqv(r.status,"PATCH_21_READY","Stato")
      truth(r.patchApplied,"Flag")
    }
    check("metriche contano una chiamata per ogni fase"){
      val m=new BaseMonsterManager
      m.patch21DayIndexedCutletName(1,2,G6,P6,I6,1)
      eqv(m.metricsSnapshot("discovery21.cutlet.name.calls"),
        BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch21.cutlet.name.calls"),
        BigInt(1),"Patch")
    }
    check("report già emesso immutabile dopo riuso manager"){
      val m=new BaseMonsterManager
      val a=m.patch21DayIndexedCutletName(1,2,G6,P6,I6,1)
      val old=a.copy()
      m.patch21DayIndexedCutletName(3,4,G6,P6,I6,42)
      eqv(a,old,"Report")
    }
    check("rifiuta cinque cotolette"){
      rejectArg("Cinque"){patch(G6,Vector(1,1,1,1,2),I6,1)}
    }
    check("rifiuta 18 cotolette"){
      rejectArg("Diciotto"){patch(Vector.fill(18)(42),
        Vector.fill(18)(1),I17,1)}
    }
    check("rifiuta nomi duplicati"){
      rejectArg("Duplicati"){patch(ids=Vector(1,1,2,3,4,5))}
    }
    check("rifiuta ID canonici fuori catalogo"){
      rejectArg("ID"){patch(ids=Vector(1,2,3,4,5,18))}
    }
    check("rifiuta intervallo 41"){
      rejectArg("Porta"){patch(g=Vector(41,42,42,42,42,43))}
    }
    check("rifiuta intervallo 964"){
      rejectArg("Porta"){patch(g=Vector(964,42,42,42,42,42))}
    }
    check("rifiuta partizione incompleta"){
      rejectArg("Partizione"){patch(p=Vector(1,1,1,1,1,2))}
    }
    check("rifiuta giorno negativo"){
      rejectArg("Negativo"){patch(d = -1)}
    }
    check("rifiuta fine anno esclusiva"){
      rejectArg("Fine"){patch(d=252)}
    }
    check("validator accetta lo stato corretto"){
      new BaseValidationManager().requirePatch21Ready(ready())
    }
    check("validator rifiuta ID patch falsificato"){
      val c=ready();c.patchedCutletNameId=Some(2)
      rejectState("ID"){new BaseValidationManager().requirePatch21Ready(c)}
    }
    check("validator rifiuta nome patch falsificato"){
      val c=ready();c.patchedCutletNameItalian=Some("volpe")
      rejectState("Nome"){new BaseValidationManager().requirePatch21Ready(c)}
    }
    check("validator rifiuta il nome storico falsificato"){
      val c=ready();c.legacyCutletNameItalian=Some("bronzo")
      rejectState("Legacy"){new BaseValidationManager().requirePatch21Ready(c)}
    }
    check("validator rifiuta lo slot storico falsificato"){
      val c=ready();c.legacyCutletNameSlot=Some(0)
      rejectState("Slot"){new BaseValidationManager().requirePatch21Ready(c)}
    }
    check("validator rifiuta snapshot alterata"){
      val c=ready();c.cutletNameDayOffset=Some(42)
      rejectState("Snapshot"){new BaseValidationManager().requirePatch21Ready(c)}
    }
    check("validator rifiuta catalogo versione alterata"){
      val c=ready();c.legacyCutletNameCatalogVersion=Some("X")
      rejectState("Versione"){new BaseValidationManager().requirePatch21Ready(c)}
    }
    check("validator rifiuta trace aggiuntiva"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager().requirePatch21Ready(c)}
    }
    check("validator rifiuta status alterato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Status"){new BaseValidationManager().requirePatch21Ready(c)}
    }
    check("validator rifiuta flag rimosso"){
      val c=ready();c.patch21Applied=false
      rejectState("Flag"){new BaseValidationManager().requirePatch21Ready(c)}
    }
    check("handler respinge il salto della discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_21_DAY_INDEXED_CUTLET_NAME"
      c.cutletNameGateGaps=Some(G6);c.cutletNamePartition=Some(P6)
      c.cutletCanonicalNameIndices=Some(I6)
      c.cutletNameDayOffset=Some(1)
      rejectState("Bootstrap"){new Patch21DayIndexedCutletNameHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patchedCutletNameId.isEmpty,"Nessun dato pubblicato")
    }
    check("handler respinge manomissione prima della pubblicazione"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_21_DAY_INDEXED_CUTLET_NAME"
      c.cutletNameGateGaps=Some(G6);c.cutletNamePartition=Some(P6)
      c.cutletCanonicalNameIndices=Some(I6)
      c.cutletNameDayOffset=Some(1)
      new Discovery21DayIndexedCutletNameHandler(
        new BaseMetricsShell).handle(c)
      c.phase="PATCH_21_DAY_INDEXED_CUTLET_NAME"
      c.cutletNameDayOffset=Some(42)
      rejectState("Snapshot"){new Patch21DayIndexedCutletNameHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patchedCutletNameId.isEmpty && !c.patch21Applied,
        "Pubblicazione atomica")
    }
    check("DISCOVERY21 rimane osservabile indipendentemente"){
      val r=new BaseMonsterManager().discover21DayIndexedCutletName(
        1,2,G6,P6,I6,1)
      eqv(r.legacyItalianName,"volpe","Legacy")
    }
    check("PATCH20 corregge ancora la frontiera della cotoletta"){
      val r=new BaseMonsterManager().patch20CutletOpenBoundary(
        1,2,G6,P6,42)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),
        (2,1),"PATCH20")
    }
    check("il codice di produzione non dipende dall'oracolo test"){
      val w=Files.walk(root().resolve("src/main/scala"))
      val text=try w.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally w.close()
      truth(!text.contains("NormativeOracle"),"Test-only")
      truth(text.contains("def cutletNamePatch("),"PATCH21")
    }
    check("Stage42 conserva la firma RED corretta"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains(
        "STAGE_42_NATIVE_VERIFICATION=PASS_EXPECTED_RED_43_PASS_3_FAIL"),
        "Stage42")
      val curr=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      truth(curr>=43,"Stage43")
    }
    println("\nRISULTATO STADIO 43: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
