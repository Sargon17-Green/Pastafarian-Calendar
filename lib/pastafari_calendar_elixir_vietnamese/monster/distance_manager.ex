defmodule PastafariCalendarElixirVietnamese.Monster.DistanceManager do
  @moduledoc """
  Bộ quản lý khoảng cách giữ lại nhánh cũ nhưng dẫn qua bản vá 03.
  Xác thực đầu vào trước khi gọi bản vá lịch sử.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{DistancePatch, Validator}

  def calculate(calculation_day, target_day) do
    Validator.require_integer_day!(calculation_day)
    Validator.require_integer_day!(target_day)
    DistancePatch.distance_patch(calculation_day, target_day)
  end
end
