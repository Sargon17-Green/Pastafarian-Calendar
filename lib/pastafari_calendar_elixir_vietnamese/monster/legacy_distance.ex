defmodule PastafariCalendarElixirVietnamese.Monster.LegacyDistance do
  @moduledoc """
  Khoảng cách lịch sử sai của phát hiện thứ ba.

  Người thiết kế cũ lấy hiệu tuyệt đối giữa hai nhãn ngày đã được vá,
  tưởng nhầm đó là khoảng cách theo trục ngày. Không cộng một và không
  so sánh lại với khoảng cách thời gian ở giai đoạn khám phá này.
  """

  alias PastafariCalendarElixirVietnamese.Monster.DayCountManager

  def old_distance(calculation_day, target_day) do
    abs(
      DayCountManager.tag(calculation_day) -
        DayCountManager.tag(target_day)
    )
  end
end
