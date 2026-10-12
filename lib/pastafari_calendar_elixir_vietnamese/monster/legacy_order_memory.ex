defmodule PastafariCalendarElixirVietnamese.Monster.LegacyOrderMemory do
  @moduledoc """
  Phát hiện 11: cùng một ô thứ tự được ghi lại 58 lần.

  Sau 46 giọt, 12 lần khuấy cuối vẫn đè cùng ô này.
  Truy vấn bát tiếp theo đọc thứ tự cuối, không đọc thứ tự
  giọt thứ 46 đã bị mất. Bản vá 11 phải giữ hàm lịch sử
  nhưng chốt riêng thứ tự ở giọt thứ 46.
  """

  def new do
    %{order: nil, writes: 0, last_source: nil}
  end

  def write(memory, order, source)
      when is_map(memory) and is_list(order) and length(order) == 6 do
    %{memory | order: order, writes: memory.writes + 1, last_source: source}
  end

  def next_bowl(memory, queried_id)
      when is_map(memory) and is_integer(queried_id) and
             queried_id in 1..6 do
    order = Map.fetch!(memory, :order)
    position = Enum.find_index(order, &(&1 == queried_id))

    if is_nil(position) do
      raise ArgumentError, "mã bát không hợp lệ"
    end

    Enum.at(order, rem(position + 1, 6))
  end

  def next_bowl(_memory, _queried_id) do
    raise ArgumentError, "mã bát không hợp lệ"
  end
end
