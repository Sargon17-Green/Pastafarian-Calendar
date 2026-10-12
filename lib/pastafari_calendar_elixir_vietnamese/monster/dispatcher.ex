defmodule PastafariCalendarElixirVietnamese.Monster.Dispatcher do
  @moduledoc """
  Bộ phân phối sản xuất duy trì các nhánh SAVE và nhãn ngày đã được vá.

  Hai nhãn ngày, khoảng cách và bảng đá đã qua các bản vá cũ.
  Bảy giọt ẩn được đọc đúng qua bản vá 05; giọt nhìn thấy
  dùng bản vá 06 để tìm các ô trước ở kho ẩn hoặc kho nhìn thấy.
  Chưa tích hợp ngày lịch.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    Context,
    DayCountManager,
    DistanceManager,
    HiddenDropManager,
    Metrics,
    SaveManager,
    StoneManager,
    Validator,
    VisibleDropManager
  }

  def bootstrap(calculation_day, target_day) do
    Validator.require_integer_day!(calculation_day)
    Validator.require_integer_day!(target_day)

    calculation_tag = DayCountManager.tag(calculation_day)
    target_tag = DayCountManager.tag(target_day)
    corrected_distance = DistanceManager.calculate(calculation_day, target_day)
    stones_table = StoneManager.build_table()
    hidden_storage =
      HiddenDropManager.build_storage(
        calculation_day,
        target_day,
        calculation_tag,
        target_tag,
        corrected_distance,
        stones_table
      )

    visible_drops =
      VisibleDropManager.build(
        calculation_day,
        target_day,
        calculation_tag,
        target_tag,
        corrected_distance,
        stones_table,
        hidden_storage
      )

    %Context{
      calculation_day: calculation_day,
      target_day: target_day,
      calculation_day_tag: calculation_tag,
      target_day_tag: target_tag,
      distance_count: corrected_distance,
      stones_table: stones_table,
      hidden_drops_storage: hidden_storage,
      visible_drops: visible_drops,
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

  def hidden_drops(calculation_day, target_day) do
    bootstrap(calculation_day, target_day).hidden_drops_storage
  end

  def hidden_drop(calculation_day, target_day, number) do
    storage = hidden_drops(calculation_day, target_day)
    HiddenDropManager.read(storage, number)
  end

  def visible_drops(calculation_day, target_day) do
    bootstrap(calculation_day, target_day).visible_drops
  end

  def visible_drop(calculation_day, target_day, index) do
    visible_drops(calculation_day, target_day)
    |> VisibleDropManager.read(index)
  end
end
