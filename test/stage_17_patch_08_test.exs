defmodule PastafariCalendarElixirVietnamese.Stage17Patch08Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlOrderManager,
    LegacyPermutationUnrank0
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "720 hoán vị của đường sản xuất khớp toàn bộ oracle độc lập" do
    orders = Enum.map(1..720, &BowlOrderManager.order_from_drop/1)
    assert length(orders) == 720
    assert length(Enum.uniq(orders)) == 720

    for rank1 <- 1..720 do
      got = Enum.at(orders, rank1 - 1)
      assert got == Ref.bowl_order_from_number(rank1)
      assert Enum.sort(got) == [1, 2, 3, 4, 5, 6]
    end
  end

  test "hàm lịch sử tiếp tục hoạt động độc lập với đầu vào hạng gốc không" do
    for rank0 <- 0..719 do
      assert LegacyPermutationUnrank0.old_permutation_unrank0(rank0) ==
               Ref.bowl_order_from_number(rank0 + 1)
    end

    assert LegacyPermutationUnrank0.old_permutation_unrank0(720) ==
             LegacyPermutationUnrank0.old_permutation_unrank0(0)
    assert LegacyPermutationUnrank0.old_permutation_unrank0(721) ==
             LegacyPermutationUnrank0.old_permutation_unrank0(1)
  end

  test "cả đầu 1 và cuối 720 qua lớp vá đều được đặt đúng" do
    assert BowlOrderManager.order_from_drop(1) == [1, 2, 3, 4, 5, 6]
    assert BowlOrderManager.order_from_drop(720) == [6, 5, 4, 3, 2, 1]

    assert LegacyPermutationUnrank0.old_permutation_unrank0(1) ==
             [1, 2, 3, 4, 6, 5]
    assert LegacyPermutationUnrank0.old_permutation_unrank0(720) ==
             [1, 2, 3, 4, 5, 6]
  end

  test "các mốc bội 720, ngay trước và sau đều đúng" do
    drops = [
      1, 2, 6, 119, 120, 121, 719, 720, 721, 722,
      1439, 1440, 1441, 2159, 2160, 2161
    ]

    for drop <- drops do
      one_based = rem(drop - 1, 720) + 1
      legacy_rank0 = one_based - 1
      assert BowlOrderManager.order_from_drop(drop) ==
               LegacyPermutationUnrank0.old_permutation_unrank0(legacy_rank0)
      assert BowlOrderManager.order_from_drop(drop) == Ref.bowl_order_from_drop(drop)
    end

    assert BowlOrderManager.order_from_drop(1) == BowlOrderManager.order_from_drop(721)
    assert BowlOrderManager.order_from_drop(720) == BowlOrderManager.order_from_drop(1440)
  end

  test "sai lệch cũ đúng một hạng vẫn tái hiện khi gọi legacy trực tiếp" do
    for rank1 <- 1..720 do
      correct = BowlOrderManager.order_from_drop(rank1)
      raw_wrong = LegacyPermutationUnrank0.old_permutation_unrank0(rank1)

      assert correct == Ref.bowl_order_from_number(rank1)
      refute raw_wrong == correct
      assert raw_wrong ==
               Ref.bowl_order_from_number(rem(rank1, 720) + 1)
    end
  end

  test "bộ quản lý dùng cùng giọt từ bootstrap trên toàn bộ 46 vị trí" do
    f = Ref.foundation_day()
    c = f - 131
    t = f + 271
    context = Calendar.bootstrap_context(c, t)

    assert map_size(context.bowl_orders) == 46
    assert context.bowl_orders == BowlOrderManager.build_orders(context.visible_drops)
    assert Calendar.bowl_orders_spaghetti(c, t) == context.bowl_orders

    for i <- 1..46 do
      expected = Ref.bowl_order_from_drop(context.visible_drops[i])
      assert context.bowl_orders[i] == expected
      assert Calendar.bowl_order_spaghetti(c, t, i) == expected
    end
  end

  test "kiểm soát kết quả 46 giọt và thứ tự trên các chiều ngày" do
    f = Ref.foundation_day()
    pairs = [
      {f, f}, {f - 1, f}, {f, f + 1},
      {f - 333, f + 91}, {f + 91, f - 333},
      {f + 700, f + 701}, {f - 700, f - 701}
    ]

    for {c, t} <- pairs do
      context = Calendar.bootstrap_context(c, t)
      counts = Ref.work_counts(c, t)
      stones = Ref.build_stones()
      hidden = Ref.build_hidden_drops(counts, stones)
      visible = Ref.build_visible_drops(counts, stones, hidden)

      assert context.visible_drops == visible

      for i <- 1..46 do
        assert context.bowl_orders[i] == Ref.bowl_order_from_drop(visible[i])
      end
    end
  end

  test "bản vá không sửa cấu trúc cũ, không trộn thứ tự với giọt ẩn" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f - 19, f + 55)
    counts = Ref.work_counts(f - 19, f + 55)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)

    assert context.stones_table == stones
    assert context.hidden_drops_storage ==
             List.to_tuple(Enum.map(7..1//-1, &Map.fetch!(hidden, &1)))
    assert context.visible_drops == Ref.build_visible_drops(counts, stones, hidden)

    for index <- 1..7 do
      assert Calendar.hidden_drop_spaghetti(f - 19, f + 55, index) == hidden[index]
    end
  end

  test "số nguyên lớn 128, 512 và 2048 bit vẫn mở đúng hoán vị" do
    for drop <- [1 <<< 128, (1 <<< 512) + 1, (1 <<< 2048) + 197] do
      assert BowlOrderManager.order_from_drop(drop) == Ref.bowl_order_from_drop(drop)
      assert Enum.sort(BowlOrderManager.order_from_drop(drop)) == [1, 2, 3, 4, 5, 6]
    end

    f = Ref.foundation_day()
    big = 1 <<< 512

    for {c, t} <- [{f + big, f - big}, {f - big, f + big}] do
      context = Calendar.bootstrap_context(c, t)

      for i <- 1..46 do
        assert context.bowl_orders[i] ==
                 Ref.bowl_order_from_drop(context.visible_drops[i])
      end
    end
  end

  test "thao tác song song sở hữu kho riêng và cùng kết quả chuẩn" do
    f = Ref.foundation_day()
    pairs = for delta <- -16..16, do: {f + delta * 13, f - delta * 17}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        max_concurrency: 8, ordered: true, timeout: 15_000
      )
      |> Enum.map(fn {:ok, context} -> context end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, context} ->
      assert context.bowl_orders == Calendar.bowl_orders_spaghetti(c, t)
      assert map_size(context.bowl_orders) == 46

      for i <- 1..46 do
        assert context.bowl_orders[i] ==
                 Ref.bowl_order_from_drop(context.visible_drops[i])
      end
    end)

    first = hd(contexts)
    changed = %{first | bowl_orders: Map.put(first.bowl_orders, 1, [])}
    refute changed.bowl_orders == first.bowl_orders
    assert first.bowl_orders ==
             Calendar.bowl_orders_spaghetti(elem(hd(pairs), 0), elem(hd(pairs), 1))
  end

  test "xác minh mọi phép gán đều trả sáu ID đúng không trùng" do
    for drop <- 1..720 do
      order = BowlOrderManager.order_from_drop(drop)
      assert length(order) == 6
      assert length(Enum.uniq(order)) == 6
      assert Enum.sort(order) == [1, 2, 3, 4, 5, 6]
    end
  end

  test "lỗi đầu vào được giữ nguyên khi vá hạng" do
    for invalid <- [0, -1, nil, :loi, "1", 1.0] do
      assert_raise ArgumentError, "giọt dùng xếp thứ tự phải là số nguyên dương", fn ->
        BowlOrderManager.order_from_drop(invalid)
      end
    end

    for invalid <- [-1, nil, :loi, "0", 0.5] do
      assert_raise ArgumentError, "hạng hoán vị gốc không phải số nguyên không âm", fn ->
        LegacyPermutationUnrank0.old_permutation_unrank0(invalid)
      end
    end

    for invalid <- [0, -1, 47, nil, 2.0, "2"] do
      assert_raise ArgumentError, "chỉ số thứ tự bát phải từ 1 đến 46", fn ->
        BowlOrderManager.read_order(%{1 => [1, 2, 3, 4, 5, 6]}, invalid)
      end
    end
  end

  test "mã nguồn kiểm chứng chuỗi vá giữ nguyên hàm mở hạng thực" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_permutation_unrank0.ex") |> File.read!()
    manager = Path.join(root, "bowl_order_manager.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert legacy =~ "position0 = div(rank0, block)"
    assert legacy =~ "next_rank0 = rem(rank0, block)"
    assert manager =~ "one_based = rem(drop - 1, 720) + 1"
    assert manager =~ "legacy_rank0 = one_based - 1"
    assert manager =~ "LegacyPermutationUnrank0.old_permutation_unrank0(legacy_rank0)"
    refute manager =~ "LegacyPermutationUnrank0.old_permutation_unrank0(one_based)"
    assert dispatcher =~ "BowlOrderManager.build_orders(visible_drops)"
    assert dispatcher =~ "bowl_orders: bowl_orders"
    refute manager =~ "NormativeReference"
    refute legacy =~ "NormativeReference"
  end

  test "giữ biên chưa tích hợp bát và lịch ở những giai đoạn sau" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f, f)
    assert context.phase == :bootstrap
    assert map_size(context.bowl_orders) == 46

    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)

    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    refute File.exists?(Path.join(root, "permutation_rank_patch.ex"))
  end
end
