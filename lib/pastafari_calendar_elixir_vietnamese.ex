defmodule PastafariCalendarElixirVietnamese do
  @moduledoc """
  Điểm vào sản xuất Elixir với tiếng Việt là ngôn ngữ nguồn.

  Giai đoạn 19 vá nguồn rót qua ánh xạ vị trí tới ID
  bát, vẫn gọi legacy nguyên bản. Các bản vá 01-08 còn nguyên.
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

  def calendar_date_spaghetti(calculation_day, target_day) do
    _context = Dispatcher.bootstrap(calculation_day, target_day)
    raise StageNotIntegratedError
  end
end
