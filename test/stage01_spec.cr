require "spec"
require "big"
require "../src/pastafarian_calendar"
require "./normative_scroll"

private def bi(value : Int64) : BigInt
  BigInt.new(value)
end

describe "બુટસ્ટ્રેપ તબક્કો" do
  it "સ્ત્રોત ભાષાનું સ્થિર સૂચિકાક્રમ જાળવે છે" do
    PastafarianCalendar::SourceLanguageCatalog::VERSION.should eq("1.0.0")
    PastafarianCalendar::SourceLanguageCatalog::LANGUAGE.should eq("ગુજરાતી")
    PastafarianCalendar::SourceLanguageCatalog::FROZEN.should be_true
    PastafarianCalendar::SourceLanguageCatalog::CUTLETS.size.should eq(17)
    PastafarianCalendar::SourceLanguageCatalog::MONTHS.size.should eq(47)
    PastafarianCalendar::SourceLanguageCatalog::CUTLETS.map(&.canonical_index).should eq((1..17).to_a)
    PastafarianCalendar::SourceLanguageCatalog::MONTHS.map(&.canonical_index).should eq((1..47).to_a)
    PastafarianCalendar::SourceLanguageCatalog.cutlet(12).should eq("ઘઉં")
    PastafarianCalendar::SourceLanguageCatalog.month(44).should eq("મીઠું")
  end

  it "સાચવેલી શેષ ક્રિયા ચોક્કસ રીતે ગણે છે" do
    m = NormativeScroll::M
    NormativeScroll.save(BigInt.new(1)).should eq(BigInt.new(1))
    NormativeScroll.save(m - 1).should eq(m - 1)
    NormativeScroll.save(m).should eq(m)
    NormativeScroll.save(m + 1).should eq(BigInt.new(1))
    NormativeScroll.save(m * 2).should eq(m)
  end

  it "સ્થાપના દિવસની ગણતરી અને દિશા યોગ્ય રાખે છે" do
    f = NormativeScroll::FOUNDATION_DAY
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
    second = NormativeScroll::STONES[1]
    second.should eq([378, 1073, 2375, 6195, 10493].map { |x| BigInt.new(x) })
  end

  it "ક્રમવિન્યાસની એક આધારિત સરહદો સાચી ખોલે છે" do
    NormativeScroll.permutation_unrank1(BigInt.new(1), [1, 2, 3, 4, 5, 6]).should eq([1, 2, 3, 4, 5, 6])
    NormativeScroll.permutation_unrank1(BigInt.new(720), [1, 2, 3, 4, 5, 6]).should eq([6, 5, 4, 3, 2, 1])
  end

  it "મર્યાદિત રચનાઓનો ચોક્કસ શબ્દકોશીય ક્રમ જાળવે છે" do
    family = NormativeScroll::BoundedCompositionFamily.new(8, 2, 3, 5)
    family.count.should eq(BigInt.new(3))
    family.unrank1(BigInt.new(1)).should eq([3, 5])
    family.unrank1(BigInt.new(2)).should eq([4, 4])
    family.unrank1(BigInt.new(3)).should eq([5, 3])
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
    family.unrank1(BigInt.new(1)).should eq([1, 1, 2, 2])
    family.unrank1(BigInt.new(2)).should eq([1, 2, 1, 2])
  end

  it "નિષ્પક્ષ મૂળ સંદર્ભ માત્ર અવલોકન શેલ સાથે બનાવે છે" do
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

  it "ઉત્પાદન સ્ત્રોત પરીક્ષણ ઓરેકલને સંદર્ભિત કરતો નથી" do
    source = File.read(File.expand_path("../src/pastafarian_calendar.cr", __DIR__))
    source.includes?("NormativeScroll").should be_false
    source.includes?("normative_scroll").should be_false
  end

  it "ભવિષ્યના ટુકડાઓના ઓળખચિહ્નો ઉત્પાદન સ્ત્રોતમાં હાજર નથી" do
    root = File.expand_path("../src", __DIR__)
    all_source = Dir.glob(File.join(root, "**/*.cr")).sort.map { |path| File.read(path) }.join("\n")
    forbidden = [
      "oldRemainder",
      "oldDayTag",
      "oldDistance",
      "mutateStonesWrong",
      "orderAt46Latch",
      "biasedLegacyPick",
      "LEGACY_YEAR_MAX",
      "oldJumpGuess",
      "VirtualLegacyList",
      "legacyChooseEachDaySeparately",
      "oldContiguousMonthDayGuess",
    ]
    forbidden.each { |token| all_source.includes?(token).should be_false }
  end
end
