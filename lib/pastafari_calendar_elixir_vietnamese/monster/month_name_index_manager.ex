defmodule PastafariCalendarElixirVietnamese.Monster.MonthNameIndexManager do
  @moduledoc """
  DISCOVERY27 chọn tên khác nhau từ 47 tên theo bowl 5,
  seal 33 và nguồn là ngày đầu của năm đích.
  Lỗi di sản cố ý tăng hạng thêm một, còn dòng đáp án
  và độ dài tháng, cách đan, năm, cốt-lết giữ nguyên.
  Chưa tích hợp ngày lịch cuối cùng.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, Dispatcher, DistinctMonthNameIndices,
    LegacyNextMonthNameRank, MonthWeavingManager
  }

  @bowl 5
  @seal 33

  def names(c, t), do: diagnose(c, t).month_name_indices

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = MonthWeavingManager.diagnose(c, t)
    child = diagnose_count(c, parent.structure_source_day, parent.month_count)

    Map.merge(parent, %{
      month_name_indices: child.month_name_indices,
      historical_month_name_indices: child.historical_month_name_indices,
      month_name_candidate_count: child.month_name_candidate_count,
      month_name_rank: child.month_name_rank,
      historical_month_name_rank: child.historical_month_name_rank,
      month_name_bowl: child.month_name_bowl,
      month_name_seal: child.month_name_seal
    })
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")

  def diagnose_count(c, source_day, month_count)
      when is_integer(c) and is_integer(source_day) do
    total = DistinctMonthNameIndices.count(month_count)
    stream = Dispatcher.answer_stream(c, source_day, @bowl, @seal)
    rank = AnswerStreamManager.choose_rank(stream, total)
    historical_rank = LegacyNextMonthNameRank.transform(rank, total)
    historical = DistinctMonthNameIndices.unrank(month_count, historical_rank)

    %{month_name_indices: historical,
      historical_month_name_indices: historical,
      month_name_candidate_count: total,
      month_name_rank: rank,
      historical_month_name_rank: historical_rank,
      month_name_bowl: @bowl, month_name_seal: @seal}
  end

  def diagnose_count(_, _, _),
    do: raise(ArgumentError, "đầu vào tên tháng không hợp lệ")
end
