defmodule PastafariCalendarElixirVietnamese.Monster.Context do
  @moduledoc """
  Ngữ cảnh riêng cho một lần gọi, không dùng trạng thái ngữ nghĩa toàn cục.

  Nhãn ngày và khoảng cách đi qua các bản vá đã hoàn thành.
  Bảng đá đã qua bản vá 04 và bảy giọt ẩn qua bản vá 05.
  Giọt, hoán vị và ba nguồn rót đã qua bản vá 09.
  Sáu phép khuấy đọc vaultOld cố định và ghi pending.
  Giai đoạn 22 lưu thứ tự cuối vào ô legacy ghi đè 58 lần,
  không có chốt riêng cho thứ tự ở giọt 46.
  Mỗi ngữ cảnh sở hữu dữ liệu riêng.
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
            initial_bowls: nil,
            bowls_after_drops: nil,
            bowls_after_post_stirs: nil,
            order_memory: nil,
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
