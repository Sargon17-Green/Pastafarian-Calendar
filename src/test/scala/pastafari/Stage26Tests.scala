package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 13: il salto storico suppone anni fissi da 5778 giorni. */
object Stage26Tests {
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
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice non trovata")
    p
  }

  final case class YearPosition(offset:BigInt,open:BigInt,close:BigInt)

  // Riferimento test-only: scansiona davvero tutti i confini contigui.
  // Ogni anno ha intervallo (apertura, chiusura].
  private def yearAt(anchor:BigInt, before:Vector[Int],
                     after:Vector[Int], target:BigInt):YearPosition = {
    if(target>anchor) {
      var open=anchor
      for(i<-after.indices) {
        val close=open+BigInt(after(i))
        if(target<=close)return YearPosition(BigInt(i),open,close)
        open=close
      }
    } else {
      var close=anchor
      for(i<-before.indices) {
        val open=close-BigInt(before(i))
        if(target>open)return YearPosition(BigInt(-i-1),open,close)
        close=open
      }
    }
    throw new IllegalArgumentException("Giorno fuori dalla finestra di test")
  }
  private def legacy(anchor:BigInt=0,target:BigInt=601,
                     before:Vector[Int]=Before,
                     after:Vector[Int]=After):LegacyYearJumpResult =
    LegacyYearJumpAdapter.oldJumpGuess(anchor,before,after,target)

  private def ready(anchor:BigInt=0,target:BigInt=601,
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
  def main(args:Array[String]):Unit = {
    check("il salto legacy assume sempre ampiezza 5778") {
      val r=legacy()
      eqv(r.guessedOffset,BigInt(0),"Stima")
      eqv(r.guessedOpenDay,BigInt(0),"Apertura")
      eqv(r.guessedCloseDay,BigInt(5778),"Chiusura stimata")
      eqv(r.yearsBefore,Before,"Anni prima")
      eqv(r.yearsFromAnchor,After,"Anni dopo")
    }
    check("il primo anno sintetico ammette 600 giorni") {
      val y=yearAt(0,Before,After,600)
      eqv(y,YearPosition(0,0,600),"Primo anno")
      eqv(legacy(target=BigInt(600)).guessedOffset,BigInt(0),"Legacy coincide")
    }
    check("la porta successiva al giorno 600 deve aprire un altro anno") {
      val actual=yearAt(0,Before,After,601)
      eqv(actual,YearPosition(1,600,1300),"Porta successiva")
      truth(legacy().guessedOffset!=actual.offset,"Cicatrice esposta")
    }
    check("gli anni precedenti sono aperti a sinistra") {
      eqv(yearAt(0,Before,After,0),YearPosition(-1,-400,0),"Giorno zero")
      eqv(yearAt(0,Before,After,-400),
        YearPosition(-2,-900,-400),"Giorno esatto del cancello")
    }
    check("il primo giorno prima del cancello zero appartiene al precedente") {
      eqv(legacy(target=BigInt(0)).guessedOffset,BigInt(-1),"Salto coincidente")
      eqv(yearAt(0,Before,After,0).offset,BigInt(-1),"Anno reale")
    }
    check("dopo il confine negativo il salto indovina ancora -1") {
      val r=legacy(target=BigInt(-401))
      eqv(r.guessedOffset,BigInt(-1),"Stima invariata")
      eqv(yearAt(0,Before,After,-401).offset,BigInt(-2),
        "Secondo anno precedente")
    }
    check("la durata normativa massima di 5778 coincide con il legacy") {
      for(i<- -3 to 3) {
        val target=BigInt(i)*5778+1
        val year=yearAt(0,Wide,Wide,target)
        val old=legacy(target=target,before=Wide,after=Wide)
        eqv(old.guessedOffset,year.offset,"Anni massimi "+i)
        eqv(old.guessedOpenDay,year.open,"Apertura "+i)
        eqv(old.guessedCloseDay,year.close,"Chiusura "+i)
      }
    }
    check("in un anno massimo la chiusura è inclusa") {
      val target=BigInt(5778)
      eqv(yearAt(0,Wide,Wide,target).offset,BigInt(0),"Inclusione")
      eqv(legacy(target=target,before=Wide,after=Wide).guessedOffset,
        BigInt(0),"Stima")
    }
    check("la prima data dopo la chiusura massima va all'anno nuovo") {
      eqv(yearAt(0,Wide,Wide,5779).offset,BigInt(1),"Scatto reale")
      eqv(legacy(target=5779,before=Wide,after=Wide).guessedOffset,
        BigInt(1),"Scatto storico")
    }
    check("la discesa attraverso il cancello massimo usa il floor negativo") {
      val day=BigInt(-5778)
      eqv(yearAt(0,Wide,Wide,day).offset,BigInt(-2),"Anno reale")
      eqv(legacy(target=day,before=Wide,after=Wide).guessedOffset,
        BigInt(-2),"Divisione euclidea")
    }
    check("il valore della data sul cancello 1300 è dell'anno precedente") {
      eqv(yearAt(0,Before,After,1300).offset,BigInt(1),"Chiusura")
      eqv(yearAt(0,Before,After,1301).offset,BigInt(2),"Dopo chiusura")
      eqv(legacy(target=1301).guessedOffset,BigInt(0),"Vecchia stima")
    }
    check("ogni durata sintetica resta entro 252 e 5778 giorni") {
      for(d<-Before++After++Wide)
        truth(d>=NormativeOracle.YearMinDays &&
          d<=NormativeOracle.YearMaxDays,"Durata "+d)
    }
    check("le tre divergenze hanno offset realmente distinti") {
      for(target<-Vector(BigInt(601),BigInt(-401),BigInt(1301))) {
        truth(legacy(target=target).guessedOffset!=
          yearAt(0,Before,After,target).offset,
          "Divergenza "+target)
      }
    }
    check("gli intervalli stimati contigui sono aperti a sinistra") {
      for(k<- -8 to 8) {
        val t=BigInt(k)*5778+1
        val r=legacy(target=t)
        eqv(r.guessedOffset,BigInt(k),"Offset "+k)
        truth(r.guessedOpenDay<t && t<=r.guessedCloseDay,
          "Intervallo "+k)
      }
    }
    check("la formula di stima funziona con giorno assoluto traslato") {
      val anchor=BigInt(7123456789L)
      val r=legacy(anchor=anchor,target=anchor+601)
      eqv(r.guessedOpenDay,anchor,"Origine")
      eqv(r.guessedOffset,BigInt(0),"Offset traslato")
    }
    check("una traslazione uniforme non cambia gli offset") {
      val anchor=(BigInt(1)<<16384)+89
      for(day<-Vector(BigInt(-401),BigInt(0),BigInt(1),
          BigInt(600),BigInt(601),BigInt(1301))) {
        eqv(legacy(anchor=anchor,target=anchor+day).guessedOffset,
          legacy(target=day).guessedOffset,"Traslazione "+day)
      }
    }
    check("giorni assoluti BigInt signed oltre 16384 bit") {
      val huge=(BigInt(1)<<16384)+17
      val positive=legacy(target=huge)
      val negative=legacy(target = -huge)
      truth(positive.guessedOffset>0,"Offset positivo")
      truth(negative.guessedOffset<0,"Offset negativo")
      eqv(positive.guessedCloseDay-positive.guessedOpenDay,
        BigInt(5778),"Ampiezza BigInt")
    }
    check("2048 vettori di durate casuali deterministiche non mutano la stima") {
      val rng=new Random(20261012L)
      for(i<-1 to 2048) {
        val before=Vector.fill(5)(252+rng.nextInt(5527))
        val after=Vector.fill(5)(252+rng.nextInt(5527))
        val target=BigInt(rng.nextInt(20001)-10000)
        val r=legacy(target=target,before=before,after=after)
        eqv(r.guessedCloseDay-r.guessedOpenDay,BigInt(5778),
          "Ampiezza costante "+i)
        eqv(r.yearsBefore,before,"Ingresso precedente "+i)
        eqv(r.yearsFromAnchor,after,"Ingresso successivo "+i)
      }
    }
    check("le lunghezze di anni non pieni non sono usate nel salto legacy") {
      val a=legacy(target=601,before=Before,after=After)
      val b=legacy(target=601,before=Wide,after=Wide)
      eqv(a.guessedOffset,b.guessedOffset,"Il difetto ignora i confini")
      truth(yearAt(0,Before,After,601)!=yearAt(0,Wide,Wide,601),
        "Ma la norma dipende dai confini")
    }
    check("nessun overflow negli offset oltre Int") {
      val target=BigInt(Int.MaxValue)*BigInt(5778)*500+1
      val r=legacy(target=target)
      eqv(r.guessedOffset,BigInt(Int.MaxValue)*500,"Indice gigantesco")
    }
    check("anni vuoti o durate non normative sono respinti") {
      for((before,after)<-Vector(
        (Vector.empty[Int],After),
        (Before,Vector.empty[Int]),
        (Vector(251),After),
        (Before,Vector(5779)),
        (Vector(-2),After),
        (Before,Vector(0)))) {
        rejectArg("Vettore di durate"){
          legacy(before=before,after=after)
        }
      }
    }
    check("l'helper storico non modifica i vettori del chiamante") {
      val before=Before;val after=After
      legacy(target=1301,before=before,after=after)
      eqv(before,Vector(400,500,600,700,800),"Prima")
      eqv(after,Vector(600,700,800,900,1000),"Dopo")
    }
    check("intercalazione di istanze non altera i risultati") {
      val before=legacy(target=601)
      for(i<-1 to 90)legacy(target=BigInt(i)*1000)
      eqv(legacy(target=601),before,"Determinismo")
    }
    check("manager pubblica i due limiti e la stima") {
      val m=new BaseMonsterManager
      val r=m.discover13YearJump(17,601,0,Before,After)
      eqv(r.calculationDay,BigInt(17),"Giorno calcolo")
      eqv(r.targetDay,BigInt(601),"Giorno bersaglio")
      eqv(r.anchorOpenDay,BigInt(0),"Ancora")
      eqv(r.yearsBefore,Before,"Prima")
      eqv(r.yearsFromAnchor,After,"Dopo")
      eqv(r.legacyYearOffset,BigInt(0),"Offset")
      eqv(r.legacyOpenDay,BigInt(0),"Apertura")
      eqv(r.legacyCloseDay,BigInt(5778),"Chiusura")
      eqv(r.phase,"DISCOVERY_13_YEAR_JUMP","Fase")
      eqv(r.status,"LEGACY_YEAR_JUMP_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_13_YEAR_JUMP"),"Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery13.year.jump.calls"),BigInt(1),
        "Metrica")
    }
    check("due richieste allo stesso manager sono isolate") {
      val m=new BaseMonsterManager
      val a=m.discover13YearJump(0,601,0,Before,After)
      val b=m.discover13YearJump(0,-401,0,Before,After)
      eqv(a.legacyYearOffset,BigInt(0),"Primo")
      eqv(b.legacyYearOffset,BigInt(-1),"Secondo")
      eqv(m.metricsSnapshot("discovery13.year.jump.calls"),BigInt(2),
        "Due invocazioni")
    }
    check("handler rifiuta Bootstrap mancante e doppio utilizzo") {
      val h=new Discovery13YearJumpHandler(new BaseMetricsShell)
      rejectState("Nessun bootstrap"){h.handle(BaseMonsterContext(1,601))}
      val c=ready()
      val previous=c.legacyJumpOffset
      rejectState("Seconda applicazione"){h.handle(c)}
      eqv(c.legacyJumpOffset,previous,"Output conservato")
    }
    check("handler rifiuta input incompleti") {
      val h=new Discovery13YearJumpHandler(new BaseMetricsShell)
      val c=BaseMonsterContext(1,601)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_13_YEAR_JUMP"
      c.jumpAnchorOpenDay=Some(0)
      rejectState("Durate assenti"){h.handle(c)}
      truth(c.legacyJumpOffset.isEmpty,"Stato non alterato")
    }
    check("validator rifiuta output e trace assenti") {
      val c=BaseMonsterContext(1,601)
      c.phase="DISCOVERY_13_YEAR_JUMP"
      c.status="LEGACY_YEAR_JUMP_READY"
      c.jumpAnchorOpenDay=Some(0)
      c.jumpBeforeLengths=Some(Before)
      c.jumpFromAnchorLengths=Some(After)
      val v=new BaseValidationManager
      rejectState("Output assente"){v.requireDiscovery13Ready(c)}
      val r=legacy()
      c.legacyJumpOffset=Some(r.guessedOffset)
      c.legacyJumpOpenDay=Some(r.guessedOpenDay)
      c.legacyJumpCloseDay=Some(r.guessedCloseDay)
      rejectState("Trace assente"){v.requireDiscovery13Ready(c)}
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_13_YEAR_JUMP"))
      v.requireDiscovery13Ready(c)
    }
    check("validator rifiuta offset storico falsificato") {
      val c=ready()
      c.legacyJumpOffset=Some(1)
      rejectState("Offset falso"){
        new BaseValidationManager().requireDiscovery13Ready(c)}
    }
    check("validator rifiuta una apertura storica falsa") {
      val c=ready()
      c.legacyJumpOpenDay=Some(300)
      rejectState("Apertura falsa"){
        new BaseValidationManager().requireDiscovery13Ready(c)}
    }
    check("validator rifiuta una chiusura storica falsa") {
      val c=ready()
      c.legacyJumpCloseDay=Some(300)
      rejectState("Chiusura falsa"){
        new BaseValidationManager().requireDiscovery13Ready(c)}
    }
    check("validator rifiuta una durata di anno mutata non valida") {
      val c=ready()
      c.jumpBeforeLengths=Some(Vector(1,500,600,700,800))
      rejectState("Durata illegale"){
        new BaseValidationManager().requireDiscovery13Ready(c)}
    }
    check("validator rifiuta alterazione dell'ancora") {
      val c=ready()
      c.jumpAnchorOpenDay=Some(BigInt(9999))
      rejectState("Ancora contraffatta"){
        new BaseValidationManager().requireDiscovery13Ready(c)}
    }
    check("validator rifiuta phase e trace alterate") {
      val c=ready()
      val v=new BaseValidationManager
      c.branchTrace.remove(1)
      rejectState("Trace errata"){v.requireDiscovery13Ready(c)}
      c.branchTrace.append("DISCOVERY_13_YEAR_JUMP")
      c.phase="PATCH_13_YEAR_JUMP"
      rejectState("Fase successiva"){v.requireDiscovery13Ready(c)}
    }
    check("validator verifica 1024 offset locali senza overflow") {
      val v=new BaseValidationManager
      for(k<- -512 to 511) {
        val c=ready(target=BigInt(k)*5778+1)
        v.requireDiscovery13Ready(c)
      }
    }
    check("le dodici patch precedenti rimangono normative") {
      val m=new BaseMonsterManager
      val f=NormativeOracle.FoundationDay
      val modulus=NormativeOracle.M
      eqv(m.patch01Save(0,0,modulus).patchedOutput,modulus,"SAVE")
      eqv(m.patch02DayTag(f,f,f).patchedTag,BigInt(1),"DayTag")
      eqv(m.patch03Distance(f,f).patchedDistance,BigInt(1),"Distance")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"Stones")
      val hidden=Vector[BigInt](101,202,303,404,505,606,707)
      eqv(m.patch05Prior(0,0,hidden,Vector.empty,1,7).patchedValue,BigInt(707),"Prior")
      eqv(m.patch06Grind(0,0,1,7,11,13,17,
        Vector[BigInt](19,23,29,31,37)).patchedValue,BigInt(422),"Grind")
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,
        Vector(6,5,4,3,2,1),"Permutation")
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),
        37,Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"Bowl freeze")
      eqv(m.patch09Vault(0,0,Vector[BigInt](11,13,17,19,23,29)).patchedBowls,
        NormativeOracle.postStir12(Vector[BigInt](11,13,17,19,23,29)),"Vault")
      eqv(m.patch10Order46(0,0,1,720,1).correctedNextBowl,6,"Latch")
      eqv(m.patch11ShortPick(0,0,modulus,1,5).patchedRank,BigInt(1),"Rejection")
      eqv(m.patch12YearCeiling(0,0,Vector.fill(6)(963)).patchedAccepted,
        true,"Anno 5778")
    }
    check("oracolo test-only e nessuna PATCH 13 anticipata") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val source=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!source.contains("NormativeOracle"),"Oracolo in produzione")
      truth(source.contains("def oldJumpGuess("),"Cicatrice del salto")
      truth(source.contains("val estimate=if(relative<0 && r!=0)q-1 else q"),
        "Divisione storica e arrotondamento")
      val stage=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=stage.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if(current<27)
        truth(!source.contains("yearJumpPatch"),"PATCH 13 anticipata")
      else
        truth(source.contains("def yearJumpPatch("),"PATCH 13 successiva presente")
      if(current<28)
        truth(!source.contains("VirtualLegacyList"),"Futura fase anticipata")
      else
        truth(source.contains("object VirtualLegacyListAdapter"),
          "DISCOVERY 14 successiva disponibile")
    }
    check("metadati Stage26 RED conservano Stage25 GREEN") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current>=26,"Stadio")
      if(current==26) {
        truth(st.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
        truth(st.contains("CURRENT_PATCH=12"),"Patch precedente")
        truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"RED")
      } else {
        truth(st.contains("STAGE_26_EXPECTED_RESULT=38_PASS_3_FAIL_INTENTIONAL"),
          "Firma storica RED conservata")
      }
      truth(st.contains("STAGE_25_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_42_PASS_0_FAIL"),
        "Certificazione Stage25")
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=25 && completed<=current,"Ordine certificazioni")
    }

    Vector(
      ("avanti",BigInt(601)),
      ("indietro",BigInt(-401)),
      ("porta",BigInt(1301))
    ).foreach {case(label,target) =>
      check("equivalenza normativa salto "+label) {
        val report=new BaseMonsterManager().discover13YearJump(
          0,target,0,Before,After)
        eqv(report.legacyYearOffset,
          yearAt(0,Before,After,target).offset,
          "Salto fisso 5778 ignora cancelli: "+label)
      }
    }
    println("\nRISULTATO STADIO 26: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
