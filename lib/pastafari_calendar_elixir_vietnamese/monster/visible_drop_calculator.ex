defmodule PastafariCalendarElixirVietnamese.Monster.VisibleDropCalculator do
  @moduledoc """
  Sinh 46 giọt nhìn thấy với đường đọc quá khứ đã vá đúng.

  Bản vá 07 đặt sentinel ở index 0 của LegacyGrindTable,
  nên cách đọc legacy từ index 1..11 vẫn dùng đủ 11 hàng
  nghiền thật. Giữ nguyên bản vá 06, giọt ẩn và SAVE.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{LegacyGrindTable, PriorPatch, SaveManager}


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
        Enum.reduce(1..11, seed, fn grind_number, old_value ->
          {a, b, c, d, kind} = LegacyGrindTable.legacy_row(grind_number)
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
