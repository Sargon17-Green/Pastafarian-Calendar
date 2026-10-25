# Kiểm chứng vi sai: chỉ xuất chỉ số chuẩn, không đổi bộ máy production.
alias PastafariCalendarElixirVietnamese, as: Calendar
alias PastafariCalendarElixirVietnamese.SourceLanguageCatalog, as: Catalog

pairs = [
  {"foundation_same", -15_055_671, -15_055_671},
  {"foundation_next", -15_055_671, -15_055_670},
  {"foundation_previous", -15_055_671, -15_055_672},
  {"foundation_plus_seven", -15_055_664, -15_055_664},
  {"foundation_mixed", -15_055_669, -15_055_668}
]

for {label, c, t} <- pairs do
  {year, cutlet, cutlet_day, month, month_day} = Calendar.calendar_date_spaghetti(c, t)
  {cutlet_index, ^cutlet} =
    Enum.find(Catalog.cutlets(), fn {_index, name} -> name == cutlet end) ||
      raise("không tìm thấy cốt-lết")
  {month_index, ^month} =
    Enum.find(Catalog.months(), fn {_index, name} -> name == month end) ||
      raise("không tìm thấy tháng")

  IO.puts("DIFF\t#{label}\t#{c}\t#{t}\t#{year}\t#{cutlet_index}\t#{cutlet_day}\t#{month_index}\t#{month_day}")
end
