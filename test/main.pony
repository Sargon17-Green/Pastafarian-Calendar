use "pony_test"
use "../src"
use "../oracle"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestBigInt)
    test(_TestSave)
    test(_TestDayCount)
    test(_TestCatalog)
    test(_TestPermutation)
    test(_TestBoundedComposition)
    test(_TestCutletBoundary)
    test(_TestWeaving)
    test(_TestBootstrapContext)
    test(_TestSauceDeterminism)

class iso _TestBigInt is UnitTest
  fun name(): String => "เลขจำนวนเต็ม/ความแม่นยำ"
  fun apply(h: TestHelper) ? =>
    let a = BigInt("999999999999999999999999999999999999")?
    let b = BigInt("1")?
    h.assert_eq[String]("1000000000000000000000000000000000000", a.add(b).string())
    let c = BigInt("12345678901234567890")?
    let d = BigInt("987654321")?
    let p = c.mul(d)
    let qr = p.divmod_trunc(c)?
    h.assert_eq[String](d.string(), qr._1.string())
    h.assert_eq[String]("0", qr._2.string())
    h.assert_eq[String]("4", BigInt("-17")?.regular_mod(BigInt("7")?)?.string())

class iso _TestSave is UnitTest
  fun name(): String => "เลขจำนวนเต็ม/การเก็บค่า"
  fun apply(h: TestHelper) ? =>
    let m = NormativeConstants.m()
    h.assert_eq[String](m.string(), NormativeArithmetic.save(m)?.string())
    h.assert_eq[String](m.string(), NormativeArithmetic.save(m.mul(BigInt.from_u64(2)))?.string())
    h.assert_eq[String](m.string(), NormativeArithmetic.save(m.mul(BigInt.from_u64(3)))?.string())
    h.assert_eq[String]("1", NormativeArithmetic.save(m.add(BigInt.from_u64(1)))?.string())

class iso _TestDayCount is UnitTest
  fun name(): String => "ออราเคิล/จำนวนวัน"
  fun apply(h: TestHelper) ? =>
    let f = NormativeConstants.foundation_day()
    h.assert_eq[String]("1", NormativeArithmetic.day_count(f).string())
    h.assert_eq[String]("3", NormativeArithmetic.day_count(f.add(BigInt.from_u64(1))).string())
    h.assert_eq[String]("2", NormativeArithmetic.day_count(f.sub(BigInt.from_u64(1))).string())
    let counts = NormativeArithmetic.work_counts(f.sub(BigInt.from_u64(5)), f.add(BigInt.from_u64(7)))
    h.assert_eq[String]("13", counts.distance.string())
    h.assert_eq[String]("3", counts.direction.string())

class iso _TestCatalog is UnitTest
  fun name(): String => "ภาษาไทย/แค็ตตาล็อกตรึง"
  fun apply(h: TestHelper) ? =>
    let cutlets = SourceLanguageCatalog.cutlets()
    let months = SourceLanguageCatalog.months()
    h.assert_eq[USize](17, cutlets.size())
    h.assert_eq[USize](47, months.size())
    h.assert_eq[String]("ข้าวสาลี", SourceLanguageCatalog.cutlet_text(12)?)
    h.assert_eq[String]("เกลือ", SourceLanguageCatalog.month_text(44)?)
    var i: USize = 0
    while i < cutlets.size() do
      h.assert_eq[USize](i + 1, cutlets(i)?.canonical_index)
      var j = i + 1
      while j < cutlets.size() do
        h.assert_false(cutlets(i)?.text == cutlets(j)?.text)
        j = j + 1
      end
      i = i + 1
    end
    i = 0
    while i < months.size() do
      h.assert_eq[USize](i + 1, months(i)?.canonical_index)
      var j = i + 1
      while j < months.size() do
        h.assert_false(months(i)?.text == months(j)?.text)
        j = j + 1
      end
      i = i + 1
    end

class iso _TestPermutation is UnitTest
  fun name(): String => "ออราเคิล/ลำดับชาม"
  fun apply(h: TestHelper) ? =>
    let first = NormativePermutation.unrank1(1)?
    let last = NormativePermutation.unrank1(720)?
    h.assert_array_eq[USize]([1; 2; 3; 4; 5; 6], first)
    h.assert_array_eq[USize]([6; 5; 4; 3; 2; 1], last)

class iso _TestBoundedComposition is UnitTest
  fun name(): String => "ออราเคิล/องค์ประกอบมีขอบเขต"
  fun apply(h: TestHelper) ? =>
    let family = BoundedCompositionCounter(5, 2, 1, 4)
    h.assert_eq[String]("4", family.count_all().string())
    h.assert_array_eq[USize]([2; 3], family.unrank1(BigInt.from_u64(2))?)

class iso _TestCutletBoundary is UnitTest
  fun name(): String => "ออราเคิล/ขอบเขตคัตเล็ต"
  fun apply(h: TestHelper) ? =>
    let family = CutletPartitionCounter(5, 2, USize(2))
    h.assert_eq[String]("1", family.count_all().string())
    h.assert_array_eq[USize]([2; 3], family.unrank1(BigInt.from_u64(1))?)

class iso _TestWeaving is UnitTest
  fun name(): String => "ออราเคิล/การสานเดือน"
  fun apply(h: TestHelper) ? =>
    let family = WeavingCounter([2; 2])
    h.assert_eq[String]("2", family.count_all()?.string())
    h.assert_array_eq[USize]([1; 1; 2; 2], family.unrank1(BigInt.from_u64(1))?)
    h.assert_array_eq[USize]([1; 2; 1; 2], family.unrank1(BigInt.from_u64(2))?)

class iso _TestBootstrapContext is UnitTest
  fun name(): String => "โครงสร้าง/บริบทพื้นฐาน"
  fun apply(h: TestHelper) ? =>
    let ctx = SpaghettiBootstrap.prepare(BigInt("1")?, BigInt("2")?)
    h.assert_eq[String]("READY", ctx.status)
    h.assert_eq[String]("BOOTSTRAP", ctx.phase)
    h.assert_eq[USize](1, ctx.branch_trace.size())

class iso _TestSauceDeterminism is UnitTest
  fun name(): String => "ออราเคิล/ความเป็นเชิงกำหนด"
  fun apply(h: TestHelper) ? =>
    let f = NormativeConstants.foundation_day()
    let a = NormativeSauce(f, f)?
    let b = NormativeSauce(f, f)?
    h.assert_eq[USize](6, a.bowls.size())
    h.assert_eq[USize](6, a.order_at_drop_46.size())
    var i: USize = 0
    while i < 6 do
      h.assert_eq[String](a.bowls(i)?.string(), b.bowls(i)?.string())
      h.assert_eq[USize](a.order_at_drop_46(i)?, b.order_at_drop_46(i)?)
      i = i + 1
    end
