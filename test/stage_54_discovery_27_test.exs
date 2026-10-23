defmodule PastafariCalendarElixirVietnamese.Stage54Discovery27Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, DistinctMonthNameIndices,
    LegacyNextMonthNameRank, MonthNameIndexManager
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671
  @source @foundation + 1

  defp oracle(c, k) do
    Ref.choose_month_name_indices(Ref.sauce(c, @source), k)
  end

  test "số lựa chọn một tên bằng 47" do
    assert DistinctMonthNameIndices.count(1) == 47
  end

  test "số lựa chọn hai và ba tên phân biệt" do
    assert DistinctMonthNameIndices.count(2) == 47 * 46
    assert DistinctMonthNameIndices.count(3) == 47 * 46 * 45
  end

  test "không gian 47 tên chính xác với số nguyên lớn" do
    assert DistinctMonthNameIndices.count(47) ==
      Enum.reduce(1..47, 1, fn x, n -> x * n end)
  end

  test "hạng đầu theo thứ tự từ điển" do
    assert DistinctMonthNameIndices.unrank(3, 1) == [1, 2, 3]
    assert DistinctMonthNameIndices.unrank(47, 1) == Enum.to_list(1..47)
  end

  test "hạng cuối theo thứ tự từ điển" do
    assert DistinctMonthNameIndices.unrank(2, 47 * 46) == [47, 46]
    assert DistinctMonthNameIndices.unrank(47, DistinctMonthNameIndices.count(47)) ==
      Enum.to_list(47..1//-1)
  end

  test "mở hạng độc lập cho các hạng rải rác" do
    for k <- 1..4 do
      n = DistinctMonthNameIndices.count(k)
      for rank <- Enum.uniq([1, 2, div(n + 1, 2), n]) do
        assert DistinctMonthNameIndices.unrank(k, rank) ==
          Ref.unrank_distinct_indices(47, k, rank)
      end
    end
  end

  test "mọi tên đều phân biệt và nằm trong miền 1..47" do
    for k <- 1..5 do
      result = DistinctMonthNameIndices.unrank(k, div(DistinctMonthNameIndices.count(k) + 1, 2))
      assert length(result) == k
      assert length(Enum.uniq(result)) == k
      assert Enum.all?(result, &(&1 in 1..47))
    end
  end

  test "di sản quay hạng tiến lên một bước và quay về 1 ở cuối" do
    assert LegacyNextMonthNameRank.transform(1, 47) == 2
    assert LegacyNextMonthNameRank.transform(47, 47) == 1
    assert LegacyNextMonthNameRank.transform(5, 47) == 6
  end

  test "di sản không thay số lượng các lựa chọn" do
    for k <- 1..4 do
      n = DistinctMonthNameIndices.count(k)
      for rank <- [1, div(n + 1, 2), n] do
        h = LegacyNextMonthNameRank.transform(rank, n)
        assert h in 1..n
      end
    end
  end

  test "thứ tự lịch sử lấy hạng thực sự qua di sản" do
    r = MonthNameIndexManager.diagnose_count(@foundation, @source, 3)
    assert r.historical_month_name_rank ==
      LegacyNextMonthNameRank.transform(r.month_name_rank, r.month_name_candidate_count)
    assert r.historical_month_name_indices ==
      DistinctMonthNameIndices.unrank(3, r.historical_month_name_rank)
    assert r.month_name_indices == DistinctMonthNameIndices.unrank(3, r.month_name_rank)
  end

  test "bát 5 và chốt 33 lấy hạng một-based" do
    r = MonthNameIndexManager.diagnose_count(@foundation, @source, 3)
    stream = Calendar.answer_stream_spaghetti(@foundation, @source, 5, 33)
    assert r.month_name_bowl == 5
    assert r.month_name_seal == 33
    assert r.month_name_rank ==
      AnswerStreamManager.choose_rank(stream, r.month_name_candidate_count)
  end

  test "không đổi tên, cốt-lết hoặc số tháng của bước trước" do
    c = @foundation + 5
    result = MonthNameIndexManager.diagnose(c, c)
    parent = PastafariCalendarElixirVietnamese.Monster.MonthWeavingManager.diagnose(c, c)
    assert result.year == parent.year
    assert result.cutlets == parent.cutlets
    assert result.month_count == parent.month_count
    assert result.month_lengths == parent.month_lengths
    assert result.month_weaving == parent.month_weaving
  end

  test "đầu vào sai bị từ chối" do
    for bad <- [0, -1, 48, nil, "3"] do
      assert_raise ArgumentError, fn -> DistinctMonthNameIndices.count(bad) end
    end
    for rank <- [0, -1, nil, 48] do
      assert_raise ArgumentError, fn -> DistinctMonthNameIndices.unrank(1, rank) end
    end
    assert_raise ArgumentError, fn -> LegacyNextMonthNameRank.transform(0, 47) end
    assert_raise ArgumentError, fn -> MonthNameIndexManager.diagnose_count(nil, @source, 2) end
  end

  test "kiểm toán đường production không gọi nguồn tham chiếu" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    manager = File.read!(Path.join(root, "month_name_index_manager.ex"))
    legacy = File.read!(Path.join(root, "legacy_next_month_name_rank.ex"))
    patch = File.read!(Path.join(root, "month_name_rank_patch.ex"))
    assert manager =~ "MonthNameRankPatch.diagnose(rank, total, month_count)"
    assert patch =~ "LegacyNextMonthNameRank.transform(rank, total)"
    assert patch =~ "DistinctMonthNameIndices.unrank(month_count, historical_rank)"
    assert legacy =~ "rem(rank, total) + 1"
    refute manager =~ "NormativeReference"
    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end

  test "normative đỏ 1: một tên tháng" do
    assert MonthNameIndexManager.diagnose_count(@foundation, @source, 1).month_name_indices ==
      oracle(@foundation, 1)
  end

  test "normative đỏ 2: hai tên tháng" do
    c = @foundation + 7
    assert MonthNameIndexManager.diagnose_count(c, @source, 2).month_name_indices ==
      oracle(c, 2)
  end

  test "normative đỏ 3: ba tên tháng" do
    c = @foundation - 7
    assert MonthNameIndexManager.diagnose_count(c, @source, 3).month_name_indices ==
      oracle(c, 3)
  end

  test "normative đỏ 4: bốn tên tháng" do
    c = @foundation + 31
    assert MonthNameIndexManager.diagnose_count(c, @source, 4).month_name_indices ==
      oracle(c, 4)
  end
end
