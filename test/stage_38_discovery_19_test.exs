defmodule PastafariCalendarElixirVietnamese.Stage38Discovery19Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyUpperBoundaryBelongsToNextYear,
    TargetYearManager,
    Year5000Manager
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp ref_year(c, t), do: elem(Ref.find_target_year(c, t), 0) |> Map.from_struct()
  defp got_year(c, t), do: Calendar.find_target_year_spaghetti(c, t) |> Map.from_struct()

  test "mục tiêu nằm giữa năm 5000 được chọn đúng" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      anchor = Calendar.year5000_spaghetti(c)
      t = div(anchor.open_gate_day + anchor.close_gate_day, 2)
      assert got_year(c, t) == ref_year(c, t)
    end
  end

  test "cổng mở là cổng đóng của năm trước, lỗi lịch sử còn thấy" do
    for delta <- [-17, 0, 17] do
      c = @foundation + delta
      anchor = Calendar.year5000_spaghetti(c)
      assert LegacyUpperBoundaryBelongsToNextYear.route(anchor.open_gate_day, anchor) == :previous
      assert ref_year(c, anchor.open_gate_day).number == 4999
      assert got_year(c, anchor.open_gate_day - 1) == ref_year(c, anchor.open_gate_day - 1)
    end
  end

  test "ngày ngay sau cổng đóng thuộc năm sau" do
    for delta <- [-37, 0, 37] do
      c = @foundation + delta
      anchor = Calendar.year5000_spaghetti(c)
      assert got_year(c, anchor.close_gate_day + 1) == ref_year(c, anchor.close_gate_day + 1)
    end
  end

  test "di sản phân nhầm ngày đóng vào năm kế" do
    anchor = Calendar.year5000_spaghetti(@foundation)
    assert LegacyUpperBoundaryBelongsToNextYear.route(anchor.close_gate_day, anchor) ==
      :next_at_upper_boundary
    assert LegacyUpperBoundaryBelongsToNextYear.route(anchor.close_gate_day + 1, anchor) == :next
    assert LegacyUpperBoundaryBelongsToNextYear.route(anchor.close_gate_day - 1, anchor) == :found
  end

  test "trên cổng mở điều hướng về năm trước" do
    anchor = Calendar.year5000_spaghetti(@foundation)
    assert LegacyUpperBoundaryBelongsToNextYear.route(anchor.open_gate_day, anchor) == :previous
    assert LegacyUpperBoundaryBelongsToNextYear.route(anchor.open_gate_day - 1, anchor) == :previous
    assert LegacyUpperBoundaryBelongsToNextYear.route(anchor.open_gate_day + 1, anchor) == :found
  end

  test "lối đi tới năm 5001 có bước tiến duy nhất" do
    anchor = Calendar.year5000_spaghetti(@foundation)
    report = TargetYearManager.diagnose(@foundation, anchor.close_gate_day + 2)
    assert report.year.number == 5001
    assert report.steps == 1
    assert report.trace == [{:next, 5000, 5001}]
    assert Map.from_struct(report.year) == ref_year(@foundation, anchor.close_gate_day + 2)
  end

  test "lối đi tới năm 4999 có bước lùi duy nhất" do
    anchor = Calendar.year5000_spaghetti(@foundation)
    target = anchor.open_gate_day - 1
    report = TargetYearManager.diagnose(@foundation, target)
    assert report.year.number == 4999
    assert report.steps == 1
    assert report.trace == [{:previous, 5000, 4999}]
    assert Map.from_struct(report.year) == ref_year(@foundation, target)
  end

  test "hai bước sang tương lai không mất thứ tự năm" do
    c = @foundation + 19
    {anchor, state} = Ref.year5000(c)
    {y5001, state2} = Ref.next_year(c, anchor, state)
    {y5002, _} = Ref.next_year(c, y5001, state2)
    t = y5002.open_gate_day + 1
    report = TargetYearManager.diagnose(c, t)
    assert Map.from_struct(report.year) == ref_year(c, t)
    assert report.year.number == 5002
    assert report.steps == 2
  end

  test "hai bước về quá khứ không mất thứ tự năm" do
    c = @foundation - 19
    {anchor, state} = Ref.year5000(c)
    {y4999, state2} = Ref.previous_year(c, anchor, state)
    {y4998, _} = Ref.previous_year(c, y4999, state2)
    t = y4998.close_gate_day - 1
    report = TargetYearManager.diagnose(c, t)
    assert Map.from_struct(report.year) == ref_year(c, t)
    assert report.year.number == 4998
    assert report.steps == 2
  end

  test "ngày đích bằng cổng đóng kích hoạt di sản đúng một bước" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      anchor = Calendar.year5000_spaghetti(c)
      report = TargetYearManager.diagnose(c, anchor.close_gate_day)
      assert report.year.number == 5001
      assert report.steps == 1
      assert report.trace == [{:legacy_upper_boundary, 5000, anchor.close_gate_day}]
    end
  end

  test "năm 5000 từ bộ tìm đích không đổi khi không đi" do
    c = @foundation
    anchor = Year5000Manager.diagnose(c)
    t = anchor.year.open_gate_day + 1
    report = TargetYearManager.diagnose(c, t)
    assert report.year == anchor.year
    assert report.gate_state == anchor.gate_state
    assert report.trace == []
    assert report.steps == 0
  end

  test "các ngày hợp lệ trong cùng năm có kết quả bất biến" do
    c = @foundation + 99
    anchor = Calendar.year5000_spaghetti(c)
    days = [anchor.open_gate_day + 1, anchor.open_gate_day + 2,
      div(anchor.open_gate_day + anchor.close_gate_day, 2),
      anchor.close_gate_day - 1]
    assert Enum.all?(days, fn t -> got_year(c, t) == ref_year(c, t) end)
  end

  test "kết quả ghi đúng c và t theo lời gọi" do
    c = @foundation + 3
    anchor = Calendar.year5000_spaghetti(c)
    t = anchor.open_gate_day + 5
    report = Calendar.find_target_year_diagnostic_spaghetti(c, t)
    assert report.calculation_day == c
    assert report.target_day == t
    assert report.anchor_year.number == 5000
  end

  test "trạng thái và chỉ số cổng còn đúng qua bước tiến" do
    c = @foundation
    anchor = Calendar.year5000_spaghetti(c)
    r = TargetYearManager.diagnose(c, anchor.close_gate_day + 33)
    assert r.gate_state.gate[r.year.open_gate_index] == r.year.open_gate_day
    assert r.gate_state.gate[r.year.close_gate_index] == r.year.close_gate_day
    assert r.gate_state.gate[anchor.close_gate_index] == anchor.close_gate_day
  end

  test "không chia sẻ trạng thái khi truy vấn lặp lại" do
    c = @foundation
    anchor = Calendar.year5000_spaghetti(c)
    t = anchor.open_gate_day + 1
    assert TargetYearManager.diagnose(c, t) == TargetYearManager.diagnose(c, t)
  end

  test "tham số sai bị từ chối ở API tìm năm" do
    for bad <- [nil, 0.5, "1", [], %{}] do
      assert_raise ArgumentError, fn -> TargetYearManager.diagnose(bad, @foundation) end
      assert_raise ArgumentError, fn -> TargetYearManager.diagnose(@foundation, bad) end
    end
  end

  test "nguồn production giữ nguyên năm trước và năm sau" do
    for delta <- [-37, 0, 37] do
      c = @foundation + delta
      assert Map.from_struct(Calendar.previous_year_spaghetti(c)) ==
        Map.from_struct(elem(Ref.previous_year(c, elem(Ref.year5000(c), 0), elem(Ref.year5000(c), 1)), 0))
      assert Map.from_struct(Calendar.next_year_spaghetti(c)) ==
        Map.from_struct(elem(Ref.next_year(c, elem(Ref.year5000(c), 0), elem(Ref.year5000(c), 1)), 0))
    end
  end

  test "mã production không được nhập oracle và phải giữ di sản" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_upper_boundary_belongs_to_next_year.ex"))
    manager = File.read!(Path.join(root, "target_year_manager.ex"))
    assert legacy =~ "target_day == year.close_gate_day -> :next_at_upper_boundary"
    assert manager =~ "LegacyUpperBoundaryBelongsToNextYear.route(target_day, year)"
    assert manager =~ "NextYearManager.next_year_from"
    assert manager =~ "PreviousYearManager.previous_year_from"
    refute manager =~ "NormativeReference"
    refute File.exists?(Path.join(root, "target_year_boundary_patch.ex"))
  end

  test "hồi quy normative đỏ 1: cổng đóng tại Foundation" do
    c = @foundation
    t = Calendar.year5000_spaghetti(c).close_gate_day
    assert got_year(c, t) == ref_year(c, t)
  end

  test "hồi quy normative đỏ 2: cổng đóng tại Foundation+1" do
    c = @foundation + 1
    t = Calendar.year5000_spaghetti(c).close_gate_day
    assert got_year(c, t) == ref_year(c, t)
  end

  test "hồi quy normative đỏ 3: cổng đóng tại Foundation+417" do
    c = @foundation + 417
    t = Calendar.year5000_spaghetti(c).close_gate_day
    assert got_year(c, t) == ref_year(c, t)
  end

  test "hồi quy normative đỏ 4: cổng đóng tại Foundation-539" do
    c = @foundation - 539
    t = Calendar.year5000_spaghetti(c).close_gate_day
    assert got_year(c, t) == ref_year(c, t)
  end
end
