package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 15: nuova selezione errata della tessitura a ogni giorno. */
object Stage30Tests {
  private var passed=0
  private var failed=0
  private val A=Vector.fill(84)(1)++Vector.fill(84)(2)++Vector.fill(84)(3)
  private val C=Vector(1,1,2)++Vector.fill(82)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val B=Vector(1,2)++Vector.fill(83)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  // Lessicograficamente: A prima di C, C prima di B.
  private val Weaves=Vector(A,C,B)

  private def check(label:String)(run: => Unit):Unit={
    try {run;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(run: => Unit):Unit={
    var caught=false
    try run catch {case _:IllegalArgumentException=>caught=true}
    truth(caught,label+": valore illegale accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var caught=false
    try run catch {case _:IllegalStateException=>caught=true}
    truth(caught,label+": falsificazione accettata")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }
  private def original(rank:BigInt=1,day:Int=0,
                       family:Vector[Vector[Int]]=Weaves):
      LegacyPerDayWeavingResult =
    LegacyDaywiseWeavingAdapter.legacyChooseEachDaySeparately(family,rank,day)

  // La tessitura è scelta UNA volta all'apertura dell'anno. Questo
  // riferimento aritmetico appare soltanto nel test, mai nel legacy.
  private def normative(rank:BigInt,day:Int,
                        family:Vector[Vector[Int]]=Weaves):Int =
    family((rank-1).toInt)(day)

  private def ready(rank:BigInt=1,day:Int=0,
                    family:Vector[Vector[Int]]=Weaves):BaseMonsterContext={
    val c=BaseMonsterContext(43,-9181)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_15_DAYWISE_WEAVING"
    c.daywiseCandidateWeavings=Some(family)
    c.daywiseYearRank1=Some(rank)
    c.daywiseOffset=Some(day)
    new Discovery15DaywiseWeavingHandler(new BaseMetricsShell).handle(c)
    c
  }
  private def singleInsertion(position:Int):Vector[Int] =
    Vector.fill(position)(1)++Vector(2)++
    Vector.fill(84-position)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)

  def main(args:Array[String]):Unit={
    check("il calendario diagnostico contiene 252 giorni"){
      eqv(Weaves.map(_.length),Vector(252,252,252),"Durate")
    }
    check("ciascuna tessitura ha tre mesi validi da 84 giorni"){
      Weaves.foreach { w =>
        eqv((1 to 3).map(i=>w.count(_==i)).toVector,
          Vector(84,84,84),"Durata per mese")
      }
    }
    check("l'ordine A C B è lessicografico e tutti sono legali"){
      LegacyDaywiseWeavingAdapter.validateCandidates(Weaves)
      truth(A!=C && C!=B && A!=B,"Candidati distinti")
    }
    check("al primo giorno il legacy conserva il rango annuale uno"){
      val r=original()
      eqv(r.dayRank1,BigInt(1),"Rank")
      eqv(r.monthId,1,"Mese")
    }
    check("al primo giorno il rango due seleziona la sua tessitura"){
      val r=original(2,0)
      eqv(r.dayRank1,BigInt(2),"Rank")
      eqv(r.monthId,normative(2,0),"Mese")
    }
    check("al primo giorno il rango tre seleziona la sua tessitura"){
      val r=original(3,0)
      eqv(r.dayRank1,BigInt(3),"Rank")
      eqv(r.monthId,normative(3,0),"Mese")
    }
    check("al secondo giorno il rango due viene ricalcolato a tre"){
      val r=original(2,1)
      eqv(r.dayRank1,BigInt(3),"Nuovo rango")
      eqv(r.monthId,2,"Mese storico")
    }
    check("al secondo giorno il rango tre ritorna impropriamente a uno"){
      val r=original(3,1)
      eqv(r.dayRank1,BigInt(1),"Ritorno")
      eqv(r.monthId,1,"Mese storico")
    }
    check("al terzo giorno il rango tre passa impropriamente a due"){
      val r=original(3,2)
      eqv(r.dayRank1,BigInt(2),"Rango giornaliero")
      eqv(r.monthId,2,"Mese storico")
    }
    check("l'ultimo giorno non estende l'anno sintetico"){
      val r=original(1,251)
      eqv(r.dayRank1,BigInt(3),"Rango modulare")
      eqv(r.monthId,3,"Mese")
    }
    check("a ogni tripla di giorni il rango antico torna all'origine"){
      for(rank<-1 to 3;day<-0 to 248 by 3){
        eqv(original(rank,day).dayRank1,BigInt(rank),"Rango")
      }
    }
    check("i casi senza alternative rimangono coerenti con l'oracolo"){
      for(day<-0 until 252){
        val r=original(1,day,Vector(A))
        eqv(r.dayRank1,BigInt(1),"Un candidato")
        eqv(r.monthId,normative(1,day,Vector(A)),"Mese")
      }
    }
    check("il rango e la data restano nel report storico"){
      val r=original(3,2)
      eqv(r.yearRank1,BigInt(3),"Rango annuale")
      eqv(r.dayOffset,2,"Offset")
      eqv(r.candidates,Weaves,"Famiglia")
    }
    check("nessuna lista viene mutata tra chiamate intercalate"){
      val first=original(2,1)
      for(i<-0 until 252)original(3,i)
      eqv(original(2,1),first,"Ripetibilità")
      eqv(Weaves,Vector(A,C,B),"Input invariato")
    }
    check("ciascuna tessitura resta lecita quando il sottoinsieme ha un elemento"){
      for(w<-Weaves)LegacyDaywiseWeavingAdapter.validateCandidates(Vector(w))
    }
    check("una famiglia lessicografica di 24 alternative è ammessa"){
      val family=(1 to 24).reverse.map(singleInsertion).toVector
      LegacyDaywiseWeavingAdapter.validateCandidates(family)
      eqv(original(24,251,family).dayRank1,BigInt(11),"Rango periodico")
    }
    check("1024 casi deterministici confrontati alla vera formula legacy"){
      val rnd=new Random(30102026L)
      val family=(1 to 16).reverse.map(singleInsertion).toVector
      for(i<-1 to 1024){
        val rank=1+rnd.nextInt(family.length)
        val day=rnd.nextInt(252)
        val r=original(rank,day,family)
        val expected=BigInt(((rank-1+day)%family.size)+1)
        eqv(r.dayRank1,expected,"Rango "+i)
        eqv(r.monthId,family(expected.toInt-1)(day),"Mese "+i)
      }
    }
    check("con la lunghezza massima di un mese il codice resta nei limiti"){
      val long=Vector.fill(123)(1)++Vector.fill(123)(2)++
        Vector.fill(123)(3)
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(long))
      eqv(original(1,368,Vector(long)).monthId,3,"Ultimo")
    }
    check("l'anno con 47 mesi ammessi non causa overflow del numero mesi"){
      val months=(1 to 47).flatMap(m=>Vector.fill(6)(m)).toVector
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(months))
      eqv(original(1,281,Vector(months)).monthId,47,"Mese quarantasette")
    }
    check("il numero totale più piccolo ammesso è 252"){
      val w=(1 to 3).flatMap(m=>Vector.fill(84)(m)).toVector
      LegacyDaywiseWeavingAdapter.validateCandidates(Vector(w))
    }
    check("le alternative possono essere una sola o più di tre"){
      val family=(1 to 8).reverse.map(singleInsertion).toVector
      LegacyDaywiseWeavingAdapter.validateCandidates(family)
      eqv(original(8,0,family).dayRank1,BigInt(8),"Ultimo")
    }
    check("la famiglia vuota viene respinta"){
      rejectArg("Vuota"){original(1,0,Vector.empty)}
    }
    check("nessun rango zero o negativo"){
      rejectArg("Zero"){original(0)}
      rejectArg("Negativo"){original(-1)}
    }
    check("il rango sopra il numero di candidati viene respinto"){
      rejectArg("Fuori"){original(4)}
    }
    check("nessun giorno fuori dalla tessitura"){
      rejectArg("Sotto"){original(1,-1)}
      rejectArg("Sopra"){original(1,252)}
    }
    check("nessuna tessitura di lunghezza fuori 252..5778"){
      rejectArg("Corta"){original(1,0,Vector(Vector(1,2,3)))}
    }
    check("ogni mese deve durare fra 4 e 123 giorni"){
      val w=Vector(1)++Vector.fill(123)(2)++Vector.fill(123)(3)++
        Vector.fill(5)(4)
      rejectArg("Breve"){original(1,0,Vector(w))}
    }
    check("una tessitura con ID mese mancante è respinta"){
      val w=Vector.fill(84)(1)++Vector.fill(84)(3)++
        Vector.fill(84)(4)
      rejectArg("Manca mese 2"){original(1,0,Vector(w))}
    }
    check("una tessitura che apre un mese fuori ordine è respinta"){
      val w=Vector.fill(84)(1)++Vector.fill(84)(3)++
        Vector.fill(84)(2)
      rejectArg("Apertura"){original(1,0,Vector(w))}
    }
    check("una tessitura che chiude un mese fuori ordine è respinta"){
      val w=Vector(1,2)++Vector.fill(83)(2)++
        Vector.fill(83)(1)++Vector.fill(84)(3)
      rejectArg("Chiusura"){original(1,0,Vector(w))}
    }
    check("un candidato con diverso numero di giorni è respinto"){
      val bad=B.dropRight(1)
      rejectArg("Lunghezza"){original(1,0,Vector(A,C,bad))}
    }
    check("un candidato con durata di mese modificata è respinto"){
      val bad=B.updated(5,2)
      rejectArg("Durata"){original(1,0,Vector(A,C,bad))}
    }
    check("un duplicato rompe l'ordinamento stretto"){
      rejectArg("Doppio"){original(1,0,Vector(A,A))}
    }
    check("l'ordine inverso rompe l'ordine lessicografico"){
      rejectArg("Ordine"){original(1,0,Vector(B,C,A))}
    }
    check("il manager pubblica output, trace e metriche"){
      val m=new BaseMonsterManager
      val r=m.discover15DaywiseWeaving(43,-9181,Weaves,2,1)
      eqv(r.calculationDay,BigInt(43),"Calcolo")
      eqv(r.targetDay,BigInt(-9181),"Target")
      eqv(r.candidates,Weaves,"Famiglia")
      eqv(r.yearRank1,BigInt(2),"Rango annuale")
      eqv(r.dayOffset,1,"Giorno")
      eqv(r.legacyDayRank1,BigInt(3),"Rango giornaliero")
      eqv(r.legacyMonthId,2,"Mese")
      eqv(r.phase,"DISCOVERY_15_DAYWISE_WEAVING","Fase")
      eqv(r.status,"LEGACY_DAYWISE_WEAVING_READY","Status")
      eqv(r.trace,Vector("BOOT","DISCOVERY_15_DAYWISE_WEAVING"),"Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery15.daywise.weaving.calls"),BigInt(1),"Discovery")
    }
    check("due manager hanno metriche e report indipendenti"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      eqv(a.discover15DaywiseWeaving(0,0,Weaves,2,1).legacyMonthId,2,"A")
      eqv(b.discover15DaywiseWeaving(0,0,Weaves,3,1).legacyMonthId,1,"B")
      eqv(a.metricsSnapshot("discovery15.daywise.weaving.calls"),BigInt(1),"A metriche")
      eqv(b.metricsSnapshot("discovery15.daywise.weaving.calls"),BigInt(1),"B metriche")
    }
    check("manager riutilizzato non altera i report precedenti"){
      val m=new BaseMonsterManager
      val r=m.discover15DaywiseWeaving(0,0,Weaves,3,2)
      m.discover15DaywiseWeaving(1,2,Weaves,2,1)
      eqv(r.legacyMonthId,2,"Snapshot immutabile")
      eqv(m.metricsSnapshot("discovery15.daywise.weaving.calls"),BigInt(2),"Due")
    }
    check("handler rifiuta un contesto mai inizializzato"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_15_DAYWISE_WEAVING"
      rejectState("Non bootstrapped"){
        new Discovery15DaywiseWeavingHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta input incompleti"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_15_DAYWISE_WEAVING"
      c.daywiseCandidateWeavings=Some(Weaves)
      rejectState("Manca rango"){
        new Discovery15DaywiseWeavingHandler(new BaseMetricsShell).handle(c)}
      truth(c.legacyDaywiseMonthId.isEmpty,"Nessun output parziale")
    }
    check("handler non consente la seconda esecuzione"){
      val c=ready()
      rejectState("Riesecuzione"){
        new Discovery15DaywiseWeavingHandler(new BaseMetricsShell).handle(c)}
    }
    check("validator accetta un vero contesto completo"){
      new BaseValidationManager().requireDiscovery15Ready(ready(2,1))
    }
    check("validator accetta estremi temporali e tutte le posizioni mese"){
      val v=new BaseValidationManager
      for(rank<-1 to 3;day<-Vector(0,1,2,83,84,85,167,168,251))
        v.requireDiscovery15Ready(ready(rank,day))
    }
    check("validator rifiuta mese storico falsificato"){
      val c=ready(2,1)
      c.legacyDaywiseMonthId=Some(1)
      rejectState("Mese"){new BaseValidationManager().requireDiscovery15Ready(c)}
    }
    check("validator rifiuta rango giornaliero falsificato"){
      val c=ready(2,1)
      c.legacyDaywiseRank1=Some(1)
      rejectState("Rango"){new BaseValidationManager().requireDiscovery15Ready(c)}
    }
    check("validator rifiuta il giorno modificato dopo la discovery"){
      val c=ready(1,0)
      c.daywiseOffset=Some(3)
      rejectState("Offset"){new BaseValidationManager().requireDiscovery15Ready(c)}
    }
    check("validator rifiuta il rango annuale modificato"){
      val c=ready(1,0)
      c.daywiseYearRank1=Some(2)
      rejectState("Anno"){new BaseValidationManager().requireDiscovery15Ready(c)}
    }
    check("validator rifiuta la famiglia mutata anche senza cambiare l'output"){
      val c=ready(1,0)
      c.daywiseCandidateWeavings=Some(Vector(A))
      rejectState("Famiglia"){new BaseValidationManager().requireDiscovery15Ready(c)}
    }
    check("validator rifiuta snapshot contraffatta"){
      val c=ready(2,1)
      c.daywiseInputSnapshot=Some((Weaves,BigInt(2),0))
      rejectState("Snapshot"){new BaseValidationManager().requireDiscovery15Ready(c)}
    }
    check("validator rifiuta phase, status e trace falsificati"){
      val c=ready()
      val v=new BaseValidationManager
      c.status="BOOTSTRAPPED"
      rejectState("Status"){v.requireDiscovery15Ready(c)}
      c.status="LEGACY_DAYWISE_WEAVING_READY"
      c.branchTrace.remove(1)
      rejectState("Trace"){v.requireDiscovery15Ready(c)}
      c.branchTrace.append("DISCOVERY_15_DAYWISE_WEAVING")
      c.phase="PATCH_15_DAYWISE_WEAVING"
      rejectState("Phase"){v.requireDiscovery15Ready(c)}
    }
    check("validator rifiuta output mancante"){
      val c=ready()
      c.legacyDaywiseMonthId=None
      rejectState("Vuoto"){new BaseValidationManager().requireDiscovery15Ready(c)}
    }
    check("le 14 PATCH precedenti mantengono le regressioni native"){
      val m=new BaseMonsterManager
      val mod=NormativeOracle.M
      val f=NormativeOracle.FoundationDay
      eqv(m.patch01Save(0,0,mod).patchedOutput,mod,"P01")
      eqv(m.patch02DayTag(f,f,f).patchedTag,BigInt(1),"P02")
      eqv(m.patch03Distance(f,f).patchedDistance,BigInt(1),"P03")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"P04")
      eqv(m.patch05Prior(0,0,Vector[BigInt](1,2,3,4,5,6,7),
        Vector.empty,1,7).patchedValue,BigInt(7),"P05")
      eqv(m.patch06Grind(0,0,1,7,11,13,17,
        Vector[BigInt](19,23,29,31,37)).patchedValue,BigInt(422),"P06")
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,
        Vector(6,5,4,3,2,1),"P07")
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),
        37,Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"P08")
      eqv(m.patch09Vault(0,0,Vector[BigInt](11,13,17,19,23,29)).patchedBowls,
        NormativeOracle.postStir12(Vector[BigInt](11,13,17,19,23,29)),"P09")
      eqv(m.patch10Order46(0,0,1,720,1).correctedNextBowl,6,"P10")
      eqv(m.patch11ShortPick(0,0,mod,1,5).patchedRank,BigInt(1),"P11")
      eqv(m.patch12YearCeiling(0,0,Vector.fill(6)(963)).patchedAccepted,
        true,"P12")
      eqv(m.patch13YearJump(0,601,0,Vector(400,500,600,700,800),
        Vector(600,700,800,900,1000)).correctedYearOffset,BigInt(1),"P13")
      eqv(m.patch14VirtualGateList(0,0,17,3,BigInt(1)<<64,
        (BigInt(1)<<32)+1).patchedSelectedGateIndex,
        BigInt(17)+((BigInt(1)<<32)*3),"P14")
    }
    check("oracolo test-only, cicatrice viva e nessuna PATCH 15"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val source=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!source.contains("NormativeOracle"),"Oracolo")
      truth(source.contains("def legacyChooseEachDaySeparately("),"Cicatrice")
      truth(!source.contains("def daywiseWeavingPatch("),"PATCH 15 anticipata")
      truth(!source.contains("oldContiguousMonthDayGuess"),"Stage32 anticipato")
    }
    check("metadati Stage30 conservano i certificati di Stage29"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=30"),"Stadio")
      truth(st.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
      truth(st.contains("CURRENT_PATCH=14"),"Patch precedente")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"RED")
      truth(st.contains("STAGE_29_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_55_PASS_0_FAIL"),
        "Certificazione P14")
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed==29 || completed==30,"Ordine cronologico")
    }

    Vector(
      ("rango2_giorno1",BigInt(2),1),
      ("rango3_giorno1",BigInt(3),1),
      ("rango3_giorno2",BigInt(3),2)
    ).foreach { case (label,rank,day) =>
      check("equivalenza normativa tessitura "+label){
        val r=new BaseMonsterManager().discover15DaywiseWeaving(
          43,-9181,Weaves,rank,day)
        eqv(r.legacyMonthId,normative(rank,day),
          "Ricampionamento giornaliero: "+label)
      }
    }
    println("\nRISULTATO STADIO 30: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
