defmodule PastafariCalendarElixirVietnamese.Stage53Patch26Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, LegacyDescendingWeavingOrder,
    MonthWeavingManager, MonthWeavingOrderPatch,
    StageNotIntegratedError, WeavingCombinatorics
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671
  @source @foundation + 1

  test "chuẩn của bốn nhóm RED cũ trở về GREEN" do
    for {delta, lengths} <- [
      {0, [4, 4]}, {7, [5, 5]}, {-7, [4, 7]}, {31, [4, 6]}
    ] do
      c = @foundation + delta
      sauce = Ref.sauce(c, @source)
      count = Ref.count_weavings(lengths)
      rank = Ref.choose_rank(Ref.ask_bowl(sauce, 4, 32), count)
      r = MonthWeavingManager.diagnose_lengths(c, @source, lengths)
      assert r.month_weaving == Ref.unrank_weaving(lengths, rank)
    end
  end

  test "di sản thật tạo ra thứ tự lịch sử được ghi" do
    for lengths <- [[4], [4, 4], [4, 5], [4, 4, 4]] do
      r = MonthWeavingOrderPatch.diagnose(lengths, 1)
      assert r.historical_order == LegacyDescendingWeavingOrder.labels(length(lengths))
    end
  end

  test "kết quả lịch sử được giữ cho nhiều hạng" do
    for lengths <- [[4, 4], [4, 5], [4, 4, 4]] do
      count = WeavingCombinatorics.count(lengths)
      for rank <- Enum.uniq([1, div(count + 1, 2), count]) do
        r = MonthWeavingOrderPatch.diagnose(lengths, rank)
        assert r.historical_weaving ==
          WeavingCombinatorics.unrank(lengths, rank, :descending)
      end
    end
  end

  test "thứ tự chuẩn được khôi phục từ thứ tự lịch sử" do
    for n <- 1..4 do
      r = MonthWeavingOrderPatch.diagnose(List.duplicate(4, n), 1)
      assert r.corrected_order == Enum.reverse(r.historical_order)
      assert r.corrected_order == Enum.to_list(1..n)
    end
  end

  test "hạng đầu, giữa và cuối khớp tham chiếu" do
    for lengths <- [[4, 4], [4, 5], [5, 4], [4, 4, 4]] do
      count = WeavingCombinatorics.count(lengths)
      for rank <- Enum.uniq([1, div(count + 1, 2), count]) do
        r = MonthWeavingOrderPatch.diagnose(lengths, rank)
        assert r.corrected_weaving == Ref.unrank_weaving(lengths, rank)
      end
    end
  end

  test "độ dài và số lần của từng tháng không đổi" do
    lengths = [4, 5, 6]
    r = MonthWeavingOrderPatch.diagnose(lengths, 1)
    assert length(r.corrected_weaving) == Enum.sum(lengths)
    for {days, label} <- Enum.with_index(lengths, 1) do
      assert Enum.count(r.corrected_weaving, &(&1 == label)) == days
    end
  end

  test "chốt 32 của bát 4 giữ hạng một-based" do
    r = MonthWeavingManager.diagnose_lengths(@foundation, @source, [4, 5])
    stream = Calendar.answer_stream_spaghetti(@foundation, @source, 4, 32)
    assert r.weaving_rank == AnswerStreamManager.choose_rank(stream, r.weaving_count)
    assert r.weaving_bowl == 4 and r.weaving_seal == 32
  end

  test "chẩn đoán phân biệt chuỗi cũ và chuỗi đã sửa" do
    r = MonthWeavingManager.diagnose_lengths(@foundation, @source, [4, 4])
    assert r.weaving_historical_order == [2, 1]
    assert r.weaving_corrected_order == [1, 2]
    assert r.historical_month_weaving != r.month_weaving
  end

  test "một tháng chỉ có một chuỗi" do
    r = MonthWeavingManager.diagnose_lengths(@foundation, @source, [4])
    assert r.month_weaving == [1, 1, 1, 1]
    assert r.historical_month_weaving == [1, 1, 1, 1]
  end

  test "tham số sai bị từ chối" do
    for invalid <- [nil, [], [3, 4], [4, 124], "4"] do
      assert_raise ArgumentError, fn -> MonthWeavingOrderPatch.diagnose(invalid, 1) end
    end
    for rank <- [0, -1, 21, nil, 1.5] do
      assert_raise ArgumentError, fn -> MonthWeavingOrderPatch.diagnose([4, 4], rank) end
    end
  end

  test "không có trạng thái thay đổi giữa hai lần gọi" do
    left = MonthWeavingManager.diagnose_lengths(@foundation + 1, @source, [4, 5])
    right = MonthWeavingManager.diagnose_lengths(@foundation + 1, @source, [4, 5])
    assert left == right
  end

  test "kiểm toán không dùng oracle trong production" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    manager = File.read!(Path.join(root, "month_weaving_manager.ex"))
    patch = File.read!(Path.join(root, "month_weaving_order_patch.ex"))
    legacy = File.read!(Path.join(root, "legacy_descending_weaving_order.ex"))
    assert manager =~ "MonthWeavingOrderPatch.diagnose(lengths, rank)"
    assert patch =~ "LegacyDescendingWeavingOrder.labels(length(lengths))"
    assert patch =~ "Enum.reverse(historical_order)"
    assert legacy =~ "Enum.reverse(Enum.to_list(1..count))"
    refute manager =~ "NormativeReference"
    refute patch =~ "NormativeReference"
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end
  test "đếm và mở hạng 47 tháng có độ dài tối thiểu" do
    lengths = List.duplicate(4, 47)
    possibilities = WeavingCombinatorics.count(lengths)
    assert possibilities > 1
    first = WeavingCombinatorics.unrank(lengths, 1)
    assert length(first) == 188
    for label <- 1..47 do
      assert Enum.count(first, &(&1 == label)) == 4
    end
  end

  @tag timeout: 180_000
  test "đếm chính xác năm tối đa 5778 ngày không duyệt mọi trạng thái" do
    lengths = List.duplicate(123, 46) ++ [120]
    count = WeavingCombinatorics.count(lengths)
    assert is_integer(count)
    assert count > Integer.pow(2, 127)
  end

end
