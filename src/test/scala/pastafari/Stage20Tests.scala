package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 10: latch vecchio della goccia 45, invece della goccia 46. */
object Stage20Tests {
  private var passed=0
  private var failed=0
  private val M=NormativeOracle.M
  private def check(label:String)(f: => Unit):Unit = {
    try { f;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit =
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  private def truth(c:Boolean,label:String):Unit =
    if(!c)throw new AssertionError(label)
  private def rejectArg(label:String)(f: => Unit):Unit = {
    var seen=false
    try f catch {case _:IllegalArgumentException => seen=true}
    truth(seen,"Parametro non valido accettato: "+label)
  }
  private def rejectState(label:String)(f: => Unit):Unit = {
    var seen=false
    try f catch {case _:IllegalStateException => seen=true}
    truth(seen,"Stato non valido accettato: "+label)
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del progetto assente.")
    p
  }
  private def expectedOrder(drop:BigInt):Vector[Int] =
    NormativeOracle.bowlOrderFromDrop(drop)
  private def next(order:Vector[Int],id:Int):Int = {
    val p=order.indexOf(id)
    require(p>=0,"ID non nell'ordine")
    order((p+1)%6)
  }
  private def ready(drop45:BigInt=BigInt(1),drop46:BigInt=BigInt(720),
                    queried:Int=1):BaseMonsterContext = {
    val c=BaseMonsterContext(1,2)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.penultimateDropValue=Some(drop45)
    c.finalDropValue=Some(drop46)
    c.queriedBowlInput=Some(queried)
    c.phase="DISCOVERY_10_ORDER46_LATCH"
    new Discovery10Order46LatchHandler(new BaseMetricsShell).handle(c)
    c
  }
  def main(args:Array[String]):Unit = {
    check("il latch autentico riusa l'ordine della goccia 45") {
      val r=LegacyOrder46LatchAdapter.orderAt46Latch(1,720,1)
      eqv(r.order45,Vector(1,2,3,4,5,6),"Ordine goccia 45")
      eqv(r.order46,Vector(6,5,4,3,2,1),"Ordine goccia 46")
      eqv(r.legacyNextBowl,2,"Successore legacy")
    }
    check("la goccia 46 non viene confusa con le ultime dodici mescolature") {
      val initial=Vector[BigInt](11,13,17,19,23,29)
      val vault=NormativeOracle.postStir12(initial)
      val r=LegacyOrder46LatchAdapter.orderAt46Latch(1,720,1)
      truth(vault.length==6,"Sei ciotole finali")
      eqv(r.order46,NormativeOracle.bowlOrderFromDrop(BigInt(720)),
        "La fotografia del quarantaseiesimo ordine rimane disponibile")
    }
    check("le due permutazioni diagnostiche sono complete e indipendenti") {
      val r=LegacyOrder46LatchAdapter.orderAt46Latch(1,720,3)
      eqv(r.order45.sorted,Vector(1,2,3,4,5,6),"45")
      eqv(r.order46.sorted,Vector(1,2,3,4,5,6),"46")
      truth(r.order45!=r.order46,"Distinzione")
    }
    check("quando i ranghi coincidono il latch non inventa la differenza") {
      for(rank<-Vector(1,2,6,121,360,720);id<-1 to 6) {
        val r=LegacyOrder46LatchAdapter.orderAt46Latch(rank,rank,id)
        eqv(r.legacyNextBowl,next(expectedOrder(BigInt(rank)),id),"Stesso ordine")
      }
    }
    check("il vicino legacy rispetta il ciclo incluso l'ultimo elemento") {
      for(id<-1 to 6) {
        val r=LegacyOrder46LatchAdapter.orderAt46Latch(1,720,id)
        eqv(r.legacyNextBowl,if(id==6)1 else id+1,"Ciclo storico")
      }
    }
    check("la scelta del rango negativo applica modulo regolare") {
      for((old,last)<-Vector((-1,-721),(-720,-1440),(-2,-3))) {
        val r=LegacyOrder46LatchAdapter.orderAt46Latch(old,last,1)
        eqv(r.order45,expectedOrder(BigInt(old)),"Modulo 45")
        eqv(r.order46,expectedOrder(BigInt(last)),"Modulo 46")
      }
    }
    check("la scelta del rango con BigInt enorme non tronca i bit") {
      val huge=(BigInt(1)<<16384)+57
      val r=LegacyOrder46LatchAdapter.orderAt46Latch(huge,-huge,4)
      eqv(r.order45,expectedOrder(huge),"BigInt45")
      eqv(r.order46,expectedOrder(-huge),"BigInt46")
    }
    check("tutti i 720 ranghi delle due gocce sono unranking normativo") {
      for(rank<-1 to 720) {
        val r=LegacyOrder46LatchAdapter.orderAt46Latch(rank,721-rank,1)
        eqv(r.order45,expectedOrder(BigInt(rank)),"45 rango "+rank)
        eqv(r.order46,expectedOrder(BigInt(721-rank)),"46 rango "+rank)
      }
    }
    check("tutti i 720 ranghi e sei ID danno il vicino storico previsto") {
      for(rank<-1 to 720;id<-1 to 6) {
        val r=LegacyOrder46LatchAdapter.orderAt46Latch(rank,720,id)
        eqv(r.legacyNextBowl,next(expectedOrder(BigInt(rank)),id),
          "Rango "+rank+" ID "+id)
      }
    }
    check("1024 coppie di BigInt signed deterministiche") {
      val rng=new Random(20261012L)
      for(i<-1 to 1024) {
        val a=BigInt(rng.nextLong())*BigInt(i)
        val b=BigInt(rng.nextLong())-BigInt(i*i)
        val id=rng.nextInt(6)+1
        val r=LegacyOrder46LatchAdapter.orderAt46Latch(a,b,id)
        eqv(r.order45,expectedOrder(a),"Coppia "+i+" ordine45")
        eqv(r.order46,expectedOrder(b),"Coppia "+i+" ordine46")
        eqv(r.legacyNextBowl,next(expectedOrder(a),id),"Coppia "+i+" next")
      }
    }
    check("il latch non dipende dall'ordine delle chiamate") {
      val baseline=LegacyOrder46LatchAdapter.orderAt46Latch(123,560,2)
      for(i<-1 to 90)
        LegacyOrder46LatchAdapter.orderAt46Latch(i,721-i,(i%6)+1)
      eqv(LegacyOrder46LatchAdapter.orderAt46Latch(123,560,2),baseline,
        "Determinismo")
    }
    check("ID zero e sette sono rifiutati") {
      for(id<-Vector(Int.MinValue,-12,0,7,17,Int.MaxValue))
        rejectArg("ID "+id) {
          LegacyOrder46LatchAdapter.orderAt46Latch(1,720,id)
        }
    }
    check("manager attraversa Bootstrap e DISCOVERY 10 realmente") {
      val m=new BaseMonsterManager
      val r=m.discover10Order46Latch(111,-222,1,720,1)
      eqv(r.calculationDay,BigInt(111),"Giorno del calcolo")
      eqv(r.targetDay,BigInt(-222),"Giorno richiesto")
      eqv(r.drop45,BigInt(1),"Goccia45")
      eqv(r.drop46,BigInt(720),"Goccia46")
      eqv(r.queriedBowlId,1,"ID")
      eqv(r.legacyOrder45,Vector(1,2,3,4,5,6),"Latched")
      eqv(r.observedOrder46,Vector(6,5,4,3,2,1),"Observed")
      eqv(r.legacyNextBowl,2,"Legacy next")
      eqv(r.phase,"DISCOVERY_10_ORDER46_LATCH","Fase")
      eqv(r.status,"LEGACY_ORDER46_LATCH_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_10_ORDER46_LATCH"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery10.order46.latch.calls"),BigInt(1),"Metrica")
    }
    check("un unico manager isola due invocazioni diverse") {
      val m=new BaseMonsterManager
      val a=m.discover10Order46Latch(1,2,1,720,1)
      val b=m.discover10Order46Latch(3,4,720,1,1)
      eqv(a.legacyNextBowl,2,"A")
      eqv(b.legacyNextBowl,6,"B")
      eqv(m.metricsSnapshot("discovery10.order46.latch.calls"),BigInt(2),"Metrica")
    }
    check("giorni arbitrariamente grandi non alterano i ranghi locali") {
      val huge=(BigInt(1)<<16384)+777
      val m=new BaseMonsterManager
      val a=m.discover10Order46Latch(0,0,1,720,4)
      val b=m.discover10Order46Latch(huge,-huge,1,720,4)
      eqv(a.legacyNextBowl,b.legacyNextBowl,"Giorno neutrale")
      eqv(b.targetDay,-huge,"Giorno enorme")
    }
    check("validator rifiuta output e traccia mancanti") {
      val v=new BaseValidationManager
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_10_ORDER46_LATCH"
      c.status="LEGACY_ORDER46_LATCH_READY"
      c.penultimateDropValue=Some(1)
      c.finalDropValue=Some(720)
      c.queriedBowlInput=Some(1)
      rejectState("Nessun output"){v.requireDiscovery10Ready(c)}
      val old=LegacyOrder46LatchAdapter.orderAt46Latch(1,720,1)
      c.legacyLatchedOrder45=Some(old.order45)
      c.observedOrder46=Some(old.order46)
      c.legacyNextBowlOutput=Some(old.legacyNextBowl)
      rejectState("Senza traccia"){v.requireDiscovery10Ready(c)}
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_10_ORDER46_LATCH"))
      v.requireDiscovery10Ready(c)
    }
    check("validator rifiuta il latch storico falsificato") {
      val v=new BaseValidationManager
      val c=ready()
      c.legacyLatchedOrder45=Some(Vector(6,5,4,3,2,1))
      rejectState("Latch falso"){v.requireDiscovery10Ready(c)}
    }
    check("validator rifiuta il vero ordine 46 falsificato") {
      val v=new BaseValidationManager
      val c=ready()
      c.observedOrder46=Some(Vector(1,2,3,4,5,6))
      rejectState("Ordine 46 falso"){v.requireDiscovery10Ready(c)}
    }
    check("validator rifiuta ID successore falsificato") {
      val v=new BaseValidationManager
      val c=ready()
      c.legacyNextBowlOutput=Some(6)
      rejectState("Next alterato"){v.requireDiscovery10Ready(c)}
    }
    check("validator rifiuta cambio di richiesta dopo la discovery") {
      val v=new BaseValidationManager
      val c=ready()
      c.queriedBowlInput=Some(2)
      rejectState("ID richiesto cambiato"){v.requireDiscovery10Ready(c)}
    }
    check("validator rifiuta cambio dei valori della goccia 46") {
      val v=new BaseValidationManager
      val c=ready()
      c.finalDropValue=Some(719)
      rejectState("Drop46 cambiato"){v.requireDiscovery10Ready(c)}
    }
    check("handler respinge assenza di Bootstrap e doppia chiamata") {
      val h=new Discovery10Order46LatchHandler(new BaseMetricsShell)
      val c=BaseMonsterContext(1,2)
      rejectState("Bootstrap assente"){h.handle(c)}
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.penultimateDropValue=Some(1)
      c.finalDropValue=Some(720);c.queriedBowlInput=Some(1)
      c.phase="DISCOVERY_10_ORDER46_LATCH"
      h.handle(c)
      val before=c.legacyNextBowlOutput
      rejectState("Doppio uso"){h.handle(c)}
      eqv(c.legacyNextBowlOutput,before,"Output stabile")
    }
    check("validator verifica tutti i 720 ranghi e sei ciotole") {
      val v=new BaseValidationManager
      for(rank<-1 to 720;id<-1 to 6) {
        v.requireDiscovery10Ready(ready(rank,721-rank,id))
      }
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
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,Vector(6,5,4,3,2,1),
        "Permutation")
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),
        37,Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"Bowl freeze")
      val r=m.patch09Vault(0,0,Vector[BigInt](11,13,17,19,23,29))
      eqv(r.patchedBowls,
        NormativeOracle.postStir12(Vector[BigInt](11,13,17,19,23,29)),
        "Vault")
    }
    check("oracle resta test-only e nessuna PATCH 10 viene introdotta") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo produzione")
      truth(sources.contains("val captured = order45"),"Latching storico reale")
      truth(sources.contains("LegacyOrder46LatchAdapter.orderAt46Latch("),
        "Helper storico richiamato nel manager")
      val state=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if(current<21)
        truth(!sources.contains("order46Patch"),"PATCH 10 anticipata")
      else
        truth(sources.contains("LegacyOrder46LatchAdapter.orderAt46Latch("),
          "La patch deve attraversare il latch storico")
      truth(!sources.contains("biasedLegacyPick"),"Fase successiva anticipata")
    }
    check("metadati Stage20 RED preservano Stage19 GREEN") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current>=20,"Stage20 conservato")
      if(current==20) {
        truth(st.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
        truth(st.contains("CURRENT_PATCH=09"),"Patch precedente")
        truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"RED")
      } else {
        truth(st.contains("STAGE_20_NATIVE_VERIFICATION=PASS_EXPECTED_RED_26_PASS_3_FAIL"),
          "La firma RED di Stage20 deve restare certificata")
      }
      truth(st.contains("STAGE_19_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_37_PASS_0_FAIL"),
        "Stadio19 certificato")
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=19 && completed<=current,"Ordine certificazione")
    }

    val m=new BaseMonsterManager
    Vector(
      ("ordine diretto",BigInt(1),BigInt(720),1),
      ("ordine inverso",BigInt(720),BigInt(1),1),
      ("giro finale",BigInt(123),BigInt(456),3)
    ).foreach {case(label,d45,d46,id) =>
      check("equivalenza normativa latch "+label) {
        val r=m.discover10Order46Latch(0,0,d45,d46,id)
        val want=next(expectedOrder(d46),id)
        eqv(r.legacyNextBowl,want,"Latch conserva ordine della goccia 45: "+label)
      }
    }
    println("\nRISULTATO STADIO 20: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
