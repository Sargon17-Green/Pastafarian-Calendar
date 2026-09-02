package pastafari

import pastafari.catalog.SourceLanguageCatalog
import pastafari.monster.BaseMonsterManager
import pastafari.BootstrapFixtures._
import pastafari.oracle.NormativeOracle
import pastafari.oracle.NormativeOracle._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path, Paths}
import scala.jdk.CollectionConverters._

object Stage01Tests {
  private var passed = 0
  private var failed = 0

  private def check(name: String)(body: => Unit): Unit = {
    try {
      body
      passed += 1
      println("PASS — " + name)
    } catch {
      case e: Throwable =>
        failed += 1
        println("FAIL — " + name + " — " + e.getMessage)
        e.printStackTrace(System.out)
    }
  }

  private def equal[A](actual: A, expected: A, label: String): Unit = {
    if (actual != expected) {
      throw new AssertionError(label + ": atteso=" + expected + ", ottenuto=" + actual)
    }
  }

  private def truth(value: Boolean, label: String): Unit = {
    if (!value) throw new AssertionError(label)
  }

  private def projectRoot(): Path = {
    var p = Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    var remaining = 8
    while (remaining > 0 && !Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent != null) {
      p = p.getParent
      remaining -= 1
    }
    if (!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))) {
      throw new IllegalStateException("Impossibile trovare la radice del progetto per l'audit statico.")
    }
    p
  }

  private def textFiles(root: Path): Vector[Path] = {
    val stream = Files.walk(root)
    try {
      stream.iterator().asScala
        .filter(p => Files.isRegularFile(p))
        .filter { p =>
          val n = p.getFileName.toString
          n.endsWith(".scala") || n.endsWith(".md") || n.endsWith(".sbt") || n.endsWith(".properties") || n.endsWith(".txt")
        }
        .toVector
    } finally stream.close()
  }

  private def read(path: Path): String =
    new String(Files.readAllBytes(path), StandardCharsets.UTF_8)

  def main(args: Array[String]): Unit = {
    check("costanti fondamentali") {
      equal(TabletsDay - FoundationDay, ExpectedFoundationDistance, "distanza tra Tavole e Fondazione")
      equal(M, (BigInt(1) << 127) - 1, "M")
      equal(YearMaxDays, 5778, "limite reale dell'anno")
    }

    check("SAVE e aritmetica modulare") {
      equal(save(BigInt(1)), BigInt(1), "SAVE(1)")
      equal(save(M - 1), M - 1, "SAVE(M-1)")
      equal(save(M), M, "SAVE(M)")
      equal(save(M + 1), BigInt(1), "SAVE(M+1)")
      equal(save(2 * M), M, "SAVE(2M)")
      equal(save(BigInt(0)), M, "SAVE(0)")
      equal(save(BigInt(-1)), M - 1, "SAVE(-1)")
    }

    check("conteggio dei giorni e contatori di lavoro") {
      equal(dayCount(FoundationDay), BigInt(1), "giorno di Fondazione")
      equal(dayCount(FoundationDay - 1), BigInt(2), "giorno prima della Fondazione")
      equal(dayCount(FoundationDay + 1), BigInt(3), "giorno dopo la Fondazione")
      equal(workCounts(FoundationDay, FoundationDay), WorkCounts(1, 1, 1, 2, 2), "contatori sullo stesso giorno")
      equal(workCounts(FoundationDay - 1, FoundationDay + 1), WorkCounts(2, 3, 3, 5, 3), "contatori attraverso la Fondazione")
    }

    check("prime due righe delle pietre") {
      equal(Stones.length, 46, "numero di righe")
      equal(Stones.head, ExpectedStoneRow1, "riga 1")
      equal(Stones(1), ExpectedStoneRow2, "riga 2")
    }

    check("apertura delle permutazioni delle ciotole") {
      equal(permutationUnrank1(1, Vector(1, 2, 3, 4, 5, 6)), ExpectedPermutationRank1, "rango 1")
      equal(permutationUnrank1(720, Vector(1, 2, 3, 4, 5, 6)), ExpectedPermutationRank720, "rango 720")
      equal(bowlOrderFromDrop(BigInt(720)), ExpectedPermutationRank720, "goccia multipla di 720")
    }

    check("selezione corta con rifiuto") {
      val n = BigInt(10)
      equal(chooseRankShort(AnswerStream(BigInt(1), 1), n), BigInt(1), "selezione immediata")
      equal(chooseRankShort(AnswerStream(M, 1), n), BigInt(1), "rifiuto di M e avanzamento sullo stesso anello")
    }

    check("selezione larga") {
      val n = M + 1
      equal(chooseRankWide(AnswerStream(BigInt(1), 1), n), n, "rango largo per N=M+1")
    }

    check("composizioni limitate in ordine lessicografico") {
      val family = new BoundedCompositionFamily(7, 2, 2, 5)
      equal(family.count(), BigInt(4), "conteggio")
      equal(family.unrank1(1), Vector(2, 5), "rango 1")
      equal(family.unrank1(2), Vector(3, 4), "rango 2")
      equal(family.unrank1(3), Vector(4, 3), "rango 3")
      equal(family.unrank1(4), Vector(5, 2), "rango 4")
    }

    check("partizione di cotolette con confine obbligatorio") {
      val family = new CutletPartitionFamily(6, 3, Some(3))
      equal(family.count(), BigInt(4), "conteggio filtrato")
      equal(family.unrank1(1), Vector(1, 2, 3), "rango 1")
      equal(family.unrank1(2), Vector(2, 1, 3), "rango 2")
      equal(family.unrank1(3), Vector(3, 1, 2), "rango 3")
      equal(family.unrank1(4), Vector(3, 2, 1), "rango 4")
    }

    check("nomi distinti per rango") {
      val expected = Vector(
        Vector(1, 2), Vector(1, 3), Vector(2, 1),
        Vector(2, 3), Vector(3, 1), Vector(3, 2)
      )
      val actual = (1 to 6).map(r => unrankDistinctIndices(3, 2, BigInt(r))).toVector
      equal(actual, expected, "permutazioni parziali")
    }

    check("tessitura normativa su uno spazio piccolo") {
      val family = new WeavingFamily(Vector(2, 2))
      equal(family.count(), BigInt(2), "conteggio delle tessiture")
      equal(family.unrank1(1), Vector(1, 1, 2, 2), "prima tessitura")
      equal(family.unrank1(2), Vector(1, 2, 1, 2), "seconda tessitura")
    }

    check("catalogo italiano congelato e indicizzato") {
      equal(SourceLanguageCatalog.Version, "1.0.0-stage01", "versione del catalogo")
      equal(SourceLanguageCatalog.Cutlets.length, 17, "numero di cotolette")
      equal(SourceLanguageCatalog.Months.length, 47, "numero di mesi")
      equal(SourceLanguageCatalog.Cutlets.map(_.canonicalIndex), (1 to 17).toVector, "indici delle cotolette")
      equal(SourceLanguageCatalog.Months.map(_.canonicalIndex), (1 to 47).toVector, "indici dei mesi")
      equal(SourceLanguageCatalog.Cutlets.map(_.italian).distinct.length, 17, "nomi di cotolette distinti")
      equal(SourceLanguageCatalog.Months.map(_.italian).distinct.length, 47, "nomi di mesi distinti")
      equal(SourceLanguageCatalog.cutlet(12).italian, "frumento", "traduzione di grano")
      equal(SourceLanguageCatalog.month(6).italian, "dentifricio", "traduzione di dentifricio")
      equal(SourceLanguageCatalog.month(28).italian, "Ninive", "toponimo Ninive")
    }

    check("riferimento del sugo deterministico") {
      val first = sauce(FoundationDay, FoundationDay)
      val second = sauce(FoundationDay, FoundationDay)
      equal(first, second, "due calcoli identici del sugo")
      equal(first.bowls.length, 6, "sei ciotole finali")
      equal(first.orderAtDrop46.sorted, Vector(1, 2, 3, 4, 5, 6), "ordine della goccia 46")
    }

    check("divari di cancello nell'intervallo normativo") {
      val engine = new GateEngine
      val positive = engine.positiveGateGap(1)
      val negative = engine.negativeGateGap(1)
      truth(positive >= GateGapMin && positive <= GateGapMax, "divario positivo fuori intervallo")
      truth(negative >= GateGapMin && negative <= GateGapMax, "divario negativo fuori intervallo")
    }

    check("contesto di produzione isolato per invocazione") {
      val manager = new BaseMonsterManager
      val first = manager.bootstrap(BigInt(10), BigInt(20))
      val second = manager.bootstrap(BigInt(10), BigInt(20))
      truth(first ne second, "due invocazioni non devono condividere il contesto")
      equal(first.status, "BOOTSTRAPPED", "stato della prima invocazione")
      equal(second.status, "BOOTSTRAPPED", "stato della seconda invocazione")
      first.branchTrace.append("SOLO_PRIMO")
      truth(!second.branchTrace.contains("SOLO_PRIMO"), "la traccia non deve trapelare tra invocazioni")
      equal(manager.metricsSnapshot.getOrElse("base.bootstrap.calls", BigInt(0)), BigInt(2), "metrica osservativa")
    }

    check("assenza di codice di patch futuro nel percorso di produzione") {
      val root = projectRoot()
      val mainRoot = root.resolve("src/main/scala")
      val content = textFiles(mainRoot).map(read).mkString("\n")
      val forbidden = Vector(
        "oldRemainder", "savePatch", "oldDayTag", "oldDistance", "mutateStonesWrong",
        "legacyPrior", "GRIND_TABLE_WITH_SENTINEL", "oldPermutationUnrank0", "bowlAlias",
        "vaultOld", "orderAt46Latch", "biasedLegacyPick", "LEGACY_YEAR_MAX",
        "oldJumpGuess", "VirtualLegacyList", "legacyChooseEachDaySeparately", "oldContiguousMonthDayGuess"
      )
      val present = forbidden.filter(content.contains)
      equal(present, Vector.empty[String], "simboli futuri trovati")
    }

    check("nessun carattere ebraico nel testo creato dal progetto") {
      val root = projectRoot()
      val offenders = textFiles(root).filter { p =>
        val text = read(p)
        text.exists(ch => ch >= '\u0590' && ch <= '\u05ff')
      }
      equal(offenders.map(_.toString), Vector.empty[String], "file con caratteri ebraici")
    }

    check("nessuna dipendenza esterna dichiarata") {
      val root = projectRoot()
      val build = read(root.resolve("build.sbt"))
      truth(!build.contains("libraryDependencies"), "Il Bootstrap non deve dichiarare dipendenze esterne.")
    }

    println("\nRISULTATO STADIO 1: " + passed + " PASS, " + failed + " FAIL")
    if (failed != 0) sys.exit(1)
  }
}
