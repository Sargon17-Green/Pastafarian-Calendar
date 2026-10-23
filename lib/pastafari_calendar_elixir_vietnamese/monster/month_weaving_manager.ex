defmodule PastafariCalendarElixirVietnamese.Monster.MonthWeavingManager do
  @moduledoc """
  PATCH26 nối độ dài tháng từ PATCH25 với bowl 4, seal 32.
  Bộ vá gọi thứ tự di sản thực và giữ cả hai chuỗi để kiểm toán.
  Chưa tích hợp tên tháng hoặc ngày lịch cuối cùng.
  """
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, Dispatcher, MonthLengthsManager,
    MonthWeavingOrderPatch, WeavingCombinatorics
  }

  @bowl 4
  @seal 32

  def weaving(c, t), do: diagnose(c, t).month_weaving

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = MonthLengthsManager.diagnose(c, t)
    child = diagnose_lengths(c, parent.structure_source_day, parent.month_lengths)
    Map.merge(parent, %{
      month_weaving: child.month_weaving,
      historical_month_weaving: child.historical_month_weaving,
      weaving_count: child.weaving_count,
      weaving_rank: child.weaving_rank,
      weaving_historical_order: child.weaving_historical_order,
      weaving_corrected_order: child.weaving_corrected_order,
      weaving_bowl: child.weaving_bowl,
      weaving_seal: child.weaving_seal
    })
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")

  def diagnose_lengths(c, source_day, lengths)
      when is_integer(c) and is_integer(source_day) do
    count = WeavingCombinatorics.count(lengths)
    stream = Dispatcher.answer_stream(c, source_day, @bowl, @seal)
    rank = AnswerStreamManager.choose_rank(stream, count)
    patch = MonthWeavingOrderPatch.diagnose(lengths, rank)

    %{month_lengths: lengths,
      month_weaving: patch.corrected_weaving,
      historical_month_weaving: patch.historical_weaving,
      weaving_count: count, weaving_rank: rank,
      weaving_historical_order: patch.historical_order,
      weaving_corrected_order: patch.corrected_order,
      weaving_bowl: @bowl, weaving_seal: @seal}
  end

  def diagnose_lengths(_, _, _),
    do: raise(ArgumentError, "ngày nguồn và ngày tính phải là số nguyên")
end
