defmodule PastafariCalendarElixirVietnamese.Monster.StoneManager do
  @moduledoc """
  Bộ quản lý 46 hàng đá, giữ lịch sử của lần phát hiện thứ tư.

  Mọi hàng sau hàng đầu phải đi qua StonePatch; bản vá này vẫn gọi
  LegacyStoneMutation sai trên bản sao rồi ghi đè năm kết quả.
  """

  alias PastafariCalendarElixirVietnamese.Monster.StonePatch

  @first_row {17, 29, 43, 71, 101}

  def build_table do
    Enum.reduce(2..46, %{1 => @first_row}, fn index, table ->
      previous_row = Map.fetch!(table, index - 1)
      next_row = StonePatch.patch_row(previous_row, index)
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
