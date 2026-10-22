defmodule PastafariCalendarElixirVietnamese.Monster.MonthLengthsManager do
  @moduledoc """
  DISCOVERY25 chọn hợp thành có thứ tự của độ dài năm
  thành đúng số tháng từ PATCH24, mỗi tháng 4..123 ngày.
  Đếm và mở hạng bằng số nguyên lớn. Di sản phản chiếu
  rank của bát 3 chốt 31; nguồn sauce là ngày đầu năm.
  Chưa thực hiện đan tháng, tên tháng hoặc lịch cuối.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, BoundedMonthCompositions,
    Dispatcher, LegacyMirroredMonthLengthsRank, MonthCountManager
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
    legacy_rank = LegacyMirroredMonthLengthsRank.transform(normative_rank, candidate_count)
    lengths = BoundedMonthCompositions.unrank(total, slots, legacy_rank)

    %{year: parent.year, gate_state: parent.gate_state,
      calculation_day: c, target_day: t, year_length: total,
      structure_source_day: parent.structure_source_day,
      cutlets: parent.cutlets, cutlet_count: parent.cutlet_count,
      month_count: slots, month_lengths: lengths,
      candidate_count: candidate_count, normative_rank: normative_rank,
      historical_rank: legacy_rank,
      bowl: @bowl, seal: @seal}
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
