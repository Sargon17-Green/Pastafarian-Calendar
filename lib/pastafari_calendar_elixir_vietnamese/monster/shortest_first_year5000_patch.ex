defmodule PastafariCalendarElixirVietnamese.Monster.ShortestFirstYear5000Patch do
  @moduledoc """
  Bản vá 16: chọn năm neo theo độ dài tăng dần, khi bằng
  nhau lấy ngày mở sớm hơn. Mô-đun này phải gọi thật
  LegacyLongestFirstYear5000 để bảo toàn chứng cứ sai
  lịch sử, sau đó mới sắp lại các ứng viên theo chuẩn.
  Không động tới nguồn cổng, danh sách ứng viên hoặc rank.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyLongestFirstYear5000

  def sort(candidates), do: diagnose(candidates).corrected_order

  def diagnose(candidates) when is_list(candidates) do
    historical_order = LegacyLongestFirstYear5000.sort(candidates)

    corrected_order =
      Enum.sort_by(historical_order, fn candidate ->
        {candidate.length, candidate.open_gate_day}
      end)

    %{
      historical_order: historical_order,
      corrected_order: corrected_order,
      candidate_count: length(candidates),
      changed: historical_order != corrected_order
    }
  end

  def diagnose(_candidates) do
    raise ArgumentError, "danh sách năm ứng viên không hợp lệ"
  end
end
