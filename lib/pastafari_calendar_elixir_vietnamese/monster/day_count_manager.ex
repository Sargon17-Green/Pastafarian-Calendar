defmodule PastafariCalendarElixirVietnamese.Monster.DayCountManager do
  @moduledoc """
  Tầng quản lý đánh số ngày vẫn tồn tại sau lần phát hiện thứ hai.

  Nhánh sản xuất đi vòng qua DayTagPatch trước khi trả nhãn ngày.
  DayTagPatch vẫn gọi trực tiếp hàm cũ bị lỗi; bộ quản lý không bỏ
  qua lớp lỗi, không gọi bộ tham chiếu và không giữ trạng thái chung.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{DayTagPatch, Validator}

  def tag(day) do
    Validator.require_integer_day!(day)
    DayTagPatch.day_tag_patch(day)
  end
end
