defmodule PastafariCalendarElixirVietnamese.Monster.LegacyLongestFirstYear5000 do
  @moduledoc """
  Phát hiện 16: thứ tự năm neo lịch sử bị đảo.

  Trong danh sách ứng viên năm 5000, chuẩn phải ưu tiên
  độ dài NGẮN trước, sau đó ngày mở. Hàm legacy sai
  cố ý đặt độ dài DÀI trước rồi mới ngày mở.
  Bản vá 16 ở Stage33 phải giữ nguyên hàm lịch sử này.
  """

  def sort(candidates) when is_list(candidates) do
    Enum.sort_by(candidates, fn candidate ->
      {-candidate.length, candidate.open_gate_day}
    end)
  end

  def sort(_), do: raise(ArgumentError, "danh sách năm ứng viên không hợp lệ")
end
