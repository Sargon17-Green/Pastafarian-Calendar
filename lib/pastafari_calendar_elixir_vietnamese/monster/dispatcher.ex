defmodule PastafariCalendarElixirVietnamese.Monster.Dispatcher do
  @moduledoc """
  Bộ phân phối sản xuất duy trì nhánh SAVE đã vá và nhánh nhãn ngày lịch sử.

  Việc tạo ngữ cảnh thực sự dùng bộ quản lý ngày sai ở giai đoạn 4.
  Chưa đưa vào lớp vá 02 hay việc tích hợp ngày lịch hoàn chỉnh.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    Context,
    DayCountManager,
    Metrics,
    SaveManager,
    Validator
  }

  def bootstrap(calculation_day, target_day) do
    Validator.require_integer_day!(calculation_day)
    Validator.require_integer_day!(target_day)

    calculation_tag = DayCountManager.tag(calculation_day)
    target_tag = DayCountManager.tag(target_day)

    %Context{
      calculation_day: calculation_day,
      target_day: target_day,
      calculation_day_tag: calculation_tag,
      target_day_tag: target_tag,
      phase: :bootstrap,
      status: :validated,
      branch_trace: [:entry, :validated, :legacy_day_count],
      metrics: Metrics.bump(%{}, :bootstrap_calls),
      logs: [{:bootstrap, calculation_day, target_day}, {:day_tags, calculation_tag, target_tag}]
    }
  end

  def save_value(value), do: SaveManager.calculate(value)
  def day_count(day), do: DayCountManager.tag(day)
end
