package pastafari

import pastafari.monster._
import pastafari.catalog.SourceLanguageCatalog
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH20: inizio inclusivo e fine esclusiva per ogni cotoletta. */
object Stage41Tests {
  private var passed=0
  private var failed=0
  private val Six=Vector.fill(6)(42)
  private val SixParts=Vector.fill(6)(1)
  private val Seventeen=Vector.fill(17)(42)
  private val SeventeenParts=Vector.fill(17)(1)
  private val Nine=Vector(42,43,44,45,46,47,48,49,50)
  private val NineParts=Vector(2,1,1,1,1,3)
  private val Huge=(BigInt(1)<<16384)+41

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
    truth(rejected,label+": input illecito accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var rejected=false
    try run catch {case _:IllegalStateException=>rejected=true}
    truth(rejected,label+": stato alterato accettato")
  }
  private def patched(
    gaps:Vector[Int]=Six,parts:Vector[Int]=SixParts,day:Int=42
  ):Patch20CutletOpenBoundaryResult =
    Patch20CutletOpenBoundaryWrapper.cutletBoundaryPatch(gaps,parts,day)
  private def manager(
    gaps:Vector[Int]=Six,parts:Vector[Int]=SixParts,day:Int=42
  ):Patch20CutletOpenBoundaryReport =
    new BaseMonsterManager().patch20CutletOpenBoundary(
      Huge,-Huge,gaps,parts,day)

