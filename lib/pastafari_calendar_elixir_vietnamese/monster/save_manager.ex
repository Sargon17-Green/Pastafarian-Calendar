defmodule PastafariCalendarElixirVietnamese.Monster.SaveManager do
  @moduledoc """
  Tầng điều phối phép SAVE bắt nguồn từ lần phát hiện thứ nhất.

  Không thay thế thiết kế lịch sử: chuyển yêu cầu qua lớp vá 01,
  còn phép dư sai được giữ lại và thực thi ở bên dưới lớp vá đó.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{SavePatch, Validator}

  def calculate(value) do
    Validator.require_integer_value!(value)
    SavePatch.save_patch(value)
  end
end
