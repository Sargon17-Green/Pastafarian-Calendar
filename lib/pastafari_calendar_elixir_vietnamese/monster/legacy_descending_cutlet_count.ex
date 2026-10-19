defmodule PastafariCalendarElixirVietnamese.Monster.LegacyDescendingCutletCount do
  @moduledoc """
  Di sản DISCOVERY20: thứ tự ứng viên số cốt-lết bị đảo.
  Cùng tập ứng viên và cùng rank nhưng chọn từ dài đến ngắn;
  PATCH20 phải giữ nguyên đoạn lỗi lịch sử này.
  """
  def sort(candidates) when is_list(candidates), do: Enum.sort(candidates, :desc)
  def sort(_), do: raise(ArgumentError, "danh sách số cốt-lết không hợp lệ")
end
