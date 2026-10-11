defmodule PastafariCalendarElixirVietnamese.Stage02Discovery01Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.LegacyRemainder
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "phần dư lịch sử thực sự được nối vào đường sản xuất" do
    m = Ref.m()

    assert LegacyRemainder.modulus() == m
    assert LegacyRemainder.old_remainder(m) == 0
    assert Calendar.save_value_spaghetti(m) == LegacyRemainder.old_remainder(m)
  end

  test "đối chứng M cộng một vẫn khớp với phép SAVE chuẩn" do
    m = Ref.m()

    assert Calendar.save_value_spaghetti(m + 1) == 1
    assert Calendar.save_value_spaghetti(m + 1) == Ref.save(m + 1)
    assert Calendar.save_value_spaghetti(m - 1) == Ref.save(m - 1)
  end

  test "nhánh SAVE chỉ nhận giá trị nguyên chính xác" do
    assert_raise ArgumentError, "giá trị phải là số nguyên chính xác", fn ->
      Calendar.save_value_spaghetti(1.0)
    end
  end

  test "hồi quy chuẩn ở M: cố ý đỏ cho phát hiện thứ nhất" do
    m = Ref.m()
    assert Calendar.save_value_spaghetti(m) == Ref.save(m)
  end

  test "hồi quy chuẩn ở 2M: cố ý đỏ cho phát hiện thứ nhất" do
    m = Ref.m()
    assert Calendar.save_value_spaghetti(2 * m) == Ref.save(2 * m)
  end

  test "hồi quy chuẩn ở 3M: cố ý đỏ cho phát hiện thứ nhất" do
    m = Ref.m()
    assert Calendar.save_value_spaghetti(3 * m) == Ref.save(3 * m)
  end
end
