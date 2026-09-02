use "../src"
primitive NormativeStones
  fun build(): Array[Stone] ? =>
    let table = Array[Stone](46)
    var s = Stone(
      BigInt.from_u64(17), BigInt.from_u64(29), BigInt.from_u64(43),
      BigInt.from_u64(71), BigInt.from_u64(101))
    table.push(s)
    var i: USize = 2
    while i <= 46 do
      let old = s
      let next_wheat = NormativeArithmetic.save(old.wheat.square().add(old.barley.mul(BigInt.from_u64(3))).add(BigInt.from_usize(i)))?
      let next_barley = NormativeArithmetic.save(old.barley.square().add(old.salt.mul(BigInt.from_u64(5))).add(old.wheat))?
      let next_salt = NormativeArithmetic.save(old.salt.square().add(old.bitter.mul(BigInt.from_u64(7))).add(old.barley))?
      let next_bitter = NormativeArithmetic.save(old.bitter.square().add(old.red.mul(BigInt.from_u64(11))).add(old.salt))?
      let next_red = NormativeArithmetic.save(old.red.square().add(old.wheat.mul(BigInt.from_u64(13))).add(old.bitter))?
      s = Stone(next_wheat, next_barley, next_salt, next_bitter, next_red)
      table.push(s)
      i = i + 1
    end
    table

primitive NormativeHidden
  fun coeff(k: USize): (U64, U64, U64, U64) ? =>
    match k
    | 1 => (3, 4, 6, 8)
    | 2 => (5, 7, 10, 12)
    | 3 => (7, 10, 14, 16)
    | 4 => (9, 13, 18, 20)
    | 5 => (11, 16, 22, 24)
    | 6 => (13, 19, 26, 28)
    | 7 => (15, 22, 30, 32)
    else error
    end

  fun grind_kind(g: USize): USize ? =>
    match g
    | 1 => 1
    | 2 => 2
    | 3 => 3
    | 4 => 4
    | 5 => 5
    | 6 => 1
    | 7 => 2
    else error
    end

  fun build(counts: WorkCounts, stones: Array[Stone] box): Array[BigInt] ? =>
    let hidden = Array[BigInt](7)
    var k: USize = 1
    while k <= 7 do
      let c = coeff(k)?
      let stone = stones(k - 1)?
      var x = counts.action
        .add(counts.target.mul(BigInt.from_u64(c._1)))
        .add(counts.distance.mul(BigInt.from_u64(c._2)))
        .add(counts.connection.mul(BigInt.from_u64(c._3)))
        .add(counts.direction.mul(BigInt.from_u64(c._4)))
        .add(stone.wheat).add(stone.barley).add(stone.salt).add(stone.bitter).add(stone.red)
      x = NormativeArithmetic.save(x)?
      var g: USize = 1
      while g <= 7 do
        let old_x = x
        x = NormativeArithmetic.save(
          old_x.square()
            .add(old_x.mul(BigInt.from_u64(3)))
            .add(stone.at(grind_kind(g)?)?)
            .add(BigInt.from_usize(g)))?
        g = g + 1
      end
      hidden.push(x)
      k = k + 1
    end
    hidden

