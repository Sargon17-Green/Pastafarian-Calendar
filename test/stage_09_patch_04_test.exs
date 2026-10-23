defmodule PastafariCalendarElixirVietnamese.Stage09Patch04Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{LegacyStoneMutation, StoneManager, StonePatch}
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "hàm legacy còn sai nhưng hàng thứ hai được vá đủ năm ô" do
    old = {17, 29, 43, 71, 101}
    legacy = LegacyStoneMutation.mutate_stones_wrong(old, 2)
    corrected = StonePatch.patch_row(old, 2)

    assert legacy == {378, 1434, 3780, 9932, 25047}
    assert corrected == {378, 1073, 2375, 6195, 10493}
    assert corrected == Ref.build_stones()[2]
    refute legacy == corrected
    assert StoneManager.row_at(2) == corrected
  end

  test "mỗi hàng từ hai đến 46 khớp mọi giá trị của bộ chuẩn" do
    actual = Calendar.stones_table_spaghetti()
    reference = Ref.build_stones()

    assert map_size(actual) == 46
    assert Enum.sort(Map.keys(actual)) == Enum.to_list(1..46)

    for i <- 1..46 do
      assert actual[i] == reference[i]
      assert Calendar.stone_row_spaghetti(i) == reference[i]
    end
  end

  test "mọi hàng riêng tuân công thức chỉ đọc hàng cũ" do
    table = StoneManager.build_table()

    for index <- 2..46 do
      {w, b, s, m, r} = Map.fetch!(table, index - 1)
      expected = {
        Ref.save(w * w + 3 * b + index),
        Ref.save(b * b + 5 * s + w),
        Ref.save(s * s + 7 * m + b),
        Ref.save(m * m + 11 * r + s),
        Ref.save(r * r + 13 * w + m)
      }

      assert StonePatch.patch_row(table[index - 1], index) == expected
      assert table[index] == expected
    end
  end

  test "gọi legacy trên clone thật nhưng không cho rác ảnh hưởng kết quả" do
    old = {17, 29, 43, 71, 101}
    bad = LegacyStoneMutation.mutate_stones_wrong(old, 2)
    good = StonePatch.patch_row(old, 2)

    assert elem(bad, 0) == elem(good, 0)

    for position <- 1..4 do
      refute elem(bad, position) == elem(good, position)
    end

    assert old == {17, 29, 43, 71, 101}
    assert StonePatch.patch_row(old, 2) == good
  end

  test "số nguyên rất lớn được thu gọn chính xác về miền SAVE" do
    m = Ref.m()
    huge = 1 <<< 2048
    row = {huge + 1, huge + 3, huge + 5, huge + 7, huge + 11}
    {w, b, s, meat, rice} = row
    i = 46

    output = StonePatch.patch_row(row, i)

    expected = {
      Ref.save(w * w + 3 * b + i),
      Ref.save(b * b + 5 * s + w),
      Ref.save(s * s + 7 * meat + b),
      Ref.save(meat * meat + 11 * rice + s),
      Ref.save(rice * rice + 13 * w + meat)
    }

    assert output == expected
    assert Enum.all?(Tuple.to_list(output), fn value -> value >= 1 and value <= m end)
  end

  test "ba vị trí muối, thịt, cơm đều không đọc giá trị mới" do
    old = {5, 7, 11, 13, 17}
    index = 19
    {w, b, s, m, r} = old
    result = StonePatch.patch_row(old, index)

    assert elem(result, 2) == Ref.save(s * s + 7 * m + b)
    assert elem(result, 3) == Ref.save(m * m + 11 * r + s)
    assert elem(result, 4) == Ref.save(r * r + 13 * w + m)
    refute result == LegacyStoneMutation.mutate_stones_wrong(old, index)
  end

  test "chứng cứ mã nguồn giữ snapshot, clone, legacy và năm ghi đè" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    patch_source = Path.join(root, "stone_patch.ex") |> File.read!()
    old_source = Path.join(root, "legacy_stone_mutation.ex") |> File.read!()
    manager_source = Path.join(root, "stone_manager.ex") |> File.read!()

    assert patch_source =~ "old_snapshot = previous_row |> Tuple.to_list() |> List.to_tuple()"
    assert patch_source =~ "legacy_clone = old_snapshot |> Tuple.to_list() |> List.to_tuple()"
    assert patch_source =~ "garbage = LegacyStoneMutation.mutate_stones_wrong(legacy_clone, index)"
    assert patch_source =~ "{w, b, s, m, r} = old_snapshot"

    for position <- 0..4 do
      assert patch_source =~ "put_elem(#{position}, SaveManager.calculate("
    end

    assert manager_source =~ "StonePatch.patch_row(previous_row, index)"
    assert old_source =~ "elem(updated_w, 0)"
    refute old_source =~ "StonePatch"
    refute patch_source =~ "NormativeReference"
  end

  test "ngữ cảnh mỗi lần gọi giữ bảng và không thay đổi theo ngày tính" do
    f = Ref.foundation_day()
    reference = Ref.build_stones()

    for {c, t} <- [{f, f}, {f - 90, f + 90}, {f + 120, f - 800}] do
      context = Calendar.bootstrap_context(c, t)
      assert context.stones_table == reference
      assert context.distance_count == Ref.work_counts(c, t).distance
    end
  end

  test "nhiều ngữ cảnh thực thi đồng thời giữ nguyên bảng chuẩn" do
    f = Ref.foundation_day()
    reference = Ref.build_stones()
    inputs = for delta <- -24..24, do: {f + delta, f - 3 * delta}

    results =
      Task.async_stream(inputs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        ordered: true, max_concurrency: 8, timeout: 15_000)
      |> Enum.map(fn {:ok, context} -> context end)

    assert length(results) == length(inputs)
    assert Enum.all?(results, &(&1.stones_table == reference))
  end

  test "kích thước hàng và chỉ số không hợp lệ bị từ chối rõ ràng" do
    for bad <- [nil, :khong_hop_le, {}, {1, 2}, [1, 2, 3, 4, 5], 123] do
      assert_raise ArgumentError, "hàng đá phải có năm giá trị và chỉ số từ 2 đến 46", fn ->
        StonePatch.patch_row(bad, 2)
      end
    end

    for index <- [0, 1, 47, nil, 2.0, "2"] do
      assert_raise ArgumentError, "hàng đá phải có năm giá trị và chỉ số từ 2 đến 46", fn ->
        StonePatch.patch_row({1, 2, 3, 4, 5}, index)
      end
    end
  end

  test "ba bản vá trước và biên ngày lịch chưa tích hợp vẫn chính xác" do
    f = Ref.foundation_day()
    m = Ref.m()

    for value <- [-m, 0, m, m + 1, 2 * m] do
      assert Calendar.save_value_spaghetti(value) == Ref.save(value)
    end

    for day <- [f - 3, f, f + 3] do
      assert Calendar.day_count_spaghetti(day) == Ref.day_count(day)
    end

    for {c, t} <- [{f, f}, {f - 2, f + 6}] do
      assert Calendar.distance_spaghetti(c, t) == Ref.work_counts(c, t).distance
    end

    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end
end
