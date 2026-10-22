defmodule PastafariCalendarElixirVietnamese.Monster.LegacyMirroredMonthLengthsRank do
  @moduledoc """
  Di sản sai DISCOVERY25: hạng đúng của phép hợp thành
  độ dài tháng bị phản chiếu trên không gian 1..N.
  Luồng đáp án bát 3 chốt 31 không đổi. PATCH25 phải
  gọi thật chức năng lịch sử này trước khi sửa hạng.
  """

  def transform(rank, count)
      when is_integer(rank) and is_integer(count) and
           count >= 1 and rank >= 1 and rank <= count,
      do: count - rank + 1

  def transform(_, _),
    do: raise(ArgumentError, "hạng và số ứng viên không hợp lệ")
end
