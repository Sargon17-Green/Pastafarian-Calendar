defmodule PastafariCalendarElixirVietnamese.Stage18Discovery09Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlDropCalculator,
    BowlSeedCalculator,
    BowlAliasPatch,
    LegacyPourPositions
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  defp context_and_oracle(c, t) do
    context = Calendar.bootstrap_context(c, t)
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    visible = context.visible_drops
    initial = Ref.initial_bowls(counts)
    {correct_after, _order_latch} =
      Ref.apply_visible_drops_to_bowls(initial, visible, stones)

    {context, initial, correct_after}
  end

  defp correct_pour(old, drop, stone, index, position, order) do
    alias_id = Enum.at(order, position - 1)

    Ref.save(drop * drop + stone * Map.fetch!(old, alias_id) +
      (2 * position + 1) * index)
  end

  defp correct_step(old, drop, order, stones, index) do
    row = Map.fetch!(stones, index)
    pours = Map.new(1..3, fn position ->
      {position, correct_pour(old, drop, elem(row, position - 1),
        index, position, order)}
    end)

    Enum.reduce(1..6, %{}, fn position, acc ->
      bowl_id = Enum.at(order, position - 1)
      prev_id = Enum.at(order, Ref.wrap1(position - 1, 6) - 1)
      next_id = Enum.at(order, Ref.wrap1(position + 1, 6) - 1)
      stir_kind = Enum.at([1, 2, 3, 4, 5, 1], position - 1)

      mix = Map.fetch!(old, bowl_id) + 2 * Map.fetch!(old, prev_id) +
        3 * Map.fetch!(old, next_id) + Map.get(pours, position, 0) +
        drop + elem(row, stir_kind - 1)

      result = Ref.save(mix * mix +
        5 * Map.fetch!(old, prev_id) * Map.fetch!(old, next_id) +
        index * position)

      Map.put(acc, bowl_id, result)
    end)
  end

  test "khởi tạo sáu bát khớp chuẩn trước khi rót" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 9, f + 17}, {f + 17, f - 9}] do
      context = Calendar.bootstrap_context(c, t)
      counts = Ref.work_counts(c, t)
      expected = Ref.initial_bowls(counts)

      assert BowlSeedCalculator.calculate(
        counts.action, counts.target, counts.distance, counts.direction
      ) == expected

      assert context.initial_bowls == expected
      assert Calendar.initial_bowls_spaghetti(c, t) == expected
      assert Map.keys(expected) |> Enum.sort() == Enum.to_list(1..6)
    end
  end

  test "hàm legacy lấy số vị trí 1,2,3 thay vì alias tên bát" do
    old = %{1 => 13, 2 => 17, 3 => 23, 4 => 29, 5 => 31, 6 => 37}
    order = [4, 5, 6, 1, 2, 3]

    for position <- 1..3 do
      actual = LegacyPourPositions.read_old(old, position)
      correct_bowl_id = Enum.at(order, position - 1)
      assert actual == old[position]
      refute actual == old[correct_bowl_id]
    end
  end

  test "công thức ba lần rót dùng sai ID thật dù vẫn SAVE đúng" do
    old = %{1 => 13, 2 => 17, 3 => 23, 4 => 29, 5 => 31, 6 => 37}
    order = [4, 5, 6, 1, 2, 3]
    drop = 41

    for position <- 1..3 do
      stone = 43 + position
      actual = LegacyPourPositions.pour(old, drop, stone, 1, position)
      wrong = Ref.save(drop * drop + stone * old[position] +
        (2 * position + 1) * 1)
      expected = correct_pour(old, drop, stone, 1, position, order)

      assert actual == wrong
      refute actual == expected
      assert actual >= 1 and actual <= Ref.m()
    end
  end

  test "khi thứ tự danh tính trùng vị trí, rót legacy không gây lệch" do
    old = %{1 => 19, 2 => 23, 3 => 29, 4 => 31, 5 => 37, 6 => 41}
    order = [1, 2, 3, 4, 5, 6]
    stones = Ref.build_stones()
    drop = 71

    assert BowlDropCalculator.step(old, drop, order, stones, 1) ==
             correct_step(old, drop, order, stones, 1)
  end

  test "bản vá 09 cập nhật đúng ID qua alias mà vẫn giữ snapshot cũ" do
    old = %{1 => 19, 2 => 23, 3 => 29, 4 => 31, 5 => 37, 6 => 41}
    order = [4, 5, 6, 1, 2, 3]
    stones = Ref.build_stones()
    drop = 71
    next_wrong = BowlDropCalculator.step(old, drop, order, stones, 1)
    next_correct = correct_step(old, drop, order, stones, 1)

    assert Enum.sort(Map.keys(next_wrong)) == Enum.to_list(1..6)
    assert next_wrong == next_correct
    assert Enum.all?(Map.values(next_wrong), fn n -> n >= 1 and n <= Ref.m() end)
    assert old == %{1 => 19, 2 => 23, 3 => 29, 4 => 31, 5 => 37, 6 => 41}
  end

  test "đường bootstrap thực sự cập nhật đủ 46 giọt trong sáu bát" do
    f = Ref.foundation_day()
    {ctx, initial, correct_after} = context_and_oracle(f - 9, f + 17)

    assert ctx.initial_bowls == initial
    assert ctx.bowls_after_drops ==
             BowlDropCalculator.apply_all(initial, ctx.visible_drops,
               ctx.bowl_orders, ctx.stones_table)
    assert Calendar.bowls_after_drops_spaghetti(f - 9, f + 17) ==
             ctx.bowls_after_drops
    assert Enum.sort(Map.keys(ctx.bowls_after_drops)) == Enum.to_list(1..6)
    assert ctx.bowls_after_drops == correct_after
  end

  test "nguồn rót qua alias giữ thứ tự bát chuẩn" do
    f = Ref.foundation_day()
    c = f - 31
    t = f + 57
    ctx = Calendar.bootstrap_context(c, t)

    for i <- 1..46 do
      assert ctx.bowl_orders[i] == Ref.bowl_order_from_drop(ctx.visible_drops[i])
      assert Enum.sort(ctx.bowl_orders[i]) == [1, 2, 3, 4, 5, 6]
    end

    assert ctx.initial_bowls == Ref.initial_bowls(Ref.work_counts(c, t))
  end

  test "nền SAVE, đá, giọt ẩn và 46 giọt không bị sửa" do
    f = Ref.foundation_day()
    c = f + 12
    t = f - 16
    ctx = Calendar.bootstrap_context(c, t)
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)

    assert ctx.stones_table == stones
    assert ctx.visible_drops == Ref.build_visible_drops(counts, stones, hidden)
    assert ctx.hidden_drops_storage ==
             List.to_tuple(Enum.map(7..1//-1, &Map.fetch!(hidden, &1)))

    for index <- 1..7 do
      assert Calendar.hidden_drop_spaghetti(c, t, index) == hidden[index]
    end
  end

  test "ngày rất lớn vẫn cho đúng miền SAVE trong sáu bát" do
    f = Ref.foundation_day()
    big = (1 <<< 512) + 1

    for {c, t} <- [{f - big, f + big}, {f + big, f - big}] do
      ctx = Calendar.bootstrap_context(c, t)
      assert map_size(ctx.bowls_after_drops) == 6
      assert Enum.all?(Map.values(ctx.bowls_after_drops), fn n ->
        is_integer(n) and n >= 1 and n <= Ref.m()
      end)
      assert ctx.initial_bowls == Ref.initial_bowls(Ref.work_counts(c, t))
    end
  end

  test "chạy song song không làm lẫn nguồn rót của các lần gọi" do
    f = Ref.foundation_day()
    pairs = for delta <- -12..12, do: {f + 13 * delta, f - 17 * delta}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        max_concurrency: 8, timeout: 15_000, ordered: true
      )
      |> Enum.map(fn {:ok, ctx} -> ctx end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, ctx} ->
      assert ctx.bowls_after_drops ==
               Calendar.bowls_after_drops_spaghetti(c, t)
    end)

    original = hd(contexts)
    changed = %{original | bowls_after_drops: Map.put(original.bowls_after_drops, 1, 0)}
    refute changed.bowls_after_drops == original.bowls_after_drops
    assert original.bowls_after_drops ==
             Calendar.bowls_after_drops_spaghetti(elem(hd(pairs), 0),
               elem(hd(pairs), 1))
  end

  test "biên đầu vào rót được kiểm tra nhưng lịch chưa tích hợp" do
    old = %{1 => 2, 2 => 3, 3 => 5, 4 => 7, 5 => 11, 6 => 13}

    for bad <- [0, 4, -1, nil, "1", 1.5] do
      assert_raise ArgumentError, "vị trí rót phải thuộc 1..3", fn ->
        LegacyPourPositions.read_old(old, bad)
      end
    end

    assert_raise ArgumentError, "đầu vào phép rót lịch sử không hợp lệ", fn ->
      LegacyPourPositions.pour(old, 7, 11, 0, 1)
    end

    f = Ref.foundation_day()
    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(f, f)
    end
  end

  test "mã nguồn giữ alias rót và chuyển khuấy qua legacy in-place" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_pour_positions.ex") |> File.read!()
    calculator = Path.join(root, "bowl_drop_calculator.ex") |> File.read!()
    legacy_stir = Path.join(root, "legacy_in_place_stir.ex") |> File.read!()
    patch = Path.join(root, "bowl_alias_patch.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert legacy =~ "Map.fetch!(bowls_old, position)"
    assert calculator =~ "BowlAliasPatch.pour("
    assert patch =~ "LegacyPourPositions.pour(bowl_alias, drop, stone, index, position)"
    assert patch =~ "Map.put(bowl_alias, position, Map.fetch!(bowls_old, id))"
    assert legacy_stir =~ "Map.put(current, id, updated)"
    assert legacy_stir =~ "Map.fetch!(source, id)"
    assert dispatcher =~ "BowlDropCalculator.apply_all_with_order_memory("
    refute legacy =~ "bowl_alias"
    assert File.exists?(Path.join(root, "bowl_alias_patch.ex"))
    refute calculator =~ "LegacyPourPositions.pour("
  end

  test "hồi quy chuẩn nguồn rót đầu tiên: cố ý đỏ cho phát hiện 09" do
    old = %{1 => 13, 2 => 17, 3 => 23, 4 => 29, 5 => 31, 6 => 37}
    order = [4, 5, 6, 1, 2, 3]
    got = BowlAliasPatch.pour(old, order, 41, 47, 1, 1)
    assert got == correct_pour(old, 41, 47, 1, 1, order)
  end

  test "hồi quy chuẩn bước khuấy đầu: cố ý đỏ cho phát hiện 09" do
    old = %{1 => 19, 2 => 23, 3 => 29, 4 => 31, 5 => 37, 6 => 41}
    order = [4, 5, 6, 1, 2, 3]
    stones = Ref.build_stones()
    assert BowlDropCalculator.step(old, 71, order, stones, 1) ==
             correct_step(old, 71, order, stones, 1)
  end

  test "hồi quy chuẩn sau 46 giọt: cố ý đỏ cho phát hiện 09" do
    f = Ref.foundation_day()
    {ctx, _initial, correct_after} = context_and_oracle(f, f)
    assert ctx.bowls_after_drops == correct_after
  end

  test "hồi quy chuẩn sau 46 giọt hai chiều ngày: cố ý đỏ cho phát hiện 09" do
    f = Ref.foundation_day()

    for {c, t} <- [{f - 13, f + 27}, {f + 27, f - 13}] do
      {ctx, _initial, correct_after} = context_and_oracle(c, t)
      assert ctx.bowls_after_drops == correct_after
    end
  end
end
