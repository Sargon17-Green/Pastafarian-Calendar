defmodule PastafariCalendarElixirVietnamese.Monster.MonthWeavingOrderPatch do
  @moduledoc """
  PATCH26 gọi thứ tự giảm từ di sản thật và lưu chuỗi lịch sử.
  Sau đó đảo thứ tự di sản về tăng dần để mở cùng hạng chuẩn.
  Không thay đầu vào, hạng, nguồn, hoặc bản thân di sản.
  """
  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyDescendingWeavingOrder, WeavingCombinatorics
  }

  def diagnose(lengths, rank) when is_list(lengths) do
    historical_order = LegacyDescendingWeavingOrder.labels(length(lengths))
    historical_weaving = WeavingCombinatorics.unrank(lengths, rank, historical_order)
    corrected_order = Enum.reverse(historical_order)
    corrected_weaving = WeavingCombinatorics.unrank(lengths, rank, corrected_order)

    %{historical_order: historical_order, historical_weaving: historical_weaving,
      corrected_order: corrected_order, corrected_weaving: corrected_weaving,
      rank: rank}
  end

  def diagnose(_, _), do: raise(ArgumentError, "danh sách tháng không hợp lệ")
end
