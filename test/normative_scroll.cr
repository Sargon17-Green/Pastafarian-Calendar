require "big"
require "../src/source_language_catalog"

module NormativeScroll
  M = BigInt.new("170141183460469231731687303715884105727")
  TABLETS_DAY = BigInt.new(-278522)
  FOUNDATION_DAY = BigInt.new(-15055671)
  GATE_GAP_MIN = 42
  GATE_GAP_MAX = 963
  YEAR_MIN_DAYS = 252
  YEAR_MAX_DAYS = 5778
  MIN_CUTLETS = 6
  MAX_CUTLETS = 17
  MIN_MONTHS = 3
  MAX_MONTHS = 47
  MIN_MONTH_DAYS = 4
  MAX_MONTH_DAYS = 123

  SEAL_GATE_GAP = 1
  SEAL_YEAR_5000 = 10
  SEAL_NEXT_YEAR = 11
  SEAL_PREVIOUS_YEAR = 12
  SEAL_CUTLET_COUNT = 20
  SEAL_CUTLET_PARTITION = 21
  SEAL_CUTLET_NAMES = 22
  SEAL_MONTH_COUNT = 30
  SEAL_MONTH_LENGTHS = 31
  SEAL_MONTH_WEAVING = 32
  SEAL_MONTH_NAMES = 33

  WHEAT = 0
  BARLEY = 1
  SALT = 2
  BITTER = 3
  RED = 4

  record WorkCounts,
    action : BigInt,
    target : BigInt,
    distance : BigInt,
    connection : BigInt,
    direction : BigInt

  record SauceResult,
    bowls : Array(BigInt),
    order_at_drop_46 : Array(Int32)

  record AnswerStream,
    first : BigInt,
    direction_step : Int32

  record Year,
    number : BigInt,
    open_gate_index : BigInt,
    close_gate_index : BigInt,
    open_gate_day : BigInt,
    close_gate_day : BigInt

  record Cutlet,
    canonical_index : Int32,
    open_gate_index : BigInt,
    close_gate_index : BigInt,
    first_day : BigInt,
    last_day : BigInt

  record YearStructure,
    cutlet_count : Int32,
    cutlet_partition : Array(Int32),
    cutlet_indices : Array(Int32),
    cutlets : Array(Cutlet),
    month_count : Int32,
    month_lengths : Array(Int32),
    month_weaving : Array(Int32),
    month_indices : Array(Int32)

  def self.regular_mod(x : BigInt, d : BigInt) : BigInt
    raise ArgumentError.new("E_MODULUS") if d <= 0
    r = x % d
    r += d if r < 0
    r
  end

  def self.save(x : BigInt) : BigInt
    BigInt.new(1) + regular_mod(x - 1, M)
  end

  def self.wrap1(position : Int32, size : Int32) : Int32
    ((position - 1) % size + size) % size + 1
  end

  def self.ceil_div(a : Int32, b : Int32) : Int32
    raise ArgumentError.new("E_CEIL_DIV") if a < 0 || b < 1
    (a + b - 1) // b
  end

  def self.day_count(day : BigInt) : BigInt
    return BigInt.new(1) if day == FOUNDATION_DAY
    if day > FOUNDATION_DAY
      BigInt.new(2) * (day - FOUNDATION_DAY) + 1
    else
      BigInt.new(2) * (FOUNDATION_DAY - day)
    end
  end

  def self.work_counts(calculation_day : BigInt, target_day : BigInt) : WorkCounts
    c = day_count(calculation_day)
    t = day_count(target_day)
    distance = (target_day - calculation_day).abs + 1
    connection = c + t
    direction = if target_day < calculation_day
                  BigInt.new(1)
                elsif target_day == calculation_day
                  BigInt.new(2)
                else
                  BigInt.new(3)
                end
    WorkCounts.new(c, t, distance, connection, direction)
  end

  def self.build_stones : Array(Array(BigInt))
    stones = Array(Array(BigInt)).new(46) { Array(BigInt).new(5, BigInt.new(0)) }
    stones[0] = [17, 29, 43, 71, 101].map { |x| BigInt.new(x) }
    i = 2
    while i <= 46
      old = stones[i - 2]
      ib = BigInt.new(i)
      next_wheat = save(old[WHEAT] * old[WHEAT] + 3 * old[BARLEY] + ib)
      next_barley = save(old[BARLEY] * old[BARLEY] + 5 * old[SALT] + old[WHEAT])
      next_salt = save(old[SALT] * old[SALT] + 7 * old[BITTER] + old[BARLEY])
      next_bitter = save(old[BITTER] * old[BITTER] + 11 * old[RED] + old[SALT])
      next_red = save(old[RED] * old[RED] + 13 * old[WHEAT] + old[BITTER])
      stones[i - 1] = [next_wheat, next_barley, next_salt, next_bitter, next_red]
      i += 1
    end
    stones
  end

  STONES = build_stones

  HIDDEN_COEFF = [
    [3, 4, 6, 8],
    [5, 7, 10, 12],
    [7, 10, 14, 16],
    [9, 13, 18, 20],
    [11, 16, 22, 24],
    [13, 19, 26, 28],
    [15, 22, 30, 32],
  ]

  HIDDEN_GRIND_STONE = [WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY]

  VISIBLE_GRINDS = [
    {3, 5, 7, 11, WHEAT},
    {5, 7, 11, 13, BARLEY},
    {7, 11, 13, 17, SALT},
    {11, 13, 17, 19, BITTER},
    {13, 17, 19, 23, RED},
    {17, 19, 23, 29, WHEAT},
    {19, 23, 29, 31, BARLEY},
    {23, 29, 31, 37, SALT},
    {29, 31, 37, 41, BITTER},
    {31, 37, 41, 43, RED},
    {37, 41, 43, 47, WHEAT},
  ]

  BOWL_PRIME = [17, 19, 23, 29, 31, 37]
  BOWL_STIR_STONE_BY_POSITION = [WHEAT, BARLEY, SALT, BITTER, RED, WHEAT]

  def self.build_hidden_drops(counts : WorkCounts, stones = STONES) : Array(BigInt)
    hidden = Array(BigInt).new(7, BigInt.new(0))
    k = 1
    while k <= 7
      a, b, c, d = HIDDEN_COEFF[k - 1]
      row = stones[k - 1]
      x = counts.action + a * counts.target + b * counts.distance + c * counts.connection + d * counts.direction
      row.each { |value| x += value }
      x = save(x)
      grind = 1
      while grind <= 7
        old_x = x
        x = save(old_x * old_x + 3 * old_x + row[HIDDEN_GRIND_STONE[grind - 1]] + grind)
        grind += 1
      end
      hidden[k - 1] = x
      k += 1
    end
    hidden
  end

  def self.build_visible_drops(counts : WorkCounts, stones = STONES, hidden = build_hidden_drops(counts, stones)) : Array(BigInt)
    timeline = Hash(Int32, BigInt).new
    k = 1
    while k <= 7
      timeline[1 - k] = hidden[k - 1]
      k += 1
    end
    visible = Array(BigInt).new(46, BigInt.new(0))
    i = 1
    while i <= 46
      prev1 = timeline[i - 1]
      prev3 = timeline[i - 3]
      prev7 = timeline[i - 7]
      row = stones[i - 1]
      x = save(
        row[WHEAT] * counts.action +
        row[BARLEY] * counts.target +
        row[SALT] * counts.distance +
        row[BITTER] * counts.connection +
        row[RED] * counts.direction +
        prev1 + 3 * prev3 + 5 * prev7 + i
      )
      grind = 0
      while grind < VISIBLE_GRINDS.size
        a, b, c, d, kind = VISIBLE_GRINDS[grind]
        old_x = x
        x = save(old_x * old_x + a * old_x + b * prev1 + c * prev3 + d * prev7 + row[kind])
        grind += 1
      end
      timeline[i] = x
      visible[i - 1] = x
      i += 1
    end
    visible
  end

  def self.factorial(n : Int32) : BigInt
    r = BigInt.new(1)
    i = 2
    while i <= n
      r *= i
      i += 1
    end
    r
  end

  def self.permutation_unrank1(rank1 : BigInt, items_ascending : Array(Int32)) : Array(Int32)
    raise ArgumentError.new("E_PERMUTATION_RANK") if rank1 < 1 || rank1 > factorial(items_ascending.size)
    rank0 = rank1 - 1
    remaining = items_ascending.dup
    result = [] of Int32
    slots_left = remaining.size
    while slots_left >= 1
      block = factorial(slots_left - 1)
      q = (rank0 // block).to_i
      rank0 = regular_mod(rank0, block)
      result << remaining.delete_at(q)
      slots_left -= 1
    end
    result
  end

  def self.bowl_order_from_number(order_number : BigInt) : Array(Int32)
    permutation_unrank1(order_number, [1, 2, 3, 4, 5, 6])
  end

  def self.bowl_order_from_drop(drop_value : BigInt) : Array(Int32)
    order_number = regular_mod(drop_value - 1, BigInt.new(720)) + 1
    bowl_order_from_number(order_number)
  end

  def self.initial_bowls(counts : WorkCounts) : Array(BigInt)
    bowls = Array(BigInt).new(6, BigInt.new(0))
    bowl_id = 1
    while bowl_id <= 6
      s = counts.action + counts.target * bowl_id + counts.distance + counts.connection + counts.direction + BOWL_PRIME[bowl_id - 1] ** 2
      bowls[bowl_id - 1] = save(s * s + bowl_id)
      bowl_id += 1
    end
    bowls
  end

  def self.apply_visible_drops_to_bowls(bowls : Array(BigInt), visible : Array(BigInt), stones = STONES) : Tuple(Array(BigInt), Array(Int32))
    order_at_drop_46 = [] of Int32
    i = 1
    while i <= 46
      drop = visible[i - 1]
      order = bowl_order_from_drop(drop)
      old = bowls.dup
      pour = Array(BigInt).new(6, BigInt.new(0))
      pour[0] = save(drop * drop + stones[i - 1][WHEAT] * old[order[0] - 1] + 3 * i)
      pour[1] = save(drop * drop + stones[i - 1][BARLEY] * old[order[1] - 1] + 5 * i)
      pour[2] = save(drop * drop + stones[i - 1][SALT] * old[order[2] - 1] + 7 * i)
      next_bowls = Array(BigInt).new(6, BigInt.new(0))
      position = 1
      while position <= 6
        bowl_id = order[position - 1]
        prev_id = order[wrap1(position - 1, 6) - 1]
        next_id = order[wrap1(position + 1, 6) - 1]
        stone_kind = BOWL_STIR_STONE_BY_POSITION[position - 1]
        s = old[bowl_id - 1] + 2 * old[prev_id - 1] + 3 * old[next_id - 1] + pour[position - 1] + drop + stones[i - 1][stone_kind]
        next_bowls[bowl_id - 1] = save(s * s + 5 * old[prev_id - 1] * old[next_id - 1] + i * position)
        position += 1
      end
      bowls = next_bowls
      order_at_drop_46 = order.dup if i == 46
      i += 1
    end
    {bowls, order_at_drop_46}
  end

  def self.post_stir12(bowls : Array(BigInt)) : Array(BigInt)
    stir = 1
    while stir <= 12
      old = bowls.dup
      saved_stir_sum = save(old.reduce(BigInt.new(0)) { |sum, value| sum + value } + 149 * stir)
      order_number = regular_mod(saved_stir_sum - 1, BigInt.new(720)) + 1
      order = bowl_order_from_number(order_number)
      next_bowls = Array(BigInt).new(6, BigInt.new(0))
      position = 1
      while position <= 6
        bowl_id = order[position - 1]
        prev_id = order[wrap1(position - 1, 6) - 1]
        next_id = order[wrap1(position + 1, 6) - 1]
        s = old[bowl_id - 1] + 3 * old[prev_id - 1] + 5 * old[next_id - 1] + saved_stir_sum + stir + position * position
        next_bowls[bowl_id - 1] = save(s * s + 7 * old[prev_id - 1] * old[next_id - 1])
        position += 1
      end
      bowls = next_bowls
      stir += 1
    end
    bowls
  end

  def self.sauce(calculation_day : BigInt, target_day : BigInt) : SauceResult
    counts = work_counts(calculation_day, target_day)
    hidden = build_hidden_drops(counts)
    visible = build_visible_drops(counts, STONES, hidden)
    bowls = initial_bowls(counts)
    bowls_after_drops, order_at_drop_46 = apply_visible_drops_to_bowls(bowls, visible)
    SauceResult.new(post_stir12(bowls_after_drops), order_at_drop_46)
  end

  def self.next_bowl_in_drop46_order(result : SauceResult, queried_bowl_id : Int32) : Int32
    p = result.order_at_drop_46.index(queried_bowl_id)
    raise ArgumentError.new("E_BOWL_ID") unless p
    result.order_at_drop_46[(p + 1) % 6]
  end

  def self.ask_bowl(result : SauceResult, queried_bowl_id : Int32, seal : Int32) : AnswerStream
    next_id = next_bowl_in_drop46_order(result, queried_bowl_id)
    first = save((result.bowls[queried_bowl_id - 1] + seal + 181) ** 2 + 179 * result.bowls[next_id - 1] + seal)
    direction_number = save((first + seal + 1 + 193) ** 2 + 193 * first + 197 * result.bowls[5])
    step = regular_mod(direction_number, BigInt.new(2)) == 1 ? 1 : -1
    AnswerStream.new(first, step)
  end

  def self.answer_at(stream : AnswerStream, k : BigInt) : BigInt
    BigInt.new(1) + regular_mod(stream.first - 1 + stream.direction_step * k, M)
  end

  def self.choose_rank_short(stream : AnswerStream, n : BigInt) : BigInt
    raise ArgumentError.new("E_SHORT_N") if n < 1 || n > M
    acceptance_limit = (M // n) * n
    k = BigInt.new(0)
    loop do
      x = answer_at(stream, k)
      return regular_mod(x - 1, n) + 1 if x <= acceptance_limit
      k += 1
    end
  end

  def self.smallest_power_count(base : BigInt, n : BigInt) : Tuple(Int32, BigInt)
    k = 1
    space = base
    while space < n
      k += 1
      space *= base
    end
    {k, space}
  end

  def self.choose_rank_wide(stream : AnswerStream, n : BigInt) : BigInt
    raise ArgumentError.new("E_WIDE_N") if n <= M
    k, space = smallest_power_count(M, n)
    wide = BigInt.new(1)
    weight = BigInt.new(1)
    j = 0
    while j < k
      wide += (answer_at(stream, BigInt.new(j)) - 1) * weight
      weight *= M
      j += 1
    end
    acceptance_limit = (space // n) * n
    loop do
      return regular_mod(wide - 1, n) + 1 if wide <= acceptance_limit
      wide = BigInt.new(1) + regular_mod(wide - 1 + stream.direction_step, space)
    end
  end

  def self.choose_rank(stream : AnswerStream, n : BigInt) : BigInt
    raise ArgumentError.new("E_CHOOSE_N") if n < 1
    n <= M ? choose_rank_short(stream, n) : choose_rank_wide(stream, n)
  end

  def self.falling_factorial(n : Int32, k : Int32) : BigInt
    raise ArgumentError.new("E_FALLING_FACTORIAL") if k < 0 || k > n
    r = BigInt.new(1)
    j = 0
    while j < k
      r *= (n - j)
      j += 1
    end
    r
  end

  def self.unrank_distinct_indices(master_size : Int32, k : Int32, rank1 : BigInt) : Array(Int32)
    total = falling_factorial(master_size, k)
    raise ArgumentError.new("E_DISTINCT_RANK") if rank1 < 1 || rank1 > total
    remaining = (1..master_size).to_a
    out = [] of Int32
    r = rank1
    position = 1
    while position <= k
      suffix_length = k - position
      block = falling_factorial(remaining.size - 1, suffix_length)
      candidate = 0
      while candidate < remaining.size
        if r > block
          r -= block
        else
          out << remaining.delete_at(candidate)
          break
        end
        candidate += 1
      end
      position += 1
    end
    out
  end

  class BoundedCompositionFamily
    getter total : Int32
    getter slots : Int32
    getter lo : Int32
    getter hi : Int32

    def initialize(@total : Int32, @slots : Int32, @lo : Int32, @hi : Int32)
      @memo = Hash(Tuple(Int32, Int32), BigInt).new
    end

    def count_suffix(rem : Int32, k : Int32) : BigInt
      return rem == 0 ? BigInt.new(1) : BigInt.new(0) if k == 0
      return BigInt.new(0) if rem < k * @lo || rem > k * @hi
      key = {rem, k}
      cached = @memo[key]?
      return cached if cached
      s = BigInt.new(0)
      x = @lo
      while x <= @hi
        s += count_suffix(rem - x, k - 1)
        x += 1
      end
      @memo[key] = s
      s
    end

    def count : BigInt
      count_suffix(@total, @slots)
    end

    def unrank1(rank1 : BigInt) : Array(Int32)
      raise ArgumentError.new("E_COMPOSITION_RANK") if rank1 < 1 || rank1 > count
      r = rank1
      rem = @total
      out = [] of Int32
      position = 1
      while position <= @slots
        x = @lo
        while x <= @hi
          block = count_suffix(rem - x, @slots - position)
          if r > block
            r -= block
          else
            out << x
            rem -= x
            break
          end
          x += 1
        end
        position += 1
      end
      out
    end
  end

  class CutletPartitionFamily
    def initialize(@gaps : Int32, @slots : Int32, @required : Int32?)
      @memo = Hash(Tuple(Int32, Int32, Int32, Bool), BigInt).new
    end

    def count_state(rem : Int32, slots : Int32, cumulative : Int32, hit : Bool) : BigInt
      if slots == 0
        return BigInt.new(0) unless rem == 0
        return BigInt.new(1) if @required.nil?
        return hit ? BigInt.new(1) : BigInt.new(0)
      end
      return BigInt.new(0) if rem < slots
      key = {rem, slots, cumulative, hit}
      cached = @memo[key]?
      return cached if cached
      total = BigInt.new(0)
      max_x = rem - (slots - 1)
      x = 1
      while x <= max_x
        next_cumulative = cumulative + x
        next_hit = hit
        if required = @required
          unless hit
            if next_cumulative == required
              next_hit = true
            elsif next_cumulative > required
              x += 1
              next
            end
          end
        end
        total += count_state(rem - x, slots - 1, next_cumulative, next_hit)
        x += 1
      end
      @memo[key] = total
      total
    end

    def count : BigInt
      count_state(@gaps, @slots, 0, false)
    end

    def unrank1(rank1 : BigInt) : Array(Int32)
      raise ArgumentError.new("E_CUTLET_PARTITION_RANK") if rank1 < 1 || rank1 > count
      r = rank1
      rem = @gaps
      slots = @slots
      cumulative = 0
      hit = false
      out = [] of Int32
      while slots > 0
        max_x = rem - (slots - 1)
        x = 1
        while x <= max_x
          next_cumulative = cumulative + x
          next_hit = hit
          allowed = true
          if required = @required
            unless hit
              if next_cumulative == required
                next_hit = true
              elsif next_cumulative > required
                allowed = false
              end
            end
          end
          if allowed
            block = count_state(rem - x, slots - 1, next_cumulative, next_hit)
            if r > block
              r -= block
            else
              out << x
              rem -= x
              slots -= 1
              cumulative = next_cumulative
              hit = next_hit
              break
            end
          end
          x += 1
        end
      end
      out
    end
  end

  class WeavingFamily
    def initialize(@lengths : Array(Int32))
      @memo = Hash(String, BigInt).new
    end

    def key(remaining : Array(Int32), opened : Int32, closed : Int32) : String
      "#{remaining.join(',')}|#{opened}|#{closed}"
    end

    def legal?(remaining : Array(Int32), opened : Int32, closed : Int32, j : Int32) : Bool
      idx = j - 1
      return false if remaining[idx] == 0
      already_opened = remaining[idx] < @lengths[idx]
      return false if !already_opened && j != opened + 1
      will_close = remaining[idx] == 1
      return false if will_close && j != closed + 1
      true
    end

    def apply(remaining : Array(Int32), opened : Int32, closed : Int32, j : Int32) : Tuple(Array(Int32), Int32, Int32)
      next_remaining = remaining.dup
      next_opened = opened
      next_closed = closed
      idx = j - 1
      next_opened = j if next_remaining[idx] == @lengths[idx]
      next_remaining[idx] -= 1
      next_closed = j if next_remaining[idx] == 0
      {next_remaining, next_opened, next_closed}
    end

    def count_state(remaining : Array(Int32), opened : Int32, closed : Int32) : BigInt
      return BigInt.new(1) if remaining.all?(&.zero?)
      cache_key = key(remaining, opened, closed)
      cached = @memo[cache_key]?
      return cached if cached
      total = BigInt.new(0)
      j = 1
      while j <= @lengths.size
        if legal?(remaining, opened, closed, j)
          next_remaining, next_opened, next_closed = apply(remaining, opened, closed, j)
          total += count_state(next_remaining, next_opened, next_closed)
        end
        j += 1
      end
      @memo[cache_key] = total
      total
    end

    def count : BigInt
      count_state(@lengths.dup, 0, 0)
    end

    def unrank1(rank1 : BigInt) : Array(Int32)
      raise ArgumentError.new("E_WEAVING_RANK") if rank1 < 1 || rank1 > count
      remaining = @lengths.dup
      opened = 0
      closed = 0
      r = rank1
      out = [] of Int32
      target_length = @lengths.sum
      while out.size < target_length
        j = 1
        while j <= @lengths.size
          if legal?(remaining, opened, closed, j)
            next_remaining, next_opened, next_closed = apply(remaining, opened, closed, j)
            block = count_state(next_remaining, next_opened, next_closed)
            if r > block
              r -= block
            else
              out << j
              remaining = next_remaining
              opened = next_opened
              closed = next_closed
              break
            end
          end
          j += 1
        end
      end
      out
    end
  end

  class GateRegistry
    getter min_known_index : BigInt
    getter max_known_index : BigInt

    def initialize
      @gate = Hash(BigInt, BigInt).new
      zero = BigInt.new(0)
      @gate[zero] = FOUNDATION_DAY
      @min_known_index = zero
      @max_known_index = zero
    end

    def [](index : BigInt) : BigInt
      ensure_gate_index(index)
      @gate[index]
    end

    def positive_gap(n : BigInt) : BigInt
      result = NormativeScroll.sauce(FOUNDATION_DAY, FOUNDATION_DAY + n)
      stream = NormativeScroll.ask_bowl(result, 1, SEAL_GATE_GAP)
      BigInt.new(41) + NormativeScroll.choose_rank(stream, BigInt.new(922))
    end

    def negative_gap(n : BigInt) : BigInt
      result = NormativeScroll.sauce(FOUNDATION_DAY, FOUNDATION_DAY - n)
      stream = NormativeScroll.ask_bowl(result, 1, SEAL_GATE_GAP)
      BigInt.new(41) + NormativeScroll.choose_rank(stream, BigInt.new(922))
    end

    def ensure_gate_index(k : BigInt) : BigInt
      if k > @max_known_index
        n = @max_known_index + 1
        while n <= k
          @gate[n] = @gate[n - 1] + positive_gap(n)
          @max_known_index = n
          n += 1
        end
      end
      if k < @min_known_index
        n = @min_known_index - 1
        while n >= k
          @gate[n] = @gate[n + 1] - negative_gap(n.abs)
          @min_known_index = n
          n -= 1
        end
      end
      @gate[k]
    end

    def ensure_cover(low_day : BigInt, high_day : BigInt)
      raise ArgumentError.new("E_GATE_RANGE") if low_day > high_day
      while @gate[@min_known_index] > low_day
        ensure_gate_index(@min_known_index - 1)
      end
      while @gate[@max_known_index] < high_day
        ensure_gate_index(@max_known_index + 1)
      end
    end

    def gate_index_at_or_before(day : BigInt) : BigInt
      ensure_cover(day, day)
      lo = @min_known_index
      hi = @max_known_index
      while lo < hi
        mid = lo + ((hi - lo + 1) // 2)
        if @gate[mid] <= day
          lo = mid
        else
          hi = mid - 1
        end
      end
      lo
    end

    def exact_gate_index(day : BigInt) : BigInt?
      i = gate_index_at_or_before(day)
      @gate[i] == day ? i : nil
    end
  end

  class CalendarOracle
    getter gates : GateRegistry

    def initialize
      @gates = GateRegistry.new
    end

    def valid_year_pair(open_index : BigInt, close_index : BigInt) : Bool
      return false if close_index - open_index < 6
      length = @gates[close_index] - @gates[open_index]
      length >= YEAR_MIN_DAYS && length <= YEAR_MAX_DAYS
    end

    def make_year(number : BigInt, open_index : BigInt, close_index : BigInt) : Year
      Year.new(number, open_index, close_index, @gates[open_index], @gates[close_index])
    end

    def year5000(calculation_day : BigInt) : Year
      @gates.ensure_cover(calculation_day - YEAR_MAX_DAYS, calculation_day + YEAR_MAX_DAYS)
      candidates = [] of Tuple(BigInt, BigInt)
      i = @gates.min_known_index
      while i < @gates.max_known_index
        j = i + 1
        while j <= @gates.max_known_index
          if valid_year_pair(i, j) && @gates[i] < calculation_day && calculation_day <= @gates[j]
            candidates << {i, j}
          end
          j += 1
        end
        i += 1
      end
      candidates.sort_by! { |pair| {@gates[pair[1]] - @gates[pair[0]], @gates[pair[0]]} }
      raise "E_NO_YEAR_5000" if candidates.empty?
      result = NormativeScroll.sauce(calculation_day, calculation_day)
      stream = NormativeScroll.ask_bowl(result, 1, SEAL_YEAR_5000)
      rank = NormativeScroll.choose_rank(stream, BigInt.new(candidates.size)).to_i
      pair = candidates[rank - 1]
      make_year(BigInt.new(5000), pair[0], pair[1])
    end

    def next_year(calculation_day : BigInt, known : Year) : Year
      open_index = known.close_gate_index
      candidates = [] of BigInt
      close_index = open_index + 1
      loop do
        gap = @gates[close_index] - @gates[open_index]
        break if gap > YEAR_MAX_DAYS
        candidates << close_index if valid_year_pair(open_index, close_index)
        close_index += 1
      end
      candidates.sort_by! { |idx| @gates[idx] - @gates[open_index] }
      result = NormativeScroll.sauce(calculation_day, @gates[open_index])
      stream = NormativeScroll.ask_bowl(result, 1, SEAL_NEXT_YEAR)
      rank = NormativeScroll.choose_rank(stream, BigInt.new(candidates.size)).to_i
      make_year(known.number + 1, open_index, candidates[rank - 1])
    end

    def previous_year(calculation_day : BigInt, known : Year) : Year
      close_index = known.open_gate_index
      candidates = [] of BigInt
      open_index = close_index - 1
      loop do
        gap = @gates[close_index] - @gates[open_index]
        break if gap > YEAR_MAX_DAYS
        candidates << open_index if valid_year_pair(open_index, close_index)
        open_index -= 1
      end
      candidates.sort_by! { |idx| @gates[close_index] - @gates[idx] }
      result = NormativeScroll.sauce(calculation_day, @gates[close_index])
      stream = NormativeScroll.ask_bowl(result, 1, SEAL_PREVIOUS_YEAR)
      rank = NormativeScroll.choose_rank(stream, BigInt.new(candidates.size)).to_i
      make_year(known.number - 1, candidates[rank - 1], close_index)
    end

    def find_target_year(calculation_day : BigInt, target_day : BigInt) : Year
      year = year5000(calculation_day)
      while target_day > year.close_gate_day
        year = next_year(calculation_day, year)
      end
      while target_day <= year.open_gate_day
        year = previous_year(calculation_day, year)
      end
      year
    end

    def choose_cutlet_count(structure_sauce : SauceResult, year : Year) : Int32
      gaps = (year.close_gate_index - year.open_gate_index).to_i
      candidates = [] of Int32
      k = MIN_CUTLETS
      while k <= MAX_CUTLETS
        candidates << k if k <= gaps
        k += 1
      end
      stream = NormativeScroll.ask_bowl(structure_sauce, 2, SEAL_CUTLET_COUNT)
      rank = NormativeScroll.choose_rank(stream, BigInt.new(candidates.size)).to_i
      candidates[rank - 1]
    end

    def choose_cutlet_partition(calculation_day : BigInt, structure_sauce : SauceResult, year : Year, cutlet_count : Int32) : Array(Int32)
      gaps = (year.close_gate_index - year.open_gate_index).to_i
      required = nil.as(Int32?)
      if exact = @gates.exact_gate_index(calculation_day)
        if year.open_gate_index < exact && exact < year.close_gate_index
          required = (exact - year.open_gate_index).to_i
        end
      end
      family = CutletPartitionFamily.new(gaps, cutlet_count, required)
      stream = NormativeScroll.ask_bowl(structure_sauce, 2, SEAL_CUTLET_PARTITION)
      rank = NormativeScroll.choose_rank(stream, family.count)
      family.unrank1(rank)
    end

    def choose_cutlet_indices(structure_sauce : SauceResult, cutlet_count : Int32) : Array(Int32)
      n = NormativeScroll.falling_factorial(17, cutlet_count)
      stream = NormativeScroll.ask_bowl(structure_sauce, 5, SEAL_CUTLET_NAMES)
      rank = NormativeScroll.choose_rank(stream, n)
      NormativeScroll.unrank_distinct_indices(17, cutlet_count, rank)
    end

    def materialize_cutlets(year : Year, partition : Array(Int32), indices : Array(Int32)) : Array(Cutlet)
      cursor = year.open_gate_index
      cutlets = [] of Cutlet
      partition.each_with_index do |gaps, idx|
        close_index = cursor + gaps
        cutlets << Cutlet.new(indices[idx], cursor, close_index, @gates[cursor] + 1, @gates[close_index])
        cursor = close_index
      end
      cutlets
    end

    def choose_month_count(structure_sauce : SauceResult, year : Year) : Int32
      length = (year.close_gate_day - year.open_gate_day).to_i
      min_months = NormativeScroll.ceil_div(length, MAX_MONTH_DAYS)
      max_months = Math.min(MAX_MONTHS, length // MIN_MONTH_DAYS)
      raise "E_MONTH_BOUNDS" unless MIN_MONTHS <= min_months && min_months <= max_months && max_months <= MAX_MONTHS
      stream = NormativeScroll.ask_bowl(structure_sauce, 3, SEAL_MONTH_COUNT)
      rank = NormativeScroll.choose_rank(stream, BigInt.new(max_months - min_months + 1)).to_i
      min_months + rank - 1
    end

    def choose_month_lengths(structure_sauce : SauceResult, year : Year, month_count : Int32) : Array(Int32)
      length = (year.close_gate_day - year.open_gate_day).to_i
      family = BoundedCompositionFamily.new(length, month_count, MIN_MONTH_DAYS, MAX_MONTH_DAYS)
      stream = NormativeScroll.ask_bowl(structure_sauce, 3, SEAL_MONTH_LENGTHS)
      rank = NormativeScroll.choose_rank(stream, family.count)
      family.unrank1(rank)
    end

    def choose_month_weaving(structure_sauce : SauceResult, lengths : Array(Int32)) : Array(Int32)
      family = WeavingFamily.new(lengths)
      stream = NormativeScroll.ask_bowl(structure_sauce, 4, SEAL_MONTH_WEAVING)
      rank = NormativeScroll.choose_rank(stream, family.count)
      family.unrank1(rank)
    end

    def choose_month_indices(structure_sauce : SauceResult, month_count : Int32) : Array(Int32)
      n = NormativeScroll.falling_factorial(47, month_count)
      stream = NormativeScroll.ask_bowl(structure_sauce, 5, SEAL_MONTH_NAMES)
      rank = NormativeScroll.choose_rank(stream, n)
      NormativeScroll.unrank_distinct_indices(47, month_count, rank)
    end

    def build_year_structure(calculation_day : BigInt, year : Year) : YearStructure
      first_day = year.open_gate_day + 1
      structure_sauce = NormativeScroll.sauce(calculation_day, first_day)
      cutlet_count = choose_cutlet_count(structure_sauce, year)
      partition = choose_cutlet_partition(calculation_day, structure_sauce, year, cutlet_count)
      cutlet_indices = choose_cutlet_indices(structure_sauce, cutlet_count)
      cutlets = materialize_cutlets(year, partition, cutlet_indices)
      month_count = choose_month_count(structure_sauce, year)
      month_lengths = choose_month_lengths(structure_sauce, year, month_count)
      weaving = choose_month_weaving(structure_sauce, month_lengths)
      month_indices = choose_month_indices(structure_sauce, month_count)
      YearStructure.new(cutlet_count, partition, cutlet_indices, cutlets, month_count, month_lengths, weaving, month_indices)
    end

    def calendar_date(calculation_day : BigInt, target_day : BigInt) : Tuple(BigInt, String, BigInt, String, Int32)
      year = find_target_year(calculation_day, target_day)
      structure = build_year_structure(calculation_day, year)
      chosen = structure.cutlets.find { |cutlet| cutlet.first_day <= target_day && target_day <= cutlet.last_day }
      raise "E_CUTLET_NOT_FOUND" unless chosen
      day_in_cutlet = target_day - chosen.first_day + 1
      year_offset0 = (target_day - (year.open_gate_day + 1)).to_i
      month_id = structure.month_weaving[year_offset0]
      month_name_index = structure.month_indices[month_id - 1]
      day_in_month = 0
      p = 0
      while p <= year_offset0
        day_in_month += 1 if structure.month_weaving[p] == month_id
        p += 1
      end
      {
        year.number,
        PastafarianCalendar::SourceLanguageCatalog.cutlet(chosen.canonical_index),
        day_in_cutlet,
        PastafarianCalendar::SourceLanguageCatalog.month(month_name_index),
        day_in_month,
      }
    end
  end
end
