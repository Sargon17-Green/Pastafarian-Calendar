package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 10: il vicino normativo segue la goccia 46, non la 45. */
object Stage21Tests {
  private var passed=0
  private var failed=0
  private val M=NormativeOracle.M
  private val First=BigInt(1)
  private val Last=BigInt(720)

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
    var rejected=false
    try run catch {case _:IllegalArgumentException => rejected=true}
    truth(rejected,label+": parametro non valido accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit = {
    var rejected=false
    try run catch {case _:IllegalStateException => rejected=true}
    truth(rejected,label+": stato non valido accettato")
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del progetto assente")
    p
  }
  private def expectedOrder(drop:BigInt):Vector[Int] =
    NormativeOracle.bowlOrderFromDrop(drop)

  // Riferimento test-only: stesso next dopo le dodici mescolature.
  private def normativeNext(drop:BigInt,queried:Int):Int = {
    val sauce=NormativeOracle.SauceResult(
      Vector.fill[BigInt](6)(1),expectedOrder(drop))
    NormativeOracle.nextBowlInDrop46Order(sauce,queried)
  }
  private def ready(drop45:BigInt=First,drop46:BigInt=Last,
                    queried:Int=1):BaseMonsterContext = {
    val c=BaseMonsterContext(1,2)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.penultimateDropValue=Some(drop45)
    c.finalDropValue=Some(drop46)
    c.queriedBowlInput=Some(queried)
    c.phase="DISCOVERY_10_ORDER46_LATCH"
    new Discovery10Order46LatchHandler(new BaseMetricsShell).handle(c)
    c.phase="PATCH_10_ORDER46_FREEZE"
    c
  }
  private def complete(
    drop45:BigInt=First,drop46:BigInt=Last,queried:Int=1
  ):BaseMonsterContext = {
    val c=ready(drop45,drop46,queried)
    new Patch10Order46Handler(new BaseMetricsShell).handle(c)
    c
  }

