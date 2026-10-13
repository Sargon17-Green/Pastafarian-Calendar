defmodule PastafariCalendarElixirVietnamese.Stage31Patch15Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    GateGapManager,
    GateTimelineManager,
    LegacyMirroredNegativeGateGap,
    NegativeGateGapPatch,
    StageNotIntegratedError
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp oracle_gate(index) do
    Ref.ensure_gate_index(Ref.new_gate_state(), index).gate[index]
  end

  test "bốn hồi quy normative Stage30 giữ nguyên và nay đều xanh" do
    for n <- 1..4 do
      assert Calendar.gate_day_spaghetti(-n) == oracle_gate(-n)
    end
  end

  test "tám khoảng cách âm đầu đúng theo oracle" do
    for n <- 1..8 do
      assert NegativeGateGapPatch.negative_gap(n) == Ref.negative_gate_gap(n)
      assert GateGapManager.negative_gap(n) == Ref.negative_gate_gap(n)
      assert Calendar.negative_gate_gap_spaghetti(n) == Ref.negative_gate_gap(n)
    end
  end

  test "bản vá tiếp tục gọi legacy thật và lưu kết quả sai" do
    for n <- 1..4 do
      report = NegativeGateGapPatch.diagnose(n)
      assert report.legacy_gap == LegacyMirroredNegativeGateGap.negative_gap(n)
      assert report.legacy_gap == Ref.positive_gate_gap(n)
      assert report.corrected_gap == Ref.negative_gate_gap(n)
      assert report.correction == report.corrected_gap - report.legacy_gap
      refute report.corrected_gap == report.legacy_gap
    end
  end

  test "trace dùng FOUNDATION-n nhưng lưu FOUNDATION+n lịch sử" do
    for n <- 1..8 do
      report = NegativeGateGapPatch.diagnose(n)
      assert report.index == -n
      assert report.historical_source_day == @foundation + n
      assert report.corrected_source_day == @foundation - n
      assert report.bowl == 1
      assert report.seal == 1
      assert report.choice_span == 922
    end
  end

  test "cổng dương vẫn có kết quả cũ chính xác" do
    for n <- 1..8 do
      assert Calendar.positive_gate_gap_spaghetti(n) == Ref.positive_gate_gap(n)
      assert Calendar.gate_day_spaghetti(n) == oracle_gate(n)
    end
  end

  test "tất cả cổng hai phía trong -8..8 trùng oracle" do
    for index <- -8..8 do
      assert Calendar.gate_day_spaghetti(index) == oracle_gate(index)
    end
  end

  test "cổng âm mở rộng bằng đúng khoảng cách chuẩn" do
    state = Calendar.gate_state_spaghetti(-8)
    assert state.min_index == -8 and state.max_index == 0
    for n <- 1..8 do
      assert state.gate[1 - n] - state.gate[-n] == Ref.negative_gate_gap(n)
      assert state.gate[-n] == oracle_gate(-n)
    end
  end

  test "trạng thái cổng không biến đổi các ảnh chụp cũ" do
    initial = GateTimelineManager.new()
    first = GateTimelineManager.ensure_index(initial, -1)
    second = GateTimelineManager.ensure_index(first, -2)
    assert initial.gate == %{0 => @foundation}
    assert first.gate[-1] == oracle_gate(-1)
    assert is_nil(first.gate[-2])
    assert second.gate[-1] == first.gate[-1]
    assert second.gate[-2] == oracle_gate(-2)
  end

  test "hai thứ tự mở rộng trái phải cho kết quả tương đương" do
    a = GateTimelineManager.new()
        |> GateTimelineManager.ensure_index(-5)
        |> GateTimelineManager.ensure_index(5)
    b = GateTimelineManager.new()
        |> GateTimelineManager.ensure_index(5)
        |> GateTimelineManager.ensure_index(-5)
    assert a == b
    for i <- -5..5, do: assert(a.gate[i] == oracle_gate(i))
  end

  test "truy xuất cổng đã lưu giữ nguyên trạng thái" do
    state = GateTimelineManager.ensure_index(GateTimelineManager.new(), -4)
    {day, same} = GateTimelineManager.day_at(state, -3)
    assert day == oracle_gate(-3)
    assert same == state
  end

  test "cùng khoảng cách âm cho cùng đầu vào khi gọi lại" do
    for n <- 1..7 do
      expected = Ref.negative_gate_gap(n)
      assert NegativeGateGapPatch.negative_gap(n) == expected
      assert NegativeGateGapPatch.negative_gap(n) == expected
    end
  end

  test "n số nguyên lớn 2048 bit không bị cắt ngắn" do
    n = (1 <<< 2048) + 7
    report = NegativeGateGapPatch.diagnose(n)
    assert report.corrected_source_day == @foundation - n
    assert report.historical_source_day == @foundation + n
    assert report.corrected_gap == Ref.negative_gate_gap(n)
    assert report.legacy_gap == Ref.positive_gate_gap(n)
  end

  test "sử dụng đồng thời không tạo trạng thái dùng chung" do
    indices = Enum.to_list(1..8)
    results = Task.async_stream(indices, &NegativeGateGapPatch.negative_gap/1,
      max_concurrency: 6, ordered: true, timeout: 25_000)
      |> Enum.map(fn {:ok, value} -> value end)
    assert results == Enum.map(indices, &Ref.negative_gate_gap/1)
  end

  test "mọi khoảng cách hai phía nằm trong 42..963" do
    for n <- 1..8 do
      assert GateGapManager.positive_gap(n) in 42..963
      assert GateGapManager.negative_gap(n) in 42..963
    end
  end

  test "cổng âm giảm nghiêm ngặt sau bản vá" do
    state = Calendar.gate_state_spaghetti(-8)
    for n <- 1..8, do: assert(state.gate[-n] < state.gate[1 - n])
  end

  test "đầu vào sai bị từ chối đúng tại patch" do
    for n <- [0, -1, nil, 1.5, "3", [], %{}] do
      assert_raise ArgumentError, "chỉ số khoảng cách cổng âm phải dương", fn ->
        NegativeGateGapPatch.negative_gap(n)
      end
      assert_raise ArgumentError, "chỉ số khoảng cách cổng âm phải dương", fn ->
        NegativeGateGapPatch.diagnose(n)
      end
    end
  end

  test "ngày lịch cuối vẫn chưa được tích hợp" do
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "hàm legacy không bị thay bằng oracle" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_mirrored_negative_gate_gap.ex"))
    patch = File.read!(Path.join(root, "negative_gate_gap_patch.ex"))
    manager = File.read!(Path.join(root, "gate_gap_manager.ex"))
    timeline = File.read!(Path.join(root, "gate_timeline_manager.ex"))
    assert legacy =~ "Dispatcher.answer_stream(@foundation, @foundation + n, 1, 1)"
    assert patch =~ "LegacyMirroredNegativeGateGap.negative_gap(n)"
    assert patch =~ "source_day = @foundation - n"
    assert manager =~ "NegativeGateGapPatch.negative_gap(n)"
    assert timeline =~ "GateGapManager.negative_gap(abs(n))"
    refute patch =~ "NormativeReference"
  end
end
