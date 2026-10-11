defmodule PastafariCalendarElixirVietnamese do
  @moduledoc """
  Điểm vào sản xuất của dòng triển khai Elixir với tiếng Việt là ngôn ngữ nguồn.

  Giai đoạn 4 cố ý mang nhãn ngày lịch sử sai vào ngữ cảnh thực thi.
  Lớp vá SAVE từ giai đoạn 3 vẫn hoạt động; ngày lịch đầy đủ chưa tích hợp.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{Dispatcher, StageNotIntegratedError}

  def bootstrap_context(calculation_day, target_day) do
    Dispatcher.bootstrap(calculation_day, target_day)
  end

  def save_value_spaghetti(value) do
    Dispatcher.save_value(value)
  end

  def day_count_spaghetti(day) do
    Dispatcher.day_count(day)
  end

  def calendar_date_spaghetti(calculation_day, target_day) do
    _context = Dispatcher.bootstrap(calculation_day, target_day)
    raise StageNotIntegratedError
  end
end
