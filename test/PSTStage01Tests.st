Object subclass: #PSTStage01Tests
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Pastafarian-Stage01-Tests'!

!PSTStage01Tests class methodsFor: 'assertions'!
assert: condition message: message
    condition ifFalse: [ self error: message ].
    ^ true
!

assert: actual equals: expected message: message
    ^ self assert: actual = expected message: message
!

assertRaisesError: aBlock message: message
    | raised |
    raised := false.
    [ aBlock value ] on: Error do: [ :error | raised := true ].
    ^ self assert: raised message: message
!
! !

!PSTStage01Tests class methodsFor: 'tests'!
testCatalog
    self assert: PSTSourceLanguageCatalog validate message: 'ماخذ زبان کا کیٹلاگ درست نہیں ہے'.
    self assert: PSTSourceLanguageCatalog cutletNames size equals: 17 message: 'کٹلیٹ ناموں کی تعداد غلط ہے'.
    self assert: PSTSourceLanguageCatalog monthNames size equals: 47 message: 'مہینوں کے ناموں کی تعداد غلط ہے'.
    self assert: (PSTSourceLanguageCatalog cutletNameAtCanonicalIndex: 12) equals: 'گندم' message: 'گندم کا کینونیکل اشاریہ بدل گیا ہے'.
    self assert: (PSTSourceLanguageCatalog monthNameAtCanonicalIndex: 15) equals: 'خرنوب' message: 'خرنوب کا کینونیکل اشاریہ بدل گیا ہے'.
    self assert: (PSTSourceLanguageCatalog monthNameAtCanonicalIndex: 47) equals: 'ریت' message: 'آخری مہینے کا کینونیکل اشاریہ بدل گیا ہے'.
!

testArbitraryPrecisionAndSave
    | oracle m |
    oracle := PSTNormativeOracle new.
    m := PSTStage01Fixtures m.
    self assert: PSTNormativeOracle m equals: m message: 'بڑے شمار کا مستقل غلط ہے'.
    self assert: ((m * m) > m) message: 'عدد صحیح کی درست بڑی گنجائش دستیاب نہیں ہے'.
    PSTStage01Fixtures saveInputsAndExpected do: [ :pair |
        self assert: (oracle save: (pair at: 1)) equals: (pair at: 2) message: 'SAVE کی قدر متوقع نتیجے سے مختلف ہے' ].
!

testDayCounts
    | oracle |
    oracle := PSTNormativeOracle new.
    PSTStage01Fixtures dayCountFixtures do: [ :pair |
        self assert: (oracle dayCount: (pair at: 1)) equals: (pair at: 2) message: 'دن کا شمار غلط ہے' ].
!

