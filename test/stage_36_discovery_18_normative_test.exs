defmodule PastafariCalendarElixirVietnamese.Stage36Discovery18NormativeTest do
  use ExUnit.Case, async: true
  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  @foundation -15_055_671

  defp reference(c) do
    {anchor, state} = Ref.year5000(c)
    {prev, _} = Ref.previous_year(c, anchor, state)
    Map.from_struct(prev)
  end
  defp production(c), do: Map.from_struct(Calendar.previous_year_spaghetti(c))

  test "hồi quy chuẩn đỏ 1: cũ trước mốc Foundation" do
    for delta <- [-539, -721, -417, -107] do
      c = @foundation + delta
      assert production(c) == reference(c)
    end
  end

  test "hồi quy chuẩn đỏ 2: gần Foundation bên phải" do
    for delta <- [1, 2, 3, 7] do
      c = @foundation + delta
      assert production(c) == reference(c)
    end
  end

  test "hồi quy chuẩn đỏ 3: xa hơn Foundation bên phải" do
    for delta <- [71, 417, 721, 1031] do
      c = @foundation + delta
      assert production(c) == reference(c)
    end
  end

  test "hồi quy chuẩn đỏ 4: quanh Foundation" do
    for delta <- [-2, -1, 0, 11] do
      c = @foundation + delta
      assert production(c) == reference(c)
    end
  end
end
