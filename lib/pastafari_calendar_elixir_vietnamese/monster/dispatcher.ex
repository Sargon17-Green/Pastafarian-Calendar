defmodule PastafariCalendarElixirVietnamese.Monster.Dispatcher do
  @moduledoc """
  Bộ phân phối sản xuất duy trì các nhánh SAVE và nhãn ngày đã được vá.

  Hai nhãn ngày đã được vá, nhưng khoảng cách trong ngữ cảnh
  còn được lấy sai từ hiệu giữa hai nhãn, theo phát hiện 03.
  Không đưa vào bản vá 03 hay tích hợp ngày lịch cuối cùng.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    Context,
    DayCountManager,
    DistanceManager,
    Metrics,
    SaveManager,
    Validator
  }

  def bootstrap(calculation_day, target_day) do
    Validator.require_integer_day!(calculation_day)
    Validator.require_integer_day!(target_day)

    calculation_tag = DayCountManager.tag(calculation_day)
    target_tag = DayCountManager.tag(target_day)
    raw_distance = DistanceManager.calculate(calculation_day, target_day)

    %Context{
      calculation_day: calculation_day,
      target_day: target_day,
      calculation_day_tag: calculation_tag,
      target_day_tag: target_tag,
      distance_count: raw_distance,
      phase: :bootstrap,
      status: :validated,
      branch_trace: [:entry, :validated, :legacy_day_count, :day_tag_patch_02],
      metrics: Metrics.bump(Metrics.bump(%{}, :bootstrap_calls), :legacy_distance_calls),
      logs: [{:bootstrap, calculation_day, target_day}, {:day_tags, calculation_tag, target_tag}]
    }
  end

  def save_value(value), do: SaveManager.calculate(value)
  def day_count(day), do: DayCountManager.tag(day)
  def distance(calculation_day, target_day),
    do: DistanceManager.calculate(calculation_day, target_day)
end
