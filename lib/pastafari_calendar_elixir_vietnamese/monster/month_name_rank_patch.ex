defmodule PastafariCalendarElixirVietnamese.Monster.MonthNameRankPatch do
  @moduledoc """
  PATCH27 thực thi di sản dịch hạng có chủ đích,
  giữ nguyên hạng và dãy tên sai làm chứng cứ.
  Đảo lại hạng một-based rồi mở dãy tên từ điển chuẩn.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    DistinctMonthNameIndices, LegacyNextMonthNameRank
  }

  def diagnose(rank, total, count) do
    historical_rank = LegacyNextMonthNameRank.transform(rank, total)
    historical_names = DistinctMonthNameIndices.unrank(count, historical_rank)
    corrected_rank = if historical_rank == 1, do: total, else: historical_rank - 1
    corrected_names = DistinctMonthNameIndices.unrank(count, corrected_rank)

    %{historical_rank: historical_rank, historical_names: historical_names,
      corrected_rank: corrected_rank, corrected_names: corrected_names,
      selected_rank: rank, candidate_count: total}
  end
end
