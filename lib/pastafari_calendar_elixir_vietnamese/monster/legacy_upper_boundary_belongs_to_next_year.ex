defmodule PastafariCalendarElixirVietnamese.Monster.LegacyUpperBoundaryBelongsToNextYear do
  @moduledoc """
  Phát hiện 19: ngày đúng cổng đóng bị phân vào năm kế tiếp.

  Chuẩn chọn khoảng (cổng mở, cổng đóng] và nếu ngày đích
  bằng cổng đóng thì phải trả năm hiện tại. Nhánh lịch sử
  cố ý xem dấu bằng như thuộc năm mới, nhưng không đi tiếp
  để tránh dao động ở ngày cổng mở của năm sau.
  """

  alias PastafariCalendarElixirVietnamese.Monster.Year

  def route(target_day, %Year{} = year) when is_integer(target_day) do
    cond do
      target_day > year.close_gate_day -> :next
      target_day == year.close_gate_day -> :next_at_upper_boundary
      target_day <= year.open_gate_day -> :previous
      true -> :found
    end
  end

  def route(_, _), do: raise(ArgumentError, "ngày đích hoặc năm không hợp lệ")
end
