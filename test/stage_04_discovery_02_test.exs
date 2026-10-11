defmodule PastafariCalendarElixirVietnamese.Stage04Discovery02Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{DayCountManager, LegacyDayTag}
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "lớp đánh số lịch sử thực sự chạy trong ngữ cảnh sản xuất" do
    f = Ref.foundation_day()
    left = Calendar.bootstrap_context(f - 3, f + 7)
    right = Calendar.bootstrap_context(f - 3, f + 7)

    assert LegacyDayTag.foundation_day() == f
    assert left.calculation_day_tag == LegacyDayTag.old_day_tag(f - 3)
    assert left.target_day_tag == LegacyDayTag.old_day_tag(f + 7)
    assert left.branch_trace == [:entry, :validated, :legacy_day_count]
    assert left.logs == [{:bootstrap, f - 3, f + 7}, {:day_tags, 6, 14}]
    assert right == left
    assert DayCountManager.tag(f + 7) == left.target_day_tag
    assert Calendar.day_count_spaghetti(f + 7) == left.target_day_tag
  end

  test "các ngày trước Ngày Nền vô tình trùng với quy tắc chuẩn" do
    f = Ref.foundation_day()
    offsets = [1, 2, 3, 7, 31, 365, 1_000_000, 1 <<< 512]

    Enum.each(offsets, fn delta ->
      day = f - delta
      assert LegacyDayTag.old_day_tag(day) == 2 * delta
      assert Calendar.day_count_spaghetti(day) == Ref.day_count(day)
      assert Calendar.bootstrap_context(day, day).target_day_tag == Ref.day_count(day)
    end)
  end

  test "đầu vào ngày không chính xác vẫn bị từ chối" do
    for value <- [nil, :khong_hop_le, 3.5, "3", [1], %{}] do
      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.day_count_spaghetti(value)
      end

      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.bootstrap_context(Ref.foundation_day(), value)
      end
    end
  end

  test "nhánh SAVE đã vá không hồi quy khi mở nhánh ngày" do
    m = Ref.m()

    for value <- [-m, 0, m, 2 * m, 3 * m, m + 1] do
      assert Calendar.save_value_spaghetti(value) == Ref.save(value)
    end

    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(Ref.foundation_day(), Ref.foundation_day())
    end
  end

  test "hồi quy chuẩn tại Ngày Nền: cố ý đỏ ở giai đoạn khám phá 02" do
    f = Ref.foundation_day()
    assert Calendar.day_count_spaghetti(f) == Ref.day_count(f)
  end

  test "hồi quy chuẩn ngày ngay sau Ngày Nền: cố ý đỏ ở giai đoạn khám phá 02" do
    f = Ref.foundation_day()
    assert Calendar.day_count_spaghetti(f + 1) == Ref.day_count(f + 1)
  end

  test "hồi quy chuẩn ngày thứ hai sau Ngày Nền: cố ý đỏ ở giai đoạn khám phá 02" do
    f = Ref.foundation_day()
    assert Calendar.bootstrap_context(f - 1, f + 2).target_day_tag == Ref.day_count(f + 2)
  end
end
