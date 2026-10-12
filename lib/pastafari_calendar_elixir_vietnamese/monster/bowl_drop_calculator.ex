defmodule PastafariCalendarElixirVietnamese.Monster.BowlDropCalculator do
  @moduledoc """
  Bản vá 10 ngăn dữ liệu bát mới làm nhiễm sáu lần khuấy.

  BowlAliasPatch tiếp tục xử lý ba nguồn rót và gọi legacy.
  BowlVaultPatch giữ vaultOld bất biến trong cả sáu lần
  LegacyInPlaceStir.compute_one, gom pending, rồi commit
  đồng loạt; lỗi lịch sử trong LegacyInPlaceStir.run còn nguyên.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlAliasPatch,
    BowlVaultPatch
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

    BowlVaultPatch.run(old, pours, drop, row, order, index)
  end

  def step(_old, _drop, _order, _stones, _index) do
    raise ArgumentError, "đầu vào khuấy bát không hợp lệ"
  end

end
