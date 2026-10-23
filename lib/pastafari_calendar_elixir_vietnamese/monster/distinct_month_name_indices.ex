defmodule PastafariCalendarElixirVietnamese.Monster.DistinctMonthNameIndices do
  @moduledoc """
  Đếm và mở hạng dãy k tên tháng khác nhau lấy từ 47 tên.
  Dùng hạng một-based theo thứ tự từ điển tăng, không tạo
  toàn bộ không gian các hoán vị trong bộ nhớ.
  """

  def count(k) when is_integer(k) and k >= 1 and k <= 47 do
    Enum.reduce(0..(k - 1), 1, fn index, product -> product * (47 - index) end)
  end

  def count(_), do: raise(ArgumentError, "số tháng phải thuộc 1..47")

  def unrank(k, rank) do
    total = count(k)

    if not is_integer(rank) or rank < 1 or rank > total do
      raise ArgumentError, "hạng tên tháng nằm ngoài miền"
    end

    unrank_loop(Enum.to_list(1..47), k, rank, [])
  end

  defp unrank_loop(_available, 0, _rank, result), do: Enum.reverse(result)

  defp unrank_loop(available, slots, rank, result) do
    block =
      if slots == 1 do
        1
      else
        Enum.reduce(0..(slots - 2), 1, fn i, acc ->
          acc * (length(available) - 1 - i)
        end)
      end

    offset = div(rank - 1, block)
    chosen = Enum.at(available, offset)
    next_rank = rem(rank - 1, block) + 1
    unrank_loop(List.delete_at(available, offset), slots - 1, next_rank, [chosen | result])
  end
end
