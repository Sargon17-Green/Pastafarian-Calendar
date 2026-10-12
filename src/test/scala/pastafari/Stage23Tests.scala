package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 11: selezione senza bias, con salto esatto dei campioni rifiutati. */
object Stage23Tests {
  private var passed=0
  private var failed=0
  private val M=NormativeOracle.M

  private def check(name:String)(run: => Unit):Unit = {
    try {run;passed+=1;println("PASS — "+name)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+name+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit =
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  private def truth(ok:Boolean,label:String):Unit =
    if(!ok)throw new AssertionError(label)
  private def rejectArg(label:String)(run: => Unit):Unit = {
    var caught=false
    try run catch {case _:IllegalArgumentException => caught=true}
    truth(caught,label+": valore illegale accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit = {
    var caught=false
    try run catch {case _:IllegalStateException => caught=true}
    truth(caught,label+": contesto falso accettato")
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del progetto non trovata.")
    p
  }
  private def oracle(first:BigInt,direction:Int,n:BigInt):BigInt =
    NormativeOracle.chooseRankShort(
      NormativeOracle.AnswerStream(first,direction),n)

  // Riferimento lento ma indipendente dal wrapper: solo famiglie modeste.
  private def slow(first:BigInt,direction:Int,n:BigInt):(BigInt,BigInt,BigInt) = {
    val limit=(M/n)*n
    var current=first
    var skipped=BigInt(0)
    while(current>limit) {
      current=BigInt(1)+(((current-1+direction)%M+M)%M)
      skipped+=1
      if(skipped>BigInt(1500))
        throw new IllegalStateException("Test slow fuori dal suo dominio")
    }
    (current,((current-1)%n)+1,skipped)
  }

  private def run(first:BigInt=M,direction:Int=1,n:BigInt=5):
      Patch11ShortPickResult =
    Patch11ShortPickWrapper.shortPickPatch(first,direction,n)

  private def ready(first:BigInt=M,direction:Int=1,n:BigInt=5):
      BaseMonsterContext = {
    val c=BaseMonsterContext(1,2)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.selectionSampleInput=Some(first)
    c.selectionDirectionInput=Some(direction)
    c.selectionFamilySizeInput=Some(n)
    c.phase="DISCOVERY_11_BIASED_SHORT_PICK"
    new Discovery11BiasedPickHandler(new BaseMetricsShell).handle(c)
    c.phase="PATCH_11_SHORT_REJECTION"
    c
  }
  private def complete(first:BigInt=M,direction:Int=1,n:BigInt=5):
      BaseMonsterContext = {
    val c=ready(first,direction,n)
    new Patch11ShortPickHandler(new BaseMetricsShell).handle(c)
    c
  }

  def main(args:Array[String]):Unit = {
    check("scarto positivo M con famiglia cinque: rango corretto uno") {
      val r=run(M,1,5)
      eqv(r.historical.legacyRank,BigInt(2),"Storico")
      eqv(r.acceptedSample,BigInt(1),"Accettato")
      eqv(r.patchedRank,BigInt(1),"Corretto")
      eqv(r.skippedSamples,BigInt(1),"Scartati")
      eqv(r.patchedRank,oracle(M,1,5),"Oracolo")
    }
    check("scarto negativo M con famiglia tre: rango corretto tre") {
      val r=run(M,-1,3)
      eqv(r.historical.legacyRank,BigInt(1),"Storico")
      eqv(r.acceptedSample,M-1,"Accettato")
      eqv(r.patchedRank,BigInt(3),"Corretto")
      eqv(r.skippedSamples,BigInt(1),"Scartati")
      eqv(r.patchedRank,oracle(M,-1,3),"Oracolo")
    }
    check("scarto negativo M meno uno con famiglia cinque") {
      val r=run(M-1,-1,5)
      eqv(r.historical.legacyRank,BigInt(1),"Storico")
      eqv(r.acceptedSample,M-2,"Accettato")
      eqv(r.patchedRank,BigInt(5),"Corretto")
      eqv(r.skippedSamples,BigInt(1),"Scartati")
      eqv(r.patchedRank,oracle(M-1,-1,5),"Oracolo")
    }
    check("lo scarto negativo può saltare due campioni consecutivi") {
      val r=run(M,-1,5)
      eqv(r.acceptedSample,M-2,"Ultimo accettabile")
      eqv(r.skippedSamples,BigInt(2),"Due rifiuti")
      eqv(r.patchedRank,BigInt(5),"Rango")
      eqv(r.patchedRank,oracle(M,-1,5),"Oracolo")
    }
    check("il flusso positivo riparte ciclicamente da uno") {
      for(n<-Vector[BigInt](3,5,7,31,720)) {
        val bound=(M/n)*n
        if(bound<M) {
          val r=run(bound+1,1,n)
          eqv(r.acceptedSample,BigInt(1),"Ripresa")
          eqv(r.skippedSamples,M-bound,"Numero scartati")
          eqv(r.patchedRank,BigInt(1),"Primo rango")
        }
      }
    }
    check("il flusso negativo torna esattamente al limite") {
      for(n<-Vector[BigInt](3,5,7,31,720)) {
        val bound=(M/n)*n
        if(bound<M) {
          val r=run(M,-1,n)
          eqv(r.acceptedSample,bound,"Ultima risposta ammissibile")
          eqv(r.skippedSamples,M-bound,"Numero scartati")
          eqv(r.patchedRank,n,"Ultimo rango")
        }
      }
    }
    check("un primo campione accettato non viene mai spostato") {
      for(n<-Vector[BigInt](1,2,3,5,11,720,M);
          x<-Vector(BigInt(1),BigInt(2),BigInt(100))) {
        if(x<=(M/n)*n)
          for(direction<-Vector(-1,1)) {
            val r=run(x,direction,n)
            eqv(r.acceptedSample,x,"Campione immutato")
            eqv(r.skippedSamples,BigInt(0),"Nessun rifiuto")
            eqv(r.patchedRank,oracle(x,direction,n),"Rango corretto")
          }
      }
    }
    check("N uno rende tutto il dominio accettabile") {
      for(x<-Vector(BigInt(1),BigInt(2),M-1,M);d<-Vector(-1,1)) {
        val r=run(x,d,1)
        eqv(r.acceptedSample,x,"N=1")
        eqv(r.patchedRank,BigInt(1),"Rango unico")
        eqv(r.skippedSamples,BigInt(0),"Zero scarti")
      }
    }
    check("N=M preserva esattamente la prima risposta") {
      for(x<-Vector(BigInt(1),BigInt(2),M-1,M);d<-Vector(-1,1)) {
        val r=run(x,d,M)
        eqv(r.acceptedSample,x,"N=M")
        eqv(r.patchedRank,x,"Rango SAVE")
        eqv(r.skippedSamples,BigInt(0),"Zero scarti")
      }
    }
    check("il primo campione alla soglia è sempre ammesso") {
      for(n<-Vector[BigInt](3,5,7,31,720,M-1)) {
        val threshold=(M/n)*n
        for(direction<-Vector(-1,1)) {
          val r=run(threshold,direction,n)
          eqv(r.acceptedSample,threshold,"Confine incluso")
          eqv(r.skippedSamples,BigInt(0),"Nessun passo")
          eqv(r.patchedRank,n,"Ultimo rango")
        }
      }
    }
    check("il campione immediatamente oltre il limite viene rifiutato") {
      for(n<-Vector[BigInt](3,5,7,31,720,M-1)) {
        val threshold=(M/n)*n
        if(threshold<M) {
          val plus=run(threshold+1,1,n)
          val minus=run(threshold+1,-1,n)
          eqv(plus.acceptedSample,BigInt(1),"Plus")
          eqv(minus.acceptedSample,threshold,"Minus")
          truth(plus.skippedSamples>0&&minus.skippedSamples>0,"Scarti")
        }
      }
    }
    check("tutte le 720 cardinalità con campioni ammessi") {
      for(n<-1 to 720;d<-Vector(-1,1)) {
        val first=BigInt(20261012)
        val r=run(first,d,BigInt(n))
        eqv(r.patchedRank,oracle(first,d,BigInt(n)),"N="+n)
        eqv(r.skippedSamples,BigInt(0),"Nessun rifiuto")
      }
    }
    check("tutte le 720 cardinalità con il campione massimo") {
      for(n<-1 to 720;d<-Vector(-1,1)) {
        val r=run(M,d,BigInt(n))
        val (accepted,rank,skipped)=slow(M,d,BigInt(n))
        eqv(r.acceptedSample,accepted,"Accettazione N="+n)
        eqv(r.patchedRank,rank,"Rango N="+n)
        eqv(r.skippedSamples,skipped,"Passi N="+n)
        eqv(r.patchedRank,oracle(M,d,BigInt(n)),"Oracle N="+n)
      }
    }
    check("2048 campioni signed deterministici contro riferimento") {
      val rng=new Random(20261012L)
      for(i<-1 to 2048) {
        val x=NormativeOracle.save(BigInt(rng.nextLong())*BigInt(i))
        val n=BigInt(rng.nextInt(720)+1)
        val d=if((i&1)==0)1 else -1
        val r=run(x,d,n)
        val (accepted,rank,skipped)=slow(x,d,n)
        eqv(r.acceptedSample,accepted,"Campione "+i)
        eqv(r.patchedRank,rank,"Rango "+i)
        eqv(r.skippedSamples,skipped,"Rifiuti "+i)
        eqv(r.historical.legacyRank,((x-1)%n)+1,"Legacy "+i)
      }
    }
    check("BigInt signed oltre 16384 bit viene normalizzato senza perdita") {
      val huge=(BigInt(1)<<16384)+13
      for(x<-Vector(huge,-huge,huge*huge)) {
        val first=NormativeOracle.save(x)
        val r=run(first,-1,7)
        eqv(r.patchedRank,oracle(first,-1,7),"Rango enorme")
        eqv(r.historical.firstSample,first,"Campione")
      }
    }
    check("famiglia enorme con coda di rifiuto gigantesca non itera") {
      val n=(M/2)+1
      val bound=(M/n)*n
      val r=run(M,-1,n)
      eqv(bound,n,"Soglia gigantesca")
      eqv(r.acceptedSample,bound,"Limite accettabile")
      eqv(r.skippedSamples,M-bound,"Distanza BigInt esatta")
      eqv(r.patchedRank,n,"Ultimo rango")
      truth(r.skippedSamples>(BigInt(1)<<100),"Nessuna iterazione plausibile")
    }
    check("famiglia enorme con direzione positiva salta senza iterare") {
      val n=(M/2)+1
      val x=n+1
      val r=run(x,1,n)
      eqv(r.acceptedSample,BigInt(1),"Primo SAVE")
      eqv(r.skippedSamples,M-x+1,"Distanza esatta")
      eqv(r.patchedRank,BigInt(1),"Primo rango")
    }
    check("famiglia M meno uno richiede un solo rifiuto dal bordo") {
      for(d<-Vector(-1,1)) {
        val r=run(M,d,M-1)
        eqv(r.skippedSamples,BigInt(1),"Un solo rifiuto")
        eqv(r.patchedRank,if(d==1)BigInt(1) else M-1,"Rango")
        eqv(r.patchedRank,oracle(M,d,M-1),"Oracle")
      }
    }
    check("la cicatrice rimane il vero helper storico invocato") {
      for(n<-Vector[BigInt](1,3,5,7,720,M-1,M);
          x<-Vector(BigInt(1),BigInt(123),M-1,M);
          d<-Vector(-1,1)) {
        val r=run(x,d,n)
        eqv(r.historical,LegacyBiasedPickAdapter.biasedLegacyPick(x,d,n),
          "Cicatrice immutata")
      }
    }
    check("gli estremi invalidi del campione sono respinti") {
      for(x<-Vector(BigInt(-1),BigInt(0),M+1,(BigInt(1)<<16384)))
        rejectArg("Campione") {run(x,1,5)}
    }
    check("le dimensioni N=0, negative e maggiori di M sono respinte") {
      for(n<-Vector(BigInt(-1),BigInt(0),M+1,M*2))
        rejectArg("N") {run(1,1,n)}
    }
    check("direzione zero e multipla sono respinte") {
      for(d<-Vector(Int.MinValue,-2,0,2,99,Int.MaxValue))
        rejectArg("Direzione") {run(1,d,5)}
    }
    check("il risultato non dipende dall'intercalazione delle chiamate") {
      val baseline=run(M,-1,5)
      for(i<-1 to 100) {
        run(BigInt(i),if((i&1)==0)1 else -1,BigInt(i+1))
      }
      eqv(run(M,-1,5),baseline,"Stateless")
    }
    check("il report manager percorre il percorso storico e la PATCH") {
      val m=new BaseMonsterManager
      val r=m.patch11ShortPick(17,-19,M,1,5)
      eqv(r.calculationDay,BigInt(17),"Calcolo")
      eqv(r.targetDay,BigInt(-19),"Bersaglio")
      eqv(r.firstSample,M,"Prima risposta")
      eqv(r.directionStep,1,"Direzione")
      eqv(r.familySize,BigInt(5),"Famiglia")
      eqv(r.legacySample,M,"Legacy prima")
      eqv(r.legacyRank,BigInt(2),"Legacy rango")
      eqv(r.acceptanceLimit,M-2,"Soglia")
      eqv(r.acceptedSample,BigInt(1),"Risposta ammessa")
      eqv(r.patchedRank,BigInt(1),"Rango corretto")
      eqv(r.skippedSamples,BigInt(1),"Scarti")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_11_SHORT_REJECTION","Fase")
      eqv(r.status,"PATCH_11_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_11_BIASED_SHORT_PICK",
        "PATCH_11_SHORT_REJECTION"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery11.biased.short.calls"),BigInt(1),
        "Discovery")
      eqv(m.metricsSnapshot("patch11.short.rejection.calls"),BigInt(1),
        "Patch")
    }
    check("il report conserva il risultato della discovery indipendente") {
      val m=new BaseMonsterManager
      for((x,d,n)<-Vector(
        (M,1,BigInt(5)),(M,-1,BigInt(3)),(M-1,-1,BigInt(5)))) {
        val old=m.discover11BiasedPick(0,0,x,d,n)
        val patched=m.patch11ShortPick(0,0,x,d,n)
        eqv(patched.legacyRank,old.legacyRank,"Vecchio rango")
        eqv(patched.legacySample,old.legacySample,"Vecchio campione")
        eqv(patched.acceptanceLimit,old.acceptanceLimit,"Limite")
      }
    }
    check("due contesti consecutivi non condividono alcuna selezione") {
      val m=new BaseMonsterManager
      val a=m.patch11ShortPick(0,1,M,1,5)
      val b=m.patch11ShortPick(2,3,M,-1,3)
      eqv(a.patchedRank,BigInt(1),"A")
      eqv(b.patchedRank,BigInt(3),"B")
      eqv(m.metricsSnapshot("patch11.short.rejection.calls"),BigInt(2),
        "Doppia chiamata")
    }
    check("giorni di calcolo estremi non influiscono sul risultato locale") {
      val huge=(BigInt(1)<<16384)+777
      val m=new BaseMonsterManager
      val a=m.patch11ShortPick(0,0,M,1,5)
      val b=m.patch11ShortPick(huge,-huge,M,1,5)
      eqv(a.patchedRank,b.patchedRank,"Giorno neutrale")
      eqv(b.calculationDay,huge,"Giorno estremo")
      eqv(b.targetDay,-huge,"Bersaglio estremo")
    }
    check("handler rifiuta NEW e Bootstrap non avanzato alla discovery") {
      val h=new Patch11ShortPickHandler(new BaseMetricsShell)
      rejectState("NEW"){h.handle(BaseMonsterContext(0,0))}
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED"
      c.branchTrace.append("BOOT")
      c.selectionSampleInput=Some(M)
      c.selectionDirectionInput=Some(1)
      c.selectionFamilySizeInput=Some(5)
      rejectState("Senza discovery"){h.handle(c)}
      truth(c.patchedShortPickRank.isEmpty,"Nessuna pubblicazione")
    }
    check("handler rifiuta doppia applicazione senza mutare i dati") {
      val h=new Patch11ShortPickHandler(new BaseMetricsShell)
      val c=ready()
      h.handle(c)
      val old=c.patchedShortPickRank
      rejectState("Doppia applicazione"){h.handle(c)}
      eqv(c.patchedShortPickRank,old,"Output stabile")
    }
    check("validator rifiuta stato patch senza i risultati") {
      val c=ready()
      c.phase="PATCH_11_SHORT_REJECTION"
      c.status="PATCH_11_READY"
      c.patch11Applied=true
      c.branchTrace.append("PATCH_11_SHORT_REJECTION")
      rejectState("Output assente"){
        new BaseValidationManager().requirePatch11Ready(c)
      }
    }
    check("validator certifica 720 famiglie e tutti gli estremi") {
      val v=new BaseValidationManager
      val h=new Patch11ShortPickHandler(new BaseMetricsShell)
      for(n<-1 to 720;x<-Vector(BigInt(1),BigInt(123),M-1,M);
          d<-Vector(-1,1)) {
        val c=ready(x,d,BigInt(n))
        h.handle(c)
        v.requirePatch11Ready(c)
      }
    }
    check("validator accetta uno scarto astronomico e non itera") {
      val v=new BaseValidationManager
      val c=complete(M,-1,(M/2)+1)
      v.requirePatch11Ready(c)
      truth(c.patchedSkippedSamples.get>(BigInt(1)<<100),"BigInt")
    }
    check("validator rifiuta un campione accettato contraffatto") {
      val c=complete()
      c.patchedAcceptedSample=Some(BigInt(2))
      rejectState("Accettato falso"){
        new BaseValidationManager().requirePatch11Ready(c)
      }
    }
    check("validator rifiuta un rango patched contraffatto") {
      val c=complete()
      c.patchedShortPickRank=Some(BigInt(2))
      rejectState("Rango falso"){
        new BaseValidationManager().requirePatch11Ready(c)
      }
    }
    check("validator rifiuta il contatore di campioni saltati falsificato") {
      val c=complete()
      c.patchedSkippedSamples=Some(BigInt(0))
      rejectState("Contatore falso"){
        new BaseValidationManager().requirePatch11Ready(c)
      }
    }
    check("validator rifiuta il vecchio rango adulterato") {
      val c=complete()
      c.legacyBiasedRankOutput=Some(BigInt(3))
      rejectState("Legacy contraffatto"){
        new BaseValidationManager().requirePatch11Ready(c)
      }
    }
    check("validator rifiuta la vecchia soglia contraffatta") {
      val c=complete()
      c.legacyAcceptanceLimitOutput=Some(M)
      rejectState("Limite falso"){
        new BaseValidationManager().requirePatch11Ready(c)
      }
    }
    check("validator rifiuta la mutazione di input e direzione") {
      val v=new BaseValidationManager
      val c=complete()
      c.selectionDirectionInput=Some(-1)
      rejectState("Direzione mutata"){v.requirePatch11Ready(c)}
      c.selectionDirectionInput=Some(1)
      c.selectionSampleInput=Some(M-1)
      rejectState("Campione mutato"){v.requirePatch11Ready(c)}
    }
    check("validator rifiuta il flag falso e la traccia falsa") {
      val v=new BaseValidationManager
      val c=complete()
      c.patch11Applied=false
      rejectState("Flag falso"){v.requirePatch11Ready(c)}
      c.patch11Applied=true
      c.branchTrace.remove(1)
      rejectState("Traccia alterata"){v.requirePatch11Ready(c)}
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
        NormativeOracle.postStir12(Vector[BigInt](11,13,17,19,23,29)),
        "Vault")
      eqv(m.patch10Order46(0,0,1,720,1).correctedNextBowl,6,"Latch 46")
    }
    check("oracolo test-only e cicatrice storica reale") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val source=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!source.contains("NormativeOracle"),"Oracolo nella produzione")
      truth(source.contains("val rank=((firstSample-1)%familySize)+1"),
        "Cicatrice storica intatta")
      truth(source.contains("LegacyBiasedPickAdapter.biasedLegacyPick("),
        "La patch attraversa il legacy")
      truth(source.contains("val limit=historical.acceptanceLimit"),
        "Soglia di accettazione reale")
      val state=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if(current<24)
        truth(!source.contains("LEGACY_YEAR_MAX"),"Stage24 anticipato")
      else
        truth(source.contains("LegacyYearCeilingAdapter.legacyYearMax("),
          "Discovery12 storica disponibile")
    }
    check("Stage23 GREEN preserva le firme native degli stadi 21/22") {
      val state=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current>=23,"Stage23 certificato")
      if(current==23) {
        truth(state.contains("CURRENT_KIND=PATCH"),"Tipo")
        truth(state.contains("CURRENT_PATCH=11"),"Patch")
        truth(state.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"GREEN")
      } else {
        truth(state.contains("STAGE_23_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_42_PASS_0_FAIL"),
          "Certificazione dello Stage23")
      }
      truth(state.contains("STAGE_22_NATIVE_VERIFICATION=PASS_EXPECTED_RED_34_PASS_3_FAIL"),
        "Stage22 RED storico")
      truth(state.contains("STAGE_21_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_40_PASS_0_FAIL"),
        "Stage21 GREEN")
      val completed=state.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=22 && completed<=current,"Ordine certificazioni")
    }
    println("\nRISULTATO STADIO 23: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
