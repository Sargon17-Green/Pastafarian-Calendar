defmodule PastafariCalendarElixirVietnamese.Monster.VisibleDropManager do
  @moduledoc """
  Bộ quản lý giọt nhìn thấy đi qua bản vá lịch sử 06.

  Cả 46 giọt được tạo trong mỗi lần gọi riêng; kho giọt ẩn được
  truyền từ ngữ cảnh hiện tại, không tính lại và không dùng biến chung.
  """

  alias PastafariCalendarElixirVietnamese.Monster.VisibleDropCalculator

  def build(calculation_day, target_day, action_tag, target_tag, distance, stones, hidden_storage) do
    VisibleDropCalculator.calculate(
      calculation_day,
      target_day,
      action_tag,
      target_tag,
      distance,
      stones,
      hidden_storage
    )
  end

  def read(visible, index) when is_map(visible) and is_integer(index) and index in 1..46 do
    Map.fetch!(visible, index)
  end

  def read(_visible, _index) do
    raise ArgumentError, "chỉ số giọt nhìn thấy phải từ 1 đến 46"
  end
end
