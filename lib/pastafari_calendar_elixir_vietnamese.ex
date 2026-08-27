defmodule PastafariCalendarElixirVietnamese do
  @moduledoc """
  Điểm vào sản xuất của dòng triển khai Elixir với tiếng Việt là ngôn ngữ nguồn.

  Giai đoạn 1 chỉ dựng hạ tầng trung tính. Hàm lịch cố ý chưa trả kết quả và không gọi bộ tham chiếu chỉ dành cho kiểm thử.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{Dispatcher, StageNotIntegratedError}

  def bootstrap_context(calculation_day, target_day) do
    Dispatcher.bootstrap(calculation_day, target_day)
  end

  def calendar_date_spaghetti(calculation_day, target_day) do
    _context = Dispatcher.bootstrap(calculation_day, target_day)
    raise StageNotIntegratedError
  end
end
