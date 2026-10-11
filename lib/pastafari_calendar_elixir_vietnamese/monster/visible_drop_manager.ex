defmodule PastafariCalendarElixirVietnamese.Monster.VisibleDropManager do
  @moduledoc """
  Bộ quản lý giọt nhìn thấy qua đường cũ chưa biết giọt ẩn.

  Kết quả của 46 giọt được xây trong mỗi lần gọi riêng biệt.
  Không sửa phép đọc lịch sử cho các địa chỉ âm trước giai đoạn 13.
  """

  alias PastafariCalendarElixirVietnamese.Monster.VisibleDropCalculator

  def build(calculation_day, target_day, action_tag, target_tag, distance, stones) do
    VisibleDropCalculator.calculate(
      calculation_day,
      target_day,
      action_tag,
      target_tag,
      distance,
      stones
    )
  end

  def read(visible, index) when is_map(visible) and is_integer(index) and index in 1..46 do
    Map.fetch!(visible, index)
  end

  def read(_visible, _index) do
    raise ArgumentError, "chỉ số giọt nhìn thấy phải từ 1 đến 46"
  end
end
