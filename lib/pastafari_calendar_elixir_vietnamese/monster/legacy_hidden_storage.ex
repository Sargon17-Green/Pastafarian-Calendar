defmodule PastafariCalendarElixirVietnamese.Monster.LegacyHiddenStorage do
  @moduledoc """
  Thiết kế lịch sử thứ năm lưu các giọt ẩn theo thứ tự đảo ngược.

  Dãy thực tế là hidden7, hidden6, ..., hidden1. Cách đọc cũ
  tưởng vị trí một ứng với hidden1 nên trả sai khi số giọt không
  nằm giữa. Bản vá ánh xạ 8-k chỉ xuất hiện ở giai đoạn 11.
  """

  def store_reversed(hidden_by_number) when is_map(hidden_by_number) do
    7..1//-1
    |> Enum.map(fn number -> Map.fetch!(hidden_by_number, number) end)
    |> List.to_tuple()
  end

  def read_as_if_forward(storage, number)
      when is_tuple(storage) and tuple_size(storage) == 7 and
             is_integer(number) and number in 1..7 do
    elem(storage, number - 1)
  end

  def read_as_if_forward(_storage, _number) do
    raise ArgumentError, "số giọt ẩn phải từ 1 đến 7"
  end
end
