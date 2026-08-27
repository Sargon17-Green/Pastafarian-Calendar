defmodule PastafariCalendarElixirVietnamese.Monster.Metrics do
  @moduledoc """
  Vỏ đo lường phi ngữ nghĩa. Giá trị đo không được đọc lại để quyết định kết quả lịch.
  """

  def bump(metrics, key) do
    Map.update(metrics, key, 1, &(&1 + 1))
  end
end
