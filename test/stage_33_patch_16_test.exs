defmodule PastafariCalendarElixirVietnamese.Stage33Patch16Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    LegacyLongestFirstYear5000,
    ShortestFirstYear5000Patch,
    Year5000CandidateManager,
    Year5000Manager,
    Year
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp oracle_year(c) do
    {year, _state} = Ref.year5000(c)
    Map.from_struct(year)
  end

  defp production_year(c), do: Calendar.year5000_spaghetti(c) |> Map.from_struct()

  test "bốn hồi quy normative Stage32 xanh không thay oracle" do
    for c <- [@foundation, @foundation + 1, @foundation + 417, @foundation - 539] do
      assert production_year(c) == oracle_year(c)
    end
  end

  test "thứ tự sửa đúng cặp độ dài/ngày mở trên mẫu có hòa" do
    samples = [
      %{length: 401, open_gate_day: -9},
      %{length: 300, open_gate_day: 2},
      %{length: 401, open_gate_day: -10},
      %{length: 700, open_gate_day: -20},
      %{length: 300, open_gate_day: -6}
    ]
    corrected = ShortestFirstYear5000Patch.sort(samples)
    assert Enum.map(corrected, &{&1.length, &1.open_gate_day}) ==
      [{300, -6}, {300, 2}, {401, -10}, {401, -9}, {700, -20}]
  end

  test "mô-đun legacy dài-trước vẫn cho kết quả sai cũ" do
    candidates = [
      %{length: 800, open_gate_day: -200},
      %{length: 300, open_gate_day: -100},
      %{length: 500, open_gate_day: -150}
    ]
    assert Enum.map(LegacyLongestFirstYear5000.sort(candidates), & &1.length) ==
      [800, 500, 300]
    assert Enum.map(ShortestFirstYear5000Patch.sort(candidates), & &1.length) ==
      [300, 500, 800]
  end

  test "patch dùng kết quả legacy thực trước khi tái sắp xếp" do
    {candidates, _state} = Year5000CandidateManager.build(@foundation)
    report = ShortestFirstYear5000Patch.diagnose(candidates)
    assert report.historical_order == LegacyLongestFirstYear5000.sort(candidates)
    assert report.corrected_order ==
      Enum.sort_by(candidates, &{&1.length, &1.open_gate_day})
    assert report.changed
    assert report.candidate_count == length(candidates)
  end

  test "mỗi ứng viên giữ nguyên số lượng và chỉ số cổng sau PATCH 16" do
    {candidates, _state} = Year5000CandidateManager.build(@foundation)
    sorted = ShortestFirstYear5000Patch.sort(candidates)
    normalize = fn elements ->
      elements |> Enum.map(&{&1.open_gate_index, &1.close_gate_index}) |> Enum.sort()
    end
    assert length(sorted) == length(candidates)
    assert normalize.(sorted) == normalize.(candidates)
    assert length(normalize.(sorted)) == length(Enum.uniq(normalize.(sorted)))
  end

  test "thứ tự chuẩn tăng dần và giữ tiêu chí phụ ngày mở" do
    sorted = ShortestFirstYear5000Patch.sort(elem(Year5000CandidateManager.build(@foundation), 0))
    assert Enum.chunk_every(sorted, 2, 1, :discard)
      |> Enum.all?(fn [a,b] ->
        a.length < b.length or
        (a.length == b.length and a.open_gate_day <= b.open_gate_day)
      end)
  end

  test "kết quả production chọn đúng ứng viên ở hạng một-based" do
    for c <- [@foundation, @foundation - 1, @foundation + 1, @foundation + 83] do
      report = Year5000Manager.diagnose(c)
      expected = Enum.at(report.corrected_order, report.rank - 1)
      assert report.year.open_gate_index == expected.open_gate_index
      assert report.year.close_gate_index == expected.close_gate_index
      assert report.year.open_gate_day == expected.open_gate_day
      assert report.year.close_gate_day == expected.close_gate_day
    end
  end

  test "xếp hạng dùng đúng bowl 1, seal 10 và cùng số ứng viên" do
    for c <- [@foundation, @foundation + 13, @foundation - 19] do
      report = Year5000Manager.diagnose(c)
      stream = Calendar.answer_stream_spaghetti(c, c, 1, 10)
      assert report.rank == AnswerStreamManager.choose_rank(stream, report.candidate_count)
      assert report.rank in 1..report.candidate_count
      assert report.bowl == 1 and report.seal == 10
    end
  end

  test "bảng gate không đổi khi chuyển đường lựa chọn" do
    for c <- [@foundation - 79, @foundation, @foundation + 79] do
      report = Year5000Manager.diagnose(c)
      reference = Ref.ensure_gates_cover(Ref.new_gate_state(), c - 5_778, c + 5_778)
      assert report.gate_state.gate == reference.gate
    end
  end

  test "trên nhiều ngày không liền nhau năm 5000 khớp oracle" do
    for delta <- [-721, -417, -101, -17, -1, 0, 1, 17, 101, 417, 721] do
      c = @foundation + delta
      assert production_year(c) == oracle_year(c)
    end
  end

  test "hai ngày sát Foundation có ranh giới hợp lệ" do
    for delta <- -2..2 do
      c = @foundation + delta
      year = Calendar.year5000_spaghetti(c)
      assert year.open_gate_day < c and c <= year.close_gate_day
      assert year.close_gate_day - year.open_gate_day in 252..5_778
      assert year.close_gate_index - year.open_gate_index >= 6
    end
  end

  test "diagnostic lưu cả hai thứ tự và cặp chọn thực" do
    report = Calendar.year5000_diagnostic_spaghetti(@foundation)
    assert report.historical_order == LegacyLongestFirstYear5000.sort(report.candidates)
    assert report.corrected_order == ShortestFirstYear5000Patch.sort(report.candidates)
    assert report.order_was_corrected
    assert hd(report.historical_order).length >= hd(report.corrected_order).length
    assert report.year.number == 5000
  end

  test "kiểu Year trong production vẫn có đủ trường bắt buộc" do
    year = Calendar.year5000_spaghetti(@foundation)
    assert %Year{} = year
    assert year.number == 5000
    assert is_integer(year.open_gate_index)
    assert is_integer(year.close_gate_index)
    assert is_integer(year.open_gate_day)
    assert is_integer(year.close_gate_day)
  end

  test "patch không biến đổi các phần tử đầu vào" do
    a = [
      %{length: 555, open_gate_day: -500, open_gate_index: -2},
      %{length: 444, open_gate_day: -400, open_gate_index: -1}
    ]
    snapshot = a
    _sorted = ShortestFirstYear5000Patch.sort(a)
    assert a == snapshot
    assert hd(a).length == 555
  end

  test "trường hợp rỗng giữ danh sách rỗng, không bịa thêm năm" do
    report = ShortestFirstYear5000Patch.diagnose([])
    assert report.historical_order == []
    assert report.corrected_order == []
    assert report.candidate_count == 0
    refute report.changed
  end

  test "đầu vào không phải danh sách bị từ chối" do
    for bad <- [nil, %{}, 1.5, 0, "x"] do
      assert_raise ArgumentError, fn -> ShortestFirstYear5000Patch.sort(bad) end
      assert_raise ArgumentError, fn -> ShortestFirstYear5000Patch.diagnose(bad) end
    end
  end

  test "đồng thời trên nhiều ngày trả đúng oracle không ảnh hưởng state" do
    days = Enum.map(-4..4, &(@foundation + 37 * &1))
    results = Task.async_stream(days, &Calendar.year5000_spaghetti/1,
      max_concurrency: 5, ordered: true, timeout: 30_000)
      |> Enum.map(fn {:ok, year} -> Map.from_struct(year) end)
    expected = Enum.map(days, &oracle_year/1)
    assert results == expected
  end

  test "trạng thái năm không phụ thuộc thứ tự truy vấn" do
    days = [@foundation + 37, @foundation - 33, @foundation + 417]
    a = Enum.map(days, &Calendar.year5000_spaghetti/1)
    b = Enum.map(Enum.reverse(days), &Calendar.year5000_spaghetti/1) |> Enum.reverse()
    assert a == b
  end

  test "không tích hợp lịch cuối trước các bước tiếp theo" do
    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end

  test "kiểm toán mã nguồn bảo vệ legacy, oracle và tuyến lựa chọn" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_longest_first_year5000.ex"))
    patch = File.read!(Path.join(root, "shortest_first_year5000_patch.ex"))
    manager = File.read!(Path.join(root, "year5000_manager.ex"))
    assert legacy =~ "{-candidate.length, candidate.open_gate_day}"
    assert patch =~ "LegacyLongestFirstYear5000.sort(candidates)"
    assert patch =~ "{candidate.length, candidate.open_gate_day}"
    assert manager =~ "ShortestFirstYear5000Patch.diagnose(candidates)"
    assert manager =~ "Enum.at(corrected_order, rank - 1)"
    refute patch =~ "NormativeReference"
    refute manager =~ "NormativeReference"
  end
end
