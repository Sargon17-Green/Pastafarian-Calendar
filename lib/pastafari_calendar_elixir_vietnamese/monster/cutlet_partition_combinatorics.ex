defmodule PastafariCalendarElixirVietnamese.Monster.CutletPartitionCombinatorics do
  @moduledoc """
  Đếm và mở hạng theo thứ tự từ điển các phân hoạch số
  khoảng cổng thành số cốt-lết đã chọn, mỗi phần >=1.
  Nếu ngày tính nằm đúng một cổng bên trong năm, cổng đó
  bắt buộc trùng ranh giới giữa hai cốt-lết. Bộ đếm dùng
  bản đồ ghi nhớ bất biến; không gọi oracle của kiểm thử.
  """

  def count(gaps, slots, required \\ nil) do
    validate!(gaps, slots, required)
    {result, _memo} = count_state(gaps, slots, 0, false, required, %{})
    result
  end

  def unrank(gaps, slots, required, rank) do
    validate!(gaps, slots, required)
    {total, memo} = count_state(gaps, slots, 0, false, required, %{})
    if not is_integer(rank) or rank < 1 or rank > total do
      raise ArgumentError, "hạng của phân hoạch cốt-lết không hợp lệ"
    end
    {partition, _memo} = unrank_loop(gaps, slots, 0, false, required, rank, memo, [])
    partition
  end

  defp validate!(gaps, slots, required) do
    if not (is_integer(gaps) and is_integer(slots) and
      gaps >= 1 and slots >= 1 and slots <= gaps and
      (is_nil(required) or
        (is_integer(required) and required >= 1 and required < gaps))) do
      raise ArgumentError, "số khoảng, số cốt-lết hoặc cổng bắt buộc không hợp lệ"
    end
  end

  defp count_state(remain, slots, cumulative, hit, required, memo) do
    key = {remain, slots, cumulative, hit, required}
    case Map.fetch(memo, key) do
      {:ok, value} -> {value, memo}
      :error ->
        cond do
          slots == 0 ->
            value = if remain == 0 and (is_nil(required) or hit), do: 1, else: 0
            {value, Map.put(memo, key, value)}
          remain < slots ->
            {0, Map.put(memo, key, 0)}
          true ->
            maximum = remain - slots + 1
            {sum, memo2} =
              Enum.reduce(1..maximum, {0, memo}, fn x, {acc, m} ->
                next_cumulative = cumulative + x
                if not is_nil(required) and not hit and next_cumulative > required do
                  {acc, m}
                else
                  next_hit = hit or (not is_nil(required) and next_cumulative == required)
                  {amount, new_m} =
                    count_state(remain - x, slots - 1, next_cumulative,
                      next_hit, required, m)
                  {acc + amount, new_m}
                end
              end)
            {sum, Map.put(memo2, key, sum)}
        end
    end
  end

  defp unrank_loop(_remain, 0, _cumulative, _hit, _required, _rank, memo, acc),
    do: {Enum.reverse(acc), memo}

  defp unrank_loop(remain, slots, cumulative, hit, required, rank, memo, acc) do
    choose_x(1, remain - slots + 1, remain, slots,
      cumulative, hit, required, rank, memo, acc)
  end

  defp choose_x(x, maximum, _remain, _slots, _cumulative, _hit, _required,
      _rank, _memo, _acc) when x > maximum do
    raise ArgumentError, "không tìm được phân hoạch cho hạng đã chọn"
  end

  defp choose_x(x, maximum, remain, slots, cumulative, hit, required,
      rank, memo, acc) do
    next_cumulative = cumulative + x
    if not is_nil(required) and not hit and next_cumulative > required do
      choose_x(x + 1, maximum, remain, slots, cumulative, hit,
        required, rank, memo, acc)
    else
      next_hit = hit or (not is_nil(required) and next_cumulative == required)
      {amount, next_memo} =
        count_state(remain - x, slots - 1, next_cumulative, next_hit, required, memo)
      if rank <= amount do
        unrank_loop(remain - x, slots - 1, next_cumulative, next_hit,
          required, rank, next_memo, [x | acc])
      else
        choose_x(x + 1, maximum, remain, slots, cumulative, hit,
          required, rank - amount, next_memo, acc)
      end
    end
  end
end
