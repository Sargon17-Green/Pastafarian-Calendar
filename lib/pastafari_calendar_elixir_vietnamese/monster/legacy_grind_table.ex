defmodule PastafariCalendarElixirVietnamese.Monster.LegacyGrindTable do
  @moduledoc """
  Phát hiện 07: bảng nghiền lưu từ chỉ số 0 nhưng bộ đọc cũ dùng 1..11.

  Vì thế bước thứ nhất bị bỏ qua, bước cuối đọc ô dự phòng.
  Ở giai đoạn vá tiếp theo, phải thêm hàng canh tại index 0,
  giữ nguyên hàm đọc lịch sử và giữ đủ 11 hàng nghiền thật.
  """

  @real_rows [
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
  def fallback_row, do: @missing_row
end
