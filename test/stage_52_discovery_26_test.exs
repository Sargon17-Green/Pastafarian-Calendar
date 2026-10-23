defmodule PastafariCalendarElixirVietnamese.Stage52Discovery26Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyDescendingWeavingOrder, MonthWeavingManager,
    WeavingCombinatorics, StageNotIntegratedError
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671
  @source @foundation + 1

  defp reference_result(c, lengths) do
    sauce = Ref.sauce(c, @source)
    count = Ref.count_weavings(lengths)
    rank = Ref.choose_rank(Ref.ask_bowl(sauce, 4, 32), count)
    Ref.unrank_weaving(lengths, rank)
  end

  test "một tháng có đúng một chuỗi" do
    assert WeavingCombinatorics.count([4]) == 1
    assert WeavingCombinatorics.unrank([4], 1) == [1, 1, 1, 1]
  end

  test "hai tháng có số cách đan theo hệ số nhị thức" do
    assert WeavingCombinatorics.count([4, 4]) == 20
    assert WeavingCombinatorics.count([4, 5]) == 35
  end

  test "bộ đếm khớp oracle trên những bộ ngắn độc lập" do
    for lengths <- [[4], [4, 4], [4, 5], [5, 4], [4, 4, 4]] do
      assert WeavingCombinatorics.count(lengths) == Ref.count_weavings(lengths)
    end
  end

  test "mở hạng đầu và cuối theo chuẩn trên bộ ngắn" do
    for lengths <- [[4, 4], [4, 5], [4, 4, 4]] do
      total = WeavingCombinatorics.count(lengths)
      assert WeavingCombinatorics.unrank(lengths, 1) == Ref.unrank_weaving(lengths, 1)
      assert WeavingCombinatorics.unrank(lengths, total) ==
        Ref.unrank_weaving(lengths, total)
    end
  end

  test "mở các hạng rải rác khớp oracle" do
    for lengths <- [[4, 4], [4, 5], [4, 4, 4]] do
      total = WeavingCombinatorics.count(lengths)
      for rank <- Enum.uniq([1, 2, div(total + 1, 2), total]) do
        assert WeavingCombinatorics.unrank(lengths, rank) ==
          Ref.unrank_weaving(lengths, rank)
      end
    end
  end

  test "di sản chỉ đảo thứ tự duyệt nhãn" do
    assert LegacyDescendingWeavingOrder.labels(4) == [4, 3, 2, 1]
    assert Enum.reverse(LegacyDescendingWeavingOrder.labels(4)) == [1, 2, 3, 4]
  end

  test "hai kiểu duyệt giữ nguyên tập chuỗi hợp lệ" do
    lengths = [4, 4]
    total = WeavingCombinatorics.count(lengths)
    ascending = Enum.map(1..total, &WeavingCombinatorics.unrank(lengths, &1))
    descending = Enum.map(1..total, &WeavingCombinatorics.unrank(lengths, &1, :descending))
    assert MapSet.new(ascending) == MapSet.new(descending)
    assert ascending != descending
    assert WeavingCombinatorics.unrank(lengths, 1, LegacyDescendingWeavingOrder.labels(2)) ==
      WeavingCombinatorics.unrank(lengths, 1, :descending)
  end

  test "các nhãn xuất hiện đúng số lần đã định" do
    for lengths <- [[4, 4], [4, 5], [4, 4, 4]] do
      result = WeavingCombinatorics.unrank(lengths, 1)
      for {length, index} <- Enum.with_index(lengths, 1) do
        assert Enum.count(result, &(&1 == index)) == length
      end
    end
  end

  test "lần đầu và lần cuối luôn theo thứ tự tăng" do
    for lengths <- [[4, 4], [4, 4, 4]] do
      result = WeavingCombinatorics.unrank(lengths, WeavingCombinatorics.count(lengths))
      k = length(lengths)
      first_positions = Enum.map(1..k, fn j ->
        Enum.find_index(result, fn value -> value == j end)
      end)
      last_positions = Enum.map(1..k, fn j ->
        length(result) - 1 -
          Enum.find_index(Enum.reverse(result), fn value -> value == j end)
      end)
      assert first_positions == Enum.sort(first_positions)
      assert last_positions == Enum.sort(last_positions)
    end
  end

  test "giai đoạn này dùng bowl 4 và chốt 32" do
    result = MonthWeavingManager.diagnose_lengths(@foundation, @source, [4, 4])
    assert result.weaving_bowl == 4
    assert result.weaving_seal == 32
  end

  test "hạng được lấy từ dòng đáp án thật" do
    result = MonthWeavingManager.diagnose_lengths(@foundation, @source, [4, 4])
    stream = Calendar.answer_stream_spaghetti(@foundation, @source, 4, 32)
    assert result.weaving_rank ==
      PastafariCalendarElixirVietnamese.Monster.AnswerStreamManager.choose_rank(
        stream, result.weaving_count)
  end

  test "production lịch sử dùng thứ tự giảm" do
    result = MonthWeavingManager.diagnose_lengths(@foundation, @source, [4, 4])
    assert result.weaving_historical_order == [2, 1]
    assert result.historical_month_weaving ==
      WeavingCombinatorics.unrank([4, 4], result.weaving_rank, :descending)
    assert result.month_weaving ==
      WeavingCombinatorics.unrank([4, 4], result.weaving_rank)
  end

  test "giá trị lịch sử vẫn đúng số lần xuất hiện" do
    result = MonthWeavingManager.diagnose_lengths(@foundation, @source, [4, 5])
    assert Enum.count(result.month_weaving, &(&1 == 1)) == 4
    assert Enum.count(result.month_weaving, &(&1 == 2)) == 5
  end

  test "nhập hạng ngoài miền bị bác bỏ" do
    for bad <- [0, -1, 21, nil, 1.2] do
      assert_raise ArgumentError, fn -> WeavingCombinatorics.unrank([4, 4], bad) end
    end
  end

  test "danh sách tháng sai bị bác bỏ" do
    for bad <- [[], [3, 4], [4, 124], [4, 0], nil, "4"] do
      assert_raise ArgumentError, fn -> WeavingCombinatorics.count(bad) end
    end
  end

  test "thứ tự mở hạng sai bị bác bỏ" do
    assert_raise ArgumentError, fn -> WeavingCombinatorics.unrank([4, 4], 1, :random) end
    assert_raise ArgumentError, fn -> LegacyDescendingWeavingOrder.labels(0) end
  end

  test "mã nguồn dùng di sản thực, không gọi oracle trong production" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    manager = File.read!(Path.join(root, "month_weaving_manager.ex"))
    patch = File.read!(Path.join(root, "month_weaving_order_patch.ex"))
    assert manager =~ "MonthWeavingOrderPatch.diagnose(lengths, rank)"
    assert patch =~ "LegacyDescendingWeavingOrder.labels(length(lengths))"
    assert patch =~ "WeavingCombinatorics.unrank(lengths, rank, historical_order)"
    assert patch =~ "Enum.reverse(historical_order)"
    refute manager =~ "NormativeReference"
    refute patch =~ "NormativeReference"
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "nhóm normative đỏ 1: hai tháng cân bằng" do
    assert MonthWeavingManager.diagnose_lengths(@foundation, @source, [4, 4]).month_weaving ==
      reference_result(@foundation, [4, 4])
  end

  test "nhóm normative đỏ 2: tháng thứ nhất dài hơn" do
    c = @foundation + 7
    assert MonthWeavingManager.diagnose_lengths(c, @source, [5, 5]).month_weaving ==
      reference_result(c, [5, 5])
  end

  test "nhóm normative đỏ 3: tháng thứ hai dài hơn" do
    c = @foundation - 7
    assert MonthWeavingManager.diagnose_lengths(c, @source, [4, 7]).month_weaving ==
      reference_result(c, [4, 7])
  end

  test "nhóm normative đỏ 4: độ dài không bằng nhau" do
    c = @foundation + 31
    assert MonthWeavingManager.diagnose_lengths(c, @source, [4, 6]).month_weaving ==
      reference_result(c, [4, 6])
  end
end
