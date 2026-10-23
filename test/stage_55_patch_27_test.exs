defmodule PastafariCalendarElixirVietnamese.Stage55Patch27Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese.Monster.{
    DistinctMonthNameIndices, LegacyNextMonthNameRank,
    MonthNameIndexManager, MonthNameRankPatch
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671
  @source @foundation + 1

  test "đúng bốn bộ RED của giai đoạn trước đều trở về GREEN" do
    for {delta, count} <- [{0, 1}, {7, 2}, {-7, 3}, {31, 4}] do
      c = @foundation + delta
      expected = Ref.choose_month_name_indices(Ref.sauce(c, @source), count)
      actual = MonthNameIndexManager.diagnose_count(c, @source, count)
      assert actual.month_name_indices == expected
      assert actual.corrected_month_name_rank == actual.month_name_rank
    end
  end

  test "di sản thật được gọi trước khi sửa" do
    for n <- 1..5 do
      total = DistinctMonthNameIndices.count(n)
      rank = div(total + 1, 2)
      patch = MonthNameRankPatch.diagnose(rank, total, n)
      assert patch.historical_rank == LegacyNextMonthNameRank.transform(rank, total)
    end
  end

  test "mọi hạng biên được khôi phục chính xác" do
    for n <- 1..5 do
      total = DistinctMonthNameIndices.count(n)
      for rank <- Enum.uniq([1, 2, div(total + 1, 2), total]) do
        result = MonthNameRankPatch.diagnose(rank, total, n)
        assert result.corrected_rank == rank
        assert result.corrected_names == DistinctMonthNameIndices.unrank(n, rank)
      end
    end
  end

  test "hạng lịch sử cuối trở về đầu và hạng đầu trở về cuối" do
    r = MonthNameRankPatch.diagnose(47, 47, 1)
    assert r.historical_rank == 1
    assert r.corrected_rank == 47
  end

  test "tên lịch sử luôn được giữ nguyên, kể cả qua ranh giới" do
    for n <- 1..4 do
      total = DistinctMonthNameIndices.count(n)
      r = MonthNameRankPatch.diagnose(total, total, n)
      assert r.historical_names == DistinctMonthNameIndices.unrank(n, 1)
      assert r.corrected_names == DistinctMonthNameIndices.unrank(n, total)
    end
  end

  test "bộ tên sửa đúng kích thước và không lặp" do
    for n <- 1..6 do
      total = DistinctMonthNameIndices.count(n)
      r = MonthNameRankPatch.diagnose(div(total + 1, 2), total, n)
      assert length(r.corrected_names) == n
      assert length(Enum.uniq(r.corrected_names)) == n
      assert Enum.all?(r.corrected_names, &(&1 in 1..47))
    end
  end

  test "không đổi bộ chỉ số tên năm trước" do
    c = @foundation + 5
    current = MonthNameIndexManager.diagnose(c, c)
    parent = PastafariCalendarElixirVietnamese.Monster.MonthWeavingManager.diagnose(c, c)
    assert current.cutlets == parent.cutlets
    assert current.month_lengths == parent.month_lengths
    assert current.month_weaving == parent.month_weaving
  end

  test "chạy lặp lại cho kết quả giống nhau" do
    a = MonthNameIndexManager.diagnose_count(@foundation, @source, 4)
    b = MonthNameIndexManager.diagnose_count(@foundation, @source, 4)
    assert a == b
  end

  test "mọi giới hạn hạng sai vẫn bị bác bỏ" do
    for bad <- [0, -1, nil, 48, 1.5] do
      assert_raise ArgumentError, fn -> MonthNameRankPatch.diagnose(bad, 47, 1) end
    end
  end

  test "mô-đun PATCH gọi đúng di sản, không dùng oracle" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    patch = File.read!(Path.join(root, "month_name_rank_patch.ex"))
    manager = File.read!(Path.join(root, "month_name_index_manager.ex"))
    assert patch =~ "LegacyNextMonthNameRank.transform(rank, total)"
    assert patch =~ "DistinctMonthNameIndices.unrank(count, historical_rank)"
    assert manager =~ "MonthNameRankPatch.diagnose(rank, total, month_count)"
    refute patch =~ "NormativeReference"
  end
end
