defmodule PastafariCalendarElixirVietnamese.Monster.DayTagPatch do
  @moduledoc """
  Bản vá 02 của nhãn ngày, bọc công thức lịch sử thay vì sửa công thức đó.

  Công thức cũ chỉ tính hai lần khoảng cách tới Ngày Nền. Phía trước
  Ngày Nền kết quả đúng sẵn; từ Ngày Nền trở đi phải tăng thêm một.
  Điều kiện bảo vệ riêng ở chính Ngày Nền được giữ lại theo lịch sử
  dù nhánh tăng một trước đó đã bảo đảm kết quả bằng một.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyDayTag

  def day_tag_patch(day) when is_integer(day) do
    tag = LegacyDayTag.old_day_tag(day)

    tag =
      if day >= LegacyDayTag.foundation_day() do
        tag + 1
      else
        tag
      end

    if day == LegacyDayTag.foundation_day() and tag != 1 do
      1
    else
      tag
    end
  end
end