primitive NormativeVisible
  fun grind_row(g: USize): (U64, U64, U64, U64, USize) ? =>
    match g
    | 1 => (3, 5, 7, 11, 1)
    | 2 => (5, 7, 11, 13, 2)
    | 3 => (7, 11, 13, 17, 3)
    | 4 => (11, 13, 17, 19, 4)
    | 5 => (13, 17, 19, 23, 5)
    | 6 => (17, 19, 23, 29, 1)
    | 7 => (19, 23, 29, 31, 2)
    | 8 => (23, 29, 31, 37, 3)
    | 9 => (29, 31, 37, 41, 4)
    | 10 => (31, 37, 41, 43, 5)
    | 11 => (37, 41, 43, 47, 1)
    else error
    end

  fun prior(visible: Array[BigInt] box, hidden: Array[BigInt] box, i: USize, back: USize): BigInt ? =>
    if i > back then
      visible(i - back - 1)?
    else
      let slot = i.i64() - back.i64()
      let k = (1 - slot).usize()
      hidden(k - 1)?
    end

  fun build(counts: WorkCounts, stones: Array[Stone] box, hidden: Array[BigInt] box): Array[BigInt] ? =>
    let visible = Array[BigInt](46)
    var i: USize = 1
    while i <= 46 do
      let p1 = prior(visible, hidden, i, 1)?
      let p3 = prior(visible, hidden, i, 3)?
      let p7 = prior(visible, hidden, i, 7)?
      let stone = stones(i - 1)?
      var x = NormativeArithmetic.save(
        stone.wheat.mul(counts.action)
          .add(stone.barley.mul(counts.target))
          .add(stone.salt.mul(counts.distance))
          .add(stone.bitter.mul(counts.connection))
          .add(stone.red.mul(counts.direction))
          .add(p1)
          .add(p3.mul(BigInt.from_u64(3)))
          .add(p7.mul(BigInt.from_u64(5)))
          .add(BigInt.from_usize(i)))?
      var g: USize = 1
      while g <= 11 do
        let row = grind_row(g)?
        let old_x = x
        x = NormativeArithmetic.save(
          old_x.square()
            .add(old_x.mul(BigInt.from_u64(row._1)))
            .add(p1.mul(BigInt.from_u64(row._2)))
            .add(p3.mul(BigInt.from_u64(row._3)))
            .add(p7.mul(BigInt.from_u64(row._4)))
            .add(stone.at(row._5)?))?
        g = g + 1
      end
      visible.push(x)
      i = i + 1
    end
    visible

primitive NormativePermutation
  fun factorial(n: USize): USize =>
    var r: USize = 1
    var i: USize = 2
    while i <= n do
      r = r * i
      i = i + 1
    end
    r

  fun unrank1(rank1: USize): Array[USize] ? =>
    if (rank1 < 1) or (rank1 > 720) then error end
    var rank0 = rank1 - 1
    let remaining: Array[USize] = [1; 2; 3; 4; 5; 6]
    let result = Array[USize](6)
    var slots_left: USize = 6
    while slots_left >= 1 do
      let block = factorial(slots_left - 1)
      let q = rank0 / block
      rank0 = rank0 % block
      result.push(remaining(q)?)
      remaining.delete(q)?
      if slots_left == 1 then break end
      slots_left = slots_left - 1
    end
    result

  fun from_drop(drop: BigInt box): Array[USize] ? =>
    let n = drop.sub(BigInt.from_u64(1)).regular_mod(BigInt.from_u64(720))?.add(BigInt.from_u64(1)).to_usize()?
    unrank1(n)?

