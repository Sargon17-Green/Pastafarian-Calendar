defmodule PastafariCalendarElixirVietnamese do
  @moduledoc """
  Điểm vào sản xuất Elixir với tiếng Việt là ngôn ngữ nguồn.

  Giai đoạn 26 bổ sung vòng đáp án chuẩn và nhánh chọn hạng
  ngắn dùng ngay phép dư legacy thiên lệch khi chưa loại bỏ.
  Các bản vá trước đều còn nguyên.
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

  def calendar_date_spaghetti(calculation_day, target_day) do
    _context = Dispatcher.bootstrap(calculation_day, target_day)
    raise StageNotIntegratedError
  end
end
