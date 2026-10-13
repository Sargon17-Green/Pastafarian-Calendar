defmodule PastafariCalendarElixirVietnamese.Monster.GateGapManager do
  @moduledoc """
  Độ dài cổng phụ thuộc đúng hai ngày, cùng nguồn nước số 1
  và chốt 1. Phía dương giữ nguyên. Phía âm dùng
  NegativeGateGapPatch, vẫn gọi legacy trước khi sửa ngày.

  Mọi truy vấn chạy qua Dispatcher.answer_stream và các bản
  vá 01..14, không dùng dữ liệu ngẫu nhiên, trạng thái chung
  hoặc mã chuẩn test-only.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    Dispatcher,
    NegativeGateGapPatch
  }

  @foundation -15_055_671

  def positive_gap(n) when is_integer(n) and n >= 1 do
    stream = Dispatcher.answer_stream(@foundation, @foundation + n, 1, 1)
    41 + AnswerStreamManager.choose_rank(stream, 922)
  end

  def positive_gap(_n) do
    raise ArgumentError, "chỉ số khoảng cách cổng dương phải dương"
  end

  def negative_gap(n) when is_integer(n) and n >= 1 do
    NegativeGateGapPatch.negative_gap(n)
  end

  def negative_gap(_n) do
    raise ArgumentError, "chỉ số khoảng cách cổng âm phải dương"
  end
end
