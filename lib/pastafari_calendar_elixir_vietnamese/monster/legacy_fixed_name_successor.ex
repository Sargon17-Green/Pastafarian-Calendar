defmodule PastafariCalendarElixirVietnamese.Monster.LegacyFixedNameSuccessor do
  @moduledoc """
  Phát hiện 12: bộ tìm bát kế tiếp dựa vào tên ID cố định.

  Hàm lịch sử này coi sáu tên ID là một vòng số học
  1 → 2 → 3 → 4 → 5 → 6 → 1. Nó không biết
  order_at_46_latch và không tìm vị trí của ID được hỏi
  trong thứ tự thực tế. Bản vá 12 phải giữ nguyên
  hàm và chỉ dùng kết quả sai làm chứng cứ chẩn đoán.
  """

  def old_next_bowl_fixed_name(id) when is_integer(id) and id in 1..6 do
    rem(id, 6) + 1
  end

  def old_next_bowl_fixed_name(_id) do
    raise ArgumentError, "mã bát phải thuộc 1..6"
  end
end
