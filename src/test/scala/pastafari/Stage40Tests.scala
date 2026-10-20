package pastafari

import pastafari.monster._
import pastafari.catalog.SourceLanguageCatalog
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY20: il giorno iniziale appartiene alla nuova cotoletta. */
object Stage40Tests {
  private var passed=0
  private var failed=0
  private val Six=Vector.fill(6)(42)
  private val SixParts=Vector.fill(6)(1)
  private val Seventeen=Vector.fill(17)(42)
  private val SeventeenParts=Vector.fill(17)(1)
  private val Nine=Vector(42,43,44,45,46,47,48,49,50)
  private val NineParts=Vector(2,1,1,1,1,3)
  private val Huge=(BigInt(1)<<16384)+40

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

  private def old(
    gaps:Vector[Int]=Six,parts:Vector[Int]=SixParts,day:Int=42
  ):LegacyCutletOpenBoundaryResult =
    LegacyCutletOpenBoundaryAdapter.oldCutletOpenBoundary(gaps,parts,day)

  // Oracolo di sola prova. Somma le durate dei gruppi; la nuova
  // cotoletta prende possesso del giorno esattamente al suo inizio.
  private def normative(
    gaps:Vector[Int],parts:Vector[Int],day:Int
  ):(Int,Int)={
    var offset=0
    var pos=0
    for((count,index)<-parts.zipWithIndex) {
      val duration=gaps.slice(pos,pos+count).sum
      if(day>=offset && day<offset+duration)
        return (index+1,day-offset+1)
      offset+=duration
      pos+=count
    }
    throw new AssertionError("Giorno fuori partizione")
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
    new Discovery20CutletOpenBoundaryHandler(new BaseMetricsShell).handle(c)
    c
  }

  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }
  def main(args:Array[String]):Unit={
    check("sei intervalli minimi producono 252 giorni"){
      eqv(Six.sum,252,"Totale")
    }
    check("la partizione minima ha esattamente sei cotolette"){
      eqv(SixParts.length,6,"Numero")
    }
    check("17 intervalli producono un anno valido"){
      eqv(Seventeen.sum,714,"Totale")
    }
    check("il catalogo delle cotolette mantiene 17 nomi distinti"){
      eqv(SourceLanguageCatalog.Cutlets.length,17,"Numero")
      eqv(SourceLanguageCatalog.Cutlets.map(_.canonicalIndex),
        (1 to 17).toVector,"Indici")
    }
    check("giorno zero apre la prima cotoletta"){
      eqv(old(Six,SixParts,0).legacyCutletId,1,"ID")
      eqv(old(Six,SixParts,0).legacyDayInCutlet,1,"Giorno")
    }
    check("ultimo giorno della prima cotoletta resta valido"){
      val r=old(Six,SixParts,41)
      eqv(r.legacyCutletId,1,"ID")
      eqv(r.legacyDayInCutlet,42,"Giorno")
    }
    check("la vecchia soglia include il primo giorno nella vecchia cotoletta"){
      val r=old()
      eqv(r.legacyCutletId,1,"ID storico")
      eqv(r.legacyDayInCutlet,43,"Giorno storico")
    }
    check("la soglia seguente raggiunge finalmente la seconda cotoletta"){
      val r=old(Six,SixParts,43)
      eqv(r.legacyCutletId,2,"ID")
      eqv(r.legacyDayInCutlet,2,"Giorno storico")
    }
    check("gli inizi cumulativi di sei cotolette sono corretti"){
      eqv(old().cutletStartOffsets,
        Vector(0,42,84,126,168,210),"Inizi")
    }
    check("la partizione su nove intervalli produce inizi deterministici"){
      eqv(old(Nine,NineParts,85).cutletStartOffsets,
        Vector(0,85,129,174,220,267),"Inizi")
    }
    check("la scansione storica tiene invariati gli input"){
      val r=old(Nine,NineParts,85)
      eqv(r.gateGaps,Nine,"Gaps")
      eqv(r.cutletPartition,NineParts,"Partition")
      eqv(r.dayOffset,85,"Offset")
    }
    check("il vecchio difetto rimane al primo confine non uniforme"){
      val r=old(Nine,NineParts,85)
      eqv(r.legacyCutletId,1,"ID sbagliato")
      eqv(r.legacyDayInCutlet,86,"Giorno fuori cotoletta")
    }
    check("i confini interni sono tutti diagnosticati"){
      val starts=old().cutletStartOffsets.tail
      for(start<-starts){
        val r=old(Six,SixParts,start)
        eqv(r.legacyCutletId,starts.indexOf(start)+1,"Precedente")
      }
    }
    check("i giorni non al confine corrispondono alla norma"){
      val starts=old().cutletStartOffsets.toSet
      for(day<-0 until 252 if !starts.contains(day)){
        val r=old(Six,SixParts,day)
        eqv((r.legacyCutletId,r.legacyDayInCutlet),
          normative(Six,SixParts,day),"Giorno "+day)
      }
    }
    check("il modello storico è riproducibile su tutti i 252 giorni"){
      for(day<-0 until 252){
        val r=old(Six,SixParts,day)
        val starts=r.cutletStartOffsets
        val k=1+starts.tail.count(_<day)
        eqv(r.legacyCutletId,k,"Indice "+day)
        eqv(r.legacyDayInCutlet,day-starts(k-1)+1,"Giorno "+day)
      }
    }
    check("i 17 confini restano in ordine stretto"){
      val starts=old(Seventeen,SeventeenParts,0).cutletStartOffsets
      eqv(starts.length,17,"Numero")
      truth(starts.sliding(2).forall(v=>v.length<2 || v(1)>v(0)),
        "Ordine")
    }
    check("l'ultimo giorno di un anno di 17 cotolette resta valido"){
      val r=old(Seventeen,SeventeenParts,713)
      eqv(r.legacyCutletId,17,"ID")
      eqv(r.legacyDayInCutlet,42,"Giorno")
    }
    check("un solo intervallo puo' durare fino a 963 giorni"){
      val gaps=Vector(963,42,42,42,42,42)
      val r=old(gaps,SixParts,962)
      eqv(r.legacyCutletId,1,"ID")
      eqv(r.legacyDayInCutlet,963,"Giorno")
    }
    check("il totale annuo massimo 5778 è accettato"){
      val gaps=Vector.fill(6)(963)
      val r=old(gaps,SixParts,5777)
      eqv(r.legacyCutletId,6,"ID")
      eqv(r.legacyDayInCutlet,963,"Giorno")
    }
    check("il report del manager conserva BigInt oltre 128 bit"){
      val m=new BaseMonsterManager
      val r=m.discover20CutletOpenBoundary(Huge,-Huge,Six,SixParts,42)
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Target")
    }
    check("il manager conserva output e trace del difetto"){
      val m=new BaseMonsterManager
      val r=m.discover20CutletOpenBoundary(1,2,Six,SixParts,42)
      eqv(r.legacyCutletId,1,"ID")
      eqv(r.legacyDayInCutlet,43,"Giorno")
      eqv(r.phase,"DISCOVERY_20_CUTLET_OPEN_BOUNDARY","Fase")
      eqv(r.status,"LEGACY_CUTLET_BOUNDARY_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_20_CUTLET_OPEN_BOUNDARY"),
        "Trace")
      eqv(m.metricsSnapshot("discovery20.cutlet.boundary.calls"),
        BigInt(1),"Metriche")
    }
    check("due manager mantengono metriche isolate"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      a.discover20CutletOpenBoundary(1,2,Six,SixParts,42)
      b.discover20CutletOpenBoundary(3,4,Nine,NineParts,85)
      eqv(a.metricsSnapshot("discovery20.cutlet.boundary.calls"),
        BigInt(1),"A")
      eqv(b.metricsSnapshot("discovery20.cutlet.boundary.calls"),
        BigInt(1),"B")
    }
    check("report precedente non mutato dopo nuova richiesta"){
      val m=new BaseMonsterManager
      val first=m.discover20CutletOpenBoundary(1,2,Six,SixParts,42)
      val before=first.copy()
      m.discover20CutletOpenBoundary(3,4,Nine,NineParts,85)
      eqv(first,before,"Report")
    }
    check("1024 partizioni valide hanno la cicatrice deterministica"){
      val rng=new Random(40102026L)
      for(i<-1 to 1024){
        val n=6+rng.nextInt(12)
        val gaps=Vector.fill(n)(42+rng.nextInt(200))
        val parts=Vector.fill(n)(1)
        val day=rng.nextInt(gaps.sum)
        val r=old(gaps,parts,day)
        val starts=r.cutletStartOffsets
        val legacy=1+starts.tail.count(_<day)
        eqv(r.legacyCutletId,legacy,"ID "+i)
        eqv(r.legacyDayInCutlet,day-starts(legacy-1)+1,"Day "+i)
      }
    }
    check("rifiuta cinque cotolette"){
      rejectArg("Numero"){old(Vector.fill(6)(42),Vector(1,1,1,1,2),42)}
    }
    check("rifiuta diciotto cotolette"){
      rejectArg("Numero"){old(Vector.fill(18)(42),Vector.fill(18)(1),42)}
    }
    check("rifiuta intervallo inferiore a 42"){
      rejectArg("Gaps"){old(Vector(41,42,42,42,42,43),SixParts,42)}
    }
    check("rifiuta intervallo superiore a 963"){
      rejectArg("Gaps"){old(Vector(964,42,42,42,42,42),SixParts,42)}
    }
    check("rifiuta partizione con elemento zero"){
      rejectArg("Partition"){old(Six,Vector(0,1,1,1,1,2),42)}
    }
    check("rifiuta partizione che non copre i varchi"){
      rejectArg("Partition"){old(Six,Vector(1,1,1,1,1,2),42)}
    }
    check("rifiuta lunghezza annuale superiore a 5778"){
      rejectArg("Year"){old(Vector.fill(7)(963),Vector(1,1,1,1,1,2),42)}
    }
    check("rifiuta offset negativo"){
      rejectArg("Offset"){old(Six,SixParts,-1)}
    }
    check("rifiuta offset dopo la fine"){
      rejectArg("Offset"){old(Six,SixParts,252)}
    }
    check("il validator indipendente accetta lo stato intatto"){
      new BaseValidationManager().requireDiscovery20Ready(ready())
    }
    check("il validator rifiuta il giorno storico modificato"){
      val c=ready();c.legacyDayInCutlet=Some(1)
      rejectState("Giorno"){new BaseValidationManager()
        .requireDiscovery20Ready(c)}
    }
    check("il validator rifiuta la cotoletta storica modificata"){
      val c=ready();c.legacyCutletId=Some(2)
      rejectState("Cotoletta"){new BaseValidationManager()
        .requireDiscovery20Ready(c)}
    }
    check("il validator rifiuta la lista degli inizi modificata"){
      val c=ready();c.legacyCutletStartOffsets=Some(Vector(0,42))
      rejectState("Inizi"){new BaseValidationManager()
        .requireDiscovery20Ready(c)}
    }
    check("il validator rifiuta lo snapshot modificato"){
      val c=ready();c.cutletDayOffset=Some(43)
      rejectState("Snapshot"){new BaseValidationManager()
        .requireDiscovery20Ready(c)}
    }
    check("il validator rifiuta trace extra"){
      val c=ready();c.branchTrace.append("EXTRA")
      rejectState("Trace"){new BaseValidationManager()
        .requireDiscovery20Ready(c)}
    }
    check("il validator rifiuta lo stato non finale"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Stato"){new BaseValidationManager()
        .requireDiscovery20Ready(c)}
    }
    check("l'handler non accetta una chiamata senza bootstrap"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_20_CUTLET_OPEN_BOUNDARY"
      c.cutletGateGaps=Some(Six)
      c.cutletGatePartition=Some(SixParts)
      c.cutletDayOffset=Some(42)
      rejectState("Bootstrap"){new Discovery20CutletOpenBoundaryHandler(
        new BaseMetricsShell).handle(c)}
    }
    check("nessun oracolo dei test compare nei sorgenti di produzione"){
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo")
    }
    check("nessuna PATCH20 viene anticipata nello stage40"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      truth(current>=40,"Stage40")
      val files=Files.walk(root().resolve("src/main/scala"))
      val sources=try files.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally files.close()
      if(current==40)
        truth(!sources.contains("def cutletBoundaryPatch("),"PATCH20 assente")
      else
        truth(sources.contains("def cutletBoundaryPatch("),"PATCH20 successiva")
    }
    check("la firma certificata di Stage39 resta preservata"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains(
        "STAGE_39_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_52_PASS_0_FAIL"),
        "Stage39")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .get.split("=",2)(1).toInt
      truth(done>=39,"Completamento")
    }

    // Solo tre equivalenze normative falliscono per il vecchio ">".
    Vector(
      ("CUTLET2_START",Six,SixParts,42),
      ("CUTLET3_START",Six,SixParts,84),
      ("CUTLET17_START",Seventeen,SeventeenParts,672)
    ).foreach { case (label,gaps,parts,day) =>
      check("equivalenza normativa confine "+label) {
        val r=new BaseMonsterManager().discover20CutletOpenBoundary(
          Huge,-Huge,gaps,parts,day)
        eqv((r.legacyCutletId,r.legacyDayInCutlet),
          normative(gaps,parts,day),"Soglia storica errata: "+label)
      }
    }
    println("\nRISULTATO STADIO 40: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
