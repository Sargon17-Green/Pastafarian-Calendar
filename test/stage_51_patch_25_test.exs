defmodule PastafariCalendarElixirVietnamese.Stage51Patch25Test do
  use ExUnit.Case, async: true
  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    BoundedMonthCompositions, LegacyMirroredMonthLengthsRank,
    MonthLengthsManager, MonthLengthsRankPatch, MonthCountManager,
    StageNotIntegratedError
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671
  defp oracle(c, t) do
    {year, _} = Ref.find_target_year(c, t)
    sauce = Ref.sauce(c, year.open_gate_day + 1)
    count = Ref.choose_month_count(sauce, year)
    Ref.choose_month_lengths(sauce, year, count)
  end

  test "bốn nhóm chuẩn ở nền và hai phía" do
    for delta <- [-71, -17, -3, -1, 0, 1, 3, 17, 71] do
      c = @foundation + delta
      assert Calendar.month_lengths_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "độ dài tháng ở các cổng đóng" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      target = Calendar.year5000_spaghetti(c).close_gate_day
      assert Calendar.month_lengths_spaghetti(c, target) == oracle(c, target)
    end
  end

  test "độ dài tháng cho ngày xa" do
    for delta <- [-721, -417, 417, 721] do
      c = @foundation + delta
      assert Calendar.month_lengths_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "bản vá hai lần phản chiếu khôi phục hạng" do
    for count <- [1, 2, 9, 301] do
      for rank <- 1..min(count, 9) do
        patch = MonthLengthsRankPatch.diagnose(rank, count)
        assert patch.corrected_rank == rank
      end
    end
  end

  test "hạng lịch sử được tính bằng hàm legacy thật" do
    for count <- [1, 2, 9, 301] do
      for rank <- 1..min(count, 9) do
        patch = MonthLengthsRankPatch.diagnose(rank, count)
        assert patch.historical_rank ==
          LegacyMirroredMonthLengthsRank.transform(rank, count)
      end
    end
  end

  test "hạng chuẩn giữ nguyên dòng trả lời" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert r.corrected_rank == r.normative_rank
    assert r.corrected_rank in 1..r.candidate_count
  end

  test "dữ liệu lịch sử vẫn được bảo toàn" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert r.historical_month_lengths ==
      BoundedMonthCompositions.unrank(r.year_length, r.month_count, r.historical_rank)
  end

  test "dữ liệu production mở đúng hạng đã vá" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert r.month_lengths ==
      BoundedMonthCompositions.unrank(r.year_length, r.month_count, r.corrected_rank)
  end

  test "đếm không gian ứng viên không bị sửa" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert r.candidate_count ==
      BoundedMonthCompositions.count(r.year_length, r.month_count)
  end

  test "mỗi tháng giữ cận và tổng đúng" do
    for delta <- [-31, 0, 31] do
      c = @foundation + delta
      r = MonthLengthsManager.diagnose(c, c)
      assert length(r.month_lengths) == r.month_count
      assert Enum.all?(r.month_lengths, &(&1 in 4..123))
      assert Enum.sum(r.month_lengths) == r.year_length
    end
  end

  test "năm và số tháng vẫn lấy từ PATCH24" do
    c = @foundation + 23
    r = MonthLengthsManager.diagnose(c, c)
    parent = MonthCountManager.diagnose(c, c)
    assert r.year == parent.year
    assert r.month_count == parent.month_count
    assert r.year_length == parent.year_length
  end

  test "các cốt-lết không đổi" do
    c = @foundation - 23
    r = MonthLengthsManager.diagnose(c, c)
    parent = MonthCountManager.diagnose(c, c)
    assert r.cutlets == parent.cutlets
    assert r.gate_state == parent.gate_state
  end

  test "ngày nguồn và bowl seal được bảo toàn" do
    r = MonthLengthsManager.diagnose(@foundation, @foundation)
    assert r.structure_source_day == r.year.open_gate_day + 1
    assert r.bowl == 3 and r.seal == 31
  end

  test "đầu năm tiếp theo không mất một ngày" do
    c = @foundation
    y = Calendar.year5000_spaghetti(c)
    t = y.close_gate_day
    r = MonthLengthsManager.diagnose(c, t)
    assert r.year == y
    assert Enum.sum(r.month_lengths) == y.close_gate_day - y.open_gate_day
  end

  test "đầu năm 5000 thuộc năm trước" do
    c = @foundation
    y = Calendar.year5000_spaghetti(c)
    r = MonthLengthsManager.diagnose(c, y.open_gate_day)
    assert r.year.number == 4999
  end

  test "hạng không hợp lệ không lọt qua bản vá" do
    for {rank, count} <- [{0, 2}, {-1, 9}, {3, 2}, {1, 0}] do
      assert_raise ArgumentError, fn -> MonthLengthsRankPatch.diagnose(rank, count) end
    end
  end

  test "cùng ngày tạo cùng kết quả" do
    c = @foundation + 67
    assert MonthLengthsManager.diagnose(c, c) ==
      MonthLengthsManager.diagnose(c, c)
  end

  test "thứ tự truy vấn không ảnh hưởng kết quả" do
    days = Enum.map(-3..3, &(@foundation + 31 * &1))
    front = Enum.map(days, &Calendar.month_lengths_spaghetti(&1, &1))
    backward = Enum.reverse(days) |> Enum.map(&Calendar.month_lengths_spaghetti(&1, &1))
    assert front == Enum.reverse(backward)
  end

  test "đầu vào ngày sai vẫn bị từ chối" do
    for bad <- [nil, "1", 1.5, %{}] do
      assert_raise ArgumentError, fn -> MonthLengthsManager.diagnose(bad, @foundation) end
      assert_raise ArgumentError, fn -> MonthLengthsManager.diagnose(@foundation, bad) end
    end
  end

  test "kiểm toán production có di sản nhưng không gọi oracle" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    patch = File.read!(Path.join(root, "month_lengths_rank_patch.ex"))
    manager = File.read!(Path.join(root, "month_lengths_manager.ex"))
    assert patch =~ "LegacyMirroredMonthLengthsRank.transform(rank, count)"
    assert patch =~ "LegacyMirroredMonthLengthsRank.transform(historical_rank, count)"
    assert manager =~ "MonthLengthsRankPatch.diagnose(normative_rank, candidate_count)"
    refute patch =~ "NormativeReference"
    refute manager =~ "NormativeReference"
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end
end
