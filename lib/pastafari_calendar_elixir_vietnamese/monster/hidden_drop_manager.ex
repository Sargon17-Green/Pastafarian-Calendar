defmodule PastafariCalendarElixirVietnamese.Monster.HiddenDropManager do
  @moduledoc """
  Bộ quản lý giọt ẩn giữ kho lịch sử đảo ngược qua bản vá 05.

  Tính toán và cách lưu của phát hiện 05 không thay đổi.
  Chỉ mọi lần đọc giọt theo số k mới đi qua ánh xạ địa chỉ 8-k.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    HiddenDropCalculator,
    HiddenStoragePatch,
    LegacyHiddenStorage
  }

  def build_storage(calculation_day, target_day, action_tag, target_tag, distance, stones) do
    HiddenDropCalculator.calculate(
      calculation_day,
      target_day,
      action_tag,
      target_tag,
      distance,
      stones
    )
    |> LegacyHiddenStorage.store_reversed()
  end

  def read(storage, number), do: HiddenStoragePatch.read_hidden(storage, number)
end
