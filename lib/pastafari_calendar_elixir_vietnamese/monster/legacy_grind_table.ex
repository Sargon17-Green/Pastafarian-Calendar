defmodule PastafariCalendarElixirVietnamese.Monster.LegacyGrindTable do
  @moduledoc """
  Bản vá 07: giữ phép đọc lịch sử từ chỉ số 1 đến 11.

  Bảng giờ có hàng canh bất biến tại index 0 và đủ 11 hàng
  nghiền thật ở index 1..11. Không bỏ qua hàng canh và không
  sửa phép đọc Enum.at đã có từ lần phát hiện 07.
  """

  @sentinel_row {0, 0, 0, 0, 1}

  @real_rows [
    @sentinel_row,
    {3, 5, 7, 11, 1},
    {5, 7, 11, 13, 2},
    {7, 11, 13, 17, 3},
    {11, 13, 17, 19, 4},
    {13, 17, 19, 23, 5},
    {17, 19, 23, 29, 1},
    {19, 23, 29, 31, 2},
    {23, 29, 31, 37, 3},
    {29, 31, 37, 41, 4},
    {31, 37, 41, 43, 5},
    {37, 41, 43, 47, 1}
  ]

  @missing_row {0, 0, 0, 0, 1}

  def legacy_row(number) when is_integer(number) and number in 1..11 do
    Enum.at(@real_rows, number, @missing_row)
  end

  def legacy_row(_number) do
    raise ArgumentError, "chỉ số lần nghiền phải từ 1 đến 11"
  end

  def row_at_zero, do: hd(@real_rows)
  def sentinel_row, do: @sentinel_row
  def all_rows_with_sentinel, do: @real_rows
  def fallback_row, do: @missing_row
end
