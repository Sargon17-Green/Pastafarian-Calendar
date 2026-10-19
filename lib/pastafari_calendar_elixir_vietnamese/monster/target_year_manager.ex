defmodule PastafariCalendarElixirVietnamese.Monster.TargetYearManager do
  @moduledoc """
  Tìm năm chứa ngày đích bằng cách đi từ năm neo 5000.
  Stage39 vẫn gọi bộ định tuyến legacy nhưng sửa cổng đóng
  thành ngày cuối năm hiện tại, theo khoảng (open,close].
  Các bước tiến/lùi khác dùng đúng hai bộ chọn đã vá.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    TargetYearBoundaryPatch,
    NextYearManager,
    PreviousYearManager,
    Year5000Manager
  }

  def find(calculation_day, target_day) do
    diagnose(calculation_day, target_day).year
  end

  def diagnose(calculation_day, target_day)
      when is_integer(calculation_day) and is_integer(target_day) do
    anchor = Year5000Manager.diagnose(calculation_day)
    {year, state, trace} =
      walk(calculation_day, target_day, anchor.year, anchor.gate_state, [])

    %{year: year, anchor_year: anchor.year, gate_state: state,
      calculation_day: calculation_day, target_day: target_day,
      trace: Enum.reverse(trace), steps: length(trace)}
  end

  def diagnose(_, _) do
    raise ArgumentError, "ngày tính và ngày đích phải là số nguyên"
  end

  defp walk(calculation_day, target_day, year, state, trace) do
    case TargetYearBoundaryPatch.route(target_day, year) do
      :found ->
        {year, state, trace}

      :next ->
        report = NextYearManager.next_year_from(calculation_day, year, state)
        walk(calculation_day, target_day, report.year, report.gate_state,
          [{:next, year.number, report.year.number} | trace])

      :previous ->
        report = PreviousYearManager.previous_year_from(calculation_day, year, state)
        walk(calculation_day, target_day, report.year, report.gate_state,
          [{:previous, year.number, report.year.number} | trace])

    end
  end
end
