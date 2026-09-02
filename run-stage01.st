FileStream fileIn: 'src/PSTSourceLanguageCatalog.st'.
FileStream fileIn: 'src/PSTOrderedFamilies.st'.
FileStream fileIn: 'src/PSTNormativeOracle.st'.
FileStream fileIn: 'src/PSTMonsterBootstrap.st'.
FileStream fileIn: 'test/PSTStage01Fixtures.st'.
FileStream fileIn: 'test/PSTStage01Tests.st'.
FileStream fileIn: 'test/PSTStage01Finalizer.st'.
PSTStage01Tests runAll.
PSTStage01Finalizer markGreen.
