import sys.FileSystem;
import sys.io.File;
import pastafari.math.BigInt;
import pastafari.catalog.SourceLanguageCatalog;
import pastafari.oracle.NormativeReference;
import pastafari.oracle.NormativeReference.AnswerStream;
import pastafari.oracle.NormativeReference.BoundedCompositionFamily;
import pastafari.oracle.NormativeReference.WeavingCounter;
import pastafari.monster.CalendarDateSpaghetti;

class Stage1Tests {
    private static function fail(message:String):Void {
        throw message;
    }

    private static function assertTrue(condition:Bool, message:String):Void {
        if (!condition) fail(message);
    }

    private static function assertString(expected:String, actual:String, message:String):Void {
        if (expected != actual) fail(message + ": väntat=" + expected + ", faktiskt=" + actual);
    }

    private static function assertInt(expected:Int, actual:Int, message:String):Void {
        if (expected != actual) fail(message + ": väntat=" + expected + ", faktiskt=" + actual);
    }

    private static function assertBig(expected:String, actual:BigInt, message:String):Void {
        assertString(expected, actual.toString(), message);
    }

    private static function assertIntArray(expected:Array<Int>, actual:Array<Int>, message:String):Void {
        assertInt(expected.length, actual.length, message + " längd");
        var i = 0;
        while (i < expected.length) {
            assertInt(expected[i], actual[i], message + " position " + i);
            i++;
        }
    }

    private static function testBigInt():Void {
        var m = NormativeReference.M;
        assertBig("170141183460469231731687303715884105727", m, "M");
        assertBig("340282366920938463463374607431768211454", BigInt.mulInt(m, 2), "dubbel M");
        assertBig("9", BigInt.modEuclid(BigInt.fromInt(-1), BigInt.fromInt(10)), "euklidisk rest");
        assertBig("-1", BigInt.floorDiv(BigInt.fromInt(-1), BigInt.fromInt(10)), "golvdivision");
        assertBig("123456789012345678901234567890", BigInt.mul(BigInt.fromString("123456789012345"), BigInt.fromString("1000000000000001")), "stor multiplikation");
    }

    private static function testSaveAndCounts():Void {
        var m = NormativeReference.M;
        assertBig(m.toString(), NormativeReference.save(m), "SAVE M");
        assertBig(m.toString(), NormativeReference.save(BigInt.mulInt(m, 2)), "SAVE 2M");
        assertBig("1", NormativeReference.save(BigInt.add(m, BigInt.one())), "SAVE M+1");
        assertBig("1", NormativeReference.dayCount(NormativeReference.FOUNDATION_DAY), "grunddagen");
        assertBig("3", NormativeReference.dayCount(BigInt.add(NormativeReference.FOUNDATION_DAY, BigInt.one())), "dagen efter grunden");
        assertBig("2", NormativeReference.dayCount(BigInt.sub(NormativeReference.FOUNDATION_DAY, BigInt.one())), "dagen före grunden");
        var counts = NormativeReference.workCounts(NormativeReference.FOUNDATION_DAY, NormativeReference.FOUNDATION_DAY);
        assertBig("1", counts.distance, "avstånd samma dag");
        assertInt(2, counts.direction, "riktning samma dag");
    }

    private static function testStonesAndOrders():Void {
        var stones = NormativeReference.buildStones();
        assertInt(46, stones.length, "antal stenrader");
        var second = stones[1];
        assertBig("378", second.wheat, "sten 2 vete");
        assertBig("1073", second.barley, "sten 2 korn");
        assertBig("2375", second.salt, "sten 2 salt");
        assertBig("6195", second.bitter, "sten 2 bitter");
        assertBig("10493", second.red, "sten 2 röd");
        assertIntArray([1,2,3,4,5,6], NormativeReference.permutationUnrank1(1), "första skålordningen");
        assertIntArray([6,5,4,3,2,1], NormativeReference.permutationUnrank1(720), "sista skålordningen");
    }

