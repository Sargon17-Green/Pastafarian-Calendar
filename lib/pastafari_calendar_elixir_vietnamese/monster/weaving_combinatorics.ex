defmodule PastafariCalendarElixirVietnamese.Monster.WeavingCombinatorics do
  @moduledoc """
  Đếm và mở hạng các cách đan tháng bằng số nguyên chính xác.
  Lần xuất hiện đầu và lần xuất hiện cuối của các tháng đều
  theo thứ tự tăng dần. Các lần xuất hiện giữa được phép xen kẽ.
  Bộ nhớ đệm chỉ tồn tại trong một lần gọi, không lưu toàn cục.
  """

  def count(lengths) do
    original = validate_lengths!(lengths)
    initial = {original, 0, 0}
    {result, _memory} = count_state(initial, original, %{})
    result
  end

  def unrank(lengths, rank), do: unrank(lengths, rank, :ascending)

  def unrank(lengths, rank, direction) when direction in [:ascending, :descending] do
    original = validate_lengths!(lengths)
    first = {original, 0, 0}
    {total, memory} = count_state(first, original, %{})

    unless is_integer(rank) and rank >= 1 and rank <= total do
      raise ArgumentError, "hạng đan tháng nằm ngoài miền hợp lệ"
    end

    labels = Enum.to_list(1..tuple_size(original))
    order = if direction == :ascending, do: labels, else: Enum.reverse(labels)
    unrank_state(first, original, order, rank, memory, Enum.sum(lengths), [])
  end

  def unrank(_lengths, _rank, _direction),
    do: raise(ArgumentError, "thứ tự mở hạng không hợp lệ")

  defp validate_lengths!(lengths) when is_list(lengths) and lengths != [] do
    if length(lengths) <= 47 and Enum.all?(lengths, &(is_integer(&1) and &1 in 4..123)) do
      List.to_tuple(lengths)
    else
      raise ArgumentError, "độ dài tháng phải nằm trong 4..123, tối đa 47 tháng"
    end
  end

  defp validate_lengths!(_),
    do: raise(ArgumentError, "danh sách độ dài tháng không hợp lệ")

  defp done?(remaining),
    do: remaining |> Tuple.to_list() |> Enum.all?(&(&1 == 0))

  defp legal?({remaining, opened, closed}, original, label) do
    left = elem(remaining, label - 1)
    initial = elem(original, label - 1)

    left > 0 and
      (left != initial or label == opened + 1) and
      (left != 1 or label == closed + 1)
  end

  defp advance({remaining, opened, closed}, original, label) do
    left = elem(remaining, label - 1)
    new_opened = if left == elem(original, label - 1), do: label, else: opened
    new_closed = if left == 1, do: label, else: closed
    {put_elem(remaining, label - 1, left - 1), new_opened, new_closed}
  end

  defp count_state({remaining, _, _} = state, original, memory) do
    case Map.fetch(memory, state) do
      {:ok, value} ->
        {value, memory}

      :error ->
        if done?(remaining) do
          {1, Map.put(memory, state, 1)}
        else
          {total, memory2} =
            Enum.reduce(1..tuple_size(original), {0, memory}, fn label, {sum, cache} ->
              if legal?(state, original, label) do
                {n, updated} = count_state(advance(state, original, label), original, cache)
                {sum + n, updated}
              else
                {sum, cache}
              end
            end)

          {total, Map.put(memory2, state, total)}
        end
    end
  end

  defp unrank_state(_state, _original, _order, _rank, _memory, 0, collected),
    do: Enum.reverse(collected)

  defp unrank_state(state, original, order, rank, memory, remaining_days, collected) do
    {chosen, rank2, memory2} =
      Enum.reduce_while(order, {nil, rank, memory}, fn label, {_found, current, cache} ->
        if legal?(state, original, label) do
          next = advance(state, original, label)
          {block, updated} = count_state(next, original, cache)

          if current > block do
            {:cont, {nil, current - block, updated}}
          else
            {:halt, {{label, next}, current, updated}}
          end
        else
          {:cont, {nil, current, cache}}
        end
      end)

    case chosen do
      {label, next} ->
        unrank_state(next, original, order, rank2, memory2, remaining_days - 1, [label | collected])

      nil ->
        raise ArgumentError, "không tìm thấy nhánh đan tháng ở hạng yêu cầu"
    end
  end
end
