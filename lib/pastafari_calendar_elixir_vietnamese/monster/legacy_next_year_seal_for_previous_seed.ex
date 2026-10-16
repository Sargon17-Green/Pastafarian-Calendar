defmodule PastafariCalendarElixirVietnamese.Monster.LegacyNextYearSealForPreviousSeed do
  @moduledoc "Phát hiện 18: nhầm chốt 11 thay 12 khi chọn năm trước."
  alias PastafariCalendarElixirVietnamese.Monster.{AnswerStreamManager, Dispatcher}
  def choose_rank(calculation_day, close_day, count)
      when is_integer(calculation_day) and is_integer(close_day) and
           is_integer(count) and count >= 1 do
    stream = Dispatcher.answer_stream(calculation_day, close_day, 1, 11)
    AnswerStreamManager.choose_rank(stream, count)
  end
  def choose_rank(_, _, _), do: raise(ArgumentError, "ngày tính, ngày đóng hoặc số năm không hợp lệ")
end