testWorkCounts
    | oracle f a b c |
    oracle := PSTNormativeOracle new.
    f := PSTStage01Fixtures foundationDay.
    a := oracle workCountsFor: f target: f.
    self assert: (a at: #distance) equals: 1 message: 'ایک ہی دن کا فاصلہ ایک ہونا چاہیے'.
    self assert: (a at: #direction) equals: 2 message: 'ایک ہی دن کی سمت دو ہونی چاہیے'.
    b := oracle workCountsFor: f target: f + 1.
    self assert: (b at: #target) equals: 3 message: 'بنیاد کے بعد دن کا شمار غلط ہے'.
    self assert: (b at: #distance) equals: 2 message: 'آگے ایک دن کے فاصلے کا شمار غلط ہے'.
    self assert: (b at: #connection) equals: 4 message: 'ربط کا شمار غلط ہے'.
    self assert: (b at: #direction) equals: 3 message: 'آگے کی سمت غلط ہے'.
    c := oracle workCountsFor: f + 1 target: f - 1.
    self assert: (c at: #distance) equals: 3 message: 'بنیاد پار فاصلے کا شمار غلط ہے'.
    self assert: (c at: #direction) equals: 1 message: 'پیچھے کی سمت غلط ہے'.
!

testStoneSnapshotRule
    | oracle table |
    oracle := PSTNormativeOracle new.
    table := oracle buildStones.
    self assert: (table at: 1) equals: #(17 29 43 71 101) message: 'پہلی پتھر قطار غلط ہے'.
    self assert: (table at: 2) equals: PSTStage01Fixtures stoneRowTwo message: 'دوسری پتھر قطار ایک ہی پرانے عکس سے نہیں بنی'.
    self assert: table size equals: 46 message: 'پتھر جدول میں چھیالیس قطاریں لازم ہیں'.
!

testPermutationUnranking
    | oracle |
    oracle := PSTNormativeOracle new.
    self assert: (oracle bowlOrderFromNumber: 1) equals: PSTStage01Fixtures permutationFirst message: 'پہلی لغوی ترتیب غلط ہے'.
    self assert: (oracle bowlOrderFromNumber: 720) equals: PSTStage01Fixtures permutationLast message: 'سات سو بیسویں لغوی ترتیب غلط ہے'.
    self assert: (oracle bowlOrderFromDrop: 720) equals: PSTStage01Fixtures permutationLast message: '720 کی ضرب پر ترتیب غلط ہے'.
!

testShortSelection
    | oracle m stream |
    oracle := PSTNormativeOracle new.
    m := PSTStage01Fixtures m.
    self assert: (oracle chooseRankShort: #(123 1) n: 1) equals: 1 message: 'ایک رکنی انتخاب غلط ہے'.
    self assert: (oracle chooseRankShort: #(123 1) n: m) equals: 123 message: 'M رکنی انتخاب غلط ہے'.
    stream := Array with: m with: -1.
    self assert: (oracle chooseRankShort: stream n: 10) equals: 10 message: 'مختصر rejection اسی جواب حلقے میں درست نہیں چلا'.
!

testWideSelection
    | oracle m n |
    oracle := PSTNormativeOracle new.
    m := PSTStage01Fixtures m.
    n := m + 1.
    self assert: (oracle chooseRankWide: #(1 1) n: n) equals: n message: 'وسیع انتخاب M+1 پر غلط ہے'.
!

testBoundedCompositionFamily
    | family expected |
    family := PSTBoundedCompositionCounter total: 10 slots: 2 lo: 4 hi: 6.
    expected := PSTStage01Fixtures boundedCompositionsTenTwo.
    self assert: family count equals: expected size message: 'محدود ترکیبات کی گنتی غلط ہے'.
    1 to: expected size do: [ :i |
        self assert: (family unrank1: i) equals: (expected at: i) message: 'محدود ترکیب کا لغوی unrank غلط ہے' ].
!

testCutletPartitionBoundary
    | family expected |
    family := PSTCutletPartitionCounter total: 6 slots: 3 requiredBoundary: 2.
    expected := PSTStage01Fixtures cutletPartitionsSixThreeBoundaryTwo.
    self assert: family count equals: expected size message: 'داخلی دروازے والی کٹلیٹ تقسیم کی گنتی غلط ہے'.
    1 to: expected size do: [ :i |
        self assert: (family unrank1: i) equals: (expected at: i) message: 'کٹلیٹ تقسیم کا لغوی unrank غلط ہے' ].
!

testDistinctNameRanks
    | oracle expected |
    oracle := PSTNormativeOracle new.
    expected := PSTStage01Fixtures distinctThreeTakeTwo.
    1 to: expected size do: [ :i |
        self assert: (oracle unrankDistinctIndicesMasterSize: 3 take: 2 rank: i) equals: (expected at: i) message: 'منفرد ناموں کا unrank غلط ہے' ].
!

testWeavingSmallSpace
    | family expected |
    family := PSTWeavingCounter lengths: #(2 2).
    expected := PSTStage01Fixtures weavingsTwoTwo.
    self assert: family count equals: expected size message: 'چھوٹی بُنائی کی مکمل گنتی غلط ہے'.
    1 to: expected size do: [ :i |
        self assert: (family unrank1: i) equals: (expected at: i) message: 'بُنائی کا لغوی unrank غلط ہے' ].
    family := PSTWeavingCounter lengths: #(1 1 1).
    self assert: family count equals: 1 message: 'ایک ایک دھاگے کی بُنائی واحد ہونی چاہیے'.
    self assert: (family unrank1: 1) equals: #(1 2 3) message: 'ایک ایک دھاگے کی بُنائی غلط ہے'.
!

testSauceDeterminismAndBounds
    | oracle f a b bowls order m |
    oracle := PSTNormativeOracle new.
    f := PSTStage01Fixtures foundationDay.
    a := oracle sauceFor: f target: f.
    b := oracle sauceFor: f target: f.
    self assert: a equals: b message: 'ایک ہی input پر رَس کا نتیجہ بدل گیا'.
    bowls := a at: #bowls.
    order := a at: #orderAtDrop46.
    m := PSTStage01Fixtures m.
    self assert: bowls size equals: 6 message: 'آخری پیالوں کی تعداد چھ نہیں ہے'.
    bowls do: [ :value | self assert: (value between: 1 and: m) message: 'پیالے کی قدر محفوظ حد سے باہر ہے' ].
    self assert: order size equals: 6 message: '46ویں قطرے کی ترتیب میں چھ پیالے لازم ہیں'.
    self assert: order asSet size equals: 6 message: '46ویں قطرے کی ترتیب permutation نہیں ہے'.
!

testGateGapRangeAndDirectionIndependence
    | oracle positive negative |
    oracle := PSTNormativeOracle new.
    positive := oracle positiveGateGap: 1.
    negative := oracle negativeGateGap: 1.
    self assert: (positive between: 42 and: 963) message: 'مثبت دروازہ فاصلہ حد سے باہر ہے'.
    self assert: (negative between: 42 and: 963) message: 'منفی دروازہ فاصلہ حد سے باہر ہے'.
    self assert: positive equals: (oracle positiveGateGap: 1) message: 'مثبت دروازہ فاصلہ deterministic نہیں ہے'.
    self assert: negative equals: (oracle negativeGateGap: 1) message: 'منفی دروازہ فاصلہ deterministic نہیں ہے'.
!

testBootstrapMonsterInfrastructure
    | manager a b metrics |
    manager := PSTMonsterManager new.
    a := manager bootstrapCalculationDay: 10 targetDay: 20.
    b := manager bootstrapCalculationDay: 10 targetDay: 20.
    self assert: a status equals: #READY message: 'بنیادی monster context تیار نہیں ہوا'.
    self assert: b status equals: #READY message: 'دوسرا بنیادی monster context تیار نہیں ہوا'.
    self assert: a ~~ b message: 'دو invocations نے ایک context بانٹ لیا'.
    self assert: a semanticState ~~ b semanticState message: 'دو invocations نے semantic state بانٹ لی'.
    metrics := manager metricsSnapshot.
    self assert: (metrics at: #bootstrapCompleted) equals: 2 message: 'غیر معنوی metrics گنتی غلط ہے'.
    self assertRaisesError: [ manager bootstrapCalculationDay: 1.5 targetDay: 2 ] message: 'غیر صحیح دن کو validator نے رد نہیں کیا'.
!
! !

!PSTStage01Tests class methodsFor: 'running'!
testSelectors
    ^ #(
        testCatalog
        testArbitraryPrecisionAndSave
        testDayCounts
        testWorkCounts
        testStoneSnapshotRule
        testPermutationUnranking
        testShortSelection
        testWideSelection
        testBoundedCompositionFamily
        testCutletPartitionBoundary
        testDistinctNameRanks
        testWeavingSmallSpace
        testSauceDeterminismAndBounds
        testGateGapRangeAndDirectionIndependence
        testBootstrapMonsterInfrastructure
    )
!

runAll
    | passed failed lines root |
    passed := 0.
    failed := OrderedCollection new.
    lines := OrderedCollection new.
    self testSelectors do: [ :selector |
        [
            self perform: selector.
            passed := passed + 1.
            lines add: selector asString , ': PASS'
        ] on: Error do: [ :error |
            failed add: selector -> error messageText.
            lines add: selector asString , ': FAIL - ' , error messageText ] ].
    lines add: 'کل آزمائشیں: ' , self testSelectors size asString.
    lines add: 'کامیاب: ' , passed asString.
    lines add: 'ناکام: ' , failed size asString.
    root := FileSystem disk workingDirectory.
    (root / 'STAGE_01_EXECUTION_LOG.txt') writeStreamDo: [ :stream |
        lines do: [ :line | stream nextPutAll: line; lf ] ].
    failed isEmpty ifFalse: [ self error: 'Stage 1 کی آزمائشوں میں ناکامی ہوئی؛ execution log دیکھیں' ].
    ^ true
!
! !

!PSTStage01Tests class methodsFor: 'audit'!
testBootstrapSourceIsolation
    | root source forbidden |
    root := FileSystem disk workingDirectory.
    source := (root / 'src/PSTMonsterBootstrap.st') readStreamDo: [ :stream | stream contents ].
    forbidden := #(
        'PSTNormativeOracle'
        'oldRemainder'
        'oldDayTag'
        'oldDistance'
        'mutateStonesWrong'
        'bowlAlias'
        'orderAt46Latch'
        'biasedLegacyPick'
        'LEGACY_YEAR_MAX'
        'oldJumpGuess'
        'ghost'
        'VirtualLegacyList'
        'oldContiguousMonthDayGuess'
    ).
    forbidden do: [ :token |
        self assert: (source includesSubstring: token) not message: 'Stage 1 میں مستقبل کا legacy یا patch code موجود ہے' ].
!

testNoHebrewCodepointsInAuthoredProjectFiles
    | root paths content |
    root := FileSystem disk workingDirectory.
    paths := #(
        'README.md'
        'DEVELOPMENT_STAGE.md'
        'SPAGHETTI_DEVELOPMENT_HISTORY.md'
        'docs/SOURCE_LANGUAGE_CATALOG.md'
        'docs/ARCHITECTURE.md'
        'src/PSTSourceLanguageCatalog.st'
        'src/PSTOrderedFamilies.st'
        'src/PSTNormativeOracle.st'
        'src/PSTMonsterBootstrap.st'
        'test/PSTStage01Fixtures.st'
        'test/PSTStage01Tests.st'
        'test/PSTStage01Finalizer.st'
        'handoff/STAGE_01_HANDOFF_UR.md'
    ).
    paths do: [ :path |
        content := (root / path) readStreamDo: [ :stream | stream contents ].
        content do: [ :character |
            self assert: ((character codePoint between: 16r0590 and: 16r05FF) not)
                message: 'انسانی متن والی project file میں عبرانی code point ملا' ] ].
!
! !

!PSTStage01Tests class methodsFor: 'running'!
testSelectors
    ^ #(
        testCatalog
        testArbitraryPrecisionAndSave
        testDayCounts
        testWorkCounts
        testStoneSnapshotRule
        testPermutationUnranking
        testShortSelection
        testWideSelection
        testBoundedCompositionFamily
        testCutletPartitionBoundary
        testDistinctNameRanks
        testWeavingSmallSpace
        testSauceDeterminismAndBounds
        testGateGapRangeAndDirectionIndependence
        testBootstrapMonsterInfrastructure
        testBootstrapSourceIsolation
        testNoHebrewCodepointsInAuthoredProjectFiles
    )
!
! !

!PSTStage01Tests class methodsFor: 'audit'!
testBootstrapSourceIsolation
    | source forbidden |
    source := 'src/PSTMonsterBootstrap.st' asFileReference readStreamDo: [ :stream | stream contents ].
    forbidden := #(
        'PSTNormativeOracle'
        'oldRemainder'
        'oldDayTag'
        'oldDistance'
        'mutateStonesWrong'
        'bowlAlias'
        'orderAt46Latch'
        'biasedLegacyPick'
        'LEGACY_YEAR_MAX'
        'oldJumpGuess'
        'ghost'
        'VirtualLegacyList'
        'oldContiguousMonthDayGuess'
    ).
    forbidden do: [ :token |
        self assert: (source includesSubstring: token) not message: 'Stage 1 میں مستقبل کا legacy یا patch code موجود ہے' ].
!

testNoHebrewCodepointsInAuthoredProjectFiles
    | paths content |
    paths := #(
        'README.md'
        'DEVELOPMENT_STAGE.md'
        'SPAGHETTI_DEVELOPMENT_HISTORY.md'
        'docs/SOURCE_LANGUAGE_CATALOG.md'
        'docs/ARCHITECTURE.md'
        'src/PSTSourceLanguageCatalog.st'
        'src/PSTOrderedFamilies.st'
        'src/PSTNormativeOracle.st'
        'src/PSTMonsterBootstrap.st'
        'test/PSTStage01Fixtures.st'
        'test/PSTStage01Tests.st'
        'test/PSTStage01Finalizer.st'
        'handoff/STAGE_01_HANDOFF_UR.md'
    ).
    paths do: [ :path |
        content := path asFileReference readStreamDo: [ :stream | stream contents ].
        content do: [ :character |
            self assert: ((character codePoint between: 16r0590 and: 16r05FF) not)
                message: 'انسانی متن والی project file میں عبرانی code point ملا' ] ].
!
! !
