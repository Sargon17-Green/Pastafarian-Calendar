package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 07: copertura esaustiva di rango 1..720 e prova della cicatrice. */
object Stage15Tests {
  private var passed = 0
  private var failed = 0
  private val First = Vector(1, 2, 3, 4, 5, 6)
  private val Last = Vector(6, 5, 4, 3, 2, 1)

  private def check(name: String)(body: => Unit): Unit = {
    try {
      body
      passed += 1
      println("PASS — " + name)
    } catch {
      case error: Throwable =>
        failed += 1
        println("FAIL — " + name + " — " + error.getMessage)
        error.printStackTrace(System.out)
    }
  }
  private def eqv[A](got: A, expected: A, name: String): Unit =
    if (got != expected)
      throw new AssertionError(
        name + ": atteso=" + expected + ", ottenuto=" + got)
  private def truth(ok: Boolean, name: String): Unit =
    if (!ok) throw new AssertionError(name)
  private def rejectArg(name: String)(body: => Unit): Unit = {
    var rejected = false
    try body catch { case _: IllegalArgumentException => rejected = true }
    truth(rejected, name + ": argomento accettato")
  }
  private def rejectState(name: String)(body: => Unit): Unit = {
    var rejected = false
    try body catch { case _: IllegalStateException => rejected = true }
    truth(rejected, name + ": stato non valido accettato")
  }
  private def root(): java.nio.file.Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null)
      p = p.getParent
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice del progetto assente")
    p
  }
  private def discoveryReady(rank: Int): BaseMonsterContext = {
    val c = BaseMonsterContext(1, 2)
    c.status = "BOOTSTRAPPED"
    c.branchTrace.append("BOOT")
    c.permutationRankInput = Some(rank)
    c.phase = "DISCOVERY_07_PERMUTATION"
    new Discovery07PermutationHandler(new BaseMetricsShell).handle(c)
    c.phase = "PATCH_07_PERMUTATION"
    c
  }

  def main(args: Array[String]): Unit = {
    check("rango 1: ripristino della prima permutazione") {
      eqv(LegacyPermutationAdapter.oldPermutationUnrank0(1),
        Vector(1,2,3,4,6,5), "Cicatrice 1")
      eqv(Patch07PermutationWrapper.permutationPatch(1), First, "Rango 1")
    }
    check("rango 2: ripristino della seconda permutazione") {
      eqv(LegacyPermutationAdapter.oldPermutationUnrank0(2),
        Vector(1,2,3,5,4,6), "Cicatrice 2")
      eqv(Patch07PermutationWrapper.permutationPatch(2),
        Vector(1,2,3,4,6,5), "Rango 2")
    }
    check("rango 719: penultimo ordine lessicografico") {
      eqv(Patch07PermutationWrapper.permutationPatch(719),
        NormativeOracle.bowlOrderFromNumber(719), "Rango 719")
    }
    check("rango 720: niente ritorno all'inizio") {
      eqv(LegacyPermutationAdapter.oldPermutationUnrank0(720), First,
        "Riavvolgimento storico")
      eqv(Patch07PermutationWrapper.permutationPatch(720), Last,
        "Ultima permutazione normativa")
    }
    check("la cicatrice legacy resta spostata esattamente di un rango") {
      (1 to 720).foreach { rank =>
        eqv(LegacyPermutationAdapter.oldPermutationUnrank0(rank),
          NormativeOracle.bowlOrderFromNumber(rank % 720 + 1),
          "Cicatrice preservata " + rank)
      }
    }
    check("PATCH 07 coincide con l'oracolo per tutti i 720 ranghi") {
      (1 to 720).foreach { rank =>
        eqv(Patch07PermutationWrapper.permutationPatch(rank),
          NormativeOracle.bowlOrderFromNumber(rank),
          "Rango normativo " + rank)
      }
    }
    check("la stessa famiglia di 720 ordini è completa e priva di ripetizioni") {
      val patched=(1 to 720).map(Patch07PermutationWrapper.permutationPatch).toVector
      eqv(patched.distinct.length,720,"Unicità")
      eqv(patched.head,First,"Inizio")
      eqv(patched.last,Last,"Fine")
      eqv(patched.toSet,(1 to 720).map(NormativeOracle.bowlOrderFromNumber).toSet,
        "Famiglia completa")
    }
    check("ordine lessicografico rigorosamente crescente fra ranghi") {
      val all=(1 to 720).map(Patch07PermutationWrapper.permutationPatch).toVector
      (0 until 719).foreach { i =>
        val a=all(i)
        val b=all(i+1)
        val firstDiff=(0 until 6).find(j=>a(j)!=b(j))
        truth(firstDiff.nonEmpty && a(firstDiff.get)<b(firstDiff.get),
          "Lessicografia " + (i+1))
      }
    }
    check("le classi della prima ciotola hanno esattamente 120 ordini") {
      val all=(1 to 720).map(Patch07PermutationWrapper.permutationPatch)
      (1 to 6).foreach { n => eqv(all.count(_.head==n),120,"Classe "+n) }
    }
    check("ogni blocco di 120 ranghi inizia con il primo elemento previsto") {
      (0 to 5).foreach { block =>
        (1 to 120).foreach { j =>
          eqv(Patch07PermutationWrapper.permutationPatch(block*120+j).head,
            block+1,"Blocco "+block+" rango "+j)
        }
      }
    }
    check("il prefisso di cinque elementi cambia sul bordo fattoriale") {
      for(rank <- Vector(1,2,6,7,24,25,120,121,719,720)) {
        eqv(Patch07PermutationWrapper.permutationPatch(rank),
          NormativeOracle.bowlOrderFromNumber(rank), "Bordo "+rank)
      }
    }
    check("inversione indipendente dell'unranking tramite rango fattoriale") {
      val factorial=Vector(1,1,2,6,24,120,720)
      (1 to 720).foreach { expectedRank =>
        val p=Patch07PermutationWrapper.permutationPatch(expectedRank)
        var remaining=Vector(1,2,3,4,5,6)
        var rank=1
        p.zipWithIndex.foreach { case (v,idx) =>
          val position=remaining.indexOf(v)
          truth(position>=0,"Identificatore non presente")
          rank += position * factorial(5-idx)
          remaining=remaining.patch(position,Nil,1)
        }
        eqv(rank,expectedRank,"Rango inverso "+expectedRank)
      }
    }
    check("rank 720 è davvero il massimo e rank 1 il minimo") {
      val all=(1 to 720).map(Patch07PermutationWrapper.permutationPatch).toVector
      eqv(all.min(Ordering.Iterable[Int]),First,"Minimo")
      eqv(all.max(Ordering.Iterable[Int]),Last,"Massimo")
    }
    check("due esecuzioni della famiglia sono riproducibili") {
      val left=(1 to 720).map(Patch07PermutationWrapper.permutationPatch).toVector
      val right=(1 to 720).map(Patch07PermutationWrapper.permutationPatch).toVector
      eqv(left,right,"Due enumerazioni")
    }
    check("2048 ranghi casuali deterministici coincidono con il riferimento") {
      val rng=new Random(20261011L)
      (1 to 2048).foreach { n =>
        val rank=rng.nextInt(720)+1
        eqv(Patch07PermutationWrapper.permutationPatch(rank),
          NormativeOracle.bowlOrderFromNumber(rank),"Campione "+n)
      }
    }
    check("input illegali rimangono illegali nel wrapper") {
      Vector(Int.MinValue,-1000,-720,-1,0,721,1440,Int.MaxValue).foreach { rank =>
        rejectArg("Rank "+rank) {Patch07PermutationWrapper.permutationPatch(rank)}
      }
    }
    check("manager fa eseguire davvero BOOT DISCOVERY 07 PATCH 07") {
      val m=new BaseMonsterManager
      val r=m.patch07Permutation(13,-17,1)
      eqv(r.calculationDay,BigInt(13),"Giorno calcolo")
      eqv(r.targetDay,BigInt(-17),"Giorno chiesto")
      eqv(r.requestedRank1,1,"Rango")
      eqv(r.legacyPermutation,Vector(1,2,3,4,6,5),"Legacy")
      eqv(r.patchedPermutation,First,"Patched")
      truth(r.patchApplied,"Flag applicazione")
      eqv(r.phase,"PATCH_07_PERMUTATION","Fase")
      eqv(r.status,"PATCH_07_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_07_PERMUTATION","PATCH_07_PERMUTATION"),"Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Metrica bootstrap")
      eqv(m.metricsSnapshot("discovery07.permutation.calls"),BigInt(1),"Metrica discovery")
      eqv(m.metricsSnapshot("patch07.permutation.calls"),BigInt(1),"Metrica patch")
    }
    check("manager allinea entrambi gli output per tutti i 720 ranghi") {
      val m=new BaseMonsterManager
      (1 to 720).foreach { rank =>
        val r=m.patch07Permutation(0,0,rank)
        eqv(r.legacyPermutation,LegacyPermutationAdapter.oldPermutationUnrank0(rank),
          "Storico "+rank)
        eqv(r.patchedPermutation,NormativeOracle.bowlOrderFromNumber(rank),
          "Normativo "+rank)
      }
      eqv(m.metricsSnapshot("patch07.permutation.calls"),BigInt(720),"Contatori")
    }
    check("diagnostica storica resta interrogabile dopo la patch") {
      val m=new BaseMonsterManager
      for(rank <- Vector(1,2,3,120,360,719,720)) {
        val before=m.discover07Permutation(1,2,rank)
        val after=m.patch07Permutation(1,2,rank)
        eqv(before.legacyPermutation,after.legacyPermutation,"Cicatrice "+rank)
        eqv(before.trace,Vector("BOOT","DISCOVERY_07_PERMUTATION"),"Traccia")
      }
    }
    check("il rango è indipendente dai giorni con BigInt oltre 16000 bit") {
      val giant=(BigInt(1) << 16384)+97531
      val m=new BaseMonsterManager
      val a=m.patch07Permutation(0,0,720)
      val b=m.patch07Permutation(giant,-giant,720)
      eqv(a.patchedPermutation,b.patchedPermutation,"Indipendenza")
      eqv(b.calculationDay,giant,"Calcolo BigInt")
      eqv(b.targetDay,-giant,"Target BigInt")
    }
    check("snapshot immutabili e invocazioni isolate") {
      val m=new BaseMonsterManager
      val a=m.patch07Permutation(1,2,1)
      val b=m.patch07Permutation(3,4,720)
      eqv(a.patchedPermutation,First,"Snapshot prima")
      eqv(b.patchedPermutation,Last,"Snapshot seconda")
      eqv(a.requestedRank1,1,"Input conservato")
      eqv(m.metricsSnapshot("patch07.permutation.calls"),BigInt(2),"Contatori")
    }
    check("handler rifiuta un contesto vergine o un falso bootstrap") {
      val h=new Patch07PermutationHandler(new BaseMetricsShell)
      rejectState("Nuovo"){h.handle(BaseMonsterContext(1,2))}
      val c=BaseMonsterContext(1,2)
      c.status="LEGACY_PERMUTATION_READY"
      c.permutationRankInput=Some(1)
      c.legacyPermutationOutput=Some(Vector(1,2,3,4,6,5))
      rejectState("Traccia mancante"){h.handle(c)}
      truth(c.patchedPermutationOutput.isEmpty && !c.patch07Applied,
        "Rifiuto senza effetti")
    }
    check("handler preserva l'output sulla seconda applicazione rifiutata") {
      val h=new Patch07PermutationHandler(new BaseMetricsShell)
      val c=discoveryReady(720)
      h.handle(c)
      val old=c.patchedPermutationOutput
      rejectState("Seconda applicazione"){h.handle(c)}
      eqv(c.patchedPermutationOutput,old,"Nessun aggiornamento")
    }
    check("validator non accetta un risultato mancante") {
      val v=new BaseValidationManager
      val c=discoveryReady(1)
      c.status="PATCH_07_READY"
      c.branchTrace.append("PATCH_07_PERMUTATION")
      c.patch07Applied=true
      rejectState("Manca patched"){v.requirePatch07Ready(c)}
    }
    check("validator conferma la formula indipendente su tutti i ranghi") {
      val v=new BaseValidationManager
      val h=new Patch07PermutationHandler(new BaseMetricsShell)
      (1 to 720).foreach { rank =>
        val c=discoveryReady(rank)
        h.handle(c)
        v.requirePatch07Ready(c)
      }
    }
    check("validator rileva una permutazione corretta ma del rango sbagliato") {
      val v=new BaseValidationManager
      val c=discoveryReady(5)
      new Patch07PermutationHandler(new BaseMetricsShell).handle(c)
      c.patchedPermutationOutput=Some(NormativeOracle.bowlOrderFromNumber(6))
      rejectState("Rango errato"){v.requirePatch07Ready(c)}
    }
    check("validator respinge manipolazione della cicatrice legacy") {
      val v=new BaseValidationManager
      val c=discoveryReady(1)
      new Patch07PermutationHandler(new BaseMetricsShell).handle(c)
      c.legacyPermutationOutput=Some(First)
      rejectState("Legacy contraffatta"){v.requirePatch07Ready(c)}
    }
    check("validator respinge fase stato traccia e flag falsificati") {
      val v=new BaseValidationManager
      val c=discoveryReady(1)
      new Patch07PermutationHandler(new BaseMetricsShell).handle(c)
      v.requirePatch07Ready(c)
      c.patch07Applied=false
      rejectState("Flag"){v.requirePatch07Ready(c)}
      c.patch07Applied=true
      c.status="LEGACY_PERMUTATION_READY"
      rejectState("Stato"){v.requirePatch07Ready(c)}
      c.status="PATCH_07_READY"
      c.branchTrace.remove(1)
      rejectState("Traccia"){v.requirePatch07Ready(c)}
    }
    check("PATCH 01–06 sono ancora normative e tutte le cicatrici osservabili") {
      val m=new BaseMonsterManager
      val foundation=NormativeOracle.FoundationDay
      val mod=NormativeOracle.M
      eqv(m.discover01Remainder(0,0,mod).legacyOutput,BigInt(0),"Scar SAVE")
      eqv(m.patch01Save(0,0,mod).patchedOutput,mod,"SAVE")
      eqv(m.discover02DayTag(foundation,foundation,foundation).legacyTag,BigInt(0),"Scar day")
      eqv(m.patch02DayTag(foundation,foundation,foundation).patchedTag,BigInt(1),"DayTag")
      eqv(m.discover03Distance(0,0).legacyDistance,BigInt(0),"Scar distance")
      eqv(m.patch03Distance(0,0).patchedDistance,BigInt(1),"Distance")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"Stones")
      val h=Vector[BigInt](101,202,303,404,505,606,707)
      eqv(m.discover05Prior(0,0,h,Vector.empty,1,7).legacyValue,BigInt(606),"Scar prior")
      eqv(m.patch05Prior(0,0,h,Vector.empty,1,7).patchedValue,BigInt(707),"Prior")
      val stones=Vector[BigInt](19,23,29,31,37)
      eqv(m.discover06Grind(0,0,1,7,11,13,17,stones).legacyValue,BigInt(68),"Scar grind")
      eqv(m.patch06Grind(0,0,1,7,11,13,17,stones).patchedValue,BigInt(422),"Grind")
    }
    check("oracolo assente in produzione e nessuna logica Stage16") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo test-only")
      truth(sources.contains("LegacyPermutationAdapter.oldPermutationUnrank0(rank1)"),
        "Il wrapper deve usare realmente l'algoritmo storico")
      truth(!sources.contains("bowlAlias"),"Funzione futura anticipata")
    }
    check("metadati dichiarano Stage15 verde e patch sette") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=15"),"Stadio 15")
      truth(st.contains("CURRENT_KIND=PATCH"),"Fase")
      truth(st.contains("CURRENT_PATCH=07"),"Patch")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"GREEN")
      truth(st.contains("STAGE_14_NATIVE_VERIFICATION=PASS_EXPECTED_RED_20_PASS_3_FAIL"),
        "Firma RED stadio 14 preservata")
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("LAST_COMPLETED_STAGE assente"))
      truth(completed>=14 && completed<=15,"Certificazione non anticipata")
    }
    println("\nRISULTATO STADIO 15: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0) sys.exit(1)
  }
}
