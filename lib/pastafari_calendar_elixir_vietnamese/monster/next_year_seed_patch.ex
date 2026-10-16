defmodule PastafariCalendarElixirVietnamese.Monster.NextYearSeedPatch do
  @moduledoc """
  PATCH 17: giữ nguyên và gọi thật hạt ngày hỏi sai
  LegacyCurrentDayNextYearSeed(c,c), rồi tính lại hạng chuẩn
  từ sauce(c,open_day), bát 1, chốt 11.

  Truy vấn năm mới bắt đầu tại cổng đóng của năm đã biết;
  open_day là ngày cổng đó. Không gọi oracle test-only,
  không thay candidate, thứ tự, ngưỡng năm hoặc state.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    Dispatcher,
    LegacyCurrentDayNextYearSeed
  }

  def choose_rank(calculation_day, open_day, count),
    do: diagnose(calculation_day, open_day, count).corrected_rank

  def diagnose(calculation_day, open_day, count)
      when is_integer(calculation_day) and is_integer(open_day) and
           is_integer(count) and count >= 1 do
    legacy_rank = LegacyCurrentDayNextYearSeed.choose_rank(calculation_day, count)
    stream = Dispatcher.answer_stream(calculation_day, open_day, 1, 11)
    corrected_rank = AnswerStreamManager.choose_rank(stream, count)

    %{
      historical_source_day: calculation_day,
      corrected_source_day: open_day,
      legacy_rank: legacy_rank,
      corrected_rank: corrected_rank,
      changed: legacy_rank != corrected_rank,
      candidate_count: count,
      bowl: 1,
      seal: 11
    }
  end

  def diagnose(_calculation_day, _open_day, _count),
    do: raise(ArgumentError, "ngày tính, ngày mở hoặc số lượng năm không hợp lệ")
end
