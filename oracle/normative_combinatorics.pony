use "../src"
use "collections"

primitive NormativeNames
  fun falling_factorial(n: USize, k: USize): BigInt =>
    var r = BigInt.from_u64(1)
    var j: USize = 0
    while j < k do
      r = r.mul(BigInt.from_usize(n - j))
      j = j + 1
    end
    r

  fun unrank_distinct(master_size: USize, k: USize, rank1: BigInt box): Array[USize] ? =>
    if k > master_size then error end
    let remaining = Array[USize](master_size)
    var i: USize = 1
    while i <= master_size do
      remaining.push(i)
      i = i + 1
    end
    let out = Array[USize](k)
    var r = BigInt.from_parts(false, rank1.string())
    var position: USize = 1
    while position <= k do
      let suffix_length = k - position
      let block = falling_factorial(remaining.size() - 1, suffix_length)
      var candidate: USize = 0
      var selected = false
      while candidate < remaining.size() do
        if r.gt(block) then
          r = r.sub(block)
        else
          out.push(remaining(candidate)?)
          remaining.delete(candidate)?
          selected = true
          break
        end
        candidate = candidate + 1
      end
      if not selected then error end
      position = position + 1
    end
    out

class BoundedCompositionCounter
  let total: USize
  let slots: USize
  let lo: USize
  let hi: USize
  let memo: Map[String, BigInt] = Map[String, BigInt]

  new create(total': USize, slots': USize, lo': USize, hi': USize) =>
    total = total'
    slots = slots'
    lo = lo'
    hi = hi'

  fun _key(rem: I64, k: USize): String =>
    rem.string() + ":" + k.string()

  fun ref count_suffix(rem: I64, k: USize): BigInt =>
    if k == 0 then
      if rem == 0 then BigInt.from_u64(1) else BigInt.from_u64(0) end
    else if (rem < (k * lo).i64()) or (rem > (k * hi).i64()) then
      BigInt.from_u64(0)
    else
      let key = _key(rem, k)
      try
        memo(key)?
      else
        var s = BigInt.from_u64(0)
        var x = lo
        while x <= hi do
          s = s.add(count_suffix(rem - x.i64(), k - 1))
          if x == hi then break end
          x = x + 1
        end
        memo(key) = s
        s
      end
    end

  fun ref count_all(): BigInt => count_suffix(total.i64(), slots)

  fun ref unrank1(rank1: BigInt box): Array[USize] ? =>
    let count = count_all()
    if rank1.lt(BigInt.from_u64(1)) or rank1.gt(count) then error end
    var r = BigInt.from_parts(false, rank1.string())
    var rem = total.i64()
    var position: USize = 1
    let out = Array[USize](slots)
    while position <= slots do
      var x = lo
      var selected = false
      while x <= hi do
        let block = count_suffix(rem - x.i64(), slots - position)
        if r.gt(block) then
          r = r.sub(block)
        else
          out.push(x)
          rem = rem - x.i64()
          selected = true
          break
        end
        if x == hi then break end
        x = x + 1
      end
      if not selected then error end
      position = position + 1
    end
    out

