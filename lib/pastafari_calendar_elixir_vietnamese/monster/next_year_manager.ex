defmodule PastafariCalendarElixirVietnamese.Monster.NextYearManager do
  @moduledoc """
  Tìm năm kế sau năm đã biết mà không thay đổi gate, SAVE hay
  nguyên tắc chọn tập ứng viên. Stage35 đi qua NextYearSeedPatch,
  vẫn gọi legacy ngày hỏi sai, rồi chọn hạng từ open_day chuẩn.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    NextYearSeedPatch,
    NextYearCandidateManager,
    Year,
    Year5000Manager
  }

  def next_year(calculation_day), do: diagnose(calculation_day).year

  def diagnose(calculation_day) when is_integer(calculation_day) do
    anchor = Year5000Manager.diagnose(calculation_day)
    next_year_from(calculation_day, anchor.year, anchor.gate_state)
  end

  def diagnose(_), do: raise(ArgumentError, "ngày tính phải là số nguyên")

  def next_year_from(calculation_day, %Year{} = known, state)
      when is_integer(calculation_day) do
    {candidates, next_state} = NextYearCandidateManager.build(known, state)
    if candidates == [], do: raise(ArgumentError, "không tìm thấy năm tiếp theo")

    open_index = known.close_gate_index
    open_day = Map.fetch!(next_state.gate, open_index)
    seed_report = NextYearSeedPatch.diagnose(calculation_day, open_day, length(candidates))
    rank = seed_report.corrected_rank
    close_index = Enum.at(candidates, rank - 1)

    year = %Year{
      number: known.number + 1,
      open_gate_index: open_index,
      close_gate_index: close_index,
      open_gate_day: open_day,
      close_gate_day: Map.fetch!(next_state.gate, close_index)
    }

    %{year: year, known_year: known, gate_state: next_state,
      candidates: candidates, candidate_count: length(candidates),
      calculation_day: calculation_day, historical_source_day: calculation_day,
      normative_source_day: open_day, rank: rank,
      historical_rank: seed_report.legacy_rank,
      rank_was_corrected: seed_report.changed, bowl: 1, seal: 11}
  end

  def next_year_from(_c, _known, _state) do
    raise ArgumentError, "ngày tính, năm hoặc trạng thái không hợp lệ"
  end
end
