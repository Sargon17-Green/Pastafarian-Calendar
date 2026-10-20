defmodule PastafariCalendarElixirVietnamese.Monster.LegacyCutletPartitionCountSeal do
  @moduledoc """
  Di sản DISCOVERY21: khi chọn phân hoạch cốt-lết, lấy hạng
  từ chốt 20 (chốt chọn số cốt-lết) thay vì chốt 21 chuẩn.
  Đếm, mở hạng và cổng bên trong vẫn đúng.
  PATCH21 phải giữ hàm lịch sử này.
  """
  alias PastafariCalendarElixirVietnamese.Monster.{AnswerStreamManager, Dispatcher}

  def choose_rank(c, first_day, count)
      when is_integer(c) and is_integer(first_day) and
        is_integer(count) and count >= 1 do
    stream = Dispatcher.answer_stream(c, first_day, 2, 20)
    AnswerStreamManager.choose_rank(stream, count)
  end

  def choose_rank(_, _, _),
    do: raise(ArgumentError, "ngày tính, ngày hỏi hoặc số lựa chọn không hợp lệ")
end