  // Oracolo test-only: accumula durate delle cotolette senza
  // utilizzare start-offset, adapter, wrapper o manager di produzione.
  private def oracle(
    gaps:Vector[Int],parts:Vector[Int],day:Int
  ):(Int,Int)={
    var gate=0
    var start=0
    for((size,i)<-parts.zipWithIndex){
      var duration=0
      var k=0
      while(k<size){duration+=gaps(gate);gate+=1;k+=1}
      if(day>=start && day<start+duration)
        return (i+1,day-start+1)
      start+=duration
    }
    throw new AssertionError("Giorno non contenuto")
  }
  private def ready(
    gaps:Vector[Int]=Six,parts:Vector[Int]=SixParts,day:Int=42
  ):BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_20_CUTLET_OPEN_BOUNDARY"
    c.cutletGateGaps=Some(gaps)
    c.cutletGatePartition=Some(parts)
    c.cutletDayOffset=Some(day)
    val m=new BaseMetricsShell
    new Discovery20CutletOpenBoundaryHandler(m).handle(c)
    new BaseValidationManager().requireDiscovery20Ready(c)
    c.phase="PATCH_20_CUTLET_OPEN_BOUNDARY"
    new Patch20CutletOpenBoundaryHandler(m).handle(c)
    c
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }

  def main(args:Array[String]):Unit={
    check("il catalogo delle cotolette mantiene i 17 ID"){
      eqv(SourceLanguageCatalog.Cutlets.map(_.canonicalIndex),
        (1 to 17).toVector,"Indici")
    }
    check("giorno zero apre la prima cotoletta"){
      val r=patched(Six,SixParts,0)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(1,1),"Inizio")
    }
    check("giorno 41 chiude la prima cotoletta"){
      val r=patched(Six,SixParts,41)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(1,42),"Fine")
    }
    check("giorno 42 apre la seconda cotoletta"){
      val r=patched()
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(2,1),"Soglia")
    }
    check("giorno 43 continua la seconda cotoletta"){
      val r=patched(Six,SixParts,43)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(2,2),"Secondo")
    }
    check("giorno 84 apre la terza cotoletta"){
      val r=patched(Six,SixParts,84)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(3,1),"Terzo")
    }
    check("giorno 210 apre la sesta cotoletta"){
      val r=patched(Six,SixParts,210)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(6,1),"Sesto")
    }
    check("giorno 251 chiude l'anno"){
      val r=patched(Six,SixParts,251)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(6,42),"Ultimo")
    }
    check("tutti gli inizi di sei cotolette sono inclusivi"){
      for(i<-1 until 6){
        val r=patched(Six,SixParts,i*42)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),(i+1,1),
          "Inizio "+i)
      }
    }
    check("tutti i giorni che precedono un confine appartengono alla precedente"){
      for(i<-1 until 6){
        val r=patched(Six,SixParts,i*42-1)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),(i,42),
          "Fine "+i)
      }
    }
    check("17 cotolette hanno 16 confini precisi"){
      for(i<-1 until 17){
        val r=patched(Seventeen,SeventeenParts,i*42)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),(i+1,1),
          "Confine "+i)
      }
    }
    check("l'ultimo giorno di 17 cotolette appartiene alla diciassettesima"){
      val r=patched(Seventeen,SeventeenParts,713)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(17,42),"Ultimo")
    }
    check("una cotoletta può attraversare più intervalli di porte"){
      eqv((patched(Nine,NineParts,84).correctedCutletId,
        patched(Nine,NineParts,84).correctedDayInCutlet),
        (1,85),"Primo gruppo")
    }
    check("il primo giorno dopo due intervalli passa alla seconda"){
      val r=patched(Nine,NineParts,85)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(2,1),"Soglia")
    }
    check("la sesta cotoletta copre gli ultimi tre intervalli"){
      val r=patched(Nine,NineParts,Nine.sum-1)
      eqv((r.correctedCutletId,r.correctedDayInCutlet),
        oracle(Nine,NineParts,Nine.sum-1),"Gruppo")
    }
    check("tutti i 252 giorni minimi concordano con l'oracolo"){
      for(day<-Six.indices.flatMap(i=>0 until Six(i))){
        val actual=patched(Six,SixParts,day)
        eqv((actual.correctedCutletId,actual.correctedDayInCutlet),
          oracle(Six,SixParts,day),"Giorno "+day)
      }
    }
    check("tutti i 714 giorni delle 17 cotolette concordano"){
      for(day<-0 until Seventeen.sum){
        val r=patched(Seventeen,SeventeenParts,day)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),
          oracle(Seventeen,SeventeenParts,day),"Giorno "+day)
      }
    }
    check("tutti i 5778 giorni massimi concordano"){
      val gaps=Vector.fill(6)(963)
      for(day<-0 until 5778){
        val r=patched(gaps,SixParts,day)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),
          oracle(gaps,SixParts,day),"Giorno "+day)
      }
    }
    check("tutti i giorni della partizione multipla concordano"){
      for(day<-0 until Nine.sum){
        val r=patched(Nine,NineParts,day)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),
          oracle(Nine,NineParts,day),"Giorno "+day)
      }
    }
    check("la vecchia cicatrice resta conservata al primo confine"){
      val r=patched()
      eqv((r.historical.legacyCutletId,r.historical.legacyDayInCutlet),
        (1,43),"Legacy")
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(2,1),"Corretto")
    }
    check("la cicatrice storica resta al confine della 17ª cotoletta"){
      val r=patched(Seventeen,SeventeenParts,672)
      eqv((r.historical.legacyCutletId,r.historical.legacyDayInCutlet),
        (16,43),"Legacy")
      eqv((r.correctedCutletId,r.correctedDayInCutlet),(17,1),"Corretto")
    }
    check("fuori dai confini storico e corretto coincidono"){
      for(day<-0 until Six.sum if day%42!=0){
        val r=patched(Six,SixParts,day)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),
          (r.historical.legacyCutletId,r.historical.legacyDayInCutlet),
          "Uguale "+day)
      }
    }
    check("il wrapper contiene il risultato storico effettivo"){
      for((g,p,d)<-Vector((Six,SixParts,42),
        (Nine,NineParts,85),(Seventeen,SeventeenParts,672))){
        eqv(patched(g,p,d).historical,
          LegacyCutletOpenBoundaryAdapter.oldCutletOpenBoundary(g,p,d),
          "Adapter")
      }
    }
    check("il risultato non modifica gli input originali"){
      val g=Nine;val p=NineParts
      val r=patched(g,p,85)
      eqv(r.historical.gateGaps,g,"Gaps")
      eqv(r.historical.cutletPartition,p,"Partizione")
      eqv(r.historical.dayOffset,85,"Offset")
    }
    check("4096 partizioni deterministiche e offset casuali"){
      val rng=new Random(41102026L)
      for(i<-1 to 4096){
        val n=6+rng.nextInt(12)
        val gaps=Vector.fill(n)(42+rng.nextInt(200))
        val parts=Vector.fill(n)(1)
        val day=rng.nextInt(gaps.sum)
        val r=patched(gaps,parts,day)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),
          oracle(gaps,parts,day),"Oracolo "+i)
        eqv(r.historical.legacyCutletId,
          1+r.historical.cutletStartOffsets.tail.count(_<day),"Legacy "+i)
      }
    }
    check("4096 partizioni non contaminano due manager"){
      val rng=new Random(41202026L)
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      for(i<-1 to 4096){
        val n=6+rng.nextInt(12)
        val gaps=Vector.fill(n)(42+rng.nextInt(200))
        val parts=Vector.fill(n)(1)
        val day=rng.nextInt(gaps.sum)
        val m=if(i%2==0)a else b
        val r=m.patch20CutletOpenBoundary(i,-Huge,gaps,parts,day)
        eqv((r.correctedCutletId,r.correctedDayInCutlet),
          oracle(gaps,parts,day),"Manager "+i)
      }
      eqv(a.metricsSnapshot("patch20.cutlet.boundary.calls"),
        BigInt(2048),"A")
      eqv(b.metricsSnapshot("patch20.cutlet.boundary.calls"),
        BigInt(2048),"B")
    }
    check("date BigInt oltre 128 bit conservate nel report"){
      val r=manager()
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Target")
    }
    check("il manager esegue BOOT Discovery20 e PATCH20 nello stesso contesto"){
      val r=manager()
      eqv(r.phase,"PATCH_20_CUTLET_OPEN_BOUNDARY","Fase")
      eqv(r.status,"PATCH_20_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_20_CUTLET_OPEN_BOUNDARY",
        "PATCH_20_CUTLET_OPEN_BOUNDARY"),"Trace")
      truth(r.patchApplied,"Flag")
    }
    check("metriche osservazionali indicano una sola esecuzione per fase"){
      val m=new BaseMonsterManager
      m.patch20CutletOpenBoundary(1,2,Six,SixParts,42)
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery20.cutlet.boundary.calls"),
        BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch20.cutlet.boundary.calls"),
        BigInt(1),"Patch")
    }
    check("due manager isolano contatori e report"){
      val a=new BaseMonsterManager;val b=new BaseMonsterManager
      val ra=a.patch20CutletOpenBoundary(1,2,Six,SixParts,42)
      val rb=b.patch20CutletOpenBoundary(3,4,Nine,NineParts,85)
      eqv(a.metricsSnapshot("patch20.cutlet.boundary.calls"),
        BigInt(1),"A")
      eqv(b.metricsSnapshot("patch20.cutlet.boundary.calls"),
        BigInt(1),"B")
      eqv(ra.correctedCutletId,2,"A output")
      eqv(rb.correctedCutletId,2,"B output")
    }
    check("riutilizzare il manager non altera il primo report"){
      val m=new BaseMonsterManager
      val first=m.patch20CutletOpenBoundary(1,2,Six,SixParts,42)
      val before=first.copy()
      m.patch20CutletOpenBoundary(3,4,Nine,NineParts,85)
      eqv(first,before,"Immutabilità")
    }
    check("rifiuta un anno più corto di 252"){
      rejectArg("Corto"){patched(Vector.fill(6)(41),SixParts,2)}
    }
    check("rifiuta un anno più lungo di 5778"){
      rejectArg("Lungo"){patched(Vector.fill(7)(963),
        Vector(1,1,1,1,1,2),2)}
    }
    check("rifiuta cinque cotolette"){
      rejectArg("Cinque"){patched(Six,Vector(1,1,1,1,2),42)}
    }
    check("rifiuta diciotto cotolette"){
      rejectArg("Diciotto"){patched(Vector.fill(18)(42),
        Vector.fill(18)(1),42)}
    }
    check("rifiuta partizione zero"){
      rejectArg("Zero"){patched(Six,Vector(0,1,1,1,1,2),42)}
    }
    check("rifiuta partizione incompleta"){
      rejectArg("Parziale"){patched(Six,Vector(1,1,1,1,1,2),42)}
    }
    check("rifiuta gate gap 41"){
      rejectArg("Minimo"){patched(Vector(41,42,42,42,42,43),
        SixParts,42)}
    }
    check("rifiuta gate gap 964"){
      rejectArg("Massimo"){patched(Vector(964,42,42,42,42,42),
        SixParts,42)}
    }
    check("rifiuta offset negativo"){
      rejectArg("Negativo"){patched(Six,SixParts,-1)}
    }
    check("rifiuta offset alla fine esatta"){
      rejectArg("Fine"){patched(Six,SixParts,252)}
    }
    check("il validator accetta uno stato completo"){
      new BaseValidationManager().requirePatch20Ready(ready())
    }
    check("il validator rifiuta ID di cotoletta falsificato"){
      val c=ready();c.patchedCutletId=Some(1)
      rejectState("ID"){new BaseValidationManager().requirePatch20Ready(c)}
    }
    check("il validator rifiuta giorno corretto falsificato"){
      val c=ready();c.patchedDayInCutlet=Some(2)
      rejectState("Giorno"){new BaseValidationManager().requirePatch20Ready(c)}
    }
    check("il validator rifiuta la cicatrice storica falsificata"){
      val c=ready();c.legacyCutletId=Some(2)
      rejectState("Legacy"){new BaseValidationManager().requirePatch20Ready(c)}
    }
    check("il validator rifiuta uno snapshot falsificato"){
      val c=ready();c.cutletDayOffset=Some(43)
      rejectState("Snapshot"){new BaseValidationManager().requirePatch20Ready(c)}
    }
    check("il validator rifiuta uno start offset falsificato"){
      val c=ready();c.legacyCutletStartOffsets=Some(Vector(0,1,2))
      rejectState("Starts"){new BaseValidationManager().requirePatch20Ready(c)}
    }
    check("il validator rifiuta trace alterata"){
      val c=ready();c.branchTrace.append("EXTRA")
      rejectState("Trace"){new BaseValidationManager().requirePatch20Ready(c)}
    }
    check("il validator rifiuta lo status alterato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Status"){new BaseValidationManager().requirePatch20Ready(c)}
    }
    check("il validator rifiuta il flag rimosso"){
      val c=ready();c.patch20Applied=false
      rejectState("Flag"){new BaseValidationManager().requirePatch20Ready(c)}
    }
    check("l'handler non consente di saltare la discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_20_CUTLET_OPEN_BOUNDARY"
      c.cutletGateGaps=Some(Six);c.cutletGatePartition=Some(SixParts)
      c.cutletDayOffset=Some(42)
      rejectState("Bootstrap"){new Patch20CutletOpenBoundaryHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patchedCutletId.isEmpty,"Pubblicazione atomica")
    }
    check("handler non pubblica output dopo manomissione"){
      val c=ready()
      c.phase="DISCOVERY_20_CUTLET_OPEN_BOUNDARY"
      c.status="LEGACY_CUTLET_BOUNDARY_READY"
      c.branchTrace.remove(2)
      c.cutletDayOffset=Some(43)
      rejectState("Snapshot"){new Patch20CutletOpenBoundaryHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.patchedCutletId.nonEmpty,"Report iniziale preservato")
    }
    check("la vecchia discovery rimane osservabile in isolamento"){
      val r=new BaseMonsterManager().discover20CutletOpenBoundary(
        1,2,Six,SixParts,42)
      eqv((r.legacyCutletId,r.legacyDayInCutlet),(1,43),"Cicatrice")
    }
    check("PATCH19 continua a scegliere il nome italiano corretto"){
      val w=Vector.fill(84)(1)++Vector.fill(84)(2)++Vector.fill(84)(3)
      val r=new BaseMonsterManager().patch19DayIndexedMonthName(
        1,2,w,Vector(1,2,3),1)
      eqv(r.correctedItalianMonthName,"argilla","PATCH19")
      eqv(r.legacyItalianMonthName,"melagrana","DISCOVERY19")
    }
    check("nessun oracolo dei test nel codice di produzione"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val source=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!source.contains("NormativeOracle"),"Oracolo test-only")
      truth(source.contains("def cutletBoundaryPatch("),"PATCH20 presente")
    }
    check("lo storico Stage40 rimane certificato"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains(
        "STAGE_40_NATIVE_VERIFICATION=PASS_EXPECTED_RED_44_PASS_3_FAIL"),
        "Stage40 RED")
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      truth(current>=41,"Stage41")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .get.split("=",2)(1).toInt
      truth(done>=40&&done<=current,"Ultimo stage")
    }
    println("\nRISULTATO STADIO 41: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
