defmodule PastafariCalendarElixirVietnamese.Monster.BowlDropCalculator do
  @moduledoc """
  Phát hiện 10 đưa lỗi ghi đè tuần tự vào khuấy sáu bát.

  BowlAliasPatch tiếp tục vá đúng ba nguồn rót và gọi legacy.
  LegacyInPlaceStir tính rồi thay ngay bát của từng vị trí,
  khiến những vị trí sau đọc giá trị đã bị cập nhật; chưa
  dùng vaultOld hay pending của bản vá 10.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlAliasPatch,
    LegacyInPlaceStir
  }

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
        BowlAliasPatch.pour(
          old, order, drop, elem(row, position - 1), index, position
        )

      {position, value}
    end)

    LegacyInPlaceStir.run(old, pours, drop, row, order, index)
  end

  def step(_old, _drop, _order, _stones, _index) do
    raise ArgumentError, "đầu vào khuấy bát không hợp lệ"
  end

end
