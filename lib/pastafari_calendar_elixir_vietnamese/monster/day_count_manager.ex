defmodule PastafariCalendarElixirVietnamese.Monster.DayCountManager do
  @moduledoc """
  Tầng quản lý đánh số ngày được hình thành trong lần phát hiện thứ hai.

  Chưa có lớp sửa cho trường hợp ngày nền và các ngày phía sau.
  Lời gọi sản xuất vẫn chuyển trực tiếp sang công thức lịch sử không đúng.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{LegacyDayTag, Validator}

  def tag(day) do
    Validator.require_integer_day!(day)
    LegacyDayTag.old_day_tag(day)
  end
end
