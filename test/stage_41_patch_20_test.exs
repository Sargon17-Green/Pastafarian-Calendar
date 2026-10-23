defmodule PastafariCalendarElixirVietnamese.Stage41Patch20Test do
  use ExUnit.Case, async: true
  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AscendingCutletCountPatch, AnswerStreamManager, CutletCountManager,
    LegacyDescendingCutletCount, TargetYearManager
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  @foundation -15_055_671

  defp oracle(c, t) do
    {year, _} = Ref.find_target_year(c, t)
    Ref.choose_cutlet_count(Ref.sauce(c, year.open_gate_day + 1), year)
  end

  test "bốn hồi quy Stage40 trở lại xanh, expected không đổi" do
    for delta <- [-721, -539, -417, -101, -17, -3, -1, 0, 1, 3, 17, 71, 101, 417, 721] do
      c = @foundation + delta
      assert Calendar.cutlet_count_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "năm neo và bốn cổng đóng khớp oracle" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      target = Calendar.year5000_spaghetti(c).close_gate_day
      assert Calendar.cutlet_count_spaghetti(c, target) == oracle(c, target)
    end
  end

  test "danh sách được sắp tăng dần kể cả các mẫu rỗng" do
    assert AscendingCutletCountPatch.sort([8, 6, 9, 7]) == [6, 7, 8, 9]
    assert AscendingCutletCountPatch.sort([]) == []
  end

  test "mô-đun di sản vẫn sai như trước" do
    assert LegacyDescendingCutletCount.sort([6, 7, 8, 9]) == [9, 8, 7, 6]
    assert AscendingCutletCountPatch.sort([6, 7, 8, 9]) == [6, 7, 8, 9]
  end

  test "patch thật sự gọi di sản rồi sửa lại thứ tự" do
    r = CutletCountManager.diagnose(@foundation, @foundation)
    patch = AscendingCutletCountPatch.diagnose(r.candidates)
    assert patch.historical_order == LegacyDescendingCutletCount.sort(r.candidates)
    assert patch.corrected_order == r.candidates
    assert patch.changed
    assert patch.candidate_count == r.candidate_count
  end

  test "production lấy đúng ứng viên thứ rank trong thứ tự tăng" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      r = CutletCountManager.diagnose(c, c)
      assert r.cutlet_count == Enum.at(r.corrected_order, r.rank - 1)
      assert r.corrected_order == r.candidates
      assert r.order_was_corrected
    end
  end

  test "rank vẫn đến từ bát 2 chốt 20" do
    for delta <- [-37, 0, 37] do
      c = @foundation + delta
      r = CutletCountManager.diagnose(c, c)
      stream = Calendar.answer_stream_spaghetti(c, r.structure_source_day, 2, 20)
      assert r.rank == AnswerStreamManager.choose_rank(stream, r.candidate_count)
      assert r.rank in 1..r.candidate_count
      assert r.bowl == 2 and r.seal == 20
    end
  end

  test "nguồn sauce là ngày đầu năm đích" do
    r = CutletCountManager.diagnose(@foundation + 83, @foundation + 83)
    assert r.structure_source_day == r.year.open_gate_day + 1
    assert r.calculation_day == @foundation + 83
  end

  test "năm đích vẫn được tìm độc lập và đúng" do
    c = @foundation
    r = CutletCountManager.diagnose(c, c)
    assert r.year == TargetYearManager.find(c, c)
    assert r.gate_state == TargetYearManager.diagnose(c, c).gate_state
  end

  test "năm 5000 đúng dù đã thêm tầng cốt-lết" do
    for delta <- [-417, 0, 417] do
      c = @foundation + delta
      actual = Calendar.year5000_spaghetti(c) |> Map.from_struct()
      expected = elem(Ref.year5000(c), 0) |> Map.from_struct()
      assert actual == expected
    end
  end

  test "năm 4999 không hồi quy do PATCH20" do
    c = @foundation
    actual = Calendar.previous_year_spaghetti(c) |> Map.from_struct()
    {anchor, state} = Ref.year5000(c)
    expected = elem(Ref.previous_year(c, anchor, state), 0) |> Map.from_struct()
    assert actual == expected
  end

  test "năm 5001 không hồi quy do PATCH20" do
    c = @foundation
    actual = Calendar.next_year_spaghetti(c) |> Map.from_struct()
    {anchor, state} = Ref.year5000(c)
    expected = elem(Ref.next_year(c, anchor, state), 0) |> Map.from_struct()
    assert actual == expected
  end

  test "cổng đóng vẫn thuộc năm hiện tại" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = CutletCountManager.diagnose(c, year.close_gate_day)
    assert r.year == year
    assert r.cutlet_count == oracle(c, year.close_gate_day)
  end

  test "tập ứng viên không bị thay bởi bản vá" do
    for delta <- [-53, 0, 53] do
      c = @foundation + delta
      r = CutletCountManager.diagnose(c, c)
      assert r.candidates == Enum.to_list(6..min(17, r.gate_gaps))
      assert r.historical_order == Enum.reverse(r.candidates)
      assert Enum.sort(r.historical_order) == r.corrected_order
    end
  end

  test "trường hợp chỉ có một ứng viên vẫn đúng" do
    patch = AscendingCutletCountPatch.diagnose([6])
    assert patch.corrected_order == [6]
    assert patch.historical_order == [6]
    refute patch.changed
  end

  test "đầu vào không hợp lệ bị từ chối" do
    for bad <- [nil, 1.5, 0, "3", %{}] do
      assert_raise ArgumentError, fn -> AscendingCutletCountPatch.diagnose(bad) end
    end
    assert_raise ArgumentError, fn -> CutletCountManager.diagnose(nil, @foundation) end
  end

  test "cùng đầu vào cho kết quả bất biến" do
    c = @foundation - 113
    assert CutletCountManager.diagnose(c, c) == CutletCountManager.diagnose(c, c)
  end

  test "song song cho kết quả bằng oracle" do
    days = Enum.map(-3..3, &(@foundation + &1 * 37))
    res = Task.async_stream(days,
      fn c -> Calendar.cutlet_count_spaghetti(c, c) end,
      max_concurrency: 4, ordered: true, timeout: 60_000)
      |> Enum.map(fn {:ok, v} -> v end)
    assert res == Enum.map(days, fn c -> oracle(c, c) end)
  end

  test "bước cuối của lịch vẫn chưa được tích hợp" do
    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end

  test "kiểm toán source: legacy nguyên vẹn, PATCH20 không gọi oracle" do
    dir = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(dir, "legacy_descending_cutlet_count.ex"))
    patch = File.read!(Path.join(dir, "ascending_cutlet_count_patch.ex"))
    manager = File.read!(Path.join(dir, "cutlet_count_manager.ex"))
    assert legacy =~ "Enum.sort(candidates, :desc)"
    assert patch =~ "LegacyDescendingCutletCount.sort(candidates)"
    assert patch =~ "Enum.sort(historical_order)"
    assert manager =~ "AscendingCutletCountPatch.diagnose(candidates)"
    assert manager =~ "Enum.at(corrected_order, rank - 1)"
    refute patch =~ "NormativeReference"
    refute manager =~ "NormativeReference"
  end
end
