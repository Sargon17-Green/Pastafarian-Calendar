package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 12: il tetto annuale 5778 è inclusivo; legacy 5777 resta immutato. */
object Stage25Tests {
  private var passed=0
  private var failed=0
  private val Six=Vector.fill(6)(963)
  private val Seven=Vector.fill(5)(963)++Vector(900,63)
  private val Eight=Vector.fill(5)(963)++Vector(321,321,321)
  private val Below=Vector.fill(5)(963)++Vector(962)
  private val Above=Vector.fill(5)(963)++Vector(322,321,321)
  private def check(label:String)(run: => Unit):Unit = {
    try {run;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit =
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  private def truth(ok:Boolean,label:String):Unit =
    if(!ok)throw new AssertionError(label)
  private def rejectArg(label:String)(run: => Unit):Unit = {
    var caught=false
    try run catch {case _:IllegalArgumentException => caught=true}
    truth(caught,label+": parametro invalido accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit = {
    var caught=false
    try run catch {case _:IllegalStateException => caught=true}
    truth(caught,label+": stato invalido accettato")
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice non trovata")
    p
  }
  private def length(gaps:Vector[Int]):BigInt =
    gaps.foldLeft(BigInt(0))((total,x)=>total+BigInt(x))
  private def normative(gaps:Vector[Int]):Boolean =
    gaps.size>=6 &&
      gaps.forall(x=>x>=NormativeOracle.GateGapMin &&
        x<=NormativeOracle.GateGapMax) &&
      length(gaps)>=NormativeOracle.YearMinDays &&
      length(gaps)<=NormativeOracle.YearMaxDays
  private def patched(gaps:Vector[Int]):Patch12YearCeilingResult =
    Patch12YearCeilingWrapper.yearMaxPatch(gaps)
  private def ready(gaps:Vector[Int]=Six):BaseMonsterContext = {
    val c=BaseMonsterContext(1,2)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.legacyYearGapsInput=Some(gaps)
    c.phase="DISCOVERY_12_YEAR_CEILING"
    new Discovery12YearCeilingHandler(new BaseMetricsShell).handle(c)
    c.phase="PATCH_12_YEAR_CEILING"
    c
  }
  private def complete(gaps:Vector[Int]=Six):BaseMonsterContext = {
    val c=ready(gaps)
    new Patch12YearCeilingHandler(new BaseMetricsShell).handle(c)
    c
  }
  def main(args:Array[String]):Unit = {
    check("sei divari massimi formano il limite normativo incluso") {
      val r=patched(Six)
      eqv(r.historical.yearLength,BigInt(5778),"Somma massima")
      eqv(r.historical.oldMaximum,5777,"Cicatrice")
      truth(!r.historical.accepted,"Legacy rifiuta")
      eqv(r.normativeMaximum,5778,"Tetto corretto")
      truth(r.correctedAccepted,"PATCH 12 ammette")
    }
    check("sette divari con 900 e 63 ammettono 5778") {
      eqv(length(Seven),BigInt(5778),"Somma")
      truth(patched(Seven).correctedAccepted,"Inclusione")
      truth(!patched(Seven).historical.accepted,"Cicatrice")
    }
    check("otto divari con tre 321 ammettono 5778") {
      eqv(length(Eight),BigInt(5778),"Somma")
      truth(patched(Eight).correctedAccepted,"Inclusione")
      truth(!patched(Eight).historical.accepted,"Cicatrice")
    }
    check("5777 rimane valido anche dopo la correzione") {
      val r=patched(Below)
      eqv(r.historical.yearLength,BigInt(5777),"Durata")
      truth(r.historical.accepted && r.correctedAccepted,"Accettazione")
    }
    check("5779 rimane escluso, anche con otto divari validi") {
      eqv(length(Above),BigInt(5779),"Durata")
      val r=patched(Above)
      truth(!r.correctedAccepted && !r.historical.accepted,"Esclusione")
    }
    check("la durata minima di sei divari da 42 è valida") {
      val gaps=Vector.fill(6)(42)
      val r=patched(gaps)
      eqv(r.historical.yearLength,BigInt(252),"Minimo")
      truth(r.historical.accepted && r.correctedAccepted,"Valido")
    }
    check("cinque divari, anche lunghi, non formano un anno") {
      val gaps=Vector.fill(5)(963)
      val r=patched(gaps)
      truth(!r.correctedAccepted,"Minimo divari")
      eqv(r.historical,LegacyYearCeilingAdapter.legacyYearMax(gaps),"Legacy")
    }
    check("un divario non costituisce un anno") {
      truth(!patched(Vector(42)).correctedAccepted,"Solo un cancello")
    }
    check("sette divari minimi costituiscono un anno") {
      val g=Vector.fill(7)(42)
      eqv(length(g),BigInt(294),"Lunghezza")
      truth(patched(g).correctedAccepted,"Sette divari")
    }
    check("sei divari da 962 producono 5772 valido") {
      val g=Vector.fill(6)(962)
      eqv(length(g),BigInt(5772),"Durata")
      truth(patched(g).correctedAccepted,"Valido")
    }
    check("sette divari da 963 superano il tetto") {
      val g=Vector.fill(7)(963)
      truth(!patched(g).correctedAccepted,"Oltre")
      eqv(length(g),BigInt(6741),"Durata")
    }
    check("centoquaranta divari minimi superano 5778") {
      val g=Vector.fill(140)(42)
      truth(!patched(g).correctedAccepted,"Superato")
      eqv(length(g),BigInt(5880),"Somma")
    }
    check("ogni singolo divario di sei porte può variare da 42 a 963") {
      for(gap<-42 to 963) {
        val g=Vector.fill(5)(42):+gap
        eqv(patched(g).correctedAccepted,normative(g),"Gap "+gap)
      }
    }
    check("921 durate di sei divari riproducono il medesimo legacy") {
      for(i<-0 until 921) {
        val g=Vector.fill(6)(42+i)
        val r=patched(g)
        eqv(r.historical,LegacyYearCeilingAdapter.legacyYearMax(g),"Legacy "+i)
        truth(r.correctedAccepted,"Norma "+i)
      }
    }
    check("il rango finale dei 922 possibili divari accetta 5778") {
      val g=Vector.fill(6)(963)
      eqv(patched(g).correctedAccepted,normative(g),"Ultimo rango")
    }
    check("tutti i vettori con sei divari 42..963 sono in dominio") {
      for(i<-42 to 963) {
        val g=Vector(42,963,123,i,321,42)
        eqv(patched(g).correctedAccepted,normative(g),"Valore "+i)
      }
    }
    check("1024 vettori deterministici fra sei e dodici divari") {
      val rng=new Random(20261012L)
      for(i<-1 to 1024) {
        val g=Vector.fill(6+rng.nextInt(7))(42+rng.nextInt(922))
        val r=patched(g)
        eqv(r.correctedAccepted,normative(g),"Vettore "+i)
        eqv(r.historical,LegacyYearCeilingAdapter.legacyYearMax(g),"Cicatrice "+i)
      }
    }
    check("4096 vettori con segno nel calcolo dei giorni normalizzati") {
      val rng=new Random(24680L)
      for(i<-1 to 4096) {
        val g=Vector.fill(6+rng.nextInt(20))(42+rng.nextInt(922))
        val r=patched(g)
        eqv(r.correctedAccepted,normative(g),"Campione "+i)
      }
    }
    check("vettori più lunghi calcolano somme come BigInt") {
      val g=Vector.fill(100000)(963)
      val r=patched(g)
      eqv(r.historical.yearLength,BigInt(96300000),"Somma BigInt")
      truth(!r.correctedAccepted,"Esclusione")
    }
    check("la cicatrice 5777 è sempre eseguita veramente") {
      for(g<-Vector(Six,Seven,Eight,Below,Above,Vector.fill(7)(42))) {
        val r=patched(g)
        eqv(r.historical,LegacyYearCeilingAdapter.legacyYearMax(g),"Legacy")
      }
    }
    check("il risultato rimane immutabile dopo chiamate intercalate") {
      val baseline=patched(Six)
      for(i<-1 to 200) patched(Vector.fill(6)(42+i%922))
      eqv(patched(Six),baseline,"Determinismo")
    }
    check("vettore vuoto è respinto dalla cicatrice") {
      rejectArg("Vuoto"){patched(Vector.empty)}
    }
    check("divari sotto 42 o sopra 963 sono respinti") {
      for(bad<-Vector(Int.MinValue,-1,0,1,41,964,2000,Int.MaxValue)) {
        rejectArg("Divario "+bad){patched(Vector(42,42,42,42,42,bad))}
      }
    }
    check("manager esegue Bootstrap, discovery e PATCH 12") {
      val m=new BaseMonsterManager
      val r=m.patch12YearCeiling(17,-19,Six)
      eqv(r.calculationDay,BigInt(17),"Calcolo")
      eqv(r.targetDay,BigInt(-19),"Domanda")
      eqv(r.gateGaps,Six,"Divari")
      eqv(r.yearLength,BigInt(5778),"Anno")
      eqv(r.legacyMaximum,5777,"Vecchio limite")
      eqv(r.patchedMaximum,5778,"Nuovo limite")
      truth(!r.legacyAccepted,"Vecchio giudizio")
      truth(r.patchedAccepted,"Nuovo giudizio")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_12_YEAR_CEILING","Fase")
      eqv(r.status,"PATCH_12_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_12_YEAR_CEILING",
        "PATCH_12_YEAR_CEILING"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery12.year.ceiling.calls"),BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch12.year.ceiling.calls"),BigInt(1),"Patch")
    }
    check("manager restituisce il medesimo giudizio storico della discovery") {
      val m=new BaseMonsterManager
      for(g<-Vector(Six,Seven,Eight,Below,Above)) {
        val old=m.discover12YearCeiling(0,0,g)
        val corrected=m.patch12YearCeiling(0,0,g)
        eqv(corrected.legacyAccepted,old.legacyAccepted,"Accettazione")
        eqv(corrected.legacyMaximum,old.oldMaximum,"Massimo")
        eqv(corrected.yearLength,old.yearLength,"Durata")
      }
    }
    check("lo stesso manager non confonde le invocazioni") {
      val m=new BaseMonsterManager
      val a=m.patch12YearCeiling(1,2,Six)
      val b=m.patch12YearCeiling(3,4,Above)
      truth(a.patchedAccepted,"Primo")
      truth(!b.patchedAccepted,"Secondo")
      eqv(m.metricsSnapshot("patch12.year.ceiling.calls"),BigInt(2),"Metrica")
    }
    check("giorni huge positivi e negativi non mutano giudizi locali") {
      val huge=(BigInt(1)<<16384)+987654321
      val m=new BaseMonsterManager
      val a=m.patch12YearCeiling(0,0,Six)
      val b=m.patch12YearCeiling(huge,-huge,Six)
      eqv(a.patchedAccepted,b.patchedAccepted,"Giudizio")
      eqv(b.calculationDay,huge,"Calcolo huge")
      eqv(b.targetDay,-huge,"Domanda huge")
    }
    check("handler respinge il contesto NEW e il bootstrap non seguito") {
      val h=new Patch12YearCeilingHandler(new BaseMetricsShell)
      rejectState("NEW"){h.handle(BaseMonsterContext(1,2))}
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.legacyYearGapsInput=Some(Six)
      rejectState("Solo BOOT"){h.handle(c)}
    }
    check("handler respinge la doppia applicazione") {
      val h=new Patch12YearCeilingHandler(new BaseMetricsShell)
      val c=ready()
      h.handle(c)
      val previous=c.patchedYearAcceptedOutput
      rejectState("Ripetizione"){h.handle(c)}
      eqv(c.patchedYearAcceptedOutput,previous,"Stato invariato")
    }
    check("validator rifiuta un giudizio PATCH assente") {
      val c=ready()
      c.phase="PATCH_12_YEAR_CEILING"
      c.status="PATCH_12_READY"
      c.branchTrace.append("PATCH_12_YEAR_CEILING")
      c.patch12Applied=true
      rejectState("PATCH mancante"){
        new BaseValidationManager().requirePatch12Ready(c)}
    }
    check("validator accetta le 922 durate regolari delle sei porte") {
      val v=new BaseValidationManager
      for(i<-0 to 921) {
        val c=complete(Vector.fill(6)(42+i))
        v.requirePatch12Ready(c)
      }
    }
    check("validator accetta tutti e tre i casi di 5778") {
      val v=new BaseValidationManager
      for(g<-Vector(Six,Seven,Eight))v.requirePatch12Ready(complete(g))
    }
    check("validator rifiuta il nuovo tetto contraffatto") {
      val c=complete()
      c.patchedYearMaxOutput=Some(5777)
      rejectState("Tetto 5777"){new BaseValidationManager().requirePatch12Ready(c)}
    }
    check("validator rifiuta il giudizio corretto contraffatto") {
      val c=complete()
      c.patchedYearAcceptedOutput=Some(false)
      rejectState("Falso rifiuto"){new BaseValidationManager().requirePatch12Ready(c)}
    }
    check("validator rifiuta il vecchio tetto modificato") {
      val c=complete()
      c.legacyYearMaxOutput=Some(5778)
      rejectState("Tetto legacy"){new BaseValidationManager().requirePatch12Ready(c)}
    }
    check("validator rifiuta il giudizio storico modificato") {
      val c=complete()
      c.legacyYearAcceptedOutput=Some(true)
      rejectState("Legacy falsificato"){new BaseValidationManager().requirePatch12Ready(c)}
    }
    check("validator rifiuta la somma storica modificata") {
      val c=complete()
      c.legacyYearLengthOutput=Some(BigInt(5777))
      rejectState("Somma falsificata"){new BaseValidationManager().requirePatch12Ready(c)}
    }
    check("validator rifiuta i divari mutati dopo la patch") {
      val c=complete()
      c.legacyYearGapsInput=Some(Below)
      rejectState("Input falsificato"){new BaseValidationManager().requirePatch12Ready(c)}
    }
    check("validator rifiuta fase, traccia e flag falsi") {
      val c=complete()
      val v=new BaseValidationManager
      c.patch12Applied=false
      rejectState("Flag"){v.requirePatch12Ready(c)}
      c.patch12Applied=true
      c.branchTrace.remove(1)
      rejectState("Traccia"){v.requirePatch12Ready(c)}
      c.branchTrace.insert(1,"DISCOVERY_12_YEAR_CEILING")
      c.phase="DISCOVERY_12_YEAR_CEILING"
      rejectState("Fase"){v.requirePatch12Ready(c)}
    }
    check("le undici patch precedenti rimangono normative") {
      val m=new BaseMonsterManager
      val f=NormativeOracle.FoundationDay
      val modulus=NormativeOracle.M
      eqv(m.patch01Save(0,0,modulus).patchedOutput,modulus,"SAVE")
      eqv(m.patch02DayTag(f,f,f).patchedTag,BigInt(1),"DayTag")
      eqv(m.patch03Distance(f,f).patchedDistance,BigInt(1),"Distance")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"Stones")
      val hidden=Vector[BigInt](101,202,303,404,505,606,707)
      eqv(m.patch05Prior(0,0,hidden,Vector.empty,1,7).patchedValue,BigInt(707),"Prior")
      eqv(m.patch06Grind(0,0,1,7,11,13,17,
        Vector[BigInt](19,23,29,31,37)).patchedValue,BigInt(422),"Grind")
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,
        Vector(6,5,4,3,2,1),"Permutation")
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),
        37,Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"Bowl freeze")
      eqv(m.patch09Vault(0,0,Vector[BigInt](11,13,17,19,23,29)).patchedBowls,
        NormativeOracle.postStir12(Vector[BigInt](11,13,17,19,23,29)),"Vault")
      eqv(m.patch10Order46(0,0,1,720,1).correctedNextBowl,6,"Latch")
      eqv(m.patch11ShortPick(0,0,modulus,1,5).patchedRank,BigInt(1),"Rejection")
    }
    check("oracolo test-only, cicatrice 5777 intatta e nessuno Stage26") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val source=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!source.contains("NormativeOracle"),"Oracolo in produzione")
      truth(source.contains("private val LEGACY_YEAR_MAX: Int = 5777"),
        "Tetto storico immutato")
      truth(source.contains("LegacyYearCeilingAdapter.legacyYearMax(gaps)"),
        "Wrapper attraversa cicatrice")
      truth(source.contains("val canonicalMaximum=5778"),"Valore canonico")
      truth(!source.contains("oldJumpGuess"),"Stage26 anticipato")
    }
    check("metadati dello Stage25 GREEN conservano Stage24 RED") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=25"),"Stadio")
      truth(st.contains("CURRENT_KIND=PATCH"),"Tipo")
      truth(st.contains("CURRENT_PATCH=12"),"Patch")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"GREEN")
      truth(st.contains("STAGE_24_NATIVE_VERIFICATION=PASS_EXPECTED_RED_33_PASS_3_FAIL"),
        "Firma storica Stage24")
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=24 && completed<=25,"Ordine certificazioni")
    }
    println("\nRISULTATO STADIO 25: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
