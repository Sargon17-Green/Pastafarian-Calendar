use "pony_test"
use "../src"
use "../oracle"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestBigInt)
    test(_TestBigIntLongProductWitness)
    test(_TestSave)
    test(_TestDayCount)
    test(_TestCatalog)
    test(_TestPermutation)
    test(_TestBoundedComposition)
    test(_TestCutletBoundary)
    test(_TestWeaving)
    test(_TestBootstrapContext)
    test(_TestSauceDeterminism)
    test(_TestInvocationIsolation)
    test(_TestContextSnapshot)
    test(_TestActorSnapshotBoundary)
    test(_TestBigIntActorValueBoundary)
    test(_TestOracleMutableStateIsolation)
    test(_TestSelectionWitness)
    test(_TestStoneWitness)
    test(_TestNameUnrankWitness)
    test(_TestMonthBoundsWitness)

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

class iso _TestBigIntLongProductWitness is UnitTest
  fun name(): String => "เลขจำนวนเต็ม/พยานการคูณยาวแบบไม่ล้น"
  fun apply(h: TestHelper) ? =>
    let n: USize = 256
    let digits: String val = recover val
      let out = String(n)
      var i: USize = 0
      while i < n do
        out.push(57)
        i = i + 1
      end
      out
    end
    let expected: String val = recover val
      let out = String(n * 2)
      var i: USize = 0
      while i < (n - 1) do
        out.push(57)
        i = i + 1
      end
      out.push(56)
      i = 0
      while i < (n - 1) do
        out.push(48)
        i = i + 1
      end
      out.push(49)
      out
    end
    let value = BigInt(digits)?
    h.assert_eq[String](expected, value.square().string())

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
    cutlets.delete(0)?
    months.delete(0)?
    h.assert_eq[USize](17, SourceLanguageCatalog.cutlets().size())
    h.assert_eq[USize](47, SourceLanguageCatalog.months().size())
    h.assert_eq[String]("สัมฤทธิ์", SourceLanguageCatalog.cutlet_text(1)?)
    h.assert_eq[String]("ดินเหนียว", SourceLanguageCatalog.month_text(1)?)

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
    let ctx = SpaghettiBootstrap.prepare(BigInt("1")?, BigInt("2")?)?
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

class iso _TestInvocationIsolation is UnitTest
  fun name(): String => "โครงสร้าง/การแยกสถานะต่อคำขอ"
  fun apply(h: TestHelper) ? =>
    let a = SpaghettiBootstrap.prepare(BigInt("10")?, BigInt("20")?)?
    let b = SpaghettiBootstrap.prepare(BigInt("10")?, BigInt("20")?)?
    h.assert_true(a.mutable_storage_is_distinct_from(b))
    h.assert_true(a.owns_distinct_internal_arrays())
    h.assert_true(b.owns_distinct_internal_arrays())
    a.logs.push("คำขอหนึ่ง")
    a.diagnostics.push("ตรวจหนึ่ง")
    a.warnings.push("เตือนหนึ่ง")
    a.branch_trace.push("LOCAL_ONLY")
    a.metrics("local.only") = 99
    h.assert_eq[USize](0, b.logs.size())
    h.assert_eq[USize](0, b.diagnostics.size())
    h.assert_eq[USize](0, b.warnings.size())
    h.assert_eq[USize](1, b.branch_trace.size())
    h.assert_eq[USize](1, b.metrics.size())

class iso _TestContextSnapshot is UnitTest
  fun name(): String => "โครงสร้าง/สแนปช็อตข้ามขอบเขต"
  fun apply(h: TestHelper) ? =>
    let ctx = SpaghettiBootstrap.prepare(BigInt("-15")?, BigInt("27")?)?
    ctx.logs.push("บันทึกหนึ่ง")
    let snap = ctx.snapshot()
    let validator = ValidationManager
    h.assert_true(validator.require_snapshot_copy(ctx, snap))
    ctx.logs.push("บันทึกสอง")
    h.assert_eq[USize](1, snap.log_size)
    h.assert_eq[USize](2, ctx.logs.size())

actor _SnapshotBoundaryReceiver
  new create(snap: MonsterSnapshot, h: TestHelper) =>
    if (snap.phase == "BOOTSTRAP") and (snap.status == "READY") then
      h.complete_action("snapshot-boundary")
    else
      h.fail_action("snapshot-boundary")
    end

class iso _TestActorSnapshotBoundary is UnitTest
  fun name(): String => "โครงสร้าง/ขอบเขต actor แบบอ่านอย่างเดียว"
  fun apply(h: TestHelper) ? =>
    h.long_test(2_000_000_000)
    h.expect_action("snapshot-boundary")
    let ctx = SpaghettiBootstrap.prepare(BigInt("1")?, BigInt("2")?)?
    _SnapshotBoundaryReceiver(ctx.snapshot(), h)

