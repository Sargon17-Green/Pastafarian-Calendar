defmodule PastafariCalendarElixirVietnamese.Stage10Discovery05Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    HiddenDropCalculator,
    HiddenDropManager,
    LegacyHiddenStorage
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  defp oracle(calculation_day, target_day) do
    counts = Ref.work_counts(calculation_day, target_day)
    Ref.build_hidden_drops(counts, Ref.build_stones())
  end

  test "bảy giá trị đúng về số học nhưng tuple cũ lưu theo thứ tự đảo" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 8, f + 27}, {f + 800, f - 19}] do
      normative = oracle(c, t)
      storage = Calendar.hidden_drops_storage_spaghetti(c, t)

      computed =
        HiddenDropCalculator.calculate(
          c,
          t,
          Ref.day_count(c),
          Ref.day_count(t),
          Ref.work_counts(c, t).distance,
          Ref.build_stones()
        )

      assert computed == normative
      assert HiddenDropManager.read(storage, 1) == Map.fetch!(normative, 1)
      assert LegacyHiddenStorage.read_as_if_forward(storage, 1) ==
               Map.fetch!(normative, 7)
      assert tuple_size(storage) == 7
      assert storage == List.to_tuple(Enum.map(7..1//-1, &Map.fetch!(normative, &1)))

      for number <- 1..7 do
        assert elem(storage, number - 1) == Map.fetch!(normative, 8 - number)
      end
    end
  end

  test "giọt ẩn ở giữa trùng chuẩn như một đối chứng không lệch" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f + 17, f - 21}] do
      assert Calendar.hidden_drop_spaghetti(c, t, 4) == Map.fetch!(oracle(c, t), 4)
      assert LegacyHiddenStorage.read_as_if_forward(
               Calendar.hidden_drops_storage_spaghetti(c, t),
               4
             ) == Map.fetch!(oracle(c, t), 4)
    end
  end

  test "đường bootstrap dùng bảng đá đã vá và ghi storage sai vào context" do
    f = Ref.foundation_day()
    c = f - 13
    t = f + 29
    context = Calendar.bootstrap_context(c, t)

    assert context.calculation_day_tag == Ref.day_count(c)
    assert context.target_day_tag == Ref.day_count(t)
    assert context.distance_count == Ref.work_counts(c, t).distance
    assert context.stones_table == Ref.build_stones()
    assert context.hidden_drops_storage == Calendar.hidden_drops_storage_spaghetti(c, t)
    assert context.hidden_drops_storage ==
             List.to_tuple(Enum.map(7..1//-1, &Map.fetch!(oracle(c, t), &1)))
  end

  test "hai lần gọi tạo giọt riêng và không chia sẻ trạng thái ngữ nghĩa" do
    f = Ref.foundation_day()
    first = Calendar.bootstrap_context(f, f + 1)
    second = Calendar.bootstrap_context(f + 1, f)
    first_before = first.hidden_drops_storage

    assert first_before == Calendar.hidden_drops_storage_spaghetti(f, f + 1)
    assert second.hidden_drops_storage == Calendar.hidden_drops_storage_spaghetti(f + 1, f)

    changed = %{first | hidden_drops_storage: put_elem(first_before, 0, -1)}
    assert first.hidden_drops_storage == first_before
    refute changed.hidden_drops_storage == first_before
    assert second.hidden_drops_storage != changed.hidden_drops_storage
  end

  test "đường lưu và đọc giọt hoạt động độc lập dưới nhiều yêu cầu" do
    f = Ref.foundation_day()
    pairs = for delta <- -24..24, do: {f + delta * 7, f - delta * 11}

    result =
      Task.async_stream(pairs, fn {c, t} ->
        Calendar.bootstrap_context(c, t)
      end, ordered: true, max_concurrency: 8, timeout: 15_000)
      |> Enum.map(fn {:ok, context} -> context end)

    assert length(result) == length(pairs)

    Enum.zip(pairs, result)
    |> Enum.each(fn {{c, t}, context} ->
      expected = oracle(c, t)
      assert context.hidden_drops_storage ==
               List.to_tuple(Enum.map(7..1//-1, &Map.fetch!(expected, &1)))
    end)
  end

  test "các ngày nguyên rất lớn không mất độ chính xác trong giọt ẩn" do
    f = Ref.foundation_day()

    for shift <- [1 <<< 128, (1 <<< 512) + 31] do
      for {c, t} <- [{f - shift, f + shift}, {f + shift, f - shift}] do
        expected = oracle(c, t)
        storage = Calendar.hidden_drops_storage_spaghetti(c, t)

        for number <- 1..7 do
          value = elem(storage, number - 1)
          assert value == Map.fetch!(expected, 8 - number)
          assert value >= 1 and value <= Ref.m()
        end
      end
    end
  end

  test "giá trị đầu vào và số hiệu giọt không hợp lệ đều bị từ chối" do
    f = Ref.foundation_day()

    for bad <- [nil, 1.5, "8", :sai, %{}, [1]] do
      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.hidden_drops_storage_spaghetti(bad, f)
      end

      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.hidden_drop_spaghetti(f, bad, 1)
      end
    end

    for number <- [0, -1, 8, nil, 2.5, "4"] do
      assert_raise ArgumentError, "số giọt ẩn phải từ 1 đến 7", fn ->
        Calendar.hidden_drop_spaghetti(f, f, number)
      end
    end
  end

  test "đường mã nguồn giữ storage đảo và thực thi bản vá truy cập 05" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    calculator = Path.join(root, "hidden_drop_calculator.ex") |> File.read!()
    legacy = Path.join(root, "legacy_hidden_storage.ex") |> File.read!()
    manager = Path.join(root, "hidden_drop_manager.ex") |> File.read!()
    patch = Path.join(root, "hidden_storage_patch.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert calculator =~ "Enum.reduce(1..7, %{}, fn hidden_number, acc ->"
    assert calculator =~ "SaveManager.calculate("
    assert legacy =~ "7..1//-1"
    assert legacy =~ "elem(storage, number - 1)"
    assert manager =~ "LegacyHiddenStorage.store_reversed()"
    assert manager =~ "HiddenStoragePatch.read_hidden(storage, number)"
    assert patch =~ "legacy_position = 8 - number"
    assert patch =~ "LegacyHiddenStorage.read_as_if_forward(storage, legacy_position)"
    assert dispatcher =~ "HiddenDropManager.build_storage("
    refute calculator =~ "NormativeReference"
    refute manager =~ "NormativeReference"
    assert File.exists?(Path.join(root, "hidden_storage_patch.ex"))
  end

  test "hồi quy các bản vá cũ và ranh giới lịch chưa tích hợp" do
    f = Ref.foundation_day()
    m = Ref.m()

    for value <- [-m, 0, m, 2 * m, m + 1] do
      assert Calendar.save_value_spaghetti(value) == Ref.save(value)
    end

    for day <- [f - 3, f, f + 3] do
      assert Calendar.day_count_spaghetti(day) == Ref.day_count(day)
    end

    for {c, t} <- [{f, f}, {f - 2, f + 6}] do
      assert Calendar.distance_spaghetti(c, t) == Ref.work_counts(c, t).distance
    end

    assert Calendar.stones_table_spaghetti() == Ref.build_stones()

    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end

  test "hồi quy chuẩn giọt ẩn thứ nhất: cố ý đỏ cho phát hiện 05" do
    f = Ref.foundation_day()
    assert Calendar.hidden_drop_spaghetti(f, f, 1) == Map.fetch!(oracle(f, f), 1)
  end

  test "hồi quy chuẩn giọt ẩn thứ hai: cố ý đỏ cho phát hiện 05" do
    f = Ref.foundation_day()
    assert Calendar.hidden_drop_spaghetti(f, f + 1, 2) ==
             Map.fetch!(oracle(f, f + 1), 2)
  end

  test "hồi quy chuẩn giọt ẩn thứ ba: cố ý đỏ cho phát hiện 05" do
    f = Ref.foundation_day()
    assert Calendar.hidden_drop_spaghetti(f - 5, f + 7, 3) ==
             Map.fetch!(oracle(f - 5, f + 7), 3)
  end

  test "hồi quy chuẩn giọt ẩn thứ bảy: cố ý đỏ cho phát hiện 05" do
    f = Ref.foundation_day()
    assert Calendar.hidden_drop_spaghetti(f + 500, f - 500, 7) ==
             Map.fetch!(oracle(f + 500, f - 500), 7)
  end
end
