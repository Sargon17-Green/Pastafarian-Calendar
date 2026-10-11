package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 08: alias in-place, confronto RED solo ai tre casi normativi. */
object Stage16Tests {
  private var passed = 0
  private var failed = 0
  private val M = NormativeOracle.M
  private val Initial = Vector[BigInt](11,13,17,19,23,29)
  private val Stones = Vector[BigInt](31,37,41,43,47)
  private val Drop = BigInt(37)
  private val Kinds = Vector(0,1,2,3,4,0)

  private def check(label: String)(run: => Unit): Unit = {
    try {
      run
      passed += 1
      println("PASS — " + label)
    } catch {
      case e: Throwable =>
        failed += 1
        println("FAIL — " + label + " — " + e.getMessage)
        e.printStackTrace(System.out)
    }
  }
  private def eqv[A](got:A,want:A,label:String): Unit =
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  private def truth(value:Boolean,label:String): Unit =
    if(!value)throw new AssertionError(label)
  private def rejectArg(label:String)(run: => Unit): Unit = {
    var threw=false
    try run catch {case _:IllegalArgumentException => threw=true}
    truth(threw,label)
  }
  private def rejectState(label:String)(run: => Unit): Unit = {
    var threw=false
    try run catch {case _:IllegalStateException => threw=true}
    truth(threw,label)
  }

  // Oracolo test-only: usa sempre un'istantanea immutata e un output separato.
  private def frozenMix(initial:Vector[BigInt],drop:BigInt,stones:Vector[BigInt],
                        step:Int,rank:Int): LegacyBowlAliasResult = {
    val order=NormativeOracle.bowlOrderFromNumber(rank)
    val pour=Array.fill[BigInt](6)(BigInt(0))
    for(p <- 0 to 2) {
      val factor=3+2*p
      pour(p)=NormativeOracle.save(drop*drop +
        stones(p)*initial(order(p)-1)+factor*step)
    }
    val output=Array.fill[BigInt](6)(BigInt(0))
    for(position <- 1 to 6) {
      val current=order(position-1)-1
      val prev=order((position+4)%6)-1
      val next=order(position%6)-1
      val sum=initial(current)+2*initial(prev)+3*initial(next)+
        pour(position-1)+drop+stones(Kinds(position-1))
      output(current)=NormativeOracle.save(
        sum*sum+5*initial(prev)*initial(next)+step*position)
    }
    LegacyBowlAliasResult(order,pour.toVector,output.toVector)
  }

