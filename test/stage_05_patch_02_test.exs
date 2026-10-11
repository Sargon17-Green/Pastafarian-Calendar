defmodule PastafariCalendarElixirVietnamese.Stage05Patch02Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    DayCountManager,
    DayTagPatch,
    LegacyDayTag
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "lớp vá vẫn gọi công thức lịch sử và sửa cả ngày nền" do
    f = Ref.foundation_day()

    assert LegacyDayTag.foundation_day() == f
    assert LegacyDayTag.old_day_tag(f) == 0
    assert LegacyDayTag.old_day_tag(f + 1) == 2

    assert DayTagPatch.day_tag_patch(f) == 1
    assert DayTagPatch.day_tag_patch(f + 1) == 3
    assert DayCountManager.tag(f + 2) == 5
    assert Calendar.day_count_spaghetti(f + 3) == 7
  end

  test "tất cả giá trị kề ngày nền ở hai phía khớp bộ chuẩn" do
    f = Ref.foundation_day()

    for delta <- -512..512 do
      day = f + delta
      actual = Calendar.day_count_spaghetti(day)

      assert actual == Ref.day_count(day)
      assert actual >= 1

      if delta < 0, do: assert(rem(actual, 2) == 0)
      if delta >= 0, do: assert(rem(actual, 2) == 1)
    end
  end

  test "các số nguyên chính xác cực lớn không làm mất độ chính xác" do
    f = Ref.foundation_day()

    for delta <- [1 <<< 128, 1 <<< 512, 1 <<< 1024, (1 <<< 4096) + 17] do
      before_day = f - delta
      after_day = f + delta

      assert Calendar.day_count_spaghetti(before_day) == 2 * delta
      assert Calendar.day_count_spaghetti(after_day) == 2 * delta + 1
      assert Calendar.day_count_spaghetti(before_day) == Ref.day_count(before_day)
      assert Calendar.day_count_spaghetti(after_day) == Ref.day_count(after_day)
    end
  end

  test "nhãn ngày trên mỗi phía tăng hoặc giảm đều đặn và không giao nhau" do
    f = Ref.foundation_day()

    for delta <- 1..512 do
      assert Calendar.day_count_spaghetti(f - delta - 1) ==
               Calendar.day_count_spaghetti(f - delta) + 2

      assert Calendar.day_count_spaghetti(f + delta) ==
               Calendar.day_count_spaghetti(f + delta - 1) + 2
    end

    assert Calendar.day_count_spaghetti(f - 1) == 2
    assert Calendar.day_count_spaghetti(f) == 1
    assert Calendar.day_count_spaghetti(f + 1) == 3
  end

  test "hai nhãn trong ngữ cảnh tính độc lập cho mọi cặp biên" do
    f = Ref.foundation_day()
    days = [f - 1_000_000, f - 1, f, f + 1, f + 1_000_000]

    for calculation_day <- days, target_day <- days do
      context = Calendar.bootstrap_context(calculation_day, target_day)

      assert context.calculation_day_tag == Ref.day_count(calculation_day)
      assert context.target_day_tag == Ref.day_count(target_day)
      assert context.logs == [
               {:bootstrap, calculation_day, target_day},
               {:day_tags, Ref.day_count(calculation_day), Ref.day_count(target_day)}
             ]
    end
  end

  test "dấu vết vá và điều kiện bảo vệ lịch sử vẫn tồn tại trong mã sản xuất" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy_source = Path.join(root, "legacy_day_tag.ex") |> File.read!()
    patch_source = Path.join(root, "day_tag_patch.ex") |> File.read!()
    manager_source = Path.join(root, "day_count_manager.ex") |> File.read!()

    assert legacy_source =~ "2 * abs(day - @foundation_day)"
    refute legacy_source =~ "DayTagPatch"
    assert patch_source =~ "LegacyDayTag.old_day_tag(day)"
    assert patch_source =~ "day >= LegacyDayTag.foundation_day()"
    assert patch_source =~ "day == LegacyDayTag.foundation_day() and tag != 1"
    assert manager_source =~ "DayTagPatch.day_tag_patch(day)"
    refute patch_source =~ "NormativeReference"

    context = Calendar.bootstrap_context(Ref.foundation_day(), Ref.foundation_day())
    assert context.branch_trace == [:entry, :validated, :legacy_day_count, :day_tag_patch_02]
  end

  test "các yêu cầu chạy đồng thời không chia sẻ trạng thái ngữ nghĩa" do
    f = Ref.foundation_day()
    inputs = Enum.map(-128..128, fn delta -> f + delta * 97 end)

    results =
      Task.async_stream(inputs, &Calendar.day_count_spaghetti/1,
        ordered: true,
        max_concurrency: 8,
        timeout: 15_000
      )
      |> Enum.map(fn {:ok, value} -> value end)

    assert results == Enum.map(inputs, &Ref.day_count/1)
    assert results == Enum.map(inputs, &Calendar.day_count_spaghetti/1)
  end

  test "đầu vào không nguyên vẫn bị từ chối và lỗi không gây rò rỉ" do
    f = Ref.foundation_day()

    for invalid <- [nil, "0", :khong_hop_le, 1.5, %{}, [1]] do
      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.day_count_spaghetti(invalid)
      end

      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.bootstrap_context(invalid, f)
      end
    end

    assert Calendar.bootstrap_context(f, f).target_day_tag == 1
  end

  test "bản vá SAVE đầu tiên vẫn đúng và ngày lịch đầy đủ chưa tích hợp" do
    f = Ref.foundation_day()
    m = Ref.m()

    for value <- [-2 * m, -m, -1, 0, 1, m, 2 * m, 3 * m, m + 1] do
      assert Calendar.save_value_spaghetti(value) == Ref.save(value)
    end

    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(f, f)
    end
  end
