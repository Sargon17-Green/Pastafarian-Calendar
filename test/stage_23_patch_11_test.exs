defmodule PastafariCalendarElixirVietnamese.Stage23Patch11Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlDropCalculator,
    LegacyOrderMemory,
    OrderAt46LatchPatch,
    PostStirCalculator
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @identity [1, 2, 3, 4, 5, 6]

  defp correct_next(order, bowl_id) do
    position = Enum.find_index(order, &(&1 == bowl_id))
    Enum.at(order, rem(position + 1, 6))
  end

  test "chốt đúng tại nguồn giọt 46 và không ghi vào memory lịch sử" do
    memory46 =
      LegacyOrderMemory.new()
      |> Map.put(:order, [4, 5, 6, 1, 2, 3])
      |> Map.put(:writes, 46)
      |> Map.put(:last_source, {:drop, 46})

    latch = OrderAt46LatchPatch.capture(memory46)

    assert latch == [4, 5, 6, 1, 2, 3]
    assert memory46.order == latch
    assert Map.keys(memory46) |> Enum.sort() == [:last_source, :order, :writes]
    refute Map.has_key?(memory46, :order_at_46_latch)
  end

  test "không thể chốt trước giọt 46 hay sau khi khuấy" do
    for {writes, source} <- [
          {0, nil}, {1, {:drop, 1}}, {45, {:drop, 45}},
          {46, {:drop, 45}}, {46, {:stir, 1}},
          {47, {:stir, 1}}, {58, {:stir, 12}}
        ] do
      memory = %{order: @identity, writes: writes, last_source: source}

      assert_raise ArgumentError, "chỉ được chốt thứ tự ngay sau giọt 46", fn ->
        OrderAt46LatchPatch.capture(memory)
      end
    end
  end

  test "chỉ chấp nhận một hoán vị của đủ sáu ID làm chốt" do
    for bad <- [
          [1, 2, 3, 4, 5, 5], [1, 2, 3, 4, 5, 7],
          [1, 2, 3, 4, 5, 0], [:a, 2, 3, 4, 5, 6]
        ] do
      memory = %{order: bad, writes: 46, last_source: {:drop, 46}}

      assert_raise ArgumentError, "thứ tự giọt 46 phải chứa sáu ID bát", fn ->
        OrderAt46LatchPatch.capture(memory)
      end
    end

    assert_raise ArgumentError, "chỉ được chốt thứ tự ngay sau giọt 46", fn ->
      OrderAt46LatchPatch.capture(%{order: [1, 2, 3], writes: 46,
        last_source: {:drop, 46}})
    end
  end

  test "đường truy vấn latch sử dụng lại LegacyOrderMemory.next_bowl" do
    latch = [4, 5, 6, 1, 2, 3]

    for id <- 1..6 do
      assert OrderAt46LatchPatch.next_bowl(latch, id) ==
               LegacyOrderMemory.next_bowl(%{order: latch}, id)
      assert OrderAt46LatchPatch.next_bowl(latch, id) == correct_next(latch, id)
    end
  end

  test "720 hoán vị đều cho đủ quan hệ kế cận chuẩn" do
    for rank <- 1..720 do
      order = Ref.bowl_order_from_number(rank)

      for id <- 1..6 do
        assert OrderAt46LatchPatch.next_bowl(order, id) == correct_next(order, id)
      end
    end
  end

  test "sau giọt 46 đã có latch, trước khi ghi thêm 12 vòng" do
    f = Ref.foundation_day()
    c = f - 31
    t = f + 79
    ctx = Calendar.bootstrap_context(c, t)

    {after_drops, memory46} =
      BowlDropCalculator.apply_all_with_order_memory(
        ctx.initial_bowls, ctx.visible_drops, ctx.bowl_orders, ctx.stones_table
      )

    latch = OrderAt46LatchPatch.capture(memory46)

    assert memory46.writes == 46
    assert memory46.last_source == {:drop, 46}
    assert latch == ctx.order_at_46_latch
    assert latch == ctx.bowl_orders[46]
    assert latch == Ref.sauce(c, t).order_at_drop_46
    assert after_drops == ctx.bowls_after_drops
  end

  test "58 lần ghi bộ nhớ legacy còn nguyên và bị ghi đè sau 12 vòng" do
    f = Ref.foundation_day()
    c = f
    t = f
    ctx = Calendar.bootstrap_context(c, t)

    {bowls46, memory46} =
      BowlDropCalculator.apply_all_with_order_memory(
        ctx.initial_bowls, ctx.visible_drops, ctx.bowl_orders, ctx.stones_table
      )

    latch = OrderAt46LatchPatch.capture(memory46)
    {bowls58, memory58} = PostStirCalculator.apply_all(bowls46, memory46)

    assert memory46.writes == 46
    assert memory58.writes == 58
    assert memory58.last_source == {:stir, 12}
    assert ctx.order_memory == memory58
    assert ctx.bowls_after_post_stirs == bowls58
    assert ctx.order_at_46_latch == latch
    refute ctx.order_at_46_latch == ctx.order_memory.order
  end

  test "cả sáu kết quả truy vấn dùng giọt 46 thay vì khuấy thứ 12" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 17, f + 37}, {f + 37, f - 17}] do
      ctx = Calendar.bootstrap_context(c, t)
      result = Ref.sauce(c, t)

      assert ctx.order_at_46_latch == result.order_at_drop_46
      assert ctx.bowls_after_post_stirs == result.bowls

      actual = Enum.map(1..6, &Calendar.next_bowl_spaghetti(c, t, &1))
      expected = Enum.map(1..6, &Ref.next_bowl_in_drop_46_order(result, &1))

      assert actual == expected
      assert Enum.sort(actual) == @identity
    end
  end

  test "giá trị memory legacy bị ghi đè không ảnh hưởng truy vấn đã chốt" do
    f = Ref.foundation_day()
    ctx = Calendar.bootstrap_context(f, f)
    order46 = ctx.order_at_46_latch

    assert order46 == ctx.bowl_orders[46]
    assert ctx.order_memory.writes == 58

    wrong = Enum.map(1..6,
      &LegacyOrderMemory.next_bowl(ctx.order_memory, &1))
    right = Enum.map(1..6,
      &OrderAt46LatchPatch.next_bowl(order46, &1))

    refute wrong == right
    assert right == Enum.map(1..6,
      &Ref.next_bowl_in_drop_46_order(Ref.sauce(f, f), &1))
  end

  test "sáu bát cuối chuẩn mà không chỉnh công thức 12 lần khuấy" do
    f = Ref.foundation_day()

    for {c, t} <- [
          {f, f}, {f - 1, f + 1}, {f + 1, f - 1},
          {f - 121, f + 292}, {f + 292, f - 121}
        ] do
      ctx = Calendar.bootstrap_context(c, t)
      result = Ref.sauce(c, t)

      assert ctx.bowls_after_post_stirs ==
               Ref.post_stir12(ctx.bowls_after_drops)
      assert ctx.bowls_after_post_stirs == result.bowls
      assert ctx.order_at_46_latch == result.order_at_drop_46
    end
  end

  test "ngày cực lớn tới 2048 bit không thay nguồn truy vấn" do
    f = Ref.foundation_day()

    for jump <- [1 <<< 128, (1 <<< 512) + 7, 1 <<< 2048] do
      for {c, t} <- [{f - jump, f + jump}, {f + jump, f - jump}] do
        ctx = Calendar.bootstrap_context(c, t)
        result = Ref.sauce(c, t)

        assert ctx.order_memory.writes == 58
        assert ctx.order_at_46_latch == result.order_at_drop_46
        assert ctx.bowls_after_post_stirs == result.bowls

        for id <- 1..6 do
          assert Calendar.next_bowl_spaghetti(c, t, id) ==
                   Ref.next_bowl_in_drop_46_order(result, id)
        end
      end
    end
  end

  test "ngữ cảnh song song không chia sẻ latch hoặc memory" do
    f = Ref.foundation_day()
    pairs = for k <- -12..12, do: {f + 17 * k, f - 29 * k}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        max_concurrency: 8, ordered: true, timeout: 15_000
      )
      |> Enum.map(fn {:ok, ctx} -> ctx end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, ctx} ->
      result = Ref.sauce(c, t)

      assert ctx.order_at_46_latch == result.order_at_drop_46
      assert ctx.order_memory.writes == 58

      for id <- 1..6 do
        assert OrderAt46LatchPatch.next_bowl(ctx.order_at_46_latch, id) ==
                 Ref.next_bowl_in_drop_46_order(result, id)
      end
    end)

    first = hd(contexts)
    altered = %{first | order_at_46_latch: Enum.reverse(first.order_at_46_latch)}
    refute altered.order_at_46_latch == first.order_at_46_latch
  end

  test "đầu vào sai bị từ chối rõ, kể cả ID ngoài 1..6" do
    for bad_order <- [nil, :sai, %{}, [1, 2, 3], "123456"] do
      assert_raise ArgumentError, "thứ tự giọt 46 không hợp lệ", fn ->
        OrderAt46LatchPatch.next_bowl(bad_order, 1)
      end
    end

    for bad_id <- [0, 7, -1, nil, 2.0, "1"] do
      assert_raise ArgumentError, "mã bát không hợp lệ", fn ->
        OrderAt46LatchPatch.next_bowl(@identity, bad_id)
      end
    end

    assert_raise ArgumentError, "thứ tự giọt 46 phải chứa sáu ID bát", fn ->
      OrderAt46LatchPatch.next_bowl([1, 1, 3, 4, 5, 6], 1)
    end
  end

  test "kiểm toán mã nguồn: latch trước post-stir, query vẫn gọi legacy" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_order_memory.ex") |> File.read!()
    patch = Path.join(root, "order_at_46_latch_patch.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()
    post_stir = Path.join(root, "post_stir_calculator.ex") |> File.read!()

    assert legacy =~ "Map.fetch!(memory, :order)"
    assert legacy =~ "memory.writes + 1"
    assert patch =~ "writes: 46, last_source: {:drop, 46}"
    assert patch =~ "LegacyOrderMemory.next_bowl("
    assert dispatcher =~ "OrderAt46LatchPatch.capture(memory_after_drops)"
    assert dispatcher =~ "OrderAt46LatchPatch.next_bowl(queried_bowl_id)"
    assert post_stir =~ "LegacyOrderMemory.write(memory, order, {:stir, stir})"
    refute legacy =~ "order_at_46_latch"
    refute post_stir =~ "order_at_46_latch"
    refute patch =~ "NormativeReference"
  end
end
