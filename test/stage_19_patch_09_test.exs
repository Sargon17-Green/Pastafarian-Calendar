defmodule PastafariCalendarElixirVietnamese.Stage19Patch09Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlAliasPatch,
    BowlDropCalculator,
    LegacyPourPositions
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @old %{1 => 13, 2 => 17, 3 => 23, 4 => 29, 5 => 31, 6 => 37}
  @reordered [4, 5, 6, 1, 2, 3]

  defp oracle_after_drops(c, t) do
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    visible = Ref.build_visible_drops(counts, stones, hidden)
    initial = Ref.initial_bowls(counts)
    {finished, order_at_46} = Ref.apply_visible_drops_to_bowls(initial, visible, stones)

    {initial, visible, finished, order_at_46}
  end

  defp reference_pour(old, order, drop, stone, index, position) do
    source_id = Enum.at(order, position - 1)
    Ref.save(drop * drop + stone * Map.fetch!(old, source_id) +
      (2 * position + 1) * index)
  end

  test "ánh xạ ba vị trí đúng với ba ID đã hoán vị" do
    view = BowlAliasPatch.alias_view(@old, @reordered)

    assert view == %{1 => 29, 2 => 31, 3 => 37}

    for position <- 1..3 do
      assert view[position] == @old[Enum.at(@reordered, position - 1)]
    end

    assert @old == %{1 => 13, 2 => 17, 3 => 23, 4 => 29, 5 => 31, 6 => 37}
  end

  test "hàm legacy nguyên vẹn vẫn đọc sai ID nếu gọi trực tiếp" do
    for position <- 1..3 do
      assert LegacyPourPositions.read_old(@old, position) == @old[position]
      refute LegacyPourPositions.read_old(@old, position) ==
               @old[Enum.at(@reordered, position - 1)]
    end

    assert LegacyPourPositions.pour(@old, 41, 47, 1, 1) ==
             Ref.save(41 * 41 + 47 * @old[1] + 3)
    refute LegacyPourPositions.pour(@old, 41, 47, 1, 1) ==
             reference_pour(@old, @reordered, 41, 47, 1, 1)
  end

  test "lớp vá thực sự dùng lại legacy với ba khóa nguồn đã ánh xạ" do
    alias_view = BowlAliasPatch.alias_view(@old, @reordered)

    for position <- 1..3 do
      stone = 47 + position
      actual = BowlAliasPatch.pour(@old, @reordered, 41, stone, 1, position)
      delegated = LegacyPourPositions.pour(alias_view, 41, stone, 1, position)

      assert actual == delegated
      assert actual == reference_pour(@old, @reordered, 41, stone, 1, position)
    end
  end

  test "cả 720 hoán vị bảo toàn ba lần đọc nguồn đúng danh tính" do
    for rank1 <- 1..720 do
      order = Ref.bowl_order_from_number(rank1)
      view = BowlAliasPatch.alias_view(@old, order)

      assert map_size(view) == 3

      for position <- 1..3 do
        assert view[position] == Map.fetch!(@old, Enum.at(order, position - 1))
        assert BowlAliasPatch.pour(@old, order, 41, 43 + position, 1, position) ==
                 reference_pour(@old, order, 41, 43 + position, 1, position)
      end
    end
  end

  test "tại hoán vị đồng nhất lớp vá vẫn tương đương phép đọc cũ" do
    identity = [1, 2, 3, 4, 5, 6]
    assert BowlAliasPatch.alias_view(@old, identity) ==
             Map.take(@old, [1, 2, 3])

    for position <- 1..3 do
      assert BowlAliasPatch.pour(@old, identity, 41, 47, 1, position) ==
               LegacyPourPositions.pour(@old, 41, 47, 1, position)
    end
  end

  test "phép cập nhật một giọt không làm thay đổi kho cũ" do
    stones = Ref.build_stones()
    old = @old
    actual = BowlDropCalculator.step(old, 71, @reordered, stones, 1)

    assert old == @old
    assert Enum.sort(Map.keys(actual)) == [1, 2, 3, 4, 5, 6]
    assert Enum.all?(Map.values(actual), fn x ->
      is_integer(x) and x >= 1 and x <= Ref.m()
    end)
    assert actual != old
  end

  test "sáu bát sau 46 giọt trùng oracle cho cả ba chiều ngày" do
    f = Ref.foundation_day()

    for {c, t} <- [
          {f, f},
          {f - 15, f + 31},
          {f + 31, f - 15},
          {f - 2000, f - 1000},
          {f + 1000, f + 2000}
        ] do
      ctx = Calendar.bootstrap_context(c, t)
      {initial, visible, expected, _} = oracle_after_drops(c, t)

      assert ctx.initial_bowls == initial
      assert ctx.visible_drops == visible
      assert ctx.bowls_after_drops == expected
      assert Calendar.bowls_after_drops_spaghetti(c, t) == expected
    end
  end

  test "quét mọi giọt đều dùng đúng thứ tự bát chuẩn" do
    f = Ref.foundation_day()
    c = f - 71
    t = f + 143
    ctx = Calendar.bootstrap_context(c, t)

    assert map_size(ctx.bowl_orders) == 46

    for index <- 1..46 do
      drop = ctx.visible_drops[index]
      order = ctx.bowl_orders[index]

      assert order == Ref.bowl_order_from_drop(drop)
      assert Enum.sort(order) == [1, 2, 3, 4, 5, 6]
    end

    {_initial, _visible, expected, _} = oracle_after_drops(c, t)
    assert ctx.bowls_after_drops == expected
  end

  test "kiểm chứng sáu bát ban đầu vẫn tính đúng từ các bộ đếm ngày" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f + 900, f - 900}, {f - 900, f + 900}] do
      ctx = Calendar.bootstrap_context(c, t)
      counts = Ref.work_counts(c, t)
      expected = Ref.initial_bowls(counts)
      assert ctx.initial_bowls == expected
    end
  end

  test "số nguyên rất lớn 128, 512 và 2048 bit không gây lệch" do
    f = Ref.foundation_day()

    for shift <- [1 <<< 128, (1 <<< 512) + 7, 1 <<< 2048] do
      for {c, t} <- [{f - shift, f + shift}, {f + shift, f - shift}] do
        ctx = Calendar.bootstrap_context(c, t)
        {initial, _visible, expected, _} = oracle_after_drops(c, t)

        assert ctx.initial_bowls == initial
        assert ctx.bowls_after_drops == expected
        assert Enum.all?(Map.values(ctx.bowls_after_drops), fn x ->
          is_integer(x) and x >= 1 and x <= Ref.m()
        end)
      end
    end
  end

  test "đồng thời không chia sẻ trạng thái ngữ nghĩa bát" do
    f = Ref.foundation_day()
    pairs = for k <- -13..13, do: {f + 31 * k, f - 29 * k}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        max_concurrency: 8, ordered: true, timeout: 15_000
      )
      |> Enum.map(fn {:ok, ctx} -> ctx end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, ctx} ->
      {_initial, _visible, expected, _} = oracle_after_drops(c, t)
      assert ctx.bowls_after_drops == expected
    end)

    first = hd(contexts)
    changed = %{first | bowls_after_drops: Map.put(first.bowls_after_drops, 1, 0)}
    refute changed.bowls_after_drops == first.bowls_after_drops
  end

  test "đầu vào sai và vị trí ngoài 1..3 bị từ chối" do
    for bad <- [nil, [], :khong_hop_le, "bad"] do
      assert_raise ArgumentError, "kho bát và hoán vị rót phải hợp lệ", fn ->
        BowlAliasPatch.alias_view(bad, @reordered)
      end
    end

    for bad <- [nil, [], [1, 2, 3], :loi] do
      assert_raise ArgumentError, "kho bát và hoán vị rót phải hợp lệ", fn ->
        BowlAliasPatch.alias_view(@old, bad)
      end
    end

    for position <- [0, -1, 4, nil, "1"] do
      assert_raise ArgumentError, "đầu vào phép rót lịch sử không hợp lệ", fn ->
        BowlAliasPatch.pour(@old, @reordered, 41, 47, 1, position)
      end
    end
  end

  test "bằng chứng nguồn: giữ alias rót và thực thi khuấy in-place lịch sử" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_pour_positions.ex") |> File.read!()
    patch = Path.join(root, "bowl_alias_patch.ex") |> File.read!()
    calculator = Path.join(root, "bowl_drop_calculator.ex") |> File.read!()
    legacy_stir = Path.join(root, "legacy_in_place_stir.ex") |> File.read!()

    assert legacy =~ "Map.fetch!(bowls_old, position)"
    refute legacy =~ "BowlAliasPatch"
    assert patch =~ "Map.put(bowl_alias, position, Map.fetch!(bowls_old, id))"
    assert patch =~ "LegacyPourPositions.pour(bowl_alias, drop, stone, index, position)"
    assert calculator =~ "BowlAliasPatch.pour("
    assert legacy_stir =~ "Map.fetch!(source, id)"
    assert legacy_stir =~ "Map.put(current, id, updated)"
    refute calculator =~ "LegacyPourPositions.pour("
    refute patch =~ "NormativeReference"
  end

  test "đã phát hiện lỗi khuấy in-place nhưng lịch vẫn chưa tích hợp" do
    f = Ref.foundation_day()
    ctx = Calendar.bootstrap_context(f, f)

    assert ctx.phase == :bootstrap
    assert map_size(ctx.bowls_after_drops) == 6

    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end
end
