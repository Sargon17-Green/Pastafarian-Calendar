defmodule PastafariCalendarElixirVietnamese.Monster.PostStirCalculator do
  @moduledoc """
  Mười hai lần khuấy sau giọt 46 giữ nguyên công thức chuẩn.

  Mỗi vòng đọc toàn bộ sáu ID từ old bất biến, tính tổng
  SAVE có hệ số 149 và tạo hoán vị đúng cho vòng hiện tại.
  Cả 12 hoán vị đều ghi đè LegacyOrderMemory thay vì chốt
  hoán vị giọt 46; đó là lỗi duy nhất ở lần phát hiện 11.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlOrderManager,
    LegacyOrderMemory,
    SaveManager
  }

  def apply_all(bowls_after_drops, order_memory)
      when is_map(bowls_after_drops) and is_map(order_memory) do
    Enum.reduce(1..12, {bowls_after_drops, order_memory}, fn stir, {old, memory} ->
      {next, order} = step(old, stir)
      {next, LegacyOrderMemory.write(memory, order, {:stir, stir})}
    end)
  end

  def step(old, stir)
      when is_map(old) and is_integer(stir) and stir in 1..12 do
    saved_bowl_sum = SaveManager.calculate(Enum.sum(Map.values(old)) + 149 * stir)
    order = BowlOrderManager.order_from_drop(saved_bowl_sum)

    next =
      Enum.reduce(1..6, %{}, fn position, pending ->
        id = Enum.at(order, position - 1)
        prev_id = Enum.at(order, wrap1(position - 1) - 1)
        next_id = Enum.at(order, wrap1(position + 1) - 1)

        mix =
          Map.fetch!(old, id) +
            3 * Map.fetch!(old, prev_id) +
            5 * Map.fetch!(old, next_id) +
            saved_bowl_sum + stir + position * position

        value =
          SaveManager.calculate(
            mix * mix + 7 * Map.fetch!(old, prev_id) * Map.fetch!(old, next_id)
          )

        Map.put(pending, id, value)
      end)

    {next, order}
  end

  def step(_old, _stir) do
    raise ArgumentError, "lượt khuấy cuối phải từ 1 đến 12"
  end

  defp wrap1(position), do: rem(position + 11, 6) + 1
end
