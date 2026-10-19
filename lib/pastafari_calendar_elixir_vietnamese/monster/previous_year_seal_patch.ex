defmodule PastafariCalendarElixirVietnamese.Monster.PreviousYearSealPatch do
  @moduledoc """
  Bản vá 18 cho bước chọn năm trước. Giữ nguyên phép hỏi di sản
  dùng chốt 11; luôn gọi nó thật trước khi hỏi lại cùng hai ngày
  bằng chốt 12 chuẩn. Không sửa ứng viên, gate hoặc thứ tự rank.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    Dispatcher,
    LegacyNextYearSealForPreviousSeed
  }

  def choose_rank(calculation_day, close_day, count) do
    diagnose(calculation_day, close_day, count).corrected_rank
  end

  def diagnose(calculation_day, close_day, count)
      when is_integer(calculation_day) and is_integer(close_day) and
           is_integer(count) and count >= 1 do
    legacy_rank = LegacyNextYearSealForPreviousSeed.choose_rank(
      calculation_day, close_day, count
    )

    stream = Dispatcher.answer_stream(calculation_day, close_day, 1, 12)
    corrected_rank = AnswerStreamManager.choose_rank(stream, count)

    %{
      calculation_day: calculation_day,
      source_day: close_day,
      bowl: 1,
      historical_seal: 11,
      normative_seal: 12,
      candidate_count: count,
      legacy_rank: legacy_rank,
      corrected_rank: corrected_rank,
      changed: legacy_rank != corrected_rank
    }
  end

  def diagnose(_, _, _) do
    raise ArgumentError, "ngày tính, ngày đóng hoặc số năm không hợp lệ"
  end
end