  def main(args:Array[String]):Unit = {
    check("l'ordine diretto ha il successore normativo inverso") {
      val r=Patch10Order46Wrapper.order46Patch(First,Last,1)
      eqv(r.historical.order45,Vector(1,2,3,4,5,6),"Goccia 45")
      eqv(r.latchedOrder46,Vector(6,5,4,3,2,1),"Goccia 46")
      eqv(r.historical.legacyNextBowl,2,"Legacy")
      eqv(r.correctedNextBowl,6,"Corretto")
    }
    check("l'ordine inverso ha il successore normativo diretto") {
      val r=Patch10Order46Wrapper.order46Patch(Last,First,1)
      eqv(r.historical.legacyNextBowl,6,"Legacy")
      eqv(r.correctedNextBowl,2,"Corretto")
    }
    check("il terzo caso della discovery resta distinguibile") {
      val r=Patch10Order46Wrapper.order46Patch(123,456,3)
      eqv(r.historical.legacyNextBowl,5,"Legacy")
      eqv(r.correctedNextBowl,2,"Corretto")
    }
    check("il nuovo latch contiene esattamente l'ordine 46") {
      for(rank<-Vector(1,2,3,6,17,120,121,360,719,720)) {
        val r=Patch10Order46Wrapper.order46Patch(1,rank,1)
        eqv(r.latchedOrder46,expectedOrder(BigInt(rank)),"Rango "+rank)
      }
    }
    check("il latch storico resta quello originale senza modifiche") {
      for((a,b,q)<-Vector((1,720,1),(720,1,1),(123,456,3),(721,1,6))) {
        val r=Patch10Order46Wrapper.order46Patch(a,b,q)
        eqv(r.historical,
          LegacyOrder46LatchAdapter.orderAt46Latch(a,b,q),"Cicatrice")
      }
    }
    check("il wrapper attraversa la cicatrice anche per ordini uguali") {
      for(rank<-Vector(1,2,6,121,360,720);id<-1 to 6) {
        val r=Patch10Order46Wrapper.order46Patch(rank,rank,id)
        eqv(r.correctedNextBowl,r.historical.legacyNextBowl,
          "Stesso ordine non distingue")
      }
    }
    check("il successore nell'ordine 46 segue il ciclo con ritorno") {
      for(id<-1 to 6) {
        val r=Patch10Order46Wrapper.order46Patch(1,720,id)
        val expected=if(id==1)6 else id-1
        eqv(r.correctedNextBowl,expected,"ID "+id)
      }
    }
    check("il prossimo ID della ciotola non è mai quello interrogato") {
      for(rank<-1 to 720;id<-1 to 6) {
        val r=Patch10Order46Wrapper.order46Patch(rank,721-rank,id)
        truth(r.correctedNextBowl!=id,"ID "+id)
      }
    }
    check("due ordini diversi possono dare lo stesso successore") {
      val r=Patch10Order46Wrapper.order46Patch(1,2,3)
      eqv(r.correctedNextBowl,normativeNext(2,3),"Normativo")
    }
    check("720 ordini di goccia 46 e sei ID equivalgono all'oracolo") {
      for(rank<-1 to 720;id<-1 to 6) {
        val r=Patch10Order46Wrapper.order46Patch(1,rank,id)
        eqv(r.latchedOrder46,expectedOrder(BigInt(rank)),"Ordine "+rank)
        eqv(r.correctedNextBowl,normativeNext(BigInt(rank),id),
          "Rango "+rank+" ID "+id)
      }
    }
    check("720 ranghi di goccia 45 conservano la cicatrice") {
      for(rank<-1 to 720) {
        val r=Patch10Order46Wrapper.order46Patch(rank,720,1)
        eqv(r.historical.order45,expectedOrder(BigInt(rank)),"Rango vecchio")
        eqv(r.historical.legacyNextBowl,
          normativeNext(BigInt(rank),1),"Successore legacy")
      }
    }
    check("tutti i 720 ranghi al confine del modulo sono corretti") {
      for(rank<-1 to 720) {
        val r=Patch10Order46Wrapper.order46Patch(rank+720,rank-720,4)
        eqv(r.correctedNextBowl,normativeNext(BigInt(rank),4),"Modulo")
      }
    }
    check("i ranghi negativi usano il modulo regolare 1-based") {
      for((a,b)<-Vector((-1,-2),(-720,-721),(-721,-1440),(-999,-500))) {
        val r=Patch10Order46Wrapper.order46Patch(a,b,3)
        eqv(r.latchedOrder46,expectedOrder(BigInt(b)),"Permutazione")
        eqv(r.correctedNextBowl,normativeNext(BigInt(b),3),"Next")
      }
    }
    check("multipli di M e confini SAVE non alterano i ranghi") {
      for((a,b)<-Vector((M,M+1),(M+1,-M),(M*2,M*3))) {
        val r=Patch10Order46Wrapper.order46Patch(a,b,6)
        eqv(r.correctedNextBowl,normativeNext(b,6),"Bordo")
      }
    }
    check("BigInt signed sopra 16384 bit non perde dati") {
      val big=(BigInt(1)<<16384)+91
      for((a,b)<-Vector((big,-big),(-big,big+1),(big*big,-big*big))) {
        val r=Patch10Order46Wrapper.order46Patch(a,b,2)
        eqv(r.latchedOrder46,expectedOrder(b),"Ordine enorme")
        eqv(r.correctedNextBowl,normativeNext(b,2),"Next enorme")
      }
    }
    check("1024 coppie deterministiche signed mantengono la norma") {
      val rng=new Random(20261012L)
      for(i<-1 to 1024) {
        val d45=BigInt(rng.nextLong())*i-rng.nextInt(720)
        val d46=BigInt(rng.nextLong())*i+rng.nextInt(720)
        val id=rng.nextInt(6)+1
        val r=Patch10Order46Wrapper.order46Patch(d45,d46,id)
        eqv(r.historical,LegacyOrder46LatchAdapter.orderAt46Latch(
          d45,d46,id),"Legacy campione "+i)
        eqv(r.latchedOrder46,expectedOrder(d46),"Ordine campione "+i)
        eqv(r.correctedNextBowl,normativeNext(d46,id),"Next campione "+i)
      }
    }
    check("il risultato non dipende dall'intercalazione di altre chiamate") {
      val baseline=Patch10Order46Wrapper.order46Patch(123,456,3)
      for(i<-1 to 90)Patch10Order46Wrapper.order46Patch(i,721-i,(i%6)+1)
      eqv(Patch10Order46Wrapper.order46Patch(123,456,3),baseline,
        "Nessun dato statico condiviso")
    }
    check("i sei ID fuori intervallo sono respinti") {
      for(id<-Vector(Int.MinValue,-99,-1,0,7,Int.MaxValue))
        rejectArg("ID "+id){Patch10Order46Wrapper.order46Patch(1,720,id)}
    }
    check("il risultato resta valido dopo 12 mescolature finali") {
      val old=Vector[BigInt](11,13,17,19,23,29)
      val finalBowls=NormativeOracle.postStir12(old)
      val r=Patch10Order46Wrapper.order46Patch(1,720,1)
      val sauce=NormativeOracle.SauceResult(finalBowls,r.latchedOrder46)
      eqv(NormativeOracle.nextBowlInDrop46Order(sauce,1),6,
        "Il caveau non modifica il latch")
      eqv(r.correctedNextBowl,6,"La PATCH usa il medesimo latch")
    }
    check("il primo valore di askBowl usa davvero il successore corretto") {
      val bowls=Vector[BigInt](11,13,17,19,23,29)
      val r=Patch10Order46Wrapper.order46Patch(1,720,1)
      val sauce=NormativeOracle.SauceResult(bowls,r.latchedOrder46)
      val ans=NormativeOracle.askBowl(sauce,1,NormativeOracle.SealGateGap)
      val q=bowls(0)
      val n=bowls(r.correctedNextBowl-1)
      val expected=NormativeOracle.save(
        (q+NormativeOracle.SealGateGap+181).pow(2)+
        179*n+NormativeOracle.SealGateGap)
      eqv(ans.first,expected,"Primo valore")
    }
    check("manager attraversa davvero Bootstrap, discovery e patch") {
      val m=new BaseMonsterManager
      val r=m.patch10Order46(17,-19,1,720,1)
      eqv(r.calculationDay,BigInt(17),"Giorno calcolo")
      eqv(r.targetDay,BigInt(-19),"Giorno chiesto")
      eqv(r.drop45,BigInt(1),"Goccia 45")
      eqv(r.drop46,BigInt(720),"Goccia 46")
      eqv(r.queriedBowlId,1,"ID")
      eqv(r.legacyOrder45,Vector(1,2,3,4,5,6),"Storico")
      eqv(r.observedOrder46,Vector(6,5,4,3,2,1),"Osservato")
      eqv(r.legacyNextBowl,2,"Vicino sbagliato")
      eqv(r.latchedOrder46,Vector(6,5,4,3,2,1),"Latch nuovo")
      eqv(r.correctedNextBowl,6,"Vicino corretto")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_10_ORDER46_FREEZE","Fase")
      eqv(r.status,"PATCH_10_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_10_ORDER46_LATCH",
        "PATCH_10_ORDER46_FREEZE"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery10.order46.latch.calls"),
        BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch10.order46.freeze.calls"),BigInt(1),"Patch")
    }
    check("manager preserva gli stessi dati della discovery indipendente") {
      val m=new BaseMonsterManager
      for((a,b,q)<-Vector((1,720,1),(720,1,1),(123,456,3))) {
        val disc=m.discover10Order46Latch(0,0,a,b,q)
        val patched=m.patch10Order46(0,0,a,b,q)
        eqv(patched.legacyOrder45,disc.legacyOrder45,"Ordine")
        eqv(patched.observedOrder46,disc.observedOrder46,"Osservato")
        eqv(patched.legacyNextBowl,disc.legacyNextBowl,"Next legacy")
      }
    }
    check("manager tiene separate due invocazioni nello stesso oggetto") {
      val m=new BaseMonsterManager
      val a=m.patch10Order46(1,2,1,720,1)
      val b=m.patch10Order46(3,4,720,1,1)
      eqv(a.correctedNextBowl,6,"A")
      eqv(b.correctedNextBowl,2,"B")
      eqv(m.metricsSnapshot("patch10.order46.freeze.calls"),BigInt(2),
        "Due invocazioni")
    }
    check("giorni di calcolo enormi non influenzano il latch locale") {
      val huge=(BigInt(1)<<16384)+37
      val m=new BaseMonsterManager
      val a=m.patch10Order46(0,0,1,720,1)
      val b=m.patch10Order46(huge,-huge,1,720,1)
      eqv(a.correctedNextBowl,b.correctedNextBowl,"Indipendenza")
      eqv(b.calculationDay,huge,"Giorno enorme")
      eqv(b.targetDay,-huge,"Giorno chiesto enorme")
    }
    check("handler respinge l'uso prima di Bootstrap o della discovery") {
      val h=new Patch10Order46Handler(new BaseMetricsShell)
      rejectState("NEW"){h.handle(BaseMonsterContext(1,2))}
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.penultimateDropValue=Some(1);c.finalDropValue=Some(720)
      c.queriedBowlInput=Some(1)
      rejectState("BOOT isolato"){h.handle(c)}
      truth(c.patchedNextBowlOutput.isEmpty,"Nessuna pubblicazione")
    }
    check("handler rifiuta la doppia patch senza mutare il risultato") {
      val h=new Patch10Order46Handler(new BaseMetricsShell)
      val c=ready()
      h.handle(c)
      val old=c.patchedNextBowlOutput
      rejectState("Seconda patch"){h.handle(c)}
      eqv(c.patchedNextBowlOutput,old,"Conservazione")
    }
    check("validator rifiuta output patch assente") {
      val v=new BaseValidationManager
      val c=ready()
      c.phase="PATCH_10_ORDER46_FREEZE"
      c.status="PATCH_10_READY";c.patch10Applied=true
      c.branchTrace.append("PATCH_10_ORDER46_FREEZE")
      rejectState("Nessuna PATCH"){v.requirePatch10Ready(c)}
    }
    check("validator autonomo certifica tutti i 720 ranghi e sei ID") {
      val v=new BaseValidationManager
      val h=new Patch10Order46Handler(new BaseMetricsShell)
      for(rank<-1 to 720;id<-1 to 6) {
        val c=ready(rank,721-rank,id)
        h.handle(c)
        v.requirePatch10Ready(c)
      }
    }
    check("validator rifiuta un ordine 46 patched falso") {
      val v=new BaseValidationManager
      val c=complete()
      c.patchedLatchedOrder46=Some(Vector(1,2,3,4,5,6))
      rejectState("Ordine patched"){v.requirePatch10Ready(c)}
    }
    check("validator rifiuta un successore patched falsificato") {
      val v=new BaseValidationManager
      val c=complete()
      c.patchedNextBowlOutput=Some(2)
      rejectState("Next patched"){v.requirePatch10Ready(c)}
    }
    check("validator rifiuta un ordine storico modificato") {
      val v=new BaseValidationManager
      val c=complete()
      c.legacyLatchedOrder45=Some(Vector(6,5,4,3,2,1))
      rejectState("Vecchio ordine"){v.requirePatch10Ready(c)}
    }
    check("validator rifiuta il successore storico modificato") {
      val v=new BaseValidationManager
      val c=complete()
      c.legacyNextBowlOutput=Some(6)
      rejectState("Next legacy"){v.requirePatch10Ready(c)}
    }
    check("validator rifiuta la contraffazione dell'ordine osservato") {
      val v=new BaseValidationManager
      val c=complete()
      c.observedOrder46=Some(Vector(1,2,3,4,5,6))
      rejectState("Ordine osservato"){v.requirePatch10Ready(c)}
    }
    check("validator rifiuta il cambio del drop 45 dopo la patch") {
      val v=new BaseValidationManager
      val c=complete()
      c.penultimateDropValue=Some(719)
      rejectState("Drop45 modificato"){v.requirePatch10Ready(c)}
    }
    check("validator rifiuta il cambio del drop 46 dopo la patch") {
      val v=new BaseValidationManager
      val c=complete()
      c.finalDropValue=Some(719)
      rejectState("Drop46 modificato"){v.requirePatch10Ready(c)}
    }
    check("validator rifiuta il cambio dell'ID richiesto") {
      val v=new BaseValidationManager
      val c=complete()
      c.queriedBowlInput=Some(2)
      rejectState("ID richiesto modificato"){v.requirePatch10Ready(c)}
    }
    check("validator rifiuta il flag falso e la traccia falsa") {
      val v=new BaseValidationManager
      val c=complete()
      c.patch10Applied=false
      rejectState("Flag falso"){v.requirePatch10Ready(c)}
      c.patch10Applied=true
      c.branchTrace.remove(1)
      rejectState("Traccia falsa"){v.requirePatch10Ready(c)}
    }
    check("le nove patch precedenti rimangono normative") {
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
    }
    check("oracolo test-only e latch storico realmente preservato") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val source=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!source.contains("NormativeOracle"),"Oracolo nel prodotto")
      truth(source.contains("val captured = order45"),"Cicatrice non cancellata")
      truth(source.contains("LegacyOrder46LatchAdapter.orderAt46Latch("),
        "La PATCH attraversa la vera cicatrice")
      truth(source.contains("val captured = Patch07PermutationWrapper.permutationPatch(finalRank)"),
        "Il latch normativo usa la vera goccia 46")
      val metadata=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=metadata.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if(current<22)
        truth(!source.contains("biasedLegacyPick"),"Stage22 anticipato")
      else
        truth(source.contains("LegacyBiasedPickAdapter.biasedLegacyPick("),
          "La discovery di selezione corta è disponibile")
    }
    check("metadati Stage21 GREEN preservano Stage20 RED") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current>=21,"Stage 21 disponibile")
      if(current==21) {
        truth(st.contains("CURRENT_KIND=PATCH"),"Tipo")
        truth(st.contains("CURRENT_PATCH=10"),"Patch")
        truth(st.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"GREEN")
      } else {
        truth(st.contains("STAGE_21_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_40_PASS_0_FAIL"),
          "La certificazione Stage21 deve essere conservata")
      }
      truth(st.contains("STAGE_20_NATIVE_VERIFICATION=PASS_EXPECTED_RED_26_PASS_3_FAIL"),
        "Certificazione Stage20")
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=20&&completed<=current,"Certificazione cronologica")
    }
    println("\nRISULTATO STADIO 21: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
