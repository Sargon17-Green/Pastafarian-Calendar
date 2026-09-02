primitive BigDigits
  fun digit(s: String box, i: USize): U8 =>
    try s(i)? - 48 else 0 end

  fun trim_mag(s: String val): String val =>
    var first: USize = 0
    while (first + 1) < s.size() do
      if digit(s, first) != 0 then break end
      first = first + 1
    end
    let start = first
    recover val
      let out = String(s.size() - start)
      var i = start
      while i < s.size() do
        out.push(try s(i)? else 48 end)
        i = i + 1
      end
      if out.size() == 0 then out.push(48) end
      out
    end

  fun cmp_mag(a: String val, b: String val): I8 =>
    let aa = trim_mag(a)
    let bb = trim_mag(b)
    if aa.size() < bb.size() then return -1 end
    if aa.size() > bb.size() then return 1 end
    var i: USize = 0
    while i < aa.size() do
      let da = digit(aa, i)
      let db = digit(bb, i)
      if da < db then return -1 end
      if da > db then return 1 end
      i = i + 1
    end
    0

  fun add_mag(a: String val, b: String val): String val =>
    let raw: String val = recover val
      let out = String(a.size().max(b.size()) + 1)
      var ia = a.size()
      var ib = b.size()
      var carry: U16 = 0
      while (ia > 0) or (ib > 0) or (carry > 0) do
        var da: U16 = 0
        var db: U16 = 0
        if ia > 0 then
          ia = ia - 1
          da = digit(a, ia).u16()
        end
        if ib > 0 then
          ib = ib - 1
          db = digit(b, ib).u16()
        end
        let sum = da + db + carry
        out.push(48 + (sum % 10).u8())
        carry = sum / 10
      end
      out.reverse_in_place()
      out
    end
    trim_mag(raw)

  fun sub_mag(a: String val, b: String val): String val =>
    let raw: String val = recover val
      let out = String(a.size())
      var ia = a.size()
      var ib = b.size()
      var borrow: I16 = 0
      while ia > 0 do
        ia = ia - 1
        var da = digit(a, ia).i16() - borrow
        var db: I16 = 0
        if ib > 0 then
          ib = ib - 1
          db = digit(b, ib).i16()
        end
        if da < db then
          da = da + 10
          borrow = 1
        else
          borrow = 0
        end
        out.push(48 + (da - db).u8())
      end
      out.reverse_in_place()
      out
    end
    trim_mag(raw)

  fun mul_mag_digit(a: String val, d: U8): String val =>
    if d == 0 then return "0" end
    if d == 1 then return trim_mag(a) end
    let raw: String val = recover val
      let out = String(a.size() + 1)
      var ia = a.size()
      var carry: U16 = 0
      while ia > 0 do
        ia = ia - 1
        let p = (digit(a, ia).u16() * d.u16()) + carry
        out.push(48 + (p % 10).u8())
        carry = p / 10
      end
      while carry > 0 do
        out.push(48 + (carry % 10).u8())
        carry = carry / 10
      end
      out.reverse_in_place()
      out
    end
    trim_mag(raw)

  fun mul_mag(a: String val, b: String val): String val =>
    let aa = trim_mag(a)
    let bb = trim_mag(b)
    if (aa == "0") or (bb == "0") then return "0" end
    var result: String val = "0"
    var ib = bb.size()
    var zero_count: USize = 0
    while ib > 0 do
      ib = ib - 1
      let partial = mul_mag_digit(aa, digit(bb, ib))
      let zeros = zero_count
      let shifted: String val = recover val
        let out = String(partial.size() + zeros)
        out.append(partial)
        var z: USize = 0
        while z < zeros do
          out.push(48)
          z = z + 1
        end
        out
      end
      result = add_mag(result, shifted)
      zero_count = zero_count + 1
    end
    trim_mag(result)

  fun one_digit(d: U8): String val =>
    recover val
      let out = String(1)
      out.push(48 + d)
      out
    end

  fun append_digit_mag(a: String val, d: U8): String val =>
    let aa = trim_mag(a)
    if aa == "0" then
      return trim_mag(one_digit(d))
    end
    recover val
      let out = String(aa.size() + 1)
      out.append(aa)
      out.push(48 + d)
      out
    end

  fun divmod_mag(a: String val, b: String val): (String val, String val) ? =>
    let aa = trim_mag(a)
    let bb = trim_mag(b)
    if bb == "0" then error end
    if cmp_mag(aa, bb) < 0 then return ("0", aa) end
    var q: String val = ""
    var rem: String val = "0"
    var i: USize = 0
    while i < aa.size() do
      rem = append_digit_mag(rem, digit(aa, i))
      var qd: U8 = 9
      var found: Bool = false
      while true do
        let p = mul_mag_digit(bb, qd)
        if cmp_mag(p, rem) <= 0 then
          q = q + one_digit(qd)
          rem = sub_mag(rem, p)
          found = true
          break
        end
        if qd == 0 then break end
        qd = qd - 1
      end
      if not found then q = q + "0" end
      i = i + 1
    end
    (trim_mag(q), trim_mag(rem))

  fun parse(s: String val): (Bool, String val) ? =>
    if s.size() == 0 then error end
    var negative = false
    var start: USize = 0
    let first = try s(0)? else error end
    if first == 45 then
      negative = true
      start = 1
    else if first == 43 then
      start = 1
    end
    if start >= s.size() then error end
    var i = start
    while i < s.size() do
      let c = try s(i)? else error end
      if (c < 48) or (c > 57) then error end
      i = i + 1
    end
    let start_at = start
    let mag: String val = recover val
      let out = String(s.size() - start_at)
      var j = start_at
      while j < s.size() do
        out.push(try s(j)? else 48 end)
        j = j + 1
      end
      out
    end
    let t = trim_mag(mag)
    (negative and (t != "0"), t)