    private static function testSelections():Void {
        var stream = new AnswerStream(NormativeReference.M, 1);
        assertBig("1", NormativeReference.chooseRankShort(stream, BigInt.one()), "kort val N=1");
        assertBig(NormativeReference.M.toString(), NormativeReference.chooseRankShort(stream, NormativeReference.M), "kort val N=M");
        var wideN = BigInt.add(NormativeReference.M, BigInt.one());
        var wideStream = new AnswerStream(BigInt.one(), 1);
        assertBig(wideN.toString(), NormativeReference.chooseRankWide(wideStream, wideN), "brett val N=M+1");
    }

    private static function testFamilies():Void {
        assertBig("60", NormativeReference.fallingFactorial(5, 3), "fallande fakultet");
        assertIntArray([1,2,3], NormativeReference.unrankDistinctIndices(5, 3, BigInt.one()), "första distinkta namnrad");
        assertIntArray([5,4,3], NormativeReference.unrankDistinctIndices(5, 3, BigInt.fromInt(60)), "sista distinkta namnrad");
        var bounded = new BoundedCompositionFamily(5, 2, 1, 4);
        assertBig("4", bounded.count(), "antal bundna kompositioner");
        assertIntArray([1,4], bounded.unrank1(BigInt.one()), "första bundna komposition");
        assertIntArray([4,1], bounded.unrank1(BigInt.fromInt(4)), "sista bundna komposition");
        var weaving = new WeavingCounter([2,2]);
        assertBig("2", weaving.count(), "antal små vävningar");
        assertIntArray([1,1,2,2], weaving.unrank1(BigInt.one()), "första lilla vävning");
        assertIntArray([1,2,1,2], weaving.unrank1(BigInt.fromInt(2)), "andra lilla vävning");
    }

    private static function testCatalog():Void {
        assertInt(17, SourceLanguageCatalog.cutletCount(), "antal kotlettnamn");
        assertInt(47, SourceLanguageCatalog.monthCount(), "antal månadsnamn");
        assertString("vete", SourceLanguageCatalog.cutlet(12).text, "översättning av vete");
        assertString("Akkad", SourceLanguageCatalog.cutlet(15).text, "translitterering av Akkad");
        assertString("tandkräm", SourceLanguageCatalog.month(6).text, "översättning av tandkräm");
        assertString("salt", SourceLanguageCatalog.month(44).text, "översättning av salt");
        var seenCutlets = new Map<Int,Bool>();
        for (entry in SourceLanguageCatalog.allCutlets()) {
            assertTrue(!seenCutlets.exists(entry.canonicalIndex), "duplicerat kotlettindex");
            seenCutlets.set(entry.canonicalIndex, true);
        }
        var seenMonths = new Map<Int,Bool>();
        for (entry in SourceLanguageCatalog.allMonths()) {
            assertTrue(!seenMonths.exists(entry.canonicalIndex), "duplicerat månadsindex");
            seenMonths.set(entry.canonicalIndex, true);
        }
    }

    private static function testNeutralMonsterShell():Void {
        var c = BigInt.fromInt(100);
        var t = BigInt.fromInt(200);
        var ctx = CalendarDateSpaghetti.bootstrapContext(c, t);
        assertString("100", ctx.calculationDay.toString(), "kontextens beräkningsdag");
        assertString("200", ctx.targetDay.toString(), "kontextens måldag");
        assertString("BOOTSTRAP_READY", ctx.phase, "neutral fas");
        assertString("SKELETON_READY", ctx.status, "neutral status");
        assertTrue(ctx.metrics.get("bootstrap.calls") == 1, "anropsmätare");
        assertTrue(ctx.metrics.get("bootstrap.success") == 1, "framgångsmätare");
    }

