package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.file.{Files, Paths}
import java.nio.charset.StandardCharsets
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 05: ritardi 1/3/7 normativi, cicatrice i-6 ancora percorribile. */
object Stage11Tests {
  private var passed=0
  private var failed=0
  private val H=Vector[BigInt](101,202,303,404,505,606,707)
  private val V=Vector.tabulate[BigInt](46)(i => BigInt(2000+i))
  private val F=NormativeOracle.FoundationDay

  private def check(name:String)(body: => Unit):Unit = try {
    body
    passed+=1
    println("PASS — "+name)
  } catch {
    case ex:Throwable =>
      failed+=1
      println("FAIL — "+name+" — "+ex.getMessage)
      ex.printStackTrace(System.out)
  }
  private def eqv[A](actual:A,expected:A,name:String):Unit =
    if(actual!=expected)throw new AssertionError(
      name+": atteso="+expected+", ottenuto="+actual)
  private def truth(v:Boolean,name:String):Unit =
    if(!v)throw new AssertionError(name)
  private def rejectArg(name:String)(body: => Unit):Unit = {
    var rejected=false
    try body catch {case _:IllegalArgumentException => rejected=true}
    truth(rejected,name+": eccezione mancante")
  }
  private def rejectState(name:String)(body: => Unit):Unit = {
    var rejected=false
    try body catch {case _:IllegalStateException => rejected=true}
    truth(rejected,name+": stato falso accettato")
  }
  private def canonical(hidden:Vector[BigInt],visible:Vector[BigInt],i:Int,lag:Int):BigInt = {
    val pos=i-lag
    if(pos<=0)hidden(-pos) else visible(pos-1)
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del repository assente")
    p
  }

