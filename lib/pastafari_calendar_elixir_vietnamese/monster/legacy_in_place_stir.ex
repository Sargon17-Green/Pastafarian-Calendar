defmodule PastafariCalendarElixirVietnamese.Monster.LegacyInPlaceStir do
  @moduledoc """
  Phát hiện 10: ghi mỗi bát ngay khi tính, rồi đọc lại kho vừa đổi.

  `run` làm sáu lần khuấy theo hoán vị, truyền map `current`
  đã cập nhật vào lần tiếp theo. Dù map Elixir bất biến, phép
  truyền giá trị mới tái tạo đúng lỗi nhiễm in-place lịch sử.
  `compute_one` chứa công thức chuẩn cho một vị trí, nhưng
  tham số nguồn là kho đã được chuyển theo thứ tự; bản vá 10
  phải giữ module này và cung cấp nguồn vaultOld cố định.
  """

  alias PastafariCalendarElixirVietnamese.Monster.SaveManager

  @stir_stones [1, 2, 3, 4, 5, 1]

  def run(old, pours, drop, row, order, index)
      when is_map(old) and is_map(pours) and is_integer(drop) and
             is_tuple(row) and is_list(order) and length(order) == 6 and
             is_integer(index) and index in 1..46 do
    Enum.reduce(1..6, old, fn position, current ->
      {id, updated} = compute_one(current, pours, drop, row, order, index, position)
      Map.put(current, id, updated)
    end)
  end

  def run(_old, _pours, _drop, _row, _order, _index) do
    raise ArgumentError, "đầu vào khuấy tại chỗ không hợp lệ"
  end

  def compute_one(source, pours, drop, row, order, index, position)
      when is_map(source) and is_map(pours) and is_integer(drop) and
             is_tuple(row) and is_list(order) and length(order) == 6 and
             is_integer(index) and index in 1..46 and
             is_integer(position) and position in 1..6 do
    id = Enum.at(order, position - 1)
    prev_id = Enum.at(order, wrap1(position - 1) - 1)
    next_id = Enum.at(order, wrap1(position + 1) - 1)
    stone_kind = Enum.at(@stir_stones, position - 1)

    mix =
      Map.fetch!(source, id) +
        2 * Map.fetch!(source, prev_id) +
        3 * Map.fetch!(source, next_id) +
        Map.get(pours, position, 0) +
        drop +
        elem(row, stone_kind - 1)

    updated =
      SaveManager.calculate(
        mix * mix +
          5 * Map.fetch!(source, prev_id) * Map.fetch!(source, next_id) +
          index * position
      )

    {id, updated}
  end

  def compute_one(_source, _pours, _drop, _row, _order, _index, _position) do
    raise ArgumentError, "đầu vào tính một bát không hợp lệ"
  end

  defp wrap1(position), do: rem(position + 11, 6) + 1
end