class val BigInt
  let _negative: Bool
  let _mag: String val

  new val create(s: String val) ? =>
    let p = BigDigits.parse(s)?
    _negative = p._1
    _mag = p._2

  new val from_u64(v: U64) =>
    _negative = false
    _mag = v.string()

  new val from_usize(v: USize) =>
    _negative = false
    _mag = v.string()

  new val _parts(negative': Bool, mag': String val) =>
    let t = BigDigits.trim_mag(mag')
    _negative = negative' and (t != "0")
    _mag = t

  new val from_parts(negative': Bool, mag': String val) =>
    let t = BigDigits.trim_mag(mag')
    _negative = negative' and (t != "0")
    _mag = t

  fun box string(): String val =>
    let mag = _mag
    let negative = _negative
    recover val
      let out = String(mag.size() + 1)
      if negative then out.push(45) end
      out.append(mag)
      out
    end

  fun box is_zero(): Bool => _mag == "0"
  fun box is_negative(): Bool => _negative

  fun box abs(): BigInt => BigInt._parts(false, _mag)

  fun box neg(): BigInt =>
    if is_zero() then BigInt._parts(false, "0") else BigInt._parts(not _negative, _mag) end

  fun box cmp(that: BigInt box): I8 =>
    if _negative and (not that._negative) then return -1 end
    if (not _negative) and that._negative then return 1 end
    let c = BigDigits.cmp_mag(_mag, that._mag)
    if _negative then -c else c end

  fun box eqv(that: BigInt box): Bool => cmp(that) == 0
  fun box lte(that: BigInt box): Bool => cmp(that) <= 0
  fun box lt(that: BigInt box): Bool => cmp(that) < 0
  fun box gte(that: BigInt box): Bool => cmp(that) >= 0
  fun box gt(that: BigInt box): Bool => cmp(that) > 0

  fun box add(that: BigInt box): BigInt =>
    if _negative == that._negative then
      BigInt._parts(_negative, BigDigits.add_mag(_mag, that._mag))
    else
      let c = BigDigits.cmp_mag(_mag, that._mag)
      if c == 0 then
        BigInt._parts(false, "0")
      else if c > 0 then
        BigInt._parts(_negative, BigDigits.sub_mag(_mag, that._mag))
      else
        BigInt._parts(that._negative, BigDigits.sub_mag(that._mag, _mag))
      end
    end

  fun box sub(that: BigInt box): BigInt => add(that.neg())

  fun box mul(that: BigInt box): BigInt =>
    BigInt._parts(_negative != that._negative, BigDigits.mul_mag(_mag, that._mag))

  fun box square(): BigInt => BigInt._parts(false, BigDigits.mul_mag(_mag, _mag))

  fun box divmod_trunc(that: BigInt box): (BigInt, BigInt) ? =>
    if that.is_zero() then error end
    let qr = BigDigits.divmod_mag(_mag, that._mag)?
    let q = BigInt._parts(_negative != that._negative, qr._1)
    let r = BigInt._parts(_negative, qr._2)
    (q, r)

  fun box floor_div(that: BigInt box): BigInt ? =>
    if that.is_zero() then error end
    let qr = divmod_trunc(that)?
    let q = qr._1
    let r = qr._2
    if ((_negative != that._negative) and (not r.is_zero())) then
      q.sub(BigInt.from_u64(1))
    else
      q
    end

  fun box regular_mod(d: BigInt box): BigInt ? =>
    if d.is_zero() or d.is_negative() then error end
    let qr = BigDigits.divmod_mag(_mag, d._mag)?
    let rem = BigInt._parts(false, qr._2)
    if not _negative then
      rem
    else if rem.is_zero() then
      rem
    else
      d.sub(rem)
    end

  fun box to_usize(): USize ? =>
    if _negative then error end
    var out: USize = 0
    var i: USize = 0
    while i < _mag.size() do
      let d = BigDigits.digit(_mag, i).usize()
      let maxv = USize.max_value()
      if out > ((maxv - d) / 10) then error end
      out = (out * 10) + d
      i = i + 1
    end
    out
