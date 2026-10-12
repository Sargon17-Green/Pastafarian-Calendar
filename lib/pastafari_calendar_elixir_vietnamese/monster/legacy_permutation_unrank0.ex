defmodule PastafariCalendarElixirVietnamese.Monster.LegacyPermutationUnrank0 do
  @moduledoc """
  Bộ mở hạng hoán vị lịch sử dùng hạng bắt đầu từ 0.

  Thuật toán chọn sáu tên bát bằng khai triển giai thừa. Hạng
  720 được quay về 0 theo chu kỳ để không đọc ra ngoài miền,
  nhưng giao diện cũ vẫn mang ý nghĩa hạng bắt đầu từ 0.
  Bản vá 08 phải giữ và thật sự gọi lại hàm này.
  """

  @bowl_ids [1, 2, 3, 4, 5, 6]
  @permutations 720

  def old_permutation_unrank0(rank0)
      when is_integer(rank0) and rank0 >= 0 do
    cyclic_rank0 = rem(rank0, @permutations)
    take_by_factorial(cyclic_rank0, @bowl_ids, [])
  end

  def old_permutation_unrank0(_rank0) do
    raise ArgumentError, "hạng hoán vị gốc không phải số nguyên không âm"
  end

  defp take_by_factorial(_rank0, [], chosen), do: Enum.reverse(chosen)

  defp take_by_factorial(rank0, remaining, chosen) do
    block = factorial(length(remaining) - 1)
    position0 = div(rank0, block)
    next_rank0 = rem(rank0, block)
    selected = Enum.at(remaining, position0)
    rest = List.delete_at(remaining, position0)
    take_by_factorial(next_rank0, rest, [selected | chosen])
  end

  defp factorial(0), do: 1
  defp factorial(n), do: Enum.reduce(1..n, 1, &*/2)
end
