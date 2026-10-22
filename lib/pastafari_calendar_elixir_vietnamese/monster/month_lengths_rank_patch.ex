defmodule PastafariCalendarElixirVietnamese.Monster.MonthLengthsRankPatch do
  @moduledoc "PATCH25 gọi di sản thật, giữ hạng lịch sử rồi khôi phục hạng chuẩn bằng đối hợp."
  alias PastafariCalendarElixirVietnamese.Monster.LegacyMirroredMonthLengthsRank

  def diagnose(rank, count) do
    historical_rank = LegacyMirroredMonthLengthsRank.transform(rank, count)
    corrected_rank = LegacyMirroredMonthLengthsRank.transform(historical_rank, count)
    %{historical_rank: historical_rank, corrected_rank: corrected_rank,
      candidate_count: count, changed: historical_rank != corrected_rank}
  end
end
