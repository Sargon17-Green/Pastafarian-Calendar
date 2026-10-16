defmodule PastafariCalendarElixirVietnamese.Monster.PreviousYearCandidateManager do
  @moduledoc "Tập cổng ứng viên năm trước, sắp theo độ dài tăng."
  alias PastafariCalendarElixirVietnamese.Monster.{GateTimelineManager, Year}
  def build(%Year{} = known, %GateTimelineManager{} = state) do
    index = known.open_gate_index
    day = Map.fetch!(state.gate, index)
    new_state = extend(state, day - 5_778)
    candidates = new_state.min_index..(index - 1)
      |> Enum.filter(fn i ->
        length = day - Map.fetch!(new_state.gate, i)
        index - i >= 6 and length >= 252 and length <= 5_778
      end)
      |> Enum.sort_by(fn i -> day - Map.fetch!(new_state.gate, i) end)
    {candidates, new_state}
  end
  def build(_, _), do: raise(ArgumentError, "năm hoặc cổng không hợp lệ")
  defp extend(state, day) do
    if Map.fetch!(state.gate, state.min_index) > day do
      extend(GateTimelineManager.ensure_index(state, state.min_index - 1), day)
    else
      state
    end
  end
end
