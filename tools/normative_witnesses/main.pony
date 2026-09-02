use "../../src"
use "../../oracle"

actor Main
  new create(env: Env) =>
    try
      let f = NormativeConstants.foundation_day()
      let m = NormativeConstants.m()
      env.out.print("ค่ามอดูลัส=" + m.string())
      env.out.print("วันฐาน=" + f.string())
      env.out.print("วันแผ่นศิลา=" + NormativeConstants.tablets_day().string())
      env.out.print("save_ค่ามอดูลัส=" + NormativeArithmetic.save(m)?.string())
      env.out.print("save_2ค่ามอดูลัส=" + NormativeArithmetic.save(m.mul(BigInt.from_u64(2)))?.string())
      env.out.print("day_วันฐาน=" + NormativeArithmetic.day_count(f).string())
      env.out.print("จำนวนวัน_ก่อนฐาน=" + NormativeArithmetic.day_count(f.sub(BigInt.from_u64(1))).string())
      env.out.print("จำนวนวัน_หลังฐาน=" + NormativeArithmetic.day_count(f.add(BigInt.from_u64(1))).string())

      let stones = NormativeStones.build()?
      let s2 = stones(1)?
      env.out.print("หินแถว2=" + s2.wheat.string() + "," + s2.barley.string() + "," + s2.salt.string() + "," + s2.bitter.string() + "," + s2.red.string())

      let sauce = NormativeSauce(f, f)?
      var i: USize = 0
      while i < sauce.bowls.size() do
        env.out.print("ซอส_ฐาน_ชาม_" + (i + 1).string() + "=" + sauce.bowls(i)?.string())
        i = i + 1
      end
      var order: String val = ""
      i = 0
      while i < sauce.order_at_drop_46.size() do
        if i > 0 then order = order + "," end
        order = order + sauce.order_at_drop_46(i)?.string()
        i = i + 1
      end
      env.out.print("ซอส_ฐาน_ลำดับหยด46=" + order)

      let oracle = NormativeCalendarOracle
      _calendar_line(env, oracle, f, f, "ปฏิทิน_วันฐาน")?
      _calendar_line(env, oracle, f, f.sub(BigInt.from_u64(1)), "ปฏิทิน_วันก่อนฐาน")?
      _calendar_line(env, oracle, f, f.add(BigInt.from_u64(1)), "ปฏิทิน_วันหลังฐาน")?
    else
      env.err.print("การสร้างพยานเชิงบรรทัดฐานล้มเหลว")
      env.exitcode(1)
    end

  fun _calendar_line(env: Env, oracle: NormativeCalendarOracle, c: BigInt box, t: BigInt box, label: String) ? =>
    let x = oracle.present(c, t)?
    env.out.print(label + "=" + x(0)? + "|" + x(1)? + "|" + x(2)? + "|" + x(3)? + "|" + x(4)?)
