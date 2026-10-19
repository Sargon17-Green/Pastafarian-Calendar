defmodule PastafariCalendarElixirVietnamese.Stage39Patch19Test do
  use ExUnit.Case, async: true
  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyUpperBoundaryBelongsToNextYear, TargetYearBoundaryPatch,
    TargetYearManager, Year
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  @foundation -15_055_671

  defp oracle(c, t), do: elem(Ref.find_target_year(c, t), 0) |> Map.from_struct()
  defp production(c, t), do: Calendar.find_target_year_spaghetti(c, t) |> Map.from_struct()

  test "bốn hồi quy normative Stage38 chuyển xanh" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      t = Calendar.year5000_spaghetti(c).close_gate_day
      assert production(c, t) == oracle(c, t)
    end
  end

  test "cổng đóng của năm 5000 thuộc chính năm 5000" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      year = Calendar.year5000_spaghetti(c)
      assert Calendar.find_target_year_spaghetti(c, year.close_gate_day) == year
    end
  end

  test "cổng mở của năm 5000 thuộc năm 4999" do
    for delta <- [-17, 0, 17] do
      c = @foundation + delta
      t = Calendar.year5000_spaghetti(c).open_gate_day
      assert Calendar.find_target_year_spaghetti(c, t).number == 4999
      assert production(c, t) == oracle(c, t)
    end
  end

  test "cổng đóng năm 5001 thuộc năm 5001" do
    for delta <- [-17, 0, 17] do
      c = @foundation + delta
      t = Calendar.next_year_spaghetti(c).close_gate_day
      assert Calendar.find_target_year_spaghetti(c, t).number == 5001
      assert production(c, t) == oracle(c, t)
    end
  end

  test "cổng đóng năm 4999 thuộc năm 4999" do
    for delta <- [-17, 0, 17] do
      c = @foundation + delta
      t = Calendar.previous_year_spaghetti(c).close_gate_day
      assert Calendar.find_target_year_spaghetti(c, t).number == 4999
      assert production(c, t) == oracle(c, t)
    end
  end

  test "ngay sau cổng đóng thuộc năm kế tiếp" do
    c = @foundation
    t = Calendar.year5000_spaghetti(c).close_gate_day + 1
    assert production(c, t) == oracle(c, t)
    assert Calendar.find_target_year_spaghetti(c, t).number == 5001
  end

  test "ba ngày quanh cổng mở dùng đúng (mở,đóng]" do
    c = @foundation
    t = Calendar.year5000_spaghetti(c).open_gate_day
    assert Calendar.find_target_year_spaghetti(c, t-1).number == 4999
    assert Calendar.find_target_year_spaghetti(c, t).number == 4999
    assert Calendar.find_target_year_spaghetti(c, t+1).number == 5000
  end

  test "patch gọi legacy thật trước khi sửa duy nhất biên đóng" do
    year = Calendar.year5000_spaghetti(@foundation)
    report = TargetYearBoundaryPatch.diagnose(year.close_gate_day, year)
    assert report.historical_route ==
      LegacyUpperBoundaryBelongsToNextYear.route(year.close_gate_day, year)
    assert report.historical_route == :next_at_upper_boundary
    assert report.corrected_route == :found
    assert report.changed
  end

  test "ngoài biên, patch giữ nguyên quyết định lịch sử" do
    year = Calendar.year5000_spaghetti(@foundation)
    for t <- [year.open_gate_day-1, year.open_gate_day,
      year.open_gate_day+1, year.close_gate_day-1, year.close_gate_day+1] do
      report = TargetYearBoundaryPatch.diagnose(t, year)
      assert report.corrected_route == report.historical_route
      refute report.changed
    end
  end

  test "cấu trúc Year và trạng thái vẫn giữ kiểu chuẩn" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    report = TargetYearManager.diagnose(c, year.close_gate_day)
    assert %Year{} = report.year
    assert report.year == year
    assert report.trace == []
    assert report.steps == 0
  end

  test "nhiều ngày qua hai phía khớp oracle" do
    for delta <- [-417, -17, 0, 17, 417] do
      c = @foundation + delta
      y = Calendar.year5000_spaghetti(c)
      for t <- [y.open_gate_day-1, y.open_gate_day, y.open_gate_day+1,
                y.close_gate_day-1, y.close_gate_day, y.close_gate_day+1] do
        assert production(c, t) == oracle(c, t)
      end
    end
  end

  test "hai năm lùi với ngày đúng cổng đóng vẫn khớp" do
    c = @foundation
    {a, s} = Ref.year5000(c)
    {b, s2} = Ref.previous_year(c, a, s)
    {d, _} = Ref.previous_year(c, b, s2)
    assert production(c, d.close_gate_day) == oracle(c, d.close_gate_day)
    assert production(c, d.close_gate_day-1) == oracle(c, d.close_gate_day-1)
  end

  test "hai năm tiến với ngày đúng cổng đóng vẫn khớp" do
    c = @foundation
    {a, s} = Ref.year5000(c)
    {b, s2} = Ref.next_year(c, a, s)
    {d, _} = Ref.next_year(c, b, s2)
    assert production(c, d.close_gate_day) == oracle(c, d.close_gate_day)
    assert production(c, d.open_gate_day+1) == oracle(c, d.open_gate_day+1)
  end

  test "diagnostic lưu hai ngày và bước đi chính xác" do
    c = @foundation + 31
    t = Calendar.year5000_spaghetti(c).close_gate_day
    report = Calendar.find_target_year_diagnostic_spaghetti(c, t)
    assert report.calculation_day == c
    assert report.target_day == t
    assert report.anchor_year.number == 5000
    assert report.steps == 0
    assert report.trace == []
  end

  test "năm neo trả về không đổi trạng thái cổng" do
    c = @foundation
    t = Calendar.year5000_spaghetti(c).close_gate_day
    report = TargetYearManager.diagnose(c, t)
    anchor = Calendar.year5000_diagnostic_spaghetti(c)
    assert report.gate_state == anchor.gate_state
  end

  test "kết quả giữ bất biến khi gọi lại" do
    c = @foundation-19
    t = Calendar.year5000_spaghetti(c).open_gate_day
    assert TargetYearManager.diagnose(c, t) == TargetYearManager.diagnose(c, t)
  end

  test "kết quả biên ổn định khi gọi song song" do
    days = Enum.map(-3..3, &(@foundation + 43 * &1))
    inputs = Enum.map(days, fn c -> {c, Calendar.year5000_spaghetti(c).close_gate_day} end)
    results = Task.async_stream(inputs, fn {c,t} -> production(c,t) end,
      max_concurrency: 4, ordered: true, timeout: 30_000)
      |> Enum.map(fn {:ok, result} -> result end)
    assert results == Enum.map(inputs, fn {c,t} -> oracle(c,t) end)
  end

  test "đầu vào sai bị từ chối" do
    year = Calendar.year5000_spaghetti(@foundation)
    for bad <- [nil, 1.5, "0", %{}] do
      assert_raise ArgumentError, fn -> TargetYearBoundaryPatch.diagnose(bad, year) end
      assert_raise ArgumentError, fn -> TargetYearManager.diagnose(@foundation, bad) end
    end
    assert_raise ArgumentError, fn -> TargetYearBoundaryPatch.diagnose(@foundation, %{}) end
  end

  test "lịch cuối chưa được tích hợp" do
    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "kiểm toán source giữ nguyên legacy và không nhập oracle" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_upper_boundary_belongs_to_next_year.ex"))
    patch = File.read!(Path.join(root, "target_year_boundary_patch.ex"))
    manager = File.read!(Path.join(root, "target_year_manager.ex"))
    assert legacy =~ "target_day == year.close_gate_day -> :next_at_upper_boundary"
    assert patch =~ "LegacyUpperBoundaryBelongsToNextYear.route(target_day, year)"
    assert patch =~ "if historical == :next_at_upper_boundary, do: :found"
    assert manager =~ "TargetYearBoundaryPatch.route(target_day, year)"
    refute patch =~ "NormativeReference"
    refute manager =~ "NormativeReference"
  end
end
