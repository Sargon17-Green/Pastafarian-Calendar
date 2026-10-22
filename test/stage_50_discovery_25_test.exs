defmodule PastafariCalendarElixirVietnamese.Stage50Discovery25Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    BoundedMonthCompositions,
    LegacyMirroredMonthLengthsRank,
    MonthLengthsManager,
    MonthCountManager,
    StageNotIntegratedError
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp oracle(c, t) do
    {year, _state} = Ref.find_target_year(c, t)
    sauce = Ref.sauce(c, year.open_gate_day + 1)
    slots = Ref.choose_month_count(sauce, year)
    Ref.choose_month_lengths(sauce, year, slots)
  end

  test "đếm các hợp thành ngắn có thứ tự đúng từng khả năng" do
    assert BoundedMonthCompositions.count(8, 2) == 1
    assert BoundedMonthCompositions.count(9, 2) == 2
    assert BoundedMonthCompositions.count(15, 3) == 10
    assert BoundedMonthCompositions.count(244, 2) == 3
    assert BoundedMonthCompositions.count(246, 2) == 1
  end

  test "hợp thành ngoài cận trả không có khả năng" do
    assert BoundedMonthCompositions.count(7, 2) == 0
    assert BoundedMonthCompositions.count(124, 1) == 0
    assert BoundedMonthCompositions.count(247, 2) == 0
    assert BoundedMonthCompositions.count(0, 0) == 1
    assert BoundedMonthCompositions.count(10, 0) == 0
  end

  test "mở hạng đầu và cuối theo thứ tự từ điển" do
    assert BoundedMonthCompositions.unrank(15, 3, 1) == [4, 4, 7]
    assert BoundedMonthCompositions.unrank(15, 3, 10) == [7, 4, 4]
    assert BoundedMonthCompositions.unrank(246, 2, 1) == [123, 123]
  end

  test "đếm và mở mọi hạng nhỏ khớp với chuẩn độc lập" do
    for total <- 12..17 do
      count = BoundedMonthCompositions.count(total, 3)
      assert count == Ref.count_bounded_compositions(total, 3, 4, 123)
      for rank <- 1..count do
        assert BoundedMonthCompositions.unrank(total, 3, rank) ==
          Ref.unrank_bounded_composition(total, 3, 4, 123, rank)
      end
    end
  end

  test "di sản phản chiếu hạng 1..N và là phép đối hợp" do
    assert LegacyMirroredMonthLengthsRank.transform(1, 9) == 9
    assert LegacyMirroredMonthLengthsRank.transform(9, 9) == 1
    assert LegacyMirroredMonthLengthsRank.transform(5, 9) == 5
    for rank <- 1..9 do
      mirrored = LegacyMirroredMonthLengthsRank.transform(rank, 9)
      assert LegacyMirroredMonthLengthsRank.transform(mirrored, 9) == rank
    end
  end

  test "nguồn ngày là cổng mở cộng một, bát 3 chốt 31" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert r.structure_source_day == r.year.open_gate_day + 1
    assert r.bowl == 3
    assert r.seal == 31
  end

  test "số tháng và độ dài năm theo PATCH24, không tính lại" do
    c = @foundation + 11
    r = MonthLengthsManager.diagnose(c, c)
    parent = MonthCountManager.diagnose(c, c)
    assert r.month_count == parent.month_count
    assert r.year_length == parent.year_length
    assert r.year == parent.year
  end

  test "mọi độ dài tháng trong đoạn 4..123 và tổng đúng" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert length(r.month_lengths) == r.month_count
    assert Enum.all?(r.month_lengths, &(&1 in 4..123))
    assert Enum.sum(r.month_lengths) == r.year_length
  end

  test "số hợp thành dùng đủ không gian hạng" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert r.candidate_count ==
      BoundedMonthCompositions.count(r.year_length, r.month_count)
    assert r.candidate_count >= 1
  end

  test "hạng chuẩn từ vòng đáp án giữ một-based và seal31" do
    c = @foundation
    r = MonthLengthsManager.diagnose(c, c)
    stream = Calendar.answer_stream_spaghetti(c, r.structure_source_day, 3, 31)
    assert r.normative_rank ==
      AnswerStreamManager.choose_rank(stream, r.candidate_count)
    assert r.normative_rank in 1..r.candidate_count
  end

  test "hạng legacy thực sự là phản chiếu hạng chuẩn" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert r.historical_rank ==
      LegacyMirroredMonthLengthsRank.transform(r.normative_rank, r.candidate_count)
    assert r.historical_rank in 1..r.candidate_count
  end

  test "production thực sự mở hạng legacy" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert r.month_lengths ==
      BoundedMonthCompositions.unrank(r.year_length, r.month_count, r.historical_rank)
    assert r.month_lengths == Calendar.month_lengths_spaghetti(@foundation, @foundation)
  end

  test "năm, bảng gate và cốt-lết không bị thay đổi" do
    c = @foundation - 13
    r = MonthLengthsManager.diagnose(c, c)
    p = MonthCountManager.diagnose(c, c)
    assert r.year == p.year
    assert r.gate_state == p.gate_state
    assert r.cutlets == p.cutlets
    assert r.cutlet_count == p.cutlet_count
  end

  test "hạng ngoài miền bị từ chối" do
    assert_raise ArgumentError, fn -> BoundedMonthCompositions.unrank(15, 3, 0) end
    assert_raise ArgumentError, fn -> BoundedMonthCompositions.unrank(15, 3, 11) end
    assert_raise ArgumentError, fn -> BoundedMonthCompositions.unrank(7, 2, 1) end
    assert_raise ArgumentError, fn -> LegacyMirroredMonthLengthsRank.transform(0, 7) end
    assert_raise ArgumentError, fn -> LegacyMirroredMonthLengthsRank.transform(8, 7) end
  end

  test "đầu vào ngày không hợp lệ bị từ chối" do
    for bad <- [nil, "1", 1.5, %{}] do
      assert_raise ArgumentError, fn -> MonthLengthsManager.diagnose(bad, @foundation) end
      assert_raise ArgumentError, fn -> MonthLengthsManager.diagnose(@foundation, bad) end
    end
  end

  test "production không gọi oracle và chưa có PATCH25" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    manager = File.read!(Path.join(root, "month_lengths_manager.ex"))
    legacy = File.read!(Path.join(root, "legacy_mirrored_month_lengths_rank.ex"))
    assert manager =~ "LegacyMirroredMonthLengthsRank.transform(normative_rank, candidate_count)"
    assert manager =~ "BoundedMonthCompositions.unrank(total, slots, legacy_rank)"
    assert legacy =~ "count - rank + 1"
    refute manager =~ "NormativeReference"
    refute File.exists?(Path.join(root, "month_lengths_rank_patch.ex"))
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "normative đỏ 1: độ dài tháng ở Ngày Nền" do
    c = @foundation
    assert Calendar.month_lengths_spaghetti(c, c) == oracle(c, c)
  end

  test "normative đỏ 2: độ dài tháng sau Ngày Nền" do
    c = @foundation + 71
    assert Calendar.month_lengths_spaghetti(c, c) == oracle(c, c)
  end

  test "normative đỏ 3: độ dài tháng trước Ngày Nền" do
    c = @foundation - 71
    assert Calendar.month_lengths_spaghetti(c, c) == oracle(c, c)
  end

  test "normative đỏ 4: độ dài tháng ở cổng đóng của năm đích" do
    c = @foundation + 17
    t = Calendar.year5000_spaghetti(c).close_gate_day
    assert Calendar.month_lengths_spaghetti(c, t) == oracle(c, t)
  end
end
