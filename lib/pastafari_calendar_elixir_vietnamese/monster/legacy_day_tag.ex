defmodule PastafariCalendarElixirVietnamese.Monster.LegacyDayTag do
  @moduledoc """
  Cách đánh số ngày cũ được đưa vào tại giai đoạn phát hiện thứ hai.

  Tác giả cũ giả định khoảng cách tuyệt đối đến Ngày Nền chỉ cần nhân đôi.
  Do đó tại ngày nền kết quả là 0, còn sau ngày nền kết quả luôn là số chẵn.
  Sai lệch cố ý được giữ ở đây cho đến giai đoạn bản vá 02.
  """

  @foundation_day -15_055_671

  def foundation_day, do: @foundation_day

  def old_day_tag(day) when is_integer(day) do
    2 * abs(day - @foundation_day)
  end
end
