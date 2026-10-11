defmodule PastafariCalendarElixirVietnamese.Monster.Dispatcher do
  @moduledoc """
  Bộ phân phối cơ sở bắt đầu mang nhánh SAVE lịch sử từ giai đoạn 2.

  Đường ngày lịch đầy đủ chưa được tích hợp. Nhánh SAVE được thực thi thật
  thông qua điểm vào sản xuất riêng để kiểm chứng sai lệch đầu tiên.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{Context, Metrics, SaveManager, Validator}

  def bootstrap(calculation_day, target_day) do
    Validator.require_integer_day!(calculation_day)
    Validator.require_integer_day!(target_day)

    %Context{
      calculation_day: calculation_day,
      target_day: target_day,
      phase: :bootstrap,
      status: :validated,
      branch_trace: [:entry, :validated],
      metrics: Metrics.bump(%{}, :bootstrap_calls),
      logs: [{:bootstrap, calculation_day, target_day}]
    }
  end

  def save_value(value), do: SaveManager.calculate(value)
end
