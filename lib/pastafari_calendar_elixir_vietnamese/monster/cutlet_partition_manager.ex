defmodule PastafariCalendarElixirVietnamese.Monster.CutletPartitionManager do
  @moduledoc """
  DISCOVERY21 tạo phân hoạch cốt-lết theo thứ tự từ điển,
  giữ cổng tính bắt buộc nếu nằm đúng trong năm. Production
  vẫn dùng hạng legacy chốt 20 thay vì chốt 21 chuẩn.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    CutletCountManager, CutletPartitionCombinatorics,
    LegacyCutletPartitionCountSeal
  }

  def partition(c, t), do: diagnose(c, t).partition

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = CutletCountManager.diagnose(c, t)
    year = parent.year
    gate = parent.gate_state.gate
    internal_index =
      Enum.find((year.open_gate_index + 1)..(year.close_gate_index - 1),
        fn i -> Map.fetch!(gate, i) == c end)
    required =
      if is_nil(internal_index), do: nil,
        else: internal_index - year.open_gate_index

    gaps = parent.gate_gaps
    slots = parent.cutlet_count
    count = CutletPartitionCombinatorics.count(gaps, slots, required)
    rank = LegacyCutletPartitionCountSeal.choose_rank(c,
      parent.structure_source_day, count)
    partition = CutletPartitionCombinatorics.unrank(gaps, slots, required, rank)

    %{year: year, gate_state: parent.gate_state,
      calculation_day: c, target_day: t,
      structure_source_day: parent.structure_source_day,
      cutlet_count: slots, gate_gaps: gaps,
      required_boundary: required, calculation_gate_index: internal_index,
      candidate_count: count, rank: rank, partition: partition,
      bowl: 2, historical_seal: 20, normative_seal: 21}
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
