defmodule PastafariCalendarElixirVietnamese.Monster.LegacyDescendingWeavingOrder do
  @moduledoc """
  Di sản lỗi của DISCOVERY26: xét nhãn tháng theo thứ tự giảm,
  trong khi chuẩn yêu cầu thứ tự từ điển tăng.
  Giữ nguyên hàm này khi PATCH26 phục hồi thứ tự chuẩn.
  """

  def labels(count) when is_integer(count) and count >= 1 and count <= 47 do
    Enum.reverse(Enum.to_list(1..count))
  end

  def labels(_), do: raise(ArgumentError, "số tháng không hợp lệ")
end