actor _BigIntBoundaryReceiver
  new create(value: BigInt val, h: TestHelper) =>
    if value.string() == "42" then
      h.complete_action("bigint-val-boundary")
    else
      h.fail_action("bigint-val-boundary")
    end

class iso _TestBigIntActorValueBoundary is UnitTest
  fun name(): String => "โครงสร้าง/จำนวนเต็ม val ข้าม actor"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    h.expect_action("bigint-val-boundary")
    _BigIntBoundaryReceiver(BigInt.from_u64(42), h)

class iso _TestOracleMutableStateIsolation is UnitTest
  fun name(): String => "ออราเคิล/การแยกโครงสร้างที่เปลี่ยนค่าได้"
  fun apply(h: TestHelper) ? =>
    let a = NormativeCalendarOracle
    let b = NormativeCalendarOracle
    h.assert_true(a.gate_store isnt b.gate_store)
    h.assert_true(a.gate_store.gates isnt b.gate_store.gates)
    h.assert_eq[USize](1, a.gate_store.gates.size())
    h.assert_eq[USize](1, b.gate_store.gates.size())
    a.gate_store.gates("ownership-probe") = BigInt.from_u64(7)
    h.assert_eq[USize](2, a.gate_store.gates.size())
    h.assert_eq[USize](1, b.gate_store.gates.size())
    let c1 = BoundedCompositionCounter(8, 3, 1, 6)
    let c2 = BoundedCompositionCounter(8, 3, 1, 6)
    h.assert_eq[USize](0, c1.memo.size())
    h.assert_eq[USize](0, c2.memo.size())
    c1.count_all()
    h.assert_true(c1.memo.size() > 0)
    h.assert_eq[USize](0, c2.memo.size())

class iso _TestSelectionWitness is UnitTest
  fun name(): String => "ออราเคิล/พยานการเลือกสั้นและกว้าง"
  fun apply(h: TestHelper) ? =>
    let m = NormativeConstants.m()
    let forward = AnswerStream(BigInt.from_u64(1), 1)
    let backward = AnswerStream(BigInt.from_u64(1), -1)
    h.assert_eq[String]("1", NormativeSelection.choose_short(forward, BigInt.from_u64(10))?.string())
    h.assert_eq[String](m.string(), NormativeAnswers.answer_at(backward, BigInt.from_u64(1))?.string())
    let rejected = AnswerStream(m, 1)
    h.assert_eq[String]("1", NormativeSelection.choose_short(rejected, BigInt.from_u64(10))?.string())
    let wide_n = m.add(BigInt.from_u64(1))
    h.assert_eq[String](wide_n.string(), NormativeSelection.choose_wide(forward, wide_n)?.string())

class iso _TestStoneWitness is UnitTest
  fun name(): String => "ออราเคิล/พยานตารางหิน"
  fun apply(h: TestHelper) ? =>
    let stones = NormativeStones.build()?
    h.assert_eq[USize](46, stones.size())
    let first = stones(0)?
    let second = stones(1)?
    h.assert_eq[String]("17", first.wheat.string())
    h.assert_eq[String]("29", first.barley.string())
    h.assert_eq[String]("43", first.salt.string())
    h.assert_eq[String]("71", first.bitter.string())
    h.assert_eq[String]("101", first.red.string())
    h.assert_eq[String]("378", second.wheat.string())
    h.assert_eq[String]("1073", second.barley.string())
    h.assert_eq[String]("2375", second.salt.string())
    h.assert_eq[String]("6195", second.bitter.string())
    h.assert_eq[String]("10493", second.red.string())

class iso _TestNameUnrankWitness is UnitTest
  fun name(): String => "ออราเคิล/พยานชื่อไม่ซ้ำ"
  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("6", NormativeNames.falling_factorial(3, 2).string())
    h.assert_array_eq[USize]([1; 2], NormativeNames.unrank_distinct(3, 2, BigInt.from_u64(1))?)
    h.assert_array_eq[USize]([3; 2], NormativeNames.unrank_distinct(3, 2, BigInt.from_u64(6))?)

class iso _TestMonthBoundsWitness is UnitTest
  fun name(): String => "ออราเคิล/พยานขอบเขตจำนวนเดือน"
  fun apply(h: TestHelper) ? =>
    let low_252 = NormativeArithmetic.ceil_div_usize(252, 123)
    let high_252 = USize(47).min(252 / 4)
    let low_5778 = NormativeArithmetic.ceil_div_usize(5778, 123)
    let high_5778 = USize(47).min(5778 / 4)
    h.assert_eq[USize](3, low_252)
    h.assert_eq[USize](47, high_252)
    h.assert_eq[USize](47, low_5778)
    h.assert_eq[USize](47, high_5778)
