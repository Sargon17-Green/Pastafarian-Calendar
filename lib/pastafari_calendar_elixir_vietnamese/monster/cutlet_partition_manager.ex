defmodule PastafariCalendarElixirVietnamese.Monster.CutletPartitionManager do
  @moduledoc """
  DISCOVERY21 tạo phân hoạch cốt-lết theo thứ tự từ điển,
  giữ cổng tính bắt buộc nếu nằm đúng trong năm. Production
  dùng PATCH21 gọi legacy chốt 20 rồi lấy hạng chuẩn chốt 21.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    CutletCountManager, CutletPartitionCombinatorics,
    CutletPartitionSealPatch
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
    seed = CutletPartitionSealPatch.diagnose(c, parent.structure_source_day, count)
    rank = seed.corrected_rank
    partition = CutletPartitionCombinatorics.unrank(gaps, slots, required, rank)

    %{year: year, gate_state: parent.gate_state,
      calculation_day: c, target_day: t,
      structure_source_day: parent.structure_source_day,
      cutlet_count: slots, gate_gaps: gaps,
      required_boundary: required, calculation_gate_index: internal_index,
      candidate_count: count, rank: rank, historical_rank: seed.legacy_rank,
      seal_was_corrected: seed.changed, partition: partition,
      bowl: 2, historical_seal: 20, normative_seal: 21}
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
