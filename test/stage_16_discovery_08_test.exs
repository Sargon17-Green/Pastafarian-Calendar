defmodule PastafariCalendarElixirVietnamese.Stage16Discovery08Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlOrderManager,
    LegacyPermutationUnrank0
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  defp correct(drop), do: Ref.bowl_order_from_drop(drop)

  test "hàm cũ mở đúng toàn bộ 720 hạng gốc không" do
    orders =
      Enum.map(0..719, &LegacyPermutationUnrank0.old_permutation_unrank0/1)

    assert length(orders) == 720
    assert length(Enum.uniq(orders)) == 720

    for rank0 <- 0..719 do
      order = Enum.at(orders, rank0)
      assert order == Ref.bowl_order_from_number(rank0 + 1)
      assert Enum.sort(order) == [1, 2, 3, 4, 5, 6]
    end
  end

  test "đầu vào 720 của hàm cũ quay vòng về 0 thay vì gây lỗi" do
    assert LegacyPermutationUnrank0.old_permutation_unrank0(720) ==
             LegacyPermutationUnrank0.old_permutation_unrank0(0)

    assert LegacyPermutationUnrank0.old_permutation_unrank0(1440) ==
             LegacyPermutationUnrank0.old_permutation_unrank0(0)

    assert LegacyPermutationUnrank0.old_permutation_unrank0(721) ==
             LegacyPermutationUnrank0.old_permutation_unrank0(1)
  end

  test "đường lỗi hiện tại chuyển hạng từ một vào hàm gốc không" do
    for drop <- [1, 2, 3, 6, 119, 120, 719, 720, 721, 722, 1440, 1441] do
      one_based = rem(drop - 1, 720) + 1
      actual = BowlOrderManager.order_from_drop(drop)

      assert actual == LegacyPermutationUnrank0.old_permutation_unrank0(one_based)
      assert Enum.sort(actual) == [1, 2, 3, 4, 5, 6]
      refute actual == correct(drop)
    end
  end

  test "hạng một thay vì hạng không đổi ngay hoán vị đầu tiên" do
    assert correct(1) == [1, 2, 3, 4, 5, 6]
    assert BowlOrderManager.order_from_drop(1) == [1, 2, 3, 4, 6, 5]
    assert LegacyPermutationUnrank0.old_permutation_unrank0(0) == [1, 2, 3, 4, 5, 6]
  end

  test "hạng 720 sai vì được coi là hạng gốc không 720 và quay vòng" do
    assert correct(720) == [6, 5, 4, 3, 2, 1]
    assert BowlOrderManager.order_from_drop(720) == [1, 2, 3, 4, 5, 6]
    assert BowlOrderManager.order_from_drop(1440) ==
             BowlOrderManager.order_from_drop(720)
  end

  test "bảng thực sự tính đủ 46 thứ tự bát từ giọt đã vá" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f - 25, f + 31)
    orders = context.bowl_orders

    assert map_size(orders) == 46
    assert Enum.sort(Map.keys(orders)) == Enum.to_list(1..46)
    assert orders == BowlOrderManager.build_orders(context.visible_drops)
    assert Calendar.bowl_orders_spaghetti(f - 25, f + 31) == orders

    for index <- 1..46 do
      drop = context.visible_drops[index]
      assert orders[index] == BowlOrderManager.order_from_drop(drop)
      assert orders[index] ==
               LegacyPermutationUnrank0.old_permutation_unrank0(rem(drop - 1, 720) + 1)
      assert Enum.sort(orders[index]) == [1, 2, 3, 4, 5, 6]
    end
  end

  test "thứ tự bát hiện tại đều lệch chuẩn ở 46 giọt" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 7, f + 21}, {f + 21, f - 7}] do
      context = Calendar.bootstrap_context(c, t)

      for index <- 1..46 do
        drop = context.visible_drops[index]
        refute context.bowl_orders[index] == correct(drop)
        assert Calendar.bowl_order_spaghetti(c, t, index) == context.bowl_orders[index]
      end
    end
  end

  test "các phép vá 01 đến 07 và kết quả 46 giọt còn đúng" do
    f = Ref.foundation_day()
    c = f - 8
    t = f + 11
    context = Calendar.bootstrap_context(c, t)
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)

    assert context.stones_table == stones
    assert context.visible_drops == Ref.build_visible_drops(counts, stones, hidden)
    assert context.hidden_drops_storage ==
             List.to_tuple(Enum.map(7..1//-1, &Map.fetch!(hidden, &1)))

    for k <- 1..7 do
      assert Calendar.hidden_drop_spaghetti(c, t, k) == hidden[k]
    end
  end

  test "phép mở hạng không dùng trạng thái toàn cục khi chạy song song" do
    f = Ref.foundation_day()
    pairs = for delta <- -16..16, do: {f + 23 * delta, f - 19 * delta}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        max_concurrency: 8, ordered: true, timeout: 15_000
      )
      |> Enum.map(fn {:ok, context} -> context end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, ctx} ->
      assert ctx.bowl_orders == Calendar.bowl_orders_spaghetti(c, t)
      assert map_size(ctx.bowl_orders) == 46
    end)

    original = hd(contexts)
    changed = %{original | bowl_orders: Map.put(original.bowl_orders, 1, [])}

    refute changed.bowl_orders == original.bowl_orders
    assert original.bowl_orders ==
             Calendar.bowl_orders_spaghetti(elem(hd(pairs), 0), elem(hd(pairs), 1))
  end

  test "giọt nguyên dương cực lớn giữ thứ tự sáu ID hợp lệ" do
    for drop <- [1 <<< 128, (1 <<< 512) + 9, (1 <<< 2048) + 1] do
      order = BowlOrderManager.order_from_drop(drop)
      one_based = rem(drop - 1, 720) + 1

      assert order == LegacyPermutationUnrank0.old_permutation_unrank0(one_based)
      assert Enum.sort(order) == [1, 2, 3, 4, 5, 6]
      refute order == correct(drop)
    end
  end

  test "biên lỗi đầu vào có thông báo rõ ràng" do
    for bad <- [-1, nil, :sai, "0", 1.5] do
      assert_raise ArgumentError, "hạng hoán vị gốc không phải số nguyên không âm", fn ->
        LegacyPermutationUnrank0.old_permutation_unrank0(bad)
      end
    end

    for bad <- [0, -7, nil, :sai, "10", 2.0] do
      assert_raise ArgumentError, "giọt dùng xếp thứ tự phải là số nguyên dương", fn ->
        BowlOrderManager.order_from_drop(bad)
      end
    end

    for bad <- [0, -1, 47, nil, 3.5, "3"] do
      assert_raise ArgumentError, "chỉ số thứ tự bát phải từ 1 đến 46", fn ->
        BowlOrderManager.read_order(%{1 => [1, 2, 3, 4, 5, 6]}, bad)
      end
    end
  end

  test "mã nguồn giữ bộ mở hạng gốc không và chưa có bản vá 08" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_permutation_unrank0.ex") |> File.read!()
    manager = Path.join(root, "bowl_order_manager.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert legacy =~ "position0 = div(rank0, block)"
    assert legacy =~ "next_rank0 = rem(rank0, block)"
    assert manager =~ "one_based = rem(drop - 1, 720) + 1"
    assert manager =~ "LegacyPermutationUnrank0.old_permutation_unrank0(one_based)"
    assert dispatcher =~ "BowlOrderManager.build_orders(visible_drops)"
    assert dispatcher =~ "bowl_orders: bowl_orders"
    refute manager =~ "legacy_rank0 = one_based - 1"
    refute legacy =~ "NormativeReference"
    refute manager =~ "NormativeReference"
    refute File.exists?(Path.join(root, "permutation_rank_patch.ex"))
  end

  test "hồi quy chuẩn hạng một: cố ý đỏ cho phát hiện 08" do
    assert BowlOrderManager.order_from_drop(1) == Ref.bowl_order_from_drop(1)
  end

  test "hồi quy chuẩn hạng 720: cố ý đỏ cho phát hiện 08" do
    assert BowlOrderManager.order_from_drop(720) == Ref.bowl_order_from_drop(720)
  end

  test "hồi quy chuẩn thứ tự giọt thứ nhất: cố ý đỏ cho phát hiện 08" do
    f = Ref.foundation_day()
    drop = Calendar.visible_drop_spaghetti(f, f, 1)
    assert Calendar.bowl_order_spaghetti(f, f, 1) == correct(drop)
  end

  test "hồi quy chuẩn thứ tự giọt cuối: cố ý đỏ cho phát hiện 08" do
    f = Ref.foundation_day()
    drop = Calendar.visible_drop_spaghetti(f - 12, f + 27, 46)
    assert Calendar.bowl_order_spaghetti(f - 12, f + 27, 46) == correct(drop)
  end
end
