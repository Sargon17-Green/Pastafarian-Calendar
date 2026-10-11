defmodule PastafariCalendarElixirVietnamese.Monster.StoneManager do
  @moduledoc """
  Quản lý bảng đá 46 hàng trong đường sản xuất thật.

  Giai đoạn 8 cố ý giữ công thức nối tiếp bị nhiễm kết quả vừa ghi.
  Bản vá dùng bản chụp hàng cũ chỉ được thêm trong giai đoạn 9.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyStoneMutation

  @first_row {17, 29, 43, 71, 101}

  def build_table do
    Enum.reduce(2..46, %{1 => @first_row}, fn index, table ->
      previous_row = Map.fetch!(table, index - 1)
      next_row = LegacyStoneMutation.mutate_stones_wrong(previous_row, index)
      Map.put(table, index, next_row)
    end)
  end

  def row_at(index) when is_integer(index) and index in 1..46 do
    build_table() |> Map.fetch!(index)
  end

  def row_at(_index) do
    raise ArgumentError, "chỉ số hàng đá phải từ 1 đến 46"
  end
end
