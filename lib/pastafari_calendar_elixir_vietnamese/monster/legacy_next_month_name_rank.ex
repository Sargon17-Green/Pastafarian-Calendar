defmodule PastafariCalendarElixirVietnamese.Monster.LegacyNextMonthNameRank do
  @moduledoc """
  Di sản lỗi DISCOVERY27: dịch hạng tên tháng một bước
  về phía trước trong không gian hữu hạn có một-based.
  PATCH27 phải gọi chính hàm này rồi sửa lại hạng.
  """

  def transform(rank, total)
      when is_integer(rank) and is_integer(total) and total >= 1 and
             rank >= 1 and rank <= total do
    rem(rank, total) + 1
  end

  def transform(_, _), do: raise(ArgumentError, "hạng lịch sử không hợp lệ")
end
