defmodule PastafariCalendarElixirVietnamese.Monster.Cutlet do
  @moduledoc """
  Một cốt-lết vật chất hóa: chỉ số tên, hai cổng và hai ngày
  biên. Khoảng ngày chuẩn thuộc (cổng mở, cổng đóng].
  """
  defstruct [:name_index, :open_gate_index, :close_gate_index, :first_day, :last_day]
end