    private static function testSauceDeterminism():Void {
        var oracle = new NormativeReference();
        var first = oracle.sauce(NormativeReference.FOUNDATION_DAY, NormativeReference.FOUNDATION_DAY);
        var second = oracle.sauce(NormativeReference.FOUNDATION_DAY, NormativeReference.FOUNDATION_DAY);
        assertInt(6, first.bowls.length, "antal slutskålar");
        assertInt(6, first.orderAtDrop46.length, "ordningslängd vid droppe 46");
        var i = 0;
        while (i < 6) {
            assertString(first.bowls[i].toString(), second.bowls[i].toString(), "deterministisk sås skål " + i);
            assertInt(first.orderAtDrop46[i], second.orderAtDrop46[i], "deterministisk såsordning " + i);
            i++;
        }
    }

    private static function collectFiles(path:String, out:Array<String>):Void {
        for (name in FileSystem.readDirectory(path)) {
            var full = path + "/" + name;
            if (FileSystem.isDirectory(full)) collectFiles(full, out); else out.push(full);
        }
    }

    private static function containsHebrew(text:String):Bool {
        var i = 0;
        while (i < text.length) {
            var c = text.charCodeAt(i);
            if (c != null && c >= 0x0590 && c <= 0x05FF) return true;
            i++;
        }
        return false;
    }

    private static function testStageAudit():Void {
        var cwd = Sys.getCwd();
        var files = new Array<String>();
        collectFiles(cwd + "src", files);
        collectFiles(cwd + "test", files);
        files.push(cwd + "README.md");
        files.push(cwd + "SOURCE_LANGUAGE_CATALOG.md");
        files.push(cwd + "ARCHITECTURE.md");
        files.push(cwd + "DECISION_1A.md");
        files.push(cwd + "SPAGHETTI_DEVELOPMENT_HISTORY.md");
        files.push(cwd + "DEVELOPMENT_STAGE.md");
        files.push(cwd + "HANDOFF.md");
        for (path in files) {
            var text = File.getContent(path);
            assertTrue(!containsHebrew(text), "hebreisk text hittades i " + path);
        }
        var monsterFiles = new Array<String>();
        collectFiles(cwd + "src/pastafari/monster", monsterFiles);
        var forbidden = [
            "oldRemainder", "savePatch", "oldDayTag", "oldDistance", "mutateStonesWrong",
            "hiddenBackward", "orderAt46Latch", "biasedLegacyPick", "wideDetour",
            "oldGateQuestionDay", "LEGACY_YEAR_MAX", "REAL_YEAR_MAX_PATCH", "oldJumpGuess",
            "LEGACY_STRUCTURE_CACHE", "oldStructureSauce", "legacyPositiveCompositions",
            "legacyNameRowWithRepeats", "VirtualLegacyList", "legacyChooseEachDaySeparately",
            "oldContiguousMonthDayGuess", "useLegacyRemainder", "useGhostWeaveCandidate"
        ];
        for (path in monsterFiles) {
            var text = File.getContent(path);
            for (token in forbidden) {
                assertTrue(text.indexOf(token) < 0, "framtida korrigeringskod hittades i produktionsskelettet: " + token);
            }
        }
        var stage = File.getContent(cwd + "DEVELOPMENT_STAGE.md");
        assertTrue(stage.indexOf("CURRENT_STAGE=1") >= 0, "fel aktuellt steg");
        assertTrue(stage.indexOf("CURRENT_KIND=BOOTSTRAP") >= 0, "fel stegtyp");
        assertTrue(stage.indexOf("PROGRAMMING_LANGUAGE=Haxe") >= 0, "fel programmeringsspråk");
        assertTrue(stage.indexOf("NATURAL_LANGUAGE=svenska") >= 0, "fel källspråk");
        assertTrue(stage.indexOf("SOURCE_LANGUAGE_CATALOG_FROZEN=YES") >= 0, "katalogen är inte markerad som fryst");
        assertTrue(stage.indexOf("CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO") >= 0, "otillåten korsimplementationsanvändning");
    }

    public static function main():Void {
        testBigInt();
        testSaveAndCounts();
        testStonesAndOrders();
        testSelections();
        testFamilies();
        testCatalog();
        testNeutralMonsterShell();
        testSauceDeterminism();
        Sys.println("STAGE_01_PASS");
        testStageAudit();
        Sys.println("STAGE_01_AUDIT_PASS");
    }
}
