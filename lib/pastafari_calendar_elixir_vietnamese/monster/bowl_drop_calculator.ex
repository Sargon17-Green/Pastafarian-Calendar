defmodule PastafariCalendarElixirVietnamese.Monster.BowlDropCalculator do
  @moduledoc """
  Cập nhật sáu bát qua 46 giọt với lỗi rót theo tên vị trí cũ.

  Chỉ phần đọc ba nguồn rót dùng LegacyPourPositions sai.
  Các phép khuấy của sáu vị trí đều đọc từ snapshot old
  và ghi vào map next riêng; không thêm lỗi in-place của
  DISCOVERY 10 hoặc phần khuấy sau giọt 46.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyPourPositions,
    SaveManager
  }

  @stir_stones [1, 2, 3, 4, 5, 1]

  def apply_all(initial_bowls, visible, orders, stones)
      when is_map(initial_bowls) and is_map(visible) and
           is_map(orders) and is_map(stones) do
    Enum.reduce(1..46, initial_bowls, fn index, old ->
      step(old, Map.fetch!(visible, index), Map.fetch!(orders, index), stones, index)
    end)
  end

  def step(old, drop, order, stones, index)
      when is_map(old) and is_integer(drop) and is_list(order) and
             length(order) == 6 and is_map(stones) and
             is_integer(index) and index in 1..46 do
    row = Map.fetch!(stones, index)

    pours = Map.new(1..3, fn position ->
      value =
        LegacyPourPositions.pour(
          old, drop, elem(row, position - 1), index, position
        )

      {position, value}
    end)

    Enum.reduce(1..6, %{}, fn position, next ->
      id = Enum.at(order, position - 1)
      prev_id = Enum.at(order, wrap1(position - 1) - 1)
      next_id = Enum.at(order, wrap1(position + 1) - 1)
      stone_kind = Enum.at(@stir_stones, position - 1)

      mix =
        Map.fetch!(old, id) +
          2 * Map.fetch!(old, prev_id) +
          3 * Map.fetch!(old, next_id) +
          Map.get(pours, position, 0) +
          drop +
          elem(row, stone_kind - 1)

      updated =
        SaveManager.calculate(
          mix * mix +
            5 * Map.fetch!(old, prev_id) * Map.fetch!(old, next_id) +
            index * position
        )

      Map.put(next, id, updated)
    end)
  end

  def step(_old, _drop, _order, _stones, _index) do
    raise ArgumentError, "đầu vào khuấy bát không hợp lệ"
  end

  defp wrap1(position), do: rem(position + 11, 6) + 1
end
