defmodule PastafariCalendarElixirVietnamese.Stage14Discovery07Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    HiddenDropManager,
    LegacyGrindTable,
    PriorPatch,
    SaveManager,
    VisibleDropCalculator
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @real_grinds [
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

  defp oracle(calculation_day, target_day) do
    counts = Ref.work_counts(calculation_day, target_day)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    Ref.build_visible_drops(counts, stones, hidden)
  end

  test "sentinel thật nằm ở index không, các bước một đến mười một khớp chuẩn" do
    assert LegacyGrindTable.row_at_zero() == {0, 0, 0, 0, 1}
    assert LegacyGrindTable.sentinel_row() == LegacyGrindTable.row_at_zero()
    assert LegacyGrindTable.all_rows_with_sentinel() ==
             [LegacyGrindTable.sentinel_row() | @real_grinds]

    for step <- 1..11 do
      assert LegacyGrindTable.legacy_row(step) == Enum.at(@real_grinds, step - 1)
    end

    assert LegacyGrindTable.legacy_row(1) == hd(@real_grinds)
    assert LegacyGrindTable.legacy_row(11) == List.last(@real_grinds)
    assert LegacyGrindTable.fallback_row() == {0, 0, 0, 0, 1}
    refute LegacyGrindTable.legacy_row(11) == LegacyGrindTable.fallback_row()
  end

  test "mười một lần đọc legacy chạy đủ số hàng thật, không chạm sentinel" do
    values = Enum.map(1..11, &LegacyGrindTable.legacy_row/1)

    assert length(values) == 11
    assert values == @real_grinds
    assert Enum.count(values, &(&1 == hd(@real_grinds))) == 1
    assert List.last(values) == List.last(@real_grinds)
    refute Enum.member?(values, LegacyGrindTable.sentinel_row())
  end

  test "giữ bằng chứng chỉ số cũ lệch và bộ đọc nay được che bằng sentinel" do
    m = Ref.m()
    seed = 37
    previous_1 = 41
    previous_3 = 43
    previous_7 = 47
    row = {53, 59, 61, 67, 71}

    fold = fn {a, b, c, d, kind}, old_value ->
      Ref.save(
        old_value * old_value + a * old_value + b * previous_1 +
          c * previous_3 + d * previous_7 + elem(row, kind - 1)
      )
    end

    corrected =
      Enum.reduce(1..11, seed, fn step, prior ->
        fold.(LegacyGrindTable.legacy_row(step), prior)
      end)

    expected = Enum.reduce(@real_grinds, seed, fold)
    historical = Enum.reduce(tl(@real_grinds) ++ [{0, 0, 0, 0, 1}], seed, fold)

    assert corrected == expected
    refute corrected == historical
    assert corrected >= 1 and corrected <= m
  end

  test "giọt đầu dùng công thức seed và đủ mười một hàng đúng qua legacy" do
    f = Ref.foundation_day()
    c = f - 11
    t = f + 19
    context = Calendar.bootstrap_context(c, t)
    counts = Ref.work_counts(c, t)
    {w, b, s, meat, rice} = context.stones_table[1]
    hidden = context.hidden_drops_storage

    p1 = HiddenDropManager.read(hidden, 1)
    p3 = HiddenDropManager.read(hidden, 3)
    p7 = HiddenDropManager.read(hidden, 7)
    assert PriorPatch.read(%{}, hidden, 1, 1) == p1
    assert PriorPatch.read(%{}, hidden, 1, 3) == p3
    assert PriorPatch.read(%{}, hidden, 1, 7) == p7

    seed =
      Ref.save(
        w * counts.action + b * counts.target + s * counts.distance +
          meat * counts.connection + rice * counts.direction +
          p1 + 3 * p3 + 5 * p7 + 1
      )

    result =
      Enum.reduce(1..11, seed, fn step, prev ->
        {a, bb, cc, dd, kind} = LegacyGrindTable.legacy_row(step)

        Ref.save(
          prev * prev + a * prev + bb * p1 + cc * p3 + dd * p7 +
            elem(context.stones_table[1], kind - 1)
        )
      end)

    assert context.visible_drops[1] == result
    assert context.visible_drops[1] == oracle(c, t)[1]
  end

  test "đường tính sản xuất đầy đủ đã vá vẫn dùng bảng legacy cũ" do
    f = Ref.foundation_day()
    c = f + 21
    t = f - 37
    context = Calendar.bootstrap_context(c, t)

    rebuilt =
      VisibleDropCalculator.calculate(
        c, t, context.calculation_day_tag, context.target_day_tag,
        context.distance_count, context.stones_table, context.hidden_drops_storage
      )

    assert rebuilt == context.visible_drops
    assert map_size(rebuilt) == 46
    assert Enum.sort(Map.keys(rebuilt)) == Enum.to_list(1..46)
    assert Enum.all?(Map.values(rebuilt), fn value ->
      value >= 1 and value <= Ref.m()
    end)
    assert rebuilt == oracle(c, t)
  end

  test "các bản vá trước vẫn trả đúng đá, giọt ẩn và ba tiền nhiệm" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f, f + 3)
    assert context.stones_table == Ref.build_stones()
    hidden = Ref.build_hidden_drops(Ref.work_counts(f, f + 3), Ref.build_stones())

    for number <- 1..7 do
      assert HiddenDropManager.read(context.hidden_drops_storage, number) == hidden[number]
    end

    for index <- 1..7, back <- [1, 3, 7], index - back <= 0 do
      assert PriorPatch.read(context.visible_drops, context.hidden_drops_storage, index, back) ==
               hidden[1 - (index - back)]
    end
  end

  test "ngày cực lớn vẫn ở miền SAVE và thuộc sở hữu mỗi context" do
    f = Ref.foundation_day()
    shift = (1 <<< 512) + 7

    for {c, t} <- [{f - shift, f + shift}, {f + shift, f - shift}] do
      context = Calendar.bootstrap_context(c, t)
      assert map_size(context.visible_drops) == 46
      assert Enum.all?(Map.values(context.visible_drops), fn value ->
        is_integer(value) and value >= 1 and value <= Ref.m()
      end)

      copied = %{context | visible_drops: Map.put(context.visible_drops, 1, 0)}
      refute copied.visible_drops == context.visible_drops
      assert Calendar.bootstrap_context(c, t).visible_drops == context.visible_drops
      assert context.visible_drops == oracle(c, t)
    end
  end

  test "bảng nghiền được vá và giữ đúng trong nhiều luồng chạy song song" do
    f = Ref.foundation_day()
    pairs = for i <- -8..8, do: {f + 7 * i, f - 11 * i}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        ordered: true, max_concurrency: 8, timeout: 15_000
      )
      |> Enum.map(fn {:ok, context} -> context end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, ctx} ->
      assert ctx.visible_drops == Calendar.visible_drops_spaghetti(c, t)
      assert ctx.hidden_drops_storage == Calendar.hidden_drops_storage_spaghetti(c, t)
      assert ctx.visible_drops == oracle(c, t)
    end)
  end

  test "chỉ số nghiền hợp lệ từ một tới mười một, ngoài miền báo lỗi" do
    for wrong <- [-1, 0, 12, 46, nil, :khong_hop_le, 1.0, "1"] do
      assert_raise ArgumentError, "chỉ số lần nghiền phải từ 1 đến 11", fn ->
        LegacyGrindTable.legacy_row(wrong)
      end
    end

    for step <- 1..11 do
      {a, b, c, d, kind} = LegacyGrindTable.legacy_row(step)
      assert Enum.all?([a, b, c, d], &is_integer/1)
      assert is_integer(kind) and kind in 1..5
      assert SaveManager.calculate(step) == step
    end
  end

  test "kiểm toán mã nguồn giữ cách đọc legacy và thêm sentinel thật ở index 0" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_grind_table.ex") |> File.read!()
    calculator = Path.join(root, "visible_drop_calculator.ex") |> File.read!()
    prior = Path.join(root, "prior_patch.ex") |> File.read!()

    assert legacy =~ "Enum.at(@real_rows, number, @missing_row)"
    assert legacy =~ "@sentinel_row {0, 0, 0, 0, 1}"
    assert legacy =~ "@real_rows [\\n    @sentinel_row,"
    assert legacy =~ "@missing_row {0, 0, 0, 0, 1}"
    assert calculator =~ "Enum.reduce(1..11, seed, fn grind_number, old_value ->"
    assert calculator =~ "LegacyGrindTable.legacy_row(grind_number)"
    assert prior =~ "HiddenDropManager.read(hidden_storage, hidden_number)"
    refute calculator =~ "NormativeReference"
    refute File.exists?(Path.join(root, "grind_table_patch.ex"))
  end

  test "hồi quy chuẩn bước nghiền đầu: cố ý đỏ ở phát hiện 07" do
    assert LegacyGrindTable.legacy_row(1) == hd(@real_grinds)
  end

  test "hồi quy chuẩn bước nghiền cuối: cố ý đỏ ở phát hiện 07" do
    assert LegacyGrindTable.legacy_row(11) == List.last(@real_grinds)
  end

  test "hồi quy chuẩn giọt nhìn thấy thứ nhất: cố ý đỏ ở phát hiện 07" do
    f = Ref.foundation_day()
    assert Calendar.visible_drop_spaghetti(f, f, 1) == oracle(f, f)[1]
  end

  test "hồi quy chuẩn giọt nhìn thấy cuối cùng: cố ý đỏ ở phát hiện 07" do
    f = Ref.foundation_day()
    assert Calendar.visible_drop_spaghetti(f - 7, f + 37, 46) ==
             oracle(f - 7, f + 37)[46]
  end
end
