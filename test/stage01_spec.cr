require "spec"
require "big"
require "../src/pastafarian_calendar"
require "./normative_scroll"
require "./bootstrap_fixtures"

describe "બુટસ્ટ્રેપ તબક્કો" do
  it "સ્ત્રોત ભાષાનું સ્થિર સૂચિકાક્રમ જાળવે છે" do
    PastafarianCalendar::SourceLanguageCatalog::VERSION.should eq("1.0.0")
    PastafarianCalendar::SourceLanguageCatalog::LANGUAGE.should eq("ગુજરાતી")
    PastafarianCalendar::SourceLanguageCatalog::FROZEN.should be_true
    PastafarianCalendar::SourceLanguageCatalog::CUTLETS.size.should eq(17)
    PastafarianCalendar::SourceLanguageCatalog::MONTHS.size.should eq(47)
    PastafarianCalendar::SourceLanguageCatalog::CUTLETS.map(&.canonical_index).to_a.should eq((1..17).to_a)
    PastafarianCalendar::SourceLanguageCatalog::MONTHS.map(&.canonical_index).to_a.should eq((1..47).to_a)
    PastafarianCalendar::SourceLanguageCatalog.cutlet(12).should eq("ઘઉં")
    PastafarianCalendar::SourceLanguageCatalog.month(44).should eq("મીઠું")
  end

  it "સાચવેલી શેષ ક્રિયા ચોક્કસ રીતે ગણે છે" do
    m = Stage01Fixtures::M
    NormativeScroll::M.should eq(m)
    NormativeScroll.save(BigInt.new(1)).should eq(BigInt.new(1))
    NormativeScroll.save(m - 1).should eq(m - 1)
    NormativeScroll.save(m).should eq(m)
    NormativeScroll.save(m + 1).should eq(BigInt.new(1))
    NormativeScroll.save(m * 2).should eq(m)
  end

  it "સ્થાપના દિવસની ગણતરી અને દિશા યોગ્ય રાખે છે" do
    f = NormativeScroll::FOUNDATION_DAY
    f.should eq(Stage01Fixtures::FOUNDATION_DAY)
    NormativeScroll::TABLETS_DAY.should eq(Stage01Fixtures::TABLETS_DAY)
    (NormativeScroll::TABLETS_DAY - f).should eq(Stage01Fixtures::TABLETS_FROM_FOUNDATION)
    NormativeScroll.day_count(f).should eq(BigInt.new(1))
    NormativeScroll.day_count(f + 1).should eq(BigInt.new(3))
    NormativeScroll.day_count(f - 1).should eq(BigInt.new(2))
    counts = NormativeScroll.work_counts(f, f)
    counts.action.should eq(BigInt.new(1))
    counts.target.should eq(BigInt.new(1))
    counts.distance.should eq(BigInt.new(1))
    counts.connection.should eq(BigInt.new(2))
    counts.direction.should eq(BigInt.new(2))
  end

  it "પાંચેય નવી પથ્થર મૂલ્યો એક જ જૂના સ્નેપશોટ પરથી ગણે છે" do
    second = NormativeScroll.build_stones[1]
    second.should eq(Stage01Fixtures::STONE_ROW_2.to_a)
  end

  it "દરેક બોલાવટ માટે અવલોકન અને માન્યતા-તપાસની સ્થિતિ અલગ રાખે છે" do
    first = PastafarianCalendar.bootstrap_context(BigInt.new(11), BigInt.new(-9))
    second = PastafarianCalendar.bootstrap_context(BigInt.new(11), BigInt.new(-9))

    first.metrics.bump("isolation.probe")
    first.logs.append("ISOLATION_PROBE")
    first.validation_failures << "E_TEST_ONLY"
    first.phase = "MUTATED_TEST_ONLY"

    second.metrics.counters.has_key?("isolation.probe").should be_false
    second.logs.events.includes?("ISOLATION_PROBE").should be_false
    second.validation_failures.should be_empty
    second.phase.should eq("BOOTSTRAP_DISPATCH")
    second.status.should eq("READY_FOR_HISTORICAL_GROWTH")
  end

  it "નોર્મેટિવ પથ્થર કોષ્ટક બોલાવટો વચ્ચે બદલાય શકે એવો સંદર્ભ વહેંચતો નથી" do
    first = NormativeScroll.build_stones
    second = NormativeScroll.build_stones
    first[0][0] = BigInt.new(999)

    second[0][0].should eq(BigInt.new(17))
    NormativeScroll.build_stones[0][0].should eq(BigInt.new(17))
  end

  it "નોર્મેટિવ સંદર્ભના દ્વાર-નોંધણી નમૂનાઓ પરસ્પર અલગ રહે છે" do
    first = NormativeScroll::CalendarOracle.new
    second = NormativeScroll::CalendarOracle.new

    first.gates.ensure_gate_index(BigInt.new(1))

    first.gates.max_known_index.should eq(BigInt.new(1))
    second.gates.max_known_index.should eq(BigInt.new(0))
    second.gates.min_known_index.should eq(BigInt.new(0))
  end

  it "ક્રમવિન્યાસની એક આધારિત સરહદો સાચી ખોલે છે" do
    NormativeScroll.permutation_unrank1(BigInt.new(1), [1, 2, 3, 4, 5, 6]).should eq(Stage01Fixtures::FIRST_BOWL_ORDER.to_a)
    NormativeScroll.permutation_unrank1(BigInt.new(720), [1, 2, 3, 4, 5, 6]).should eq(Stage01Fixtures::LAST_BOWL_ORDER.to_a)
  end

  it "ટૂંકી અને પહોળી ક્રમ-પસંદગીની ફરજિયાત સરહદો જાળવે છે" do
    m = NormativeScroll::M
    forward = NormativeScroll::AnswerStream.new(BigInt.new(1), 1)
    backward_from_m = NormativeScroll::AnswerStream.new(m, -1)

    NormativeScroll.choose_rank_short(forward, BigInt.new(1)).should eq(BigInt.new(1))
    NormativeScroll.choose_rank_short(backward_from_m, m).should eq(m)
    NormativeScroll.choose_rank_short(backward_from_m, m - 1).should eq(m - 1)
    NormativeScroll.choose_rank_wide(forward, m + 1).should eq(m + 1)

    wide_rank = NormativeScroll.choose_rank_wide(forward, m * m + 1)
    (wide_rank >= 1).should be_true
    (wide_rank <= m * m + 1).should be_true
  end

  it "મર્યાદિત રચનાઓનો ચોક્કસ શબ્દકોશીય ક્રમ જાળવે છે" do
    family = NormativeScroll::BoundedCompositionFamily.new(8, 2, 3, 5)
    family.count.should eq(BigInt.new(3))
    family.unrank1(BigInt.new(1)).should eq(Stage01Fixtures::BOUNDED_8_2_3_5[0].to_a)
    family.unrank1(BigInt.new(2)).should eq(Stage01Fixtures::BOUNDED_8_2_3_5[1].to_a)
    family.unrank1(BigInt.new(3)).should eq(Stage01Fixtures::BOUNDED_8_2_3_5[2].to_a)
  end

  it "ગણતરી-દિવસના આંતરિક દ્વાર માટે કટલેટ વિભાજન કુટુંબને ચોક્કસ પૂર્વસંગ્રહ પર ગાળે છે" do
    all = NormativeScroll::CutletPartitionFamily.new(5, 2, nil)
    at_two = NormativeScroll::CutletPartitionFamily.new(5, 2, 2)
    at_three = NormativeScroll::CutletPartitionFamily.new(5, 2, 3)

    all.count.should eq(BigInt.new(4))
    at_two.count.should eq(BigInt.new(1))
    at_two.unrank1(BigInt.new(1)).should eq([2, 3])
    at_three.count.should eq(BigInt.new(1))
    at_three.unrank1(BigInt.new(1)).should eq([3, 2])
  end

  it "અલગ નામ સૂચકાંકો પુનરાવર્તન વગર ખોલે છે" do
    first = NormativeScroll.unrank_distinct_indices(5, 3, BigInt.new(1))
    first.should eq([1, 2, 3])
    first.uniq.size.should eq(3)
    NormativeScroll.falling_factorial(5, 3).should eq(BigInt.new(60))
  end

  it "નાની માસિક વણાટ કુટુંબને પૂર્ણ વણાટ તરીકે ગણે છે" do
    family = NormativeScroll::WeavingFamily.new([2, 2])
    family.count.should eq(BigInt.new(2))
    family.unrank1(BigInt.new(1)).should eq(Stage01Fixtures::WEAVINGS_2_2[0].to_a)
    family.unrank1(BigInt.new(2)).should eq(Stage01Fixtures::WEAVINGS_2_2[1].to_a)
  end

  it "વણાટ કુટુંબ બોલાવનારના બદલાય શકે એવા લંબાઈ અરેનો સંદર્ભ પોતાની પાસે રાખતું નથી" do
    lengths = [2, 2]
    family = NormativeScroll::WeavingFamily.new(lengths)
    lengths[0] = 9

    family.count.should eq(BigInt.new(2))
    family.unrank1(BigInt.new(1)).should eq([1, 1, 2, 2])
  end

  it "નિષ્પક્ષ મૂળ સંદર્ભ માત્ર અવલોકન ખોળ સાથે બનાવે છે" do
    context = PastafarianCalendar.bootstrap_context(BigInt.new(11), BigInt.new(-9))
    context.status.should eq("READY_FOR_HISTORICAL_GROWTH")
    context.phase.should eq("BOOTSTRAP_DISPATCH")
    context.metrics.counters["dispatcher.bootstrap"].should eq(BigInt.new(1))
    context.validation_failures.should be_empty
  end

  it "ઉત્પાદન માર્ગ હજી ભવિષ્યના ઐતિહાસિક તબક્કાઓ અમલમાં મૂકતો નથી" do
    expect_raises(PastafarianCalendar::MonsterNotReadyError, "E_STAGE01_PRODUCTION_SKELETON") do
      PastafarianCalendar.calendar_date_spaghetti(BigInt.new(1), BigInt.new(1))
    end
  end

  it "ઉત્પાદન સ્ત્રોત પરીક્ષણ સંદર્ભ-ગણકને સંદર્ભિત કરતો નથી" do
    source = File.read(File.expand_path("../src/pastafarian_calendar.cr", __DIR__))
    source.includes?("NormativeScroll").should be_false
    source.includes?("normative_scroll").should be_false
  end

  it "ઉત્પાદન અને પરીક્ષણ સ્ત્રોતમાં વહેંચાયેલા વર્ગ અથવા મૉડ્યુલ સ્તરના અર્થનિર્ધારક ચલ રાખતો નથી" do
    root = File.expand_path("..", __DIR__)
    files = Dir.glob(File.join(root, "src/**/*.cr")).sort
    files << File.join(root, "test/normative_scroll.cr")
    all_source = files.map { |path| File.read(path) }.join("\n")
    all_source.includes?("@@").should be_false
    all_source.includes?("class_property").should be_false
    all_source.includes?("class_getter").should be_false
    all_source.includes?("class_setter").should be_false
  end

  it "ભવિષ્યના ટુકડાઓના ઓળખચિહ્નો ઉત્પાદન સ્ત્રોતમાં હાજર નથી" do
    root = File.expand_path("../src", __DIR__)
    all_source = Dir.glob(File.join(root, "**/*.cr")).sort.map { |path| File.read(path) }.join("\n")
    forbidden = [
      "oldRemainder",
      "savePatch",
      "oldDayTag",
      "dayTagWithFoundationScar",
      "oldDistance",
      "mutateStonesWrong",
      "legacyHidden",
      "legacyPrior",
      "GRIND_TABLE_WITH_SENTINEL",
      "oldPermutationUnrank0",
      "bowlAlias",
      "vaultOld",
      "orderAt46Latch",
      "oldNextBowlFixedName",
      "biasedLegacyPick",
      "wideDetour",
      "oldGateQuestionDay",
      "LEGACY_YEAR_MAX",
      "REAL_YEAR_MAX_PATCH",
      "oldJumpGuess",
      "LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER",
      "oldStructureSauce",
      "legacyPositiveCompositions",
      "legacyNameRowWithRepeats",
      "VirtualLegacyList",
      "legacyChooseEachDaySeparately",
      "oldContiguousMonthDayGuess",
    ]
    forbidden.each { |token| all_source.includes?(token).should be_false }
  end
end
