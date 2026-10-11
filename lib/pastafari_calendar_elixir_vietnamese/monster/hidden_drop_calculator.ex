defmodule PastafariCalendarElixirVietnamese.Monster.HiddenDropCalculator do
  @moduledoc """
  Tính bảy giọt ẩn theo công thức chuẩn nhưng chưa quyết định cách lưu.

  Việc đảo thứ tự thuộc lớp lưu trữ lịch sử bên ngoài; không sử dụng
  bộ tham chiếu kiểm thử trong đường tính sản xuất.
  """

  alias PastafariCalendarElixirVietnamese.Monster.SaveManager

  @coefficients %{
    1 => {3, 4, 6, 8},
    2 => {5, 7, 10, 12},
    3 => {7, 10, 14, 16},
    4 => {9, 13, 18, 20},
    5 => {11, 16, 22, 24},
    6 => {13, 19, 26, 28},
    7 => {15, 22, 30, 32}
  }

  @grind_stone [1, 2, 3, 4, 5, 1, 2]

  def calculate(calculation_day, target_day, action_tag, target_tag, distance, stones) do
    connection = action_tag + target_tag

    direction =
      cond do
        target_day < calculation_day -> 1
        target_day == calculation_day -> 2
        true -> 3
      end

    Enum.reduce(1..7, %{}, fn hidden_number, acc ->
      {a, b, c, d} = Map.fetch!(@coefficients, hidden_number)
      stone_row = Map.fetch!(stones, hidden_number)

      stone_sum =
        stone_row
        |> Tuple.to_list()
        |> Enum.sum()

      seed =
        SaveManager.calculate(
          action_tag +
            a * target_tag +
            b * distance +
            c * connection +
            d * direction +
            stone_sum
        )

      value =
        @grind_stone
        |> Enum.with_index(1)
        |> Enum.reduce(seed, fn {stone_kind, grind_number}, previous ->
          stone_value = elem(stone_row, stone_kind - 1)

          SaveManager.calculate(
            previous * previous + 3 * previous + stone_value + grind_number
          )
        end)

      Map.put(acc, hidden_number, value)
    end)
  end
end
