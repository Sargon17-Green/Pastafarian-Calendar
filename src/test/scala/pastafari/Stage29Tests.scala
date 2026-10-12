package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 14: rango 1-based BigInt, cicatrice Int realmente attraversata. */
object Stage29Tests {
  private var passed=0
  private var failed=0
  private val Huge=(BigInt(1)<<16384)+9181
  private val Count=(BigInt(1)<<16385)+173

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
    try run catch {case _:IllegalArgumentException => caught=true}
    truth(caught,label+": parametro non rifiutato")
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var caught=false
    try run catch {case _:IllegalStateException => caught=true}
    truth(caught,label+": contesto falso accettato")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent!=null)
      p=p.getParent
    p
  }
  // Riferimento test-only: selezione aritmetica, non il wrapper corretto.
  private def normative(first:BigInt,step:BigInt,rank:BigInt):BigInt=
    first+step*(rank-1)

  private def corrected(rank:BigInt=1,first:BigInt=17,
                        step:BigInt=3,count:BigInt=Count):
      Patch14VirtualGateResult =
    Patch14VirtualGateWrapper.virtualGatePatch(first,step,count,rank)

  private def discovery(rank:BigInt=1,first:BigInt=17,
                        step:BigInt=3,count:BigInt=Count):
      BaseMonsterContext = {
    val c=BaseMonsterContext(43,-9181)
    c.phase="DISCOVERY_14_VIRTUAL_GATE_LIST"
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.virtualFirstGateIndex=Some(first)
    c.virtualGateStride=Some(step)
    c.virtualCandidateCount=Some(count)
    c.virtualRequestedRank=Some(rank)
    new Discovery14VirtualGateListHandler(new BaseMetricsShell).handle(c)
    c
  }
  private def complete(rank:BigInt=1,first:BigInt=17,
                       step:BigInt=3,count:BigInt=Count):
      BaseMonsterContext = {
    val c=discovery(rank,first,step,count)
    c.phase="PATCH_14_VIRTUAL_GATE_LIST"
    new Patch14VirtualGateHandler(new BaseMetricsShell).handle(c)
    c
  }

  def main(args:Array[String]):Unit={
    check("il primo rango 1-based sceglie il primo indice"){
      val r=corrected()
      eqv(r.correctedSelectedGateIndex,BigInt(17),"Primo")
      eqv(r.historical.narrowedRank,1,"Legacy")
    }
    check("il secondo rango include esattamente un passo"){
      eqv(corrected(2).correctedSelectedGateIndex,BigInt(20),"Secondo")
    }
    check("il rango finale di una famiglia breve resta incluso"){
      val r=corrected(99,count=99)
      eqv(r.correctedSelectedGateIndex,BigInt(311),"Ultimo")
    }
    check("il massimo signed Int coincide con il legacy"){
      val rank=BigInt(Int.MaxValue)
      val r=corrected(rank)
      eqv(r.correctedSelectedGateIndex,normative(17,3,rank),"Norma")
      eqv(r.historical.guessedGateIndex,r.correctedSelectedGateIndex,"Legacy")
    }
    check("il primo rango fuori Int signed viene corretto"){
      val rank=BigInt(Int.MaxValue)+1
      val r=corrected(rank)
      eqv(r.correctedSelectedGateIndex,normative(17,3,rank),"BigInt")
      eqv(r.historical.narrowedRank,Int.MinValue,"Cicatrice")
      truth(r.historical.guessedGateIndex!=r.correctedSelectedGateIndex,"Divergenza")
    }
    check("la soglia esatta 2^32 non viene ridotta a rango zero"){
      val rank=BigInt(1)<<32
      val r=corrected(rank)
      eqv(r.correctedSelectedGateIndex,normative(17,3,rank),"Norma")
      eqv(r.historical.narrowedRank,0,"Vecchio zero")
    }
    check("il rango 2^32+1 non ritorna al primo candidato"){
      val rank=(BigInt(1)<<32)+1
      val r=corrected(rank)
      eqv(r.historical.guessedGateIndex,BigInt(17),"Legacy")
      eqv(r.correctedSelectedGateIndex,normative(17,3,rank),"Norma")
    }
    check("il rango 2^64+1 conserva tutti i bit alti"){
      val rank=(BigInt(1)<<64)+1
      val r=corrected(rank)
      eqv(r.historical.narrowedRank,1,"Legacy")
      eqv(r.correctedSelectedGateIndex,normative(17,3,rank),"Norma")
    }
    check("il rango 2^127+1 non subisce overflow"){
      val rank=(BigInt(1)<<127)+1
      eqv(corrected(rank).correctedSelectedGateIndex,
        normative(17,3,rank),"BigInt")
    }
    check("il rango di oltre 16384 bit è supportato"){
      val r=corrected(Huge)
      eqv(r.correctedSelectedGateIndex,17+(Huge-1)*3,"Rango enorme")
      eqv(r.historical.narrowedRank,Huge.toInt,"Cicatrice")
    }
    check("la cardinalità stessa può essere rango"){
      val r=corrected(Count)
      eqv(r.correctedSelectedGateIndex,normative(17,3,Count),"Ultimo enorme")
    }
    check("il passo negativo produce una progressione decrescente"){
      val r=corrected(4,first=100,step = -7)
      eqv(r.correctedSelectedGateIndex,BigInt(79),"Decrescente")
    }
    check("un prefisso negativo enorme è preservato"){
      val r=corrected(4,first = -Huge,step=7)
      eqv(r.correctedSelectedGateIndex,-Huge+21,"Segno")
    }
    check("un prefisso positivo enorme è preservato"){
      val r=corrected(4,first=Huge,step = -7)
      eqv(r.correctedSelectedGateIndex,Huge-21,"Segno")
    }
    check("un passo positivo enorme è preservato"){
      val r=corrected(5,first=17,step=Huge)
      eqv(r.correctedSelectedGateIndex,17+Huge*4,"Passo")
    }
    check("un passo negativo enorme è preservato"){
      val r=corrected(5,first=17,step = -Huge)
      eqv(r.correctedSelectedGateIndex,17-Huge*4,"Passo")
    }
    check("una traduzione comune dell'origine trasla entrambe le scelte"){
      val original=corrected((BigInt(1)<<32)+3)
      val shifted=corrected((BigInt(1)<<32)+3,first=17+Huge)
      eqv(shifted.correctedSelectedGateIndex-original.correctedSelectedGateIndex,
        Huge,"Traslazione PATCH")
      eqv(shifted.historical.guessedGateIndex-original.historical.guessedGateIndex,
        Huge,"Traslazione legacy")
    }
    check("un cambio di passo scala entrambi gli scarti"){
      val rank=(BigInt(1)<<64)+8
      val a=corrected(rank,first=17,step=3)
      val b=corrected(rank,first=17,step=15)
      eqv(b.correctedSelectedGateIndex-17,
        (a.correctedSelectedGateIndex-17)*5,"Scalatura PATCH")
      eqv(b.historical.guessedGateIndex-17,
        (a.historical.guessedGateIndex-17)*5,"Scalatura legacy")
    }
    check("cicatrice storico completa corrisponde al helper originale"){
      for(rank<-Vector[BigInt](1,2,BigInt(Int.MaxValue),
           BigInt(Int.MaxValue)+1,BigInt(1)<<32,
           (BigInt(1)<<64)+1,Huge,Count)) {
        val r=corrected(rank,first = -Huge,step = -3)
        eqv(r.historical,VirtualLegacyListAdapter.oldVirtualGateAt(
          -Huge,-3,Count,rank),"Storia "+rank)
      }
    }
    check("4096 vettori con ranghi Int confrontati indipendentemente"){
      val rnd=new Random(20261012L)
      for(i<-1 to 4096) {
        val rank=BigInt(1+rnd.nextInt(1000000))
        val first=BigInt(rnd.nextLong())
        val raw=BigInt(rnd.nextInt(100001)-50000)
        val stride=if(raw==0)BigInt(1) else raw
        val r=corrected(rank,first,stride)
        eqv(r.correctedSelectedGateIndex,normative(first,stride,rank),
          "Campione "+i)
        eqv(r.historical.guessedGateIndex,r.correctedSelectedGateIndex,
          "Legacy "+i)
      }
    }
    check("4096 vettori BigInt signed con rango oltre Int"){
      val rnd=new Random(29102026L)
      for(i<-1 to 4096) {
        val rank=(BigInt(1)<<64)+BigInt(1+rnd.nextInt(2000000))
        val first=BigInt(rnd.nextLong())*(BigInt(1)<<128)
        val stride=if(i%2==0)BigInt(99+i) else -BigInt(99+i)
        val r=corrected(rank,first,stride)
        eqv(r.correctedSelectedGateIndex,normative(first,stride,rank),
          "Corretto "+i)
        eqv(r.historical,VirtualLegacyListAdapter.oldVirtualGateAt(
          first,stride,Count,rank),"Cicatrice "+i)
      }
    }
    check("2048 vettori di rango signed oltre 16384 bit"){
      val rnd=new Random(2917L)
      for(i<-1 to 2048) {
        val rank=(BigInt(1)<<16384)+BigInt(1+rnd.nextInt(100000))
        val origin=(BigInt(1)<<16384)+BigInt(i)
        val step=if(i%2==0)BigInt(i+1) else -BigInt(i+1)
        eqv(corrected(rank,origin,step).correctedSelectedGateIndex,
          normative(origin,step,rank),"Gigante "+i)
      }
    }
    check("la sequenza PATCH rimane monotona con passo positivo"){
      val start=BigInt(1)<<31
      var previous=corrected(start).correctedSelectedGateIndex
      for(i<-1 to 1000) {
        val now=corrected(start+i).correctedSelectedGateIndex
        eqv(now-previous,BigInt(3),"Differenza")
        previous=now
      }
    }
    check("la sequenza PATCH rimane monotona con passo negativo"){
      val start=BigInt(1)<<32
      var previous=corrected(start,step = -7).correctedSelectedGateIndex
      for(i<-1 to 1000) {
        val now=corrected(start+i,step = -7).correctedSelectedGateIndex
        eqv(now-previous,BigInt(-7),"Differenza")
        previous=now
      }
    }
    check("rango zero è respinto prima del calcolo"){
      rejectArg("Zero"){corrected(0)}
    }
    check("rango negativo è respinto prima del calcolo"){
      rejectArg("Negativo"){corrected(-1)}
    }
    check("rango superiore alla cardinalità viene respinto"){
      rejectArg("Oltre"){corrected(Count+1)}
    }
    check("cardinalità zero o negativa viene respinta"){
      rejectArg("Zero"){corrected(1,count=0)}
      rejectArg("Negativo"){corrected(1,count = -1)}
    }
    check("un passo zero è respinto"){
      rejectArg("Passo"){corrected(1,step=0)}
    }
    check("la famiglia con unico candidato è valida"){
      val r=corrected(1,count=1,first = -Huge,step=Huge)
      eqv(r.correctedSelectedGateIndex,-Huge,"Unico")
    }
    check("report storico non muta dopo richieste intercalate"){
      val r=corrected(Huge,first = -Huge,step=Huge)
      for(i<-1 to 100)corrected(i)
      eqv(corrected(Huge,first = -Huge,step=Huge),r,"Immutabile")
    }
    check("manager attraversa BOOT, discovery e patch nello stesso contesto"){
      val m=new BaseMonsterManager
      val rank=BigInt(1)<<32
      val r=m.patch14VirtualGateList(43,-9181,17,3,Count,rank)
      eqv(r.calculationDay,BigInt(43),"Azione")
      eqv(r.targetDay,BigInt(-9181),"Domanda")
      eqv(r.firstGateIndex,BigInt(17),"Primo")
      eqv(r.gateStride,BigInt(3),"Passo")
      eqv(r.candidateCount,Count,"Count")
      eqv(r.requestedRank,rank,"Rank")
      eqv(r.legacyNarrowedRank,0,"Narrowing")
      eqv(r.legacySelectedGateIndex,BigInt(14),"Legacy")
      eqv(r.patchedSelectedGateIndex,normative(17,3,rank),"PATCH")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_14_VIRTUAL_GATE_LIST","Fase")
      eqv(r.status,"PATCH_14_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_14_VIRTUAL_GATE_LIST",
        "PATCH_14_VIRTUAL_GATE_LIST"),"Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery14.virtual.gate.calls"),BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch14.virtual.gate.calls"),BigInt(1),"Patch")
    }
    check("lo stesso manager mantiene indipendenti due richieste"){
      val m=new BaseMonsterManager
      val a=m.patch14VirtualGateList(1,2,17,3,Count,BigInt(1)<<31)
      val b=m.patch14VirtualGateList(3,4,17,3,Count,BigInt(1)<<32)
      eqv(a.patchedSelectedGateIndex,normative(17,3,BigInt(1)<<31),"A")
      eqv(b.patchedSelectedGateIndex,normative(17,3,BigInt(1)<<32),"B")
      eqv(m.metricsSnapshot("patch14.virtual.gate.calls"),BigInt(2),"Due")
    }
    check("il diagnostico discovery rimane RED esattamente sugli stessi input"){
      val m=new BaseMonsterManager
      val rank=BigInt(1)<<31
      val old=m.discover14VirtualGateList(0,0,17,3,Count,rank)
      val now=m.patch14VirtualGateList(0,0,17,3,Count,rank)
      eqv(old.legacySelectedGateIndex,now.legacySelectedGateIndex,"Cicatrice")
      eqv(old.narrowedRank,now.legacyNarrowedRank,"Rango amputato")
      truth(now.patchedSelectedGateIndex!=old.legacySelectedGateIndex,"RED storico")
    }
    check("due manager non condividono lo stato semantico"){
      val m1=new BaseMonsterManager
      val m2=new BaseMonsterManager
      eqv(m1.patch14VirtualGateList(0,0,17,3,Count,1).patchedSelectedGateIndex,
        BigInt(17),"M1")
      eqv(m2.patch14VirtualGateList(0,0,17,3,Count,2).patchedSelectedGateIndex,
        BigInt(20),"M2")
      eqv(m1.metricsSnapshot("patch14.virtual.gate.calls"),BigInt(1),"Metrica1")
      eqv(m2.metricsSnapshot("patch14.virtual.gate.calls"),BigInt(1),"Metrica2")
    }
    check("handler rifiuta un contesto nuovo senza discovery"){
      val c=BaseMonsterContext(1,2)
      c.phase="PATCH_14_VIRTUAL_GATE_LIST"
      rejectState("Senza BOOT"){
        new Patch14VirtualGateHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta bootstrap senza discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED"
      c.branchTrace.append("BOOT")
      c.phase="PATCH_14_VIRTUAL_GATE_LIST"
      rejectState("Senza legacy"){
        new Patch14VirtualGateHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler respinge la cicatrice modificata e non pubblica output"){
      val c=discovery(BigInt(1)<<31)
      c.phase="PATCH_14_VIRTUAL_GATE_LIST"
      c.legacyVirtualNarrowedRank=Some(1)
      rejectState("Narrowed falso"){
        new Patch14VirtualGateHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedVirtualSelectedGateIndex.isEmpty,"Output non scritto")
      truth(!c.patch14Applied,"Flag non attivo")
      eqv(c.branchTrace.toVector,Vector("BOOT","DISCOVERY_14_VIRTUAL_GATE_LIST"),
        "Trace invariata")
    }
    check("handler rifiuta la seconda applicazione"){
      val c=complete()
      rejectState("Doppio"){
        new Patch14VirtualGateHandler(new BaseMetricsShell).handle(c)}
    }
    check("validator indipendente accetta il contesto completo"){
      new BaseValidationManager().requirePatch14Ready(complete())
    }
    check("validator accetta il rango 2^32 dopo il wrapping legacy"){
      val c=complete(BigInt(1)<<32)
      new BaseValidationManager().requirePatch14Ready(c)
      eqv(c.legacyVirtualNarrowedRank,Some(0),"Vecchio")
    }
    check("validator accetta tutti i ranghi di frontiera"){
      val v=new BaseValidationManager
      for(rank<-Vector[BigInt](1,2,BigInt(Int.MaxValue),
         BigInt(Int.MaxValue)+1,BigInt(1)<<32,(BigInt(1)<<64)+1,Huge,Count))
        v.requirePatch14Ready(complete(rank))
    }
    check("validator accetta passo signed negativo e origine enorme"){
      new BaseValidationManager().requirePatch14Ready(
        complete(Huge,first = -Huge,step = -Huge))
    }
    check("validator rifiuta output PATCH falsificato"){
      val c=complete()
      c.patchedVirtualSelectedGateIndex=Some(999)
      rejectState("Valore"){
        new BaseValidationManager().requirePatch14Ready(c)}
    }
    check("validator rifiuta risultato storico falsificato"){
      val c=complete()
      c.legacyVirtualSelectedGateIndex=Some(999)
      rejectState("Legacy"){
        new BaseValidationManager().requirePatch14Ready(c)}
    }
    check("validator rifiuta narrowing storico falsificato"){
      val c=complete()
      c.legacyVirtualNarrowedRank=Some(2)
      rejectState("Narrowed"){
        new BaseValidationManager().requirePatch14Ready(c)}
    }
    check("validator rifiuta il rango richiesto alterato"){
      val c=complete()
      c.virtualRequestedRank=Some(2)
      rejectState("Rango"){
        new BaseValidationManager().requirePatch14Ready(c)}
    }
    check("validator rifiuta origine mutata"){
      val c=complete()
      c.virtualFirstGateIndex=Some(18)
      rejectState("Origine"){
        new BaseValidationManager().requirePatch14Ready(c)}
    }
    check("validator rifiuta passo mutato"){
      val c=complete()
      c.virtualGateStride=Some(5)
      rejectState("Passo"){
        new BaseValidationManager().requirePatch14Ready(c)}
    }
    check("validator rifiuta cardinalità mutata fuori dominio"){
      val c=complete()
      c.virtualCandidateCount=Some(0)
      rejectState("Conteggio"){
        new BaseValidationManager().requirePatch14Ready(c)}
    }
    check("validator rifiuta output mancante"){
      val c=complete()
      c.patchedVirtualSelectedGateIndex=None
      rejectState("Mancante"){
        new BaseValidationManager().requirePatch14Ready(c)}
    }
    check("validator rifiuta flag, fase e trace contraffatti"){
      val c=complete()
      val v=new BaseValidationManager
      c.patch14Applied=false
      rejectState("Flag"){v.requirePatch14Ready(c)}
      c.patch14Applied=true
      c.branchTrace.remove(1)
      rejectState("Trace"){v.requirePatch14Ready(c)}
      c.branchTrace.insert(1,"DISCOVERY_14_VIRTUAL_GATE_LIST")
      c.phase="DISCOVERY_14_VIRTUAL_GATE_LIST"
      rejectState("Fase"){v.requirePatch14Ready(c)}
    }
    check("le tredici PATCH precedenti rimangono normative"){
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
    }
    check("oracolo test-only, vecchia cicatrice preservata e nessuno Stage30"){
      val files=Files.walk(root().resolve("src/main/scala"))
      val sources=try files.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally files.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo")
      truth(sources.contains("val narrow=rank1.toInt"),"Legacy Int")
      truth(sources.contains("def virtualGatePatch("),"PATCH 14 disponibile")
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if(current<30)
        truth(!sources.contains("legacyChooseEachDaySeparately"),"Fase futura")
      else
        truth(sources.contains("def legacyChooseEachDaySeparately("),
          "DISCOVERY 15 posteriore presente")
      truth(!sources.contains("oldContiguousMonthDayGuess"),"Fase futura")
    }
    check("metadati Stage29 conservano la certificazione Stage28"){
      val text=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=text.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current>=29,"Stage29")
      truth(text.contains("CURRENT_PATCH=14"),"PATCH 14")
      truth(text.contains("STAGE_28_NATIVE_VERIFICATION=PASS_EXPECTED_RED_41_PASS_3_FAIL"),
        "Stage28")
      truth(text.contains("STAGE_29_NATIVE_VERIFICATION="),"Stato")
      val completed=text.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=28 && completed<=current,"Ordine")
    }
    println("\nRISULTATO STADIO 29: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
