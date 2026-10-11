package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 07: 20 PASS e 3 FAIL attesi per rango 1-based letto come 0-based. */
object Stage14Tests {
  private var passed = 0
  private var failed = 0

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
    if (got != expected) throw new AssertionError(
      name + ": atteso=" + expected + ", ottenuto=" + got)
  private def truth(ok: Boolean, name: String): Unit =
    if (!ok) throw new AssertionError(name)
  private def rejectArg(name: String)(body: => Unit): Unit = {
    var rejected = false
    try body catch { case _: IllegalArgumentException => rejected = true }
    truth(rejected, name + ": errore di argomento non ricevuto")
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
      throw new IllegalStateException("Radice non trovata")
    p
  }

  def main(args: Array[String]): Unit = {
    check("il rango storico uno produce il secondo ordine lessicografico") {
      eqv(LegacyPermutationAdapter.oldPermutationUnrank0(1),
        Vector(1, 2, 3, 4, 6, 5), "Successore della prima permutazione")
    }

    check("il rango storico due produce la terza permutazione") {
      eqv(LegacyPermutationAdapter.oldPermutationUnrank0(2),
        Vector(1, 2, 3, 5, 4, 6), "Terza permutazione")
    }

    check("il rango storico 719 restituisce il vero rango 720") {
      eqv(LegacyPermutationAdapter.oldPermutationUnrank0(719),
        Vector(6, 5, 4, 3, 2, 1), "Ultima permutazione lessicografica")
    }

    check("il rango storico 720 si riavvolge indebitamente alla prima") {
      eqv(LegacyPermutationAdapter.oldPermutationUnrank0(720),
        Vector(1, 2, 3, 4, 5, 6), "Riavvolgimento modulo 720")
    }

    check("ogni risultato legacy è una permutazione valida di sei ciotole") {
      (1 to 720).foreach { rank =>
        val p = LegacyPermutationAdapter.oldPermutationUnrank0(rank)
        eqv(p.length, 6, "Lunghezza " + rank)
        eqv(p.sorted, Vector(1, 2, 3, 4, 5, 6), "Valori " + rank)
      }
    }

    check("tutte le 720 letture sono il successore del rango normativo") {
      (1 to 720).foreach { rank =>
        val expected = NormativeOracle.bowlOrderFromNumber((rank % 720) + 1)
        eqv(LegacyPermutationAdapter.oldPermutationUnrank0(rank),
          expected, "Successore lessicografico " + rank)
      }
    }

    check("i 720 ordini storici sono tutti distinti e nessuno manca") {
      val all = (1 to 720).map(LegacyPermutationAdapter.oldPermutationUnrank0).toVector
      eqv(all.distinct.length, 720, "Bijezione sulle 720 permutazioni")
      truth(all.contains(Vector(6, 5, 4, 3, 2, 1)), "Permutazione finale")
      truth(all.contains(Vector(1, 2, 3, 4, 5, 6)), "Permutazione iniziale")
    }

    check("le classi del primo elemento sono bilanciate 120 ciascuna") {
      val all = (1 to 720).map(LegacyPermutationAdapter.oldPermutationUnrank0)
      (1 to 6).foreach { first =>
        eqv(all.count(_.head == first), 120, "Primo elemento " + first)
      }
    }

    check("la mutazione è di indice, non di scelta del repertorio") {
      val actual = (1 to 720).map(LegacyPermutationAdapter.oldPermutationUnrank0).toSet
      val normative = (1 to 720).map(NormativeOracle.bowlOrderFromNumber).toSet
      eqv(actual, normative, "Identico insieme di permutazioni")
    }

    check("campionamento deterministico di 1024 ranghi") {
      val rng = new Random(20261011L)
      (1 to 1024).foreach { sample =>
        val rank = rng.nextInt(720) + 1
        eqv(LegacyPermutationAdapter.oldPermutationUnrank0(rank),
          NormativeOracle.bowlOrderFromNumber(rank % 720 + 1),
          "Campione " + sample)
      }
    }

    check("tutti i ranghi non ammessi vengono rifiutati") {
      Vector(Int.MinValue, -720, -1, 0, 721, 1440, Int.MaxValue).foreach { rank =>
        rejectArg("Rango " + rank) {
          LegacyPermutationAdapter.oldPermutationUnrank0(rank)
        }
      }
    }

    check("ripetizioni non consumano o contaminano il registro delle permutazioni") {
      val before = LegacyPermutationAdapter.oldPermutationUnrank0(37)
      (1 to 100).foreach { _ =>
        eqv(LegacyPermutationAdapter.oldPermutationUnrank0(37),
          before, "Ripetizione")
      }
      eqv(LegacyPermutationAdapter.oldPermutationUnrank0(1),
        Vector(1, 2, 3, 4, 6, 5), "Prima dopo ripetizioni")
    }

    check("il manager esegue Bootstrap dispatcher e handler reali") {
      val m = new BaseMonsterManager
      val r = m.discover07Permutation(17, -19, 1)
      eqv(r.calculationDay, BigInt(17), "Giorno calcolo")
      eqv(r.targetDay, BigInt(-19), "Giorno chiesto")
      eqv(r.requestedRank1, 1, "Rango")
      eqv(r.legacyPermutation, Vector(1, 2, 3, 4, 6, 5), "Cicatrice")
      eqv(r.phase, "DISCOVERY_07_PERMUTATION", "Fase")
      eqv(r.status, "LEGACY_PERMUTATION_READY", "Stato")
      eqv(r.trace, Vector("BOOT", "DISCOVERY_07_PERMUTATION"), "Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"), BigInt(1), "Bootstrap")
      eqv(m.metricsSnapshot("discovery07.permutation.calls"), BigInt(1), "Handler")
    }

