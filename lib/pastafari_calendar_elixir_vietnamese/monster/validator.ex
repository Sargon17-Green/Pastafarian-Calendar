defmodule PastafariCalendarElixirVietnamese.Monster.Validator do
  @moduledoc """
  Lớp kiểm tra cơ sở của giai đoạn khởi tạo.
  """

  def require_integer_day!(value) when is_integer(value), do: :ok
  def require_integer_day!(_), do: raise(ArgumentError, "ngày phải là số nguyên chính xác")
end
