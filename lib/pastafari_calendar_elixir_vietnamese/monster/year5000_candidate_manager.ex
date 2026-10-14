defmodule PastafariCalendarElixirVietnamese.Monster.Year5000CandidateManager do
  @moduledoc """
  Mở rộng bảng cổng chính xác trong cửa sổ +/-5778 ngày
  quanh ngày tính. Liệt kê mọi cặp cổng i<j sao cho có ít
  nhất sáu khoảng, năm dài từ 252 tới 5778 ngày,
  gate(i)<ngày tính<=gate(j).

  Không sắp xếp tại tầng này: di sản lỗi Stage32
  nằm riêng trong LegacyLongestFirstYear5000.
  """

  alias PastafariCalendarElixirVietnamese.Monster.GateTimelineManager

  @max_year_days 5_778
  @min_year_days 252
  @min_gaps 6

  def max_year_days, do: @max_year_days
  def min_year_days, do: @min_year_days

  def build(calculation_day) when is_integer(calculation_day) do
    state =
      GateTimelineManager.new()
      |> cover_lower(calculation_day - @max_year_days)
      |> cover_upper(calculation_day + @max_year_days)

    indices = Enum.to_list(state.min_index..state.max_index)

    candidates =
      for i <- indices, j <- indices,
          i < j and j - i >= @min_gaps,
          into: [] do
        first_day = Map.fetch!(state.gate, i)
        last_day = Map.fetch!(state.gate, j)
        length = last_day - first_day

        if length >= @min_year_days and length <= @max_year_days and
             first_day < calculation_day and calculation_day <= last_day do
          %{open_gate_index: i, close_gate_index: j,
            open_gate_day: first_day, close_gate_day: last_day,
            length: length}
        else
          nil
        end
      end
      |> Enum.reject(&is_nil/1)

    {candidates, state}
  end

  def build(_), do: raise(ArgumentError, "ngày tính phải là số nguyên")

  defp cover_lower(state, day) do
    if Map.fetch!(state.gate, state.min_index) > day do
      next = GateTimelineManager.ensure_index(state, state.min_index - 1)
      cover_lower(next, day)
    else
      state
    end
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
