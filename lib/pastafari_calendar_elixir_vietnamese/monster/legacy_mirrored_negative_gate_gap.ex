defmodule PastafariCalendarElixirVietnamese.Monster.LegacyMirroredNegativeGateGap do
  @moduledoc """
  Phát hiện 15: lỗi phản chiếu nguồn ngày của cổng âm.

  Hệ cổng chuẩn phải tính khoảng cách âm thứ n bằng cùng
  Ngày Nền nhưng dùng ngày hỏi FOUNDATION-n. Hàm lịch sử
  cố ý dùng FOUNDATION+n, khiến độ dài phía âm bị sao chép
  từ phía dương. Không sửa hàm này trong giai đoạn 30.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    Dispatcher
  }

  @foundation -15_055_671

  def negative_gap(n) when is_integer(n) and n >= 1 do
    stream = Dispatcher.answer_stream(@foundation, @foundation + n, 1, 1)
    41 + AnswerStreamManager.choose_rank(stream, 922)
  end

  def negative_gap(_n) do
    raise ArgumentError, "chỉ số khoảng cách cổng âm phải dương"
  end
end
