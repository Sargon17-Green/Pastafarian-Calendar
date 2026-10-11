defmodule PastafariCalendarElixirVietnamese.Monster.HiddenDropManager do
  @moduledoc """
  Tạo các giọt ẩn đúng về số học, nhưng lưu và đọc bằng cách cũ sai.

  Không đảo lại tuple và không thêm hàm truy cập vá 05 trong giai đoạn
  khám phá này. Trạng thái tính riêng cho mỗi lời gọi.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    HiddenDropCalculator,
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

  def read(storage, number), do: LegacyHiddenStorage.read_as_if_forward(storage, number)
end
