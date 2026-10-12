package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH17: unrank lessicografico dei nomi distinti, base47 legacy separata. */
object Stage35Tests {
  private var passed=0
  private var failed=0
  private val Total47=NormativeOracle.fallingFactorial(47,47)
  private val Huge=(BigInt(1)<<16384)+1735

  private def check(label:String)(test: => Unit):Unit={
    try {test;passed+=1;println("PASS — "+label)}
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
  private def rejectArg(label:String)(test: => Unit):Unit={
    var caught=false
    try test catch {case _:IllegalArgumentException=>caught=true}
    truth(caught,label+": argomento illegale accettato")
  }
  private def rejectState(label:String)(test: => Unit):Unit={
    var caught=false
    try test catch {case _:IllegalStateException=>caught=true}
    truth(caught,label+": stato falsificato accettato")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }
  private def oracle(months:Int,rank:BigInt):Vector[Int]=
    NormativeOracle.unrankDistinctIndices(47,months,rank)
  private def patch(months:Int=3,rank:BigInt=1):
      Patch17DistinctMonthNamesResult=
    Patch17DistinctMonthNameWrapper.monthNameDistinctPatch(months,rank)
  private def count(months:Int):BigInt=
    NormativeOracle.fallingFactorial(47,months)

  // Inversione test-only indipendente da wrapper e oracolo:
  // codifica il vettore usando i prefissi delle disposizioni.
  private def inverse(names:Vector[Int]):BigInt={
    val remaining=scala.collection.mutable.ArrayBuffer.from(1 to 47)
    var zero=BigInt(0)
    for(pos<-names.indices){
      val digit=remaining.indexOf(names(pos))
      truth(digit>=0,"Nome già utilizzato nella codifica")
      var block=BigInt(1)
      for(j<-0 until names.length-pos-1)
        block*=BigInt(remaining.size-1-j)
      zero+=BigInt(digit)*block
      remaining.remove(digit)
    }
    zero+1
  }
  private def ready(months:Int=3,rank:BigInt=1):BaseMonsterContext={
    val ctx=BaseMonsterContext(43,-Huge)
    ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
    ctx.phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"
    ctx.monthNameCount=Some(months)
    ctx.monthNameRank1=Some(rank)
    new Discovery17DuplicatedMonthNameHandler(new BaseMetricsShell).handle(ctx)
    ctx.phase="PATCH_17_DISTINCT_MONTH_NAME"
    new Patch17DistinctMonthNameHandler(new BaseMetricsShell).handle(ctx)
    ctx
  }
  def main(args:Array[String]):Unit={
    check("tre nomi distinti iniziano con 1,2,3"){
      eqv(patch().correctedCanonicalNameIndices,Vector(1,2,3),"Primo")
    }
    check("secondo rango distinto è 1,2,4"){
      eqv(patch(3,2).correctedCanonicalNameIndices,Vector(1,2,4),"Secondo")
    }
    check("il rango 45 cambia terza cifra sino a 47"){
      eqv(patch(3,45).correctedCanonicalNameIndices,Vector(1,2,47),"Ultima")
    }
    check("il rango 46 riporta la seconda cifra"){
      eqv(patch(3,46).correctedCanonicalNameIndices,Vector(1,3,2),"Riporto")
    }
    check("il rango 2070 termina il primo blocco di nomi"){
      val names=patch(3,2070).correctedCanonicalNameIndices
      eqv(names,Vector(1,47,46),"Blocco")
    }
    check("il rango 2071 comincia il blocco col primo nome 2"){
      eqv(patch(3,2071).correctedCanonicalNameIndices,
        Vector(2,1,3),"Riporto maggiore")
    }
    check("l'ultimo rango di tre mesi è 47,46,45"){
      eqv(patch(3,count(3)).correctedCanonicalNameIndices,
        Vector(47,46,45),"Ultimo")
    }
    check("primo rango di 47 mesi copre catalogo crescente"){
      eqv(patch(47,1).correctedCanonicalNameIndices,
        (1 to 47).toVector,"Ordine")
    }
    check("secondo rango di 47 mesi scambia gli ultimi due"){
      val r=patch(47,2)
      eqv(r.correctedCanonicalNameIndices.take(45),(1 to 45).toVector,
        "Prefisso")
      eqv(r.correctedCanonicalNameIndices.takeRight(2),Vector(47,46),
        "Ultimi")
    }
    check("ultimo rango di 47 mesi inverte il catalogo"){
      eqv(patch(47,Total47).correctedCanonicalNameIndices,
        (1 to 47).reverse.toVector,"Ultima permutazione")
    }
    check("ultimo rango su 46 mesi resta senza ripetizioni"){
      val r=patch(46,count(46))
      eqv(r.correctedCanonicalNameIndices,(2 to 47).reverse.toVector,
        "Ultima disposizione 46")
    }
    check("rank e cardinalità grandi non vengono ristretti a Int"){
      truth(Total47>(BigInt(1)<<128),"Il prodotto 47! è enorme")
      val result=patch(47,Total47)
      eqv(result.historical.sourceRank1,Total47,"BigInt")
    }
    check("le 45 cardinalità da 3 a 47 mesi sono rispettate"){
      for(m<-3 to 47){
        val p=patch(m,count(m))
        eqv(p.correctedCanonicalNameIndices.size,m,"Dimensione "+m)
      }
    }
    check("il primo rango per ogni numero di mesi usa 1..m"){
      for(m<-3 to 47)
        eqv(patch(m,1).correctedCanonicalNameIndices,
          (1 to m).toVector,"Primo "+m)
    }
    check("l'ultimo rango coincide con l'oracolo per ogni mese"){
      for(m<-3 to 47){
        val rank=count(m)
        eqv(patch(m,rank).correctedCanonicalNameIndices,
          oracle(m,rank),"Ultimo "+m)
      }
    }
    check("il rango due coincide con l'oracolo per tutti i mesi"){
      for(m<-3 to 47)
        eqv(patch(m,2).correctedCanonicalNameIndices,
          oracle(m,2),"Secondo "+m)
    }
    check("tutti i 47 indici sono nel catalogo congelato"){
      for(m<-3 to 47;r<-Vector[BigInt](1,2,47,count(m))){
        val names=patch(m,r).correctedCanonicalNameIndices
        truth(names.forall(n=>n>=1 && n<=47),"Indice "+m)
      }
    }
    check("ogni nome viene usato al massimo una volta"){
      for(m<-3 to 47;r<-Vector[BigInt](1,2,47,count(m))){
        val names=patch(m,r).correctedCanonicalNameIndices
        eqv(names.distinct.size,m,"Unici "+m)
      }
    }
    check("l'inversa del rank è valida ai bordi per tutti i mesi"){
      for(m<-3 to 47;r<-Vector[BigInt](1,2,47,count(m))){
        eqv(inverse(patch(m,r).correctedCanonicalNameIndices),
          r,"Inversione "+m)
      }
    }
    check("i primi 2071 ranghi di tre mesi coincidono con oracolo"){
      for(rank<-1 to 2071)
        eqv(patch(3,rank).correctedCanonicalNameIndices,
          oracle(3,rank),"Rango "+rank)
    }
    check("i primi 4096 ranghi di tre mesi sono tutti distinti"){
      val values=(1 to 4096).map(i=>
        patch(3,i).correctedCanonicalNameIndices).toVector
      eqv(values.distinct.length,4096,"Iniettività")
    }
    check("la sequenza lessicografica cresce strettamente sui primi 4096"){
      var last=Vector.empty[Int]
      for(rank<-1 to 4096){
        val next=patch(3,rank).correctedCanonicalNameIndices
        if(rank>1)truth(
          last.zip(next).find{case (a,b)=>a!=b}.exists{
            case (a,b)=>a<b
          },"Ordine rango "+rank)
        last=next
      }
    }
    check("4096 campioni random per 3..47 mesi concordano con l'oracolo"){
      val rng=new Random(35102026L)
      for(i<-1 to 4096){
        val m=3+rng.nextInt(45)
        val n=count(m)
        val raw=BigInt(1,new Array[Byte](0)++{
          val b=new Array[Byte](32);rng.nextBytes(b);b
        })
        val rank=(raw%n)+1
        val names=patch(m,rank).correctedCanonicalNameIndices
        eqv(names,oracle(m,rank),"Campione "+i)
      }
    }
    check("4096 altri campioni riproducono il rango inverso"){
      val rng=new Random(17351026L)
      for(i<-1 to 4096){
        val m=3+rng.nextInt(45)
        val n=count(m)
        val b=new Array[Byte](32);rng.nextBytes(b)
        val rank=(BigInt(1,b)%n)+1
        val names=patch(m,rank).correctedCanonicalNameIndices
        eqv(inverse(names),rank,"Inversa "+i)
        eqv(names.distinct.length,m,"Nomi distinti "+i)
      }
    }
    check("i primi 128 ranghi completi da 47 nomi coincidono con l'oracolo"){
      for(rank<-1 to 128)
        eqv(patch(47,rank).correctedCanonicalNameIndices,
          oracle(47,rank),"47! "+rank)
    }
    check("ranghi di 47 mesi sopra 128 bit concordano con l'oracolo"){
      val base=BigInt(1)<<150
      for(i<-0 until 512){
        val rank=base+BigInt(i)
        eqv(patch(47,rank).correctedCanonicalNameIndices,
          oracle(47,rank),"BigInt "+i)
      }
    }
    check("il vecchio rango primo resta il nome 1 duplicato"){
      val r=patch(3,1)
      eqv(r.historical.legacyCanonicalNameIndices,Vector(1,1,1),
        "Legacy")
      eqv(r.correctedCanonicalNameIndices,Vector(1,2,3),"Patch")
    }
    check("il vecchio rango due resta distinto dalla PATCH 17"){
      val r=patch(3,2)
      eqv(r.historical.legacyCanonicalNameIndices,Vector(1,1,2),
        "Legacy")
      eqv(r.correctedCanonicalNameIndices,Vector(1,2,4),"Patch")
    }
    check("il vecchio rango primo di 47 mesi continua a duplicare"){
      val r=patch(47,1)
      eqv(r.historical.legacyCanonicalNameIndices,Vector.fill(47)(1),
        "Legacy")
      eqv(r.correctedCanonicalNameIndices,(1 to 47).toVector,
        "Patch")
    }
    check("ogni esecuzione invoca davvero il percorso storico"){
      for(m<-3 to 47;r<-Vector[BigInt](1,2,47,count(m))){
        val got=patch(m,r)
        eqv(got.historical,
          LegacyDuplicatedMonthNameAdapter.oldMonthNameDuplicated(m,r),
          "Cicatrice "+m)
      }
    }
    check("intercalare migliaia di richieste non cambia i report"){
      val old=patch(3,1)
      for(i<-1 to 256)patch(47,BigInt(i))
      eqv(patch(3,1),old,"Immutabilità")
    }
    check("primo e ultimo rank 47 sono deterministici"){
      eqv(patch(47,1),patch(47,1),"Primo")
      eqv(patch(47,Total47),patch(47,Total47),"Ultimo")
    }
    check("la cardinalità distinta non coincide con 47^m"){
      for(m<-3 to 47){
        val r=patch(m,1)
        truth(r.historical.permittedDistinctChoices<
          r.historical.legacyReplacementSpace,"Distinti "+m)
      }
    }
    check("rifiuta meno di tre mesi"){
      rejectArg("2"){patch(2,1)}
      rejectArg("0"){patch(0,1)}
    }
    check("rifiuta piu' di 47 mesi"){
      rejectArg("48"){patch(48,1)}
    }
    check("rifiuta rank zero"){
      rejectArg("Zero"){patch(3,0)}
    }
    check("rifiuta rank negativo"){
      rejectArg("Negativo"){patch(3,-1)}
    }
    check("rifiuta rank sopra P(47,3)"){
      rejectArg("Oltre"){patch(3,count(3)+1)}
    }
    check("rifiuta rank sopra il fattoriale 47"){
      rejectArg("Oltre massimo"){patch(47,Total47+1)}
    }
    check("rifiuta rank gigantesco oltre il dominio"){
      rejectArg("16384 bit"){patch(47,Huge)}
    }
    check("il manager rende disponibili entrambe le scelte di nomi"){
      val m=new BaseMonsterManager
      val r=m.patch17DistinctMonthName(Huge,-Huge,3,1)
      eqv(r.calculationDay,Huge,"Azione")
      eqv(r.targetDay,-Huge,"Domanda")
      eqv(r.monthCount,3,"Mesi")
      eqv(r.rank1,BigInt(1),"Rango")
      eqv(r.permittedDistinctChoices,count(3),"Cardinalità")
      eqv(r.legacyReplacementSpace,BigInt(47).pow(3),"Spazio")
      eqv(r.legacyCanonicalNameIndices,Vector(1,1,1),"Legacy")
      eqv(r.correctedCanonicalNameIndices,Vector(1,2,3),"Patch")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_17_DISTINCT_MONTH_NAME","Fase")
      eqv(r.status,"PATCH_17_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_17_DUPLICATED_MONTH_NAME",
        "PATCH_17_DISTINCT_MONTH_NAME"),"Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery17.month.names.calls"),BigInt(1),
        "Discovery")
      eqv(m.metricsSnapshot("patch17.distinct.month.names.calls"),BigInt(1),
        "Patch")
    }
    check("il manager accetta 47 mesi e il massimo BigInt"){
      val r=new BaseMonsterManager().patch17DistinctMonthName(
        Huge,-Huge,47,Total47)
      eqv(r.correctedCanonicalNameIndices,
        (1 to 47).reverse.toVector,"Ultima")
      eqv(r.rank1,Total47,"Rango")
    }
    check("manager riutilizzato non contamina report precedenti"){
      val m=new BaseMonsterManager
      val a=m.patch17DistinctMonthName(1,2,3,1)
      val b=m.patch17DistinctMonthName(3,4,3,2)
      eqv(a.correctedCanonicalNameIndices,Vector(1,2,3),"A")
      eqv(b.correctedCanonicalNameIndices,Vector(1,2,4),"B")
      eqv(a.legacyCanonicalNameIndices,Vector(1,1,1),"Cicatrice")
      eqv(m.metricsSnapshot("patch17.distinct.month.names.calls"),
        BigInt(2),"Contatore")
    }
    check("due manager tengono separate le proprie metriche"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      eqv(a.patch17DistinctMonthName(1,2,3,1).correctedCanonicalNameIndices,
        Vector(1,2,3),"A")
      eqv(b.patch17DistinctMonthName(3,4,3,2).correctedCanonicalNameIndices,
        Vector(1,2,4),"B")
      eqv(a.metricsSnapshot("patch17.distinct.month.names.calls"),
        BigInt(1),"Metrica A")
      eqv(b.metricsSnapshot("patch17.distinct.month.names.calls"),
        BigInt(1),"Metrica B")
    }
    check("la stessa istanza manager attraversa 45 cardinalità"){
      val m=new BaseMonsterManager
      for(k<-3 to 47){
        val r=m.patch17DistinctMonthName(0,0,k,count(k))
        eqv(r.correctedCanonicalNameIndices,oracle(k,count(k)),"Nomi")
      }
      eqv(m.metricsSnapshot("patch17.distinct.month.names.calls"),
        BigInt(45),"Metriche")
    }
    check("il manager legacy di sola discovery resta invariato"){
      val m=new BaseMonsterManager
      val old=m.discover17DuplicatedMonthName(1,2,3,1)
      val now=m.patch17DistinctMonthName(1,2,3,1)
      eqv(old.legacyCanonicalNameIndices,now.legacyCanonicalNameIndices,
        "Legacy")
      truth(old.legacyCanonicalNameIndices!=
        now.correctedCanonicalNameIndices,"Difetto conservato")
    }
    check("handler rifiuta contesto senza bootstrap"){
      val c=BaseMonsterContext(1,2);c.phase="PATCH_17_DISTINCT_MONTH_NAME"
      rejectState("Senza BOOT"){
        new Patch17DistinctMonthNameHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta bootstrap senza discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_17_DISTINCT_MONTH_NAME"
      rejectState("Senza legacy"){
        new Patch17DistinctMonthNameHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler non ammette doppia applicazione"){
      val c=ready()
      rejectState("Doppia PATCH"){
        new Patch17DistinctMonthNameHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta legacy manomesso senza pubblicare il nuovo output"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.monthNameCount=Some(3);c.monthNameRank1=Some(1)
      c.phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"
      new Discovery17DuplicatedMonthNameHandler(new BaseMetricsShell).handle(c)
      c.phase="PATCH_17_DISTINCT_MONTH_NAME"
      c.legacyMonthNameIndices=Some(Vector(1,1,2))
      rejectState("Falsificazione"){
        new Patch17DistinctMonthNameHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedDistinctMonthNameIndices.isEmpty,"Nessun output")
      truth(!c.patch17Applied,"Flag assente")
    }
    check("handler rifiuta rango post-hoc anche se coincide il primo nome"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.monthNameCount=Some(3);c.monthNameRank1=Some(1)
      c.phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"
      new Discovery17DuplicatedMonthNameHandler(new BaseMetricsShell).handle(c)
      c.phase="PATCH_17_DISTINCT_MONTH_NAME"
      c.monthNameRank1=Some(2)
      rejectState("Rango mutato"){
        new Patch17DistinctMonthNameHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedDistinctMonthNameIndices.isEmpty,"Nessuna pubblicazione")
    }
    check("validator accetta un contesto autentico"){
      new BaseValidationManager().requirePatch17Ready(ready())
    }
    check("validator indipendente accetta tutti i 45 conteggi mensili"){
      val v=new BaseValidationManager
      for(m<-3 to 47)v.requirePatch17Ready(ready(m,1))
    }
    check("validator accetta l'ultimo rango per ogni numero di mesi"){
      val v=new BaseValidationManager
      for(m<-3 to 47)v.requirePatch17Ready(ready(m,count(m)))
    }
    check("validator accetta 128 ranghi completi di 47 mesi"){
      val v=new BaseValidationManager
      for(rank<-1 to 128)v.requirePatch17Ready(ready(47,rank))
    }
    check("validator accetta grandi ranghi BigInt e li inverte"){
      val v=new BaseValidationManager
      for(i<-0 until 64)
        v.requirePatch17Ready(ready(47,(BigInt(1)<<150)+i))
    }
    check("validator rifiuta i nomi corretti falsificati"){
      val c=ready()
      c.patchedDistinctMonthNameIndices=Some(Vector(1,2,4))
      rejectState("Correzione falsa"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta la duplicazione di un nome corretto"){
      val c=ready()
      c.patchedDistinctMonthNameIndices=Some(Vector(1,1,2))
      rejectState("Duplicato"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta un nome corretto fuori 1..47"){
      for(bad<-Vector(0,48)){
        val c=ready()
        c.patchedDistinctMonthNameIndices=Some(Vector(1,2,bad))
        rejectState("Fuori catalogo"){
          new BaseValidationManager().requirePatch17Ready(c)}
      }
    }
    check("validator rifiuta la cicatrice storica cambiata"){
      val c=ready()
      c.legacyMonthNameIndices=Some(Vector(1,1,2))
      rejectState("Legacy"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta il prodotto decrescente falsificato"){
      val c=ready()
      c.legacyMonthNameDistinctChoices=Some(BigInt(47).pow(3))
      rejectState("Cardinalità"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta il prodotto con rimpiazzo falsificato"){
      val c=ready()
      c.legacyMonthNameReplacementSpace=Some(BigInt(1))
      rejectState("Sostituzione"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta rango post-hoc"){
      val c=ready()
      c.monthNameRank1=Some(2)
      rejectState("Rank"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta conteggio mensile post-hoc"){
      val c=ready()
      c.monthNameCount=Some(4)
      rejectState("Mesi"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta snapshot falsificata"){
      val c=ready()
      c.monthNameInputSnapshot=Some((3,BigInt(2)))
      rejectState("Snapshot"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta snapshot assente"){
      val c=ready()
      c.monthNameInputSnapshot=None
      rejectState("Assente"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta output corretto assente"){
      val c=ready()
      c.patchedDistinctMonthNameIndices=None
      rejectState("Output"){
        new BaseValidationManager().requirePatch17Ready(c)}
    }
    check("validator rifiuta flag status phase e trace manomessi"){
      val c=ready()
      val v=new BaseValidationManager
      c.patch17Applied=false
      rejectState("Flag"){v.requirePatch17Ready(c)}
      c.patch17Applied=true
      c.status="LEGACY_DUPLICATED_MONTH_NAMES_READY"
      rejectState("Status"){v.requirePatch17Ready(c)}
      c.status="PATCH_17_READY"
      c.branchTrace.remove(1)
      rejectState("Trace"){v.requirePatch17Ready(c)}
      c.branchTrace.insert(1,"DISCOVERY_17_DUPLICATED_MONTH_NAME")
      c.phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"
      rejectState("Phase"){v.requirePatch17Ready(c)}
    }
    check("le sedici PATCH precedenti funzionano ancora"){
      val m=new BaseMonsterManager
      val mod=NormativeOracle.M
      val foundation=NormativeOracle.FoundationDay
      val A=Vector.fill(84)(1)++Vector.fill(84)(2)++Vector.fill(84)(3)
      val B=Vector(1,2)++Vector.fill(83)(1)++
        Vector.fill(83)(2)++Vector.fill(84)(3)
      val C=Vector(1,1,2)++Vector.fill(82)(1)++
        Vector.fill(83)(2)++Vector.fill(84)(3)
      eqv(m.patch01Save(0,0,mod).patchedOutput,mod,"P01")
      eqv(m.patch02DayTag(foundation,foundation,foundation).patchedTag,
        BigInt(1),"P02")
      eqv(m.patch03Distance(foundation,foundation).patchedDistance,
        BigInt(1),"P03")
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
      eqv(m.patch15DaywiseWeaving(0,0,Vector(A,C,B),2,2).correctedDayInMonth,
        1,"P15")
      eqv(m.patch16ContiguousMonthDay(0,0,C,2).correctedDayInMonth,1,"P16")
    }
    check("oracolo test-only, nome legacy conservato e nessuna Stage36"){
      val walk=Files.walk(root().resolve("src/main/scala"))
      val sources=try walk.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally walk.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo solo test")
      truth(sources.contains("def oldMonthNameDuplicated("),"Legacy storico")
      truth(sources.contains("def monthNameDistinctPatch("),"PATCH17")
      truth(!sources.contains("oldSourceCatalogMismatch"),"Stage36 assente")
    }
    check("metadati Stage35 certificano la storia senza cambiarla"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=35"),"Current")
      truth(st.contains("CURRENT_KIND=PATCH"),"Tipo")
      truth(st.contains("CURRENT_PATCH=17"),"Patch")
      truth(st.contains("STAGE_34_NATIVE_VERIFICATION=PASS_EXPECTED_RED_63_PASS_3_FAIL"),
        "DISCOVERY17 certificata")
      truth(st.contains("STAGE_33_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_65_PASS_0_FAIL"),
        "PATCH16 certificata")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(done==34 || done==35,"Sequenza")
    }
    println("\nRISULTATO STADIO 35: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
