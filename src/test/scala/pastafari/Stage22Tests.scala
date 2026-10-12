package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 11: il primo campione viene ridotto senza rejection sampling. */
object Stage22Tests {
  private var passed=0
  private var failed=0
  private val M=NormativeOracle.M

  private def check(label:String)(run: => Unit):Unit = {
    try {run;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit =
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  private def truth(value:Boolean,label:String):Unit =
    if(!value)throw new AssertionError(label)
  private def rejectArg(label:String)(run: => Unit):Unit = {
    var caught=false
    try run catch {case _:IllegalArgumentException => caught=true}
    truth(caught,"Parametro non valido accettato: "+label)
  }
  private def rejectState(label:String)(run: => Unit):Unit = {
    var caught=false
    try run catch {case _:IllegalStateException => caught=true}
    truth(caught,"Stato non valido accettato: "+label)
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice non trovata")
    p
  }
  private def historic(x:BigInt,direction:Int,n:BigInt):LegacyBiasedPickResult =
    LegacyBiasedPickAdapter.biasedLegacyPick(x,direction,n)

  private def oracle(x:BigInt,direction:Int,n:BigInt):BigInt =
    NormativeOracle.chooseRankShort(
      NormativeOracle.AnswerStream(x,direction),n)

  private def ready(x:BigInt=M,direction:Int=1,n:BigInt=5):BaseMonsterContext = {
    val c=BaseMonsterContext(1,2)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.selectionSampleInput=Some(x)
    c.selectionDirectionInput=Some(direction)
    c.selectionFamilySizeInput=Some(n)
    c.phase="DISCOVERY_11_BIASED_SHORT_PICK"
    new Discovery11BiasedPickHandler(new BaseMetricsShell).handle(c)
    c
  }

  def main(args:Array[String]):Unit = {
    check("la prima risposta non viene mai scartata dal vecchio codice") {
      val r=historic(M,1,5)
      eqv(r.firstSample,M,"Campione vecchio")
      eqv(r.acceptanceLimit,M-2,"Limite")
      eqv(r.legacyRank,BigInt(2),"Rango distorto")
    }
    check("il limite floor(M/N)*N usa l'esatto dominio di SAVE") {
      for(n<-Vector[BigInt](1,2,3,4,5,7,11,31,720,100000,M)) {
        val r=historic(1,1,n)
        eqv(r.acceptanceLimit,(M/n)*n,"Limite "+n)
        truth(r.acceptanceLimit>=n && r.acceptanceLimit<=M,"Dominio")
      }
    }
    check("il numero di campione rimane sempre quello iniziale") {
      for(x<-Vector(BigInt(1),BigInt(2),M/2,M-2,M-1,M)) {
        eqv(historic(x,-1,5).firstSample,x,"Campione")
      }
    }
    check("per campioni accettati la scelta legacy è normativa") {
      for(n<-Vector[BigInt](1,2,3,5,31,720,10000,M);
          x<-Vector(BigInt(1),BigInt(2),BigInt(100))) {
        if(x<=M && x<=((M/n)*n)) {
          for(direction<-Vector(-1,1)) {
            eqv(historic(x,direction,n).legacyRank,
              oracle(x,direction,n),"Campione accettato")
          }
        }
      }
    }
    check("N uguale a uno restituisce sempre il solo rango") {
      for(x<-Vector(BigInt(1),BigInt(2),M-1,M)) {
        val r=historic(x,1,1)
        eqv(r.legacyRank,BigInt(1),"N uno")
        eqv(r.acceptanceLimit,M,"Tutti accettati")
      }
    }
    check("N uguale a M mantiene il campione senza bias") {
      for(x<-Vector(BigInt(1),BigInt(2),M-1,M)) {
        eqv(historic(x,1,M).legacyRank,x,"N=M")
        eqv(oracle(x,1,M),x,"Riferimento")
      }
    }
    check("la direzione viene controllata anche se ignorata dal bias") {
      for(x<-Vector(BigInt(1),M-2,M-1,M);n<-Vector[BigInt](2,3,5,7)) {
        eqv(historic(x,1,n).legacyRank,
          historic(x,-1,n).legacyRank,"Direzione ignorata")
      }
    }
    check("il rango legacy appartiene sempre alla famiglia") {
      for(n<-1 to 720;x<-Vector(BigInt(1),BigInt(2),M-1,M)) {
        val r=historic(x,1,BigInt(n))
        truth(r.legacyRank>=1 && r.legacyRank<=n,"Rango")
      }
    }
    check("i 720 possibili valori di N con primo campione accettato") {
      for(n<-1 to 720) {
        val sample=BigInt(20261012)
        val r=historic(sample,1,BigInt(n))
        truth(sample<=r.acceptanceLimit,"Campione scelto ammesso")
        eqv(r.legacyRank,oracle(sample,1,BigInt(n)),"N="+n)
      }
    }
    check("2048 campioni signed deterministici attraversano SAVE") {
      val rng=new Random(20261012L)
      for(i<-1 to 2048) {
        val signed=BigInt(rng.nextLong())*BigInt(i)
        val x=NormativeOracle.save(signed)
        val n=BigInt(rng.nextInt(720)+1)
        val d=if((i&1)==0)1 else -1
        val r=historic(x,d,n)
        eqv(r.legacyRank,((x-1)%n)+1,"Rango storico")
        eqv(r.acceptanceLimit,(M/n)*n,"Limite")
        if(x<=r.acceptanceLimit)
          eqv(r.legacyRank,oracle(x,d,n),"Campione ammesso")
      }
    }
    check("BigInt oltre 16384 bit normalizzato da SAVE resta esatto") {
      val huge=(BigInt(1)<<16384)+12345
      for(z<-Vector(huge,-huge,huge*huge)) {
        val x=NormativeOracle.save(z)
        val r=historic(x,-1,7)
        eqv(r.legacyRank,((x-1)%7)+1,"Rango grande")
        eqv(r.acceptanceLimit,(M/7)*7,"Limite grande")
      }
    }
    check("campione fuori scala è respinto, senza troncamento") {
      for(x<-Vector(BigInt(-1),BigInt(0),M+1,(BigInt(1)<<16384))) {
        rejectArg("Valore "+x.signum) {historic(x,1,5)}
      }
    }
    check("N minore di uno o maggiore di M è respinto") {
      for(n<-Vector(BigInt(-5),BigInt(0),M+1,M*2)) {
        rejectArg("Dimensione "+n.signum) {historic(1,1,n)}
      }
    }
    check("direzioni diverse da piu o meno uno sono respinte") {
      for(d<-Vector(Int.MinValue,-2,0,2,99,Int.MaxValue)) {
        rejectArg("Direzione "+d) {historic(1,d,5)}
      }
    }
    check("una nuova chiamata non modifica il vecchio risultato") {
      val baseline=historic(M,1,5)
      for(i<-1 to 100) {
        val x=BigInt(i)
        historic(x,if(i%2==0)1 else -1,BigInt(i+1))
      }
      eqv(historic(M,1,5),baseline,"Cicatrice immutabile")
    }
    check("la soglia ammette precisamente il limite e rifiuta il successivo") {
      for(n<-Vector[BigInt](3,5,7,31,720)) {
        val bound=(M/n)*n
        truth(bound<=M,"Limite interno")
        val r=historic(bound,1,n)
        eqv(r.legacyRank,oracle(bound,1,n),"Ultimo accettato")
        if(bound<M)
          truth(historic(bound+1,1,n).firstSample>bound,
            "Rifiuto omesso")
      }
    }
    check("il campione M con N cinque devia positivamente") {
      val r=historic(M,1,5)
      truth(r.firstSample>r.acceptanceLimit,"Campione non valido")
      eqv(r.legacyRank,BigInt(2),"Rango legacy")
      eqv(oracle(M,1,5),BigInt(1),"Rango normativo")
    }
    check("il campione M con N tre devia negativamente") {
      val r=historic(M,-1,3)
      truth(r.firstSample>r.acceptanceLimit,"Campione non valido")
      eqv(r.legacyRank,BigInt(1),"Rango legacy")
      eqv(oracle(M,-1,3),BigInt(3),"Rango normativo")
    }
    check("campione M meno uno, N cinque, direzione negativa") {
      val r=historic(M-1,-1,5)
      truth(r.firstSample>r.acceptanceLimit,"Campione non valido")
      eqv(r.legacyRank,BigInt(1),"Rango legacy")
      eqv(oracle(M-1,-1,5),BigInt(5),"Rango normativo")
    }
    check("il manager espone campione, rango e limite storico") {
      val m=new BaseMonsterManager
      val r=m.discover11BiasedPick(17,-19,M,-1,3)
      eqv(r.calculationDay,BigInt(17),"Giorno calcolo")
      eqv(r.targetDay,BigInt(-19),"Giorno chiesto")
      eqv(r.firstSample,M,"Campione")
      eqv(r.directionStep,-1,"Direzione")
      eqv(r.familySize,BigInt(3),"N")
      eqv(r.legacySample,M,"Campione legacy")
      eqv(r.legacyRank,BigInt(1),"Rango legacy")
      eqv(r.acceptanceLimit,M-1,"Limite")
      eqv(r.phase,"DISCOVERY_11_BIASED_SHORT_PICK","Fase")
      eqv(r.status,"LEGACY_BIASED_PICK_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_11_BIASED_SHORT_PICK"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery11.biased.short.calls"),BigInt(1),"Discovery")
    }
    check("due invocazioni del manager rimangono isolate") {
      val m=new BaseMonsterManager
      val a=m.discover11BiasedPick(0,1,M,1,5)
      val b=m.discover11BiasedPick(2,3,M,-1,3)
      eqv(a.familySize,BigInt(5),"Prima")
      eqv(b.familySize,BigInt(3),"Seconda")
      eqv(m.metricsSnapshot("discovery11.biased.short.calls"),BigInt(2),"Metrica")
    }
    check("giorni calcolo signed enormi non alterano la selezione locale") {
      val big=(BigInt(1)<<16384)+777
      val m=new BaseMonsterManager
      val a=m.discover11BiasedPick(0,0,M,-1,3)
      val b=m.discover11BiasedPick(big,-big,M,-1,3)
      eqv(a.legacyRank,b.legacyRank,"Indipendenza dal giorno")
      eqv(b.calculationDay,big,"Giorno enorme")
    }
    check("handler respinge contesto non avviato e doppia esecuzione") {
      val h=new Discovery11BiasedPickHandler(new BaseMetricsShell)
      rejectState("NEW"){h.handle(BaseMonsterContext(1,2))}
      val c=ready()
      val sample=c.legacyBiasedRankOutput
      rejectState("Secondo uso"){h.handle(c)}
      eqv(c.legacyBiasedRankOutput,sample,"Nessuna mutazione")
    }
    check("handler rifiuta contesto avviato con input incompleto") {
      val h=new Discovery11BiasedPickHandler(new BaseMetricsShell)
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED"
      c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_11_BIASED_SHORT_PICK"
      rejectState("Input assente"){h.handle(c)}
      truth(c.legacyBiasedRankOutput.isEmpty,"Nessuna pubblicazione")
    }
    check("validator rifiuta campione, rango e limite assenti") {
      val v=new BaseValidationManager
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_11_BIASED_SHORT_PICK"
      c.status="LEGACY_BIASED_PICK_READY"
      c.selectionSampleInput=Some(M)
      c.selectionDirectionInput=Some(1)
      c.selectionFamilySizeInput=Some(5)
      rejectState("Output assente"){v.requireDiscovery11Ready(c)}
      val r=historic(M,1,5)
      c.legacyBiasedSampleOutput=Some(r.firstSample)
      c.legacyBiasedRankOutput=Some(r.legacyRank)
      c.legacyAcceptanceLimitOutput=Some(r.acceptanceLimit)
      rejectState("Traccia assente"){v.requireDiscovery11Ready(c)}
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_11_BIASED_SHORT_PICK"))
      v.requireDiscovery11Ready(c)
    }
    check("validator rifiuta rango storico contraffatto") {
      val c=ready()
      c.legacyBiasedRankOutput=Some(4)
      rejectState("Rango falsificato"){
        new BaseValidationManager().requireDiscovery11Ready(c)
      }
    }
    check("validator rifiuta limite di accettazione falsificato") {
      val c=ready()
      c.legacyAcceptanceLimitOutput=Some(M)
      rejectState("Limite falsificato"){
        new BaseValidationManager().requireDiscovery11Ready(c)
      }
    }
    check("validator rifiuta campione legacy modificato") {
      val c=ready()
      c.legacyBiasedSampleOutput=Some(M-1)
      rejectState("Campione falsificato"){
        new BaseValidationManager().requireDiscovery11Ready(c)
      }
    }
    check("validator rifiuta famiglia e direzione non valide") {
      val v=new BaseValidationManager
      val c=ready()
      c.selectionFamilySizeInput=Some(M+1)
      rejectState("Famiglia falsa"){v.requireDiscovery11Ready(c)}
      c.selectionFamilySizeInput=Some(5)
      c.selectionDirectionInput=Some(0)
      rejectState("Direzione falsa"){v.requireDiscovery11Ready(c)}
    }
    check("validator rifiuta la fase e la traccia falsificate") {
      val v=new BaseValidationManager
      val c=ready()
      c.branchTrace.remove(1)
      rejectState("Trace assente"){v.requireDiscovery11Ready(c)}
      c.branchTrace.append("DISCOVERY_11_BIASED_SHORT_PICK")
      c.phase="PATCH_11_SHORT_PICK"
      rejectState("Fase futura"){v.requireDiscovery11Ready(c)}
    }
    check("validator controlla 720 famiglie e gli estremi validi") {
      val v=new BaseValidationManager
      for(n<-1 to 720;x<-Vector(BigInt(1),BigInt(123),M-1,M)) {
        v.requireDiscovery11Ready(ready(x,1,BigInt(n)))
      }
    }
    check("le dieci patch precedenti rimangono normative") {
      val m=new BaseMonsterManager
      val f=NormativeOracle.FoundationDay
      eqv(m.patch01Save(0,0,M).patchedOutput,M,"SAVE")
      eqv(m.patch02DayTag(f,f,f).patchedTag,BigInt(1),"DayTag")
      eqv(m.patch03Distance(f,f).patchedDistance,BigInt(1),"Distance")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"Stones")
      val h=Vector[BigInt](101,202,303,404,505,606,707)
      eqv(m.patch05Prior(0,0,h,Vector.empty,1,7).patchedValue,BigInt(707),"Prior")
      eqv(m.patch06Grind(0,0,1,7,11,13,17,
        Vector[BigInt](19,23,29,31,37)).patchedValue,BigInt(422),"Grind")
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,
        Vector(6,5,4,3,2,1),"Permutation")
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),37,
        Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"Bowl freeze")
      eqv(m.patch09Vault(0,0,Vector[BigInt](11,13,17,19,23,29)).patchedBowls,
        NormativeOracle.postStir12(Vector[BigInt](11,13,17,19,23,29)),"Vault")
      eqv(m.patch10Order46(0,0,1,720,1).correctedNextBowl,6,"Latch 46")
    }
    check("oracolo test-only e cicatrice biased preservata") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val source=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!source.contains("NormativeOracle"),"Oracolo nella produzione")
      truth(source.contains("def biasedLegacyPick("),"Cicatrice reale")
      truth(source.contains("val rank=((firstSample-1)%familySize)+1"),
        "Nessuna rejection anticipata")
      val meta=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=meta.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if(current<23)
        truth(!source.contains("shortPickPatch"),"PATCH 11 anticipata")
      else
        truth(source.contains("LegacyBiasedPickAdapter.biasedLegacyPick("),
          "La PATCH deve attraversare la cicatrice")
      if(current<24)
        truth(!source.contains("LEGACY_YEAR_MAX"),"Logica futura introdotta")
      else
        truth(source.contains("LegacyYearCeilingAdapter.legacyYearMax("),
          "Discovery12 disponibile")
    }
    check("metadati Stage22 RED preservano Stage21 GREEN") {
      val state=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current>=22,"Stage22 conservato")
      if(current==22) {
        truth(state.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
        truth(state.contains("CURRENT_PATCH=10"),"Patch precedente")
        truth(state.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"RED")
      } else {
        truth(state.contains("STAGE_22_NATIVE_VERIFICATION=PASS_EXPECTED_RED_34_PASS_3_FAIL"),
          "La firma storica Stage22 rimane registrata")
      }
      truth(state.contains("STAGE_21_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_40_PASS_0_FAIL"),
        "Certificazione Stage21")
      val completed=state.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=21 && completed<=current,"Ordine certificazioni")
    }

    check("equivalenza normativa scelta positiva") {
      val old=new BaseMonsterManager().discover11BiasedPick(0,0,M,1,5)
      eqv(old.legacyRank,oracle(M,1,5),
        "Campione respinto ignorato: positiva")
    }
    check("equivalenza normativa scelta negativa") {
      val old=new BaseMonsterManager().discover11BiasedPick(0,0,M,-1,3)
      eqv(old.legacyRank,oracle(M,-1,3),
        "Campione respinto ignorato: negativa")
    }
    check("equivalenza normativa scelta soglia") {
      val old=new BaseMonsterManager().discover11BiasedPick(0,0,M-1,-1,5)
      eqv(old.legacyRank,oracle(M-1,-1,5),
        "Campione respinto ignorato: soglia")
    }
    println("\nRISULTATO STADIO 22: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
