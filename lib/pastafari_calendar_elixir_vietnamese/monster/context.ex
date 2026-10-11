defmodule PastafariCalendarElixirVietnamese.Monster.Context do
  @moduledoc """
  Ngữ cảnh riêng cho một lần gọi, không dùng trạng thái ngữ nghĩa toàn cục.

  Từ giai đoạn 4, ngữ cảnh còn giữ hai nhãn ngày từ bộ đánh số lịch sử;
  đây là dữ liệu phát sinh trên đường sản xuất, chưa được sửa sai.
  """

  defstruct calculation_day: nil,
            target_day: nil,
            calculation_day_tag: nil,
            target_day_tag: nil,
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
