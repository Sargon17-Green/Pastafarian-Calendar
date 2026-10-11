defmodule PastafariCalendarElixirVietnamese.Monster.LegacyStoneMutation do
  @moduledoc """
  Cách cập nhật năm loại đá theo thứ tự bị sai từ giai đoạn phát hiện 04.

  Sau khi cập nhật một ô, các công thức tiếp theo đọc lại ô vừa
  cập nhật thay vì giữ tất cả giá trị từ hàng trước. Elixir dùng
  tuple bất biến, vì vậy lỗi ghi tại chỗ được biểu diễn bằng chuỗi
  put_elem liên tiếp và đọc giá trị mới từ tuple trung gian.
  """

  alias PastafariCalendarElixirVietnamese.Monster.SaveManager

  def mutate_stones_wrong(row, index)
      when is_tuple(row) and tuple_size(row) == 5 and is_integer(index) and index >= 2 do
    {w, b, s, m, r} = row

    updated_w = put_elem(row, 0, SaveManager.calculate(w * w + 3 * b + index))
    updated_b =
      put_elem(updated_w, 1, SaveManager.calculate(b * b + 5 * s + elem(updated_w, 0)))

    updated_s =
      put_elem(updated_b, 2, SaveManager.calculate(s * s + 7 * m + elem(updated_b, 1)))

    updated_m =
      put_elem(updated_s, 3, SaveManager.calculate(m * m + 11 * r + elem(updated_s, 2)))

    put_elem(
      updated_m,
      4,
      SaveManager.calculate(r * r + 13 * elem(updated_m, 0) + elem(updated_m, 3))
    )
  end
end