primitive NormativeBowls
  fun initial(counts: WorkCounts): Array[BigInt] ? =>
    let primes: Array[U64] = [17; 19; 23; 29; 31; 37]
    let bowls = Array[BigInt](6)
    var id: USize = 1
    while id <= 6 do
      let p = primes(id - 1)?
      let s = counts.action
        .add(counts.target.mul(BigInt.from_usize(id)))
        .add(counts.distance).add(counts.connection).add(counts.direction)
        .add(BigInt.from_u64(p * p))
      bowls.push(NormativeArithmetic.save(s.square().add(BigInt.from_usize(id)))?)
      id = id + 1
    end
    bowls

  fun stir_kind(position: USize): USize ? =>
    match position
    | 1 => 1
    | 2 => 2
    | 3 => 3
    | 4 => 4
    | 5 => 5
    | 6 => 1
    else error
    end

  fun apply_visible(bowls_in: Array[BigInt] box, visible: Array[BigInt] box, stones: Array[Stone] box): (Array[BigInt], Array[USize]) ? =>
    var bowls = bowls_in.clone()
    var order_at_46 = Array[USize](6)
    var i: USize = 1
    while i <= 46 do
      let drop = visible(i - 1)?
      let order = NormativePermutation.from_drop(drop)?
      let old = bowls.clone()
      let pour = Array[BigInt].init(BigInt.from_u64(0), 6)
      let first_id = order(0)?
      let second_id = order(1)?
      let third_id = order(2)?
      let stone = stones(i - 1)?
      pour.update(0, NormativeArithmetic.save(drop.square().add(stone.wheat.mul(old(first_id - 1)?)).add(BigInt.from_u64(3).mul(BigInt.from_usize(i))))?)?
      pour.update(1, NormativeArithmetic.save(drop.square().add(stone.barley.mul(old(second_id - 1)?)).add(BigInt.from_u64(5).mul(BigInt.from_usize(i))))?)?
      pour.update(2, NormativeArithmetic.save(drop.square().add(stone.salt.mul(old(third_id - 1)?)).add(BigInt.from_u64(7).mul(BigInt.from_usize(i))))?)?
      let next_bowls = Array[BigInt].init(BigInt.from_u64(0), 6)
      var position: USize = 1
      while position <= 6 do
        let id = order(position - 1)?
        let prev_id = order(NormativeArithmetic.wrap1(position.i64() - 1, 6) - 1)?
        let next_id = order(NormativeArithmetic.wrap1(position.i64() + 1, 6) - 1)?
        let s = old(id - 1)?
          .add(old(prev_id - 1)?.mul(BigInt.from_u64(2)))
          .add(old(next_id - 1)?.mul(BigInt.from_u64(3)))
          .add(pour(position - 1)?)
          .add(drop)
          .add(stone.at(stir_kind(position)?)?)
        let v = NormativeArithmetic.save(
          s.square()
            .add(old(prev_id - 1)?.mul(old(next_id - 1)?).mul(BigInt.from_u64(5)))
            .add(BigInt.from_usize(i * position)))?
        next_bowls.update(id - 1, v)?
        position = position + 1
      end
      bowls = next_bowls
      if i == 46 then order_at_46 = order.clone() end
      i = i + 1
    end
    (bowls, order_at_46)

  fun post_stir12(bowls_in: Array[BigInt] box): Array[BigInt] ? =>
    var bowls = bowls_in.clone()
    var stir: USize = 1
    while stir <= 12 do
      let old = bowls.clone()
      var raw = BigInt.from_u64(0)
      for b in old.values() do raw = raw.add(b) end
      let saved_sum = NormativeArithmetic.save(raw.add(BigInt.from_u64(149).mul(BigInt.from_usize(stir))))?
      let order_number = saved_sum.sub(BigInt.from_u64(1)).regular_mod(BigInt.from_u64(720))?.add(BigInt.from_u64(1)).to_usize()?
      let order = NormativePermutation.unrank1(order_number)?
      let next_bowls = Array[BigInt].init(BigInt.from_u64(0), 6)
      var position: USize = 1
      while position <= 6 do
        let id = order(position - 1)?
        let prev_id = order(NormativeArithmetic.wrap1(position.i64() - 1, 6) - 1)?
        let next_id = order(NormativeArithmetic.wrap1(position.i64() + 1, 6) - 1)?
        let s = old(id - 1)?
          .add(old(prev_id - 1)?.mul(BigInt.from_u64(3)))
          .add(old(next_id - 1)?.mul(BigInt.from_u64(5)))
          .add(saved_sum)
          .add(BigInt.from_usize(stir))
          .add(BigInt.from_usize(position * position))
        let v = NormativeArithmetic.save(s.square().add(old(prev_id - 1)?.mul(old(next_id - 1)?).mul(BigInt.from_u64(7))))?
        next_bowls.update(id - 1, v)?
        position = position + 1
      end
      bowls = next_bowls
      stir = stir + 1
    end
    bowls

primitive NormativeSauce
  fun apply(calculation_day: BigInt box, target_day: BigInt box): SauceResult ? =>
    let counts = NormativeArithmetic.work_counts(calculation_day, target_day)
    let stones = NormativeStones.build()?
    let hidden = NormativeHidden.build(counts, stones)?
    let visible = NormativeVisible.build(counts, stones, hidden)?
    let bowls = NormativeBowls.initial(counts)?
    let after = NormativeBowls.apply_visible(bowls, visible, stones)?
    let final_bowls = NormativeBowls.post_stir12(after._1)?
    SauceResult(final_bowls, after._2)

