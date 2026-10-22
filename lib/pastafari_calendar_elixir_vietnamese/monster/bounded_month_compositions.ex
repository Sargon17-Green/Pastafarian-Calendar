defmodule PastafariCalendarElixirVietnamese.Monster.BoundedMonthCompositions do
  @moduledoc """
  Đếm hợp thành có thứ tự theo giới hạn 4..123 ngày,
  mở hạng tăng từ điển với hạng một-based. Dùng nguyên
  lớn chính xác và phép bù trừ số cách chọn, không duyệt
  mọi phân hoạch hoặc dùng oracle dành cho kiểm thử.
  """

  @lower 4
  @upper 123
  @width @upper - @lower + 1

  def count(total, slots)
      when is_integer(total) and is_integer(slots) and total >= 0 and slots >= 0 do
    cond do
      slots == 0 -> if(total == 0, do: 1, else: 0)
      total < slots * @lower or total > slots * @upper -> 0
      true ->
        surplus = total - slots * @lower
        max_exclusions = min(slots, div(surplus, @width))
        Enum.reduce(0..max_exclusions, 0, fn j, acc ->
          amount =
            choose(slots, j) *
              choose(surplus - @width * j + slots - 1, slots - 1)
          if rem(j, 2) == 0, do: acc + amount, else: acc - amount
        end)
    end
  end

  def count(_, _), do: raise(ArgumentError, "tổng hoặc số tháng không hợp lệ")

  def unrank(total, slots, rank)
      when is_integer(total) and is_integer(slots) and
           is_integer(rank) and total >= 0 and slots >= 1 do
    candidates = count(total, slots)
    if rank < 1 or rank > candidates do
      raise ArgumentError, "hạng hợp thành tháng không hợp lệ"
    end
    open(total, slots, rank, [])
  end

  def unrank(_, _, _), do: raise(ArgumentError, "hạng hoặc cấu trúc tháng không hợp lệ")

  defp open(0, 0, _rank, acc), do: Enum.reverse(acc)

  defp open(total, slots, rank, acc) when slots >= 1 do
    lo = max(@lower, total - @upper * (slots - 1))
    hi = min(@upper, total - @lower * (slots - 1))

    {selected, remaining_rank} =
      Enum.reduce_while(lo..hi, rank, fn x, current_rank ->
        block = count(total - x, slots - 1)
        if current_rank > block do
          {:cont, current_rank - block}
        else
          {:halt, {x, current_rank}}
        end
      end)

    open(total - selected, slots - 1, remaining_rank, [selected | acc])
  end

  defp choose(n, k) when k < 0 or n < 0 or k > n, do: 0
  defp choose(_n, 0), do: 1

  defp choose(n, k) do
    small = min(k, n - k)
    if small == 0 do
      1
    else
      Enum.reduce(1..small, 1, fn i, acc ->
        div(acc * (n - small + i), i)
      end)
    end
  end
end
