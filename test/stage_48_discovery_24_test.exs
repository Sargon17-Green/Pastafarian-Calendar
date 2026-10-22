defmodule PastafariCalendarElixirVietnamese.Stage48Discovery24Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    CutletMaterializationManager,
    LegacyDescendingMonthCount,
    AscendingMonthCountPatch,
    MonthCountManager,
    StageNotIntegratedError
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp reference_count(c, target) do
    {year, _state} = Ref.find_target_year(c, target)
    Ref.choose_month_count(Ref.sauce(c, year.open_gate_day + 1), year)
  end

  test "cận dưới ceil(length/123) và cận trên min(47,floor(length/4))" do
    assert MonthCountManager.candidates_for_length(252) == Enum.to_list(3..47)
    assert MonthCountManager.candidates_for_length(5_778) == [47]
    assert MonthCountManager.candidates_for_length(123) == Enum.to_list(1..30)
  end

  test "trường hợp năm ngắn có đúng một số tháng hợp lệ" do
    assert MonthCountManager.candidates_for_length(4) == [1]
    assert MonthCountManager.candidates_for_length(123) |> hd() == 1
    assert MonthCountManager.candidates_for_length(124) |> hd() == 2
  end

  test "di sản đảo thứ tự các ứng viên mà không bỏ phần tử" do
    sample = [3, 4, 5, 6, 7]
    assert LegacyDescendingMonthCount.sort(sample) == [7, 6, 5, 4, 3]
    assert Enum.sort(LegacyDescendingMonthCount.sort(sample)) == sample
  end

  test "năm được lấy từ tầng vật chất hóa đã vá" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = MonthCountManager.diagnose(c, c)
      parent = CutletMaterializationManager.diagnose(c, c)
      assert r.year == parent.year
      assert r.gate_state == parent.gate_state
    end
  end

  test "số ngày của năm đúng chênh lệch hai cổng" do
    for delta <- [-101, 0, 101] do
      c = @foundation + delta
      r = MonthCountManager.diagnose(c, c)
      assert r.year_length == r.year.close_gate_day - r.year.open_gate_day
      assert r.year_length >= 252
      assert r.year_length <= 5_778
    end
  end

  test "dãy ứng viên thứ tự tăng theo giới hạn chuẩn" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      r = MonthCountManager.diagnose(c, c)
      assert r.candidates == MonthCountManager.candidates_for_length(r.year_length)
      assert r.candidates == Enum.sort(r.candidates)
      assert r.candidate_count == length(r.candidates)
    end
  end

  test "thứ tự lịch sử là đảo thứ tự chuẩn" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = MonthCountManager.diagnose(c, c)
      assert r.historical_order == Enum.reverse(r.candidates)
      assert r.historical_order == LegacyDescendingMonthCount.sort(r.candidates)
    end
  end

  test "rank đúng dùng bát 3 chốt 30 và một-based" do
    for delta <- [-101, 0, 101] do
      c = @foundation + delta
      r = MonthCountManager.diagnose(c, c)
      stream = Calendar.answer_stream_spaghetti(c, r.structure_source_day, 3, 30)
      assert r.rank == AnswerStreamManager.choose_rank(stream, r.candidate_count)
      assert r.rank in 1..r.candidate_count
      assert r.bowl == 3 and r.seal == 30
    end
  end

  test "production dùng thứ tự tăng dần sau khi gọi legacy" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      r = MonthCountManager.diagnose(c, c)
      assert r.historical_month_count == Enum.at(r.historical_order, r.rank - 1)
      assert r.month_count == Enum.at(r.corrected_order, r.rank - 1)
      assert r.month_count == AscendingMonthCountPatch.diagnose(r.candidates, r.rank).corrected_count
      assert Calendar.month_count_spaghetti(c, c) == r.month_count
    end
  end

  test "số tháng luôn nằm trong tập khả thi" do
    for delta <- [-721, -71, 0, 71, 721] do
      c = @foundation + delta
      r = MonthCountManager.diagnose(c, c)
      assert r.month_count in r.candidates
      assert r.month_count >= 1
      assert r.month_count <= 47
    end
  end

  test "nguồn sauce dùng ngày đầu năm chứ không dùng ngày tính" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = MonthCountManager.diagnose(c, c)
      assert r.structure_source_day == r.year.open_gate_day + 1
      assert r.calculation_day == c
      assert r.target_day == c
    end
  end

  test "cổng đóng năm neo vẫn thuộc năm neo" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = MonthCountManager.diagnose(c, year.close_gate_day)
    assert r.year == year
  end

  test "cổng mở năm neo vẫn thuộc năm 4999" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = MonthCountManager.diagnose(c, year.open_gate_day)
    assert r.year.number == 4999
    assert r.year.close_gate_day == year.open_gate_day
  end

  test "bảng gate và cốt-lết giữ nguyên sau khi chọn số tháng" do
    c = @foundation + 47
    r = MonthCountManager.diagnose(c, c)
    parent = CutletMaterializationManager.diagnose(c, c)
    assert r.gate_state == parent.gate_state
    assert r.cutlets == parent.cutlets
    assert r.cutlet_count == parent.cutlet_count
  end

  test "đầu vào năm hoặc ngày không hợp lệ bị từ chối" do
    for bad <- [nil, "1", 1.5, %{}] do
      assert_raise ArgumentError, fn -> MonthCountManager.diagnose(bad, @foundation) end
      assert_raise ArgumentError, fn -> MonthCountManager.diagnose(@foundation, bad) end
      assert_raise ArgumentError, fn -> MonthCountManager.candidates_for_length(bad) end
    end
    assert_raise ArgumentError, fn -> MonthCountManager.candidates_for_length(1) end
    assert_raise ArgumentError, fn -> LegacyDescendingMonthCount.sort(nil) end
  end

  test "source bảo đảm dùng legacy thật, không gọi oracle hoặc tích hợp lịch cuối" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_descending_month_count.ex"))
    manager = File.read!(Path.join(root, "month_count_manager.ex"))
    assert legacy =~ "Enum.sort(candidates, :desc)"
    assert manager =~ "AscendingMonthCountPatch.diagnose(candidates, rank)"
    assert manager =~ "Dispatcher.answer_stream(c, source_day, @bowl, @seal)"
    assert manager =~ "chosen = patch.corrected_count"
    refute manager =~ "NormativeReference"
    assert File.exists?(Path.join(root, "ascending_month_count_patch.ex"))
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "normative đỏ 1: số tháng quanh Ngày Nền" do
    for delta <- [-3, -1, 0, 1, 3] do
      c = @foundation + delta
      assert Calendar.month_count_spaghetti(c, c) == reference_count(c, c)
    end
  end

  test "normative đỏ 2: số tháng sau Ngày Nền" do
    for delta <- [17, 71, 101, 417, 721, 1031, 2003] do
      c = @foundation + delta
      assert Calendar.month_count_spaghetti(c, c) == reference_count(c, c)
    end
  end

  test "normative đỏ 3: số tháng trước Ngày Nền" do
    for delta <- [-721, -539, -417, -101, -17] do
      c = @foundation + delta
      assert Calendar.month_count_spaghetti(c, c) == reference_count(c, c)
    end
  end

  test "normative đỏ 4: số tháng ở cổng đóng của năm đích" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      target = Calendar.year5000_spaghetti(c).close_gate_day
      assert Calendar.month_count_spaghetti(c, target) == reference_count(c, target)
    end
  end
end
