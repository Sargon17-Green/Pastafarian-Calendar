package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 12: l'anno storico esclude la durata canonica 5778. */
object Stage24Tests {
  private var passed=0
  private var failed=0
  private val Six=Vector.fill(6)(963)
  private val Seven=Vector.fill(5)(963)++Vector(900,63)
  private val Eight=Vector.fill(5)(963)++Vector(321,321,321)
  private val Below=Vector.fill(5)(963)++Vector(962)

  private def check(label:String)(f: => Unit):Unit = {
    try {f;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](a:A,b:A,label:String):Unit =
    if(a!=b)throw new AssertionError(label+": atteso="+b+", ottenuto="+a)
  private def truth(v:Boolean,label:String):Unit =
    if(!v)throw new AssertionError(label)
  private def rejectArg(label:String)(f: => Unit):Unit = {
    var rejected=false
    try f catch {case _:IllegalArgumentException => rejected=true}
    truth(rejected,label+": input illegale accettato")
  }
  private def rejectState(label:String)(f: => Unit):Unit = {
    var rejected=false
    try f catch {case _:IllegalStateException => rejected=true}
    truth(rejected,label+": contesto falso accettato")
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
    gaps.map(BigInt(_)).sum

  // Il predicato di riferimento usa solo i limiti dell'oracolo test-only.
  private def normative(gaps:Vector[Int]):Boolean =
    gaps.size>=6 &&
    gaps.forall(x=>x>=NormativeOracle.GateGapMin &&
      x<=NormativeOracle.GateGapMax) &&
    length(gaps)>=NormativeOracle.YearMinDays &&
    length(gaps)<=NormativeOracle.YearMaxDays

  private def historic(gaps:Vector[Int]):LegacyYearCeilingResult =
    LegacyYearCeilingAdapter.legacyYearMax(gaps)

  private def ready(gaps:Vector[Int]=Six):BaseMonsterContext = {
    val c=BaseMonsterContext(1,2)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.legacyYearGapsInput=Some(gaps)
    c.phase="DISCOVERY_12_YEAR_CEILING"
    new Discovery12YearCeilingHandler(new BaseMetricsShell).handle(c)
    c
  }

  def main(args:Array[String]):Unit = {
    check("limite storico dichiarato a 5777 giorni") {
      val r=historic(Six)
      eqv(r.oldMaximum,5777,"Tetto legacy")
      eqv(r.yearLength,BigInt(5778),"Lunghezza")
      truth(!r.accepted,"Il legacy deve rifiutare la durata limite")
    }
    check("il tetto normativo test-only è esattamente 5778") {
      eqv(NormativeOracle.YearMaxDays,5778,"Tetto normativo")
      truth(NormativeOracle.YearMaxDays!=historic(Six).oldMaximum,
        "Differenza di un solo giorno")
    }
    check("il tetto minimo canonico resta di 252 giorni") {
      val gaps=Vector.fill(6)(42)
      eqv(length(gaps),BigInt(252),"Lunghezza minima")
      truth(historic(gaps).accepted,"Minimo storico valido")
      truth(normative(gaps),"Minimo canonico valido")
    }
    check("cinque divari non formano mai una candidata valida") {
      val gaps=Vector.fill(5)(963)
      truth(!historic(gaps).accepted,"Cinque divari")
      truth(!normative(gaps),"Regola dei sei cancelli")
    }
    check("un solo divario non costituisce una candidata valida") {
      val gaps=Vector(42)
      truth(!historic(gaps).accepted,"Un divario")
      truth(!normative(gaps),"Un divario normativo")
    }
    check("5777 con sei divari resta valido") {
      eqv(length(Below),BigInt(5777),"Penultimo giorno")
      truth(historic(Below).accepted,"Legacy include 5777")
      truth(normative(Below),"Norma include 5777")
    }
    check("sei divari di 962 giorni restano validi") {
      val gaps=Vector.fill(6)(962)
      eqv(length(gaps),BigInt(5772),"Sei divari")
      eqv(historic(gaps).accepted,normative(gaps),"Equivalenza")
    }
    check("otto divari con totale 5779 sono invalidi") {
      val gaps=Vector.fill(5)(963)++Vector(322,321,321)
      eqv(length(gaps),BigInt(5779),"Lunghezza oltre limite")
      truth(!historic(gaps).accepted,"Legacy rifiuta 5779")
      truth(!normative(gaps),"Norma rifiuta 5779")
    }
    check("140 divari minimi superano la durata massima") {
      val gaps=Vector.fill(140)(42)
      truth(!historic(gaps).accepted,"Legacy")
      truth(!normative(gaps),"Norma")
    }
    check("922 durate regolari di sei cancelli includono il limite esterno") {
      for(i<-0 until 921) {
        val gaps=Vector.fill(6)(42+i)
        val r=historic(gaps)
        eqv(r.yearLength,BigInt(6*(42+i)),"Somma "+i)
        truth(r.accepted,"Candidata inferiore al tetto "+i)
        truth(normative(gaps),"Norma "+i)
      }
    }
    check("la somma dei divari conserva tutti i dati di input") {
      for(gaps<-Vector(Six,Seven,Eight,Below,Vector.fill(6)(42))) {
        val r=historic(gaps)
        eqv(r.gateGaps,gaps,"Vettore immutato")
        eqv(r.yearLength,length(gaps),"Somma indipendente")
      }
    }
    check("inversione dei divari non modifica la durata") {
      for(gaps<-Vector(Seven,Eight,Below)) {
        val r=historic(gaps)
        val reversed=historic(gaps.reverse)
        eqv(r.yearLength,reversed.yearLength,"Somma")
        eqv(r.accepted,reversed.accepted,"Accettazione")
      }
    }
    check("permutazioni con 5777 giorni restano invarianti") {
      val a=Below
      val b=Below.reverse
      truth(historic(a).accepted&&historic(b).accepted,"Permutazione valida")
    }
    check("nessun divario singolo può essere inferiore a 42") {
      for(x<-Vector(Int.MinValue,-1,0,1,41)) {
        rejectArg("Divario piccolo "+x) {historic(Vector.fill(5)(42):+x)}
      }
    }
    check("nessun divario singolo può essere superiore a 963") {
      for(x<-Vector(964,10000,Int.MaxValue)) {
        rejectArg("Divario grande "+x){historic(Vector.fill(5)(42):+x)}
      }
    }
    check("il vettore vuoto viene rifiutato dal legacy") {
      rejectArg("Nessun divario"){historic(Vector.empty)}
    }
    check("l'asse delle durate usa BigInt e non subisce overflow") {
      val gaps=Vector.fill(5000)(963)
      val r=historic(gaps)
      eqv(r.yearLength,BigInt(4815000),"Somma grande")
      truth(!r.accepted,"Durata fuori soglia")
    }
    check("2048 vettori random deterministici conservano la norma fuori dal bordo") {
      val rng=new Random(20261012L)
      for(i<-1 to 2048) {
        val n=1+rng.nextInt(40)
        val gaps=Vector.fill(n)(42+rng.nextInt(922))
        val r=historic(gaps)
        eqv(r.yearLength,length(gaps),"Lunghezza "+i)
        if(length(gaps)!=BigInt(5778))
          eqv(r.accepted,normative(gaps),"Equivalenza "+i)
      }
    }
    check("il manager espone la traccia della discovery completa") {
      val m=new BaseMonsterManager
      val r=m.discover12YearCeiling(17,-19,Six)
      eqv(r.calculationDay,BigInt(17),"Giorno calcolo")
      eqv(r.targetDay,BigInt(-19),"Giorno richiesto")
      eqv(r.gateGaps,Six,"Divari")
      eqv(r.yearLength,BigInt(5778),"Lunghezza")
      truth(!r.legacyAccepted,"Rifiuto vecchio")
      eqv(r.oldMaximum,5777,"Tetto vecchio")
      eqv(r.phase,"DISCOVERY_12_YEAR_CEILING","Fase")
      eqv(r.status,"LEGACY_YEAR_CEILING_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_12_YEAR_CEILING"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery12.year.ceiling.calls"),BigInt(1),"Metrica")
    }
    check("due invocazioni del manager sono separate") {
      val m=new BaseMonsterManager
      val a=m.discover12YearCeiling(0,1,Six)
      val b=m.discover12YearCeiling(2,3,Below)
      truth(!a.legacyAccepted,"Prima")
      truth(b.legacyAccepted,"Seconda")
      eqv(m.metricsSnapshot("discovery12.year.ceiling.calls"),BigInt(2),"Metrica")
    }
    check("giorni signed enormi non modificano il predicato locale") {
      val m=new BaseMonsterManager
      val huge=(BigInt(1)<<16384)+777
      val a=m.discover12YearCeiling(0,0,Below)
      val b=m.discover12YearCeiling(huge,-huge,Below)
      eqv(a.legacyAccepted,b.legacyAccepted,"Prova locale")
      eqv(b.calculationDay,huge,"Giorno calcolo grande")
      eqv(b.targetDay,-huge,"Giorno chiesto grande")
    }
    check("handler non può essere eseguito senza bootstrap") {
      val h=new Discovery12YearCeilingHandler(new BaseMetricsShell)
      rejectState("Contesto NEW"){h.handle(BaseMonsterContext(1,2))}
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED"
      c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_12_YEAR_CEILING"
      rejectState("Divari assenti"){h.handle(c)}
    }
    check("handler rifiuta la seconda esecuzione preservando il risultato") {
      val h=new Discovery12YearCeilingHandler(new BaseMetricsShell)
      val c=ready()
      val before=c.legacyYearLengthOutput
      rejectState("Doppia discovery"){h.handle(c)}
      eqv(c.legacyYearLengthOutput,before,"Stato non alterato")
    }
    check("validator rifiuta il risultato assente") {
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_12_YEAR_CEILING"
      c.status="LEGACY_YEAR_CEILING_READY"
      c.legacyYearGapsInput=Some(Below)
      rejectState("Non pubblicato"){
        new BaseValidationManager().requireDiscovery12Ready(c)}
    }
    check("validator rifiuta il limite contraffatto") {
      val c=ready()
      c.legacyYearMaxOutput=Some(5778)
      rejectState("Tetto modificato"){
        new BaseValidationManager().requireDiscovery12Ready(c)}
    }
    check("validator rifiuta la durata contraffatta") {
      val c=ready()
      c.legacyYearLengthOutput=Some(BigInt(5777))
      rejectState("Durata modificata"){
        new BaseValidationManager().requireDiscovery12Ready(c)}
    }
    check("validator rifiuta il giudizio legacy contraffatto") {
      val c=ready()
      c.legacyYearAcceptedOutput=Some(true)
      rejectState("Accettazione forzata"){
        new BaseValidationManager().requireDiscovery12Ready(c)}
    }
    check("validator rifiuta divari cambiati dopo la discovery") {
      val c=ready()
      c.legacyYearGapsInput=Some(Below)
      rejectState("Vettore mutato"){
        new BaseValidationManager().requireDiscovery12Ready(c)}
    }
    check("validator rifiuta la traccia falsa e la fase falsa") {
      val c=ready()
      val v=new BaseValidationManager
      c.branchTrace.remove(1)
      rejectState("Traccia"){v.requireDiscovery12Ready(c)}
      c.branchTrace.append("DISCOVERY_12_YEAR_CEILING")
      c.phase="PATCH_12_YEAR_CEILING"
      rejectState("Fase"){v.requireDiscovery12Ready(c)}
    }
    check("validator accetta 921 vettori sottosoglia e casi minimi") {
      val v=new BaseValidationManager
      for(i<-0 until 921) {
        v.requireDiscovery12Ready(ready(Vector.fill(6)(42+i)))
      }
    }
    check("le undici patch precedenti restano normative") {
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
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),37,
        Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"Bowl freeze")
      eqv(m.patch09Vault(0,0,Vector[BigInt](11,13,17,19,23,29)).patchedBowls,
        NormativeOracle.postStir12(Vector[BigInt](11,13,17,19,23,29)),
        "Vault")
      eqv(m.patch10Order46(0,0,1,720,1).correctedNextBowl,6,"Latch")
      eqv(m.patch11ShortPick(0,0,modulus,1,5).patchedRank,BigInt(1),"Rejection")
    }
    check("oracle test-only, cicatrice 5777 e nessuna PATCH 12") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val source=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!source.contains("NormativeOracle"),"Oracolo in produzione")
      truth(source.contains("private val LEGACY_YEAR_MAX: Int = 5777"),
        "La cicatrice del limite vecchio")
      truth(!source.contains("yearMaxPatch"),"PATCH 12 anticipata")
      truth(!source.contains("oldJumpGuess"),"Stadio futuro anticipato")
    }
    check("metadati Stage24 RED preservano Stage23 GREEN") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=24"),"Stadio")
      truth(st.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
      truth(st.contains("CURRENT_PATCH=11"),"Patch precedente")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"Stato atteso")
      truth(st.contains("STAGE_23_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_42_PASS_0_FAIL"),
        "Certificazione Stage23")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(done==23||done==24,"Ordine certificazione")
    }

    check("equivalenza normativa limite sei divari") {
      val r=new BaseMonsterManager().discover12YearCeiling(0,0,Six)
      eqv(r.legacyAccepted,normative(Six),"Tetto legacy 5777: sei divari")
    }
    check("equivalenza normativa limite sette divari") {
      val r=new BaseMonsterManager().discover12YearCeiling(0,0,Seven)
      eqv(r.legacyAccepted,normative(Seven),"Tetto legacy 5777: sette divari")
    }
    check("equivalenza normativa limite otto divari") {
      val r=new BaseMonsterManager().discover12YearCeiling(0,0,Eight)
      eqv(r.legacyAccepted,normative(Eight),"Tetto legacy 5777: otto divari")
    }
    println("\nRISULTATO STADIO 24: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
