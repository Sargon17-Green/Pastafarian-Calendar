defmodule PastafariCalendarElixirVietnamese.Monster.LegacyRemainder do
  @moduledoc """
  Phần dư lịch sử của lần phát hiện thứ nhất.

  Thiết kế cũ đồng nhất phép SAVE với phần dư thông thường.
  Khi đầu vào chia hết cho M, nó trả 0 thay vì M.
  Sai lệch này được giữ nguyên trong giai đoạn khám phá; không vá trước giai đoạn 3.
  """

  import Bitwise

  @m (1 <<< 127) - 1

  def modulus, do: @m

  def old_remainder(value) when is_integer(value) do
    Integer.mod(value, @m)
  end
end