class CutletPartitionCounter
  let gaps: USize
  let parts: USize
  let required: (USize | None)
  let memo: Map[String, BigInt] = Map[String, BigInt]

  new create(gaps': USize, parts': USize, required': (USize | None)) =>
    gaps = gaps'
    parts = parts'
    required = required'

  fun _key(rem: USize, slots: USize, cumulative: USize, hit: Bool): String =>
    rem.string() + ":" + slots.string() + ":" + cumulative.string() + ":" + (if hit then "1" else "0" end)

  fun ref count_state(rem: USize, slots: USize, cumulative: USize, hit: Bool): BigInt =>
    if slots == 0 then
      if rem != 0 then
        BigInt.from_u64(0)
      else
        match required
        | None => BigInt.from_u64(1)
        | let _: USize => if hit then BigInt.from_u64(1) else BigInt.from_u64(0) end
        end
      end
    else if rem < slots then
      BigInt.from_u64(0)
    else
      let key = _key(rem, slots, cumulative, hit)
      try
        memo(key)?
      else
        var total = BigInt.from_u64(0)
        let max_x = rem - (slots - 1)
        var x: USize = 1
        while x <= max_x do
          let next_cumulative = cumulative + x
          var allowed = true
          var next_hit = hit
          match required
          | let boundary: USize =>
            if not hit then
              if next_cumulative == boundary then
                next_hit = true
              else if next_cumulative > boundary then
                allowed = false
              end
            end
          | None => None
          end
          if allowed then
            total = total.add(count_state(rem - x, slots - 1, next_cumulative, next_hit))
          end
          if x == max_x then break end
          x = x + 1
        end
        memo(key) = total
        total
      end
    end

  fun ref count_all(): BigInt => count_state(gaps, parts, 0, false)

  fun ref unrank1(rank1: BigInt box): Array[USize] ? =>
    if rank1.lt(BigInt.from_u64(1)) or rank1.gt(count_all()) then error end
    var r = BigInt.from_parts(false, rank1.string())
    var rem = gaps
    var slots_left = parts
    var cumulative: USize = 0
    var hit = false
    let out = Array[USize](parts)
    while slots_left > 0 do
      let max_x = rem - (slots_left - 1)
      var x: USize = 1
      var selected = false
      while x <= max_x do
        let next_cumulative = cumulative + x
        var allowed = true
        var next_hit = hit
        match required
        | let boundary: USize =>
          if not hit then
            if next_cumulative == boundary then
              next_hit = true
            else if next_cumulative > boundary then
              allowed = false
            end
          end
        | None => None
        end
        if allowed then
          let block = count_state(rem - x, slots_left - 1, next_cumulative, next_hit)
          if r.gt(block) then
            r = r.sub(block)
          else
            out.push(x)
            rem = rem - x
            slots_left = slots_left - 1
            cumulative = next_cumulative
            hit = next_hit
            selected = true
            break
          end
        end
        if x == max_x then break end
        x = x + 1
      end
      if not selected then error end
    end
    out

class WeaveState
  let remaining: Array[USize]
  let opened_up_to: USize
  let closed_up_to: USize

  new create(remaining': Array[USize], opened': USize, closed': USize) =>
    remaining = remaining'
    opened_up_to = opened'
    closed_up_to = closed'

class WeavingCounter
  let lengths: Array[USize]
  let memo: Map[String, BigInt] = Map[String, BigInt]

  new create(lengths': Array[USize]) =>
    lengths = lengths'.clone()

  fun sum_lengths(): USize =>
    var s: USize = 0
    for x in lengths.values() do s = s + x end
    s

  fun _key(state: WeaveState): String val =>
    var out: String val = state.opened_up_to.string() + ":" + state.closed_up_to.string() + ":"
    for x in state.remaining.values() do
      out = out + x.string() + ","
    end
    out

  fun legal(state: WeaveState, j: USize): Bool =>
    if (j < 1) or (j > lengths.size()) then return false end
    let idx = j - 1
    let rem = try state.remaining(idx)? else return false end
    if rem == 0 then return false end
    let original = try lengths(idx)? else return false end
    let already_opened = rem < original
    if (not already_opened) and (j != (state.opened_up_to + 1)) then return false end
    let will_close = rem == 1
    if will_close and (j != (state.closed_up_to + 1)) then return false end
    true

  fun apply_move(state: WeaveState, j: USize): WeaveState ? =>
    if not legal(state, j) then error end
    let next_remaining = state.remaining.clone()
    let idx = j - 1
    let original = lengths(idx)?
    let before = next_remaining(idx)?
    var opened = state.opened_up_to
    var closed = state.closed_up_to
    if before == original then opened = j end
    next_remaining.update(idx, before - 1)?
    if (before - 1) == 0 then closed = j end
    WeaveState(next_remaining, opened, closed)

  fun ref count_state(state: WeaveState): BigInt ? =>
    var done = true
    for x in state.remaining.values() do
      if x != 0 then done = false; break end
    end
    if done then return BigInt.from_u64(1) end
    let key = _key(state)
    try
      memo(key)?
    else
      var total = BigInt.from_u64(0)
      var j: USize = 1
      while j <= lengths.size() do
        if legal(state, j) then
          total = total.add(count_state(apply_move(state, j)?)?)
        end
        j = j + 1
      end
      memo(key) = total
      total
    end

  fun initial_state(): WeaveState => WeaveState(lengths.clone(), 0, 0)

  fun ref count_all(): BigInt ? => count_state(initial_state())?

  fun ref unrank1(rank1: BigInt box): Array[USize] ? =>
    let total = count_all()?
    if rank1.lt(BigInt.from_u64(1)) or rank1.gt(total) then error end
    var state = initial_state()
    var r = BigInt.from_parts(false, rank1.string())
    let out = Array[USize](sum_lengths())
    while out.size() < sum_lengths() do
      var j: USize = 1
      var selected = false
      while j <= lengths.size() do
        if legal(state, j) then
          let next = apply_move(state, j)?
          let block = count_state(next)?
          if r.gt(block) then
            r = r.sub(block)
          else
            out.push(j)
            state = next
            selected = true
            break
          end
        end
        j = j + 1
      end
      if not selected then error end
    end
    out
