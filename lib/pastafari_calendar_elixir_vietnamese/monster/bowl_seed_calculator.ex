defmodule PastafariCalendarElixirVietnamese.Monster.BowlSeedCalculator do
  @moduledoc """
  Khởi tạo sáu bát định danh từ các bộ đếm ngày đã vá.

  Tính mỗi ID bát độc lập theo công thức chuẩn; chưa thêm lỗi
  các vị trí rót và không dùng kho trạng thái chung.
  """
  alias PastafariCalendarElixirVietnamese.Monster.SaveManager

  @bowl_primes [17, 19, 23, 29, 31, 37]

  def calculate(action_tag, target_tag, distance, direction)
      when is_integer(action_tag) and is_integer(target_tag) and
             is_integer(distance) and is_integer(direction) do
    connection = action_tag + target_tag

    Map.new(1..6, fn id ->
      prime = Enum.at(@bowl_primes, id - 1)
      seed = action_tag + target_tag * id + distance +
        connection + direction + prime * prime
      {id, SaveManager.calculate(seed * seed + id)}
    end)
  end
end
