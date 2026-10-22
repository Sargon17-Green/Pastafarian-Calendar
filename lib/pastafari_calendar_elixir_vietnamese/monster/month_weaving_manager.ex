defmodule PastafariCalendarElixirVietnamese.Monster.MonthWeavingManager do
  @moduledoc """
  DISCOVERY26 dùng bowl 4, seal 32 và độ dài tháng từ PATCH25.
  Cố ý mở hạng theo thứ tự nhãn giảm của di sản; giữ thứ tự
  và hạng trong chẩn đoán để PATCH26 sửa sau khi RED được xác nhận.
  Không tích hợp tên tháng hoặc ngày lịch hoàn chỉnh.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, Dispatcher, LegacyDescendingWeavingOrder,
    MonthLengthsManager, WeavingCombinatorics
  }

  @bowl 4
  @seal 32

  def weaving(c, t), do: diagnose(c, t).month_weaving

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = MonthLengthsManager.diagnose(c, t)
    child = diagnose_lengths(c, parent.structure_source_day, parent.month_lengths)

    Map.merge(parent, %{
      month_weaving: child.month_weaving,
      weaving_count: child.weaving_count,
      weaving_rank: child.weaving_rank,
      weaving_historical_order: child.weaving_historical_order,
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
    order = LegacyDescendingWeavingOrder.labels(length(lengths))
    historical = WeavingCombinatorics.unrank(lengths, rank, :descending)

    %{month_lengths: lengths, month_weaving: historical,
      weaving_count: count, weaving_rank: rank,
      weaving_historical_order: order,
      weaving_bowl: @bowl, weaving_seal: @seal}
  end

  def diagnose_lengths(_, _, _),
    do: raise(ArgumentError, "ngày nguồn và ngày tính phải là số nguyên")
end
