defmodule PastafariCalendarElixirVietnamese.Monster.DistinctCutletNameIndices do
  @moduledoc """
  Đếm và mở hạng một-based của dãy chỉ số tên khác nhau
  từ tập 1..17, theo thứ tự từ điển. Không bao giờ sinh
  hoán vị trong bộ nhớ: lấy trực tiếp khối hạng còn lại.
  """

  def count(n, k)
      when is_integer(n) and is_integer(k) and n >= 0 and k >= 0 and k <= n do
    if k == 0 do
      1
    else
      Enum.reduce(0..(k - 1), 1, fn j, product -> product * (n - j) end)
    end
  end

  def count(_, _), do: raise(ArgumentError, "số tên hoặc độ dài dãy không hợp lệ")

  def unrank(n, k, rank) do
    total = count(n, k)
    if not is_integer(rank) or rank < 1 or rank > total do
      raise ArgumentError, "hạng chọn tên không hợp lệ"
    end
    if k == 0 do
      []
    else
      do_unrank(Enum.to_list(1..n), k, rank, [])
    end
  end

  defp do_unrank(_remaining, 0, _rank, acc), do: Enum.reverse(acc)

  defp do_unrank(remaining, slots, rank, acc) do
    block = count(length(remaining) - 1, slots - 1)
    chosen_pos = div(rank - 1, block)
    next_rank = rem(rank - 1, block) + 1
    chosen = Enum.at(remaining, chosen_pos)
    rest = List.delete_at(remaining, chosen_pos)
    do_unrank(rest, slots - 1, next_rank, [chosen | acc])
  end
end
