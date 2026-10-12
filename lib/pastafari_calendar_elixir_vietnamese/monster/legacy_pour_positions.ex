defmodule PastafariCalendarElixirVietnamese.Monster.LegacyPourPositions do
  @moduledoc """
  Phát hiện 09: phép rót cũ đọc tên bát như số vị trí 1, 2, 3.

  Trình tự sáu ID đã được hoán vị nhưng hàm này không tra
  danh tính theo hoán vị. Bản vá 09 sẽ bảo toàn lời gọi này
  và ánh xạ vị trí tới ID thật trước khi đọc.
  """

  alias PastafariCalendarElixirVietnamese.Monster.SaveManager

  def read_old(bowls_old, position)
      when is_map(bowls_old) and is_integer(position) and position in 1..3 do
    Map.fetch!(bowls_old, position)
  end

  def read_old(_bowls_old, _position) do
    raise ArgumentError, "vị trí rót phải thuộc 1..3"
  end

  def pour(bowls_old, drop, stone, index, position)
      when is_integer(drop) and is_integer(stone) and is_integer(index) and
             index in 1..46 and is_integer(position) and position in 1..3 do
    multiplier = 2 * position + 1

    SaveManager.calculate(
      drop * drop + stone * read_old(bowls_old, position) + multiplier * index
    )
  end

  def pour(_bowls_old, _drop, _stone, _index, _position) do
    raise ArgumentError, "đầu vào phép rót lịch sử không hợp lệ"
  end
end
