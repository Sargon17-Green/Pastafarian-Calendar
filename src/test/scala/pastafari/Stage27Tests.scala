package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 13: scansione normativa dei confini, cicatrice legacy intatta. */
object Stage27Tests {
  private var passed=0
  private var failed=0
  private val Before=Vector(400,500,600,700,800)
  private val After=Vector(600,700,800,900,1000)
  private val Wide=Vector.fill(5)(5778)

  private def check(label:String)(run: => Unit):Unit = {
    try {run;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit =
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  private def truth(ok:Boolean,label:String):Unit =
    if(!ok)throw new AssertionError(label)
  private def rejectArg(label:String)(run: => Unit):Unit = {
    var caught=false
    try run catch {case _:IllegalArgumentException => caught=true}
    truth(caught,label+": parametro invalido accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit = {
    var caught=false
    try run catch {case _:IllegalStateException => caught=true}
    truth(caught,label+": stato invalido accettato")
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent!=null)
      p=p.getParent
    p
  }
  final case class Position(offset:BigInt,open:BigInt,close:BigInt)
  // Validatore di riferimento test-only, indipendente dal wrapper di produzione.
  private def expected(anchor:BigInt,before:Vector[Int],
                       after:Vector[Int],target:BigInt):Position = {
    if(target>anchor) {
      var boundary=anchor
      for((len,index)<-after.zipWithIndex) {
        val next=boundary+BigInt(len)
        if(boundary<target && target<=next)
          return Position(BigInt(index),boundary,next)
        boundary=next
      }
    } else {
      var boundary=anchor
      for((len,index)<-before.zipWithIndex) {
        val previous=boundary-BigInt(len)
        if(previous<target && target<=boundary)
          return Position(-BigInt(index)-1,previous,boundary)
        boundary=previous
      }
    }
    throw new IllegalArgumentException("Fuori finestra")
  }
  private def patched(target:BigInt=601,anchor:BigInt=0,
                      before:Vector[Int]=Before,
                      after:Vector[Int]=After):Patch13YearJumpResult =
    Patch13YearJumpWrapper.yearJumpPatch(anchor,before,after,target)
  private def discovery(target:BigInt=601,anchor:BigInt=0,
                        before:Vector[Int]=Before,
                        after:Vector[Int]=After):BaseMonsterContext = {
    val c=BaseMonsterContext(BigInt(17),target)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.jumpAnchorOpenDay=Some(anchor)
    c.jumpBeforeLengths=Some(before)
    c.jumpFromAnchorLengths=Some(after)
    c.phase="DISCOVERY_13_YEAR_JUMP"
    new Discovery13YearJumpHandler(new BaseMetricsShell).handle(c)
    c
  }
  private def complete(target:BigInt=601):BaseMonsterContext = {
    val c=discovery(target)
    c.phase="PATCH_13_YEAR_JUMP"
    new Patch13YearJumpHandler(new BaseMetricsShell).handle(c)
    c
  }
  private def same(r:Patch13YearJumpResult,p:Position):Unit = {
    eqv(r.correctedOffset,p.offset,"Offset")
    eqv(r.correctedOpenDay,p.open,"Apertura")
    eqv(r.correctedCloseDay,p.close,"Chiusura")
    truth(r.correctedOpenDay<r.correctedCloseDay,"Ampiezza positiva")
  }
  def main(args:Array[String]):Unit = {
    check("601 è nell'anno seguente, non nella finestra 5778") {
      val r=patched()
      same(r,Position(1,600,1300))
      eqv(r.historical.guessedOffset,BigInt(0),"Cicatrice")
    }
    check("-401 è nel secondo anno precedente") {
      val r=patched(-401)
      same(r,Position(-2,-900,-400))
      eqv(r.historical.guessedOffset,BigInt(-1),"Cicatrice")
    }
    check("1301 è nel terzo anno") {
      val r=patched(1301)
      same(r,Position(2,1300,2100))
      eqv(r.historical.guessedOffset,BigInt(0),"Cicatrice")
    }
    check("il giorno di apertura zero chiude l'anno precedente") {
      same(patched(0),Position(-1,-400,0))
    }
    check("il confine -400 chiude il secondo anno precedente") {
      same(patched(-400),Position(-2,-900,-400))
      same(patched(-399),Position(-1,-400,0))
    }
    check("il giorno uno inizia il primo anno dopo l'ancora") {
      same(patched(1),Position(0,0,600))
    }
    check("il giorno 600 chiude il primo anno") {
      same(patched(600),Position(0,0,600))
    }
    check("il giorno 1300 chiude il secondo anno") {
      same(patched(1300),Position(1,600,1300))
    }
    check("il giorno 2100 chiude il terzo anno") {
      same(patched(2100),Position(2,1300,2100))
    }
    check("la fine dell'ultima finestra positiva è inclusiva") {
      same(patched(4000),Position(4,3000,4000))
    }
    check("l'ultimo giorno della finestra negativa è incluso") {
      same(patched(-2999),Position(-5,-3000,-2200))
    }
    check("le due finestre esteriori non consentono estrapolazioni") {
      rejectArg("Troppo avanti"){patched(4001)}
      rejectArg("Troppo indietro"){patched(-3000)}
      rejectArg("Ancora indietro"){patched(-3001)}
    }
    check("anni massimi da 5778 non cambiano gli offset") {
      for(k<- -4 to 4) {
        val day=BigInt(k)*5778+1
        val r=patched(day,0,Wide,Wide)
        same(r,expected(0,Wide,Wide,day))
        eqv(r.correctedOffset,r.historical.guessedOffset,"Legacy coincide")
      }
    }
    check("la chiusura 5778 è ancora nell'anno corrente") {
      same(patched(5778,0,Wide,Wide),Position(0,0,5778))
    }
    check("la chiusura -5778 è nel secondo anno precedente") {
      same(patched(-5778,0,Wide,Wide),Position(-2,-11556,-5778))
    }
    check("il minimo 252 è un anno completo valido") {
      val lengths=Vector.fill(3)(252)
      same(patched(252,0,lengths,lengths),Position(0,0,252))
      same(patched(-252,0,lengths,lengths),Position(-2,-504,-252))
    }
    check("traslazione immensa signed non cambia i risultati") {
      val anchor=(BigInt(1)<<16384)+20261012
      for(day<-Vector(BigInt(-2999),BigInt(-900),BigInt(-401),
          BigInt(-400),BigInt(0),BigInt(1),BigInt(600),BigInt(601),
          BigInt(1300),BigInt(1301),BigInt(4000))) {
        val r=patched(anchor+day,anchor)
        val local=patched(day)
        eqv(r.correctedOffset,local.correctedOffset,"Traslazione offset")
        eqv(r.correctedOpenDay-anchor,local.correctedOpenDay,"Traslazione open")
        eqv(r.correctedCloseDay-anchor,local.correctedCloseDay,"Traslazione close")
      }
    }
    check("2048 vettori deterministici confrontati con un validatore distinto") {
      val rng=new Random(20261012L)
      for(i<-1 to 2048) {
        val before=Vector.fill(1+rng.nextInt(15))(252+rng.nextInt(5527))
        val after=Vector.fill(1+rng.nextInt(15))(252+rng.nextInt(5527))
        val anchor=BigInt(rng.nextInt(10001)-5000)
        val bindex=rng.nextInt(before.size)
        val aindex=rng.nextInt(after.size)
        val positive=anchor+after.take(aindex).map(BigInt(_)).sum+
          BigInt(1+rng.nextInt(after(aindex)))
        val negative=anchor-before.take(bindex).map(BigInt(_)).sum-
          BigInt(rng.nextInt(before(bindex)))
        for(day<-Vector(positive,negative)) {
          val r=patched(day,anchor,before,after)
          same(r,expected(anchor,before,after,day))
          eqv(r.historical,LegacyYearJumpAdapter.oldJumpGuess(
            anchor,before,after,day),"Cicatrice integrale")
        }
      }
    }
    check("la scansione non altera i vettori di ingresso") {
      val before=Before
      val after=After
      patched(601,0,before,after)
      eqv(before,Before,"Prima")
      eqv(after,After,"Dopo")
    }
    check("le chiamate intercalate non condividono stato") {
      val first=patched()
      for(i<-1 to 100)patched(target=BigInt((i%600)+1))
      eqv(patched(),first,"Determinismo")
    }
    check("durate fuori dominio respinte dal legacy prima della patch") {
      for((b,a)<-Vector(
        (Vector.empty[Int],After),(Before,Vector.empty[Int]),
        (Vector(251),After),(Before,Vector(5779)))) {
        rejectArg("Durate errate"){patched(1,0,b,a)}
      }
    }
    check("manager attraversa BOOT DISCOVERY 13 PATCH 13") {
      val m=new BaseMonsterManager
      val r=m.patch13YearJump(17,601,0,Before,After)
      eqv(r.calculationDay,BigInt(17),"Calcolo")
      eqv(r.targetDay,BigInt(601),"Target")
      eqv(r.anchorOpenDay,BigInt(0),"Ancora")
      eqv(r.yearsBefore,Before,"Prima")
      eqv(r.yearsFromAnchor,After,"Dopo")
      eqv(r.legacyYearOffset,BigInt(0),"Legacy")
      eqv(r.correctedYearOffset,BigInt(1),"Corretto")
      eqv(r.correctedOpenDay,BigInt(600),"Open")
      eqv(r.correctedCloseDay,BigInt(1300),"Close")
      truth(r.patchApplied,"Applicata")
      eqv(r.trace,Vector("BOOT","DISCOVERY_13_YEAR_JUMP",
        "PATCH_13_YEAR_JUMP"),"Trace")
      eqv(r.status,"PATCH_13_READY","Status")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery13.year.jump.calls"),BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch13.year.jump.calls"),BigInt(1),"Patch")
    }
    check("diagnostica Stage26 ancora RED sullo stesso input") {
      val m=new BaseMonsterManager
      val d=m.discover13YearJump(0,601,0,Before,After)
      val p=m.patch13YearJump(0,601,0,Before,After)
      eqv(d.legacyYearOffset,BigInt(0),"Divergenza storica")
      eqv(p.legacyYearOffset,d.legacyYearOffset,"Cicatrice conservata")
      eqv(p.correctedYearOffset,BigInt(1),"Correzione")
    }
    check("manager mantiene isolamento fra richieste e metriche") {
      val m=new BaseMonsterManager
      val a=m.patch13YearJump(1,601,0,Before,After)
      val b=m.patch13YearJump(2,-401,0,Before,After)
      eqv(a.correctedYearOffset,BigInt(1),"Avanti")
      eqv(b.correctedYearOffset,BigInt(-2),"Indietro")
      eqv(m.metricsSnapshot("patch13.year.jump.calls"),BigInt(2),"Numero")
    }
    check("handler rifiuta BOOT senza discovery") {
      val c=BaseMonsterContext(1,601)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_13_YEAR_JUMP"
      rejectState("Niente discovery"){
        new Patch13YearJumpHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler respinge un legacy alterato senza modificare l'output") {
      val c=discovery()
      c.legacyJumpOffset=Some(123)
      c.phase="PATCH_13_YEAR_JUMP"
      rejectState("Legacy falso"){
        new Patch13YearJumpHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedJumpOffset.isEmpty && !c.patch13Applied,
        "Nessuna pubblicazione parziale")
    }
    check("handler respinge una seconda applicazione") {
      val c=complete()
      rejectState("Ripetizione"){
        new Patch13YearJumpHandler(new BaseMetricsShell).handle(c)}
    }
    check("validator accetta il contesto completo") {
      new BaseValidationManager().requirePatch13Ready(complete())
    }
    check("validator rifiuta offset corretto alterato") {
      val c=complete()
      c.patchedJumpOffset=Some(0)
      rejectState("Offset"){new BaseValidationManager().requirePatch13Ready(c)}
    }
    check("validator rifiuta apertura corretta alterata") {
      val c=complete()
      c.patchedJumpOpenDay=Some(0)
      rejectState("Apertura"){new BaseValidationManager().requirePatch13Ready(c)}
    }
    check("validator rifiuta chiusura corretta alterata") {
      val c=complete()
      c.patchedJumpCloseDay=Some(5778)
      rejectState("Chiusura"){new BaseValidationManager().requirePatch13Ready(c)}
    }
    check("validator rifiuta offset storico alterato") {
      val c=complete()
      c.legacyJumpOffset=Some(1)
      rejectState("Legacy"){new BaseValidationManager().requirePatch13Ready(c)}
    }
    check("validator rifiuta l'ancora contraffatta") {
      val c=complete()
      c.jumpAnchorOpenDay=Some(200)
      rejectState("Ancora"){new BaseValidationManager().requirePatch13Ready(c)}
    }
    check("validator rifiuta durate mutate dopo la patch") {
      val c=complete()
      c.jumpFromAnchorLengths=Some(Wide)
      rejectState("Durate"){new BaseValidationManager().requirePatch13Ready(c)}
    }
    check("validator rifiuta flag fase e trace errati") {
      val c=complete()
      val v=new BaseValidationManager
      c.patch13Applied=false
      rejectState("Flag"){v.requirePatch13Ready(c)}
      c.patch13Applied=true
      c.branchTrace.remove(1)
      rejectState("Trace"){v.requirePatch13Ready(c)}
      c.branchTrace.insert(1,"DISCOVERY_13_YEAR_JUMP")
      c.phase="DISCOVERY_13_YEAR_JUMP"
      rejectState("Fase"){v.requirePatch13Ready(c)}
    }
    check("validator rifiuta output assente") {
      val c=complete()
      c.patchedJumpCloseDay=None
      rejectState("Mancante"){new BaseValidationManager().requirePatch13Ready(c)}
    }
    check("le dodici patch precedenti conservano le proprie funzioni") {
      val m=new BaseMonsterManager
      val f=NormativeOracle.FoundationDay
      val mod=NormativeOracle.M
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
    }
    check("oracolo resta test-only, il codice storico rimane immutato") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Test-only")
      truth(sources.contains("def oldJumpGuess("),"Cicatrice")
      truth(sources.contains("val estimate=if(relative<0 && r!=0)q-1 else q"),
        "Formula legacy immutata")
      truth(sources.contains("def yearJumpPatch("),"PATCH 13 presente")
      val stage=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=stage.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if(current<28)
        truth(!sources.contains("VirtualLegacyList"),"Stage28 non anticipato")
      else
        truth(sources.contains("object VirtualLegacyListAdapter"),
          "Stage28 aggiunto dopo la PATCH 13")
    }
    check("metadati Stage27 e certificazione Stage26 preservata") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current>=27,"Stage27 disponibile")
      if(current==27)
        truth(st.contains("CURRENT_KIND=PATCH"),"Stadio PATCH")
      else
        truth(st.contains("STAGE_27_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_39_PASS_0_FAIL"),
          "Certificazione PATCH 13 storica")
      truth(st.contains("CURRENT_PATCH=13"),"Patch13")
      truth(st.contains("STAGE_26_NATIVE_VERIFICATION=PASS_EXPECTED_RED_38_PASS_3_FAIL"),
        "Stage26")
      truth(st.contains("STAGE_27_NATIVE_VERIFICATION="),"Status Stage27")
    }
    println("\nRISULTATO STADIO 27: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
