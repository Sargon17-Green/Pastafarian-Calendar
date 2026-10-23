defmodule PastafariCalendarElixirVietnamese.Stage07Patch03Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{DistanceManager, DistancePatch, LegacyDistance}
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "nhánh giữ nguyên chạy khi hai khoảng cách cơ sở trùng nhau" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 1, f + 2}, {f - 2, f + 5}, {f - 3, f + 8}] do
      raw = LegacyDistance.old_distance(c, t)
      chronological = abs(t - c)

      assert raw == chronological
      assert DistancePatch.distance_patch(c, t) == raw + 1
      assert Calendar.distance_spaghetti(c, t) == Ref.work_counts(c, t).distance
    end
  end

  test "nhánh sửa thực sự thay khoảng cách lịch sử khác chuẩn" do
    f = Ref.foundation_day()

    for {c, t} <- [{f - 2, f}, {f - 3, f - 1}, {f + 1, f + 3}, {f - 1, f + 1}] do
      raw = LegacyDistance.old_distance(c, t)
      chronological = abs(t - c)

      refute raw == chronological
      assert DistancePatch.distance_patch(c, t) == chronological + 1
      assert DistanceManager.calculate(c, t) == Ref.work_counts(c, t).distance
    end
  end

  test "mọi cặp ngày trong lưới quanh Ngày Nền khớp tham chiếu chuẩn" do
    f = Ref.foundation_day()

    for c_offset <- -32..32, t_offset <- -32..32 do
      c = f + c_offset
      t = f + t_offset
      expected = Ref.work_counts(c, t).distance

      assert Calendar.distance_spaghetti(c, t) == expected
      assert Calendar.bootstrap_context(c, t).distance_count == expected
    end
  end

  test "ngày cực xa và số nguyên tùy ý không mất độ chính xác" do
    f = Ref.foundation_day()

    for shift <- [1 <<< 128, 1 <<< 512, 1 <<< 2048] do
      for {c, t} <- [
        {f - shift, f + shift},
        {f + shift, f - shift},
        {f - shift, f - shift - 19},
        {f + shift, f + shift + 19},
        {f + shift, f + shift}
      ] do
        expected = Ref.work_counts(c, t).distance
        assert Calendar.distance_spaghetti(c, t) == expected
        assert Calendar.bootstrap_context(c, t).distance_count == expected
      end
    end
  end

  test "tính đối xứng và hướng thời gian không làm đổi khoảng cách" do
    f = Ref.foundation_day()

    for c_offset <- [-101, -7, -1, 0, 1, 7, 101],
        t_offset <- [-101, -7, -1, 0, 1, 7, 101] do
      c = f + c_offset
      t = f + t_offset
      assert Calendar.distance_spaghetti(c, t) == Calendar.distance_spaghetti(t, c)
      assert Calendar.distance_spaghetti(c, t) == abs(t - c) + 1
    end
  end

  test "hàm lịch sử vẫn sai nhưng tuyến công khai có kết quả đã vá" do
    f = Ref.foundation_day()

    Enum.each([{f, f}, {f - 3, f - 1}, {f + 1, f + 3}, {f - 1, f + 1}], fn {c, t} ->
      legacy = LegacyDistance.old_distance(c, t)
      expected = Ref.work_counts(c, t).distance
      refute legacy == expected
      assert Calendar.distance_spaghetti(c, t) == expected
    end)
  end

  test "cấu trúc bắt buộc giữ ba chức năng lịch sử thật" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy_source = Path.join(root, "legacy_distance.ex") |> File.read!()
    patch_source = Path.join(root, "distance_patch.ex") |> File.read!()
    manager_source = Path.join(root, "distance_manager.ex") |> File.read!()
    save_source = Path.join(root, "save_patch.ex") |> File.read!()
    day_source = Path.join(root, "day_tag_patch.ex") |> File.read!()

    assert legacy_source =~ "DayCountManager.tag(calculation_day)"
    refute legacy_source =~ "chronological"
    assert patch_source =~ "LegacyDistance.old_distance(calculation_day, target_day)"
    assert patch_source =~ "chronological = abs(target_day - calculation_day)"
    assert patch_source =~ "if legacy != chronological do"
    assert patch_source =~ "base_distance + 1"
    assert manager_source =~ "DistancePatch.distance_patch(calculation_day, target_day)"
    assert save_source =~ "LegacyRemainder.old_remainder(value)"
    assert day_source =~ "LegacyDayTag.old_day_tag(day)"
  end

  test "các yêu cầu đồng thời không chia sẻ trạng thái ngữ nghĩa" do
    f = Ref.foundation_day()
    inputs = for delta <- -64..64, do: {f + delta * 17, f - delta * 31}

    contexts =
      inputs
      |> Task.async_stream(fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        ordered: true, max_concurrency: 8, timeout: 15_000)
      |> Enum.map(fn {:ok, context} -> context end)

    Enum.zip(inputs, contexts)
    |> Enum.each(fn {{c, t}, context} ->
      assert context.distance_count == Ref.work_counts(c, t).distance
      assert context.metrics[:distance_patch_03_calls] == 1
      assert context.metrics[:legacy_distance_calls] == 1
    end)
  end

  test "đầu vào không nguyên vẫn bị từ chối trước bản vá" do
    f = Ref.foundation_day()

    for invalid <- [nil, 1.0, "19", :khong_hop_le, %{}, [1]] do
      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.distance_spaghetti(f, invalid)
      end

      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.bootstrap_context(invalid, f)
      end
    end
  end

  test "các bản vá 01/02 và ranh giới ngày lịch vẫn nguyên" do
    f = Ref.foundation_day()
    m = Ref.m()

    for value <- [-m, 0, m, 2 * m, m + 1] do
      assert Calendar.save_value_spaghetti(value) == Ref.save(value)
    end

    for day <- [f - 2, f - 1, f, f + 1, f + 2] do
      assert Calendar.day_count_spaghetti(day) == Ref.day_count(day)
    end

    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end
end
