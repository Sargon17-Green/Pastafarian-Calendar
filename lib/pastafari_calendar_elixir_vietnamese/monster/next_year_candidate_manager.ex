defmodule PastafariCalendarElixirVietnamese.Monster.NextYearCandidateManager do
  @moduledoc """
  Các năm sau năm đã biết bắt đầu đúng tại cổng đóng của năm cũ.
  Mở rộng cổng đến open_day+5778, lọc mọi cổng đóng hợp lệ
  có ít nhất 6 khoảng và độ dài 252..5778, rồi sắp theo
  độ dài tăng dần. Không chọn rank trong tầng này.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{GateTimelineManager, Year}

  @max_days 5_778
  @min_days 252
  @min_gaps 6

  def build(%Year{} = known, %GateTimelineManager{} = state) do
    open_index = known.close_gate_index
    open_day = Map.fetch!(state.gate, open_index)
    next_state = cover_upper(state, open_day + @max_days)

    candidates =
      (open_index + 1)..next_state.max_index
      |> Enum.filter(fn close_index ->
        length = Map.fetch!(next_state.gate, close_index) - open_day
        gaps = close_index - open_index
        gaps >= @min_gaps and length >= @min_days and length <= @max_days
      end)
      |> Enum.sort_by(fn close_index ->
        Map.fetch!(next_state.gate, close_index) - open_day
      end)

    {candidates, next_state}
  end

  def build(_known, _state) do
    raise ArgumentError, "năm hoặc trạng thái cổng không hợp lệ"
  end

  defp cover_upper(state, day) do
    if Map.fetch!(state.gate, state.max_index) < day do
      next = GateTimelineManager.ensure_index(state, state.max_index + 1)
      cover_upper(next, day)
    else
      state
    end
  end
end
