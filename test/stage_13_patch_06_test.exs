defmodule PastafariCalendarElixirVietnamese.Stage13Patch06Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    HiddenDropManager,
    LegacyPrior,
    PriorPatch,
    VisibleDropCalculator,
    VisibleDropManager
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  defp expected(c, t) do
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    Ref.build_visible_drops(counts, stones, hidden)
  end

  test "mọi giọt từ một tới 46 trùng hoàn toàn với chuẩn độc lập" do
    f = Ref.foundation_day()

    for {c, t} <- [
          {f, f},
          {f - 1, f},
          {f, f + 1},
          {f - 12, f + 30},
          {f + 30, f - 12},
          {f + 500, f + 501},
          {f - 700, f - 701}
        ] do
      normative = expected(c, t)
      actual = Calendar.visible_drops_spaghetti(c, t)

      assert map_size(actual) == 46
      assert Enum.sort(Map.keys(actual)) == Enum.to_list(1..46)
      assert actual == normative

      for index <- 1..46 do
        assert Calendar.visible_drop_spaghetti(c, t, index) == normative[index]
      end
    end
  end

  test "địa chỉ không dương đọc đúng từng giọt ẩn từ kho đảo" do
    f = Ref.foundation_day()
    c = f - 2
    t = f + 9
    context = Calendar.bootstrap_context(c, t)

    for index <- 1..7 do
      for back <- [1, 3, 7] do
        slot = index - back

        if slot <= 0 do
          number = 1 - slot
          actual = PriorPatch.read(%{}, context.hidden_drops_storage, index, back)

          assert actual == HiddenDropManager.read(context.hidden_drops_storage, number)
          assert actual == Calendar.hidden_drop_spaghetti(c, t, number)
          assert actual >= 1 and actual <= Ref.m()
          assert LegacyPrior.legacy_prior(%{}, index, back) == 0
        end
      end
    end
  end

  test "địa chỉ dương vẫn gọi chính hàm lịch sử trên kho nhìn thấy" do
    f = Ref.foundation_day()
    hidden = Calendar.hidden_drops_storage_spaghetti(f, f)
    visible = %{1 => 13, 2 => 17, 3 => 19, 4 => 23, 5 => 29, 6 => 31, 7 => 37}

    for index <- 2..8, back <- [1, 3, 7], index - back >= 1 do
      assert PriorPatch.read(visible, hidden, index, back) ==
               LegacyPrior.legacy_prior(visible, index, back)
      assert PriorPatch.read(visible, hidden, index, back) ==
               Map.get(visible, index - back, 0)
    end
  end

  test "giữ nguyên hàm legacy sai và không trộn lẫn hai kho" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f, f)
    visible = context.visible_drops
    hidden = context.hidden_drops_storage

    assert LegacyPrior.legacy_prior(%{}, 1, 1) == 0
    assert LegacyPrior.legacy_prior(%{}, 1, 7) == 0
    assert PriorPatch.read(%{}, hidden, 1, 1) == Calendar.hidden_drop_spaghetti(f, f, 1)
    assert PriorPatch.read(%{}, hidden, 1, 7) == Calendar.hidden_drop_spaghetti(f, f, 7)

    for index <- 8..46, back <- [1, 3, 7] do
      assert PriorPatch.read(visible, hidden, index, back) ==
               LegacyPrior.legacy_prior(visible, index, back)
    end

    assert context.visible_drops == expected(f, f)
    assert context.hidden_drops_storage == Calendar.hidden_drops_storage_spaghetti(f, f)
  end

  test "giọt đầu dùng đầy đủ ba tiền nhiệm ẩn theo công thức" do
    f = Ref.foundation_day()
    c = f - 3
    t = f + 4
    counts = Ref.work_counts(c, t)
    context = Calendar.bootstrap_context(c, t)
    stones = context.stones_table
    row = stones[1]
    {w, b, s, m, r} = row

    p1 = HiddenDropManager.read(context.hidden_drops_storage, 1)
    p3 = HiddenDropManager.read(context.hidden_drops_storage, 3)
    p7 = HiddenDropManager.read(context.hidden_drops_storage, 7)

    seed =
      Ref.save(
        w * counts.action + b * counts.target + s * counts.distance +
          m * counts.connection + r * counts.direction + p1 + 3 * p3 + 5 * p7 + 1
      )

    grinds = [
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

    result =
      Enum.reduce(grinds, seed, fn {aa, bb, cc, dd, kind}, prior ->
        Ref.save(
          prior * prior + aa * prior + bb * p1 + cc * p3 + dd * p7 +
            elem(row, kind - 1)
        )
      end)

    assert context.visible_drops[1] == result
    assert result == expected(c, t)[1]
  end

  test "chuyển cùng bộ nhớ giọt ẩn từ bootstrap tới phép tính" do
    f = Ref.foundation_day()
    c = f + 31
    t = f - 17
    context = Calendar.bootstrap_context(c, t)

    recalculated =
      VisibleDropCalculator.calculate(
        c,
        t,
        context.calculation_day_tag,
        context.target_day_tag,
        context.distance_count,
        context.stones_table,
        context.hidden_drops_storage
      )

    assert context.visible_drops == recalculated
    assert context.visible_drops == expected(c, t)
    assert VisibleDropManager.read(recalculated, 46) == expected(c, t)[46]
  end

  test "kiểm soát toàn bộ vùng tiếp giáp từ giọt một tới giọt tám" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f - 5, f + 13)
    known = expected(f - 5, f + 13)

    for index <- 1..8 do
      for back <- [1, 3, 7] do
        value = PriorPatch.read(context.visible_drops, context.hidden_drops_storage, index, back)
        slot = index - back

        if slot >= 1 do
          assert value == known[slot]
        else
          hidden_number = 1 - slot
          assert value == HiddenDropManager.read(context.hidden_drops_storage, hidden_number)
        end
      end
    end
  end

  test "số nguyên cực lớn không phá kết quả và miền SAVE" do
    f = Ref.foundation_day()

    for shift <- [1 <<< 128, (1 <<< 512) + 7, 1 <<< 2048] do
      for {c, t} <- [{f + shift, f - shift}, {f - shift, f + shift}] do
        context = Calendar.bootstrap_context(c, t)
        normative = expected(c, t)

        assert context.visible_drops == normative
        assert Enum.all?(Map.values(context.visible_drops), fn x ->
          is_integer(x) and x >= 1 and x <= Ref.m()
        end)
      end
    end
  end

  test "đọc đồng thời và ngữ cảnh độc lập không nhiễm giá trị" do
    f = Ref.foundation_day()
    pairs = for k <- -18..18, do: {f + 17 * k, f - 19 * k}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        ordered: true, max_concurrency: 8, timeout: 15_000
      )
      |> Enum.map(fn {:ok, context} -> context end)

    assert length(contexts) == length(pairs)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, context} ->
      assert context.visible_drops == expected(c, t)
      assert Map.fetch!(context.visible_drops, 1) >= 1
    end)

    original = hd(contexts)
    changed = %{original | visible_drops: Map.put(original.visible_drops, 1, 0)}
    refute changed.visible_drops == original.visible_drops
    assert original.visible_drops == expected(elem(hd(pairs), 0), elem(hd(pairs), 1))
  end

  test "đầu vào sai bị chặn và giữ biên ngày chưa được tích hợp" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f, f)
    invalids = [0, -1, 47, nil, 1.5, :sai, "2"]

    for invalid <- invalids do
      assert_raise ArgumentError, "địa chỉ giọt trước phải hợp lệ với độ lùi 1, 3 hoặc 7", fn ->
        PriorPatch.read(%{}, context.hidden_drops_storage, invalid, 1)
      end
    end

    for back <- [0, 2, 8, nil, 1.0, "3"] do
      assert_raise ArgumentError, "địa chỉ giọt trước phải hợp lệ với độ lùi 1, 3 hoặc 7", fn ->
        PriorPatch.read(%{}, context.hidden_drops_storage, 1, back)
      end
    end

    assert_raise ArgumentError, "địa chỉ giọt trước phải hợp lệ với độ lùi 1, 3 hoặc 7", fn ->
      PriorPatch.read(%{}, {}, 1, 1)
    end

    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(f, f)
    end
  end

  test "mã nguồn giữ nguyên legacy và chỉ phân nhánh tại bản vá 06" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_prior.ex") |> File.read!()
    patch = Path.join(root, "prior_patch.ex") |> File.read!()
    calculator = Path.join(root, "visible_drop_calculator.ex") |> File.read!()
    manager = Path.join(root, "visible_drop_manager.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert legacy =~ "Map.get(visible_store, slot, 0)"
    refute legacy =~ "HiddenDropManager"
    assert patch =~ "slot = index - back"
    assert patch =~ "if slot >= 1 do"
    assert patch =~ "LegacyPrior.legacy_prior(visible_store, index, back)"
    assert patch =~ "hidden_number = 1 - slot"
    assert patch =~ "HiddenDropManager.read(hidden_storage, hidden_number)"
    assert calculator =~ "PriorPatch.read(visible_store, hidden_storage, index, 1)"
    assert calculator =~ "PriorPatch.read(visible_store, hidden_storage, index, 3)"
    assert calculator =~ "PriorPatch.read(visible_store, hidden_storage, index, 7)"
    assert manager =~ "hidden_storage"
    assert dispatcher =~ "hidden_storage"
    refute patch =~ "NormativeReference"
    refute calculator =~ "NormativeReference"
  end
end
