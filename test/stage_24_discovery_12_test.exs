defmodule PastafariCalendarElixirVietnamese.Stage24Discovery12Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyFixedNameSuccessor,
    LegacyOrderMemory,
    OrderAt46LatchPatch
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @fixture [4, 5, 2, 3, 6, 1]
  @ids [1, 2, 3, 4, 5, 6]

  defp next_from_order(order, id) do
    index = Enum.find_index(order, &(&1 == id))
    Enum.at(order, rem(index + 1, 6))
  end

  test "vòng legacy dùng tên ID cố định từ 1 tới 6" do
    actual = Enum.map(@ids, &LegacyFixedNameSuccessor.old_next_bowl_fixed_name/1)
    assert actual == [2, 3, 4, 5, 6, 1]

    for id <- @ids do
      assert LegacyFixedNameSuccessor.old_next_bowl_fixed_name(id) ==
               rem(id, 6) + 1
    end
  end

  test "hàm legacy độc lập hoàn toàn với hoán vị thực ở giọt 46" do
    fixed = Enum.map(@ids, &LegacyFixedNameSuccessor.old_next_bowl_fixed_name/1)
    order1 = [1, 2, 3, 4, 5, 6]
    order2 = @fixture

    assert fixed == Enum.map(@ids, &next_from_order(order1, &1))
    refute fixed == Enum.map(@ids, &next_from_order(order2, &1))
  end

  test "chứng cứ cụ thể: ID 3 có kế cận chuẩn 6, legacy trả 4" do
    assert next_from_order(@fixture, 3) == 6
    assert LegacyFixedNameSuccessor.old_next_bowl_fixed_name(3) == 4
    refute LegacyFixedNameSuccessor.old_next_bowl_fixed_name(3) ==
             next_from_order(@fixture, 3)
  end

  test "chứng cứ cụ thể cho ID 1 và 5 khi vị trí đã đổi" do
    assert next_from_order(@fixture, 1) == 4
    assert next_from_order(@fixture, 5) == 2
    assert LegacyFixedNameSuccessor.old_next_bowl_fixed_name(1) == 2
    assert LegacyFixedNameSuccessor.old_next_bowl_fixed_name(5) == 6
  end

  test "latch đã vá từ giai đoạn 23 vẫn chốt đúng vị trí" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 17, f + 37}, {f + 37, f - 17}] do
      ctx = Calendar.bootstrap_context(c, t)
      result = Ref.sauce(c, t)
      assert ctx.order_at_46_latch == result.order_at_drop_46
      assert ctx.bowl_orders[46] == result.order_at_drop_46
      assert Enum.sort(ctx.order_at_46_latch) == @ids
    end
  end

  test "bộ nhớ lịch sử vẫn ghi đủ 58 lần, không quay ngược lỗi 11" do
    f = Ref.foundation_day()
    ctx = Calendar.bootstrap_context(f, f)

    assert ctx.order_memory.writes == 58
    assert ctx.order_memory.last_source == {:stir, 12}
    assert ctx.order_at_46_latch == ctx.bowl_orders[46]
    assert ctx.order_at_46_latch == Ref.sauce(f, f).order_at_drop_46
    assert ctx.order_memory.order != ctx.order_at_46_latch
    assert LegacyOrderMemory.next_bowl(ctx.order_memory, 1) ==
             Enum.at(ctx.order_memory.order,
               rem(Enum.find_index(ctx.order_memory.order, &(&1 == 1)) + 1, 6))
  end

  test "đường production thật chọn vòng ID cố định cho mọi tên bát" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 11, f + 19}, {f + 19, f - 11}],
        id <- @ids do
      assert Calendar.next_bowl_spaghetti(c, t, id) ==
               LegacyFixedNameSuccessor.old_next_bowl_fixed_name(id)
    end
  end

  test "latch đọc độc lập vẫn có thuật toán vòng theo hoán vị đúng" do
    for id <- @ids do
      assert OrderAt46LatchPatch.next_bowl(@fixture, id) ==
               next_from_order(@fixture, id)
    end

    refute Enum.map(@ids, &OrderAt46LatchPatch.next_bowl(@fixture, &1)) ==
             Enum.map(@ids, &LegacyFixedNameSuccessor.old_next_bowl_fixed_name/1)
  end

  test "720 hoán vị bộc lộ cố định một vòng, không bị rút gọn thành một hoán vị" do
    fixed = Enum.map(@ids, &LegacyFixedNameSuccessor.old_next_bowl_fixed_name/1)

    matches =
      Enum.count(1..720, fn rank ->
        order = Ref.bowl_order_from_number(rank)
        successors = Enum.map(@ids, &next_from_order(order, &1))
        successors == fixed
      end)

    assert matches == 6
    assert length(Enum.uniq(Enum.map(@ids,
      &LegacyFixedNameSuccessor.old_next_bowl_fixed_name/1))) == 6
  end

  test "sáu bát sau 12 lượt khuấy tiếp tục khớp chuẩn oracle" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 101, f + 87}, {f + 87, f - 101}] do
      ctx = Calendar.bootstrap_context(c, t)
      reference = Ref.sauce(c, t)
      assert ctx.bowls_after_post_stirs == reference.bowls
      assert ctx.bowls_after_post_stirs ==
               Ref.post_stir12(ctx.bowls_after_drops)
    end
  end

  test "số ngày 2048 bit không tác động công thức vòng cố định" do
    f = Ref.foundation_day()
    shift = (1 <<< 2048) + 1

    for {c, t} <- [{f - shift, f + shift}, {f + shift, f - shift}] do
      ctx = Calendar.bootstrap_context(c, t)
      assert ctx.order_at_46_latch == Ref.sauce(c, t).order_at_drop_46
      assert ctx.order_memory.writes == 58

      for id <- @ids do
        assert Calendar.next_bowl_spaghetti(c, t, id) == rem(id, 6) + 1
      end
    end
  end

  test "không có trạng thái dùng chung ở các lời gọi đồng thời" do
    f = Ref.foundation_day()
    pairs = for k <- -10..10, do: {f + 13 * k, f - 17 * k}

    results =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        max_concurrency: 8, ordered: true, timeout: 15_000
      )
      |> Enum.map(fn {:ok, ctx} -> ctx end)

    Enum.zip(pairs, results)
    |> Enum.each(fn {{c, t}, ctx} ->
      assert ctx.order_at_46_latch == Ref.sauce(c, t).order_at_drop_46
      assert ctx.order_memory.writes == 58
      assert Calendar.next_bowl_spaghetti(c, t, 6) == 1
    end)
  end

  test "đầu vào ngoài sáu ID luôn bị từ chối" do
    for wrong <- [0, 7, -1, nil, 1.5, "3", :ba] do
      assert_raise ArgumentError, "mã bát phải thuộc 1..6", fn ->
        LegacyFixedNameSuccessor.old_next_bowl_fixed_name(wrong)
      end

      f = Ref.foundation_day()
      assert_raise ArgumentError, "mã bát phải thuộc 1..6", fn ->
        Calendar.next_bowl_spaghetti(f, f, wrong)
      end
    end
  end

  test "kiểm toán mã nguồn giữ tên vòng cố định và chưa có Patch 12" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_fixed_name_successor.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()
    latch = Path.join(root, "order_at_46_latch_patch.ex") |> File.read!()

    assert legacy =~ "rem(id, 6) + 1"
    assert dispatcher =~ "LegacyFixedNameSuccessor.old_next_bowl_fixed_name(queried_bowl_id)"
    assert dispatcher =~ "_latch = order_at_46_latch(calculation_day, target_day)"
    assert latch =~ "LegacyOrderMemory.next_bowl("
    refute legacy =~ "OrderAt46LatchPatch"
    refute File.exists?(Path.join(root, "next_bowl_patch_wrapper.ex"))
  end

  test "hồi quy chuẩn vòng giả lập ID 3: cố ý đỏ phát hiện 12" do
    expected = next_from_order(@fixture, 3)
    assert LegacyFixedNameSuccessor.old_next_bowl_fixed_name(3) == expected
  end

  test "hồi quy chuẩn toàn bộ ID ngày gốc: cố ý đỏ phát hiện 12" do
    f = Ref.foundation_day()
    result = Ref.sauce(f, f)
    actual = Enum.map(@ids, &Calendar.next_bowl_spaghetti(f, f, &1))
    expected = Enum.map(@ids, &Ref.next_bowl_in_drop_46_order(result, &1))
    assert actual == expected
  end

  test "hồi quy chuẩn toàn bộ ID khi đảo ngày: cố ý đỏ phát hiện 12" do
    f = Ref.foundation_day()
    c = f + 37
    t = f - 17
    result = Ref.sauce(c, t)
    actual = Enum.map(@ids, &Calendar.next_bowl_spaghetti(c, t, &1))
    expected = Enum.map(@ids, &Ref.next_bowl_in_drop_46_order(result, &1))
    assert actual == expected
  end

  test "hồi quy chuẩn toàn bộ ID ngày rất lớn: cố ý đỏ phát hiện 12" do
    f = Ref.foundation_day()
    shift = 1 <<< 512
    c = f - shift
    t = f + shift
    result = Ref.sauce(c, t)
    actual = Enum.map(@ids, &Calendar.next_bowl_spaghetti(c, t, &1))
    expected = Enum.map(@ids, &Ref.next_bowl_in_drop_46_order(result, &1))
    assert actual == expected
  end
end
