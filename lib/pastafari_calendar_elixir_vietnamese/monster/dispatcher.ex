defmodule PastafariCalendarElixirVietnamese.Monster.Dispatcher do
  @moduledoc """
  Bộ phân phối trung tính của giai đoạn 1. Nó chỉ đi qua kiểm tra đầu vào và không chứa logic của bất kỳ bản vá tương lai nào.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{Context, Metrics, Validator}

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
end
