defmodule PastafariCalendarElixirVietnamese.Monster.AscendingCutletCountPatch do
  @moduledoc """
  PATCH20: giữ việc gọi thật di sản đảo thứ tự số cốt-lết,
  rồi tái sắp theo số tăng dần (6 đến min(17,gaps)).
  Rank, tập hợp, nguồn ngày, bowl và seal vẫn nguyên.
  """
  alias PastafariCalendarElixirVietnamese.Monster.LegacyDescendingCutletCount

  def sort(candidates), do: diagnose(candidates).corrected_order

  def diagnose(candidates) when is_list(candidates) do
    historical_order = LegacyDescendingCutletCount.sort(candidates)
    corrected_order = Enum.sort(historical_order)
    %{historical_order: historical_order, corrected_order: corrected_order,
      candidate_count: length(candidates), changed: historical_order != corrected_order}
  end

  def diagnose(_), do: raise(ArgumentError, "danh sách số cốt-lết không hợp lệ")
end
