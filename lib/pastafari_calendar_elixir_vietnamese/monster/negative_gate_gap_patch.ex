defmodule PastafariCalendarElixirVietnamese.Monster.NegativeGateGapPatch do
  @moduledoc """
  Bản vá 15: giữ và gọi thật LegacyMirroredNegativeGateGap,
  sau đó sửa nguồn ngày của cổng âm từ FOUNDATION+n
  thành FOUNDATION-n. Kết quả được chọn bằng cùng answer
  ring đã vá, bát 1, chốt 1 và miền 922.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    Dispatcher,
    LegacyMirroredNegativeGateGap
  }

  @foundation -15_055_671

  def negative_gap(n), do: diagnose(n).corrected_gap

  def diagnose(n) when is_integer(n) and n >= 1 do
    legacy_gap = LegacyMirroredNegativeGateGap.negative_gap(n)
    source_day = @foundation - n
    stream = Dispatcher.answer_stream(@foundation, source_day, 1, 1)
    correct_gap = 41 + AnswerStreamManager.choose_rank(stream, 922)

    %{
      index: -n,
      historical_source_day: @foundation + n,
      corrected_source_day: source_day,
      legacy_gap: legacy_gap,
      corrected_gap: correct_gap,
      correction: correct_gap - legacy_gap,
      bowl: 1,
      seal: 1,
      choice_span: 922
    }
  end

  def diagnose(_n), do: raise(ArgumentError, "chỉ số khoảng cách cổng âm phải dương")
end
