defmodule PastafariCalendarElixirVietnamese.Stage55CalendarIntegrationTest do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.CalendarDateManager
  alias PastafariCalendarElixirVietnamese.SourceLanguageCatalog
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  test "ngày mốc khớp công thức quy phạm từ đầu đến cuối" do
    for {c, t} <- [
      {@foundation, @foundation},
      {@foundation + 1, @foundation + 1},
      {@foundation + 7, @foundation + 7}
    ] do
      assert Calendar.calendar_date_spaghetti(c, t) == Ref.calendar_date(c, t)
    end
  end

  test "ngày đích khác ngày tính vẫn khớp quy phạm" do
    for {c, t} <- [
      {@foundation + 2, @foundation + 3},
      {@foundation + 10, @foundation + 12}
    ] do
      assert Calendar.calendar_date_spaghetti(c, t) == Ref.calendar_date(c, t)
    end
  end

  test "kết quả luôn là bộ năm thành phần có ngày dương" do
    {year, cutlet, day_cutlet, month, day_month} =
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    assert is_integer(year)
    assert is_binary(cutlet)
    assert day_cutlet >= 1
    assert is_binary(month)
    assert day_month >= 1
  end

  test "danh mục tiếng Việt là nguồn tên duy nhất" do
    c = @foundation + 1
    diag = Calendar.calendar_date_diagnostic_spaghetti(c, c)
    assert elem(diag.calendar_date, 1) == SourceLanguageCatalog.cutlet_name(diag.cutlet_name_index)
    assert elem(diag.calendar_date, 3) == SourceLanguageCatalog.month_name(diag.month_name_index)
    assert diag.day_in_month == elem(diag.calendar_date, 4)
    assert diag.day_in_cutlet == elem(diag.calendar_date, 2)
  end

  test "định danh ngày được lấy từ cùng một năm đã chọn" do
    c = @foundation + 2
    diag = CalendarDateManager.diagnose(c, c)
    assert diag.target_day == c
    assert diag.structure_source_day == diag.year.open_gate_day + 1
    assert length(diag.month_weaving) == diag.year_length
    assert length(diag.month_name_indices) == diag.month_count
    assert length(Enum.uniq(diag.month_name_indices)) == diag.month_count
  end

  test "đầu vào không phải số ngày nguyên bị bác bỏ" do
    for bad <- [nil, "1", 1.5, %{}] do
      assert_raise ArgumentError, fn -> Calendar.calendar_date_spaghetti(bad, @foundation) end
      assert_raise ArgumentError, fn -> Calendar.calendar_date_spaghetti(@foundation, bad) end
    end
  end

  test "sản xuất không gọi bộ tham chiếu thử nghiệm" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    source = File.read!(Path.join(root, "calendar_date_manager.ex"))
    refute source =~ "NormativeReference"
    assert source =~ "MonthNameIndexManager.diagnose(c, t)"
    assert source =~ "SourceLanguageCatalog.cutlet_name"
    assert source =~ "SourceLanguageCatalog.month_name"
  end
end
