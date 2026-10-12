defmodule PastafariCalendarElixirVietnamese.Monster.BowlAliasPatch do
  @moduledoc """
  Bản vá 09: ánh xạ vị trí rót 1..3 tới tên ID bát trong hoán vị.

  Hàm rót lịch sử vẫn gọi trực tiếp Map.fetch!(bowls_old, position).
  Cung cấp một bản xem riêng: khóa vị trí 1..3 trỏ đến giá trị
  của ID ở order[position]. Không thay đổi kho old ban đầu;
  các phép khuấy vẫn đọc đầy đủ sáu tên ID từ snapshot old.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyPourPositions

  def alias_view(bowls_old, order)
      when is_map(bowls_old) and is_list(order) and length(order) == 6 do
    Enum.reduce(1..3, %{}, fn position, bowl_alias ->
      id = Enum.at(order, position - 1)
      Map.put(bowl_alias, position, Map.fetch!(bowls_old, id))
    end)
  end

  def alias_view(_bowls_old, _order) do
    raise ArgumentError, "kho bát và hoán vị rót phải hợp lệ"
  end

  def pour(bowls_old, order, drop, stone, index, position) do
    bowl_alias = alias_view(bowls_old, order)
    LegacyPourPositions.pour(bowl_alias, drop, stone, index, position)
  end
end
