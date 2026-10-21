defmodule PastafariCalendarElixirVietnamese.Monster.CutletNameIndexManager do
  @moduledoc """
  PATCH22 chọn đúng rank từ bát 5/chốt 22 sau khi gọi
  thật di sản đã xoay rank một bước để ghi nhận lịch sử.
  Count P(17,k), mở hạng từ điển và nguồn ngày không đổi.
  Chưa vật chất hóa cốt-lết hoặc kết quả lịch cuối.
  """
  alias PastafariCalendarElixirVietnamese.Monster.{
    CutletPartitionManager, DistinctCutletNameIndices,
    CutletNameRankPatch
  }

  @names 17
  def names(c, t), do: diagnose(c, t).name_indices

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = CutletPartitionManager.diagnose(c, t)
    k = parent.cutlet_count
    total = DistinctCutletNameIndices.count(@names, k)
    seed = CutletNameRankPatch.diagnose(c, parent.structure_source_day, total)
    rank = seed.corrected_rank
    names = DistinctCutletNameIndices.unrank(@names, k, rank)
    %{year: parent.year, gate_state: parent.gate_state,
      calculation_day: c, target_day: t,
      structure_source_day: parent.structure_source_day,
      cutlet_partition: parent.partition, cutlet_count: k,
      candidate_count: total, rank: rank,
      historical_rank: seed.historical_rank,
      rank_was_corrected: seed.changed,
      name_indices: names, name_capacity: @names, bowl: 5, seal: 22}
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
