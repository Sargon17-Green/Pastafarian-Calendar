defmodule PastafariCalendarElixirVietnamese.Monster.Year5000Manager do
  @moduledoc """
  Chọn năm neo 5000 từ các cặp cổng hợp lệ.
  Stage32: danh sách ứng viên và rank là chuẩn,
  nhưng thứ tự dùng LegacyLongestFirstYear5000
  theo độ dài giảm dần, cố ý cho kết quả sai.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    Dispatcher,
    LegacyLongestFirstYear5000,
    Year,
    Year5000CandidateManager
  }

  @bowl 1
  @seal 10

  def year5000(calculation_day), do: diagnose(calculation_day).year

  def diagnose(calculation_day) when is_integer(calculation_day) do
    {candidates, state} = Year5000CandidateManager.build(calculation_day)
    if candidates == [], do: raise(ArgumentError, "không tìm thấy năm neo 5000")

    historical_order = LegacyLongestFirstYear5000.sort(candidates)
    stream = Dispatcher.answer_stream(calculation_day, calculation_day, @bowl, @seal)
    rank = AnswerStreamManager.choose_rank(stream, length(candidates))
    selected = Enum.at(historical_order, rank - 1)

    year = %Year{
      number: 5000,
      open_gate_index: selected.open_gate_index,
      close_gate_index: selected.close_gate_index,
      open_gate_day: selected.open_gate_day,
      close_gate_day: selected.close_gate_day
    }

    %{year: year, gate_state: state, candidates: candidates,
      historical_order: historical_order, candidate_count: length(candidates),
      rank: rank, bowl: @bowl, seal: @seal}
  end

  def diagnose(_), do: raise(ArgumentError, "ngày tính phải là số nguyên")
end
