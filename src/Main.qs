namespace Pastafari.Main {
    import Std.Diagnostics.Fact;

    @EntryPoint()
    operation Main() : Unit {
        Pastafari.Tests.TestExactArithmetic();
        Pastafari.Tests.TestSourceLanguageCatalog();
        Pastafari.Tests.TestNeutralMonsterInfrastructure();
        Pastafari.Tests.TestCoreAndOracleHelpers();
        Pastafari.Tests.TestPermutationAndSelection();
        Pastafari.Tests.TestOrderedFamiliesSmallFixtures();
        Pastafari.Tests.TestWeavingSmallFixtures();
        Pastafari.Tests.TestSauceLocalDifferential();
        Fact(true, "Stage 1 の Q# テストが完了しました。");
    }
}
