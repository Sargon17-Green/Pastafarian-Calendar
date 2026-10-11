defmodule PastafariCalendarElixirVietnamese.Monster.LegacyPrior do
  @moduledoc """
  Lần phát hiện 06: hàm đọc giọt trước chỉ biết kho giọt nhìn thấy.

  Các địa chỉ từ 0 đến -6 không có trong kho. Thiết kế cũ dùng
  số không cho ô vắng mặt, thay vì hỏi kho bảy giọt ẩn.
  Không thêm bản vá phân nhánh lịch sử tại giai đoạn này.
  """

  def legacy_prior(visible_store, index, back)
      when is_map(visible_store) and is_integer(index) and index >= 1 and
             is_integer(back) and back in [1, 3, 7] do
    slot = index - back
    Map.get(visible_store, slot, 0)
  end

  def legacy_prior(_visible_store, _index, _back) do
    raise ArgumentError, "chỉ được đọc giọt trước với độ lùi 1, 3 hoặc 7"
  end
end
