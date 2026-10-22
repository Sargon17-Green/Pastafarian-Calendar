defmodule PastafariCalendarElixirVietnamese.Stage46Discovery23Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    Cutlet,
    CutletMaterializationManager,
    CutletNameIndexManager,
    LegacyInclusiveCutletFirstDay,
    StageNotIntegratedError
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp oracle(c, t) do
    {year, state} = Ref.find_target_year(c, t)
    sauce = Ref.sauce(c, year.open_gate_day + 1)
    count = Ref.choose_cutlet_count(sauce, year)
    {partition, state2} = Ref.choose_cutlet_partition(c, sauce, year, count, state)
    names = Ref.choose_cutlet_name_indices(sauce, count)
    Ref.materialize_cutlets(year, partition, names, state2)
    |> Enum.map(&Map.from_struct/1)
  end

  defp actual(c, t) do
    Calendar.materialized_cutlets_spaghetti(c, t)
    |> Enum.map(&Map.from_struct/1)
  end

  test "số lượng cốt-lết khớp số đã chọn" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      report = CutletMaterializationManager.diagnose(c, c)
      assert length(report.cutlets) == report.cutlet_count
      assert length(report.cutlet_partition) == report.cutlet_count
      assert length(report.name_indices) == report.cutlet_count
    end
  end

  test "mỗi phần tử vật chất hóa có đúng kiểu và trường" do
    report = CutletMaterializationManager.diagnose(@foundation, @foundation)
    for cutlet <- report.cutlets do
      assert %Cutlet{} = cutlet
      assert is_integer(cutlet.name_index)
      assert is_integer(cutlet.first_day)
      assert is_integer(cutlet.last_day)
      assert is_integer(cutlet.open_gate_index)
      assert is_integer(cutlet.close_gate_index)
    end
  end

  test "tên cốt-lết sản xuất khớp đúng danh sách từ PATCH22" do
    for delta <- [-59, 0, 59] do
      c = @foundation + delta
      report = CutletMaterializationManager.diagnose(c, c)
      assert Enum.map(report.cutlets, & &1.name_index) == report.name_indices
      assert report.name_indices == CutletNameIndexManager.names(c, c)
    end
  end

  test "chỉ số cổng đầu và cuối bao kín năm đích" do
    r = CutletMaterializationManager.diagnose(@foundation, @foundation)
    assert hd(r.cutlets).open_gate_index == r.year.open_gate_index
    assert List.last(r.cutlets).close_gate_index == r.year.close_gate_index
    assert hd(r.cutlets).first_day == r.year.open_gate_day + 1
    assert List.last(r.cutlets).last_day == r.year.close_gate_day
  end

  test "chỉ số cổng của các cốt-lết liên tục" do
    r = CutletMaterializationManager.diagnose(@foundation, @foundation)
    for [left, right] <- Enum.chunk_every(r.cutlets, 2, 1, :discard) do
      assert left.close_gate_index == right.open_gate_index
      assert left.last_day + 1 == right.first_day
    end
  end

  test "mọi phần có số khoảng cổng dương đúng phân hoạch" do
    for delta <- [-101, 0, 101] do
      c = @foundation + delta
      r = CutletMaterializationManager.diagnose(c, c)
      lengths = Enum.map(r.cutlets, fn piece ->
        piece.close_gate_index - piece.open_gate_index
      end)
      assert lengths == r.cutlet_partition
      assert Enum.all?(lengths, &(&1 > 0))
    end
  end

  test "ngày cuối của mỗi cốt-lết bằng ngày cổng đóng" do
    r = CutletMaterializationManager.diagnose(@foundation, @foundation)
    for piece <- r.cutlets do
      assert piece.last_day == Map.fetch!(r.gate_state.gate, piece.close_gate_index)
    end
  end

  test "production bắt đầu sau ngày cổng mở, vẫn giữ chứng cứ legacy" do
    for delta <- [-3, 0, 3] do
      c = @foundation + delta
      r = CutletMaterializationManager.diagnose(c, c)
      for piece <- r.cutlets do
        assert piece.first_day == Map.fetch!(r.gate_state.gate, piece.open_gate_index) + 1
      end
      assert Enum.all?(r.historical_cutlets, fn piece ->
        piece.first_day == Map.fetch!(r.gate_state.gate, piece.open_gate_index)
      end)
    end
  end

  test "vẫn có đúng khoảng cách giữa các cổng theo bảng nguồn" do
    r = CutletMaterializationManager.diagnose(@foundation, @foundation)
    assert Enum.sum(Enum.map(r.cutlets, fn piece ->
      piece.last_day - piece.first_day
    end)) == r.year.close_gate_day - r.year.open_gate_day - r.cutlet_count
  end

  test "không sửa năm, bảng gate hoặc tập tên từ tầng trước" do
    c = @foundation + 13
    r = CutletMaterializationManager.diagnose(c, c)
    parent = CutletNameIndexManager.diagnose(c, c)
    assert r.year == parent.year
    assert r.gate_state == parent.gate_state
    assert r.name_indices == parent.name_indices
    assert r.cutlet_partition == parent.cutlet_partition
  end

  test "bảng nguyên cả khi ngày đích là cổng đóng năm neo" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = CutletMaterializationManager.diagnose(c, year.close_gate_day)
    assert r.year == year
    assert List.last(r.cutlets).last_day == year.close_gate_day
  end

  test "cổng mở của năm neo thuộc năm trước như các PATCH trước" do
    c = @foundation
    anchor = Calendar.year5000_spaghetti(c)
    r = CutletMaterializationManager.diagnose(c, anchor.open_gate_day)
    assert r.year.number == 4999
    assert List.last(r.cutlets).last_day == anchor.open_gate_day
  end

  test "hàm sản xuất công khai trả cùng đối tượng như chẩn đoán" do
    for delta <- [-37, 0, 37] do
      c = @foundation + delta
      assert Calendar.materialized_cutlets_spaghetti(c, c) ==
        Calendar.materialized_cutlets_diagnostic_spaghetti(c, c).cutlets
    end
  end

  test "đầu vào ngày không hợp lệ bị từ chối" do
    for bad <- [nil, "1", 1.5, %{}] do
      assert_raise ArgumentError, fn -> CutletMaterializationManager.diagnose(bad, @foundation) end
      assert_raise ArgumentError, fn -> CutletMaterializationManager.diagnose(@foundation, bad) end
    end
  end

  test "di sản từ chối danh sách tên không khớp phân hoạch" do
    r = CutletNameIndexManager.diagnose(@foundation, @foundation)
    assert_raise ArgumentError, fn ->
      LegacyInclusiveCutletFirstDay.materialize(
        r.year, r.cutlet_partition, tl(r.name_indices), r.gate_state)
    end
  end

  test "kiểm toán source xác nhận PATCH23 gọi legacy thật" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    source = File.read!(Path.join(root, "legacy_inclusive_cutlet_first_day.ex"))
    manager = File.read!(Path.join(root, "cutlet_materialization_manager.ex"))
    assert source =~ "first_day: Map.fetch!(state.gate, cursor)"
    assert source =~ "last_day: Map.fetch!(state.gate, close)"
    assert manager =~ "CutletFirstDayPatch.diagnose("
    refute source =~ "NormativeReference"
    refute manager =~ "NormativeReference"
    assert File.exists?(Path.join(root, "cutlet_first_day_patch.ex"))
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "normative đỏ 1: cốt-lết ở Ngày Nền và lân cận" do
    for delta <- [-3, -1, 0, 1, 3] do
      c = @foundation + delta
      assert actual(c, c) == oracle(c, c)
    end
  end

  test "normative đỏ 2: cốt-lết ở các ngày phía trước" do
    for delta <- [17, 71, 101, 417] do
      c = @foundation + delta
      assert actual(c, c) == oracle(c, c)
    end
  end

  test "normative đỏ 3: cốt-lết ở các ngày phía sau" do
    for delta <- [-721, -539, -417, -101, -17] do
      c = @foundation + delta
      assert actual(c, c) == oracle(c, c)
    end
  end

  test "normative đỏ 4: cổng đóng năm đích" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      target = Calendar.year5000_spaghetti(c).close_gate_day
      assert actual(c, target) == oracle(c, target)
    end
  end
end
