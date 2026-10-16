defmodule PastafariCalendarElixirVietnamese.Stage36Discovery18ControlsTest do
  use ExUnit.Case, async: true
  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    LegacyNextYearSealForPreviousSeed,
    PreviousYearCandidateManager,
    PreviousYearManager,
    Year5000Manager,
    Year
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  @foundation -15_055_671

  test "năm trước năm neo có số 4999" do
    assert %Year{number: 4999} = Calendar.previous_year_spaghetti(@foundation)
  end

  test "cổng đóng năm trước trùng cổng mở năm 5000" do
    for offset <- [-37, 0, 17] do
      report = PreviousYearManager.diagnose(@foundation + offset)
      assert report.year.close_gate_index == report.known_year.open_gate_index
      assert report.year.close_gate_day == report.known_year.open_gate_day
    end
  end

  test "năm trước đủ khoảng và độ dài" do
    for offset <- [-539, 0, 417] do
      y = Calendar.previous_year_spaghetti(@foundation + offset)
      assert y.close_gate_index - y.open_gate_index >= 6
      assert y.close_gate_day - y.open_gate_day in 252..5_778
    end
  end

  test "bảng gate trải xuống tới close_day-5778" do
    report = PreviousYearManager.diagnose(@foundation + 11)
    assert report.gate_state.gate[report.gate_state.min_index] <=
      report.year.close_gate_day - 5_778
  end

  test "tập ứng viên chỉ bao gồm cổng hợp lệ" do
    for offset <- [-41, 0, 41] do
      r = PreviousYearManager.diagnose(@foundation + offset)
      assert r.candidate_count > 0
      for i <- r.candidates do
        assert r.year.close_gate_index - i >= 6
        assert r.year.close_gate_day - r.gate_state.gate[i] in 252..5_778
      end
    end
  end

  test "ứng viên năm trước được sắp ngắn trước dài" do
    r = PreviousYearManager.diagnose(@foundation)
    lengths = Enum.map(r.candidates, &(r.year.close_gate_day - r.gate_state.gate[&1]))
    assert lengths == Enum.sort(lengths)
  end

  test "ứng viên trùng tập độc lập từ oracle" do
    c = @foundation + 19
    anchor = Year5000Manager.diagnose(c)
    {candidates, state} = PreviousYearCandidateManager.build(anchor.year, anchor.gate_state)
    close_index = anchor.year.open_gate_index
    close_day = anchor.year.open_gate_day
    ref = Ref.ensure_gates_cover(Ref.new_gate_state(), close_day - 5_778, state.gate[state.max_index])
    expected =
      ref.min_index..(close_index - 1)
      |> Enum.filter(fn i -> close_index - i >= 6 and close_day - ref.gate[i] in 252..5_778 end)
      |> Enum.sort_by(&(close_day - ref.gate[&1]))
    assert candidates == expected
    assert length(candidates) == length(Enum.uniq(candidates))
  end

  test "ngày hỏi đúng nhưng chốt legacy 11 sai" do
    r = PreviousYearManager.diagnose(@foundation + 17)
    assert r.source_day == r.known_year.open_gate_day
    assert r.bowl == 1
    assert r.historical_seal == 11
    assert r.normative_seal == 12
  end

  test "rank legacy đến từ bát 1 chốt 11" do
    c = @foundation - 37
    r = PreviousYearManager.diagnose(c)
    stream = Calendar.answer_stream_spaghetti(c, r.source_day, 1, 11)
    assert r.rank == AnswerStreamManager.choose_rank(stream, r.candidate_count)
    assert r.rank == LegacyNextYearSealForPreviousSeed.choose_rank(c, r.source_day, r.candidate_count)
  end

  test "chọn năm sản xuất từ vị trí rank one-based" do
    r = PreviousYearManager.diagnose(@foundation + 2)
    assert r.year.open_gate_index == Enum.at(r.candidates, r.rank - 1)
    assert r.year.open_gate_day == r.gate_state.gate[r.year.open_gate_index]
  end

  test "năm 5000 giữ chính xác theo oracle" do
    for offset <- [-539, 0, 417] do
      c = @foundation + offset
      assert Map.from_struct(Calendar.year5000_spaghetti(c)) ==
        Map.from_struct(elem(Ref.year5000(c), 0))
    end
  end

  test "năm 5001 vẫn đúng sau PATCH 17" do
    for offset <- [0, 2] do
      c = @foundation + offset
      {anchor, state} = Ref.year5000(c)
      {ref_year, _} = Ref.next_year(c, anchor, state)
      assert Map.from_struct(Calendar.next_year_spaghetti(c)) == Map.from_struct(ref_year)
    end
  end

  test "đọc lại không thay trạng thái" do
    c = @foundation + 17
    assert PreviousYearManager.diagnose(c) == PreviousYearManager.diagnose(c)
  end

  test "mở gate âm không phá dữ liệu năm neo" do
    anchor = Year5000Manager.diagnose(@foundation)
    prev = PreviousYearManager.diagnose(@foundation)
    for {i, day} <- anchor.gate_state.gate, do: assert(prev.gate_state.gate[i] == day)
  end

  test "đầu vào sai bị từ chối" do
    for bad <- [nil, 1.5, "1", %{}] do
      assert_raise ArgumentError, fn -> PreviousYearManager.diagnose(bad) end
      assert_raise ArgumentError, fn -> LegacyNextYearSealForPreviousSeed.choose_rank(bad, 0, 3) end
    end
    for bad <- [0, -1, nil] do
      assert_raise ArgumentError, fn -> LegacyNextYearSealForPreviousSeed.choose_rank(@foundation, 0, bad) end
    end
  end

  test "kiểm toán source: legacy chốt 11, chưa có PATCH 18" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_next_year_seal_for_previous_seed.ex"))
    manager = File.read!(Path.join(root, "previous_year_manager.ex"))
    assert legacy =~ "Dispatcher.answer_stream(calculation_day, close_day, 1, 11)"
    assert manager =~ "LegacyNextYearSealForPreviousSeed.choose_rank("
    refute File.exists?(Path.join(root, "previous_year_seal_patch.ex"))
    refute manager =~ "NormativeReference"
  end
end