  // Simulazione indipendente, funzionale, della vecchia scrittura in-place.
  private def historicalFunctional(initial:Vector[BigInt],drop:BigInt,
                                   stones:Vector[BigInt],step:Int,rank:Int)
                                   :Vector[BigInt] = {
    val original=frozenMix(initial,drop,stones,step,rank)
    var current=initial
    for(position <- 1 to 6) {
      val at=original.order(position-1)-1
      val prev=original.order((position+4)%6)-1
      val next=original.order(position%6)-1
      val sum=current(at)+2*current(prev)+3*current(next)+
        original.pours(position-1)+drop+stones(Kinds(position-1))
      val value=NormativeOracle.save(
        sum*sum+5*current(prev)*current(next)+step*position)
      current=current.updated(at,value)
    }
    current
  }

  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent!=null)
      p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice non trovata")
    p
  }

  def main(args:Array[String]): Unit = {
    check("l'ordine legacy usa la PATCH 07 e non il rango sbagliato") {
      for(rank <- Vector(1,2,360,719,720)) {
        val result=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,1,rank)
        eqv(result.order,NormativeOracle.bowlOrderFromNumber(rank),"Rango "+rank)
      }
    }
    check("il caso diretto mostra il primo valore calcolato senza alias") {
      val old=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,1,1)
      eqv(old.order,Vector(1,2,3,4,5,6),"Ordine")
      eqv(old.bowls.head,BigInt(3570207),"Prima ciotola")
      eqv(old.bowls(1),BigInt("51014281221246"),"Seconda già contaminata")
    }
    check("il caso diretto differisce dopo il primo aggiornamento") {
      val old=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,1,1)
      val correct=frozenMix(Initial,Drop,Stones,1,1)
      eqv(old.bowls.head,correct.bowls.head,"Prima equazione")
      truth(old.bowls(1)!=correct.bowls(1),"La seconda deve usare l'alias")
    }
    check("l'ordine inverso contamina le posizioni successive") {
      val old=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,1,720)
      val correct=frozenMix(Initial,Drop,Stones,1,720)
      eqv(old.order,Vector(6,5,4,3,2,1),"Rango 720")
      eqv(old.bowls(5),correct.bowls(5),"Primo aggiornamento")
      truth(old.bowls(0)!=correct.bowls(0),"Ultimo aggiornamento")
    }
    check("alla goccia 46 la dipendenza dalle scritture rimane") {
      val old=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,46,360)
      val good=frozenMix(Initial,Drop,Stones,46,360)
      truth(old.bowls != good.bowls,"La cicatrice non deve sparire")
      eqv(old.order,good.order,"Ordine già corretto")
    }
    check("tutti i getti sono prodotti prima delle scritture mutate") {
      for(rank <- Vector(1,120,360,720);step <- Vector(1,2,46)) {
        val r=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,step,rank)
        eqv(r.pours,frozenMix(Initial,Drop,Stones,step,rank).pours,"Getti "+rank)
        eqv(r.pours.drop(3),Vector.fill[BigInt](3)(0),"Getti finali")
      }
    }
    check("il helper restituisce SAVE per tutte le ciotole anche se sbaglia") {
      for(rank <- Vector(1,2,3,119,120,121,360,719,720);step <- Vector(1,46)) {
        val r=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,step,rank)
        truth(r.bowls.forall(x=>x>=1 && x<=M),"SAVE a rango "+rank)
      }
    }
    check("tutti i 720 ranghi mostrano la stessa semantica alias") {
      for(rank <- 1 to 720) {
        val r=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,1,rank)
        eqv(r.bowls,historicalFunctional(Initial,Drop,Stones,1,rank),
          "Simulazione storico "+rank)
      }
    }
    check("il riferimento usa sei valori vecchi congelati") {
      for(rank <- Vector(1,2,360,719,720);step <- Vector(1,46)) {
        val r=frozenMix(Initial,Drop,Stones,step,rank)
        truth(r.bowls.length==6,"Lunghezza")
        truth(r.bowls.forall(x=>x>=1 && x<=M),"SAVE normativo")
        eqv(r.order,NormativeOracle.bowlOrderFromNumber(rank),"Ordine")
      }
    }
    check("nessuna scrittura modifica il Vector di input") {
      val original=Initial
      val first=LegacyBowlAliasAdapter.bowlAlias(original,Drop,Stones,1,1)
      eqv(original,Vector[BigInt](11,13,17,19,23,29),"Input immutato")
      truth(first.bowls!=original,"L'uscita deve essere nuova")
    }
    check("ripetizioni del helper non inquinano un'altra invocazione") {
      val before=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,1,1)
      for(i <- 1 to 100) {
        LegacyBowlAliasAdapter.bowlAlias(Initial,BigInt(i),Stones,46,720)
      }
      eqv(LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,1,1),before,
        "Nessun registro condiviso fra chiamate")
    }
    check("interi con segno enormi fino a 8192 bit restano esatti") {
      val huge=(BigInt(1)<<8192)+999
      val initial=Vector(huge,-huge,huge+1,-huge-1,huge*2,-huge*2)
      val stones=Vector[BigInt](huge,-huge,huge+7,-huge-7,huge+11)
      for(rank <- Vector(1,360,720)) {
        val actual=LegacyBowlAliasAdapter.bowlAlias(initial,-huge,stones,46,rank)
        eqv(actual.bowls,historicalFunctional(initial,-huge,stones,46,rank),
          "Arbitrarietà signed "+rank)
      }
    }
    check("campioni deterministici di 256 mescolature legacy") {
      val random=new Random(20261011L)
      for(sample <- 1 to 256) {
        val rank=1+random.nextInt(720)
        val step=1+random.nextInt(46)
        val n=BigInt(random.nextInt(10001)-5000)
        val initial=Vector.tabulate[BigInt](6)(j=>n*(j+1)+sample)
        val stones=Vector.tabulate[BigInt](5)(j=>n-j)
        val actual=LegacyBowlAliasAdapter.bowlAlias(initial,n,stones,step,rank)
        eqv(actual.bowls,historicalFunctional(initial,n,stones,step,rank),
          "Campione "+sample)
      }
    }
    check("gli indici di goccia fuori da uno a quarantasei sono rifiutati") {
      for(step <- Vector(Int.MinValue,-1,0,47,100,Int.MaxValue))
        rejectArg("Step "+step){
          LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,step,1)
        }
    }
    check("i ranghi fuori da uno a settecentoventi sono rifiutati") {
      for(rank <- Vector(Int.MinValue,-1,0,721,1440,Int.MaxValue))
        rejectArg("Rank "+rank){
          LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,1,rank)
        }
    }
    check("le lunghezze malformate di ciotole e pietre sono rifiutate") {
      for(size <- Vector(0,1,5,7,10))
        rejectArg("Ciotole "+size){
          LegacyBowlAliasAdapter.bowlAlias(Vector.fill[BigInt](size)(1),
            Drop,Stones,1,1)
        }
      for(size <- Vector(0,1,4,6,10))
        rejectArg("Pietre "+size){
          LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,
            Vector.fill[BigInt](size)(1),1,1)
        }
    }
    check("il manager percorre davvero Bootstrap e DISCOVERY 08") {
      val m=new BaseMonsterManager
      val r=m.discover08BowlAlias(123,-456,Initial,Drop,Stones,1,1)
      eqv(r.calculationDay,BigInt(123),"Calcolo")
      eqv(r.targetDay,BigInt(-456),"Interrogazione")
      eqv(r.initialBowls,Initial,"Snapshot iniziale")
      eqv(r.stones,Stones,"Snapshot delle pietre")
      eqv(r.orderRank1,1,"Rango")
      eqv(r.step,1,"Goccia")
      eqv(r.bowlOrder,Vector(1,2,3,4,5,6),"Ordine")
      eqv(r.legacyBowls.head,BigInt(3570207),"Output reale")
      eqv(r.phase,"DISCOVERY_08_BOWL_ALIAS","Fase")
      eqv(r.status,"LEGACY_BOWL_ALIAS_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_08_BOWL_ALIAS"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery08.bowl.alias.calls"),BigInt(1),"Handler")
    }
    check("due chiamate conservano snapshot e metriche isolate") {
      val m=new BaseMonsterManager
      val a=m.discover08BowlAlias(1,2,Initial,Drop,Stones,1,1)
      val b=m.discover08BowlAlias(3,4,Initial,Drop,Stones,46,720)
      eqv(a.initialBowls,Initial,"Input primo")
      eqv(a.legacyBowls.head,BigInt(3570207),"Output primo")
      truth(a.legacyBowls!=b.legacyBowls,"Due esiti diversi")
      eqv(b.orderRank1,720,"Input secondo")
      eqv(m.metricsSnapshot("discovery08.bowl.alias.calls"),BigInt(2),"Due chiamate")
    }
    check("giorni BigInt enormi non perturbano la mescolatura locale") {
      val m=new BaseMonsterManager
      val huge=(BigInt(1)<<16384)+17
      val a=m.discover08BowlAlias(0,0,Initial,Drop,Stones,46,360)
      val b=m.discover08BowlAlias(huge,-huge,Initial,Drop,Stones,46,360)
      eqv(a.legacyBowls,b.legacyBowls,"Indipendenza")
      eqv(b.calculationDay,huge,"BigInt non troncato")
    }
    check("il validatore rifiuta output assente e traccia contraffatta") {
      val v=new BaseValidationManager
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_08_BOWL_ALIAS"
      c.status="LEGACY_BOWL_ALIAS_READY"
      rejectState("Nessun output"){v.requireDiscovery08Ready(c)}
      c.bowlInput=Some(Initial);c.bowlDropInput=Some(Drop)
      c.bowlStonesInput=Some(Stones);c.bowlStepInput=Some(1)
      c.bowlRankInput=Some(1)
      val old=LegacyBowlAliasAdapter.bowlAlias(Initial,Drop,Stones,1,1)
      c.legacyBowlOrderOutput=Some(old.order)
      c.legacyBowlPoursOutput=Some(old.pours)
      c.legacyBowlOutput=Some(old.bowls)
      rejectState("Trace mancante"){v.requireDiscovery08Ready(c)}
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_08_BOWL_ALIAS"))
      v.requireDiscovery08Ready(c)
    }
    check("il validatore rileva getto falsificato e rango non corrispondente") {
      val v=new BaseValidationManager
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.bowlInput=Some(Initial);c.bowlDropInput=Some(Drop)
      c.bowlStonesInput=Some(Stones);c.bowlStepInput=Some(1)
      c.bowlRankInput=Some(1);c.phase="DISCOVERY_08_BOWL_ALIAS"
      new Discovery08BowlAliasHandler(new BaseMetricsShell).handle(c)
      v.requireDiscovery08Ready(c)
      val pours=c.legacyBowlPoursOutput.get
      c.legacyBowlPoursOutput=Some(pours.updated(0,pours.head+1))
      rejectState("Getto falsificato"){v.requireDiscovery08Ready(c)}
      c.legacyBowlPoursOutput=Some(pours)
      c.bowlRankInput=Some(720)
      rejectState("Rango falsificato"){v.requireDiscovery08Ready(c)}
    }
    check("l'handler rifiuta bypass del Bootstrap e seconda esecuzione") {
      val h=new Discovery08BowlAliasHandler(new BaseMetricsShell)
      val c=BaseMonsterContext(1,2)
      rejectState("Senza Bootstrap"){h.handle(c)}
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.bowlInput=Some(Initial);c.bowlDropInput=Some(Drop)
      c.bowlStonesInput=Some(Stones);c.bowlStepInput=Some(1)
      c.bowlRankInput=Some(1);c.phase="DISCOVERY_08_BOWL_ALIAS"
      h.handle(c)
      val before=c.legacyBowlOutput
      rejectState("Secondo uso"){h.handle(c)}
      eqv(c.legacyBowlOutput,before,"Output conservato")
    }
    check("sette patch precedenti ancora normative e cicatrici presenti") {
      val m=new BaseMonsterManager
      val f=NormativeOracle.FoundationDay
      eqv(m.patch01Save(0,0,M).patchedOutput,M,"SAVE")
      eqv(m.patch02DayTag(f,f,f).patchedTag,BigInt(1),"DayTag")
      eqv(m.patch03Distance(f,f).patchedDistance,BigInt(1),"Distance")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"Stones")
      val hidden=Vector[BigInt](101,202,303,404,505,606,707)
      eqv(m.patch05Prior(0,0,hidden,Vector.empty,1,7).patchedValue,
        BigInt(707),"Prior")
      eqv(m.patch06Grind(0,0,1,7,11,13,17,
        Vector[BigInt](19,23,29,31,37)).patchedValue,BigInt(422),"Grind")
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,
        Vector(6,5,4,3,2,1),"Permutation")
      eqv(m.discover07Permutation(0,0,720).legacyPermutation,
        Vector(1,2,3,4,5,6),"Cicatrice")
    }
    check("oracle test-only e nessuna PATCH 08 o logica futura") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracle in produzione")
      truth(sources.contains("val next = register"),"Aliasing storico assente")
      truth(sources.contains("Patch07PermutationWrapper.permutationPatch(rank1)"),
        "La selezione deve usare la PATCH 07")
      val st = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current = st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if (current < 17)
        truth(!sources.contains("bowlPatch"),"PATCH 08 anticipata")
      else
        truth(sources.contains("LegacyBowlAliasAdapter.bowlAlias("),
          "Cicatrice reale ancora percorribile")
      truth(!sources.contains("vaultOld"),"Logica dello stadio futuro")
    }
    check("metadati Stage16 RED senza certificazione anticipata") {
      val state=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current = state.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current >= 16,"Stage16 resta disponibile")
      if (current == 16) {
        truth(state.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
        truth(state.contains("CURRENT_PATCH=07"),"Ultima patch")
        truth(state.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"Rosso previsto")
      } else {
        truth(state.contains("STAGE_16_NATIVE_VERIFICATION=PASS_EXPECTED_RED_25_PASS_3_FAIL"),
          "Firma RED storica invariata")
      }
      truth(state.contains("STAGE_15_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_31_PASS_0_FAIL"),
        "Stage 15 rimane certificato")
      val completed=state.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=15 && completed<=current,"Certificazioni cronologiche")
    }

    val manager=new BaseMonsterManager
    Vector(
      ("ordine diretto",1,1),
      ("ordine inverso",1,720),
      ("goccia quarantasei",46,360)
    ).foreach {case(label,step,rank) =>
      check("equivalenza normativa mescolatura "+label) {
        val actual=manager.discover08BowlAlias(
          0,0,Initial,Drop,Stones,step,rank)
        val expected=frozenMix(Initial,Drop,Stones,step,rank)
        eqv(actual.legacyBowls,expected.bowls,"Alias muta valori precedenti: "+label)
      }
    }
    println("\nRISULTATO STADIO 16: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
