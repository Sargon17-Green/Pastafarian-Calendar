defmodule PastafariCalendarElixirVietnamese.Stage11Patch05Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    HiddenDropManager,
    HiddenStoragePatch,
    LegacyHiddenStorage
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  defp oracle(calculation_day, target_day) do
    counts = Ref.work_counts(calculation_day, target_day)
    Ref.build_hidden_drops(counts, Ref.build_stones())
  end

  test "bản vá đọc đúng hai đầu kho mà không thay thứ tự lưu trữ" do
    f = Ref.foundation_day()
    expected = oracle(f, f)
    storage = Calendar.hidden_drops_storage_spaghetti(f, f)

    assert storage == List.to_tuple(Enum.map(7..1//-1, &Map.fetch!(expected, &1)))
    assert elem(storage, 0) == expected[7]
    assert elem(storage, 6) == expected[1]

    assert HiddenStoragePatch.read_hidden(storage, 1) == expected[1]
    assert HiddenStoragePatch.read_hidden(storage, 7) == expected[7]
    assert HiddenDropManager.read(storage, 1) == expected[1]
    assert HiddenDropManager.read(storage, 7) == expected[7]

    assert LegacyHiddenStorage.read_as_if_forward(storage, 1) == expected[7]
    assert LegacyHiddenStorage.read_as_if_forward(storage, 7) == expected[1]
  end

  test "bảy giọt khớp oracle độc lập ở nhiều cặp ngày và hai chiều" do
    f = Ref.foundation_day()

    pairs = [
      {f, f},
      {f - 1, f},
      {f, f + 1},
      {f - 25, f + 199},
      {f + 199, f - 25},
      {f + 1300, f + 1301},
      {f - 1300, f - 1301}
    ]

    for {c, t} <- pairs do
      expected = oracle(c, t)
      for number <- 1..7 do
        assert Calendar.hidden_drop_spaghetti(c, t, number) == expected[number]
      end
    end
  end

  test "đọc legacy vẫn sai ở sáu vị trí không nằm giữa" do
    f = Ref.foundation_day()
    expected = oracle(f, f)
    storage = Calendar.hidden_drops_storage_spaghetti(f, f)

    for number <- [1, 2, 3, 5, 6, 7] do
      assert LegacyHiddenStorage.read_as_if_forward(storage, number) ==
               expected[8 - number]
      assert HiddenStoragePatch.read_hidden(storage, number) == expected[number]
      refute LegacyHiddenStorage.read_as_if_forward(storage, number) ==
               HiddenStoragePatch.read_hidden(storage, number)
    end
  end

  test "giọt thứ tư tiếp tục trùng ở cả đường sai và bản vá" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 12, f + 8}, {f + 10, f - 3}] do
      storage = Calendar.hidden_drops_storage_spaghetti(c, t)
      expected = oracle(c, t)[4]
      assert LegacyHiddenStorage.read_as_if_forward(storage, 4) == expected
      assert HiddenStoragePatch.read_hidden(storage, 4) == expected
      assert Calendar.hidden_drop_spaghetti(c, t, 4) == expected
    end
  end

  test "tính chính xác các ngày có số nguyên lớn tùy ý" do
    f = Ref.foundation_day()

    for offset <- [1 <<< 128, 1 <<< 512, (1 <<< 2048) + 127] do
      for {c, t} <- [{f - offset, f + offset}, {f + offset, f - offset}] do
        expected = oracle(c, t)
        storage = Calendar.hidden_drops_storage_spaghetti(c, t)

        for number <- 1..7 do
          assert HiddenStoragePatch.read_hidden(storage, number) == expected[number]
          assert Calendar.hidden_drop_spaghetti(c, t, number) == expected[number]
          assert elem(storage, number - 1) == expected[8 - number]
        end
      end
    end
  end

  test "đầu vào không hợp lệ bị chặn giống trước khi sửa" do
    f = Ref.foundation_day()
    storage = Calendar.hidden_drops_storage_spaghetti(f, f)

    for bad <- [0, -1, 8, nil, :sai, 1.5, "4", %{}, [1]] do
      assert_raise ArgumentError, "số giọt ẩn phải từ 1 đến 7", fn ->
        HiddenStoragePatch.read_hidden(storage, bad)
      end

      assert_raise ArgumentError, "số giọt ẩn phải từ 1 đến 7", fn ->
        Calendar.hidden_drop_spaghetti(f, f, bad)
      end
    end

    for invalid_storage <- [nil, {}, {1, 2}, [], %{}, :sai] do
      assert_raise ArgumentError, "số giọt ẩn phải từ 1 đến 7", fn ->
        HiddenStoragePatch.read_hidden(invalid_storage, 1)
      end
    end
  end

  test "context sở hữu tuple đảo độc lập và không bị đổi khi đọc" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f - 12, f + 33)
    original = context.hidden_drops_storage

    for number <- 1..7 do
      assert HiddenDropManager.read(original, number) == oracle(f - 12, f + 33)[number]
      assert original == context.hidden_drops_storage
    end

    changed = put_elem(original, 0, -1)
    refute changed == original
    assert Calendar.bootstrap_context(f - 12, f + 33).hidden_drops_storage == original
  end

  test "nhiều ngữ cảnh đồng thời không làm lẫn giọt của các lần gọi" do
    f = Ref.foundation_day()
    pairs = for delta <- -16..16, do: {f + delta * 11, f - delta * 19}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        ordered: true, max_concurrency: 8, timeout: 15_000
      )
      |> Enum.map(fn {:ok, context} -> context end)

    assert length(contexts) == length(pairs)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, context} ->
      expected = oracle(c, t)

      for number <- 1..7 do
        assert HiddenDropManager.read(context.hidden_drops_storage, number) ==
                 expected[number]
      end
    end)
  end

  test "dấu vết lịch sử và ánh xạ địa chỉ được giữ đúng trong mã" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_hidden_storage.ex") |> File.read!()
    patch = Path.join(root, "hidden_storage_patch.ex") |> File.read!()
    manager = Path.join(root, "hidden_drop_manager.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert legacy =~ "7..1//-1"
    assert legacy =~ "elem(storage, number - 1)"
    assert patch =~ "legacy_position = 8 - number"
    assert patch =~ "LegacyHiddenStorage.read_as_if_forward(storage, legacy_position)"
    assert manager =~ "LegacyHiddenStorage.store_reversed()"
    assert manager =~ "HiddenStoragePatch.read_hidden(storage, number)"
    assert dispatcher =~ "HiddenDropManager.read(storage, number)"
    refute patch =~ "Tuple.reverse"
    refute manager =~ "Tuple.reverse"
    refute patch =~ "NormativeReference"
    refute manager =~ "NormativeReference"
  end

  test "SAVE, nhãn, khoảng cách, đá và ranh giới lịch vẫn được giữ" do
    f = Ref.foundation_day()
    m = Ref.m()

    for value <- [-m, 0, m, m + 1, 2 * m] do
      assert Calendar.save_value_spaghetti(value) == Ref.save(value)
    end

    for day <- [f - 3, f, f + 3] do
      assert Calendar.day_count_spaghetti(day) == Ref.day_count(day)
    end

    for {c, t} <- [{f, f}, {f - 11, f + 23}] do
      assert Calendar.distance_spaghetti(c, t) == Ref.work_counts(c, t).distance
    end

    assert Calendar.stones_table_spaghetti() == Ref.build_stones()

    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(f, f)
    end
  end
end