  def main(args:Array[String]):Unit = {
    check("helper storico mantiene tre letture sbagliate al ritardo sette") {
      eqv(LegacyPriorAdapter.legacyPrior(H,Vector.empty,1,7),H(5),"Goccia 1")
      eqv(LegacyPriorAdapter.legacyPrior(H,V.take(6),7,7),V(0),"Goccia 7")
      eqv(LegacyPriorAdapter.legacyPrior(H,V,47,7),V(40),"Goccia 47")
    }

    check("PATCH 05 legge il settimo nascosto alla prima goccia") {
      eqv(Patch05PriorWrapper.priorPatch(H,Vector.empty,1,7),H(6),"Prima goccia")
      truth(H(6)!=H(5),"La cicatrice deve distinguersi")
    }

    check("ritardo uno su tutte le 47 finestre") {
      (1 to 47).foreach { i =>
        eqv(Patch05PriorWrapper.priorPatch(H,V.take(i-1),i,1),
          canonical(H,V,i,1),"Lag1 posizione "+i)
      }
    }

    check("ritardo tre su tutte le 47 finestre") {
      (1 to 47).foreach { i =>
        eqv(Patch05PriorWrapper.priorPatch(H,V.take(i-1),i,3),
          canonical(H,V,i,3),"Lag3 posizione "+i)
      }
    }

    check("ritardo sette corretto su tutte le 47 finestre") {
      (1 to 47).foreach { i =>
        eqv(Patch05PriorWrapper.priorPatch(H,V.take(i-1),i,7),
          canonical(H,V,i,7),"Lag7 posizione "+i)
      }
    }

    check("prodotto cartesiano di 47 posizioni e tre ritardi") {
      for(i<-1 to 47; lag<-Vector(1,3,7)) {
        eqv(Patch05PriorWrapper.priorPatch(H,V.take(i-1),i,lag),
          canonical(H,V,i,lag),"Finestra "+i+"/"+lag)
      }
    }

    check("tutte le soglie da nascosto a visibile per il ritardo sette") {
      (1 to 7).foreach { i =>
        val corrected=Patch05PriorWrapper.priorPatch(H,V.take(i-1),i,7)
        eqv(corrected,H(7-i),"Hidden "+i)
      }
    }

    check("dalla ottava goccia il ritardo sette usa soltanto precedenti visibili") {
      (8 to 47).foreach { i =>
        val corrected=Patch05PriorWrapper.priorPatch(H,V.take(i-1),i,7)
        eqv(corrected,V(i-8),"Visible "+i)
      }
    }

    check("equivalenza alle gocce reali dell'oracolo per 47 per tre letture") {
      val counts=NormativeOracle.workCounts(F,F+1)
      val hidden=NormativeOracle.buildHiddenDrops(counts)
      val visible=NormativeOracle.buildVisibleDrops(counts,hidden)
      eqv(hidden.length,7,"Sette nascoste")
      eqv(visible.length,46,"Quarantasei visibili")
      for(i<-1 to 47; lag<-Vector(1,3,7)) {
        eqv(Patch05PriorWrapper.priorPatch(hidden,visible.take(i-1),i,lag),
          canonical(hidden,visible,i,lag),"Oracolo "+i+"/"+lag)
      }
    }

    check("i tre casi RED storici diventano verdi soltanto nel wrapper") {
      val counts=NormativeOracle.workCounts(F,F+1)
      val hidden=NormativeOracle.buildHiddenDrops(counts)
      val visible=NormativeOracle.buildVisibleDrops(counts,hidden)
      Vector(1,7,47).foreach { i =>
        val past=visible.take(i-1)
        val expected=canonical(hidden,visible,i,7)
        eqv(Patch05PriorWrapper.priorPatch(hidden,past,i,7),expected,"Patch "+i)
        truth(LegacyPriorAdapter.legacyPrior(hidden,past,i,7)!=expected,
          "La diagnostica non può diventare verde al caso "+i)
      }
    }

    check("i ritardi uno e tre riutilizzano i valori del vero legacy") {
      for(i<-1 to 47; lag<-Vector(1,3)) {
        eqv(Patch05PriorWrapper.priorPatch(H,V.take(i-1),i,lag),
          LegacyPriorAdapter.legacyPrior(H,V.take(i-1),i,lag),
          "Legame legacy "+i+"/"+lag)
      }
    }

    check("BigInt positivi e negativi oltre 16384 bit") {
      val huge=(BigInt(1)<<16384)+1234567
      val hidden=Vector.tabulate[BigInt](7)(i => huge+BigInt(i))
      val visible=Vector.tabulate[BigInt](46)(i => -(huge+BigInt(i)))
      for(i<-1 to 47; lag<-Vector(1,3,7)) {
        eqv(Patch05PriorWrapper.priorPatch(hidden,visible.take(i-1),i,lag),
          canonical(hidden,visible,i,lag),"Bit 16384 "+i+"/"+lag)
      }
    }

    check("segni contrari e valori di modulo enorme non causano troncamenti") {
      val max=BigInt(1)<<4096
      val hidden=Vector[BigInt](-max,max,-max-3,max+3,-max-7,max+7,-max-11)
      val visible=Vector.tabulate[BigInt](46)(i => if(i%2==0)max+i else -max-i)
      for(i<-1 to 47; lag<-Vector(1,3,7)) {
        eqv(Patch05PriorWrapper.priorPatch(hidden,visible.take(i-1),i,lag),
          canonical(hidden,visible,i,lag),"Segno "+i+"/"+lag)
      }
    }

    check("campionamento deterministico di 512 finestre arbitrarie") {
      val rng=new Random(20261011L)
      (1 to 512).foreach { sample =>
        val k=1+rng.nextInt(47)
        val lag=Vector(1,3,7)(rng.nextInt(3))
        val hidden=Vector.fill(7)(BigInt(1)<<(1+rng.nextInt(4096)))
        val visible=Vector.fill(k-1)(-(BigInt(1)<<(1+rng.nextInt(4096))))
        eqv(Patch05PriorWrapper.priorPatch(hidden,visible,k,lag),
          canonical(hidden,visible,k,lag),"Campione "+sample)
      }
    }

    check("nessuna modifica delle finestre passate dal chiamante") {
      val hidden=H
      val visible=V.take(20)
      val beforeH=hidden
      val beforeV=visible
      (1 to 50).foreach(_ => Patch05PriorWrapper.priorPatch(hidden,visible,21,7))
      eqv(hidden,beforeH,"Hidden")
      eqv(visible,beforeV,"Visible")
    }

    check("cinquanta invocazioni ripetute restituiscono output deterministico") {
      val expected=canonical(H,V,40,7)
      val results=Vector.fill(50)(Patch05PriorWrapper.priorPatch(H,V.take(39),40,7))
      truth(results.forall(_==expected),"Determinismo")
    }

    check("finestre vuote anticipate o mancanti vengono rifiutate") {
      rejectArg("Finestra anticipata") {
        Patch05PriorWrapper.priorPatch(H,V.take(1),1,7)
      }
      rejectArg("Finestra parziale") {
        Patch05PriorWrapper.priorPatch(H,V.take(10),12,7)
      }
      rejectArg("Finestra lunga") {
        Patch05PriorWrapper.priorPatch(H,V,46,1)
      }
    }

    check("lunghezza nascosta sei o otto rifiutata") {
      rejectArg("Sei") {Patch05PriorWrapper.priorPatch(H.take(6),Vector.empty,1,7)}
      rejectArg("Otto") {Patch05PriorWrapper.priorPatch(H:+BigInt(808),Vector.empty,1,7)}
    }

    check("indici zero negativi e oltre 47 rifiutati") {
      Vector(-100,0,48).foreach { i =>
        rejectArg("Indice "+i) {
          Patch05PriorWrapper.priorPatch(H,Vector.empty,i,7)
        }
      }
    }

    check("ritardi diversi da uno tre sette rifiutati") {
      Vector(-1,0,2,4,6,8).foreach { lag =>
        rejectArg("Lag "+lag) {
          Patch05PriorWrapper.priorPatch(H,Vector.empty,1,lag)
        }
      }
    }

    check("manager attraversa BOOT poi DISCOVERY 05 poi PATCH 05 realmente") {
      val m=new BaseMonsterManager
      val r=m.patch05Prior(11,22,H,V.take(6),7,7)
      eqv(r.calculationDay,BigInt(11),"Calculation day")
      eqv(r.targetDay,BigInt(22),"Target day")
      eqv(r.index,7,"Indice")
      eqv(r.lag,7,"Lag")
      eqv(r.hiddenDrops,H,"Nascosti")
      eqv(r.visibleDropsSoFar,V.take(6),"Visibili")
      eqv(r.legacyValue,V(0),"Legacy")
      eqv(r.patchedValue,H(0),"Normativo")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_05_PRIOR","Fase")
      eqv(r.status,"PATCH_05_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_05_PRIOR","PATCH_05_PRIOR"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery05.prior.calls"),BigInt(1),"Discovery reale")
      eqv(m.metricsSnapshot("patch05.prior.calls"),BigInt(1),"Patch reale")
    }

    check("report include sempre i due output e preserva la diagnostica") {
      val m=new BaseMonsterManager
      val before=m.discover05Prior(F,F,H,Vector.empty,1,7)
      val after=m.patch05Prior(F,F,H,Vector.empty,1,7)
      eqv(before.legacyValue,H(5),"Diag")
      eqv(after.legacyValue,before.legacyValue,"Cicatrice nel report")
      eqv(after.patchedValue,H(6),"Correzione")
      eqv(before.trace,Vector("BOOT","DISCOVERY_05_PRIOR"),"Percorso vecchio")
      eqv(m.metricsSnapshot("discovery05.prior.calls"),BigInt(2),"Legacy invocato due volte")
    }

    check("due manager calls mantengono ownership e metriche isolate") {
      val m=new BaseMonsterManager
      val first=m.patch05Prior(1,2,H,Vector.empty,1,7)
      val second=m.patch05Prior(3,4,H,V.take(10),11,1)
      eqv(first.legacyValue,H(5),"Legacy primo")
      eqv(first.patchedValue,H(6),"Primo corretto")
      eqv(second.legacyValue,V(9),"Legacy secondo")
      eqv(second.patchedValue,V(9),"Secondo corretto")
      eqv(first.calculationDay,BigInt(1),"Snapshot 1")
      eqv(second.calculationDay,BigInt(3),"Snapshot 2")
      eqv(m.metricsSnapshot("patch05.prior.calls"),BigInt(2),"Due chiamate")
    }

    check("validator respinge manomissione di output legacy e patched") {
      val v=new BaseValidationManager
      val c=BaseMonsterContext(1,2)
      c.phase="PATCH_05_PRIOR"
      c.status="PATCH_05_READY"
      c.patch05Applied=true
      rejectState("Campi vuoti") {v.requirePatch05Ready(c)}
      c.priorHiddenInput=Some(H)
      c.priorVisibleInput=Some(Vector.empty)
      c.priorIndexInput=Some(1)
      c.priorLagInput=Some(7)
      c.legacyPriorOutput=Some(H(5))
      c.patchedPriorOutput=Some(H(6))
      rejectState("Traccia mancante") {v.requirePatch05Ready(c)}
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_05_PRIOR","PATCH_05_PRIOR"))
      v.requirePatch05Ready(c)
      c.patchedPriorOutput=Some(H(5))
      rejectState("Patch falsa") {v.requirePatch05Ready(c)}
      c.patchedPriorOutput=Some(H(6))
      c.legacyPriorOutput=Some(H(6))
      rejectState("Cicatrice contraffatta") {v.requirePatch05Ready(c)}
      c.legacyPriorOutput=Some(H(5))
      c.patch05Applied=false
      rejectState("Flag assente") {v.requirePatch05Ready(c)}
    }

    check("handler rifiuta bypass e doppia patch senza effetti") {
      val h=new Patch05PriorHandler(new BaseMetricsShell)
      val fake=BaseMonsterContext(1,2)
      rejectState("Nessun bootstrap") {h.handle(fake)}
      fake.status="LEGACY_PRIOR_READY"
      fake.priorHiddenInput=Some(H)
      fake.priorVisibleInput=Some(Vector.empty)
      fake.priorIndexInput=Some(1)
      fake.priorLagInput=Some(7)
      fake.legacyPriorOutput=Some(H(5))
      rejectState("Nessuna trace discovery") {h.handle(fake)}
      truth(fake.patchedPriorOutput.isEmpty && !fake.patch05Applied,"Nessun effetto")
      val real=BaseMonsterContext(1,2)
      real.status="BOOTSTRAPPED"
      real.branchTrace.append("BOOT")
      real.priorHiddenInput=Some(H)
      real.priorVisibleInput=Some(Vector.empty)
      real.priorIndexInput=Some(1)
      real.priorLagInput=Some(7)
      new Discovery05PriorHandler(new BaseMetricsShell).handle(real)
      real.phase="PATCH_05_PRIOR"
      h.handle(real)
      rejectState("Doppia applicazione") {h.handle(real)}
    }

    check("quattro patch precedenti rimangono verdi e cicatrici accessibili") {
      val m=new BaseMonsterManager
      val mod=NormativeOracle.M
      eqv(m.discover01Remainder(0,0,mod).legacyOutput,BigInt(0),"Scar 01")
      eqv(m.patch01Save(0,0,mod).patchedOutput,mod,"PATCH 01")
      eqv(m.discover02DayTag(F,F,F).legacyTag,BigInt(0),"Scar 02")
      eqv(m.patch02DayTag(F,F,F).patchedTag,BigInt(1),"PATCH 02")
      eqv(m.discover03Distance(F,F).legacyDistance,BigInt(0),"Scar 03")
      eqv(m.patch03Distance(F,F).patchedDistance,BigInt(1),"PATCH 03")
      eqv(m.discover04Stones(F,F).legacyStoneRows(1)(1),BigInt(1434),"Scar 04")
      eqv(m.patch04Stones(F,F).patchedStoneRows,NormativeOracle.Stones,"PATCH 04")
    }

    check("oracolo solo nel test e Stage11 verde senza Stage12") {
      val status=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val currentStage = status.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("CURRENT_STAGE mancante"))
      truth(currentStage >= 11,"PATCH 05 resta disponibile")
      if (currentStage == 11) {
        truth(status.contains("CURRENT_KIND=PATCH"),"Tipo")
        truth(status.contains("CURRENT_PATCH=05"),"Patch")
        truth(status.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"GREEN")
      } else {
        truth(status.contains("STAGE_11_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_27_PASS_0_FAIL"),
          "Certificazione dello stadio 11 preservata")
      }
      truth(status.contains("STAGE_10_NATIVE_VERIFICATION=PASS_EXPECTED_RED_15_PASS_3_FAIL"),
        "Firma RED storica")
      val completed=status.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("LAST_COMPLETED_STAGE assente"))
      truth(completed >= 10 && completed <= currentStage,
        "Ordine di certificazione storico conservato")
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo nel prodotto")
      truth(sources.contains("LegacyPriorAdapter.legacyPrior(hidden, visible, index, lag)"),
        "Wrapper deve usare veramente il helper legacy")
      if (currentStage < 12)
        truth(!sources.contains("GRIND_TABLE_WITH_SENTINEL"),"Stage12 anticipato")
      else
        truth(sources.contains("GRIND_TABLE_WITH_SENTINEL"),"La cicatrice Stage12 deve essere presente")
    }

    println("\nRISULTATO STADIO 11: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
