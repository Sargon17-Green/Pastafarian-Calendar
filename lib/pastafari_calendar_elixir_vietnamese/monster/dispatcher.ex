defmodule PastafariCalendarElixirVietnamese.Monster.Dispatcher do
  @moduledoc """
  Bộ phân phối sản xuất duy trì các nhánh SAVE và nhãn ngày đã được vá.

  Hai nhãn ngày đã được vá. Khoảng cách đi qua DistancePatch. Bảng đá được tính trong cùng
  ngữ cảnh bằng LegacyStoneMutation sai của lần phát hiện 04.
  Không có bản vá 04 hay ngày lịch cuối cùng.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    Context,
    DayCountManager,
    DistanceManager,
    Metrics,
    SaveManager,
    StoneManager,
    Validator
  }

  def bootstrap(calculation_day, target_day) do
    Validator.require_integer_day!(calculation_day)
    Validator.require_integer_day!(target_day)

    calculation_tag = DayCountManager.tag(calculation_day)
    target_tag = DayCountManager.tag(target_day)
    corrected_distance = DistanceManager.calculate(calculation_day, target_day)
    stones_table = StoneManager.build_table()

    %Context{
      calculation_day: calculation_day,
      target_day: target_day,
      calculation_day_tag: calculation_tag,
      target_day_tag: target_tag,
      distance_count: corrected_distance,
      stones_table: stones_table,
      phase: :bootstrap,
      status: :validated,
      branch_trace: [:entry, :validated, :legacy_day_count, :day_tag_patch_02],
      metrics:
        %{}
        |> Metrics.bump(:bootstrap_calls)
        |> Metrics.bump(:legacy_distance_calls)
        |> Metrics.bump(:distance_patch_03_calls),
      logs: [{:bootstrap, calculation_day, target_day}, {:day_tags, calculation_tag, target_tag}]
    }
  end

  def save_value(value), do: SaveManager.calculate(value)
  def day_count(day), do: DayCountManager.tag(day)
  def distance(calculation_day, target_day),
    do: DistanceManager.calculate(calculation_day, target_day)

  def stones_table, do: StoneManager.build_table()
  def stone_row(index), do: StoneManager.row_at(index)
end
