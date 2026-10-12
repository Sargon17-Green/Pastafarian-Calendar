defmodule PastafariCalendarElixirVietnamese.Monster.BowlVaultPatch do
  @moduledoc """
  Bản vá 10: giữ sáu giá trị cũ trong vaultOld cho cả một lần khuấy.

  Giữ nguyên LegacyInPlaceStir cùng lỗi truyền map current đã sửa
  của hàm run lịch sử. Thay vì gọi run ấy, bản vá vẫn gọi thật
  LegacyInPlaceStir.compute_one cho từng vị trí với cùng nguồn
  vault_old, gom sáu giá trị vào pending riêng, rồi mới áp dụng
  đồng loạt sau khi cả sáu phép tính hoàn tất.

  Không sửa kho old đầu vào, không dùng trạng thái toàn cục và
  không thay công thức khuấy hoặc thứ tự ID bát.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyInPlaceStir

  def run(old, pours, drop, row, order, index)
      when is_map(old) and is_map(pours) and is_integer(drop) and
             is_tuple(row) and is_list(order) and length(order) == 6 and
             is_integer(index) and index in 1..46 do
    vault_old = old

    pending =
      Enum.reduce(1..6, %{}, fn position, pending ->
        {id, updated} =
          LegacyInPlaceStir.compute_one(
            vault_old, pours, drop, row, order, index, position
          )

        Map.put(pending, id, updated)
      end)

    Map.merge(vault_old, pending)
  end

  def run(_old, _pours, _drop, _row, _order, _index) do
    raise ArgumentError, "đầu vào bản vá kho bát không hợp lệ"
  end
end
