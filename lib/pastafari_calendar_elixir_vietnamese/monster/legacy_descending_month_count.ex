defmodule PastafariCalendarElixirVietnamese.Monster.LegacyDescendingMonthCount do
  @moduledoc """
  Di sản DISCOVERY24 đảo thứ tự các ứng viên số tháng.
  Tập tháng và hạng từ bát 3 chốt 30 vẫn đúng; chỉ sai
  thứ tự chọn, từ lớn đến nhỏ thay vì từ nhỏ đến lớn.
  PATCH24 phải giữ và gọi thật di sản này.
  """
  def sort(candidates) when is_list(candidates), do: Enum.sort(candidates, :desc)

  def sort(_),
    do: raise(ArgumentError, "danh sách số tháng không hợp lệ")
end
