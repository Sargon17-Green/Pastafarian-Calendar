defmodule PastafariCalendarElixirVietnamese.Monster.TargetYearBoundaryPatch do
  @moduledoc """
  Bản vá 19: gọi thật bộ định tuyến legacy, rồi sửa riêng
  ngày cổng đóng thành thuộc năm hiện tại: (open,close].
  """
  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyUpperBoundaryBelongsToNextYear, Year
  }

  def route(target_day, year), do: diagnose(target_day, year).corrected_route

  def diagnose(target_day, %Year{} = year) when is_integer(target_day) do
    historical = LegacyUpperBoundaryBelongsToNextYear.route(target_day, year)
    corrected = if historical == :next_at_upper_boundary, do: :found, else: historical
    %{historical_route: historical, corrected_route: corrected,
      changed: corrected != historical, target_day: target_day,
      open_gate_day: year.open_gate_day, close_gate_day: year.close_gate_day}
  end

  def diagnose(_, _), do: raise(ArgumentError, "ngày đích hoặc năm không hợp lệ")
end
