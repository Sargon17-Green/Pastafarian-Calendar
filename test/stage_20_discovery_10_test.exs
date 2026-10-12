defmodule PastafariCalendarElixirVietnamese.Stage20Discovery10Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlAliasPatch,
    BowlDropCalculator,
    BowlVaultPatch,
    LegacyInPlaceStir,
    LegacyPourPositions
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @old %{1 => 13, 2 => 17, 3 => 23, 4 => 29, 5 => 31, 6 => 37}
  @order [4, 5, 6, 1, 2, 3]

  defp correct_step(old, drop, order, stones, index) do
    row = Map.fetch!(stones, index)

    pours = Map.new(1..3, fn position ->
      stone = elem(row, position - 1)
      id = Enum.at(order, position - 1)

      {position,
       Ref.save(drop * drop + stone * Map.fetch!(old, id) +
         (2 * position + 1) * index)}
    end)

    Enum.reduce(1..6, %{}, fn position, next ->
      bowl_id = Enum.at(order, position - 1)
      previous = Enum.at(order, Ref.wrap1(position - 1, 6) - 1)
      following = Enum.at(order, Ref.wrap1(position + 1, 6) - 1)
      kind = Enum.at([1, 2, 3, 4, 5, 1], position - 1)

      mix = Map.fetch!(old, bowl_id) +
        2 * Map.fetch!(old, previous) + 3 * Map.fetch!(old, following) +
        Map.get(pours, position, 0) + drop + elem(row, kind - 1)

      Map.put(next, bowl_id,
        Ref.save(mix * mix +
          5 * Map.fetch!(old, previous) * Map.fetch!(old, following) +
          index * position))
    end)
  end

  defp correct_final(c, t) do
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    visible = Ref.build_visible_drops(counts, stones, hidden)
    initial = Ref.initial_bowls(counts)
    {final, _last_order} = Ref.apply_visible_drops_to_bowls(initial, visible, stones)
    {initial, visible, final}
  end

  defp prepare(old, order, stones, index, drop) do
    row = Map.fetch!(stones, index)

    pours = Map.new(1..3, fn position ->
      {position, BowlAliasPatch.pour(
        old, order, drop, elem(row, position - 1), index, position)}
    end)

    {row, pours}
  end

  test "vị trí đầu tiên chỉ đọc old và trùng công thức chuẩn" do
    stones = Ref.build_stones()
    drop = 71
    {row, pours} = prepare(@old, @order, stones, 1, drop)
    {first_id, first_value} = LegacyInPlaceStir.compute_one(
      @old, pours, drop, row, @order, 1, 1)

    expected = correct_step(@old, drop, @order, stones, 1)
    assert first_id == hd(@order)
    assert first_value == expected[first_id]
  end

  test "vị trí thứ hai đọc giá trị bát đầu đã ghi đè" do
    stones = Ref.build_stones()
    drop = 71
    {row, pours} = prepare(@old, @order, stones, 1, drop)
    {first_id, first_value} = LegacyInPlaceStir.compute_one(
      @old, pours, drop, row, @order, 1, 1)
    current = Map.put(@old, first_id, first_value)
    {second_id, contaminated} = LegacyInPlaceStir.compute_one(
      current, pours, drop, row, @order, 1, 2)
    {^second_id, independent} = LegacyInPlaceStir.compute_one(
      @old, pours, drop, row, @order, 1, 2)

    refute contaminated == independent
    assert second_id == Enum.at(@order, 1)
    assert contaminated >= 1 and contaminated <= Ref.m()
    assert independent == correct_step(@old, drop, @order, stones, 1)[second_id]
  end

  test "mô phỏng lỗi legacy còn nguyên nhưng bản vá không ghi đè lần lượt" do
    stones = Ref.build_stones()
    drop = 79
    {row, pours} = prepare(@old, @order, stones, 3, drop)
    threaded = Enum.reduce(1..6, @old, fn position, current ->
      {id, value} = LegacyInPlaceStir.compute_one(
        current, pours, drop, row, @order, 3, position)
      Map.put(current, id, value)
    end)

    assert LegacyInPlaceStir.run(@old, pours, drop, row, @order, 3) == threaded
    refute BowlDropCalculator.step(@old, drop, @order, stones, 3) == threaded
    assert BowlDropCalculator.step(@old, drop, @order, stones, 3) ==
             correct_step(@old, drop, @order, stones, 3)
    refute threaded == correct_step(@old, drop, @order, stones, 3)
  end

  test "ba lần rót qua alias vẫn lấy đúng ID, lỗi chỉ phát sinh ở khuấy" do
    stones = Ref.build_stones()
    drop = 83
    row = Map.fetch!(stones, 2)

    for position <- 1..3 do
      id = Enum.at(@order, position - 1)
      actual = BowlAliasPatch.pour(
        @old, @order, drop, elem(row, position - 1), 2, position)

      assert actual == Ref.save(
        drop * drop + elem(row, position - 1) * @old[id] +
          (2 * position + 1) * 2
      )
      assert actual == LegacyPourPositions.pour(
        BowlAliasPatch.alias_view(@old, @order),
        drop, elem(row, position - 1), 2, position)
    end
  end

  test "hoán vị đồng nhất được vá, còn legacy vẫn nhiễm nguồn" do
    stones = Ref.build_stones()
    identity = [1, 2, 3, 4, 5, 6]
    actual = BowlDropCalculator.step(@old, 89, identity, stones, 1)
    expected = correct_step(@old, 89, identity, stones, 1)

    assert actual[1] == expected[1]
    assert actual == expected
    assert Enum.sort(Map.keys(actual)) == [1, 2, 3, 4, 5, 6]
  end

  test "sáu tên ID vẫn nguyên sau mỗi lần ghi đè, mọi giá trị thuộc SAVE" do
    stones = Ref.build_stones()

    for index <- [1, 2, 7, 23, 46],
        order <- [@order, [1, 2, 3, 4, 5, 6], [6, 5, 4, 3, 2, 1]] do
      got = BowlDropCalculator.step(@old, 101 + index, order, stones, index)
      assert Map.keys(got) |> Enum.sort() == [1, 2, 3, 4, 5, 6]
      assert Enum.all?(Map.values(got), fn value ->
        is_integer(value) and value >= 1 and value <= Ref.m()
      end)
    end

    assert @old == %{1 => 13, 2 => 17, 3 => 23, 4 => 29, 5 => 31, 6 => 37}
  end

  test "bootstrap thực hiện đủ 46 lần cập nhật không nhiễm" do
    f = Ref.foundation_day()
    c = f - 33
    t = f + 77
    ctx = Calendar.bootstrap_context(c, t)

    assert ctx.bowls_after_drops ==
             BowlDropCalculator.apply_all(
               ctx.initial_bowls, ctx.visible_drops,
               ctx.bowl_orders, ctx.stones_table)
    assert map_size(ctx.bowls_after_drops) == 6

    {initial, visible, expected} = correct_final(c, t)
    assert ctx.initial_bowls == initial
    assert ctx.visible_drops == visible
    assert ctx.bowls_after_drops == expected
  end

  test "các bản vá từ một tới chín còn đúng trước khâu khuấy" do
    f = Ref.foundation_day()
    c = f + 25
    t = f - 17
    ctx = Calendar.bootstrap_context(c, t)
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    visible = Ref.build_visible_drops(counts, stones, hidden)

    assert ctx.stones_table == stones
    assert ctx.visible_drops == visible
    assert ctx.initial_bowls == Ref.initial_bowls(counts)

    for index <- 1..46 do
      assert ctx.bowl_orders[index] == Ref.bowl_order_from_drop(visible[index])
    end

    for k <- 1..7 do
      assert Calendar.hidden_drop_spaghetti(c, t, k) == hidden[k]
    end
  end

  test "ngày 2048 bit không vượt biên SAVE và không gây rò rỉ trạng thái" do
    f = Ref.foundation_day()
    jump = (1 <<< 2048) + 1

    for {c, t} <- [{f - jump, f + jump}, {f + jump, f - jump}] do
      ctx = Calendar.bootstrap_context(c, t)
      assert map_size(ctx.bowls_after_drops) == 6
      assert Enum.all?(Map.values(ctx.bowls_after_drops), fn v ->
        is_integer(v) and v >= 1 and v <= Ref.m()
      end)
      assert ctx.bowls_after_drops == Calendar.bowls_after_drops_spaghetti(c, t)
    end
  end

  test "nhiều context đồng thời vẫn biệt lập mặc dù cùng lỗi khuấy" do
    f = Ref.foundation_day()
    pairs = for j <- -9..9, do: {f + 17 * j, f - 23 * j}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        ordered: true, max_concurrency: 8, timeout: 15_000
      )
      |> Enum.map(fn {:ok, ctx} -> ctx end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, ctx} ->
      assert ctx.bowls_after_drops == Calendar.bowls_after_drops_spaghetti(c, t)
      assert ctx.initial_bowls == Ref.initial_bowls(Ref.work_counts(c, t))
    end)

    first = hd(contexts)
    changed = %{first | bowls_after_drops: Map.put(first.bowls_after_drops, 1, 0)}
    refute changed.bowls_after_drops == first.bowls_after_drops
  end

  test "khi nguồn thiếu hoặc chỉ số sai, báo lỗi thay vì dùng giá trị rác" do
    stones = Ref.build_stones()
    {row, pours} = prepare(@old, @order, stones, 1, 71)

    for bad <- [0, -1, 47, nil, 1.0, "1"] do
      assert_raise ArgumentError, "đầu vào tính một bát không hợp lệ", fn ->
        LegacyInPlaceStir.compute_one(@old, pours, 71, row, @order, 1, bad)
      end
    end

    assert_raise ArgumentError, "đầu vào khuấy tại chỗ không hợp lệ", fn ->
      LegacyInPlaceStir.run(%{}, pours, 71, row, @order, 0)
    end

    assert_raise KeyError, fn ->
      LegacyInPlaceStir.compute_one(%{}, pours, 71, row, @order, 1, 1)
    end
  end

  test "mã nguồn giữ legacy ghi đè và thêm bản vá vaultOld pending" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_in_place_stir.ex") |> File.read!()
    calculator = Path.join(root, "bowl_drop_calculator.ex") |> File.read!()
    alias_patch = Path.join(root, "bowl_alias_patch.ex") |> File.read!()
    vault_patch = Path.join(root, "bowl_vault_patch.ex") |> File.read!()

    assert legacy =~ "Enum.reduce(1..6, old, fn position, current ->"
    assert legacy =~ "compute_one(current, pours, drop, row, order, index, position)"
    assert legacy =~ "Map.put(current, id, updated)"
    assert legacy =~ "Map.fetch!(source, prev_id)"
    assert legacy =~ "Map.fetch!(source, next_id)"
    assert calculator =~ "BowlVaultPatch.run(old, pours, drop, row, order, index)"
    assert vault_patch =~ "vault_old = old"
    assert vault_patch =~ "pending ="
    assert vault_patch =~ "LegacyInPlaceStir.compute_one("
    assert vault_patch =~ "Map.merge(vault_old, pending)"
    assert alias_patch =~ "LegacyPourPositions.pour(bowl_alias, drop, stone, index, position)"
    refute legacy =~ "vault_old"
    refute calculator =~ "vault_old"
    assert File.exists?(Path.join(root, "bowl_vault_patch.ex"))
    refute vault_patch =~ "LegacyInPlaceStir.run("
  end

  test "hồi quy chuẩn lần khuấy đầu: cố ý đỏ tại phát hiện 10" do
    stones = Ref.build_stones()
    assert BowlDropCalculator.step(@old, 71, @order, stones, 1) ==
             correct_step(@old, 71, @order, stones, 1)
  end

  test "hồi quy chuẩn một cặp ngày bằng nhau: cố ý đỏ tại phát hiện 10" do
    f = Ref.foundation_day()
    ctx = Calendar.bootstrap_context(f, f)
    {_initial, _visible, correct} = correct_final(f, f)
    assert ctx.bowls_after_drops == correct
  end

  test "hồi quy chuẩn cặp ngày ngược hướng: cố ý đỏ tại phát hiện 10" do
    f = Ref.foundation_day()
    c = f + 41
    t = f - 47
    ctx = Calendar.bootstrap_context(c, t)
    {_initial, _visible, correct} = correct_final(c, t)
    assert ctx.bowls_after_drops == correct
  end

  test "hồi quy chuẩn ngày lớn hai chiều: cố ý đỏ tại phát hiện 10" do
    f = Ref.foundation_day()
    jump = 1 <<< 512

    for {c, t} <- [{f - jump, f + jump}, {f + jump, f - jump}] do
      ctx = Calendar.bootstrap_context(c, t)
      {_initial, _visible, correct} = correct_final(c, t)
      assert ctx.bowls_after_drops == correct
    end
  end
end
