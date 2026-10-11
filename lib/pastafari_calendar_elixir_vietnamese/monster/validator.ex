defmodule PastafariCalendarElixirVietnamese.Monster.Validator do
  @moduledoc """
  Lớp kiểm tra giá trị nguyên chính xác cho ngữ cảnh ngày và nhánh SAVE.
  """

  def require_integer_day!(value) when is_integer(value), do: :ok
  def require_integer_day!(_), do: raise(ArgumentError, "ngày phải là số nguyên chính xác")

  def require_integer_value!(value) when is_integer(value), do: :ok
  def require_integer_value!(_), do: raise(ArgumentError, "giá trị phải là số nguyên chính xác")
end
