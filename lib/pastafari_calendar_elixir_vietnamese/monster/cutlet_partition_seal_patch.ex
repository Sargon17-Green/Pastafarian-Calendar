defmodule PastafariCalendarElixirVietnamese.Monster.CutletPartitionSealPatch do
  @moduledoc """
  PATCH21: gọi thật di sản hỏi sai chốt 20 khi chọn phân hoạch,
  ghi hạng lịch sử; sau đó hỏi lại cùng hai ngày, bát 2
  với chốt 21 chuẩn. Không thay đếm hoặc mở hạng từ điển.
  """
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, Dispatcher, LegacyCutletPartitionCountSeal
  }

  def choose_rank(c, first_day, count),
    do: diagnose(c, first_day, count).corrected_rank

  def diagnose(c, first_day, count)
      when is_integer(c) and is_integer(first_day) and
           is_integer(count) and count >= 1 do
    legacy_rank = LegacyCutletPartitionCountSeal.choose_rank(c, first_day, count)
    stream = Dispatcher.answer_stream(c, first_day, 2, 21)
    corrected_rank = AnswerStreamManager.choose_rank(stream, count)
    %{calculation_day: c, structure_source_day: first_day,
      bowl: 2, historical_seal: 20, normative_seal: 21,
      candidate_count: count, legacy_rank: legacy_rank,
      corrected_rank: corrected_rank,
      changed: legacy_rank != corrected_rank}
  end

  def diagnose(_, _, _),
    do: raise(ArgumentError, "ngày tính, ngày hỏi hoặc số lựa chọn không hợp lệ")
end
