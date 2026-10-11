defmodule PastafariCalendarElixirVietnamese.Monster.DistanceManager do
  @moduledoc """
  Bộ quản lý khoảng cách của lần phát hiện thứ ba.

  Xác thực ngày nguyên chính xác rồi thực thi phép tính sai lịch sử.
  Bản vá sửa khoảng cách theo thứ tự thời gian chỉ thuộc giai đoạn 7.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{LegacyDistance, Validator}

  def calculate(calculation_day, target_day) do
    Validator.require_integer_day!(calculation_day)
    Validator.require_integer_day!(target_day)
    LegacyDistance.old_distance(calculation_day, target_day)
  end
end
