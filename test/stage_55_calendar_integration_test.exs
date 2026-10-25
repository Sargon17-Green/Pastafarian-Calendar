defmodule PastafariCalendarElixirVietnamese.Stage55CalendarIntegrationTest do
  # Dữ liệu năm dài rất lớn: tránh tranh CPU giữa các ca tích hợp.
  use ExUnit.Case, async: false

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.CalendarDateManager
  alias PastafariCalendarElixirVietnamese.SourceLanguageCatalog
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp kiểm_tra_ghep_ngay(c, t) do
    diagnostic = Calendar.calendar_date_diagnostic_spaghetti(c, t)
    {reference_year, _state} = Ref.find_target_year(c, t)

    assert diagnostic.year.number == reference_year.number
    assert diagnostic.year.open_gate_day == reference_year.open_gate_day
    assert diagnostic.year.close_gate_day == reference_year.close_gate_day

    # Kiểm tra tên tháng qua quy phạm mà không gọi bộ đếm đan tháng
    # đệ quy trên một năm dài.
    sauce = Ref.sauce(c, diagnostic.structure_source_day)
    expected_names = Ref.choose_month_name_indices(sauce, diagnostic.month_count)
    assert diagnostic.month_name_indices == expected_names

    chosen =
      Enum.find(diagnostic.cutlets, fn piece ->
        piece.first_day <= t and t <= piece.last_day
      end)

    assert chosen != nil
    offset = t - reference_year.open_gate_day - 1
    assert offset >= 0 and offset < length(diagnostic.month_weaving)
    month_id = Enum.at(diagnostic.month_weaving, offset)
    name_index = Enum.at(expected_names, month_id - 1)
    day_in_month =
      diagnostic.month_weaving
      |> Enum.take(offset + 1)
      |> Enum.count(&(&1 == month_id))

    expected = {
      reference_year.number,
      SourceLanguageCatalog.cutlet_name(chosen.name_index),
      t - chosen.first_day + 1,
      SourceLanguageCatalog.month_name(name_index),
      day_in_month
    }

    assert diagnostic.calendar_date == expected
    # Hàm công khai được thử riêng. Không dựng lại cả năm ở đây
    # chỉ để so cùng một kết quả đã có từ chẩn đoán.
  end

  test "ghép ngày tại mốc nền với nguồn quy phạm" do
    kiểm_tra_ghep_ngay(@foundation, @foundation)
  end

  test "ghép ngày tiếp theo với nguồn quy phạm" do
    kiểm_tra_ghep_ngay(@foundation + 1, @foundation + 1)
  end

  test "ghép ngày đích khác ngày tính trong năm" do
    kiểm_tra_ghep_ngay(@foundation + 2, @foundation + 3)
  end

  test "ghép ngày khác với nguồn quy phạm" do
    kiểm_tra_ghep_ngay(@foundation + 10, @foundation + 12)
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
