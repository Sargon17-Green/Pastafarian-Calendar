package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 14: restringimento 32-bit del rango in una lista virtuale. */
object Stage28Tests {
  private var passed=0
  private var failed=0
  private val Huge=(BigInt(1)<<16384)+9181
  private val Count=(BigInt(1)<<130)+173
  private def check(label:String)(f: => Unit):Unit={
    try {f;passed+=1;println("PASS — "+label)}
    catch {case error:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+error.getMessage)
      error.printStackTrace(System.out)}
  }
  private def eqv[A](a:A,b:A,label:String):Unit=
    if(a!=b)throw new AssertionError(
      label+": atteso="+b+", ottenuto="+a)
  private def truth(c:Boolean,label:String):Unit={
    if(!c)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(f: => Unit):Unit={
    var got=false
    try f catch {case _:IllegalArgumentException => got=true}
    truth(got,label+": non rifiutato")
  }
  private def rejectState(label:String)(f: => Unit):Unit={
    var got=false
    try f catch {case _:IllegalStateException => got=true}
    truth(got,label+": non rifiutato")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent!=null)
      p=p.getParent
    p
  }
  // Oracolo test-only: rango 1-based di una progressione virtuale,
  // senza enumerazione, senza narrowing e senza chiamata alla cicatrice.
  private def normative(first:BigInt,stride:BigInt,rank:BigInt):BigInt=
    first+(rank-1)*stride

  private def legacy(rank:BigInt=1,first:BigInt=17,
                     stride:BigInt=3,count:BigInt=Count):
      LegacyVirtualGateListResult =
    VirtualLegacyListAdapter.oldVirtualGateAt(first,stride,count,rank)

  private def ctx(rank:BigInt=1,first:BigInt=17,
                  stride:BigInt=3,count:BigInt=Count):
      BaseMonsterContext={
    val c=BaseMonsterContext(43,-9181)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_14_VIRTUAL_GATE_LIST"
    c.virtualFirstGateIndex=Some(first)
    c.virtualGateStride=Some(stride)
    c.virtualCandidateCount=Some(count)
    c.virtualRequestedRank=Some(rank)
    new Discovery14VirtualGateListHandler(new BaseMetricsShell).handle(c)
    c
  }

  def main(args:Array[String]):Unit={
    check("il primo candidato rispetta il rango 1-based"){
      val a=legacy()
      eqv(a.guessedGateIndex,BigInt(17),"Primo")
      eqv(a.narrowedRank,1,"Rango int")
    }
    check("il secondo candidato segue il passo positivo"){
      eqv(legacy(2).guessedGateIndex,BigInt(20),"Secondo")
    }
    check("l'ultimo rango signed Int positivo coincide"){
      val n=BigInt(Int.MaxValue)
      eqv(legacy(n).guessedGateIndex,normative(17,3,n),"Limite")
    }
    check("il passo signed negativo è calcolato correttamente per ranghi piccoli"){
      for(i<-1 to 1000)
        eqv(legacy(i,first=100,stride = -7).guessedGateIndex,
          normative(100,-7,i),"Rango "+i)
    }
    check("la prima divergenza comincia a Int.MaxValue più uno"){
      val n=BigInt(Int.MaxValue)+1
      val a=legacy(n)
      eqv(a.narrowedRank,Int.MinValue,"Wrapping")
      truth(a.guessedGateIndex!=normative(17,3,n),"Divergenza")
    }
    check("il rango 2^32 diventa zero senza abortire la cicatrice"){
      val n=BigInt(1)<<32
      val a=legacy(n)
      eqv(a.narrowedRank,0,"Troncamento")
      eqv(a.guessedGateIndex,BigInt(14),"Posizione storica")
    }
    check("il rango 2^32+1 torna al rango uno per il legacy"){
      val n=(BigInt(1)<<32)+1
      eqv(legacy(n).guessedGateIndex,BigInt(17),"Ritorno spurio")
    }
    check("il massimo signed positivo seguito dal negativo"){
      val a=legacy(BigInt(Int.MaxValue))
      val b=legacy(BigInt(Int.MaxValue)+1)
      truth(b.guessedGateIndex<a.guessedGateIndex,"Rottura monotonia")
    }
    check("un prefisso traslato oltre 16384 bit rimane esatto"){
      val a=legacy(13,first=Huge,stride=7)
      eqv(a.guessedGateIndex,Huge+84,"Prefisso huge")
    }
    check("il prefisso negativo oltre 16384 bit è supportato"){
      val a=legacy(13,first = -Huge,stride = -7)
      eqv(a.guessedGateIndex,-Huge-84,"Prefisso negativo")
    }
    check("l'ampiezza arbitraria del passo è preservata"){
      val a=legacy(3,first=17,stride=Huge)
      eqv(a.guessedGateIndex,17+2*Huge,"Passo huge")
    }
    check("il conteggio arbitrariamente alto non si converte in Int"){
      val hugeCount=BigInt(1)<<16384
      val a=legacy(1,count=hugeCount)
      eqv(a.candidateCount,hugeCount,"Cardinalità")
      eqv(a.guessedGateIndex,BigInt(17),"Primo")
    }
    check("il rango enorme viene memorizzato senza perdita nel report"){
      val rank=(BigInt(1)<<130)+100
      val a=legacy(rank)
      eqv(a.requestedRank,rank,"Rango")
      eqv(a.narrowedRank,100,"Residuo")
      truth(a.guessedGateIndex!=normative(17,3,rank),"Difetto")
    }
    check("4096 vettori deterministici nel dominio Int coincidono"){
      val rnd=new Random(20261012L)
      for(i<-1 to 4096){
        val rank=BigInt(1+rnd.nextInt(1000000))
        val start=BigInt(rnd.nextLong())
        val stride=BigInt(rnd.nextInt(100001)-50000)
        val safe=if(stride==0)BigInt(1) else stride
        eqv(legacy(rank,start,safe).guessedGateIndex,
          normative(start,safe,rank),"Campione "+i)
      }
    }
    check("2048 ranghi enormi rivelano esattamente il troncamento"){
      val rnd=new Random(28102026L)
      val modulo=BigInt(1)<<32
      for(i<-1 to 2048){
        val rank=(BigInt(1)<<64)+BigInt(1+rnd.nextInt(2000000))
        val a=legacy(rank)
        val residue=rank%modulo
        eqv(a.narrowedRank,residue.toInt,"Residuo "+i)
        eqv(a.guessedGateIndex,BigInt(17)+(BigInt(residue.toInt)-1)*3,
          "Formula legacy "+i)
        truth(a.guessedGateIndex!=normative(17,3,rank),
          "Cicatrice "+i)
      }
    }
    check("il valore di ritorno è immutabile dopo chiamate intercalate"){
      val first=legacy(2147483648L)
      for(i<-1 to 200)legacy(BigInt(i))
      eqv(legacy(2147483648L),first,"Determinismo")
    }
    check("due manager separati condividono soltanto la regola, non lo stato"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      eqv(a.discover14VirtualGateList(5,8,17,3,Count,1).legacySelectedGateIndex,
        BigInt(17),"Primo")
      eqv(b.discover14VirtualGateList(9,3,17,3,Count,2).legacySelectedGateIndex,
        BigInt(20),"Secondo")
      eqv(a.metricsSnapshot("discovery14.virtual.gate.calls"),BigInt(1),"Metriche")
      eqv(b.metricsSnapshot("discovery14.virtual.gate.calls"),BigInt(1),"Isolamento")
    }
    check("manager pubblica input, output, traccia e metriche"){
      val m=new BaseMonsterManager
      val r=m.discover14VirtualGateList(43,-9181,-Huge,7,Count,1)
      eqv(r.calculationDay,BigInt(43),"Calcolo")
      eqv(r.targetDay,BigInt(-9181),"Domanda")
      eqv(r.firstGateIndex,-Huge,"Primo")
      eqv(r.gateStride,BigInt(7),"Passo")
      eqv(r.candidateCount,Count,"Cardinalità")
      eqv(r.requestedRank,BigInt(1),"Richiesta")
      eqv(r.narrowedRank,1,"Int")
      eqv(r.legacySelectedGateIndex,-Huge,"Selezionato")
      eqv(r.phase,"DISCOVERY_14_VIRTUAL_GATE_LIST","Fase")
      eqv(r.status,"LEGACY_VIRTUAL_GATE_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_14_VIRTUAL_GATE_LIST"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery14.virtual.gate.calls"),BigInt(1),"Discovery")
    }
    check("manager riutilizzato incrementa le metriche senza alias"){
      val m=new BaseMonsterManager
      val x=m.discover14VirtualGateList(1,1,17,3,Count,1)
      val y=m.discover14VirtualGateList(1,1,17,3,Count,2)
      eqv(x.legacySelectedGateIndex,BigInt(17),"Vecchio report")
      eqv(y.legacySelectedGateIndex,BigInt(20),"Nuovo report")
      eqv(m.metricsSnapshot("discovery14.virtual.gate.calls"),BigInt(2),"Due")
    }
    check("rank zero e negativo sono respinti prima della conversione"){
      rejectArg("Zero"){legacy(0)}
      rejectArg("Negativo"){legacy(-1)}
    }
    check("il rango maggiore del totale è respinto"){
      rejectArg("Oltre"){legacy(Count+1)}
    }
    check("cardinalità nulla e negativa sono respinte"){
      rejectArg("Zero"){legacy(1,count=0)}
      rejectArg("Negativo"){legacy(1,count = -1)}
    }
    check("un passo nullo viene respinto"){
      rejectArg("Nullo"){legacy(1,stride=0)}
    }
    check("il limite rank uguale a cardinalità è incluso"){
      val count=BigInt(99)
      eqv(legacy(count,count=count).guessedGateIndex,
        normative(17,3,count),"Rango ultimo")
    }
    check("handler rifiuta contesto senza Bootstrap"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_14_VIRTUAL_GATE_LIST"
      rejectState("Nuovo"){
        new Discovery14VirtualGateListHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta i campi obbligatori mancanti"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_14_VIRTUAL_GATE_LIST"
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.virtualFirstGateIndex=Some(17)
      rejectState("Parziale"){
        new Discovery14VirtualGateListHandler(new BaseMetricsShell).handle(c)}
      truth(c.legacyVirtualNarrowedRank.isEmpty,"Non pubblicato")
    }
    check("handler non consente una seconda applicazione"){
      val c=ctx()
      rejectState("Doppio"){
        new Discovery14VirtualGateListHandler(new BaseMetricsShell).handle(c)}
    }
    check("validator accetta lo stato prodotto dal handler"){
      new BaseValidationManager().requireDiscovery14Ready(ctx())
    }
    check("validator accetta il rango signed massimo"){
      val c=ctx(BigInt(Int.MaxValue))
      new BaseValidationManager().requireDiscovery14Ready(c)
    }
    check("validator accetta il rango unsigned 2^32 e il suo zero storico"){
      val c=ctx(BigInt(1)<<32)
      new BaseValidationManager().requireDiscovery14Ready(c)
      eqv(c.legacyVirtualNarrowedRank,Some(0),"Zero troncato")
    }
    check("validator accetta valori enormi signed e passo negativo"){
      val c=ctx((BigInt(1)<<129)+7,-Huge,-Huge,Count)
      new BaseValidationManager().requireDiscovery14Ready(c)
    }
    check("validator rifiuta output falso"){
      val c=ctx()
      c.legacyVirtualSelectedGateIndex=Some(999)
      rejectState("Output"){new BaseValidationManager().requireDiscovery14Ready(c)}
    }
    check("validator rifiuta narrowedRank falsificato"){
      val c=ctx()
      c.legacyVirtualNarrowedRank=Some(2)
      rejectState("Narrowing"){new BaseValidationManager().requireDiscovery14Ready(c)}
    }
    check("validator rifiuta firstGateIndex mutato"){
      val c=ctx()
      c.virtualFirstGateIndex=Some(18)
      rejectState("Input"){new BaseValidationManager().requireDiscovery14Ready(c)}
    }
    check("validator rifiuta rango mutato"){
      val c=ctx()
      c.virtualRequestedRank=Some(2)
      rejectState("Rango"){new BaseValidationManager().requireDiscovery14Ready(c)}
    }
    check("validator rifiuta passo nullo e cardinalità invalida"){
      val c=ctx()
      c.virtualGateStride=Some(0)
      rejectState("Passo"){new BaseValidationManager().requireDiscovery14Ready(c)}
      c.virtualGateStride=Some(3)
      c.virtualCandidateCount=Some(0)
      rejectState("Cardinalità"){new BaseValidationManager().requireDiscovery14Ready(c)}
    }
    check("validator rifiuta status phase o trace alterati"){
      val c=ctx()
      val v=new BaseValidationManager
      c.status="BOOTSTRAPPED"
      rejectState("Stato"){v.requireDiscovery14Ready(c)}
      c.status="LEGACY_VIRTUAL_GATE_READY"
      c.branchTrace.remove(1)
      rejectState("Traccia"){v.requireDiscovery14Ready(c)}
      c.branchTrace.append("DISCOVERY_14_VIRTUAL_GATE_LIST")
      c.phase="PATCH_14_VIRTUAL_GATE_LIST"
      rejectState("Fase"){v.requireDiscovery14Ready(c)}
    }
    check("validator rifiuta output mancante"){
      val c=ctx()
      c.legacyVirtualSelectedGateIndex=None
      rejectState("Vuoto"){new BaseValidationManager().requireDiscovery14Ready(c)}
    }
    check("dodici patch normative precedenti e PATCH 13 ancora funzionano"){
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
    check("code Scala, oracolo test-only e nessuna PATCH 14"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val source=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!source.contains("NormativeOracle"),"Oracolo")
      truth(source.contains("object VirtualLegacyListAdapter"),"Cicatrice")
      truth(source.contains("val narrow=rank1.toInt"),"Troncamento vero")
      truth(!source.contains("def virtualGatePatch("),"PATCH14 anticipata")
    }
    check("metadati Stage28 conservano tutti i certificati precedenti"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=28"),"Stage28")
      truth(st.contains("CURRENT_KIND=DISCOVERY"),"DISCOVERY")
      truth(st.contains("CURRENT_PATCH=13"),"PATCH 13 preservata")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"RED")
      truth(st.contains("STAGE_27_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_39_PASS_0_FAIL"),
        "Certificato Stage27")
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed==27 || completed==28,"Sequenza")
    }

    Vector(
      ("rango 2147483648",BigInt(1)<<31),
      ("rango 4294967296",BigInt(1)<<32),
      ("rango 18446744073709551617",(BigInt(1)<<64)+1)
    ).foreach {case(label,rank) =>
      check("equivalenza normativa lista virtuale "+label){
        val r=new BaseMonsterManager().discover14VirtualGateList(
          1,2,17,3,Count,rank)
        eqv(r.legacySelectedGateIndex,normative(17,3,rank),
          "Troncamento Int cambia il candidato: "+label)
      }
    }
    println("\nRISULTATO STADIO 28: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
