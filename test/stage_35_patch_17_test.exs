defmodule PastafariCalendarElixirVietnamese.Stage35Patch17Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    Dispatcher,
    LegacyCurrentDayNextYearSeed,
    NextYearCandidateManager,
    NextYearManager,
    NextYearSeedPatch,
    Year5000Manager
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp normative_next(c) do
    {known, state} = Ref.year5000(c)
    {year, _} = Ref.next_year(c, known, state)
    Map.from_struct(year)
  end

  test "bốn hồi quy normative Stage34 chuyển về xanh" do
    for c <- [@foundation - 539, @foundation + 1, @foundation + 417, @foundation + 2] do
      assert Calendar.next_year_spaghetti(c) |> Map.from_struct() == normative_next(c)
    end
  end

  test "patch chọn rank theo cùng Dispatcher, bát 1 chốt 11" do
    for c <- [@foundation - 539, @foundation + 2, @foundation + 417] do
      report = NextYearManager.diagnose(c)
      stream = Dispatcher.answer_stream(c, report.year.open_gate_day, 1, 11)
      expected = AnswerStreamManager.choose_rank(stream, report.candidate_count)
      assert report.rank == expected
      assert report.rank in 1..report.candidate_count
      assert report.bowl == 1 and report.seal == 11
    end
  end

  test "legacy vẫn được gọi và ghi lại hạng sai độc lập" do
    for c <- [@foundation - 539, @foundation + 1, @foundation + 2, @foundation + 417] do
      report = NextYearManager.diagnose(c)
      assert report.historical_rank ==
        LegacyCurrentDayNextYearSeed.choose_rank(c, report.candidate_count)
      assert report.rank != report.historical_rank
      assert report.rank_was_corrected
    end
  end

  test "ngày nguồn sai và chuẩn được giữ trong diagnostic" do
    c = @foundation + 2
    report = NextYearManager.diagnose(c)
    assert report.historical_source_day == c
    assert report.normative_source_day == report.known_year.close_gate_day
    assert report.normative_source_day == report.year.open_gate_day
    assert report.normative_source_day != c
  end

  test "truy vấn trực tiếp patch ghi chính xác hai ngày nguồn" do
    for {c, open_day, count} <- [{17, 51, 5}, {-100, 200, 8}, {0, 0, 1}] do
      diagnostic = NextYearSeedPatch.diagnose(c, open_day, count)
      assert diagnostic.historical_source_day == c
      assert diagnostic.corrected_source_day == open_day
      assert diagnostic.candidate_count == count
      assert diagnostic.bowl == 1 and diagnostic.seal == 11
      assert diagnostic.legacy_rank == LegacyCurrentDayNextYearSeed.choose_rank(c, count)
      stream = Calendar.answer_stream_spaghetti(c, open_day, 1, 11)
      assert diagnostic.corrected_rank == AnswerStreamManager.choose_rank(stream, count)
    end
  end

  test "khi c trùng ngày mở, rank legacy và rank chuẩn giống nhau" do
    c = @foundation
    rank = NextYearSeedPatch.diagnose(c, c, 7)
    assert rank.legacy_rank == rank.corrected_rank
    refute rank.changed
  end

  test "trường hợp chỉ có một ứng viên luôn được chọn" do
    diagnostic = NextYearSeedPatch.diagnose(@foundation, @foundation + 37, 1)
    assert diagnostic.legacy_rank == 1
    assert diagnostic.corrected_rank == 1
    assert NextYearSeedPatch.choose_rank(@foundation, @foundation + 37, 1) == 1
  end

  test "mọi năm kế tiếp thuộc biên 252..5778 ngày và >=6 cổng" do
    for c <- [@foundation - 539, @foundation - 71, @foundation, @foundation + 417] do
      year = Calendar.next_year_spaghetti(c)
      assert year.close_gate_day - year.open_gate_day in 252..5_778
      assert year.close_gate_index - year.open_gate_index >= 6
      assert year.number == 5001
    end
  end

  test "đầu năm sau trùng ngày đóng của năm neo 5000" do
    for delta <- [-539, -101, 0, 1, 417] do
      c = @foundation + delta
      known = Calendar.year5000_spaghetti(c)
      year = Calendar.next_year_spaghetti(c)
      assert known.close_gate_day == year.open_gate_day
      assert known.close_gate_index == year.open_gate_index
    end
  end

  test "tập ứng viên và thứ tự không đổi khi sửa nguồn hạt" do
    for delta <- [-539, -1, 0, 417] do
      c = @foundation + delta
      anchor = Year5000Manager.diagnose(c)
      {candidates, state} = NextYearCandidateManager.build(anchor.year, anchor.gate_state)
      report = NextYearManager.diagnose(c)
      assert report.candidates == candidates
      assert report.gate_state == state
      assert candidates == Enum.sort_by(candidates, &state.gate[&1])
    end
  end

  test "hạng corrected là một-based và chỉ số đóng lấy đúng ứng viên" do
    for c <- [@foundation - 539, @foundation + 2, @foundation + 417] do
      r = NextYearManager.diagnose(c)
      assert r.year.close_gate_index == Enum.at(r.candidates, r.rank - 1)
      assert r.year.close_gate_day == r.gate_state.gate[r.year.close_gate_index]
    end
  end

  test "year5000 không bị ảnh hưởng qua nhiều ngày" do
    for delta <- [-539, -71, 0, 71, 417] do
      c = @foundation + delta
      expected = Ref.year5000(c) |> elem(0) |> Map.from_struct()
      assert Calendar.year5000_spaghetti(c) |> Map.from_struct() == expected
    end
  end

  test "so sánh năm sau với oracle ở nhiều điểm phụ" do
    for delta <- [-721, -109, -41, -2, -1, 0, 1, 2, 3, 83, 417, 721] do
      c = @foundation + delta
      assert Calendar.next_year_spaghetti(c) |> Map.from_struct() == normative_next(c)
    end
  end

  test "đồng thời không dùng cache hoặc state chung" do
    days = Enum.map(-3..3, &(@foundation + 37 * &1))
    results = Task.async_stream(days, &Calendar.next_year_spaghetti/1,
      max_concurrency: 5, ordered: true, timeout: 30_000)
      |> Enum.map(fn {:ok, year} -> Map.from_struct(year) end)
    assert results == Enum.map(days, &normative_next/1)
  end

  test "lặp lại cùng ngày nhận cùng kết quả, không đột biến year" do
    for c <- [@foundation + 1, @foundation + 2, @foundation - 71] do
      report = NextYearManager.diagnose(c)
      assert NextYearManager.diagnose(c) == report
      assert Calendar.next_year_spaghetti(c) == report.year
    end
  end

  test "truy vấn năm kế không làm mất các cổng đã biết" do
    c = @foundation + 53
    anchor = Year5000Manager.diagnose(c)
    next = NextYearManager.diagnose(c)
    for {k, v} <- anchor.gate_state.gate do
      assert next.gate_state.gate[k] == v
    end
    assert anchor.year == Calendar.year5000_spaghetti(c)
  end

  test "tham số hạt không hợp lệ bị từ chối" do
    for bad <- [nil, 1.5, "1", %{}] do
      assert_raise ArgumentError, fn -> NextYearSeedPatch.diagnose(bad, 3, 5) end
      assert_raise ArgumentError, fn -> NextYearSeedPatch.diagnose(0, bad, 5) end
      assert_raise ArgumentError, fn -> NextYearSeedPatch.choose_rank(0, 2, bad) end
    end
    for bad <- [0, -1] do
      assert_raise ArgumentError, fn -> NextYearSeedPatch.diagnose(0, 1, bad) end
    end
  end

  test "ngày lịch cuối chưa tích hợp dù năm sau đã chính xác" do
    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "kiểm toán đường patch: vẫn giữ nguồn legacy sai c,c" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_current_day_next_year_seed.ex"))
    patch = File.read!(Path.join(root, "next_year_seed_patch.ex"))
    manager = File.read!(Path.join(root, "next_year_manager.ex"))
    assert legacy =~ "Dispatcher.answer_stream(calculation_day, calculation_day, 1, 11)"
    assert patch =~ "LegacyCurrentDayNextYearSeed.choose_rank(calculation_day, count)"
    assert patch =~ "Dispatcher.answer_stream(calculation_day, open_day, 1, 11)"
    assert manager =~ "NextYearSeedPatch.diagnose(calculation_day, open_day, length(candidates))"
    assert manager =~ "rank = seed_report.corrected_rank"
    refute patch =~ "NormativeReference"
  end

  test "gốc PATCH 17 chỉ phụ thuộc dữ liệu đầu vào" do
    a = NextYearSeedPatch.diagnose(@foundation + 1, @foundation + 503, 9)
    _ = NextYearSeedPatch.diagnose(@foundation + 2, @foundation + 700, 11)
    assert a == NextYearSeedPatch.diagnose(@foundation + 1, @foundation + 503, 9)
  end
end
