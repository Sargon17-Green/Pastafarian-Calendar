defmodule PastafariCalendarElixirVietnamese.Monster.CutletNameRankPatch do
  @moduledoc """
  PATCH22 giữ nguyên chứng tích di sản xoay rank tên cốt-lết
  một bước. Hàm chẩn đoán gọi thật phép chọn legacy trước,
  rồi hỏi đúng lại cùng ngày, bát 5 và chốt 22 theo rank
  một-based. Không sửa số tên, thứ tự từ điển hoặc phân hoạch.
  """
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, Dispatcher, LegacyRotatedCutletNameRank
  }

  def choose_rank(c, first_day, count),
    do: diagnose(c, first_day, count).corrected_rank

  def diagnose(c, first_day, count)
      when is_integer(c) and is_integer(first_day) and
           is_integer(count) and count >= 1 do
    historical_rank = LegacyRotatedCutletNameRank.choose_rank(c, first_day, count)
    stream = Dispatcher.answer_stream(c, first_day, 5, 22)
    corrected_rank = AnswerStreamManager.choose_rank(stream, count)
    %{calculation_day: c, structure_source_day: first_day,
      bowl: 5, seal: 22, candidate_count: count,
      historical_rank: historical_rank, corrected_rank: corrected_rank,
      changed: historical_rank != corrected_rank}
  end

  def diagnose(_, _, _),
    do: raise(ArgumentError, "ngày tính, ngày hỏi hoặc số lựa chọn không hợp lệ")
end
