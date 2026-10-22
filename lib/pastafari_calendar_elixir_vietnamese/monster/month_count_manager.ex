defmodule PastafariCalendarElixirVietnamese.Monster.MonthCountManager do
  @moduledoc """
  DISCOVERY24 chọn số tháng của năm chứa ngày đích.
  Cận dưới ceil(year_length/123), cận trên
  min(47,floor(year_length/4)), chọn từ bát 3 chốt 30
  theo hạng một-based. Production cố ý dùng ứng viên
  theo thứ tự di sản giảm dần thay vì thứ tự chuẩn tăng.
  Chưa tính chiều dài hoặc tên tháng.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, CutletMaterializationManager,
    Dispatcher, LegacyDescendingMonthCount
  }

  @bowl 3
  @seal 30

  def month_count(c, t), do: diagnose(c, t).month_count

  def candidates_for_length(length)
      when is_integer(length) and length >= 1 do
    minimum = div(length + 122, 123)
    maximum = min(47, div(length, 4))
    if minimum > maximum do
      raise ArgumentError, "độ dài năm không có số tháng khả thi"
    end
    Enum.to_list(minimum..maximum)
  end

  def candidates_for_length(_),
    do: raise(ArgumentError, "độ dài năm phải là số nguyên dương")

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = CutletMaterializationManager.diagnose(c, t)
    year = parent.year
    year_length = year.close_gate_day - year.open_gate_day
    candidates = candidates_for_length(year_length)
    historical_order = LegacyDescendingMonthCount.sort(candidates)
    source_day = year.open_gate_day + 1

    stream = Dispatcher.answer_stream(c, source_day, @bowl, @seal)
    rank = AnswerStreamManager.choose_rank(stream, length(candidates))
    chosen = Enum.at(historical_order, rank - 1)

    %{year: year, gate_state: parent.gate_state,
      calculation_day: c, target_day: t, year_length: year_length,
      structure_source_day: source_day,
      cutlets: parent.cutlets, cutlet_count: parent.cutlet_count,
      candidates: candidates, historical_order: historical_order,
      candidate_count: length(candidates), rank: rank,
      month_count: chosen, bowl: @bowl, seal: @seal}
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
