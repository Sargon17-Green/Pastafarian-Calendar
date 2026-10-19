defmodule PastafariCalendarElixirVietnamese.Monster.CutletCountManager do
  @moduledoc """
  DISCOVERY20 chọn số cốt-lết của năm đích. Cổng, tập ứng
  viên 6..17, bowl2, seal20, nguồn ngày và rank đều đúng.
  Production cố tình áp rank vào thứ tự di sản giảm dần.
  Chưa tính phân hoạch, tên cốt-lết hay lịch hoàn chỉnh.
  """
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, Dispatcher,
    LegacyDescendingCutletCount, TargetYearManager
  }

  @bowl 2
  @seal 20
  def cutlet_count(c, t), do: diagnose(c, t).cutlet_count

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    target_report = TargetYearManager.diagnose(c, t)
    year = target_report.year
    gaps = year.close_gate_index - year.open_gate_index
    candidates = Enum.filter(6..17, &(&1 <= gaps))
    if candidates == [], do: raise(ArgumentError, "không tìm thấy số cốt-lết")
    historical_order = LegacyDescendingCutletCount.sort(candidates)
    first_day = year.open_gate_day + 1
    stream = Dispatcher.answer_stream(c, first_day, @bowl, @seal)
    rank = AnswerStreamManager.choose_rank(stream, length(candidates))
    selected = Enum.at(historical_order, rank - 1)
    %{year: year, gate_state: target_report.gate_state,
      calculation_day: c, target_day: t,
      structure_source_day: first_day, gate_gaps: gaps,
      candidates: candidates, historical_order: historical_order,
      candidate_count: length(candidates), rank: rank,
      cutlet_count: selected, bowl: @bowl, seal: @seal}
  end

  def diagnose(_, _), do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
