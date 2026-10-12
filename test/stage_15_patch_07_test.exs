defmodule PastafariCalendarElixirVietnamese.Stage15Patch07Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    HiddenDropManager,
    LegacyGrindTable,
    LegacyPrior,
    PriorPatch,
    VisibleDropCalculator
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @correct_rows [
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

  defp normative_visible(calculation_day, target_day) do
    counts = Ref.work_counts(calculation_day, target_day)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    Ref.build_visible_drops(counts, stones, hidden)
  end

  test "sentinel bắt buộc ở ô không và chỉ có một trong 12 hàng" do
    rows = LegacyGrindTable.all_rows_with_sentinel()
    sentinel = {0, 0, 0, 0, 1}

    assert length(rows) == 12
    assert hd(rows) == sentinel
    assert LegacyGrindTable.row_at_zero() == sentinel
    assert LegacyGrindTable.sentinel_row() == sentinel
    assert LegacyGrindTable.fallback_row() == sentinel
    assert tl(rows) == @correct_rows
    assert Enum.count(rows, &(&1 == sentinel)) == 1
  end

  test "mọi vị trí 1 tới 11 đúng, không truy cập hàng canh" do
    rows = LegacyGrindTable.all_rows_with_sentinel()

    for position <- 1..11 do
      assert LegacyGrindTable.legacy_row(position) == Enum.at(rows, position)
      assert LegacyGrindTable.legacy_row(position) == Enum.at(@correct_rows, position - 1)
      refute LegacyGrindTable.legacy_row(position) == hd(rows)
    end

    assert LegacyGrindTable.legacy_row(1) == {3, 5, 7, 11, 1}
    assert LegacyGrindTable.legacy_row(11) == {37, 41, 43, 47, 1}
  end

  test "đọc index cổ được giữ nguyên trong mã và không thay bằng index trừ một" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_grind_table.ex") |> File.read!()
    calculator = Path.join(root, "visible_drop_calculator.ex") |> File.read!()

    assert legacy =~ "Enum.at(@real_rows, number, @missing_row)"
    assert legacy =~ "@real_rows ["
    assert legacy =~ "@sentinel_row,"
    assert legacy =~ "def row_at_zero, do: hd(@real_rows)"
    refute legacy =~ "Enum.at(@real_rows, number - 1"
    assert calculator =~ "LegacyGrindTable.legacy_row(grind_number)"
    assert calculator =~ "Enum.reduce(1..11, seed, fn grind_number, old_value ->"
    refute calculator =~ "NormativeReference"
  end

  test "tính thủ công 11 vòng nghiền đúng từ các hàng bộ tham chiếu" do
    row = {53, 59, 61, 67, 71}
    seed = 101
    p1 = 103
    p3 = 107
    p7 = 109

    fold = fn {a, b, c, d, kind}, prior ->
      Ref.save(prior * prior + a * prior + b * p1 + c * p3 +
        d * p7 + elem(row, kind - 1))
    end

    expected = Enum.reduce(@correct_rows, seed, fold)

    actual =
      Enum.reduce(1..11, seed, fn step, prior ->
        fold.(LegacyGrindTable.legacy_row(step), prior)
      end)

    historical =
      Enum.reduce(tl(@correct_rows) ++ [{0, 0, 0, 0, 1}], seed, fold)

    assert actual == expected
    refute actual == historical
    assert actual >= 1 and actual <= Ref.m()
  end

  test "46 giọt ở bảy cặp ngày khớp oracle độc lập" do
    foundation = Ref.foundation_day()

    pairs = [
      {foundation, foundation},
      {foundation - 1, foundation},
      {foundation, foundation + 1},
      {foundation - 901, foundation + 271},
      {foundation + 271, foundation - 901},
      {foundation + 1001, foundation + 1002},
      {foundation - 1001, foundation - 1002}
    ]

    for {calculation_day, target_day} <- pairs do
      expected = normative_visible(calculation_day, target_day)
      context = Calendar.bootstrap_context(calculation_day, target_day)

      assert map_size(context.visible_drops) == 46
      assert context.visible_drops == expected
      assert Calendar.visible_drops_spaghetti(calculation_day, target_day) == expected
    end
  end

  test "đọc từng ô sản xuất trả đúng và thứ tự hiển thị là 1..46" do
    foundation = Ref.foundation_day()
    c = foundation - 27
    t = foundation + 93
    expected = normative_visible(c, t)
    visible = Calendar.visible_drops_spaghetti(c, t)

    assert Enum.sort(Map.keys(visible)) == Enum.to_list(1..46)

    for index <- 1..46 do
      assert Map.fetch!(visible, index) == expected[index]
      assert Calendar.visible_drop_spaghetti(c, t, index) == expected[index]
    end
  end

  test "hàm tính thực dùng tuple ẩn của cùng ngữ cảnh và không tính lại" do
    f = Ref.foundation_day()
    c = f + 28
    t = f - 92
    context = Calendar.bootstrap_context(c, t)

    actual =
      VisibleDropCalculator.calculate(
        c, t, context.calculation_day_tag, context.target_day_tag,
        context.distance_count, context.stones_table, context.hidden_drops_storage
      )

    assert actual == context.visible_drops
    assert actual == normative_visible(c, t)
    assert context.hidden_drops_storage ==
             Calendar.hidden_drops_storage_spaghetti(c, t)
  end

  test "các phép vá 01 đến 06 vẫn được giữ nguyên" do
    f = Ref.foundation_day()
    c = f - 99
    t = f + 55
    context = Calendar.bootstrap_context(c, t)
    counts = Ref.work_counts(c, t)
    hidden = Ref.build_hidden_drops(counts, Ref.build_stones())

    assert context.stones_table == Ref.build_stones()
    assert context.calculation_day_tag == counts.action
    assert context.target_day_tag == counts.target
    assert context.distance_count == counts.distance

    for number <- 1..7 do
      assert HiddenDropManager.read(context.hidden_drops_storage, number) == hidden[number]
    end

    for index <- 1..7, back <- [1, 3, 7], index - back <= 0 do
      assert PriorPatch.read(context.visible_drops, context.hidden_drops_storage, index, back) ==
               hidden[1 - (index - back)]
      assert LegacyPrior.legacy_prior(%{}, index, back) == 0
    end
  end

  test "số nguyên 128, 512 và 2048 bit vẫn khớp tất cả giọt" do
    f = Ref.foundation_day()

    for shift <- [1 <<< 128, (1 <<< 512) + 39, 1 <<< 2048] do
      for {c, t} <- [{f + shift, f - shift}, {f - shift, f + shift}] do
        context = Calendar.bootstrap_context(c, t)

        assert context.visible_drops == normative_visible(c, t)
        assert Enum.all?(Map.values(context.visible_drops), fn value ->
          is_integer(value) and value >= 1 and value <= Ref.m()
        end)
      end
    end
  end

  test "chạy đồng thời tạo kết quả chính xác không có trạng thái ngữ nghĩa dùng chung" do
    foundation = Ref.foundation_day()
    pairs = for delta <- -17..17, do: {foundation + 23 * delta, foundation - 37 * delta}

    results =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        max_concurrency: 8, ordered: true, timeout: 15_000
      )
      |> Enum.map(fn {:ok, context} -> context end)

    assert length(results) == length(pairs)

    Enum.zip(pairs, results)
    |> Enum.each(fn {{c, t}, context} ->
      assert context.visible_drops == normative_visible(c, t)
    end)

    initial = hd(results)
    changed = %{initial | visible_drops: Map.put(initial.visible_drops, 1, 0)}
    refute initial.visible_drops == changed.visible_drops
    assert initial.visible_drops ==
             normative_visible(elem(hd(pairs), 0), elem(hd(pairs), 1))
  end

  test "chỉ số ngoài phạm vi và ngày không nguyên vẫn bị từ chối" do
    f = Ref.foundation_day()

    for invalid <- [0, -1, 12, nil, 1.0, "5", :khong_hop_le] do
      assert_raise ArgumentError, "chỉ số lần nghiền phải từ 1 đến 11", fn ->
        LegacyGrindTable.legacy_row(invalid)
      end
    end

    for invalid_day <- [nil, :sai, 1.5, "3"] do
      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.visible_drops_spaghetti(invalid_day, f)
      end
    end
  end

  test "ranh giới ngày lịch cuối và các giai đoạn tương lai chưa được mở" do
    foundation = Ref.foundation_day()
    assert Calendar.visible_drops_spaghetti(foundation, foundation) ==
             normative_visible(foundation, foundation)

    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(foundation, foundation)
    end

    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    refute File.exists?(Path.join(root, "grind_table_patch.ex"))
    assert File.exists?(Path.join(root, "legacy_grind_table.ex"))
  end
end
