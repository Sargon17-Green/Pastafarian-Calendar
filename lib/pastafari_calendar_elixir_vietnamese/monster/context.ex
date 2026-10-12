defmodule PastafariCalendarElixirVietnamese.Monster.Context do
  @moduledoc """
  Ngữ cảnh riêng cho một lần gọi, không dùng trạng thái ngữ nghĩa toàn cục.

  Nhãn ngày và khoảng cách đi qua các bản vá đã hoàn thành.
  Bảng đá đã qua bản vá 04 và bảy giọt ẩn qua bản vá 05.
  Giọt nhìn thấy đã qua bản vá 07; thứ tự sáu bát tại
  giai đoạn 16 vẫn dùng sai hạng hoán vị gốc không.
  Mỗi ngữ cảnh sở hữu dữ liệu của riêng mình.
  """

  defstruct calculation_day: nil,
            target_day: nil,
            calculation_day_tag: nil,
            target_day_tag: nil,
            distance_count: nil,
            stones_table: nil,
            hidden_drops_storage: nil,
            visible_drops: nil,
            bowl_orders: nil,
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
