defmodule PastafariCalendarElixirVietnamese.Stage37Patch18Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    GateTimelineManager,
    LegacyNextYearSealForPreviousSeed,
    PreviousYearCandidateManager,
    PreviousYearManager,
    PreviousYearSealPatch,
    Year,
    Year5000Manager
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp reference_previous(c) do
    {anchor, state} = Ref.year5000(c)
    {year, _} = Ref.previous_year(c, anchor, state)
    Map.from_struct(year)
  end

  defp actual_previous(c), do: Map.from_struct(Calendar.previous_year_spaghetti(c))

  test "bốn nhóm hồi quy normative Stage36 trở lại xanh" do
    for delta <- [-721, -539, -417, -107, -2, -1, 0, 1, 2, 3, 7, 11, 71, 417, 721, 1031] do
      c = @foundation + delta
      assert actual_previous(c) == reference_previous(c)
    end
  end

  test "năm trước trả đúng năm 4999 và biên" do
    report = PreviousYearManager.diagnose(@foundation)
    assert %Year{number: 4999} = report.year
    assert report.year.close_gate_index == report.known_year.open_gate_index
    assert report.year.close_gate_day == report.known_year.open_gate_day
    assert report.year.open_gate_day < report.year.close_gate_day
  end

  test "bản vá thật sự gọi legacy và ghi hạng lịch sử" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      report = PreviousYearManager.diagnose(c)
      expected = LegacyNextYearSealForPreviousSeed.choose_rank(
        c, report.source_day, report.candidate_count
      )
      assert report.historical_rank == expected
      patch = PreviousYearSealPatch.diagnose(c, report.source_day, report.candidate_count)
      assert patch.legacy_rank == expected
      assert patch.corrected_rank == report.rank
    end
  end

  test "chốt 12 chuẩn nhưng chốt 11 di sản còn nguyên" do
    for delta <- [-109, 0, 71] do
      c = @foundation + delta
      report = PreviousYearManager.diagnose(c)
      old_stream = Calendar.answer_stream_spaghetti(c, report.source_day, 1, 11)
      good_stream = Calendar.answer_stream_spaghetti(c, report.source_day, 1, 12)
      assert report.historical_rank ==
        AnswerStreamManager.choose_rank(old_stream, report.candidate_count)
      assert report.rank ==
        AnswerStreamManager.choose_rank(good_stream, report.candidate_count)
      assert report.historical_seal == 11
      assert report.normative_seal == 12
      assert report.bowl == 1
    end
  end

  test "nguồn ngày chuẩn là ngày đóng của năm trước" do
    for delta <- [-107, 0, 103] do
      report = PreviousYearManager.diagnose(@foundation + delta)
      assert report.source_day == report.known_year.open_gate_day
      assert report.source_day == report.year.close_gate_day
      assert report.calculation_day == @foundation + delta
    end
  end

  test "thứ tự ứng viên vẫn ngắn trước dài" do
    report = PreviousYearManager.diagnose(@foundation)
    lengths = Enum.map(report.candidates, fn index ->
      report.year.close_gate_day - report.gate_state.gate[index]
    end)
    assert lengths == Enum.sort(lengths)
    assert length(lengths) == length(Enum.uniq(report.candidates))
  end

  test "chọn cổng mở đúng hạng một-based" do
    for delta <- [-55, 0, 55] do
      report = PreviousYearManager.diagnose(@foundation + delta)
      assert report.rank in 1..report.candidate_count
      assert report.year.open_gate_index == Enum.at(report.candidates, report.rank - 1)
    end
  end

  test "tập ứng viên giữ nguyên khi sửa seed" do
    c = @foundation + 19
    report = PreviousYearManager.diagnose(c)
    {candidates, state} = PreviousYearCandidateManager.build(report.known_year,
      Year5000Manager.diagnose(c).gate_state)
    assert candidates == report.candidates
    assert state == report.gate_state
  end

  test "bảng cổng âm dương khớp oracle sau bản vá" do
    c = @foundation - 47
    report = PreviousYearManager.diagnose(c)
    ref_state = Ref.ensure_gates_cover(Ref.new_gate_state(),
      report.source_day - 5_778, report.gate_state.gate[report.gate_state.max_index])
    for {index, day} <- ref_state.gate do
      assert report.gate_state.gate[index] == day
    end
  end

  test "năm neo 5000 vẫn bằng tham chiếu" do
    for delta <- [-417, 0, 417] do
      c = @foundation + delta
      assert Map.from_struct(Calendar.year5000_spaghetti(c)) ==
        Map.from_struct(elem(Ref.year5000(c), 0))
    end
  end

  test "năm tiếp theo 5001 vẫn bằng tham chiếu" do
    for delta <- [-17, 0, 17] do
      c = @foundation + delta
      {anchor, state} = Ref.year5000(c)
      {expected, _} = Ref.next_year(c, anchor, state)
      assert Map.from_struct(Calendar.next_year_spaghetti(c)) == Map.from_struct(expected)
    end
  end

  test "gọi lặp lại cùng đầu vào có cùng kết quả" do
    c = @foundation + 47
    assert PreviousYearManager.diagnose(c) == PreviousYearManager.diagnose(c)
    assert PreviousYearSealPatch.diagnose(c, c - 1_000, 9) ==
      PreviousYearSealPatch.diagnose(c, c - 1_000, 9)
  end

  test "gọi song song không chia sẻ state" do
    days = Enum.map(-4..4, &(@foundation + 31 * &1))
    results =
      Task.async_stream(days, &Calendar.previous_year_spaghetti/1,
        max_concurrency: 5, ordered: true, timeout: 30_000)
      |> Enum.map(fn {:ok, year} -> Map.from_struct(year) end)
    assert results == Enum.map(days, &reference_previous/1)
  end

  test "trình tự truy vấn không thay đổi kết quả" do
    days = Enum.map(-3..3, &(@foundation + 57 * &1))
    a = Enum.map(days, &Calendar.previous_year_spaghetti/1)
    b = Enum.map(Enum.reverse(days), &Calendar.previous_year_spaghetti/1) |> Enum.reverse()
    assert a == b
  end

  test "patch trả giá trị phù hợp cả khi miền chỉ có một lựa chọn" do
    report = PreviousYearSealPatch.diagnose(@foundation, @foundation - 99, 1)
    assert report.candidate_count == 1
    assert report.legacy_rank == 1
    assert report.corrected_rank == 1
    refute report.changed
  end

  test "patch báo mức thay đổi một cách trung thực" do
    for delta <- [-13, 1, 79] do
      report = PreviousYearManager.diagnose(@foundation + delta)
      assert report.seal_was_corrected == (report.historical_rank != report.rank)
    end
  end

  test "đầu vào sai phải bị từ chối" do
    for bad <- [nil, 0.5, "1", %{}] do
      assert_raise ArgumentError, fn -> PreviousYearSealPatch.choose_rank(bad, 0, 3) end
      assert_raise ArgumentError, fn -> PreviousYearSealPatch.diagnose(@foundation, bad, 3) end
    end
    for bad <- [0, -1, nil, 1.5, "5"] do
      assert_raise ArgumentError, fn -> PreviousYearSealPatch.diagnose(@foundation, 0, bad) end
    end
  end

  test "cấu trúc Year và GateTimelineManager còn kiểu nguyên bản" do
    report = PreviousYearManager.diagnose(@foundation)
    assert %Year{} = report.year
    assert %GateTimelineManager{} = report.gate_state
    assert is_integer(report.year.open_gate_index)
    assert is_integer(report.year.close_gate_index)
  end

  test "lịch cuối vẫn chưa được tích hợp" do
    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end

  test "kiểm toán source giữ di sản và loại oracle khỏi production" do
    dir = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(dir, "legacy_next_year_seal_for_previous_seed.ex"))
    patch = File.read!(Path.join(dir, "previous_year_seal_patch.ex"))
    manager = File.read!(Path.join(dir, "previous_year_manager.ex"))
    assert legacy =~ "Dispatcher.answer_stream(calculation_day, close_day, 1, 11)"
    assert patch =~ "LegacyNextYearSealForPreviousSeed.choose_rank("
    assert patch =~ "Dispatcher.answer_stream(calculation_day, close_day, 1, 12)"
    assert manager =~ "PreviousYearSealPatch.diagnose(day, close_day, length(candidates))"
    assert manager =~ "rank = seed.corrected_rank"
    refute patch =~ "NormativeReference"
    refute manager =~ "NormativeReference"
  end
end
