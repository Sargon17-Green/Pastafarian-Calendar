defmodule PastafariCalendarElixirVietnamese.Monster.SaveManager do
  @moduledoc """
  Tầng điều phối phép SAVE hình thành ở giai đoạn khám phá thứ nhất.

  Tầng này đang ủy quyền trực tiếp cho phép dư lịch sử sai.
  Không có lớp sửa sai, đường dự phòng hoặc bộ tham chiếu kiểm thử.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{LegacyRemainder, Validator}

  def calculate(value) do
    Validator.require_integer_value!(value)
    LegacyRemainder.old_remainder(value)
  end
end
