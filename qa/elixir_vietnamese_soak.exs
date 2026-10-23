defmodule PastafariCalendarElixirVietnamese.QaSoak55 do
  use ExUnit.Case, async: false
  @moduletag timeout: 240_000

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    DistinctMonthNameIndices, WeavingCombinatorics
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp đo(thông_báo, fun) do
    {microseconds, result} = :timer.tc(fun)
    IO.puts("ĐO_SOAK #{thông_báo}: #{microseconds} micro giây")
    result
  end

  defp kiểm_tra_dan(dãy, độ_dài) do
    assert length(dãy) == Enum.sum(độ_dài)
    for {số_ngày, nhãn} <- Enum.with_index(độ_dài, 1) do
      assert Enum.count(dãy, &(&1 == nhãn)) == số_ngày
    end
    k = length(độ_dài)
    đầu = Enum.map(1..k, fn nhãn -> Enum.find_index(dãy, &(&1 == nhãn)) end)
    cuối = Enum.map(1..k, fn nhãn ->
      length(dãy) - 1 - Enum.find_index(Enum.reverse(dãy), &(&1 == nhãn))
    end)
    assert đầu == Enum.sort(đầu)
    assert cuối == Enum.sort(cuối)
  end

  test "năm cực đại 5778 ngày: đếm chính xác và mở hai biên" do
    lengths = List.duplicate(123, 46) ++ [120]
    assert Enum.sum(lengths) == 5778
    total = đo("đếm 47 tháng, 5778 ngày", fn ->
      WeavingCombinatorics.count(lengths)
    end)
    assert is_integer(total) and total > 1

    for {name, rank} <- [{"hạng đầu", 1}, {"hạng cuối", total}] do
      sequence = đo(name, fn -> WeavingCombinatorics.unrank(lengths, rank) end)
      kiểm_tra_dan(sequence, lengths)
    end
  end

  test "tập ngắn: hạng biên và giữa tương đương tham chiếu" do
    for lengths <- [[4, 4], [4, 5], [4, 4, 4], [4, 5, 4]] do
      n = WeavingCombinatorics.count(lengths)
      for rank <- Enum.uniq([1, 2, div(n + 1, 2), n]) do
        actual = WeavingCombinatorics.unrank(lengths, rank)
        assert actual == Ref.unrank_weaving(lengths, rank)
      end
    end
  end

  test "47 tên tháng: hạng cực đại và bảo toàn phân biệt" do
    total = DistinctMonthNameIndices.count(47)
    assert total == Enum.reduce(1..47, 1, &(&1 * &2))
    assert DistinctMonthNameIndices.unrank(47, 1) == Enum.to_list(1..47)
    assert DistinctMonthNameIndices.unrank(47, total) == Enum.to_list(47..1//-1)
  end

  test "lịch đầy đủ: nhiều hướng ngày và sự nhất quán nội tại" do
    pairs = [
      {@foundation - 365, @foundation - 365},
      {@foundation - 7, @foundation - 6},
      {@foundation, @foundation},
      {@foundation + 2, @foundation + 3},
      {@foundation + 30, @foundation + 29},
      {@foundation + 365, @foundation + 365}
    ]

    for {c, t} <- pairs do
      d = đo("ngày #{c} -> #{t}", fn ->
        Calendar.calendar_date_diagnostic_spaghetti(c, t)
      end)
      assert d.calculation_day == c
      assert d.target_day == t
      assert d.year.open_gate_day < t and t <= d.year.close_gate_day
      assert length(d.month_weaving) == d.year_length
      assert Enum.sum(d.month_lengths) == d.year_length
      assert length(d.month_name_indices) == d.month_count
      assert length(Enum.uniq(d.month_name_indices)) == d.month_count
      assert is_tuple(d.calendar_date) and tuple_size(d.calendar_date) == 5
      assert elem(d.calendar_date, 2) >= 1
      assert elem(d.calendar_date, 4) >= 1
    end
  end
end
