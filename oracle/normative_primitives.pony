use "../src"
primitive NormativeConstants
  fun m(): BigInt => BigInt.from_parts(false, "170141183460469231731687303715884105727")
  fun tablets_day(): BigInt => BigInt.from_parts(true, "278522")
  fun foundation_day(): BigInt => BigInt.from_parts(true, "15055671")
  fun year_min_days(): USize => 252
  fun year_max_days(): USize => 5778

primitive NormativeArithmetic
  fun one(): BigInt => BigInt.from_u64(1)
  fun two(): BigInt => BigInt.from_u64(2)

  fun save(x: BigInt box): BigInt ? =>
    x.sub(one()).regular_mod(NormativeConstants.m())?.add(one())

  fun wrap1(position: I64, size: USize): USize =>
    let s = size.i64()
    var r = (position - 1) % s
    if r < 0 then r = r + s end
    (r + 1).usize()

  fun ceil_div_usize(a: USize, b: USize): USize =>
    (a + b - 1) / b

  fun day_count(day: BigInt box): BigInt =>
    let f = NormativeConstants.foundation_day()
    if day.eqv(f) then
      one()
    else if day.gt(f) then
      day.sub(f).mul(two()).add(one())
    else
      f.sub(day).mul(two())
    end

  fun work_counts(calculation_day: BigInt box, target_day: BigInt box): WorkCounts =>
    let c = day_count(calculation_day)
    let t = day_count(target_day)
    let distance = target_day.sub(calculation_day).abs().add(one())
    let connection = c.add(t)
    let direction =
      if target_day.lt(calculation_day) then BigInt.from_u64(1)
      else if target_day.eqv(calculation_day) then BigInt.from_u64(2)
      else BigInt.from_u64(3)
      end
    WorkCounts(c, t, distance, connection, direction)
