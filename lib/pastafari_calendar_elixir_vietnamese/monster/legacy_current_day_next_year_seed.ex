defmodule PastafariCalendarElixirVietnamese.Monster.LegacyCurrentDayNextYearSeed do
  @moduledoc """
  Phát hiện 17: chọn năm tiếp theo bằng sai ngày hỏi.
  Chuẩn dùng sauce(calculation_day, open_day), trong đó
  open_day chính là cổng đóng của năm đã biết.
  Legacy cố ý dùng sauce(calculation_day, calculation_day)
  dù niên giới bắt đầu ở ngày khác.
  Giữ nguyên mô-đun này cho PATCH 17 của Stage35.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{AnswerStreamManager, Dispatcher}

  def choose_rank(calculation_day, count)
      when is_integer(calculation_day) and is_integer(count) and count >= 1 do
    stream = Dispatcher.answer_stream(calculation_day, calculation_day, 1, 11)
    AnswerStreamManager.choose_rank(stream, count)
  end

  def choose_rank(_calculation_day, _count) do
    raise ArgumentError, "ngày tính hoặc số lượng năm không hợp lệ"
  end
end
