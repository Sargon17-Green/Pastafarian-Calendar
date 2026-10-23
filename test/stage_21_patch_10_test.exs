defmodule PastafariCalendarElixirVietnamese.Stage21Patch10Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlAliasPatch,
    BowlDropCalculator,
    BowlVaultPatch,
    LegacyInPlaceStir
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @old %{1 => 13, 2 => 17, 3 => 23, 4 => 29, 5 => 31, 6 => 37}
  @order [4, 5, 6, 1, 2, 3]

  defp pours(old, order, drop, row, index) do
    Map.new(1..3, fn position ->
      {position,
       BowlAliasPatch.pour(old, order, drop, elem(row, position - 1), index, position)}
    end)
  end

  defp independent_step(old, order, drop, row, index) do
    source_pours =
      Map.new(1..3, fn position ->
        id = Enum.at(order, position - 1)
        {position,
         Ref.save(drop * drop + elem(row, position - 1) * Map.fetch!(old, id) +
           (2 * position + 1) * index)}
      end)

    Enum.reduce(1..6, %{}, fn position, acc ->
      id = Enum.at(order, position - 1)
      prev_id = Enum.at(order, Ref.wrap1(position - 1, 6) - 1)
      next_id = Enum.at(order, Ref.wrap1(position + 1, 6) - 1)
      kind = Enum.at([1, 2, 3, 4, 5, 1], position - 1)

      mix =
        Map.fetch!(old, id) +
          2 * Map.fetch!(old, prev_id) +
          3 * Map.fetch!(old, next_id) +
          Map.get(source_pours, position, 0) +
          drop + elem(row, kind - 1)

      updated =
        Ref.save(mix * mix +
          5 * Map.fetch!(old, prev_id) * Map.fetch!(old, next_id) +
          index * position)

      Map.put(acc, id, updated)
    end)
  end

  defp normative_bowls(c, t) do
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    visible = Ref.build_visible_drops(counts, stones, hidden)
    initial = Ref.initial_bowls(counts)
    {finished, _order46} = Ref.apply_visible_drops_to_bowls(initial, visible, stones)
    {initial, visible, finished}
  end

  test "cả sáu phép tính lấy cùng vaultOld và commit sau khi đủ pending" do
    row = Map.fetch!(Ref.build_stones(), 1)
    source_pours = pours(@old, @order, 71, row, 1)
    expected_pending =
      Enum.reduce(1..6, %{}, fn position, acc ->
        {id, value} = LegacyInPlaceStir.compute_one(
          @old, source_pours, 71, row, @order, 1, position)
        Map.put(acc, id, value)
      end)

    actual = BowlVaultPatch.run(@old, source_pours, 71, row, @order, 1)
    assert map_size(expected_pending) == 6
    assert actual == Map.merge(@old, expected_pending)
    assert actual == expected_pending
    assert @old == %{1 => 13, 2 => 17, 3 => 23, 4 => 29, 5 => 31, 6 => 37}
  end

  test "vị trí một và hai tính từ vault bất biến chứ không từ current đã ghi" do
    row = Map.fetch!(Ref.build_stones(), 1)
    source_pours = pours(@old, @order, 71, row, 1)
    {first_id, first_value} = LegacyInPlaceStir.compute_one(
      @old, source_pours, 71, row, @order, 1, 1)
    {second_id, correct_second} = LegacyInPlaceStir.compute_one(
      @old, source_pours, 71, row, @order, 1, 2)
    {^second_id, corrupted_second} = LegacyInPlaceStir.compute_one(
      Map.put(@old, first_id, first_value),
      source_pours, 71, row, @order, 1, 2)

    actual = BowlVaultPatch.run(@old, source_pours, 71, row, @order, 1)
    assert actual[first_id] == first_value
    assert actual[second_id] == correct_second
    refute actual[second_id] == corrupted_second
  end

  test "run cũ vẫn tái hiện lỗi nhiễm, bản vá không xóa legacy" do
    row = Map.fetch!(Ref.build_stones(), 1)
    source_pours = pours(@old, @order, 71, row, 1)

    historical = LegacyInPlaceStir.run(@old, source_pours, 71, row, @order, 1)
    corrected = BowlVaultPatch.run(@old, source_pours, 71, row, @order, 1)

    refute historical == corrected
    assert corrected == independent_step(@old, @order, 71, row, 1)
    assert historical[hd(@order)] == corrected[hd(@order)]
  end

  test "cả 720 hoán vị đều khớp công thức độc lập của sáu vị trí" do
    row = Map.fetch!(Ref.build_stones(), 1)

    for rank <- 1..720 do
      order = Ref.bowl_order_from_number(rank)
      source_pours = pours(@old, order, 79, row, 1)
      actual = BowlVaultPatch.run(@old, source_pours, 79, row, order, 1)
      expected = independent_step(@old, order, 79, row, 1)

      assert actual == expected
      assert Map.keys(actual) |> Enum.sort() == [1, 2, 3, 4, 5, 6]
    end
  end

  test "cùng dữ liệu có thứ tự đồng nhất cũng không còn đọc đè" do
    order = [1, 2, 3, 4, 5, 6]
    row = Map.fetch!(Ref.build_stones(), 1)
    source_pours = pours(@old, order, 89, row, 1)

    assert BowlVaultPatch.run(@old, source_pours, 89, row, order, 1) ==
             independent_step(@old, order, 89, row, 1)
    refute LegacyInPlaceStir.run(@old, source_pours, 89, row, order, 1) ==
             independent_step(@old, order, 89, row, 1)
  end

  test "BowlDropCalculator.step đã định tuyến qua vault ở ba chỉ số" do
    stones = Ref.build_stones()

    for index <- [1, 23, 46], order <- [
          @order, [1, 2, 3, 4, 5, 6], [6, 5, 4, 3, 2, 1]
        ] do
      drop = 71 + index
      row = Map.fetch!(stones, index)
      source_pours = pours(@old, order, drop, row, index)
      expected = independent_step(@old, order, drop, row, index)

      assert BowlDropCalculator.step(@old, drop, order, stones, index) ==
               BowlVaultPatch.run(@old, source_pours, drop, row, order, index)
      assert BowlDropCalculator.step(@old, drop, order, stones, index) == expected
    end
  end

  test "sáu bát sau 46 giọt khớp oracle với ngày bằng nhau và hai chiều" do
    f = Ref.foundation_day()
    pairs = [
      {f, f},
      {f - 1, f},
      {f, f + 1},
      {f - 101, f + 89},
      {f + 89, f - 101},
      {f + 333, f + 334},
      {f - 333, f - 334}
    ]

    for {c, t} <- pairs do
      {initial, visible, expected} = normative_bowls(c, t)
      ctx = Calendar.bootstrap_context(c, t)

      assert ctx.initial_bowls == initial
      assert ctx.visible_drops == visible
      assert ctx.bowls_after_drops == expected
      assert Calendar.bowls_after_drops_spaghetti(c, t) == expected
    end
  end

  test "đá, giọt, thứ tự bát và ba nguồn rót đã vá không bị ảnh hưởng" do
    f = Ref.foundation_day()
    c = f - 7
    t = f + 57
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    visible = Ref.build_visible_drops(counts, stones, hidden)
    ctx = Calendar.bootstrap_context(c, t)

    assert ctx.stones_table == stones
    assert ctx.visible_drops == visible

    for index <- 1..46 do
      assert ctx.bowl_orders[index] == Ref.bowl_order_from_drop(visible[index])
    end

    for number <- 1..7 do
      assert Calendar.hidden_drop_spaghetti(c, t, number) == hidden[number]
    end

    for position <- 1..3 do
      id = Enum.at(@order, position - 1)
      row = Map.fetch!(stones, 1)
      drop = 73
      assert BowlAliasPatch.pour(@old, @order, drop, elem(row, position - 1), 1, position) ==
               Ref.save(drop * drop + elem(row, position - 1) * @old[id] +
                 (2 * position + 1))
    end
  end

  test "số nguyên 128, 512 và 2048 bit không phá vault hoặc miền SAVE" do
    f = Ref.foundation_day()

    for jump <- [1 <<< 128, (1 <<< 512) + 7, 1 <<< 2048] do
      for {c, t} <- [{f - jump, f + jump}, {f + jump, f - jump}] do
        ctx = Calendar.bootstrap_context(c, t)
        {initial, _visible, expected} = normative_bowls(c, t)

        assert ctx.initial_bowls == initial
        assert ctx.bowls_after_drops == expected
        assert Enum.all?(Map.values(ctx.bowls_after_drops), fn value ->
          is_integer(value) and value >= 1 and value <= Ref.m()
        end)
      end
    end
  end

  test "nhiều context song song trả kết quả chuẩn, không lây trạng thái" do
    f = Ref.foundation_day()
    pairs = for k <- -17..17, do: {f + 23 * k, f - 29 * k}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        max_concurrency: 8, ordered: true, timeout: 15_000
      )
      |> Enum.map(fn {:ok, ctx} -> ctx end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, ctx} ->
      {_initial, _visible, expected} = normative_bowls(c, t)
      assert ctx.bowls_after_drops == expected
    end)

    first = hd(contexts)
    modified = %{first | bowls_after_drops: Map.put(first.bowls_after_drops, 1, 0)}
    refute modified.bowls_after_drops == first.bowls_after_drops
    assert first.bowls_after_drops ==
             Calendar.bowls_after_drops_spaghetti(elem(hd(pairs), 0), elem(hd(pairs), 1))
  end

  test "thiếu nguồn hoặc vị trí bất hợp lệ vẫn báo lỗi rõ ràng" do
    row = Map.fetch!(Ref.build_stones(), 1)
    source_pours = pours(@old, @order, 71, row, 1)

    for bad <- [0, -1, 47, nil, 2.0, "1"] do
      assert_raise ArgumentError, "đầu vào bản vá kho bát không hợp lệ", fn ->
        BowlVaultPatch.run(@old, source_pours, 71, row, @order, bad)
      end
    end

    assert_raise KeyError, fn ->
      BowlVaultPatch.run(%{}, source_pours, 71, row, @order, 1)
    end

    assert_raise ArgumentError, "đầu vào bản vá kho bát không hợp lệ", fn ->
      BowlVaultPatch.run(@old, source_pours, 71, row, [1, 2, 3], 1)
    end
  end

  test "mã nguồn giữ run lịch sử sai và áp dụng pending cùng lúc" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_in_place_stir.ex") |> File.read!()
    patch = Path.join(root, "bowl_vault_patch.ex") |> File.read!()
    calculator = Path.join(root, "bowl_drop_calculator.ex") |> File.read!()

    assert legacy =~ "compute_one(current, pours, drop, row, order, index, position)"
    assert legacy =~ "Map.put(current, id, updated)"
    assert patch =~ "vault_old = old"
    assert patch =~ "pending ="
    assert patch =~ "LegacyInPlaceStir.compute_one("
    assert patch =~ "Map.put(pending, id, updated)"
    assert patch =~ "Map.merge(vault_old, pending)"
    assert calculator =~ "BowlVaultPatch.run(old, pours, drop, row, order, index)"
    refute calculator =~ "LegacyInPlaceStir.run("
    refute patch =~ "NormativeReference"
  end

  test "sáu ID được cập nhật đúng một lần, không tạo khóa thừa" do
    row = Map.fetch!(Ref.build_stones(), 1)
    source_pours = pours(@old, @order, 97, row, 1)
    updated = BowlVaultPatch.run(@old, source_pours, 97, row, @order, 1)

    assert map_size(updated) == 6
    assert Enum.sort(Map.keys(updated)) == [1, 2, 3, 4, 5, 6]
    assert Enum.all?(Map.values(updated), fn x -> x >= 1 and x <= Ref.m() end)
    assert updated == independent_step(@old, @order, 97, row, 1)
  end

  test "ranh giới chưa mở khuấy sau giọt 46 và chưa có ngày lịch cuối" do
    f = Ref.foundation_day()
    ctx = Calendar.bootstrap_context(f, f)

    {_initial, _visible, expected} = normative_bowls(f, f)
    assert ctx.bowls_after_drops == expected
    assert ctx.phase == :bootstrap

    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end
end
