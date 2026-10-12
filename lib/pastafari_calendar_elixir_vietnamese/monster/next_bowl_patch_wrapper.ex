defmodule PastafariCalendarElixirVietnamese.Monster.NextBowlPatchWrapper do
  @moduledoc """
  Bản vá 12: giữ bộ kế cận vòng tên cũ làm dấu vết chẩn đoán.

  Mỗi lần hỏi, gọi thật LegacyFixedNameSuccessor trước để
  nhận ID theo vòng số cố định; giá trị đó chỉ đi vào kết quả
  chẩn đoán. Kết quả được trả cho người gọi luôn được lấy từ
  vị trí ID trong thứ tự đã chốt tại giọt 46, có vòng nối
  vị trí cuối về đầu. Không có biến toàn cục hay sửa legacy.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyFixedNameSuccessor,
    OrderAt46LatchPatch
  }

  def diagnose(order_at_46_latch, queried_id) do
    legacy_next_id =
      LegacyFixedNameSuccessor.old_next_bowl_fixed_name(queried_id)

    correct_next_id =
      OrderAt46LatchPatch.next_bowl(order_at_46_latch, queried_id)

    %{
      queried_id: queried_id,
      legacy_next_id: legacy_next_id,
      correct_next_id: correct_next_id,
      diverges: legacy_next_id != correct_next_id
    }
  end

  def next_bowl(order_at_46_latch, queried_id) do
    diagnose(order_at_46_latch, queried_id).correct_next_id
  end
end
