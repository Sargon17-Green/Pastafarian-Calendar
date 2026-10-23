defmodule PastafariCalendarElixirVietnamese.Monster.CalendarDateManager do
  @moduledoc """
  Ghép năm, tên cốt-lết, ngày trong cốt-lết, tên tháng
  và ngày trong tháng thành bộ năm thành phần chuẩn.
  Giữ nguyên cấu trúc năm và lựa chọn tên đã sửa.
  """

  alias PastafariCalendarElixirVietnamese.Monster.MonthNameIndexManager
  alias PastafariCalendarElixirVietnamese.SourceLanguageCatalog

  def date(c, t), do: diagnose(c, t).calendar_date

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = MonthNameIndexManager.diagnose(c, t)
    year = parent.year

    chosen =
      Enum.find(parent.cutlets, fn piece ->
        piece.first_day <= t and t <= piece.last_day
      end) || raise(ArgumentError, "ngày đích không nằm trong cốt-lết nào")

    offset = t - year.open_gate_day - 1

    unless offset >= 0 and offset < length(parent.month_weaving) do
      raise ArgumentError, "ngày đích nằm ngoài năm đã chọn"
    end

    month_id = Enum.at(parent.month_weaving, offset)
    month_name_index = Enum.at(parent.month_name_indices, month_id - 1)
    day_in_cutlet = t - chosen.first_day + 1

    day_in_month =
      parent.month_weaving
      |> Enum.take(offset + 1)
      |> Enum.count(&(&1 == month_id))

    tuple = {
      year.number,
      SourceLanguageCatalog.cutlet_name(chosen.name_index),
      day_in_cutlet,
      SourceLanguageCatalog.month_name(month_name_index),
      day_in_month
    }

    Map.merge(parent, %{
      calendar_date: tuple,
      cutlet_name_index: chosen.name_index,
      month_id: month_id,
      month_name_index: month_name_index,
      day_in_cutlet: day_in_cutlet,
      day_in_month: day_in_month
    })
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
