defmodule PastafariCalendarElixirVietnamese.Monster.LegacyRotatedCutletNameRank do
  @moduledoc """
  Di sản DISCOVERY22: sau khi chọn hạng đúng từ bát 5,
  chốt 22, phép chuyển nhầm hạng một-based sang hạng kế.
  Hạng cuối bị quay về 1; tập tên và vòng đáp án vẫn đúng.
  PATCH22 phải giữ nguyên và gọi thật hàm lỗi này.
  """
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, Dispatcher
  }

  def choose_rank(c, first_day, count)
      when is_integer(c) and is_integer(first_day) and
           is_integer(count) and count >= 1 do
    stream = Dispatcher.answer_stream(c, first_day, 5, 22)
    chosen_rank = AnswerStreamManager.choose_rank(stream, count)
    rem(chosen_rank, count) + 1
  end

  def choose_rank(_, _, _),
    do: raise(ArgumentError, "ngày tính, ngày hỏi hoặc số lựa chọn không hợp lệ")
end
