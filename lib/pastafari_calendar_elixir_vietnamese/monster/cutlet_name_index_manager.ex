defmodule PastafariCalendarElixirVietnamese.Monster.CutletNameIndexManager do
  @moduledoc """
  DISCOVERY22 chọn dãy tên riêng cho các cốt-lết của năm.
  Count P(17,k), nguồn ngày đầu năm, bát 5 và chốt 22 đúng;
  di sản làm lệch hạng một bước trước khi mở hạng từ điển.
  Chưa vật chất hóa cốt-lết hoặc kết quả lịch cuối.
  """
  alias PastafariCalendarElixirVietnamese.Monster.{
    CutletPartitionManager, DistinctCutletNameIndices,
    LegacyRotatedCutletNameRank
  }

  @names 17
  def names(c, t), do: diagnose(c, t).name_indices

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = CutletPartitionManager.diagnose(c, t)
    k = parent.cutlet_count
    total = DistinctCutletNameIndices.count(@names, k)
    rank = LegacyRotatedCutletNameRank.choose_rank(
      c, parent.structure_source_day, total)
    names = DistinctCutletNameIndices.unrank(@names, k, rank)
    %{year: parent.year, gate_state: parent.gate_state,
      calculation_day: c, target_day: t,
      structure_source_day: parent.structure_source_day,
      cutlet_partition: parent.partition, cutlet_count: k,
      candidate_count: total, rank: rank, name_indices: names,
      name_capacity: @names, bowl: 5, seal: 22}
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
