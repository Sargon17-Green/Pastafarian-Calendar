defmodule PastafariCalendarElixirVietnamese.Monster.DistancePatch do
  @moduledoc """
  Bản vá 03 giữ lại phép tính khoảng cách cũ trong đường chạy thật.

  Nếu hiệu hai nhãn ngày khác khoảng cách thời gian, thay giá trị cơ sở
  bằng khoảng cách thời gian. Kết quả cuối cùng luôn tăng thêm một.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyDistance

  def distance_patch(calculation_day, target_day)
      when is_integer(calculation_day) and is_integer(target_day) do
    legacy = LegacyDistance.old_distance(calculation_day, target_day)
    chronological = abs(target_day - calculation_day)

    base_distance =
      if legacy != chronological do
        chronological
      else
        legacy
      end

    base_distance + 1
  end
end