    check("il calcolo delle permutazioni resta indipendente dai giorni BigInt") {
      val giant = (BigInt(1) << 16384) + 97531
      val m = new BaseMonsterManager
      val a = m.discover07Permutation(0, 0, 720)
      val b = m.discover07Permutation(giant, -giant, 720)
      eqv(a.legacyPermutation, b.legacyPermutation, "Permutazione deterministica")
      eqv(a.calculationDay, BigInt(0), "Snapshot originale")
      eqv(b.targetDay, -giant, "Giorno negativo enorme")
    }

    check("due invocazioni conservano output separati e metriche osservative") {
      val m = new BaseMonsterManager
      val a = m.discover07Permutation(1, 2, 1)
      val b = m.discover07Permutation(3, 4, 719)
      eqv(a.legacyPermutation, Vector(1, 2, 3, 4, 6, 5), "Prima invocazione")
      eqv(b.legacyPermutation, Vector(6, 5, 4, 3, 2, 1), "Seconda invocazione")
      eqv(a.requestedRank1, 1, "Snapshot rango")
      eqv(m.metricsSnapshot("discovery07.permutation.calls"), BigInt(2), "Metrica")
    }

    check("il validatore rifiuta un output mancante o falsificato") {
      val v = new BaseValidationManager
      val c = BaseMonsterContext(1, 2)
      c.phase = "DISCOVERY_07_PERMUTATION"
      c.status = "LEGACY_PERMUTATION_READY"
      c.permutationRankInput = Some(1)
      rejectState("Output assente") { v.requireDiscovery07Ready(c) }
      c.legacyPermutationOutput = Some(Vector(1, 2, 3, 4, 5, 6))
      rejectState("Traccia assente") { v.requireDiscovery07Ready(c) }
      c.branchTrace.appendAll(Seq("BOOT", "DISCOVERY_07_PERMUTATION"))
      rejectState("Output normativo contraffatto") { v.requireDiscovery07Ready(c) }
      c.legacyPermutationOutput = Some(Vector(1, 2, 3, 4, 6, 5))
      v.requireDiscovery07Ready(c)
    }

    check("l'handler rifiuta bypass e doppio uso dello stesso contesto") {
      val handler = new Discovery07PermutationHandler(new BaseMetricsShell)
      val fresh = BaseMonsterContext(1, 2)
      fresh.permutationRankInput = Some(2)
      rejectState("Bootstrap assente") { handler.handle(fresh) }
      fresh.status = "BOOTSTRAPPED"
      fresh.branchTrace.append("BOOT")
      handler.handle(fresh)
      eqv(fresh.legacyPermutationOutput,
        Some(Vector(1, 2, 3, 5, 4, 6)), "Output storico")
      rejectState("Doppio uso") { handler.handle(fresh) }
    }

    check("tutte le sei patch precedenti restano percorribili") {
      val m = new BaseMonsterManager
      val F = NormativeOracle.FoundationDay
      val M = NormativeOracle.M
      eqv(m.patch01Save(0, 0, M).patchedOutput, M, "SAVE")
      eqv(m.patch02DayTag(F, F, F).patchedTag, BigInt(1), "DayTag")
      eqv(m.patch03Distance(F, F).patchedDistance, BigInt(1), "Distanza")
      eqv(m.patch04Stones(0, 0).patchedStoneRows, NormativeOracle.Stones, "Pietre")
      val hidden = Vector[BigInt](101, 202, 303, 404, 505, 606, 707)
      eqv(m.patch05Prior(0, 0, hidden, Vector.empty, 1, 7).patchedValue,
        BigInt(707), "Prior")
      eqv(m.patch06Grind(0, 0, 1, 7, 11, 13, 17,
        Vector[BigInt](19, 23, 29, 31, 37)).patchedValue, BigInt(422), "Macinatura")
    }

    check("oracolo isolato, nessuna patch futura e stadio 14 intenzionalmente RED") {
      val stream = Files.walk(root().resolve("src/main/scala"))
      val code = try stream.iterator().asScala
        .filter(p => Files.isRegularFile(p) && p.toString.endsWith(".scala"))
        .map(p => new String(Files.readAllBytes(p), StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!code.contains("NormativeOracle"), "Oracolo nei sorgenti di produzione")
      truth(code.contains("oldPermutationUnrank0"), "Cicatrice assente")
      truth(!code.contains("permutationPatch"), "PATCH 07 anticipata")
      truth(!code.contains("bowlAlias"), "Stadio futuro anticipato")
    }

    check("metadati discovery 07 dopo lo stadio 13 certificato") {
      val st = new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=14"), "Stadio")
      truth(st.contains("CURRENT_KIND=DISCOVERY"), "Tipo")
      truth(st.contains("CURRENT_PATCH=06"), "Ultima patch")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"), "RED atteso")
      truth(st.contains("STAGE_13_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_26_PASS_0_FAIL"),
        "Stage13 storico conservato")
      val completed = st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt)
        .getOrElse(throw new IllegalStateException("LAST_COMPLETED_STAGE assente"))
      truth(completed == 13 || completed == 14, "Nessuno stadio futuro certificato")
    }

    val m = new BaseMonsterManager
    Vector(("rango primo", 1), ("rango secondo", 2), ("rango settecentoventi", 720))
      .foreach { case (label, rank) =>
        check("equivalenza normativa permutazione " + label) {
          eqv(m.discover07Permutation(0, 0, rank).legacyPermutation,
            NormativeOracle.bowlOrderFromNumber(rank), "Errore di base del rango: " + label)
        }
      }

    println("\nRISULTATO STADIO 14: " + passed + " PASS, " + failed + " FAIL")
    if (failed != 0) sys.exit(1)
  }
}
