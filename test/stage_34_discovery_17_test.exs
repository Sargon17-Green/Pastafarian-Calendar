defmodule PastafariCalendarElixirVietnamese.Stage34Discovery17Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyCurrentDayNextYearSeed,
    NextYearCandidateManager,
    NextYearManager,
    Year,
    Year5000Manager
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp reference_next_year(c) do
    {anchor, gate} = Ref.year5000(c)
    {next, _state} = Ref.next_year(c, anchor, gate)
    Map.from_struct(next)
  end

  defp production_next_year(c) do
    Calendar.next_year_spaghetti(c) |> Map.from_struct()
  end

  test "năm sau năm neo được đặt số 5001" do
    result = Calendar.next_year_spaghetti(@foundation)
    assert %Year{} = result
    assert result.number == 5001
    assert result.open_gate_index < result.close_gate_index
  end

  test "năm sau bắt đầu đúng ở cổng đóng của năm trước" do
    for c <- [@foundation, @foundation + 17, @foundation - 19] do
      report = NextYearManager.diagnose(c)
      assert report.year.open_gate_index == report.known_year.close_gate_index
      assert report.year.open_gate_day == report.known_year.close_gate_day
      assert report.year.open_gate_day < report.year.close_gate_day
    end
  end

  test "ứng viên năm sau đều có ít nhất sáu khoảng hợp lệ" do
    for c <- [@foundation, @foundation - 31] do
      report = NextYearManager.diagnose(c)
      assert report.candidate_count >= 1
      for j <- report.candidates do
        gaps = j - report.year.open_gate_index
        span = report.gate_state.gate[j] - report.year.open_gate_day
        assert gaps >= 6
        assert span in 252..5_778
      end
    end
  end

  test "các ứng viên được sắp theo độ dài tăng dần" do
    report = NextYearManager.diagnose(@foundation)
    days = Enum.map(report.candidates, fn j ->
      report.gate_state.gate[j] - report.year.open_gate_day
    end)
    assert days == Enum.sort(days)
    assert days != []
  end

  test "bảng gate mở đủ tới open_day cộng 5778" do
    for c <- [@foundation, @foundation + 71] do
      report = NextYearManager.diagnose(c)
      state = report.gate_state
      assert state.gate[state.max_index] >= report.year.open_gate_day + 5_778
    end
  end

  test "tất cả cổng năm tiếp theo đúng với oracle tại cửa sổ" do
    c = @foundation
    report = NextYearManager.diagnose(c)
    lower = report.gate_state.gate[report.gate_state.min_index]
    upper = report.year.open_gate_day + 5_778
    ref = Ref.ensure_gates_cover(Ref.new_gate_state(), lower, upper)
    for {i, day} <- ref.gate, do: assert(report.gate_state.gate[i] == day)
  end

  test "bộ ứng viên không thay đổi năm 5000 đã biết" do
    c = @foundation - 47
    anchor = Year5000Manager.diagnose(c)
    year_before = anchor.year
    {candidates, new_state} = NextYearCandidateManager.build(year_before, anchor.gate_state)
    assert length(candidates) > 0
    assert year_before == anchor.year
    assert anchor.gate_state.gate == Map.take(new_state.gate, Map.keys(anchor.gate_state.gate))
  end

  test "tập ứng viên khớp tập normative độc lập" do
    c = @foundation + 41
    anchor = Year5000Manager.diagnose(c)
    {actual, next_state} = NextYearCandidateManager.build(anchor.year, anchor.gate_state)
    open_index = anchor.year.close_gate_index
    open_day = anchor.year.close_gate_day
    ref = Ref.ensure_gates_cover(Ref.new_gate_state(), open_day, open_day + 5_778)
    expected =
      (open_index + 1)..ref.max_index
      |> Enum.filter(fn j ->
        span = ref.gate[j] - open_day
        j-open_index >= 6 and span in 252..5_778
      end)
      |> Enum.sort_by(fn j -> ref.gate[j] - open_day end)
    assert actual == expected
    assert Enum.all?(actual, &Map.has_key?(next_state.gate, &1))
  end

  test "nguồn legacy hỏi c,c chứ không phải c,ngày mở" do
    c = @foundation + 17
    report = NextYearManager.diagnose(c)
    assert report.historical_source_day == c
    assert report.normative_source_day == report.year.open_gate_day
    assert report.normative_source_day != c
    assert report.rank == LegacyCurrentDayNextYearSeed.choose_rank(c, report.candidate_count)
  end

  test "seal của năm kế tiếp là 11 và bát là 1" do
    report = NextYearManager.diagnose(@foundation)
    assert report.bowl == 1
    assert report.seal == 11
    assert report.rank in 1..report.candidate_count
  end

  test "đường production lấy ứng viên theo rank sai của legacy" do
    report = NextYearManager.diagnose(@foundation)
    selected = Enum.at(report.candidates, report.rank - 1)
    assert selected == report.year.close_gate_index
    assert report.year.close_gate_day == report.gate_state.gate[selected]
  end

  test "đường public và manager trùng nhau trên ba ngày" do
    for c <- [@foundation - 29, @foundation, @foundation + 29] do
      assert Calendar.next_year_spaghetti(c) == NextYearManager.next_year(c)
    end
  end

  test "khi chạy lại cùng ngày cho cùng kết quả" do
    c = @foundation - 31
    a = NextYearManager.diagnose(c)
    b = NextYearManager.diagnose(c)
    assert a == b
  end

  test "năm 5000 trước đó vẫn khớp oracle" do
    for c <- [@foundation, @foundation - 539, @foundation + 417] do
      assert Calendar.year5000_spaghetti(c) |> Map.from_struct() ==
        (Ref.year5000(c) |> elem(0) |> Map.from_struct())
    end
  end

  test "đầu vào sai bị chặn tại manager và legacy" do
    for invalid <- [nil, 1.5, "1", %{}] do
      assert_raise ArgumentError, fn -> NextYearManager.diagnose(invalid) end
      assert_raise ArgumentError, fn -> LegacyCurrentDayNextYearSeed.choose_rank(invalid, 3) end
    end
    for count <- [0, -1, nil, 2.5] do
      assert_raise ArgumentError, fn ->
        LegacyCurrentDayNextYearSeed.choose_rank(@foundation, count)
      end
    end
  end

  test "kiểm toán nguồn và không có patch 17 trước Stage35" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_current_day_next_year_seed.ex"))
    manager = File.read!(Path.join(root, "next_year_manager.ex"))
    candidates = File.read!(Path.join(root, "next_year_candidate_manager.ex"))
    assert legacy =~ "Dispatcher.answer_stream(calculation_day, calculation_day, 1, 11)"
    assert manager =~ "LegacyCurrentDayNextYearSeed.choose_rank(calculation_day, length(candidates))"
    assert candidates =~ "Enum.sort_by"
    refute File.exists?(Path.join(root, "next_year_seed_patch.ex"))
    refute manager =~ "NormativeReference"
  end

  test "hồi quy normative đỏ 1: năm kế sau FOUNDATION" do
    c = @foundation
    assert production_next_year(c) == reference_next_year(c)
  end

  test "hồi quy normative đỏ 2: năm kế sau FOUNDATION+1" do
    c = @foundation + 1
    assert production_next_year(c) == reference_next_year(c)
  end

  test "hồi quy normative đỏ 3: năm kế sau FOUNDATION+417" do
    c = @foundation + 417
    assert production_next_year(c) == reference_next_year(c)
  end

  test "hồi quy normative đỏ 4: năm kế sau FOUNDATION-539" do
    c = @foundation - 539
    assert production_next_year(c) == reference_next_year(c)
  end
end
