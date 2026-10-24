defmodule PastafariCalendarElixirVietnamese.Monster.WeavingCombinatorics do
  @moduledoc """
  Đếm và mở hạng đan tháng bằng số nguyên chính xác.
  Thứ tự xuất hiện đầu và thứ tự xuất hiện cuối đều tăng.
  Thay quy hoạch động trên véc-tơ ngày bằng bảng các tháng
  chưa mở cùng công thức đếm phần đã mở. Bộ nhớ chỉ trong
  từng lần gọi, không dùng bộ đệm ngữ nghĩa toàn cục.
  """

  def count(lengths) do
    lengths = validate_lengths!(lengths)
    table = tail_table(lengths)
    elem(Map.fetch!(table, 1), 0)
  end

  def unrank(lengths, rank), do: unrank(lengths, rank, :ascending)

  def unrank(lengths, rank, strategy) do
    lengths = validate_lengths!(lengths)
    month_count = length(lengths)
    standard_order = Enum.to_list(1..month_count)

    order =
      case strategy do
        :ascending -> standard_order
        :descending -> Enum.reverse(standard_order)
        supplied when is_list(supplied) ->
          if Enum.sort(supplied) == standard_order do
            supplied
          else
            raise ArgumentError, "thứ tự nhãn không phải hoán vị đầy đủ"
          end
        _ -> raise ArgumentError, "thứ tự mở hạng không hợp lệ"
      end

    run_unrank(lengths, rank, [order]) |> hd()
  end

  # Tính bảng đuôi một lần cho các thứ tự nhãn khác nhau
  # cùng chọn từ một hạng; giữ nguyên từng chứng cứ di sản.
  def unrank_in_orders(lengths, rank, orders) when is_list(orders) and orders != [] do
    lengths = validate_lengths!(lengths)
    month_count = length(lengths)
    labels = Enum.to_list(1..month_count)

    unless Enum.all?(orders, fn order ->
      is_list(order) and Enum.sort(order) == labels
    end) do
      raise ArgumentError, "thứ tự nhãn không phải hoán vị đầy đủ"
    end

    run_unrank(lengths, rank, orders)
  end

  def unrank_in_orders(_, _, _),
    do: raise(ArgumentError, "danh sách thứ tự nhãn không hợp lệ")

  defp run_unrank(lengths, rank, orders) do
    table = tail_table(lengths)
    total = elem(Map.fetch!(table, 1), 0)

    unless is_integer(rank) and rank >= 1 and rank <= total do
      raise ArgumentError, "hạng đan tháng nằm ngoài miền hợp lệ"
    end

    original = List.to_tuple(lengths)
    days = Enum.sum(lengths)

    Enum.map(orders, fn order ->
      unrank_loop(original, original, 0, 0, 1, rank, order, table, days, [])
    end)
  end

  defp validate_lengths!(lengths) when is_list(lengths) and lengths != [] do
    if length(lengths) <= 47 and Enum.all?(lengths, &(is_integer(&1) and &1 in 4..123)) do
      lengths
    else
      raise ArgumentError, "độ dài tháng phải nằm trong 4..123, tối đa 47 tháng"
    end
  end

  defp validate_lengths!(_),
    do: raise(ArgumentError, "danh sách độ dài tháng không hợp lệ")

  defp binomial(_n, 0), do: 1

  defp binomial(n, k) when is_integer(n) and is_integer(k) and 0 < k and k <= n do
    small = min(k, n - k)
    if small == 0 do
      1
    else
      Enum.reduce(1..small, 1, fn i, acc ->
        div(acc * (n - small + i), i)
      end)
    end
  end

  defp tail_table(lengths) do
    month_count = length(lengths)
    total_days = Enum.sum(lengths)
    prefixes = [0 | Enum.scan(lengths, 0, fn days, sum -> sum + days end)]
    initial = %{month_count + 1 => List.to_tuple(List.duplicate(1, total_days + 1))}

    Enum.reduce(month_count..1//-1, initial, fn month, table ->
      days = Enum.at(lengths, month - 1)
      maximum_suffix = Enum.at(prefixes, month - 1)
      next_table = Map.fetch!(table, month + 1)

      {_sum, reversed, _next_coefficient} =
        Enum.reduce(0..maximum_suffix, {0, [], 1}, fn suffix, {sum, values, coefficient} ->
          value = sum + coefficient * elem(next_table, suffix + days - 1)
          # C(s+days-1,days-2) / C(s+days-2,days-2)
          # = (s+days-1)/(s+1), chỉ chia sau khi nhân.
          following = div(coefficient * (suffix + days - 1), suffix + 1)
          {value, [value | values], following}
        end)

      Map.put(table, month, reversed |> Enum.reverse() |> List.to_tuple())
    end)
  end

  # Tỉ số số cách khi một ngày ở tháng đang mở được lấy.
  # Duyệt hậu tố một lần thay vì đọc vị trí danh sách nhiều lần.
  defp suffix_ratios(active) do
    count = length(active)

    if count <= 1 do
      %{2 => {1, 1}}
    else
      prefixes = Enum.scan(active, 0, fn days, sum -> sum + days end)

      {result, _fraction} =
        prefixes
        |> Enum.with_index(1)
        |> Enum.reverse()
        |> Enum.reduce({%{count + 1 => {1, 1}}, {1, 1}}, fn
          {_prefix, 1}, acc -> acc
          {prefix, index}, {ratios, {numerator, denominator}} ->
            current = {numerator * prefix, denominator * (prefix - 1)}
            {Map.put(ratios, index, current), current}
        end)

      result
    end
  end

  # Bỏ tháng vừa đóng, với số ngày còn lại bằng một.
  # Mỗi thừa số so với cách đếm cũ có dạng
  # tổng tiền tố trước / (tổng tiền tố sau - 1).
  defp close_base(base, [_one]), do: base

  defp close_base(base, [1 | later]) do
    {numerator, denominator, _prefix} =
      Enum.reduce(later, {1, 1, 1}, fn days, {num, den, prefix} ->
        {num * prefix, den * (prefix + days - 1), prefix + days}
      end)

    div(base * numerator, denominator)
  end

  defp unrank_loop(_remaining, _original, _opened, _closed,
       _base, _rank, _order, _table, 0, collected), do: Enum.reverse(collected)

  defp unrank_loop(remaining, original, opened, closed, base, rank,
       order, table, days_left, collected) do
    active =
      if opened > closed do
        Enum.map((closed + 1)..opened, fn label -> elem(remaining, label - 1) end)
      else
        []
      end

    available_days = Enum.sum(active)
    ratios = suffix_ratios(active)

    selection =
      Enum.reduce_while(order, rank, fn label, current_rank ->
        left = elem(remaining, label - 1)
        initial = elem(original, label - 1)

        legal =
          left > 0 and
          (left != initial or label == opened + 1) and
          (left != 1 or label == closed + 1)

        if legal do
          {new_base, new_opened, new_closed, new_days} =
            cond do
              left == initial ->
                updated_base = base * binomial(available_days + left - 2, left - 2)
                {updated_base, label, closed, available_days + left - 1}

              left == 1 ->
                {close_base(base, active), opened, label, available_days - 1}

              true ->
                local_index = label - closed
                {numerator, denominator} = Map.fetch!(ratios, max(2, local_index))
                factor = if local_index == 1, do: left, else: left - 1
                updated_base = div(base * factor * numerator, available_days * denominator)
                {updated_base, opened, closed, available_days - 1}
            end

          suffix_table = Map.fetch!(table, new_opened + 1)
          completions = new_base * elem(suffix_table, new_days)

          if current_rank > completions do
            {:cont, current_rank - completions}
          else
            {:halt, {:chosen, label, current_rank, new_opened, new_closed, new_base}}
          end
        else
          {:cont, current_rank}
        end
      end)

    case selection do
      {:chosen, label, next_rank, new_opened, new_closed, next_base} ->
        new_remaining = put_elem(remaining, label - 1, elem(remaining, label - 1) - 1)
        unrank_loop(new_remaining, original, new_opened, new_closed,
          next_base, next_rank, order, table, days_left - 1, [label | collected])
      _ ->
        raise ArgumentError, "không tìm thấy nhánh đan tháng ở hạng yêu cầu"
    end
  end
end
