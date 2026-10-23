defmodule PastafariCalendarElixirVietnamese do
  @moduledoc """
  Điểm vào sản xuất Elixir với tiếng Việt là ngôn ngữ nguồn.

  Giai đoạn 33 đã vá thứ tự năm 5000.
  PATCH 17 và PATCH 18 đã sửa năm kế và năm trước.
  Stage38 mở tìm năm đích nhưng để lộ lỗi biên đóng
  của năm. Chưa tích hợp lịch đầy đủ.
  """

  alias PastafariCalendarElixirVietnamese.Monster.Dispatcher

  def bootstrap_context(calculation_day, target_day) do
    Dispatcher.bootstrap(calculation_day, target_day)
  end

  def save_value_spaghetti(value) do
    Dispatcher.save_value(value)
  end

  def day_count_spaghetti(day) do
    Dispatcher.day_count(day)
  end

  def distance_spaghetti(calculation_day, target_day) do
    Dispatcher.distance(calculation_day, target_day)
  end

  def stones_table_spaghetti do
    Dispatcher.stones_table()
  end

  def stone_row_spaghetti(index) do
    Dispatcher.stone_row(index)
  end

  def hidden_drops_storage_spaghetti(calculation_day, target_day) do
    Dispatcher.hidden_drops(calculation_day, target_day)
  end

  def hidden_drop_spaghetti(calculation_day, target_day, number) do
    Dispatcher.hidden_drop(calculation_day, target_day, number)
  end

  def visible_drops_spaghetti(calculation_day, target_day) do
    Dispatcher.visible_drops(calculation_day, target_day)
  end

  def visible_drop_spaghetti(calculation_day, target_day, index) do
    Dispatcher.visible_drop(calculation_day, target_day, index)
  end

  def bowl_orders_spaghetti(calculation_day, target_day) do
    Dispatcher.bowl_orders(calculation_day, target_day)
  end

  def bowl_order_spaghetti(calculation_day, target_day, index) do
    Dispatcher.bowl_order(calculation_day, target_day, index)
  end

  def initial_bowls_spaghetti(calculation_day, target_day) do
    Dispatcher.initial_bowls(calculation_day, target_day)
  end

  def bowls_after_drops_spaghetti(calculation_day, target_day) do
    Dispatcher.bowls_after_drops(calculation_day, target_day)
  end

  def bowls_after_post_stirs_spaghetti(calculation_day, target_day) do
    Dispatcher.bowls_after_post_stirs(calculation_day, target_day)
  end

  def order_memory_spaghetti(calculation_day, target_day) do
    Dispatcher.order_memory(calculation_day, target_day)
  end

  def order_at_46_latch_spaghetti(calculation_day, target_day) do
    Dispatcher.order_at_46_latch(calculation_day, target_day)
  end

  def next_bowl_spaghetti(calculation_day, target_day, queried_bowl_id) do
    Dispatcher.next_bowl(calculation_day, target_day, queried_bowl_id)
  end

  def next_bowl_diagnostic_spaghetti(calculation_day, target_day, queried_bowl_id) do
    Dispatcher.next_bowl_diagnostic(calculation_day, target_day, queried_bowl_id)
  end

  def answer_stream_spaghetti(calculation_day, target_day, queried_bowl_id, seal) do
    Dispatcher.answer_stream(calculation_day, target_day, queried_bowl_id, seal)
  end

  def answer_at_spaghetti(calculation_day, target_day, queried_bowl_id, seal, k) do
    Dispatcher.answer_at(calculation_day, target_day, queried_bowl_id, seal, k)
  end

  def choose_rank_short_spaghetti(calculation_day, target_day, queried_bowl_id, seal, n) do
    Dispatcher.choose_rank_short(calculation_day, target_day, queried_bowl_id, seal, n)
  end

  def choose_rank_spaghetti(calculation_day, target_day, queried_bowl_id, seal, n) do
    Dispatcher.choose_rank(calculation_day, target_day, queried_bowl_id, seal, n)
  end

  def positive_gate_gap_spaghetti(n), do: Dispatcher.positive_gate_gap(n)
  def negative_gate_gap_spaghetti(n), do: Dispatcher.negative_gate_gap(n)
  def gate_day_spaghetti(index), do: Dispatcher.gate_day(index)
  def gate_state_spaghetti(index), do: Dispatcher.gate_state(index)

  def year5000_spaghetti(calculation_day), do: Dispatcher.year5000(calculation_day)
  def year5000_diagnostic_spaghetti(calculation_day), do: Dispatcher.year5000_diagnostic(calculation_day)

  def next_year_spaghetti(calculation_day), do: Dispatcher.next_year(calculation_day)
  def next_year_diagnostic_spaghetti(calculation_day), do: Dispatcher.next_year_diagnostic(calculation_day)

  def previous_year_spaghetti(day), do: Dispatcher.previous_year(day)
  def previous_year_diagnostic_spaghetti(day), do: Dispatcher.previous_year_diagnostic(day)

  def find_target_year_spaghetti(calculation_day, target_day),
    do: Dispatcher.find_target_year(calculation_day, target_day)

  def find_target_year_diagnostic_spaghetti(calculation_day, target_day),
    do: Dispatcher.find_target_year_diagnostic(calculation_day, target_day)

  def cutlet_count_spaghetti(calculation_day, target_day),
    do: Dispatcher.cutlet_count(calculation_day, target_day)

  def cutlet_count_diagnostic_spaghetti(calculation_day, target_day),
    do: Dispatcher.cutlet_count_diagnostic(calculation_day, target_day)

  def cutlet_partition_spaghetti(calculation_day, target_day),
    do: Dispatcher.cutlet_partition(calculation_day, target_day)

  def cutlet_partition_diagnostic_spaghetti(calculation_day, target_day),
    do: Dispatcher.cutlet_partition_diagnostic(calculation_day, target_day)

  def cutlet_name_indices_spaghetti(c, t), do: Dispatcher.cutlet_name_indices(c, t)
  def cutlet_name_indices_diagnostic_spaghetti(c, t), do: Dispatcher.cutlet_name_indices_diagnostic(c, t)

  def materialized_cutlets_spaghetti(c, t),
    do: Dispatcher.materialized_cutlets(c, t)

  def materialized_cutlets_diagnostic_spaghetti(c, t),
    do: Dispatcher.materialized_cutlets_diagnostic(c, t)

  def month_count_spaghetti(c, t),
    do: Dispatcher.month_count(c, t)

  def month_count_diagnostic_spaghetti(c, t),
    do: Dispatcher.month_count_diagnostic(c, t)

  def month_lengths_spaghetti(c, t),
    do: Dispatcher.month_lengths(c, t)

  def month_lengths_diagnostic_spaghetti(c, t),
    do: Dispatcher.month_lengths_diagnostic(c, t)

  def month_name_indices_spaghetti(c, t),
    do: Dispatcher.month_name_indices(c, t)

  def month_name_indices_diagnostic_spaghetti(c, t),
    do: Dispatcher.month_name_indices_diagnostic(c, t)

  def month_weaving_spaghetti(c, t), do: Dispatcher.month_weaving(c, t)

  def month_weaving_diagnostic_spaghetti(c, t),
    do: Dispatcher.month_weaving_diagnostic(c, t)

  def calendar_date_spaghetti(calculation_day, target_day),
    do: Dispatcher.calendar_date(calculation_day, target_day)

  def calendar_date_diagnostic_spaghetti(calculation_day, target_day),
    do: Dispatcher.calendar_date_diagnostic(calculation_day, target_day)
end
