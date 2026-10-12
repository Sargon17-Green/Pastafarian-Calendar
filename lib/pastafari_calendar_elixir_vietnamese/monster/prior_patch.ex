defmodule PastafariCalendarElixirVietnamese.Monster.PriorPatch do
  @moduledoc """
  Bản vá 06 định tuyến giọt trước theo vị trí, giữ phép đọc cũ.

  Với địa chỉ dương, thực sự gọi LegacyPrior trong kho nhìn thấy.
  Với địa chỉ từ 0 đến -6, đọc giọt ẩn số 1-slot qua
  HiddenDropManager, vốn đã vá địa chỉ của kho đảo ở giai đoạn 11.
  Không hợp nhất hoặc đảo các kho, không dùng trạng thái toàn cục.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{HiddenDropManager, LegacyPrior}

  def read(visible_store, hidden_storage, index, back)
      when is_map(visible_store) and is_tuple(hidden_storage) and
             tuple_size(hidden_storage) == 7 and is_integer(index) and
             index in 1..46 and is_integer(back) and back in [1, 3, 7] do
    slot = index - back

    if slot >= 1 do
      LegacyPrior.legacy_prior(visible_store, index, back)
    else
      hidden_number = 1 - slot
      HiddenDropManager.read(hidden_storage, hidden_number)
    end
  end

  def read(_visible_store, _hidden_storage, _index, _back) do
    raise ArgumentError, "địa chỉ giọt trước phải hợp lệ với độ lùi 1, 3 hoặc 7"
  end
end
