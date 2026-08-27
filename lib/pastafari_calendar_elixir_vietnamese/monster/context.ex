defmodule PastafariCalendarElixirVietnamese.Monster.Context do
  @moduledoc """
  Ngữ cảnh cơ sở của một lần gọi. Mỗi lần gọi sở hữu một giá trị riêng và không chia sẻ trạng thái ngữ nghĩa có thể thay đổi.
  """

  defstruct calculation_day: nil,
            target_day: nil,
            phase: :bootstrap,
            sub_phase: 0,
            mode: :authoritative_bootstrap,
            status: :new,
            branch_trace: [],
            metrics: %{},
            logs: [],
            diagnostics: [],
            last_error: nil
end
