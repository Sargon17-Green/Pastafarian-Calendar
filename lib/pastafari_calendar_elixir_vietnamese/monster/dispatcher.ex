defmodule PastafariCalendarElixirVietnamese.Monster.Dispatcher do
  @moduledoc """
  Bộ phân phối sản xuất duy trì các nhánh SAVE và nhãn ngày đã được vá.

  Hai nhãn ngày, khoảng cách và bảng đá đã qua các bản vá cũ.
  Bảy giọt ẩn và 46 giọt nhìn thấy đều được tính đúng.
  Giai đoạn 26 tính vòng đáp án đúng từ sáu bát, ID kế cận
  chuẩn và dấu hỏi, nhưng lựa chọn hạng ngắn còn gọi ngay
  LegacyBiasedPick không loại bỏ giá trị vượt ngưỡng.
  Các bản vá trước vẫn đúng; chưa tích hợp lịch.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    BowlOrderManager,
    BowlSeedCalculator,
    BowlDropCalculator,
    AnswerStreamManager,
    Context,
    DayCountManager,
    DistanceManager,
    HiddenDropManager,
    Metrics,
    NextBowlPatchWrapper,
    OrderAt46LatchPatch,
    SaveManager,
    PostStirCalculator,
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

    bowl_orders = BowlOrderManager.build_orders(visible_drops)

    direction =
      cond do
        target_day < calculation_day -> 1
        target_day == calculation_day -> 2
        true -> 3
      end

    initial_bowls =
      BowlSeedCalculator.calculate(
        calculation_tag, target_tag, corrected_distance, direction
      )

    {bowls_after_drops, memory_after_drops} =
      BowlDropCalculator.apply_all_with_order_memory(
        initial_bowls, visible_drops, bowl_orders, stones_table
      )

    order_at_46_latch = OrderAt46LatchPatch.capture(memory_after_drops)

    {bowls_after_post_stirs, order_memory} =
      PostStirCalculator.apply_all(bowls_after_drops, memory_after_drops)

    %Context{
      calculation_day: calculation_day,
      target_day: target_day,
      calculation_day_tag: calculation_tag,
      target_day_tag: target_tag,
      distance_count: corrected_distance,
      stones_table: stones_table,
      hidden_drops_storage: hidden_storage,
      visible_drops: visible_drops,
      bowl_orders: bowl_orders,
      initial_bowls: initial_bowls,
      bowls_after_drops: bowls_after_drops,
      bowls_after_post_stirs: bowls_after_post_stirs,
      order_memory: order_memory,
      order_at_46_latch: order_at_46_latch,
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

  def bowl_orders(calculation_day, target_day) do
    bootstrap(calculation_day, target_day).bowl_orders
  end

  def bowl_order(calculation_day, target_day, index) do
    bowl_orders(calculation_day, target_day)
    |> BowlOrderManager.read_order(index)
  end

  def initial_bowls(calculation_day, target_day) do
    bootstrap(calculation_day, target_day).initial_bowls
  end

  def bowls_after_drops(calculation_day, target_day) do
    bootstrap(calculation_day, target_day).bowls_after_drops
  end

  def bowls_after_post_stirs(calculation_day, target_day) do
    bootstrap(calculation_day, target_day).bowls_after_post_stirs
  end

  def order_memory(calculation_day, target_day) do
    bootstrap(calculation_day, target_day).order_memory
  end

  def order_at_46_latch(calculation_day, target_day) do
    bootstrap(calculation_day, target_day).order_at_46_latch
  end

  def next_bowl(calculation_day, target_day, queried_bowl_id) do
    order_at_46_latch(calculation_day, target_day)
    |> NextBowlPatchWrapper.next_bowl(queried_bowl_id)
  end

  def next_bowl_diagnostic(calculation_day, target_day, queried_bowl_id) do
    order_at_46_latch(calculation_day, target_day)
    |> NextBowlPatchWrapper.diagnose(queried_bowl_id)
  end

  def answer_stream(calculation_day, target_day, queried_bowl_id, seal) do
    context = bootstrap(calculation_day, target_day)

    next_id =
      NextBowlPatchWrapper.next_bowl(context.order_at_46_latch, queried_bowl_id)

    AnswerStreamManager.build(
      context.bowls_after_post_stirs, queried_bowl_id, next_id, seal
    )
  end

  def answer_at(calculation_day, target_day, queried_bowl_id, seal, k) do
    answer_stream(calculation_day, target_day, queried_bowl_id, seal)
    |> AnswerStreamManager.answer_at(k)
  end

  def choose_rank_short(calculation_day, target_day, queried_bowl_id, seal, n) do
    answer_stream(calculation_day, target_day, queried_bowl_id, seal)
    |> AnswerStreamManager.choose_rank_short_biased(n)
  end
end
