defmodule PastafariCalendarElixirVietnamese.Monster.GateTimelineManager do
  @moduledoc """
  Dãy chỉ số cổng nguyên hai chiều, neo tại FOUNDATION.
  Giai đoạn 30 mở rộng cổng dương và âm bằng GateGapManager,
  giữ mọi ô trong bản đồ riêng và không thay đổi trạng thái cũ.
  Nhánh âm đã được sửa qua GateGapManager và PATCH 15.
  """

  alias PastafariCalendarElixirVietnamese.Monster.GateGapManager

  @foundation -15_055_671

  defstruct gate: %{0 => -15_055_671}, min_index: 0, max_index: 0

  def new, do: %__MODULE__{}
  def foundation_day, do: @foundation

  def gate_day(index) when is_integer(index) do
    {day, _state} = day_at(new(), index)
    day
  end

  def gate_day(_index), do: raise(ArgumentError, "chỉ số cổng phải là số nguyên")

  def day_at(%__MODULE__{} = state, index) when is_integer(index) do
    state2 = ensure_index(state, index)
    {Map.fetch!(state2.gate, index), state2}
  end

  def day_at(_state, _index) do
    raise ArgumentError, "trạng thái cổng hoặc chỉ số không hợp lệ"
  end

  def ensure_index(%__MODULE__{} = state, index) when is_integer(index) do
    cond do
      index > state.max_index -> extend_positive(state, state.max_index + 1, index)
      index < state.min_index -> extend_negative(state, state.min_index - 1, index)
      true -> state
    end
  end

  def ensure_index(_state, _index) do
    raise ArgumentError, "trạng thái cổng hoặc chỉ số không hợp lệ"
  end

  defp extend_positive(state, n, target) when n > target, do: state

  defp extend_positive(state, n, target) do
    previous_day = Map.fetch!(state.gate, n - 1)
    next_day = previous_day + GateGapManager.positive_gap(n)
    next = %{state | gate: Map.put(state.gate, n, next_day), max_index: n}
    extend_positive(next, n + 1, target)
  end

  defp extend_negative(state, n, target) when n < target, do: state

  defp extend_negative(state, n, target) do
    following_day = Map.fetch!(state.gate, n + 1)
    previous_day = following_day - GateGapManager.negative_gap(abs(n))
    next = %{state | gate: Map.put(state.gate, n, previous_day), min_index: n}
    extend_negative(next, n - 1, target)
  end
end
