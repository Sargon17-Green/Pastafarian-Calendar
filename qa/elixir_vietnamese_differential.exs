# Kiểm chứng vi sai: chỉ xuất chỉ số chuẩn, không đổi bộ máy production.
alias PastafariCalendarElixirVietnamese, as: Calendar
alias PastafariCalendarElixirVietnamese.SourceLanguageCatalog, as: Catalog

pairs =
  Path.join(__DIR__, "differential_cases.tsv")
  |> File.stream!()
  |> Enum.reject(fn line -> String.trim(line) == "" or String.starts_with?(line, "#") end)
  |> Enum.map(fn line ->
    case String.trim(line) |> String.split("\t") do
      [label, c, t] -> {label, String.to_integer(c), String.to_integer(t)}
      _ -> raise("dòng kiểm tra vi sai không hợp lệ")
    end
  end)


for {label, c, t} <- pairs do
  IO.puts(:stderr, "ELIXIR_CASE_BEGIN #{label} #{c} #{t}")
  {year, cutlet, cutlet_day, month, month_day} = Calendar.calendar_date_spaghetti(c, t)
  {cutlet_index, ^cutlet} =
    Enum.find(Catalog.cutlets(), fn {_index, name} -> name == cutlet end) ||
      raise("không tìm thấy cốt-lết")
  {month_index, ^month} =
    Enum.find(Catalog.months(), fn {_index, name} -> name == month end) ||
      raise("không tìm thấy tháng")

  IO.puts("DIFF\t#{label}\t#{c}\t#{t}\t#{year}\t#{cutlet_index}\t#{cutlet_day}\t#{month_index}\t#{month_day}")
end
