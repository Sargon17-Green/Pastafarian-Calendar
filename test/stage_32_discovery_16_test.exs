defmodule PastafariCalendarElixirVietnamese.Stage32Discovery16Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    LegacyLongestFirstYear5000,
    Year5000CandidateManager,
    Year5000Manager
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp reference_year(c), do: elem(Ref.year5000(c), 0) |> Map.from_struct()
  defp production_year(c), do: Calendar.year5000_spaghetti(c) |> Map.from_struct()

  test "mốc năm 5000 vẫn là 5000 và có cổng mở/đóng thực" do
    result = Year5000Manager.year5000(@foundation)
    assert result.number == 5000
    assert is_integer(result.open_gate_index)
    assert is_integer(result.close_gate_index)
    assert result.open_gate_index < result.close_gate_index
    assert result.open_gate_day < @foundation
    assert @foundation <= result.close_gate_day
  end

  test "chỉ số cổng và độ dài của năm được chọn đáp ứng giới hạn" do
    for c <- [@foundation, @foundation + 31, @foundation - 31] do
      year = Calendar.year5000_spaghetti(c)
      assert year.close_gate_index - year.open_gate_index >= 6
      assert year.close_gate_day - year.open_gate_day in 252..5_778
      assert year.open_gate_day < c
      assert c <= year.close_gate_day
    end
  end

  test "bảng cổng phủ đủ cửa sổ quanh ngày tính" do
    for c <- [@foundation, @foundation + 17, @foundation - 17] do
      report = Year5000Manager.diagnose(c)
      state = report.gate_state
      assert state.gate[state.min_index] <= c - 5_778
      assert state.gate[state.max_index] >= c + 5_778
      assert state.min_index < 0 and state.max_index > 0
    end
  end

  test "các cổng trong cửa sổ khớp oracle cả hai hướng" do
    c = @foundation + 37
    report = Year5000Manager.diagnose(c)
    reference = Ref.ensure_gates_cover(Ref.new_gate_state(), c - 5_778, c + 5_778)
    assert report.gate_state.gate == reference.gate
    assert report.gate_state.min_index == reference.min_index
    assert report.gate_state.max_index == reference.max_index
  end

  test "bộ chọn ứng viên tuân thủ tất cả quy tắc lọc" do
    for c <- [@foundation, @foundation - 19] do
      {candidates, _state} = Year5000CandidateManager.build(c)
      assert length(candidates) > 1
      for candidate <- candidates do
        assert candidate.close_gate_index > candidate.open_gate_index
        assert candidate.close_gate_index - candidate.open_gate_index >= 6
        assert candidate.length in 252..5_778
        assert candidate.length == candidate.close_gate_day - candidate.open_gate_day
        assert candidate.open_gate_day < c
        assert c <= candidate.close_gate_day
      end
    end
  end

  test "tập ứng viên không mất hay thêm cặp nào so với oracle" do
    c = @foundation + 71
    {candidates, _state} = Year5000CandidateManager.build(c)
    reference = Ref.ensure_gates_cover(Ref.new_gate_state(), c - 5_778, c + 5_778)
    indices = Enum.to_list(reference.min_index..reference.max_index)
    expected =
      for i <- indices, j <- indices, i < j,
          j-i >= 6,
          Map.fetch!(reference.gate, j) - Map.fetch!(reference.gate, i) in 252..5_778,
          Map.fetch!(reference.gate, i) < c,
          c <= Map.fetch!(reference.gate, j) do
        {i, j}
      end
    actual = Enum.map(candidates, &{&1.open_gate_index, &1.close_gate_index})
    assert Enum.sort(actual) == Enum.sort(expected)
    assert length(actual) == length(Enum.uniq(actual))
  end

  test "mô-đun legacy thực sự đảo thứ tự độ dài trên mẫu kiểm soát" do
    candidates = [
      %{length: 400, open_gate_day: 2},
      %{length: 300, open_gate_day: 3},
      %{length: 400, open_gate_day: 1},
      %{length: 800, open_gate_day: 4}
    ]
    sorted = LegacyLongestFirstYear5000.sort(candidates)
    assert Enum.map(sorted, &{&1.length, &1.open_gate_day}) ==
             [{800,4}, {400,1}, {400,2}, {300,3}]
  end

  test "thứ tự legacy trái với quy tắc ưu tiên năm ngắn" do
    report = Year5000Manager.diagnose(@foundation)
    assert length(report.candidates) > 1
    assert report.historical_order == LegacyLongestFirstYear5000.sort(report.candidates)
    assert hd(report.historical_order).length == Enum.max_by(report.candidates, & &1.length).length
    assert List.last(report.historical_order).length == Enum.min_by(report.candidates, & &1.length).length
  end

  test "đầu vào nằm trên cổng đóng được phép, trên cổng mở bị loại" do
    c = @foundation
    report = Year5000Manager.diagnose(c)
    for candidate <- report.candidates do
      assert candidate.open_gate_day != c
      assert candidate.close_gate_day >= c
    end
  end

  test "rank được lấy từ bát 1, chốt 10 và cùng answer stream" do
    c = @foundation + 17
    report = Year5000Manager.diagnose(c)
    stream = Calendar.answer_stream_spaghetti(c, c, 1, 10)
    expected = AnswerStreamManager.choose_rank(stream, report.candidate_count)
    assert report.bowl == 1
    assert report.seal == 10
    assert report.rank == expected
    assert report.rank in 1..report.candidate_count
  end

  test "bản sản xuất chọn từ danh sách đã sửa, legacy vẫn lưu nguyên" do
    for c <- [@foundation, @foundation + 31] do
      report = Year5000Manager.diagnose(c)
      selected = Enum.at(report.corrected_order, report.rank - 1)
      assert report.historical_order == LegacyLongestFirstYear5000.sort(report.candidates)
      assert report.year.open_gate_index == selected.open_gate_index
      assert report.year.close_gate_index == selected.close_gate_index
      assert Calendar.year5000_spaghetti(c) == report.year
    end
  end

  test "không có ứng viên nào dài hơn trần 5778 ngày" do
    {candidates, _} = Year5000CandidateManager.build(@foundation)
    assert Enum.all?(candidates, &(&1.length <= 5_778))
    assert Enum.any?(candidates, &(&1.length >= 252))
  end

  test "mỗi phần tử thứ tự legacy xuất hiện đúng một lần" do
    report = Year5000Manager.diagnose(@foundation)
    expected = Enum.sort_by(report.candidates, &{&1.open_gate_index, &1.close_gate_index})
    actual = Enum.sort_by(report.historical_order, &{&1.open_gate_index, &1.close_gate_index})
    assert actual == expected
  end

  test "cùng ngày tính cho kết quả bất biến khi gọi lại" do
    c = @foundation - 47
    a = Year5000Manager.diagnose(c)
    b = Year5000Manager.diagnose(c)
    assert a == b
    assert Calendar.year5000_spaghetti(c) == a.year
  end

  test "API công khai không gọi bộ tham chiếu trong production" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_longest_first_year5000.ex"))
    selector = File.read!(Path.join(root, "year5000_manager.ex"))
    candidates = File.read!(Path.join(root, "year5000_candidate_manager.ex"))
    assert legacy =~ "{-candidate.length, candidate.open_gate_day}"
    assert selector =~ "ShortestFirstYear5000Patch.diagnose(candidates)"
    assert selector =~ "Enum.at(corrected_order, rank - 1)"
    assert candidates =~ "GateTimelineManager.ensure_index"
    refute selector =~ "NormativeReference"
    assert File.exists?(Path.join(root, "shortest_first_year5000_patch.ex"))
  end

  test "đầu vào năm 5000 phải là số nguyên" do
    for bad <- [nil, "0", 1.5, %{}] do
      assert_raise ArgumentError, fn -> Year5000CandidateManager.build(bad) end
      assert_raise ArgumentError, fn -> Year5000Manager.diagnose(bad) end
    end
  end

  test "hồi quy normative đỏ: năm 5000 tại Ngày Nền" do
    c = @foundation
    assert production_year(c) == reference_year(c)
  end

  test "hồi quy normative đỏ: năm 5000 ngày kế tiếp" do
    c = @foundation + 1
    assert production_year(c) == reference_year(c)
  end

  test "hồi quy normative đỏ: năm 5000 tại mốc +417" do
    c = @foundation + 417
    assert production_year(c) == reference_year(c)
  end

  test "hồi quy normative đỏ: năm 5000 tại mốc -539" do
    c = @foundation - 539
    assert production_year(c) == reference_year(c)
  end
end
