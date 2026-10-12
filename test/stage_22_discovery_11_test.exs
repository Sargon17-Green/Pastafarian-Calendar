defmodule PastafariCalendarElixirVietnamese.Stage22Discovery11Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlDropCalculator,
    BowlOrderManager,
    LegacyOrderMemory,
    PostStirCalculator
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  defp expected_next(order, id) do
    position = Enum.find_index(order, &(&1 == id))
    Enum.at(order, rem(position + 1, 6))
  end

  defp oracle(c, t) do
    result = Ref.sauce(c, t)
    {result.bowls, result.order_at_drop_46}
  end

  test "ô thứ tự được tạo trống, ghi đè thay vì tạo latch giọt 46" do
    first = LegacyOrderMemory.new()
    assert first.order == nil
    assert first.writes == 0
    assert first.last_source == nil

    order46 = [1, 2, 3, 4, 5, 6]
    order12 = [4, 5, 6, 1, 2, 3]

    once = LegacyOrderMemory.write(first, order46, {:drop, 46})
    twice = LegacyOrderMemory.write(once, order12, {:stir, 12})

    assert once.order == order46
    assert once.writes == 1
    assert twice.order == order12
    assert twice.writes == 2
    assert twice.last_source == {:stir, 12}
    assert first.order == nil
    refute Map.has_key?(twice, :order_at_drop_46)
  end

  test "46 giọt ghi 46 lần và chưa bị khuấy cuối ghi đè" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f - 13, f + 29)

    {finished, memory} =
      BowlDropCalculator.apply_all_with_order_memory(
        context.initial_bowls,
        context.visible_drops,
        context.bowl_orders,
        context.stones_table
      )

    assert finished == context.bowls_after_drops
    assert memory.writes == 46
    assert memory.last_source == {:drop, 46}
    assert memory.order == context.bowl_orders[46]
    assert memory.order == Ref.bowl_order_from_drop(context.visible_drops[46])
    assert memory.order == BowlOrderManager.order_from_drop(context.visible_drops[46])
  end

  test "12 lần khuấy cuối ghi đè cùng ô và nâng số lần ghi lên 58" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f, f)

    {after_drops, memory46} =
      BowlDropCalculator.apply_all_with_order_memory(
        context.initial_bowls, context.visible_drops,
        context.bowl_orders, context.stones_table
      )

    {finished, memory58} = PostStirCalculator.apply_all(after_drops, memory46)

    assert memory46.writes == 46
    assert memory58.writes == 58
    assert memory58.last_source == {:stir, 12}
    assert context.order_memory == memory58
    assert context.order_memory.order == memory58.order
    assert context.bowls_after_post_stirs == finished
    assert context.bowls_after_post_stirs == Ref.post_stir12(after_drops)
  end

  test "mười hai lần khuấy dùng SAVE của tổng sáu ID và số 149" do
    f = Ref.foundation_day()
    initial = Calendar.bowls_after_drops_spaghetti(f, f)

    current =
      Enum.reduce(1..12, initial, fn stir, old ->
        saved_sum = Ref.save(Enum.sum(Map.values(old)) + 149 * stir)
        expected_order = Ref.bowl_order_from_drop(saved_sum)
        {next, got_order} = PostStirCalculator.step(old, stir)

        assert got_order == expected_order
        assert Enum.sort(got_order) == [1, 2, 3, 4, 5, 6]
        assert Enum.sort(Map.keys(next)) == [1, 2, 3, 4, 5, 6]
        assert Enum.all?(Map.values(next), &(&1 >= 1 and &1 <= Ref.m()))
        next
      end)

    assert current == Ref.post_stir12(initial)
  end

  test "mỗi vị trí khuấy dùng trạng thái old cố định, không có lỗi in-place" do
    f = Ref.foundation_day()
    old = Calendar.bowls_after_drops_spaghetti(f - 19, f + 31)
    {next, order} = PostStirCalculator.step(old, 1)
    saved_sum = Ref.save(Enum.sum(Map.values(old)) + 149)

    expected =
      Enum.reduce(1..6, %{}, fn position, acc ->
        id = Enum.at(order, position - 1)
        prev_id = Enum.at(order, Ref.wrap1(position - 1, 6) - 1)
        next_id = Enum.at(order, Ref.wrap1(position + 1, 6) - 1)
        mix = old[id] + 3 * old[prev_id] + 5 * old[next_id] +
          saved_sum + 1 + position * position
        value = Ref.save(mix * mix + 7 * old[prev_id] * old[next_id])
        Map.put(acc, id, value)
      end)

    assert next == expected
    assert old == Calendar.bowls_after_drops_spaghetti(f - 19, f + 31)
  end

  test "trạng thái sáu bát sau 12 lượt hoàn toàn đúng với oracle" do
    f = Ref.foundation_day()
    pairs = [
      {f, f},
      {f - 1, f},
      {f, f + 1},
      {f - 17, f + 37},
      {f + 37, f - 17}
    ]

    for {c, t} <- pairs do
      ctx = Calendar.bootstrap_context(c, t)
      {expected, _order46} = oracle(c, t)

      assert ctx.bowls_after_post_stirs == expected
      assert Calendar.bowls_after_post_stirs_spaghetti(c, t) == expected
      assert ctx.bowls_after_post_stirs == Ref.post_stir12(ctx.bowls_after_drops)
    end
  end

  test "query legacy thực sự theo thứ tự bị ghi đè sau khuấy 12" do
    f = Ref.foundation_day()
    ctx = Calendar.bootstrap_context(f, f)
    memory = ctx.order_memory

    assert memory.writes == 58
    assert memory.last_source == {:stir, 12}

    for bowl_id <- 1..6 do
      actual = Calendar.next_bowl_spaghetti(f, f, bowl_id)
      assert actual == LegacyOrderMemory.next_bowl(memory, bowl_id)
      assert actual == expected_next(memory.order, bowl_id)
    end
  end

  test "thứ tự giọt 46 tồn tại trong map cũ nhưng query không dùng nó" do
    f = Ref.foundation_day()
    ctx = Calendar.bootstrap_context(f, f)
    expected_order46 = Ref.sauce(f, f).order_at_drop_46

    assert ctx.bowl_orders[46] == expected_order46
    assert ctx.order_memory.last_source == {:stir, 12}
    assert ctx.order_memory.writes == 58
    refute ctx.order_memory.order == expected_order46

    wrong = Enum.map(1..6, &Calendar.next_bowl_spaghetti(f, f, &1))
    correct = Enum.map(1..6, &expected_next(expected_order46, &1))
    refute wrong == correct
  end

  test "các bản vá 01 đến 10 vẫn giữ kết quả giọt và bát sau 46 vòng" do
    f = Ref.foundation_day()
    c = f - 19
    t = f + 31
    ctx = Calendar.bootstrap_context(c, t)
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    visible = Ref.build_visible_drops(counts, stones, hidden)
    initial = Ref.initial_bowls(counts)
    {after_drops, order46} = Ref.apply_visible_drops_to_bowls(
      initial, visible, stones)

    assert ctx.stones_table == stones
    assert ctx.visible_drops == visible
    assert ctx.initial_bowls == initial
    assert ctx.bowls_after_drops == after_drops
    assert ctx.bowl_orders[46] == order46
    assert ctx.bowls_after_post_stirs == Ref.post_stir12(after_drops)
  end

  test "kho bộ nhớ 58 lần viết độc lập giữa các cuộc gọi song song" do
    f = Ref.foundation_day()
    pairs = for delta <- -11..11, do: {f + delta * 19, f - delta * 23}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        max_concurrency: 8, ordered: true, timeout: 15_000
      )
      |> Enum.map(fn {:ok, ctx} -> ctx end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, ctx} ->
      assert ctx.order_memory.writes == 58
      assert ctx.order_memory.last_source == {:stir, 12}
      assert ctx.bowls_after_post_stirs == Ref.post_stir12(ctx.bowls_after_drops)
      assert ctx.order_memory == Calendar.order_memory_spaghetti(c, t)
    end)

    original = hd(contexts)
    changed = %{original | order_memory: %{original.order_memory | order: []}}
    refute changed.order_memory.order == original.order_memory.order
  end

  test "ngày số nguyên 512 và 2048 bit giữ đủ 58 lần viết" do
    f = Ref.foundation_day()
    for shift <- [(1 <<< 512) + 1, 1 <<< 2048] do
      for {c, t} <- [{f - shift, f + shift}, {f + shift, f - shift}] do
        ctx = Calendar.bootstrap_context(c, t)

        assert ctx.order_memory.writes == 58
        assert ctx.order_memory.last_source == {:stir, 12}
        assert ctx.bowls_after_post_stirs == Ref.post_stir12(ctx.bowls_after_drops)
        assert Enum.all?(Map.values(ctx.bowls_after_post_stirs), fn value ->
          is_integer(value) and value >= 1 and value <= Ref.m()
        end)
      end
    end
  end

  test "biên lượt khuấy và mã bát phải báo lỗi rõ ràng" do
    f = Ref.foundation_day()
    old = Calendar.bowls_after_drops_spaghetti(f, f)

    for bad <- [0, -1, 13, nil, 1.0, "1"] do
      assert_raise ArgumentError, "lượt khuấy cuối phải từ 1 đến 12", fn ->
        PostStirCalculator.step(old, bad)
      end
    end

    memory = LegacyOrderMemory.write(LegacyOrderMemory.new(),
      [1, 2, 3, 4, 5, 6], {:drop, 46})

    for bad <- [0, 7, -1, nil, 1.0, "1"] do
      assert_raise ArgumentError, "mã bát không hợp lệ", fn ->
        LegacyOrderMemory.next_bowl(memory, bad)
      end
    end
  end

  test "hồi quy chuẩn kế cận của ID 1 ở ngày gốc: cố ý đỏ" do
    f = Ref.foundation_day()
    expected = Ref.next_bowl_in_drop_46_order(Ref.sauce(f, f), 1)
    assert Calendar.next_bowl_spaghetti(f, f, 1) == expected
  end

  test "hồi quy chuẩn ánh xạ cả sáu ID cùng ngày: cố ý đỏ" do
    f = Ref.foundation_day()
    expected_result = Ref.sauce(f, f)

    actual = Enum.map(1..6, &Calendar.next_bowl_spaghetti(f, f, &1))
    expected = Enum.map(1..6,
      &Ref.next_bowl_in_drop_46_order(expected_result, &1))

    assert actual == expected
  end

  test "hồi quy chuẩn ánh xạ cả sáu ID ngày đảo chiều: cố ý đỏ" do
    f = Ref.foundation_day()
    c = f + 37
    t = f - 17
    expected_result = Ref.sauce(c, t)

    actual = Enum.map(1..6, &Calendar.next_bowl_spaghetti(c, t, &1))
    expected = Enum.map(1..6,
      &Ref.next_bowl_in_drop_46_order(expected_result, &1))

    assert actual == expected
  end

  test "hồi quy chuẩn sáu ID ngày số nguyên lớn: cố ý đỏ" do
    f = Ref.foundation_day()
    jump = 1 <<< 512
    c = f - jump
    t = f + jump
    expected_result = Ref.sauce(c, t)

    actual = Enum.map(1..6, &Calendar.next_bowl_spaghetti(c, t, &1))
    expected = Enum.map(1..6,
      &Ref.next_bowl_in_drop_46_order(expected_result, &1))

    assert actual == expected
  end
end
