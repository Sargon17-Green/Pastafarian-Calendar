defmodule PastafariCalendarElixirVietnamese.Monster.BowlOrderManager do
  @moduledoc """
  Bản vá 08 chuyển đúng hạng từ 1..720 về hạng bắt đầu từ 0.

  Bộ mở hạng lịch sử vẫn hoạt động và giữ nguyên; chỉ thêm
  phép chuyển hạng một-based thành zero-based trước khi gọi.
  Các thứ tự vẫn được lưu vào ngữ cảnh, chưa rót vào bát.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyPermutationUnrank0

  def order_from_drop(drop) when is_integer(drop) and drop >= 1 do
    one_based = rem(drop - 1, 720) + 1
    legacy_rank0 = one_based - 1
    LegacyPermutationUnrank0.old_permutation_unrank0(legacy_rank0)
  end

  def order_from_drop(_drop) do
    raise ArgumentError, "giọt dùng xếp thứ tự phải là số nguyên dương"
  end

  def build_orders(visible) when is_map(visible) and map_size(visible) == 46 do
    Map.new(1..46, fn index ->
      drop = Map.fetch!(visible, index)
      {index, order_from_drop(drop)}
    end)
  end

  def build_orders(_visible) do
    raise ArgumentError, "kho giọt nhìn thấy phải có đúng 46 phần tử"
  end

  def read_order(orders, index)
      when is_map(orders) and is_integer(index) and index in 1..46 do
    Map.fetch!(orders, index)
  end

  def read_order(_orders, _index) do
    raise ArgumentError, "chỉ số thứ tự bát phải từ 1 đến 46"
  end
end
