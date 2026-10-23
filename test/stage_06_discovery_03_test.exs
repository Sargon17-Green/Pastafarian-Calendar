defmodule PastafariCalendarElixirVietnamese.Stage06Discovery03Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    DayCountManager,
    DistanceManager,
    LegacyDistance
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "lớp lỗi cũ tồn tại nhưng ngữ cảnh đã dùng bản vá 03" do
    f = Ref.foundation_day()
    calculation_day = f - 1
    target_day = f + 1
    context = Calendar.bootstrap_context(calculation_day, target_day)

    assert context.calculation_day_tag == 2
    assert context.target_day_tag == 3
    assert LegacyDistance.old_distance(calculation_day, target_day) == 1
    assert context.distance_count == Ref.work_counts(calculation_day, target_day).distance
    refute context.distance_count == LegacyDistance.old_distance(calculation_day, target_day)
    assert context.metrics[:legacy_distance_calls] == 1
    assert context.metrics[:distance_patch_03_calls] == 1
    assert DistanceManager.calculate(calculation_day, target_day) == 3
    assert Calendar.distance_spaghetti(calculation_day, target_day) == 3
  end

  test "hai đối chứng tình cờ đúng ở hai phía Ngày Nền" do
    f = Ref.foundation_day()
    examples = [{f - 2, f}, {f + 1, f + 2}]

    Enum.each(examples, fn {calculation_day, target_day} ->
      expected = Ref.work_counts(calculation_day, target_day).distance
      assert Calendar.distance_spaghetti(calculation_day, target_day) == expected
      assert Calendar.bootstrap_context(calculation_day, target_day).distance_count == expected
    end)
  end

  test "đường lịch sử đối xứng và giữ số nguyên lớn nguyên vẹn" do
    f = Ref.foundation_day()
    shift = 1 <<< 512

    for {calculation_day, target_day} <- [
          {f - shift, f + shift},
          {f + shift, f - shift},
          {f - shift, f - shift - 3},
          {f + shift, f + shift + 3}
        ] do
      expected =
        abs(
          DayCountManager.tag(calculation_day) -
            DayCountManager.tag(target_day)
        )

      assert LegacyDistance.old_distance(calculation_day, target_day) == expected
      corrected = Ref.work_counts(calculation_day, target_day).distance
      assert Calendar.distance_spaghetti(calculation_day, target_day) == corrected
      assert Calendar.distance_spaghetti(target_day, calculation_day) == corrected
      assert Calendar.bootstrap_context(calculation_day, target_day).distance_count == corrected
    end
  end

  test "các ngữ cảnh song song không truyền khoảng cách sang nhau" do
    f = Ref.foundation_day()
    pairs = for delta <- -40..40, do: {f + delta, f - delta + 1}

    results =
      Task.async_stream(pairs, fn {c, t} ->
        Calendar.bootstrap_context(c, t)
      end, ordered: true, max_concurrency: 8, timeout: 15_000)
      |> Enum.map(fn {:ok, context} -> context end)

    assert length(results) == length(pairs)

    Enum.zip(pairs, results)
    |> Enum.each(fn {{c, t}, context} ->
      assert context.calculation_day == c
      assert context.target_day == t
      assert LegacyDistance.old_distance(c, t) == abs(Ref.day_count(c) - Ref.day_count(t))
      assert context.distance_count == Ref.work_counts(c, t).distance
      assert context.metrics[:legacy_distance_calls] == 1
      assert context.metrics[:distance_patch_03_calls] == 1
    end)
  end

  test "kiểm tra đầu vào và các bản vá trước vẫn giữ nguyên hành vi" do
    f = Ref.foundation_day()
    m = Ref.m()

    for bad <- [nil, :khong_hop_le, "1", 0.5, %{}, [1]] do
      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.distance_spaghetti(f, bad)
      end

      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.distance_spaghetti(bad, f)
      end
    end

    for day <- [f - 7, f - 1, f, f + 1, f + 7] do
      assert Calendar.day_count_spaghetti(day) == Ref.day_count(day)
    end

    for value <- [-m, 0, m, m + 1] do
      assert Calendar.save_value_spaghetti(value) == Ref.save(value)
    end
  end

  test "cấu trúc giữ sai lệch cũ dưới lớp vá 03" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    distance_source = Path.join(root, "legacy_distance.ex") |> File.read!()
    manager_source = Path.join(root, "distance_manager.ex") |> File.read!()
    patch_source = Path.join(root, "distance_patch.ex") |> File.read!()
    dispatcher_source = Path.join(root, "dispatcher.ex") |> File.read!()
    day_patch_source = Path.join(root, "day_tag_patch.ex") |> File.read!()

    assert distance_source =~ "DayCountManager.tag(calculation_day)"
    assert distance_source =~ "DayCountManager.tag(target_day)"
    assert manager_source =~ "DistancePatch.distance_patch(calculation_day, target_day)"
    assert patch_source =~ "LegacyDistance.old_distance(calculation_day, target_day)"
    assert patch_source =~ "chronological = abs(target_day - calculation_day)"
    assert dispatcher_source =~ "DistanceManager.calculate(calculation_day, target_day)"
    assert day_patch_source =~ "LegacyDayTag.old_day_tag(day)"
    refute distance_source =~ "NormativeReference"
    refute distance_source =~ "chronological"
    refute manager_source =~ "chronological"

    f = Ref.foundation_day()
    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end

  test "hồi quy chuẩn ở cùng một ngày: cố ý đỏ cho phát hiện 03" do
    f = Ref.foundation_day()
    assert Calendar.distance_spaghetti(f, f) == Ref.work_counts(f, f).distance
  end

  test "hồi quy chuẩn hai ngày sau Ngày Nền: cố ý đỏ cho phát hiện 03" do
    f = Ref.foundation_day()
    assert Calendar.distance_spaghetti(f + 1, f + 3) ==
             Ref.work_counts(f + 1, f + 3).distance
  end

  test "hồi quy chuẩn hai ngày trước Ngày Nền: cố ý đỏ cho phát hiện 03" do
    f = Ref.foundation_day()
    assert Calendar.distance_spaghetti(f - 3, f - 1) ==
             Ref.work_counts(f - 3, f - 1).distance
  end

  test "hồi quy chuẩn khi đi qua Ngày Nền: cố ý đỏ cho phát hiện 03" do
    f = Ref.foundation_day()
    assert Calendar.bootstrap_context(f - 1, f + 1).distance_count ==
             Ref.work_counts(f - 1, f + 1).distance
  end
end
