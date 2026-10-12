package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 17: i nomi mensili sono scelti con rimpiazzo nel legacy. */
object Stage34Tests {
  private var passed=0
  private var failed=0
  private val Huge=(BigInt(1)<<16384)+451
  private val All47=NormativeOracle.fallingFactorial(47,47)

  private def check(label:String)(f: => Unit):Unit={
    try { f;passed+=1;println("PASS — "+label) }
    catch { case ex:Throwable =>
      failed+=1
      println("FAIL — "+label+" — "+ex.getMessage)
      ex.printStackTrace(System.out)
    }
  }
  private def eqv[A](actual:A,expected:A,label:String):Unit={
    if(actual!=expected)
      throw new AssertionError(
        label+": atteso="+expected+", ottenuto="+actual)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(f: => Unit):Unit={
    var caught=false
    try f catch {case _:IllegalArgumentException=>caught=true}
    truth(caught,label+": parametro illegale accettato")
  }
  private def rejectState(label:String)(f: => Unit):Unit={
    var caught=false
    try f catch {case _:IllegalStateException=>caught=true}
    truth(caught,label+": stato falsificato accettato")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }

  private def legacy(months:Int=3,rank:BigInt=1):
      LegacyDuplicatedMonthNameResult =
    LegacyDuplicatedMonthNameAdapter.oldMonthNameDuplicated(months,rank)

  // Riferimento solo test: disposizioni SENZA ripetizione nell'ordine
  // lessicografico del catalogo immutabile dei 47 nomi.
  private def normative(months:Int,rank:BigInt):Vector[Int] =
    NormativeOracle.unrankDistinctIndices(47,months,rank)

  private def independentBase47(months:Int,rank:BigInt):Vector[Int]={
    val chars=Array.fill[Int](months)(1)
    var rest=rank-1
    var k=months-1
    while(k>=0){
      chars(k)=(rest%47).toInt+1
      rest/=47
      k-=1
    }
    truth(rest==0,"Nessun digit perso")
    chars.toVector
  }

  private def ready(months:Int=3,rank:BigInt=1):BaseMonsterContext={
    val ctx=BaseMonsterContext(43,-Huge)
    ctx.status="BOOTSTRAPPED"
    ctx.branchTrace.append("BOOT")
    ctx.phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"
    ctx.monthNameCount=Some(months)
    ctx.monthNameRank1=Some(rank)
    new Discovery17DuplicatedMonthNameHandler(new BaseMetricsShell).handle(ctx)
    ctx
  }

  def main(args:Array[String]):Unit={
    check("47 indici distinti appartengono al catalogo canonico"){
      eqv(NormativeOracle.fallingFactorial(47,47),All47,"Catalogo")
      truth(All47>(BigInt(1)<<128),"Rango arbitariamente grande")
    }
    check("il numero minimo di mesi e' tre"){
      eqv(legacy().monthCount,3,"Minimo")
    }
    check("il numero massimo di mesi e' quarantasette"){
      eqv(legacy(47).monthCount,47,"Massimo")
    }
    check("il rango minimo annuale e' uno"){
      eqv(legacy().sourceRank1,BigInt(1),"Primo")
    }
    check("il primo rango restituisce tre nomi identici nel legacy"){
      eqv(legacy().legacyCanonicalNameIndices,Vector(1,1,1),"Cicatrice")
    }
    check("il rango due resta la seconda parola base47"){
      eqv(legacy(3,2).legacyCanonicalNameIndices,
        Vector(1,1,2),"Rango")
    }
    check("il rango 47 conclude con nome 47"){
      eqv(legacy(3,47).legacyCanonicalNameIndices,
        Vector(1,1,47),"Unita'")
    }
    check("il rango 48 porta un riporto nella seconda posizione"){
      eqv(legacy(3,48).legacyCanonicalNameIndices,
        Vector(1,2,1),"Riporto")
    }
    check("il rango 2209 porta un riporto nella prima posizione"){
      eqv(legacy(3,2209).legacyCanonicalNameIndices,
        Vector(2,1,1),"Riporto superiore")
    }
    check("spazio con rimpiazzo per tre mesi e' 47^3"){
      eqv(legacy(3).legacyReplacementSpace,BigInt(47).pow(3),
        "Sostituzione")
    }
    check("spazio senza rimpiazzo per tre mesi e' 47*46*45"){
      eqv(legacy(3).permittedDistinctChoices,BigInt(47*46*45),
        "Decrescente")
    }
    check("il rango massimo da tre mesi resta entro lo spazio distinto"){
      val max=NormativeOracle.fallingFactorial(47,3)
      val r=legacy(3,max)
      eqv(r.sourceRank1,max,"Ultimo")
      eqv(r.legacyCanonicalNameIndices,independentBase47(3,max),
        "Base47")
    }
    check("il rango massimo di 47 mesi non perde alcun bit"){
      val r=legacy(47,All47)
      eqv(r.sourceRank1,All47,"Rango")
      eqv(r.legacyCanonicalNameIndices,independentBase47(47,All47),
        "Cifre")
    }
    check("per 47 mesi lo spazio legacy e' maggiore del fattoriale"){
      val r=legacy(47)
      eqv(r.legacyReplacementSpace,BigInt(47).pow(47),"Potenza")
      truth(r.legacyReplacementSpace>r.permittedDistinctChoices,
        "Modello con rimpiazzo")
    }
    check("il primo rango di 47 mesi ripete 47 volte il nome uno"){
      eqv(legacy(47).legacyCanonicalNameIndices,Vector.fill(47)(1),
        "Tutti duplicati")
    }
    check("nessun nome legacy esce dall'intervallo 1..47"){
      for(m<-3 to 47){
        val r=legacy(m,NormativeOracle.fallingFactorial(47,m))
        truth(r.legacyCanonicalNameIndices.forall(x=>x>=1 && x<=47),
          "Catalogo "+m)
      }
    }
    check("la cardinalita' distinta cala rispetto alle parole con rimpiazzo"){
      for(m<-3 to 47){
        val x=legacy(m)
        truth(x.permittedDistinctChoices<x.legacyReplacementSpace,
          "Famiglia "+m)
      }
    }
    check("le 45 cardinalita' normative sono prodotti decrescenti"){
      for(m<-3 to 47){
        var n=BigInt(1)
        for(k<-0 until m)n*=47-k
        eqv(legacy(m).permittedDistinctChoices,n,"Cardinalita' "+m)
      }
    }
    check("2048 ranghi piccoli seguono la formula base47 esatta"){
      val rnd=new Random(34102026L)
      for(i<-1 to 2048){
        val m=3+rnd.nextInt(9)
        val cap=NormativeOracle.fallingFactorial(47,m)
        val rank=BigInt(1+rnd.nextInt(100000)).min(cap)
        val x=legacy(m,rank)
        eqv(x.legacyCanonicalNameIndices,independentBase47(m,rank),
          "Campione "+i)
      }
    }
    check("2048 ranghi grandi restano esatti anche sopra 128 bit"){
      val rnd=new Random(1703412L)
      for(i<-1 to 2048){
        val cap=All47
        val randomBytes=new Array[Byte](24)
        rnd.nextBytes(randomBytes)
        val rank=(BigInt(1,randomBytes)%cap)+1
        val x=legacy(47,rank)
        eqv(x.legacyCanonicalNameIndices,independentBase47(47,rank),
          "BigInt "+i)
      }
    }
    check("tutti i ranghi 1..2209 attraversano la portata base47"){
      for(rank<-1 to 2209)
        eqv(legacy(3,rank).legacyCanonicalNameIndices,
          independentBase47(3,rank),"Rank "+rank)
    }
    check("i primi 47 ranghi danno 47 diversi nomi nella terza sede"){
      eqv((1 to 47).map(k=>legacy(3,k).legacyCanonicalNameIndices.last)
        .toVector,(1 to 47).toVector,"Ultima cifra")
    }
    check("il modello senza rimpiazzo non ripete nomi"){
      for(m<-Vector(3,4,11,23,47);r<-Vector[BigInt](1,2,47)){
        val oracle=normative(m,r)
        truth(oracle.distinct.size==m,"Distinti "+m+" "+r)
      }
    }
    check("il primo rango normativo di tre mesi e' 1,2,3"){
      eqv(normative(3,1),Vector(1,2,3),"Distinti")
    }
    check("il primo rango normativo di 47 mesi e' 1..47"){
      eqv(normative(47,1),(1 to 47).toVector,"Catalogo intero")
    }
    check("l'ultimo rango normativo di 47 mesi e' decrescente"){
      eqv(normative(47,All47),(1 to 47).reverse.toVector,"Ultimo")
    }
    check("l'ultimo rango normativo di tre mesi e' 47,46,45"){
      val max=NormativeOracle.fallingFactorial(47,3)
      eqv(normative(3,max),Vector(47,46,45),"Ultimo")
    }
    check("l'indice nome errato resta indipendente dal giorno richiesto"){
      val m=new BaseMonsterManager
      val r1=m.discover17DuplicatedMonthName(1,0,3,1)
      val r2=m.discover17DuplicatedMonthName(1,1000,3,1)
      eqv(r1.legacyCanonicalNameIndices,r2.legacyCanonicalNameIndices,
        "Selezione annua")
    }
    check("la tessitura valida non altera la scelta dei nomi per rango"){
      val m=new BaseMonsterManager
      val first=m.discover17DuplicatedMonthName(20,30,3,2)
      val second=m.discover17DuplicatedMonthName(40,50,3,2)
      eqv(first.legacyCanonicalNameIndices,second.legacyCanonicalNameIndices,
        "Nomi")
    }
    check("una chiamata successiva non muta il rapporto precedente"){
      val m=new BaseMonsterManager
      val saved=m.discover17DuplicatedMonthName(1,2,3,1)
      for(r<-2 to 100)m.discover17DuplicatedMonthName(1,2,3,r)
      eqv(saved.legacyCanonicalNameIndices,Vector(1,1,1),"Storico")
      eqv(saved.rank1,BigInt(1),"Rank")
    }
    check("la selezione non condivide buffer fra invocazioni"){
      val x=legacy(47,1)
      for(i<-1 to 100)legacy(47,i)
      eqv(x.legacyCanonicalNameIndices,Vector.fill(47)(1),"Immutabile")
    }
    check("i casi minimi e massimi sono deterministici"){
      for(m<-3 to 47){
        val cap=NormativeOracle.fallingFactorial(47,m)
        eqv(legacy(m,1),legacy(m,1),"Primo "+m)
        eqv(legacy(m,cap),legacy(m,cap),"Ultimo "+m)
      }
    }
    check("non si accettano meno di tre mesi"){
      rejectArg("2 mesi"){legacy(2)}
      rejectArg("0 mesi"){legacy(0)}
      rejectArg("Negativo"){legacy(-1)}
    }
    check("non si accettano piu' di quarantasette mesi"){
      rejectArg("48 mesi"){legacy(48)}
    }
    check("non si accetta il rango nullo"){
      rejectArg("Rango zero"){legacy(3,0)}
    }
    check("non si accetta il rango negativo"){
      rejectArg("Rango negativo"){legacy(3,-1)}
    }
    check("non si accetta il rango sopra il prodotto decrescente"){
      val max=NormativeOracle.fallingFactorial(47,3)
      rejectArg("Oltre massimo"){legacy(3,max+1)}
    }
    check("non si accetta un rango enorme sopra 47!"){
      rejectArg("Gigante"){legacy(47,Huge)}
    }
    check("il vecchio rango non viene ridotto automaticamente modulo 47!"){
      rejectArg("Non si puo' riciclare il rank"){legacy(47,All47+1)}
    }
    check("il manager pubblica la cicatrice e una trace di due fasi"){
      val m=new BaseMonsterManager
      val r=m.discover17DuplicatedMonthName(43,-Huge,3,1)
      eqv(r.calculationDay,BigInt(43),"Azione")
      eqv(r.targetDay,-Huge,"Domanda")
      eqv(r.monthCount,3,"Numero mesi")
      eqv(r.rank1,BigInt(1),"Rank")
      eqv(r.permittedDistinctChoices,BigInt(47*46*45),"Distinti")
      eqv(r.legacyReplacementSpace,BigInt(47).pow(3),"Vecchio spazio")
      eqv(r.legacyCanonicalNameIndices,Vector(1,1,1),"Legacy")
      eqv(r.phase,"DISCOVERY_17_DUPLICATED_MONTH_NAME","Fase")
      eqv(r.status,"LEGACY_DUPLICATED_MONTH_NAMES_READY","Status")
      eqv(r.trace,Vector("BOOT","DISCOVERY_17_DUPLICATED_MONTH_NAME"),
        "Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery17.month.names.calls"),BigInt(1),
        "Metrica")
    }
    check("l'ultimo rango di 47 mesi attraversa il manager"){
      val m=new BaseMonsterManager
      val r=m.discover17DuplicatedMonthName(Huge,-Huge,47,All47)
      eqv(r.calculationDay,Huge,"Giorno BigInt")
      eqv(r.targetDay,-Huge,"Target")
      eqv(r.legacyCanonicalNameIndices,
        independentBase47(47,All47),"Unrank")
    }
    check("manager riusato preserva rapporti separati"){
      val m=new BaseMonsterManager
      val a=m.discover17DuplicatedMonthName(1,2,3,1)
      val b=m.discover17DuplicatedMonthName(3,4,3,2)
      eqv(a.legacyCanonicalNameIndices,Vector(1,1,1),"A")
      eqv(b.legacyCanonicalNameIndices,Vector(1,1,2),"B")
      eqv(m.metricsSnapshot("discovery17.month.names.calls"),BigInt(2),"Metrica")
    }
    check("due manager hanno metriche e stato separati"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      eqv(a.discover17DuplicatedMonthName(1,2,3,1).legacyCanonicalNameIndices,
        Vector(1,1,1),"Manager A")
      eqv(b.discover17DuplicatedMonthName(3,4,3,2).legacyCanonicalNameIndices,
        Vector(1,1,2),"Manager B")
      eqv(a.metricsSnapshot("discovery17.month.names.calls"),BigInt(1),"A")
      eqv(b.metricsSnapshot("discovery17.month.names.calls"),BigInt(1),"B")
    }
    check("handler rifiuta contesto mai bootstrapped"){
      val ctx=BaseMonsterContext(1,2)
      ctx.phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"
      rejectState("Nessun BOOT"){
        new Discovery17DuplicatedMonthNameHandler(new BaseMetricsShell).handle(ctx)}
    }
    check("handler rifiuta input incompleti"){
      val ctx=BaseMonsterContext(1,2)
      ctx.status="BOOTSTRAPPED";ctx.branchTrace.append("BOOT")
      ctx.phase="DISCOVERY_17_DUPLICATED_MONTH_NAME"
      ctx.monthNameCount=Some(3)
      rejectState("Manca rank"){
        new Discovery17DuplicatedMonthNameHandler(new BaseMetricsShell).handle(ctx)}
      truth(ctx.legacyMonthNameIndices.isEmpty,"Output non pubblicato")
    }
    check("handler rifiuta una seconda applicazione"){
      val ctx=ready()
      rejectState("Doppia discovery"){
        new Discovery17DuplicatedMonthNameHandler(new BaseMetricsShell).handle(ctx)}
    }
    check("validator accetta il contesto autentico"){
      new BaseValidationManager().requireDiscovery17Ready(ready())
    }
    check("validator accetta ogni cardinalita' mensile"){
      val v=new BaseValidationManager
      for(m<-3 to 47)v.requireDiscovery17Ready(ready(m,1))
    }
    check("validator accetta gli ultimi ranghi per 3..47 mesi"){
      val v=new BaseValidationManager
      for(m<-3 to 47)
        v.requireDiscovery17Ready(ready(m,
          NormativeOracle.fallingFactorial(47,m)))
    }
    check("validator accetta oltre cento ranghi distinti"){
      val v=new BaseValidationManager
      for(r<-1 to 128)v.requireDiscovery17Ready(ready(5,r))
    }
    check("validator rifiuta un nome storico falsificato"){
      val ctx=ready()
      ctx.legacyMonthNameIndices=Some(Vector(1,1,2))
      rejectState("Nomi"){new BaseValidationManager().requireDiscovery17Ready(ctx)}
    }
    check("validator rifiuta un indice catalogo 0 o 48"){
      for(bad<-Vector(0,48)){
        val ctx=ready()
        ctx.legacyMonthNameIndices=Some(Vector(bad,1,1))
        rejectState("Catalogo"){new BaseValidationManager().requireDiscovery17Ready(ctx)}
      }
    }
    check("validator rifiuta uno spazio distinto falsificato"){
      val ctx=ready()
      ctx.legacyMonthNameDistinctChoices=Some(BigInt(47).pow(3))
      rejectState("Spazio"){new BaseValidationManager().requireDiscovery17Ready(ctx)}
    }
    check("validator rifiuta lo spazio con rimpiazzo falsificato"){
      val ctx=ready()
      ctx.legacyMonthNameReplacementSpace=Some(BigInt(1))
      rejectState("Sostituzione"){
        new BaseValidationManager().requireDiscovery17Ready(ctx)}
    }
    check("validator rifiuta il rango cambiato dopo la discovery"){
      val ctx=ready()
      ctx.monthNameRank1=Some(2)
      rejectState("Rank post-hoc"){
        new BaseValidationManager().requireDiscovery17Ready(ctx)}
    }
    check("validator rifiuta il numero di mesi alterato"){
      val ctx=ready()
      ctx.monthNameCount=Some(4)
      rejectState("Mesi post-hoc"){
        new BaseValidationManager().requireDiscovery17Ready(ctx)}
    }
    check("validator rifiuta la snapshot falsificata"){
      val ctx=ready()
      ctx.monthNameInputSnapshot=Some((3,BigInt(2)))
      rejectState("Snapshot"){
        new BaseValidationManager().requireDiscovery17Ready(ctx)}
    }
    check("validator rifiuta lo snapshot mancante"){
      val ctx=ready()
      ctx.monthNameInputSnapshot=None
      rejectState("Snapshot assente"){
        new BaseValidationManager().requireDiscovery17Ready(ctx)}
    }
    check("validator rifiuta output mancanti"){
      val ctx=ready()
      ctx.legacyMonthNameIndices=None
      rejectState("Output"){
        new BaseValidationManager().requireDiscovery17Ready(ctx)}
    }
    check("validator rifiuta trace, phase e status alterati"){
      val ctx=ready()
      val v=new BaseValidationManager
      ctx.status="BOOTSTRAPPED"
      rejectState("Status"){v.requireDiscovery17Ready(ctx)}
      ctx.status="LEGACY_DUPLICATED_MONTH_NAMES_READY"
      ctx.branchTrace.remove(1)
      rejectState("Trace"){v.requireDiscovery17Ready(ctx)}
      ctx.branchTrace.append("DISCOVERY_17_DUPLICATED_MONTH_NAME")
      ctx.phase="PATCH_17_DUPLICATED_MONTH_NAME"
      rejectState("Phase"){v.requireDiscovery17Ready(ctx)}
    }
    check("le sedici PATCH precedenti restano operative"){
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
    check("il catalogo resta congelato, oracolo test-only, PATCH17 assente"){
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Test-only")
      truth(sources.contains("def oldMonthNameDuplicated("),"Cicatrice")
      truth(!sources.contains("def monthNameDistinctPatch("),"PATCH17 prematura")
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("SOURCE_LANGUAGE_CATALOG_FROZEN=YES"),
        "Catalogo congelato")
    }
    check("metadati Stage34 conservano il certificato Stage33"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=34"),"Stage")
      truth(st.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
      truth(st.contains("CURRENT_PATCH=16"),"PATCH precedente")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"RED")
      truth(st.contains("STAGE_33_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_65_PASS_0_FAIL"),
        "Stage33")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(done==33 || done==34,"Sequenza")
    }

    Vector(
      ("rango1_tre_mesi",3,BigInt(1)),
      ("rango2_tre_mesi",3,BigInt(2)),
      ("rango1_47_mesi",47,BigInt(1))
    ).foreach { case (label,count,rank) =>
      check("equivalenza normativa nomi "+label){
        val r=new BaseMonsterManager().discover17DuplicatedMonthName(
          43,-Huge,count,rank)
        eqv(r.legacyCanonicalNameIndices,normative(count,rank),
          "Nomi con rimpiazzo: "+label)
      }
    }
    println("\nRISULTATO STADIO 34: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
