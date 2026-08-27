defmodule PastafariCalendarElixirVietnamese.TestOnly.NormativeReference do
  import Bitwise
  @moduledoc false

  alias PastafariCalendarElixirVietnamese.SourceLanguageCatalog

  defmodule WorkCounts do
    defstruct [:action, :target, :distance, :connection, :direction]
  end

  defmodule SauceResult do
    defstruct [:bowls, :order_at_drop_46]
  end

  defmodule AnswerStream do
    defstruct [:first, :direction_step]
  end

  defmodule GateState do
    defstruct gate: %{0 => -15_055_671}, min_index: 0, max_index: 0
  end

  defmodule Year do
    defstruct [:number, :open_gate_index, :close_gate_index, :open_gate_day, :close_gate_day]
  end

  defmodule Cutlet do
    defstruct [:name_index, :open_gate_index, :close_gate_index, :first_day, :last_day]
  end

  defmodule YearStructure do
    defstruct [
      :cutlet_count,
      :cutlet_partition,
      :cutlet_name_indices,
      :cutlets,
      :month_count,
      :month_lengths,
      :month_weaving,
      :month_name_indices
    ]
  end

  @tablets_day -278_522
  @foundation_day -15_055_671
  @m (1 <<< 127) - 1
  @year_min_days 252
  @year_max_days 5_778

  @hidden_coeff %{
    1 => {3, 4, 6, 8},
    2 => {5, 7, 10, 12},
    3 => {7, 10, 14, 16},
    4 => {9, 13, 18, 20},
    5 => {11, 16, 22, 24},
    6 => {13, 19, 26, 28},
    7 => {15, 22, 30, 32}
  }

  @hidden_grind_stone [1, 2, 3, 4, 5, 1, 2]

  @visible_grinds [
    {3, 5, 7, 11, 1},
    {5, 7, 11, 13, 2},
    {7, 11, 13, 17, 3},
    {11, 13, 17, 19, 4},
    {13, 17, 19, 23, 5},
    {17, 19, 23, 29, 1},
    {19, 23, 29, 31, 2},
    {23, 29, 31, 37, 3},
    {29, 31, 37, 41, 4},
    {31, 37, 41, 43, 5},
    {37, 41, 43, 47, 1}
  ]

  @bowl_prime [17, 19, 23, 29, 31, 37]
  @bowl_stir_stone [1, 2, 3, 4, 5, 1]

  @seal_gate_gap 1
  @seal_year_5000 10
  @seal_next_year 11
  @seal_previous_year 12
  @seal_cutlet_count 20
  @seal_cutlet_partition 21
  @seal_cutlet_names 22
  @seal_month_count 30
  @seal_month_lengths 31
  @seal_month_weaving 32
  @seal_month_names 33

  def tablets_day, do: @tablets_day
  def foundation_day, do: @foundation_day
  def m, do: @m
  def year_max_days, do: @year_max_days

  def regular_mod(x, d) when is_integer(x) and is_integer(d) and d >= 1 do
    r = rem(x, d)
    if r < 0, do: r + d, else: r
  end

  def floor_div(a, b) when is_integer(a) and is_integer(b) and b >= 1 do
    q = div(a, b)
    r = rem(a, b)
    if r < 0, do: q - 1, else: q
  end

  def ceil_div(a, b) when is_integer(a) and a >= 0 and is_integer(b) and b >= 1 do
    floor_div(a + b - 1, b)
  end

  def save(x), do: 1 + regular_mod(x - 1, @m)
  def square(x), do: x * x
  def wrap1(position, size), do: regular_mod(position - 1, size) + 1

  def day_count(day) do
    cond do
      day == @foundation_day -> 1
      day > @foundation_day -> 2 * (day - @foundation_day) + 1
      true -> 2 * (@foundation_day - day)
    end
  end

  def work_counts(calculation_day, target_day) do
    c = day_count(calculation_day)
    t = day_count(target_day)

    direction =
      cond do
        target_day < calculation_day -> 1
        target_day == calculation_day -> 2
        true -> 3
      end

    %WorkCounts{
      action: c,
      target: t,
      distance: abs(target_day - calculation_day) + 1,
      connection: c + t,
      direction: direction
    }
  end

  def build_stones do
    Enum.reduce(2..46, %{1 => {17, 29, 43, 71, 101}}, fn i, table ->
      old = Map.fetch!(table, i - 1)
      w = elem(old, 0)
      b = elem(old, 1)
      s = elem(old, 2)
      m = elem(old, 3)
      r = elem(old, 4)

      next = {
        save(square(w) + 3 * b + i),
        save(square(b) + 5 * s + w),
        save(square(s) + 7 * m + b),
        save(square(m) + 11 * r + s),
        save(square(r) + 13 * w + m)
      }

      Map.put(table, i, next)
    end)
  end

  def stone_value(stones, i, kind) do
    stones |> Map.fetch!(i) |> elem(kind - 1)
  end

  def build_hidden_drops(counts, stones) do
    Enum.reduce(1..7, %{}, fn k, hidden ->
      {a, b, c, d} = Map.fetch!(@hidden_coeff, k)

      x0 =
        counts.action +
          a * counts.target +
          b * counts.distance +
          c * counts.connection +
          d * counts.direction +
          Enum.reduce(1..5, 0, fn kind, acc -> acc + stone_value(stones, k, kind) end)
        |> save()

      x =
        Enum.reduce(Enum.with_index(@hidden_grind_stone, 1), x0, fn {kind, grind}, old_x ->
          save(square(old_x) + 3 * old_x + stone_value(stones, k, kind) + grind)
        end)

      Map.put(hidden, k, x)
    end)
  end

  def seed_drop_timeline(hidden) do
    Enum.reduce(1..7, %{}, fn k, timeline ->
      Map.put(timeline, 1 - k, Map.fetch!(hidden, k))
    end)
  end

  def build_visible_drops(counts, stones, hidden) do
    timeline = seed_drop_timeline(hidden)

    final =
      Enum.reduce(1..46, timeline, fn i, store ->
        prev1 = Map.fetch!(store, i - 1)
        prev3 = Map.fetch!(store, i - 3)
        prev7 = Map.fetch!(store, i - 7)

        x0 =
          stone_value(stones, i, 1) * counts.action +
            stone_value(stones, i, 2) * counts.target +
            stone_value(stones, i, 3) * counts.distance +
            stone_value(stones, i, 4) * counts.connection +
            stone_value(stones, i, 5) * counts.direction +
            prev1 + 3 * prev3 + 5 * prev7 + i
          |> save()

        x =
          Enum.reduce(@visible_grinds, x0, fn {a, b, c, d, kind}, old_x ->
            save(
              square(old_x) + a * old_x + b * prev1 + c * prev3 + d * prev7 +
                stone_value(stones, i, kind)
            )
          end)

        Map.put(store, i, x)
      end)

    Map.new(1..46, fn i -> {i, Map.fetch!(final, i)} end)
  end

  def factorial(0), do: 1
  def factorial(n) when n > 0, do: Enum.reduce(1..n, 1, fn x, acc -> x * acc end)

  def permutation_unrank1(rank1, items) when rank1 >= 1 do
    permutation_unrank0(rank1 - 1, items, [])
  end

  defp permutation_unrank0(_rank0, [], acc), do: Enum.reverse(acc)

  defp permutation_unrank0(rank0, remaining, acc) do
    slots_left = length(remaining)
    block = factorial(slots_left - 1)
    q = div(rank0, block)
    next_rank = regular_mod(rank0, block)
    chosen = Enum.at(remaining, q)
    rest = List.delete_at(remaining, q)
    permutation_unrank0(next_rank, rest, [chosen | acc])
  end

  def bowl_order_from_number(order_number) when order_number >= 1 and order_number <= 720 do
    permutation_unrank1(order_number, [1, 2, 3, 4, 5, 6])
  end

  def bowl_order_from_drop(drop_value) do
    order_number = regular_mod(drop_value - 1, 720) + 1
    bowl_order_from_number(order_number)
  end

  def initial_bowls(counts) do
    Enum.reduce(1..6, %{}, fn bowl_id, bowls ->
      prime = Enum.at(@bowl_prime, bowl_id - 1)

      s =
        counts.action + counts.target * bowl_id + counts.distance + counts.connection +
          counts.direction + square(prime)

      Map.put(bowls, bowl_id, save(square(s) + bowl_id))
    end)
  end

  def apply_visible_drops_to_bowls(bowls, visible, stones) do
    Enum.reduce(1..46, {bowls, nil}, fn i, {current, latch} ->
      drop = Map.fetch!(visible, i)
      order = bowl_order_from_drop(drop)
      old = current

      pours = %{
        1 => save(square(drop) + stone_value(stones, i, 1) * Map.fetch!(old, Enum.at(order, 0)) + 3 * i),
        2 => save(square(drop) + stone_value(stones, i, 2) * Map.fetch!(old, Enum.at(order, 1)) + 5 * i),
        3 => save(square(drop) + stone_value(stones, i, 3) * Map.fetch!(old, Enum.at(order, 2)) + 7 * i),
        4 => 0,
        5 => 0,
        6 => 0
      }

      next =
        Enum.reduce(1..6, %{}, fn position, acc ->
          bowl_id = Enum.at(order, position - 1)
          prev_id = Enum.at(order, wrap1(position - 1, 6) - 1)
          next_id = Enum.at(order, wrap1(position + 1, 6) - 1)
          stone_kind = Enum.at(@bowl_stir_stone, position - 1)

          s =
            Map.fetch!(old, bowl_id) + 2 * Map.fetch!(old, prev_id) + 3 * Map.fetch!(old, next_id) +
              Map.fetch!(pours, position) + drop + stone_value(stones, i, stone_kind)

          value =
            save(
              square(s) + 5 * Map.fetch!(old, prev_id) * Map.fetch!(old, next_id) + i * position
            )

          Map.put(acc, bowl_id, value)
        end)

      {next, if(i == 46, do: order, else: latch)}
    end)
  end

  def post_stir12(bowls) do
    Enum.reduce(1..12, bowls, fn stir, current ->
      old = current
      saved_bowl_sum = save(Enum.sum(Map.values(old)) + 149 * stir)
      order_number = regular_mod(saved_bowl_sum - 1, 720) + 1
      order = bowl_order_from_number(order_number)

      Enum.reduce(1..6, %{}, fn position, acc ->
        bowl_id = Enum.at(order, position - 1)
        prev_id = Enum.at(order, wrap1(position - 1, 6) - 1)
        next_id = Enum.at(order, wrap1(position + 1, 6) - 1)

        s =
          Map.fetch!(old, bowl_id) + 3 * Map.fetch!(old, prev_id) + 5 * Map.fetch!(old, next_id) +
            saved_bowl_sum + stir + square(position)

        value = save(square(s) + 7 * Map.fetch!(old, prev_id) * Map.fetch!(old, next_id))
        Map.put(acc, bowl_id, value)
      end)
    end)
  end

  def sauce(calculation_day, target_day) do
    counts = work_counts(calculation_day, target_day)
    stones = build_stones()
    hidden = build_hidden_drops(counts, stones)
    visible = build_visible_drops(counts, stones, hidden)
    bowls = initial_bowls(counts)
    {bowls_after_drops, order_at_drop_46} = apply_visible_drops_to_bowls(bowls, visible, stones)

    %SauceResult{
      bowls: post_stir12(bowls_after_drops),
      order_at_drop_46: order_at_drop_46
    }
  end

  def next_bowl_in_drop_46_order(%SauceResult{} = result, queried_bowl_id) do
    position = Enum.find_index(result.order_at_drop_46, &(&1 == queried_bowl_id))

    if is_nil(position) do
      raise ArgumentError, "mã bát không hợp lệ"
    end

    Enum.at(result.order_at_drop_46, rem(position + 1, 6))
  end

  def ask_bowl(%SauceResult{} = result, queried_bowl_id, seal) do
    next_id = next_bowl_in_drop_46_order(result, queried_bowl_id)

    first =
      save(
        square(Map.fetch!(result.bowls, queried_bowl_id) + seal + 181) +
          179 * Map.fetch!(result.bowls, next_id) + seal
      )

    direction_number =
      save(
        square(first + seal + 1 + 193) + 193 * first + 197 * Map.fetch!(result.bowls, 6)
      )

    step = if regular_mod(direction_number, 2) == 1, do: 1, else: -1
    %AnswerStream{first: first, direction_step: step}
  end

  def answer_at(%AnswerStream{} = stream, k) when k >= 0 do
    1 + regular_mod(stream.first - 1 + stream.direction_step * k, @m)
  end

  def choose_rank_short(%AnswerStream{} = stream, n) when n >= 1 and n <= @m do
    limit = floor_div(@m, n) * n
    choose_short_loop(stream, n, limit, 0)
  end

  defp choose_short_loop(stream, n, limit, k) do
    x = answer_at(stream, k)
    if x <= limit, do: regular_mod(x - 1, n) + 1, else: choose_short_loop(stream, n, limit, k + 1)
  end

  def smallest_power_count(base, n) when base >= 1 and n >= 1 do
    smallest_power_loop(base, n, 1, base)
  end

  defp smallest_power_loop(_base, n, k, space) when space >= n, do: {k, space}
  defp smallest_power_loop(base, n, k, space), do: smallest_power_loop(base, n, k + 1, space * base)

  def choose_rank_wide(%AnswerStream{} = stream, n) when n > @m do
    {k, space} = smallest_power_count(@m, n)

    {wide0, _weight} =
      Enum.reduce(0..(k - 1), {1, 1}, fn j, {wide, weight} ->
        digit = answer_at(stream, j) - 1
        {wide + digit * weight, weight * @m}
      end)

    limit = floor_div(space, n) * n
    wide_rejection_loop(wide0, stream.direction_step, space, limit, n)
  end

  defp wide_rejection_loop(w, _step, _space, limit, n) when w <= limit,
    do: regular_mod(w - 1, n) + 1

  defp wide_rejection_loop(w, step, space, limit, n) do
    next = 1 + regular_mod(w - 1 + step, space)
    wide_rejection_loop(next, step, space, limit, n)
  end

  def choose_rank(stream, n) when n >= 1 do
    if n <= @m, do: choose_rank_short(stream, n), else: choose_rank_wide(stream, n)
  end

  def falling_factorial(_n, 0), do: 1

  def falling_factorial(n, k) when k >= 1 and k <= n do
    Enum.reduce(0..(k - 1), 1, fn j, acc -> acc * (n - j) end)
  end

  def unrank_distinct_indices(n, k, rank1) when k >= 0 and k <= n and rank1 >= 1 do
    unrank_distinct_loop(Enum.to_list(1..n), k, rank1, [])
  end

  defp unrank_distinct_loop(_remaining, 0, _rank, acc), do: Enum.reverse(acc)

  defp unrank_distinct_loop(remaining, k, rank, acc) do
    block = falling_factorial(length(remaining) - 1, k - 1)
    {chosen_pos, next_rank} = distinct_pick_position(rank, block, 0)
    chosen = Enum.at(remaining, chosen_pos)
    rest = List.delete_at(remaining, chosen_pos)
    unrank_distinct_loop(rest, k - 1, next_rank, [chosen | acc])
  end

  defp distinct_pick_position(rank, block, pos) when rank > block,
    do: distinct_pick_position(rank - block, block, pos + 1)

  defp distinct_pick_position(rank, _block, pos), do: {pos, rank}

  def count_bounded_compositions(total, slots, lo, hi) do
    {count, _memo} = bounded_count(total, slots, lo, hi, %{})
    count
  end

  defp bounded_count(remain, slots, lo, hi, memo) do
    key = {remain, slots}

    case Map.fetch(memo, key) do
      {:ok, value} -> {value, memo}
      :error ->
        cond do
          slots == 0 ->
            value = if remain == 0, do: 1, else: 0
            {value, Map.put(memo, key, value)}

          remain < slots * lo or remain > slots * hi ->
            {0, Map.put(memo, key, 0)}

          true ->
            {sum, memo2} =
              Enum.reduce(lo..hi, {0, memo}, fn x, {acc, m} ->
                {value, m2} = bounded_count(remain - x, slots - 1, lo, hi, m)
                {acc + value, m2}
              end)

            {sum, Map.put(memo2, key, sum)}
        end
    end
  end

  def unrank_bounded_composition(total, slots, lo, hi, rank1) do
    {count, memo} = bounded_count(total, slots, lo, hi, %{})

    if rank1 < 1 or rank1 > count do
      raise ArgumentError, "hạng của hợp thành bị chặn không hợp lệ"
    end

    {result, _memo} = bounded_unrank_loop(total, slots, lo, hi, rank1, memo, [])
    result
  end

  defp bounded_unrank_loop(_remain, 0, _lo, _hi, _rank, memo, acc), do: {Enum.reverse(acc), memo}

  defp bounded_unrank_loop(remain, slots, lo, hi, rank, memo, acc) do
    {x, next_rank, memo2} = bounded_pick_x(lo, hi, remain, slots, lo, hi, rank, memo)
    bounded_unrank_loop(remain - x, slots - 1, lo, hi, next_rank, memo2, [x | acc])
  end

  defp bounded_pick_x(x, hi, _remain, _slots, _lo, _bound_hi, _rank, _memo) when x > hi do
    raise ArgumentError, "không thể mở hạng hợp thành bị chặn"
  end

  defp bounded_pick_x(x, hi, remain, slots, lo, bound_hi, rank, memo) do
    {block, memo2} = bounded_count(remain - x, slots - 1, lo, bound_hi, memo)

    if rank > block do
      bounded_pick_x(x + 1, hi, remain, slots, lo, bound_hi, rank - block, memo2)
    else
      {x, rank, memo2}
    end
  end

  def count_weavings(lengths) do
    original = List.to_tuple(lengths)
    state = {original, 0, 0}
    {count, _memo} = weave_count(state, original, %{})
    count
  end

  def unrank_weaving(lengths, rank1) do
    original = List.to_tuple(lengths)
    initial = {original, 0, 0}
    {count, memo} = weave_count(initial, original, %{})

    if rank1 < 1 or rank1 > count do
      raise ArgumentError, "hạng của phép đan tháng không hợp lệ"
    end

    total = Enum.sum(lengths)
    {out, _state, _memo} = weave_unrank_loop(initial, original, rank1, memo, total, [])
    out
  end

  defp weave_count({remaining, _opened, _closed} = state, original, memo) do
    case Map.fetch(memo, state) do
      {:ok, value} -> {value, memo}
      :error ->
        if tuple_all_zero?(remaining) do
          {1, Map.put(memo, state, 1)}
        else
          m = tuple_size(remaining)

          {sum, memo2} =
            Enum.reduce(1..m, {0, memo}, fn j, {acc, m0} ->
              if legal_weave_move?(state, j, original) do
                next = apply_weave_move(state, j, original)
                {value, m1} = weave_count(next, original, m0)
                {acc + value, m1}
              else
                {acc, m0}
              end
            end)

          {sum, Map.put(memo2, state, sum)}
        end
    end
  end

  defp tuple_all_zero?(tuple) do
    tuple |> Tuple.to_list() |> Enum.all?(&(&1 == 0))
  end

  def legal_weave_move?({remaining, opened, closed}, j, original) do
    r = elem(remaining, j - 1)
    orig = elem(original, j - 1)

    cond do
      r == 0 -> false
      r == orig and j != opened + 1 -> false
      r == 1 and j != closed + 1 -> false
      true -> true
    end
  end

  def apply_weave_move({remaining, opened, closed}, j, original) do
    r = elem(remaining, j - 1)
    orig = elem(original, j - 1)
    next_opened = if r == orig, do: j, else: opened
    next_remaining = put_elem(remaining, j - 1, r - 1)
    next_closed = if r - 1 == 0, do: j, else: closed
    {next_remaining, next_opened, next_closed}
  end

  defp weave_unrank_loop(state, original, rank, memo, total, acc) when length(acc) == total do
    {Enum.reverse(acc), state, memo}
  end

  defp weave_unrank_loop(state, original, rank, memo, total, acc) do
    m = tuple_size(original)
    {j, next_state, next_rank, memo2} = weave_pick_label(1, m, state, original, rank, memo)
    weave_unrank_loop(next_state, original, next_rank, memo2, total, [j | acc])
  end

  defp weave_pick_label(j, m, _state, _original, _rank, _memo) when j > m do
    raise ArgumentError, "không tìm thấy khối từ điển hợp lệ của phép đan"
  end

  defp weave_pick_label(j, m, state, original, rank, memo) do
    if legal_weave_move?(state, j, original) do
      next = apply_weave_move(state, j, original)
      {block, memo2} = weave_count(next, original, memo)

      if rank > block do
        weave_pick_label(j + 1, m, state, original, rank - block, memo2)
      else
        {j, next, rank, memo2}
      end
    else
      weave_pick_label(j + 1, m, state, original, rank, memo)
    end
  end

  def make_cutlet_partition_count(gaps, cutlet_count, required_boundary) do
    {count, _memo} = cutlet_partition_count(gaps, cutlet_count, 0, false, required_boundary, %{})
    count
  end

  def unrank_cutlet_partition(gaps, cutlet_count, required_boundary, rank1) do
    {count, memo} = cutlet_partition_count(gaps, cutlet_count, 0, false, required_boundary, %{})

    if rank1 < 1 or rank1 > count do
      raise ArgumentError, "hạng của phân hoạch miếng không hợp lệ"
    end

    {out, _memo} =
      cutlet_partition_unrank_loop(
        gaps,
        cutlet_count,
        0,
        false,
        required_boundary,
        rank1,
        memo,
        []
      )

    out
  end

  defp cutlet_partition_count(remain, slots, cumulative, hit, required, memo) do
    key = {remain, slots, cumulative, hit, required}

    case Map.fetch(memo, key) do
      {:ok, value} -> {value, memo}
      :error ->
        cond do
          slots == 0 ->
            value =
              cond do
                remain != 0 -> 0
                is_nil(required) -> 1
                hit -> 1
                true -> 0
              end

            {value, Map.put(memo, key, value)}

          remain < slots ->
            {0, Map.put(memo, key, 0)}

          true ->
            max_x = remain - (slots - 1)

            {sum, memo2} =
              Enum.reduce(1..max_x, {0, memo}, fn x, {acc, m0} ->
                next_cumulative = cumulative + x

                cond do
                  not is_nil(required) and not hit and next_cumulative > required ->
                    {acc, m0}

                  true ->
                    next_hit = hit or (not is_nil(required) and next_cumulative == required)

                    {value, m1} =
                      cutlet_partition_count(
                        remain - x,
                        slots - 1,
                        next_cumulative,
                        next_hit,
                        required,
                        m0
                      )

                    {acc + value, m1}
                end
              end)

            {sum, Map.put(memo2, key, sum)}
        end
    end
  end

  defp cutlet_partition_unrank_loop(_remain, 0, _cumulative, _hit, _required, _rank, memo, acc),
    do: {Enum.reverse(acc), memo}

  defp cutlet_partition_unrank_loop(remain, slots, cumulative, hit, required, rank, memo, acc) do
    max_x = remain - (slots - 1)

    {x, next_cumulative, next_hit, next_rank, memo2} =
      cutlet_partition_pick_x(
        1,
        max_x,
        remain,
        slots,
        cumulative,
        hit,
        required,
        rank,
        memo
      )

    cutlet_partition_unrank_loop(
      remain - x,
      slots - 1,
      next_cumulative,
      next_hit,
      required,
      next_rank,
      memo2,
      [x | acc]
    )
  end

  defp cutlet_partition_pick_x(x, max_x, _remain, _slots, _cumulative, _hit, _required, _rank, _memo)
       when x > max_x do
    raise ArgumentError, "không thể mở hạng phân hoạch miếng"
  end

  defp cutlet_partition_pick_x(x, max_x, remain, slots, cumulative, hit, required, rank, memo) do
    next_cumulative = cumulative + x

    if not is_nil(required) and not hit and next_cumulative > required do
      cutlet_partition_pick_x(x + 1, max_x, remain, slots, cumulative, hit, required, rank, memo)
    else
      next_hit = hit or (not is_nil(required) and next_cumulative == required)

      {block, memo2} =
        cutlet_partition_count(
          remain - x,
          slots - 1,
          next_cumulative,
          next_hit,
          required,
          memo
        )

      if rank > block do
        cutlet_partition_pick_x(
          x + 1,
          max_x,
          remain,
          slots,
          cumulative,
          hit,
          required,
          rank - block,
          memo2
        )
      else
        {x, next_cumulative, next_hit, rank, memo2}
      end
    end
  end

  def positive_gate_gap(n) when n >= 1 do
    result = sauce(@foundation_day, @foundation_day + n)
    stream = ask_bowl(result, 1, @seal_gate_gap)
    41 + choose_rank(stream, 922)
  end

  def negative_gate_gap(n) when n >= 1 do
    result = sauce(@foundation_day, @foundation_day - n)
    stream = ask_bowl(result, 1, @seal_gate_gap)
    41 + choose_rank(stream, 922)
  end

  def new_gate_state, do: %GateState{}

  def ensure_gate_index(%GateState{} = state, k) when k > state.max_index do
    ensure_positive_gate(state, state.max_index + 1, k)
  end

  def ensure_gate_index(%GateState{} = state, k) when k < state.min_index do
    ensure_negative_gate(state, state.min_index - 1, k)
  end

  def ensure_gate_index(%GateState{} = state, _k), do: state

  defp ensure_positive_gate(state, n, target) when n > target, do: state

  defp ensure_positive_gate(state, n, target) do
    previous = Map.fetch!(state.gate, n - 1)
    day = previous + positive_gate_gap(n)
    next = %{state | gate: Map.put(state.gate, n, day), max_index: n}
    ensure_positive_gate(next, n + 1, target)
  end

  defp ensure_negative_gate(state, n, target) when n < target, do: state

  defp ensure_negative_gate(state, n, target) do
    next_day = Map.fetch!(state.gate, n + 1)
    day = next_day - negative_gate_gap(abs(n))
    next = %{state | gate: Map.put(state.gate, n, day), min_index: n}
    ensure_negative_gate(next, n - 1, target)
  end

  def ensure_gates_cover(%GateState{} = state, low_day, high_day) when low_day <= high_day do
    state |> cover_low(low_day) |> cover_high(high_day)
  end

  defp cover_low(state, low_day) do
    if Map.fetch!(state.gate, state.min_index) > low_day do
      state |> ensure_gate_index(state.min_index - 1) |> cover_low(low_day)
    else
      state
    end
  end

  defp cover_high(state, high_day) do
    if Map.fetch!(state.gate, state.max_index) < high_day do
      state |> ensure_gate_index(state.max_index + 1) |> cover_high(high_day)
    else
      state
    end
  end

  def gate_index_at_or_before(state, day) do
    state2 = ensure_gates_cover(state, day, day)
    index = binary_gate_before(state2.gate, state2.min_index, state2.max_index, day)
    {index, state2}
  end

  defp binary_gate_before(_gate, lo, hi, _day) when lo == hi, do: lo

  defp binary_gate_before(gate, lo, hi, day) do
    mid = lo + floor_div(hi - lo + 1, 2)

    if Map.fetch!(gate, mid) <= day do
      binary_gate_before(gate, mid, hi, day)
    else
      binary_gate_before(gate, lo, mid - 1, day)
    end
  end

  def exact_gate_index(state, day) do
    {index, state2} = gate_index_at_or_before(state, day)
    {if(Map.fetch!(state2.gate, index) == day, do: index, else: nil), state2}
  end

  def year_length(state, open_index, close_index) do
    Map.fetch!(state.gate, close_index) - Map.fetch!(state.gate, open_index)
  end

  def valid_year_pair?(state, open_index, close_index) do
    gaps = close_index - open_index
    length = year_length(state, open_index, close_index)
    gaps >= 6 and length >= @year_min_days and length <= @year_max_days
  end

  def year5000(calculation_day, state \\ new_gate_state()) do
    state2 = ensure_gates_cover(state, calculation_day - @year_max_days, calculation_day + @year_max_days)
    indices = Enum.to_list(state2.min_index..state2.max_index)

    candidates =
      for i <- indices,
          j <- indices,
          i < j,
          valid_year_pair?(state2, i, j),
          Map.fetch!(state2.gate, i) < calculation_day,
          calculation_day <= Map.fetch!(state2.gate, j) do
        {i, j}
      end
      |> Enum.sort_by(fn {i, j} ->
        {year_length(state2, i, j), Map.fetch!(state2.gate, i)}
      end)

    if candidates == [] do
      raise ArgumentError, "không tìm thấy năm neo 5000"
    end

    result = sauce(calculation_day, calculation_day)
    stream = ask_bowl(result, 1, @seal_year_5000)
    rank = choose_rank(stream, length(candidates))
    {i, j} = Enum.at(candidates, rank - 1)

    {%Year{
       number: 5000,
       open_gate_index: i,
       close_gate_index: j,
       open_gate_day: Map.fetch!(state2.gate, i),
       close_gate_day: Map.fetch!(state2.gate, j)
     }, state2}
  end

  def next_year(calculation_day, %Year{} = known, state) do
    open_index = known.close_gate_index
    open_day = Map.fetch!(state.gate, open_index)
    state2 = ensure_gates_cover(state, Map.fetch!(state.gate, state.min_index), open_day + @year_max_days)

    candidates =
      (open_index + 1)..state2.max_index
      |> Enum.filter(fn close_index ->
        year_length(state2, open_index, close_index) <= @year_max_days and
          valid_year_pair?(state2, open_index, close_index)
      end)
      |> Enum.sort_by(&year_length(state2, open_index, &1))

    result = sauce(calculation_day, open_day)
    stream = ask_bowl(result, 1, @seal_next_year)
    rank = choose_rank(stream, length(candidates))
    close_index = Enum.at(candidates, rank - 1)

    {%Year{
       number: known.number + 1,
       open_gate_index: open_index,
       close_gate_index: close_index,
       open_gate_day: open_day,
       close_gate_day: Map.fetch!(state2.gate, close_index)
     }, state2}
  end

  def previous_year(calculation_day, %Year{} = known, state) do
    close_index = known.open_gate_index
    close_day = Map.fetch!(state.gate, close_index)
    state2 = ensure_gates_cover(state, close_day - @year_max_days, Map.fetch!(state.gate, state.max_index))

    candidates =
      state2.min_index..(close_index - 1)
      |> Enum.filter(fn open_index ->
        year_length(state2, open_index, close_index) <= @year_max_days and
          valid_year_pair?(state2, open_index, close_index)
      end)
      |> Enum.sort_by(&year_length(state2, &1, close_index))

    result = sauce(calculation_day, close_day)
    stream = ask_bowl(result, 1, @seal_previous_year)
    rank = choose_rank(stream, length(candidates))
    open_index = Enum.at(candidates, rank - 1)

    {%Year{
       number: known.number - 1,
       open_gate_index: open_index,
       close_gate_index: close_index,
       open_gate_day: Map.fetch!(state2.gate, open_index),
       close_gate_day: close_day
     }, state2}
  end

  def find_target_year(calculation_day, target_day) do
    {year, state} = year5000(calculation_day)
    walk_target_year(calculation_day, target_day, year, state)
  end

  defp walk_target_year(calculation_day, target_day, year, state) do
    cond do
      target_day > year.close_gate_day ->
        {next, state2} = next_year(calculation_day, year, state)
        walk_target_year(calculation_day, target_day, next, state2)

      target_day <= year.open_gate_day ->
        {previous, state2} = previous_year(calculation_day, year, state)
        walk_target_year(calculation_day, target_day, previous, state2)

      true ->
        {year, state}
    end
  end

  def choose_cutlet_count(structure_sauce, %Year{} = year) do
    gate_gaps = year.close_gate_index - year.open_gate_index
    candidates = Enum.filter(6..17, &(&1 <= gate_gaps))
    stream = ask_bowl(structure_sauce, 2, @seal_cutlet_count)
    Enum.at(candidates, choose_rank(stream, length(candidates)) - 1)
  end

  def choose_cutlet_partition(calculation_day, structure_sauce, year, cutlet_count, state) do
    gaps = year.close_gate_index - year.open_gate_index
    {gate_index, state2} = exact_gate_index(state, calculation_day)

    required =
      if not is_nil(gate_index) and gate_index > year.open_gate_index and gate_index < year.close_gate_index do
        gate_index - year.open_gate_index
      else
        nil
      end

    count = make_cutlet_partition_count(gaps, cutlet_count, required)
    stream = ask_bowl(structure_sauce, 2, @seal_cutlet_partition)
    rank = choose_rank(stream, count)
    {unrank_cutlet_partition(gaps, cutlet_count, required, rank), state2}
  end

  def choose_cutlet_name_indices(structure_sauce, cutlet_count) do
    count = falling_factorial(17, cutlet_count)
    stream = ask_bowl(structure_sauce, 5, @seal_cutlet_names)
    rank = choose_rank(stream, count)
    unrank_distinct_indices(17, cutlet_count, rank)
  end

  def materialize_cutlets(year, partition, name_indices, state) do
    {cutlets, _cursor} =
      Enum.zip(partition, name_indices)
      |> Enum.map_reduce(year.open_gate_index, fn {part, name_index}, cursor ->
        close_index = cursor + part

        cutlet = %Cutlet{
          name_index: name_index,
          open_gate_index: cursor,
          close_gate_index: close_index,
          first_day: Map.fetch!(state.gate, cursor) + 1,
          last_day: Map.fetch!(state.gate, close_index)
        }

        {cutlet, close_index}
      end)

    cutlets
  end

  def choose_month_count(structure_sauce, year) do
    length = year.close_gate_day - year.open_gate_day
    min_months = ceil_div(length, 123)
    max_months = min(47, floor_div(length, 4))
    candidates = Enum.to_list(min_months..max_months)
    stream = ask_bowl(structure_sauce, 3, @seal_month_count)
    Enum.at(candidates, choose_rank(stream, length(candidates)) - 1)
  end

  def choose_month_lengths(structure_sauce, year, month_count) do
    length = year.close_gate_day - year.open_gate_day
    count = count_bounded_compositions(length, month_count, 4, 123)
    stream = ask_bowl(structure_sauce, 3, @seal_month_lengths)
    rank = choose_rank(stream, count)
    unrank_bounded_composition(length, month_count, 4, 123, rank)
  end

  def choose_month_weaving(structure_sauce, month_lengths) do
    count = count_weavings(month_lengths)
    stream = ask_bowl(structure_sauce, 4, @seal_month_weaving)
    rank = choose_rank(stream, count)
    unrank_weaving(month_lengths, rank)
  end

  def choose_month_name_indices(structure_sauce, month_count) do
    count = falling_factorial(47, month_count)
    stream = ask_bowl(structure_sauce, 5, @seal_month_names)
    rank = choose_rank(stream, count)
    unrank_distinct_indices(47, month_count, rank)
  end

  def build_year_structure(calculation_day, year, state) do
    first_day = year.open_gate_day + 1
    result = sauce(calculation_day, first_day)
    cutlet_count = choose_cutlet_count(result, year)
    {partition, state2} = choose_cutlet_partition(calculation_day, result, year, cutlet_count, state)
    cutlet_name_indices = choose_cutlet_name_indices(result, cutlet_count)
    cutlets = materialize_cutlets(year, partition, cutlet_name_indices, state2)
    month_count = choose_month_count(result, year)
    month_lengths = choose_month_lengths(result, year, month_count)
    month_weaving = choose_month_weaving(result, month_lengths)
    month_name_indices = choose_month_name_indices(result, month_count)

    {%YearStructure{
       cutlet_count: cutlet_count,
       cutlet_partition: partition,
       cutlet_name_indices: cutlet_name_indices,
       cutlets: cutlets,
       month_count: month_count,
       month_lengths: month_lengths,
       month_weaving: month_weaving,
       month_name_indices: month_name_indices
     }, state2}
  end

  def calendar_date(calculation_day, target_day) do
    {year, state} = find_target_year(calculation_day, target_day)
    {structure, _state2} = build_year_structure(calculation_day, year, state)

    {chosen_cutlet, _cutlet_index} =
      structure.cutlets
      |> Enum.with_index(1)
      |> Enum.find(fn {cutlet, _index} ->
        cutlet.first_day <= target_day and target_day <= cutlet.last_day
      end) || raise(ArgumentError, "ngày đích không nằm trong miếng nào")

    day_in_cutlet = target_day - chosen_cutlet.first_day + 1
    year_offset0 = target_day - (year.open_gate_day + 1)
    month_id = Enum.at(structure.month_weaving, year_offset0)
    month_name_index = Enum.at(structure.month_name_indices, month_id - 1)

    day_in_month =
      structure.month_weaving
      |> Enum.take(year_offset0 + 1)
      |> Enum.count(&(&1 == month_id))

    {
      year.number,
      SourceLanguageCatalog.cutlet_name(chosen_cutlet.name_index),
      day_in_cutlet,
      SourceLanguageCatalog.month_name(month_name_index),
      day_in_month
    }
  end
end
