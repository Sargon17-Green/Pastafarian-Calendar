defmodule PastafariCalendarElixirVietnamese do
  @moduledoc """
  Điểm vào sản xuất của dòng triển khai Elixir với tiếng Việt là ngôn ngữ nguồn.

  Giai đoạn 3 bổ sung lớp vá SAVE bên trên phần dư lịch sử của giai đoạn 2.
  Hàm ngày lịch đầy đủ vẫn chưa được tích hợp và không gọi bộ tham chiếu kiểm thử.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{Dispatcher, StageNotIntegratedError}

  def bootstrap_context(calculation_day, target_day) do
    Dispatcher.bootstrap(calculation_day, target_day)
  end

  def save_value_spaghetti(value) do
    Dispatcher.save_value(value)
  end

  def calendar_date_spaghetti(calculation_day, target_day) do
    _context = Dispatcher.bootstrap(calculation_day, target_day)
    raise StageNotIntegratedError
  end
end
