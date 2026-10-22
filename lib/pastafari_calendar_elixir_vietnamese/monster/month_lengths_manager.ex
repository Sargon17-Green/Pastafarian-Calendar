defmodule PastafariCalendarElixirVietnamese.Monster.MonthLengthsManager do
  @moduledoc """
  PATCH25 chọn hợp thành có thứ tự của độ dài năm
  thành đúng số tháng từ PATCH24, mỗi tháng 4..123 ngày.
  Đếm và mở hạng bằng số nguyên lớn. Di sản phản chiếu
  rank của bát 3 chốt 31; bản vá gọi di sản thật và khôi phục hạng.
  Chưa thực hiện đan tháng, tên tháng hoặc lịch cuối.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, BoundedMonthCompositions,
    Dispatcher, MonthLengthsRankPatch, MonthCountManager
  }

  @bowl 3
  @seal 31

  def lengths(c, t), do: diagnose(c, t).month_lengths

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = MonthCountManager.diagnose(c, t)
    total = parent.year_length
    slots = parent.month_count
    candidate_count = BoundedMonthCompositions.count(total, slots)
    stream = Dispatcher.answer_stream(c, parent.structure_source_day, @bowl, @seal)
    normative_rank = AnswerStreamManager.choose_rank(stream, candidate_count)
    patch = MonthLengthsRankPatch.diagnose(normative_rank, candidate_count)
    lengths = BoundedMonthCompositions.unrank(total, slots, patch.corrected_rank)
    historical_lengths = BoundedMonthCompositions.unrank(total, slots, patch.historical_rank)

    %{year: parent.year, gate_state: parent.gate_state,
      calculation_day: c, target_day: t, year_length: total,
      structure_source_day: parent.structure_source_day,
      cutlets: parent.cutlets, cutlet_count: parent.cutlet_count,
      month_count: slots, month_lengths: lengths,
      historical_month_lengths: historical_lengths,
      candidate_count: candidate_count, normative_rank: normative_rank,
      historical_rank: patch.historical_rank, corrected_rank: patch.corrected_rank,
      bowl: @bowl, seal: @seal}
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
