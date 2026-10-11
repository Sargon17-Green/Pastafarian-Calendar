package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 08: tutte le sei uscite derivano dai registri vecchi congelati. */
object Stage17Tests {
  private var passed=0
  private var failed=0
  private val I=Vector[BigInt](11,13,17,19,23,29)
  private val S=Vector[BigInt](31,37,41,43,47)
  private val D=BigInt(37)
  private val M=NormativeOracle.M
  private val kinds=Vector(0,1,2,3,4,0)
  private def check(label:String)(run: => Unit):Unit = {
    try {run;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable => failed+=1;println("FAIL — "+label+" — "+e.getMessage);e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit =
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  private def truth(value:Boolean,label:String):Unit =
    if(!value)throw new AssertionError(label)
  private def rejectArg(label:String)(run: => Unit):Unit = {
    var rejected=false
    try run catch {case _:IllegalArgumentException => rejected=true}
    truth(rejected,"Parametro malformato "+label)
  }
  private def rejectState(label:String)(run: => Unit):Unit = {
    var rejected=false
    try run catch {case _:IllegalStateException => rejected=true}
    truth(rejected,"Stato malformato "+label)
  }
  private def expected(initial:Vector[BigInt],drop:BigInt,
                       stones:Vector[BigInt],step:Int,rank:Int):LegacyBowlAliasResult = {
    val order=NormativeOracle.bowlOrderFromNumber(rank)
    val pour=Vector.tabulate[BigInt](6){p =>
      if(p>=3)BigInt(0)
      else NormativeOracle.save(drop*drop+stones(p)*initial(order(p)-1)+(3+2*p)*step)
    }
    val result=Array.fill[BigInt](6)(BigInt(0))
    for(p<-1 to 6) {
      val at=order(p-1)-1
      val previous=order((p+4)%6)-1
      val following=order(p%6)-1
      val value=initial(at)+2*initial(previous)+3*initial(following)+
        pour(p-1)+drop+stones(kinds(p-1))
      result(at)=NormativeOracle.save(value*value+5*initial(previous)*initial(following)+step*p)
    }
    LegacyBowlAliasResult(order,pour,result.toVector)
  }
  private def ready(rank:Int=1,step:Int=1):BaseMonsterContext = {
    val c=BaseMonsterContext(1,2)
    c.status="BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.bowlInput=Some(I);c.bowlDropInput=Some(D)
    c.bowlStonesInput=Some(S);c.bowlStepInput=Some(step)
    c.bowlRankInput=Some(rank);c.phase="DISCOVERY_08_BOWL_ALIAS"
    new Discovery08BowlAliasHandler(new BaseMetricsShell).handle(c)
    c.phase="PATCH_08_BOWL_FREEZE"
    c
  }
  private def root():java.nio.file.Path = {
    var path=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(path.resolve("DEVELOPMENT_STAGE.md")) && path.getParent!=null)
      path=path.getParent
    if(!Files.exists(path.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Root mancante")
    path
  }
  def main(args:Array[String]):Unit = {
    check("l'output congelato diretto è normativo anche al secondo registro") {
      val patched=Patch08BowlWrapper.bowlPatch(I,D,S,1,1)
      eqv(patched,expected(I,D,S,1,1).bowls,"Ordine diretto")
      eqv(patched(1),BigInt(4061162),"Seconda ciotola")
    }
    check("la cicatrice dell'ordine diretto resta verificabile") {
      val legacy=LegacyBowlAliasAdapter.bowlAlias(I,D,S,1,1)
      eqv(legacy.bowls.head,BigInt(3570207),"Prima storica")
      eqv(legacy.bowls(1),BigInt("51014281221246"),"Seconda storica")
      truth(legacy.bowls!=Patch08BowlWrapper.bowlPatch(I,D,S,1,1),"Cicatrice presente")
    }
    check("l'ordine inverso restituisce tutte le sei uscite normative") {
      eqv(Patch08BowlWrapper.bowlPatch(I,D,S,1,720),
        expected(I,D,S,1,720).bowls,"Ordine inverso")
    }
    check("la goccia 46 restituisce le sei uscite normative") {
      eqv(Patch08BowlWrapper.bowlPatch(I,D,S,46,360),
        expected(I,D,S,46,360).bowls,"Goccia 46")
    }
    check("il primo aggiornamento rimane identico all'errore storico") {
      for(rank <- Vector(1,2,6,121,360,719,720);step <- Vector(1,46)){
        val wrong=LegacyBowlAliasAdapter.bowlAlias(I,D,S,step,rank)
        val right=Patch08BowlWrapper.bowlPatch(I,D,S,step,rank)
        eqv(right(wrong.order.head-1),wrong.bowls(wrong.order.head-1),
          "Prima posizione "+rank)
      }
    }
    check("i getti iniziali sono identici tra norma e helper legacy") {
      for(rank <- Vector(1,2,360,720);step <- Vector(1,2,23,46)){
        val wrong=LegacyBowlAliasAdapter.bowlAlias(I,D,S,step,rank)
        eqv(wrong.pours,expected(I,D,S,step,rank).pours,"Getti "+rank)
      }
    }
    check("tutti i 720 ranghi rispettano la mescolatura congelata") {
      for(rank <- 1 to 720){
        val got=Patch08BowlWrapper.bowlPatch(I,D,S,1,rank)
        eqv(got,expected(I,D,S,1,rank).bowls,"Rango "+rank)
      }
    }
    check("ogni posizione della prima ciotola ha la sua classe di 120 ordini") {
      for(first <- 1 to 6){
        var count=0
        for(rank <- 1 to 720){
          val order=LegacyBowlAliasAdapter.bowlAlias(I,D,S,1,rank).order
          if(order.head==first)count+=1
        }
        eqv(count,120,"Prima ciotola "+first)
      }
    }
    check("46 gocce consecutive sono confrontate con istantanea indipendente") {
      val m=new BaseMonsterManager
      var old=I
      var norm=I
      for(step<-1 to 46){
        val rank=((step*113-1)%720)+1
        val drop=D+step
        val expectedStep=expected(norm,drop,S,step,rank)
        val report=m.patch08Bowls(1,2,old,drop,S,step,rank)
        eqv(report.patchedBowls,expectedStep.bowls,"Goccia "+step)
        old=report.patchedBowls
        norm=expectedStep.bowls
      }
      eqv(old,norm,"Risultato dopo 46 gocce")
      eqv(m.metricsSnapshot("patch08.bowl.freeze.calls"),BigInt(46),"Metriche 46")
    }
    check("salvataggio positivo e dominio fra uno e M") {
      for(rank <- Vector(1,120,360,720);step <- Vector(1,46)){
        val got=Patch08BowlWrapper.bowlPatch(Vector.fill[BigInt](6)(M),BigInt(0),
          Vector.fill[BigInt](5)(M),step,rank)
        truth(got.length==6 && got.forall(x=>x>=1 && x<=M),"SAVE")
      }
    }
    check("valori signed e BigInt a piu di sedicimila bit senza overflow") {
      val huge=(BigInt(1)<<16384)+757
      val initial=Vector(huge,-huge,huge*2,-huge*3,huge+5,-huge-7)
      val stones=Vector(huge,-huge,huge+11,-huge-13,huge*2)
      for(rank <- Vector(1,360,720);step <- Vector(1,46)){
        eqv(Patch08BowlWrapper.bowlPatch(initial,-huge,stones,step,rank),
          expected(initial,-huge,stones,step,rank).bowls,"Grande "+rank)
      }
    }
    check("512 campioni signed deterministici") {
      val rng=new Random(20261011L)
      for(i<-1 to 512){
        val rank=rng.nextInt(720)+1
        val step=rng.nextInt(46)+1
        val shift=rng.nextInt(100000)-50000
        val initial=Vector.tabulate[BigInt](6)(j=>BigInt(shift)*(j+1)+i)
        val stone=Vector.tabulate[BigInt](5)(j=>BigInt(shift)-i*j)
        val drop=BigInt(shift)*i
        eqv(Patch08BowlWrapper.bowlPatch(initial,drop,stone,step,rank),
          expected(initial,drop,stone,step,rank).bowls,"Campione "+i)
      }
    }
    check("il wrapper non modifica Vector input delle sei ciotole") {
      val input=I
      Patch08BowlWrapper.bowlPatch(input,D,S,1,1)
      eqv(input,I,"Registro iniziale")
      eqv(S,Vector[BigInt](31,37,41,43,47),"Pietre iniziali")
    }
    check("il wrapper è deterministico dopo chiamate diverse") {
      val baseline=Patch08BowlWrapper.bowlPatch(I,D,S,46,720)
      (1 to 70).foreach{j=>Patch08BowlWrapper.bowlPatch(I,D+j,S,j%46+1,j%720+1)}
      eqv(Patch08BowlWrapper.bowlPatch(I,D,S,46,720),baseline,"Snapshot")
    }
    check("input invalidi di step e rango rifiutati") {
      for(step <- Vector(Int.MinValue,-1,0,47,100,Int.MaxValue)){
        rejectArg("Goccia "+step){Patch08BowlWrapper.bowlPatch(I,D,S,step,1)}
      }
      for(rank <- Vector(Int.MinValue,-1,0,721,1440,Int.MaxValue)){
        rejectArg("Rango "+rank){Patch08BowlWrapper.bowlPatch(I,D,S,1,rank)}
      }
    }
    check("input con cinque o sette ciotole e pietre malformate rifiutati") {
      for(len <- Vector(0,1,5,7,10)){
        rejectArg("Ciotole "+len){
          Patch08BowlWrapper.bowlPatch(Vector.fill[BigInt](len)(1),D,S,1,1)
        }
      }
      for(len <- Vector(0,1,4,6,10)){
        rejectArg("Pietre "+len){
          Patch08BowlWrapper.bowlPatch(I,D,Vector.fill[BigInt](len)(1),1,1)
        }
      }
    }
    check("il manager attraversa BOOT DISCOVERY 08 e PATCH 08 realmente") {
      val m=new BaseMonsterManager
      val r=m.patch08Bowls(123,-456,I,D,S,1,1)
      eqv(r.calculationDay,BigInt(123),"Calculation day")
      eqv(r.targetDay,BigInt(-456),"Target day")
      eqv(r.initialBowls,I,"Stato iniziale")
      eqv(r.bowlOrder,Vector(1,2,3,4,5,6),"Ordine")
      eqv(r.legacyBowls(1),BigInt("51014281221246"),"Cicatrice")
      eqv(r.patchedBowls,expected(I,D,S,1,1).bowls,"Correzione")
      truth(r.patchApplied,"Flag PATCH 08")
      eqv(r.phase,"PATCH_08_BOWL_FREEZE","Fase")
      eqv(r.status,"PATCH_08_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_08_BOWL_ALIAS","PATCH_08_BOWL_FREEZE"),"Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery08.bowl.alias.calls"),BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch08.bowl.freeze.calls"),BigInt(1),"Patch")
    }
    check("i due report percorrono la stessa cicatrice storica") {
      val m=new BaseMonsterManager
      for(rank <- Vector(1,2,121,360,719,720);step <- Vector(1,46)){
        val old=m.discover08BowlAlias(1,2,I,D,S,step,rank)
        val now=m.patch08Bowls(1,2,I,D,S,step,rank)
        eqv(now.legacyBowls,old.legacyBowls,"Legacy "+rank)
        eqv(now.pours,old.pours,"Getti "+rank)
        eqv(now.bowlOrder,old.bowlOrder,"Ordine "+rank)
        eqv(now.patchedBowls,expected(I,D,S,step,rank).bowls,"PATCH "+rank)
      }
    }
    check("rapporti e contatori sono isolati fra due invocazioni") {
      val m=new BaseMonsterManager
      val a=m.patch08Bowls(1,2,I,D,S,1,1)
      val b=m.patch08Bowls(3,4,I,D,S,46,720)
      truth(a.patchedBowls!=b.patchedBowls,"Due snapshot")
      eqv(a.orderRank1,1,"Rango A")
      eqv(b.orderRank1,720,"Rango B")
      eqv(a.calculationDay,BigInt(1),"Giorno A")
      eqv(m.metricsSnapshot("patch08.bowl.freeze.calls"),BigInt(2),"Metrica")
    }
    check("grandi giorni di calendario non contaminano il registro") {
      val giant=(BigInt(1)<<16384)+13
      val m=new BaseMonsterManager
      val a=m.patch08Bowls(0,0,I,D,S,46,360)
      val b=m.patch08Bowls(giant,-giant,I,D,S,46,360)
      eqv(a.patchedBowls,b.patchedBowls,"Indipendenza")
      eqv(b.targetDay,-giant,"BigInt calcolo")
    }
    check("handler respinge contesti senza una discovery valida") {
      val h=new Patch08BowlHandler(new BaseMetricsShell)
      rejectState("Contesto nuovo"){h.handle(BaseMonsterContext(1,2))}
      val c=BaseMonsterContext(1,2)
      c.status="LEGACY_BOWL_ALIAS_READY"
      c.bowlInput=Some(I);c.bowlDropInput=Some(D)
      c.bowlStonesInput=Some(S);c.bowlStepInput=Some(1);c.bowlRankInput=Some(1)
      rejectState("Nessuna trace"){h.handle(c)}
      truth(c.patchedBowlOutput.isEmpty && !c.patch08Applied,"Nessun effetto")
    }
    check("handler rifiuta il doppio uso e conserva la prima uscita") {
      val h=new Patch08BowlHandler(new BaseMetricsShell)
      val c=ready()
      h.handle(c)
      val snapshot=c.patchedBowlOutput
      rejectState("Doppia PATCH"){h.handle(c)}
      eqv(c.patchedBowlOutput,snapshot,"Snapshot stabile")
    }
    check("validator non accetta output patched o trace assenti") {
      val v=new BaseValidationManager
      val c=ready()
      c.status="PATCH_08_READY"
      c.branchTrace.append("PATCH_08_BOWL_FREEZE")
      c.patch08Applied=true
      rejectState("Manca patched"){v.requirePatch08Ready(c)}
      c.patchedBowlOutput=Some(expected(I,D,S,1,1).bowls)
      v.requirePatch08Ready(c)
      c.branchTrace.remove(1)
      rejectState("Trace falsificata"){v.requirePatch08Ready(c)}
    }
    check("validator verifica autonomamente 720 ordini normativi") {
      val v=new BaseValidationManager
      val h=new Patch08BowlHandler(new BaseMetricsShell)
      for(rank<-1 to 720){
        val c=ready(rank)
        h.handle(c)
        v.requirePatch08Ready(c)
        eqv(c.patchedBowlOutput.get,expected(I,D,S,1,rank).bowls,"Rango "+rank)
      }
    }
    check("validator scopre una ciotola patched contraffatta") {
      val v=new BaseValidationManager
      val c=ready(360,46)
      new Patch08BowlHandler(new BaseMetricsShell).handle(c)
      c.patchedBowlOutput=Some(c.patchedBowlOutput.get.updated(2,BigInt(999)))
      rejectState("Valore patched"){v.requirePatch08Ready(c)}
    }
    check("validator scopre la falsificazione della cicatrice") {
      val v=new BaseValidationManager
      val c=ready()
      new Patch08BowlHandler(new BaseMetricsShell).handle(c)
      c.legacyBowlOutput=Some(c.legacyBowlOutput.get.updated(0,BigInt(999)))
      rejectState("Output legacy"){v.requirePatch08Ready(c)}
    }
    check("validator scopre getti falsificati e rango alterato") {
      val v=new BaseValidationManager
      val c=ready()
      new Patch08BowlHandler(new BaseMetricsShell).handle(c)
      val pours=c.legacyBowlPoursOutput.get
      c.legacyBowlPoursOutput=Some(pours.updated(0,BigInt(999)))
      rejectState("Getti"){v.requirePatch08Ready(c)}
      c.legacyBowlPoursOutput=Some(pours)
      c.bowlRankInput=Some(720)
      rejectState("Rango"){v.requirePatch08Ready(c)}
    }
    check("validator respinge flag falso e stato falso") {
      val v=new BaseValidationManager
      val c=ready()
      new Patch08BowlHandler(new BaseMetricsShell).handle(c)
      c.patch08Applied=false
      rejectState("Flag"){v.requirePatch08Ready(c)}
      c.patch08Applied=true
      c.status="LEGACY_BOWL_ALIAS_READY"
      rejectState("Stato"){v.requirePatch08Ready(c)}
    }
    check("le sette patch precedenti restano tutte normative") {
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
    }
    check("l'oracolo resta test-only e nessun codice Stage18 compare") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val src=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!src.contains("NormativeOracle"),"Oracolo nel prodotto")
      truth(src.contains("val next = register"),"Cicatrice cancellata")
      truth(src.contains("LegacyBowlAliasAdapter.bowlAlias(initial,drop,stones,step,rank1)"),
        "Il wrapper deve attraversare realmente il legacy")
      val st = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current = st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if(current < 18)
        truth(!src.contains("vaultOld"),"Stage18 anticipato")
      else
        truth(src.contains("LegacyVaultAdapter.vaultOld("),"Discovery 09 disponibile")
    }
    check("metadati Stage17 verdi preservano la firma RED di Stage16") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current = st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current>=17,"Stage17 disponibile")
      if(current==17) {
        truth(st.contains("CURRENT_KIND=PATCH"),"Tipo")
        truth(st.contains("CURRENT_PATCH=08"),"Patch")
        truth(st.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"GREEN")
      } else {
        truth(st.contains("STAGE_17_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_31_PASS_0_FAIL"),
          "Certificazione storica Stage17")
      }
      truth(st.contains("STAGE_16_NATIVE_VERIFICATION=PASS_EXPECTED_RED_25_PASS_3_FAIL"),
        "Firma di Stage16")
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=16 && completed<=current,"Certificazione non anticipata")
    }
    println("\nRISULTATO STADIO 17: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