primitive NormativeAnswers
  fun next_bowl(result: SauceResult, queried_id: USize): USize ? =>
    var p: USize = 0
    var found = false
    while p < result.order_at_drop_46.size() do
      if result.order_at_drop_46(p)? == queried_id then
        found = true
        break
      end
      p = p + 1
    end
    if not found then error end
    result.order_at_drop_46((p + 1) % 6)?

  fun ask(result: SauceResult, queried_id: USize, seal: U64): AnswerStream ? =>
    let next_id = next_bowl(result, queried_id)?
    let queried = result.bowls(queried_id - 1)?
    let next_value = result.bowls(next_id - 1)?
    let first_base = queried.add(BigInt.from_u64(seal)).add(BigInt.from_u64(181))
    let first = NormativeArithmetic.save(first_base.square().add(next_value.mul(BigInt.from_u64(179))).add(BigInt.from_u64(seal)))?
    let direction_base = first.add(BigInt.from_u64(seal)).add(BigInt.from_u64(1)).add(BigInt.from_u64(193))
    let direction_number = NormativeArithmetic.save(
      direction_base.square()
        .add(first.mul(BigInt.from_u64(193)))
        .add(result.bowls(5)?.mul(BigInt.from_u64(197))))?
    let parity = direction_number.regular_mod(BigInt.from_u64(2))?.to_usize()?
    let step: I8 = if parity == 1 then 1 else -1 end
    AnswerStream(first, step)

  fun answer_at(stream: AnswerStream, k: BigInt box): BigInt ? =>
    let signed_k = if stream.direction_step == 1 then k.abs() else k.abs().neg() end
    stream.first.sub(BigInt.from_u64(1)).add(signed_k).regular_mod(NormativeConstants.m())?.add(BigInt.from_u64(1))

primitive NormativeSelection
  fun choose_short(stream: AnswerStream, n: BigInt box): BigInt ? =>
    let m = NormativeConstants.m()
    if n.lt(BigInt.from_u64(1)) or n.gt(m) then error end
    let limit = m.floor_div(n)?.mul(n)
    var k = BigInt.from_u64(0)
    while true do
      let x = NormativeAnswers.answer_at(stream, k)?
      if x.lte(limit) then
        return x.sub(BigInt.from_u64(1)).regular_mod(n)?.add(BigInt.from_u64(1))
      end
      k = k.add(BigInt.from_u64(1))
    end
    error

  fun choose_wide(stream: AnswerStream, n: BigInt box): BigInt ? =>
    let m = NormativeConstants.m()
    if n.lte(m) then error end
    var places: USize = 1
    var space = m
    while space.lt(n) do
      places = places + 1
      space = space.mul(m)
    end
    var wide = BigInt.from_u64(1)
    var weight = BigInt.from_u64(1)
    var j: USize = 0
    while j < places do
      let digit = NormativeAnswers.answer_at(stream, BigInt.from_usize(j))?.sub(BigInt.from_u64(1))
      wide = wide.add(digit.mul(weight))
      weight = weight.mul(m)
      j = j + 1
    end
    let limit = space.floor_div(n)?.mul(n)
    while wide.gt(limit) do
      let step = if stream.direction_step == 1 then BigInt.from_u64(1) else BigInt.from_u64(1).neg() end
      wide = wide.sub(BigInt.from_u64(1)).add(step).regular_mod(space)?.add(BigInt.from_u64(1))
    end
    wide.sub(BigInt.from_u64(1)).regular_mod(n)?.add(BigInt.from_u64(1))

  fun choose(stream: AnswerStream, n: BigInt box): BigInt ? =>
    if n.lte(NormativeConstants.m()) then choose_short(stream, n)? else choose_wide(stream, n)? end
