defmodule PastafariCalendarElixirVietnamese.Monster.LegacyBiasedPick do
  @moduledoc """
  Phát hiện 13: phép lấy dư thiên lệch khi chọn hạng.

  Hàm lịch sử nhận một x đã có sẵn và lập tức chọn
  1 + rem(x - 1, n). Nó không biết ngưỡng chia đều
  floor(M/n)*n, không được phép bỏ hay sửa trong PATCH 13.
  Vấn đề nằm ở đường gọi quá sớm trước bước loại bỏ.
  """

  def biased_legacy_pick(x, n)
      when is_integer(x) and x >= 1 and is_integer(n) and n >= 1 do
    rem(x - 1, n) + 1
  end

  def biased_legacy_pick(_x, _n) do
    raise ArgumentError, "giá trị và miền chọn phải dương"
  end
end
