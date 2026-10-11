defmodule PastafariCalendarElixirVietnamese.Monster.HiddenStoragePatch do
  @moduledoc """
  Bản vá 05 giữ nguyên kho giọt ẩn đảo ngược, chỉ sửa địa chỉ đọc.

  Giọt có số k nằm tại vị trí 8-k trong kho lịch sử một-based.
  Phép đọc vẫn đi qua LegacyHiddenStorage thực; tuple không bị đảo lại.
  """

  alias PastafariCalendarElixirVietnamese.Monster.LegacyHiddenStorage

  def read_hidden(storage, number) when is_integer(number) and number in 1..7 do
    legacy_position = 8 - number
    LegacyHiddenStorage.read_as_if_forward(storage, legacy_position)
  end

  def read_hidden(_storage, _number) do
    raise ArgumentError, "số giọt ẩn phải từ 1 đến 7"
  end
end
