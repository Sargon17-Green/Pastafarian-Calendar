defmodule PastafariCalendarElixirVietnamese.Monster.AscendingMonthCountPatch do
  @moduledoc """
  PATCH24 thực sự gọi di sản đảo thứ tự các ứng viên,
  giữ toàn bộ thứ tự lịch sử, rồi chọn lại theo thứ tự
  tăng dần chuẩn với cùng hạng và cùng tập số tháng.
  """
  alias PastafariCalendarElixirVietnamese.Monster.LegacyDescendingMonthCount

  def diagnose(candidates, rank) when is_list(candidates) and is_integer(rank) do
    historical_order = LegacyDescendingMonthCount.sort(candidates)
    corrected_order = Enum.sort(historical_order)
    count = length(corrected_order)
    if rank < 1 or rank > count do
      raise ArgumentError, "hạng số tháng không hợp lệ"
    end
    %{historical_order: historical_order, corrected_order: corrected_order,
      historical_count: Enum.at(historical_order, rank - 1),
      corrected_count: Enum.at(corrected_order, rank - 1),
      rank: rank, changed: historical_order != corrected_order}
  end

  def diagnose(_, _), do: raise(ArgumentError, "ứng viên hoặc hạng không hợp lệ")
end
