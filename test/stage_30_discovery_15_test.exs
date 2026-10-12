defmodule PastafariCalendarElixirVietnamese.Stage30Discovery15Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    GateGapManager,
    GateTimelineManager,
    LegacyMirroredNegativeGateGap
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp reference_gate(index) do
    state = Ref.ensure_gate_index(Ref.new_gate_state(), index)
    Map.fetch!(state.gate, index)
  end

  test "cổng 0 đúng Ngày Nền mà không chạy bất kỳ vòng sauce nào" do
    state = GateTimelineManager.new()
    assert state.gate == %{0 => @foundation}
    assert state.min_index == 0 and state.max_index == 0
    assert GateTimelineManager.foundation_day() == Ref.foundation_day()
    assert Calendar.gate_day_spaghetti(0) == @foundation
    assert reference_gate(0) == @foundation
  end

  test "khoảng cách phía dương đúng cả bốn giá trị đầu" do
    for n <- 1..4 do
      assert GateGapManager.positive_gap(n) == Ref.positive_gate_gap(n)
      assert Calendar.positive_gate_gap_spaghetti(n) == Ref.positive_gate_gap(n)
    end
  end

  test "mỗi ngày cổng dương trùng oracle và cộng dồn từ cùng neo" do
    state = Calendar.gate_state_spaghetti(4)
    assert state.gate[0] == @foundation
    assert state.min_index == 0 and state.max_index == 4
    for n <- 1..4 do
      assert state.gate[n] == reference_gate(n)
      assert state.gate[n] - state.gate[n - 1] == GateGapManager.positive_gap(n)
    end
  end

  test "legacy phía âm cố ý dùng cùng hạt với phía dương" do
    for n <- 1..4 do
      assert LegacyMirroredNegativeGateGap.negative_gap(n) ==
               GateGapManager.positive_gap(n)
      assert GateGapManager.negative_gap(n) ==
               LegacyMirroredNegativeGateGap.negative_gap(n)
    end
  end

  test "cổng âm sản xuất thật trừ các gap của nhánh sai" do
    state = Calendar.gate_state_spaghetti(-4)
    assert state.gate[0] == @foundation
    assert state.min_index == -4 and state.max_index == 0
    for n <- 1..4 do
      assert state.gate[-n] == state.gate[1 - n] - GateGapManager.negative_gap(n)
      assert Calendar.gate_day_spaghetti(-n) == state.gate[-n]
    end
  end

  test "độ dài mọi gap thuộc miền chuẩn 42..963" do
    for n <- 1..4 do
      assert GateGapManager.positive_gap(n) in 42..963
      assert GateGapManager.negative_gap(n) in 42..963
    end
  end

  test "trình tự âm giảm nghiêm ngặt và dương tăng nghiêm ngặt" do
    for n <- 1..3 do
      assert Calendar.gate_day_spaghetti(-(n + 1)) < Calendar.gate_day_spaghetti(-n)
      assert Calendar.gate_day_spaghetti(n + 1) > Calendar.gate_day_spaghetti(n)
    end
  end

  test "mở bên dương trước rồi bên âm giữ nguyên dữ liệu dương" do
    base = GateTimelineManager.new()
    pos = GateTimelineManager.ensure_index(base, 3)
    both = GateTimelineManager.ensure_index(pos, -3)
    assert base.gate == %{0 => @foundation}
    assert pos.gate == Map.take(both.gate, [0, 1, 2, 3])
    assert both.min_index == -3 and both.max_index == 3
  end

  test "mở bên âm trước rồi dương tạo cùng trạng thái hai phía" do
    a = GateTimelineManager.new()
        |> GateTimelineManager.ensure_index(-3)
        |> GateTimelineManager.ensure_index(3)
    b = GateTimelineManager.new()
        |> GateTimelineManager.ensure_index(3)
        |> GateTimelineManager.ensure_index(-3)
    assert a == b
    assert Map.keys(a.gate) |> Enum.sort() == Enum.to_list(-3..3)
  end

  test "đọc chỉ số đã lưu không gọi tính lại hoặc thay đổi state" do
    state = GateTimelineManager.ensure_index(GateTimelineManager.new(), -2)
    {day, same_state} = GateTimelineManager.day_at(state, -1)
    assert day == state.gate[-1]
    assert same_state == state
    assert GateTimelineManager.ensure_index(state, -2) == state
  end

  test "điểm +1 và -1 nằm hai phía Ngày Nền" do
    assert Calendar.gate_day_spaghetti(1) > @foundation
    assert Calendar.gate_day_spaghetti(-1) < @foundation
    assert Calendar.gate_day_spaghetti(1) - @foundation ==
             Calendar.positive_gate_gap_spaghetti(1)
    assert @foundation - Calendar.gate_day_spaghetti(-1) ==
             Calendar.negative_gate_gap_spaghetti(1)
  end

  test "public và tầng quản lý dùng cùng kết quả trên cổng hai chiều" do
    for index <- -3..3 do
      assert Calendar.gate_day_spaghetti(index) == GateTimelineManager.gate_day(index)
      assert Calendar.gate_state_spaghetti(index).gate[index] == Calendar.gate_day_spaghetti(index)
    end
  end

  test "ngữ cảnh khác nhau không dùng bản đồ cổng toàn cục" do
    a = GateTimelineManager.ensure_index(GateTimelineManager.new(), 3)
    b = GateTimelineManager.ensure_index(GateTimelineManager.new(), -3)
    assert Map.keys(a.gate) |> Enum.sort() == Enum.to_list(0..3)
    assert Map.keys(b.gate) |> Enum.sort() == Enum.to_list(-3..0)
    assert GateTimelineManager.new().gate == %{0 => @foundation}
  end

  test "giữ kết quả ổn định khi đọc đồng thời" do
    indices = [-2, -1, 0, 1, 2]
    results =
      Task.async_stream(indices, &Calendar.gate_day_spaghetti/1,
        max_concurrency: 5, ordered: true, timeout: 20_000)
      |> Enum.map(fn {:ok, value} -> value end)
    assert results == Enum.map(indices, &GateTimelineManager.gate_day/1)
  end

  test "loại bỏ tham số cổng và gap không hợp lệ" do
    for bad <- [0, -1, nil, 1.5, "1"] do
      assert_raise ArgumentError, fn -> GateGapManager.positive_gap(bad) end
      assert_raise ArgumentError, fn -> GateGapManager.negative_gap(bad) end
      assert_raise ArgumentError, fn -> LegacyMirroredNegativeGateGap.negative_gap(bad) end
    end
    for bad <- [nil, 0.25, "0"] do
      assert_raise ArgumentError, fn -> GateTimelineManager.gate_day(bad) end
      assert_raise ArgumentError, fn -> GateTimelineManager.ensure_index(GateTimelineManager.new(), bad) end
    end
    assert_raise ArgumentError, fn -> GateTimelineManager.day_at(%{}, 0) end
  end

  test "kiểm toán nguồn: cổng âm dùng dấu cộng sai, chưa có PATCH 15" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_mirrored_negative_gate_gap.ex"))
    gap = File.read!(Path.join(root, "gate_gap_manager.ex"))
    timeline = File.read!(Path.join(root, "gate_timeline_manager.ex"))
    dispatcher = File.read!(Path.join(root, "dispatcher.ex"))
    assert legacy =~ "@foundation + n"
    assert legacy =~ "Dispatcher.answer_stream"
    assert gap =~ "LegacyMirroredNegativeGateGap.negative_gap(n)"
    assert timeline =~ "GateGapManager.negative_gap(abs(n))"
    assert dispatcher =~ "GateTimelineManager.gate_day(index)"
    refute legacy =~ "NormativeReference"
    refute File.exists?(Path.join(root, "negative_gate_gap_patch.ex"))
  end

  test "hồi quy chuẩn đỏ: cổng -1 phải dùng FOUNDATION-1" do
    assert Calendar.gate_day_spaghetti(-1) == reference_gate(-1)
  end

  test "hồi quy chuẩn đỏ: cổng -2 phải dùng FOUNDATION-2" do
    assert Calendar.gate_day_spaghetti(-2) == reference_gate(-2)
  end

  test "hồi quy chuẩn đỏ: cổng -3 phải dùng FOUNDATION-3" do
    assert Calendar.gate_day_spaghetti(-3) == reference_gate(-3)
  end

  test "hồi quy chuẩn đỏ: cổng -4 phải dùng FOUNDATION-4" do
    assert Calendar.gate_day_spaghetti(-4) == reference_gate(-4)
  end
end
