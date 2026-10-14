defmodule PastafariCalendarElixirVietnamese.Monster.Year do
  @moduledoc """
  Một năm lịch với hai cổng biên. Năm neo được đánh số 5000.
  Các chỉ số cổng giữ nguyên số nguyên có dấu và ngày tuyệt đối.
  """
  defstruct [:number, :open_gate_index, :close_gate_index,
             :open_gate_day, :close_gate_day]
end
