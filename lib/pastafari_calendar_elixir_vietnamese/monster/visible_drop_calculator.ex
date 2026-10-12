defmodule PastafariCalendarElixirVietnamese.Monster.VisibleDropCalculator do
  @moduledoc """
  Sinh 46 giọt nhìn thấy với bản vá 06 định tuyến ba lần đọc lịch sử.

  Với địa chỉ dương, dùng LegacyPrior thực trên kho nhìn thấy.
  Với ô âm hoặc ô không, bản vá gọi HiddenDropManager để lấy
  giọt ẩn đã tính trong bootstrap. Các kho luôn tách biệt.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{PriorPatch, SaveManager}

  @grinds [
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

  def calculate(calculation_day, target_day, action_tag, target_tag, distance, stones, hidden_storage)
      when is_integer(calculation_day) and is_integer(target_day) do
    connection = action_tag + target_tag

    direction =
      cond do
        target_day < calculation_day -> 1
        target_day == calculation_day -> 2
        true -> 3
      end

    Enum.reduce(1..46, %{}, fn index, visible_store ->
      previous_1 = PriorPatch.read(visible_store, hidden_storage, index, 1)
      previous_3 = PriorPatch.read(visible_store, hidden_storage, index, 3)
      previous_7 = PriorPatch.read(visible_store, hidden_storage, index, 7)
      stone_row = Map.fetch!(stones, index)

      {w, b, s, m, r} = stone_row

      seed =
        SaveManager.calculate(
          w * action_tag +
            b * target_tag +
            s * distance +
            m * connection +
            r * direction +
            previous_1 + 3 * previous_3 + 5 * previous_7 + index
        )

      result =
        Enum.reduce(@grinds, seed, fn {a, b, c, d, kind}, old_value ->
          SaveManager.calculate(
            old_value * old_value +
              a * old_value +
              b * previous_1 +
              c * previous_3 +
              d * previous_7 +
              elem(stone_row, kind - 1)
          )
        end)

      Map.put(visible_store, index, result)
    end)
  end
end
