defmodule PastafariCalendarElixirVietnamese.Monster.SavePatch do
  @moduledoc """
  Lớp vá 01 đặt trên phép dư lịch sử mà không sửa hoặc xóa phép tính cũ.

  Phép dư theo M cho kết quả trong miền 0..M−1. Riêng trường hợp
  bằng không phải được chuyển thành M để phép SAVE nằm trong miền 1..M.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyRemainder

  def save_patch(value) when is_integer(value) do
    remainder = LegacyRemainder.old_remainder(value)

    if remainder == 0 do
      LegacyRemainder.modulus()
    else
      remainder
    end
  end
end
