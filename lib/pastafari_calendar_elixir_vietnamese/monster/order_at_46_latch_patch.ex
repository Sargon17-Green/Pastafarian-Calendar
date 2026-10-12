defmodule PastafariCalendarElixirVietnamese.Monster.OrderAt46LatchPatch do
  @moduledoc """
  Bản vá 11: chốt bất biến thứ tự đúng tại giọt thứ 46.

  Giữ nguyên 58 lần ghi của LegacyOrderMemory: chốt riêng
  khi nguồn còn là giọt 46, trước 12 lượt khuấy cuối.
  Truy vấn dùng chốt đã tách khỏi ô legacy vẫn bị ghi đè.
  Hàm next_bowl thực sự tái sử dụng bộ đọc legacy trên
  bản xem chỉ chứa thứ tự được chốt, không sửa thuật toán cũ.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyOrderMemory

  @six_ids [1, 2, 3, 4, 5, 6]

  def capture(%{order: order, writes: 46, last_source: {:drop, 46}})
      when is_list(order) and length(order) == 6 do
    if Enum.sort(order) == @six_ids do
      order
    else
      raise ArgumentError, "thứ tự giọt 46 phải chứa sáu ID bát"
    end
  end

  def capture(_memory) do
    raise ArgumentError, "chỉ được chốt thứ tự ngay sau giọt 46"
  end

  def next_bowl(order_at_46_latch, queried_id)
      when is_list(order_at_46_latch) and length(order_at_46_latch) == 6 do
    if Enum.sort(order_at_46_latch) == @six_ids do
      LegacyOrderMemory.next_bowl(
        %{order: order_at_46_latch},
        queried_id
      )
    else
      raise ArgumentError, "thứ tự giọt 46 phải chứa sáu ID bát"
    end
  end

  def next_bowl(_order_at_46_latch, _queried_id) do
    raise ArgumentError, "thứ tự giọt 46 không hợp lệ"
  end
end
