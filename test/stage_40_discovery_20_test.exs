defmodule PastafariCalendarElixirVietnamese.Stage40Discovery20Test do
  use ExUnit.Case, async: true
  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, CutletCountManager,
    LegacyDescendingCutletCount, TargetYearManager, StageNotIntegratedError
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  @foundation -15_055_671

  defp oracle(c, t) do
    {year, _state} = Ref.find_target_year(c, t)
    Ref.choose_cutlet_count(Ref.sauce(c, year.open_gate_day + 1), year)
  end

  test "năm tính dùng đúng cấu trúc năm đích" do
    for delta <- [-37, 0, 37] do
      c = @foundation + delta
      r = CutletCountManager.diagnose(c, c)
      assert r.year == TargetYearManager.find(c, c)
    end
  end

  test "tập ứng viên bắt đầu ở sáu và kết thúc ở min(17,gaps)" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      r = CutletCountManager.diagnose(c, c)
      assert r.candidates == Enum.to_list(6..min(17, r.gate_gaps))
      assert length(r.candidates) == r.candidate_count
    end
  end

  test "các ứng viên tăng đều và không trùng" do
    r = CutletCountManager.diagnose(@foundation, @foundation)
    assert r.candidates == Enum.sort(Enum.uniq(r.candidates))
    assert hd(r.candidates) == 6
  end

  test "legacy đảo đúng thứ tự các ứng viên" do
    r = CutletCountManager.diagnose(@foundation, @foundation)
    assert r.historical_order == Enum.reverse(r.candidates)
    assert r.historical_order == LegacyDescendingCutletCount.sort(r.candidates)
  end

  test "di sản không làm mất ứng viên khi đảo" do
    assert LegacyDescendingCutletCount.sort([6, 7, 8, 9]) == [9, 8, 7, 6]
    assert Enum.sort(LegacyDescendingCutletCount.sort([6, 7, 8])) == [6, 7, 8]
  end

  test "ngày hỏi là ngày đầu tiên của năm" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = CutletCountManager.diagnose(c, c)
      assert r.structure_source_day == r.year.open_gate_day + 1
      assert r.calculation_day == c
    end
  end

  test "hạng chọn bằng bát 2 và chốt 20" do
    c = @foundation + 83
    r = CutletCountManager.diagnose(c, c)
    stream = Calendar.answer_stream_spaghetti(c, r.structure_source_day, 2, 20)
    assert r.rank == AnswerStreamManager.choose_rank(stream, r.candidate_count)
    assert r.rank in 1..r.candidate_count
    assert r.bowl == 2 and r.seal == 20
  end

  test "production thực chọn từ thứ tự legacy" do
    for delta <- [-59, 0, 59] do
      c = @foundation + delta
      r = CutletCountManager.diagnose(c, c)
      assert r.cutlet_count == Enum.at(r.historical_order, r.rank - 1)
      assert Calendar.cutlet_count_spaghetti(c, c) == r.cutlet_count
    end
  end

  test "giá trị chọn nằm trong tập hợp lệ" do
    for delta <- [-531, -101, 0, 101, 531] do
      c = @foundation + delta
      r = CutletCountManager.diagnose(c, c)
      assert is_integer(r.cutlet_count)
      assert r.cutlet_count in r.candidates
    end
  end

  test "cổng đóng năm neo thuộc chính năm neo" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = CutletCountManager.diagnose(c, year.close_gate_day)
    assert r.year == year
  end

  test "cổng mở năm neo thuộc năm 4999" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = CutletCountManager.diagnose(c, year.open_gate_day)
    assert r.year.number == 4999
    assert r.year.close_gate_day == year.open_gate_day
  end

  test "state được giữ nguyên khi chuyển đến tầng cốt-lết" do
    c = @foundation + 17
    r = CutletCountManager.diagnose(c, c)
    assert r.gate_state == TargetYearManager.diagnose(c, c).gate_state
  end

  test "cùng đầu vào có cùng báo cáo bất biến" do
    c = @foundation - 73
    assert CutletCountManager.diagnose(c, c) == CutletCountManager.diagnose(c, c)
  end

  test "đầu vào không hợp lệ bị từ chối" do
    for bad <- [nil, 1.5, "1", %{}] do
      assert_raise ArgumentError, fn -> CutletCountManager.diagnose(bad, @foundation) end
      assert_raise ArgumentError, fn -> CutletCountManager.diagnose(@foundation, bad) end
    end
    assert_raise ArgumentError, fn -> LegacyDescendingCutletCount.sort(nil) end
  end

  test "không ngụy tạo bước phân hoạch hay ngày lịch cuối" do
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "kiểm toán mã nguồn giữ legacy và oracle tách biệt" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_descending_cutlet_count.ex"))
    manager = File.read!(Path.join(root, "cutlet_count_manager.ex"))
    assert legacy =~ "Enum.sort(candidates, :desc)"
    assert manager =~ "LegacyDescendingCutletCount.sort(candidates)"
    assert manager =~ "Dispatcher.answer_stream(c, first_day, @bowl, @seal)"
    assert manager =~ "Enum.at(historical_order, rank - 1)"
    refute manager =~ "NormativeReference"
    refute File.exists?(Path.join(root, "ascending_cutlet_count_patch.ex"))
  end

  test "normative đỏ 1: quanh ngày Foundation" do
    for delta <- [-3, -1, 0, 1, 3] do
      c = @foundation + delta
      assert Calendar.cutlet_count_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "normative đỏ 2: các ngày sau Foundation" do
    for delta <- [17, 71, 101, 417, 721] do
      c = @foundation + delta
      assert Calendar.cutlet_count_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "normative đỏ 3: các ngày trước Foundation" do
    for delta <- [-721, -539, -417, -101, -17] do
      c = @foundation + delta
      assert Calendar.cutlet_count_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "normative đỏ 4: các cổng đóng năm 5000" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      t = Calendar.year5000_spaghetti(c).close_gate_day
      assert Calendar.cutlet_count_spaghetti(c, t) == oracle(c, t)
    end
  end
end
