defmodule PastafariCalendarElixirVietnamese do
  @moduledoc """
  Điểm vào sản xuất Elixir với tiếng Việt là ngôn ngữ nguồn.

  Giai đoạn 22 tính đủ 12 lần khuấy sau 46 giọt,
  nhưng truy vấn bát kế tiếp đọc ô thứ tự bị ghi đè
  thay vì thứ tự gốc của giọt 46. Các bản vá cũ được giữ.
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

  def next_bowl_spaghetti(calculation_day, target_day, queried_bowl_id) do
    Dispatcher.next_bowl(calculation_day, target_day, queried_bowl_id)
  end

  def calendar_date_spaghetti(calculation_day, target_day) do
    _context = Dispatcher.bootstrap(calculation_day, target_day)
    raise StageNotIntegratedError
  end
end
