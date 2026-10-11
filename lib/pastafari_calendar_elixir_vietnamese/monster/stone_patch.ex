defmodule PastafariCalendarElixirVietnamese.Monster.StonePatch do
  @moduledoc """
  Bản vá 04: lưu ảnh chụp của hàng cũ trước khi tính năm viên đá.

  Gọi hàm nối tiếp sai trên bản sao thật để nhận kết quả trung gian.
  Sau đó ghi đè đủ năm ô bằng công thức chỉ đọc ảnh chụp ban đầu.
  Không được bỏ lời gọi lịch sử hoặc thay các công thức trước đó.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{LegacyStoneMutation, SaveManager}

  def patch_row(previous_row, index)
      when is_tuple(previous_row) and tuple_size(previous_row) == 5 and
             is_integer(index) and index in 2..46 do
    old_snapshot = previous_row |> Tuple.to_list() |> List.to_tuple()
    legacy_clone = old_snapshot |> Tuple.to_list() |> List.to_tuple()
    garbage = LegacyStoneMutation.mutate_stones_wrong(legacy_clone, index)

    {w, b, s, m, r} = old_snapshot

    garbage
    |> put_elem(0, SaveManager.calculate(w * w + 3 * b + index))
    |> put_elem(1, SaveManager.calculate(b * b + 5 * s + w))
    |> put_elem(2, SaveManager.calculate(s * s + 7 * m + b))
    |> put_elem(3, SaveManager.calculate(m * m + 11 * r + s))
    |> put_elem(4, SaveManager.calculate(r * r + 13 * w + m))
  end

  def patch_row(_previous_row, _index) do
    raise ArgumentError, "hàng đá phải có năm giá trị và chỉ số từ 2 đến 46"
  end
end
