defmodule PastafariCalendarElixirVietnamese.Monster.PreviousYearManager do
  @moduledoc "Tìm năm trước 5000; Stage36 cố ý dùng legacy chốt 11 thay vì 12."
  alias PastafariCalendarElixirVietnamese.Monster.{LegacyNextYearSealForPreviousSeed, PreviousYearCandidateManager, Year, Year5000Manager}
  def previous_year(day), do: diagnose(day).year
  def diagnose(day) when is_integer(day) do
    anchor = Year5000Manager.diagnose(day)
    previous_year_from(day, anchor.year, anchor.gate_state)
  end
  def diagnose(_), do: raise(ArgumentError, "ngày tính phải là số nguyên")
  def previous_year_from(day, %Year{} = known, state) when is_integer(day) do
    {candidates, new_state} = PreviousYearCandidateManager.build(known, state)
    if candidates == [], do: raise(ArgumentError, "không tìm thấy năm trước")
    close_index = known.open_gate_index
    close_day = Map.fetch!(new_state.gate, close_index)
    rank = LegacyNextYearSealForPreviousSeed.choose_rank(day, close_day, length(candidates))
    open_index = Enum.at(candidates, rank - 1)
    year = %Year{number: known.number - 1,
      open_gate_index: open_index, close_gate_index: close_index,
      open_gate_day: Map.fetch!(new_state.gate, open_index), close_gate_day: close_day}
    %{year: year, known_year: known, gate_state: new_state,
      candidates: candidates, candidate_count: length(candidates),
      calculation_day: day, source_day: close_day,
      rank: rank, bowl: 1, historical_seal: 11, normative_seal: 12}
  end
  def previous_year_from(_, _, _), do: raise(ArgumentError, "ngày tính, năm hoặc trạng thái không hợp lệ")
end
