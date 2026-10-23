defmodule PastafariCalendarElixirVietnamese.Stage47Patch23Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    Cutlet, CutletFirstDayPatch, CutletMaterializationManager,
    CutletNameIndexManager, LegacyInclusiveCutletFirstDay
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp reference(c, t) do
    {year, state} = Ref.find_target_year(c, t)
    sauce = Ref.sauce(c, year.open_gate_day + 1)
    count = Ref.choose_cutlet_count(sauce, year)
    {parts, state2} = Ref.choose_cutlet_partition(c, sauce, year, count, state)
    names = Ref.choose_cutlet_name_indices(sauce, count)
    Ref.materialize_cutlets(year, parts, names, state2)
    |> Enum.map(&Map.from_struct/1)
  end

  defp actual(c, t),
    do: Calendar.materialized_cutlets_spaghetti(c, t) |> Enum.map(&Map.from_struct/1)

  test "bốn nhóm normative Stage46 giờ đều xanh mà không đổi oracle" do
    for delta <- [-721, -539, -417, -101, -17, -3, -1, 0, 1, 3,
                  17, 71, 101, 417] do
      c = @foundation + delta
      assert actual(c, c) == reference(c, c)
    end
  end

  test "các cổng đóng năm neo đối chiếu oracle chuẩn" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      t = Calendar.year5000_spaghetti(c).close_gate_day
      assert actual(c, t) == reference(c, t)
    end
  end

  test "ngày đầu cốt-lết đúng bằng gate mở cộng một" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = CutletMaterializationManager.diagnose(c, c)
      for piece <- r.cutlets do
        assert piece.first_day == Map.fetch!(r.gate_state.gate, piece.open_gate_index) + 1
      end
    end
  end

  test "ngày cuối vẫn bằng gate đóng chưa bị sửa" do
    for delta <- [-37, 0, 37] do
      c = @foundation + delta
      r = CutletMaterializationManager.diagnose(c, c)
      for piece <- r.cutlets do
        assert piece.last_day == Map.fetch!(r.gate_state.gate, piece.close_gate_index)
      end
    end
  end

  test "không có ngày chung giữa các cốt-lết liên tiếp" do
    r = CutletMaterializationManager.diagnose(@foundation, @foundation)
    for [left, right] <- Enum.chunk_every(r.cutlets, 2, 1, :discard) do
      assert left.close_gate_index == right.open_gate_index
      assert left.last_day + 1 == right.first_day
    end
  end

  test "khoảng (mở,đóng] che đúng mọi ngày của năm" do
    for delta <- [-17, 0, 17] do
      c = @foundation + delta
      r = CutletMaterializationManager.diagnose(c, c)
      first = hd(r.cutlets)
      last = List.last(r.cutlets)
      assert first.first_day == r.year.open_gate_day + 1
      assert last.last_day == r.year.close_gate_day
      assert Enum.sum(Enum.map(r.cutlets, &(&1.last_day - &1.first_day + 1))) ==
        r.year.close_gate_day - r.year.open_gate_day
    end
  end

  test "di sản vẫn gọi thực và giữ ngày gate mở cũ" do
    c = @foundation - 47
    r = CutletMaterializationManager.diagnose(c, c)
    old = LegacyInclusiveCutletFirstDay.materialize(
      r.year, r.cutlet_partition, r.name_indices, r.gate_state)
    assert r.historical_cutlets == old
    for piece <- old do
      assert piece.first_day == Map.fetch!(r.gate_state.gate, piece.open_gate_index)
    end
  end

  test "báo cáo patch giữ cả hai bản và cho đúng chỉ báo thay đổi" do
    c = @foundation + 73
    parent = CutletNameIndexManager.diagnose(c, c)
    r = CutletFirstDayPatch.diagnose(
      parent.year, parent.cutlet_partition, parent.name_indices, parent.gate_state)
    assert r.corrected_cutlets == Calendar.materialized_cutlets_spaghetti(c, c)
    assert r.cutlet_count == length(r.corrected_cutlets)
    assert r.changed
  end

  test "chỉ trường ngày đầu được đổi trong mỗi đối tượng Cutlet" do
    c = @foundation
    r = CutletMaterializationManager.diagnose(c, c)
    for {old, new} <- Enum.zip(r.historical_cutlets, r.cutlets) do
      assert %Cutlet{} = old
      assert %Cutlet{} = new
      assert old.name_index == new.name_index
      assert old.open_gate_index == new.open_gate_index
      assert old.close_gate_index == new.close_gate_index
      assert old.last_day == new.last_day
      assert new.first_day == old.first_day + 1
    end
  end

  test "đủ số phần, phân hoạch và tên riêng như PATCH21/22" do
    for delta <- [-107, 0, 107] do
      c = @foundation + delta
      r = CutletMaterializationManager.diagnose(c, c)
      assert length(r.cutlets) == r.cutlet_count
      assert Enum.map(r.cutlets, & &1.name_index) == r.name_indices
      assert Enum.uniq(r.name_indices) == r.name_indices
      assert Enum.map(r.cutlets, &(&1.close_gate_index - &1.open_gate_index)) ==
        r.cutlet_partition
    end
  end

  test "số ngày mỗi phần không âm và tính từ cổng" do
    r = CutletMaterializationManager.diagnose(@foundation, @foundation)
    for piece <- r.cutlets do
      assert piece.first_day <= piece.last_day
      assert piece.last_day - piece.first_day + 1 ==
        Map.fetch!(r.gate_state.gate, piece.close_gate_index) -
        Map.fetch!(r.gate_state.gate, piece.open_gate_index)
    end
  end

  test "cổng mở năm neo thuộc năm 4999 không bị hồi quy" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = CutletMaterializationManager.diagnose(c, year.open_gate_day)
    assert r.year.number == 4999
    assert List.last(r.cutlets).last_day == year.open_gate_day
  end

  test "cổng đóng của năm neo thuộc năm 5000 đã vá" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = CutletMaterializationManager.diagnose(c, year.close_gate_day)
    assert r.year == year
    assert List.last(r.cutlets).last_day == year.close_gate_day
  end

  test "bảng gate và danh sách tên không bị PATCH23 đụng tới" do
    c = @foundation + 41
    r = CutletMaterializationManager.diagnose(c, c)
    parent = CutletNameIndexManager.diagnose(c, c)
    assert r.year == parent.year
    assert r.gate_state == parent.gate_state
    assert r.name_indices == parent.name_indices
    assert r.cutlet_partition == parent.cutlet_partition
  end

  test "chạy lại cùng ngày bất biến" do
    c = @foundation + 19
    assert CutletMaterializationManager.diagnose(c, c) ==
      CutletMaterializationManager.diagnose(c, c)
  end

  test "thứ tự truy vấn không thay dữ liệu" do
    days = Enum.map(-3..3, &(@foundation + 29 * &1))
    front = Enum.map(days, &Calendar.materialized_cutlets_spaghetti(&1, &1))
    back = Enum.map(Enum.reverse(days), &Calendar.materialized_cutlets_spaghetti(&1, &1))
    assert front == Enum.reverse(back)
  end

  test "tính đồng thời trả đúng oracle ở nhiều ngày" do
    days = Enum.map(-4..4, &(@foundation + 31 * &1))
    result =
      Task.async_stream(days, fn c -> actual(c, c) end,
        max_concurrency: 4, ordered: true, timeout: 60_000)
      |> Enum.map(fn {:ok, output} -> output end)
    assert result == Enum.map(days, fn c -> reference(c, c) end)
  end

  test "hàm patch giữ kiểm tra độ dài đầu vào của di sản" do
    r = CutletNameIndexManager.diagnose(@foundation, @foundation)
    assert_raise ArgumentError, fn ->
      CutletFirstDayPatch.diagnose(r.year, r.cutlet_partition,
        tl(r.name_indices), r.gate_state)
    end
  end

  test "ngày tính không hợp lệ vẫn bị từ chối ở API production" do
    for bad <- [nil, 1.5, "1", %{}] do
      assert_raise ArgumentError, fn -> CutletMaterializationManager.diagnose(bad, @foundation) end
      assert_raise ArgumentError, fn -> CutletMaterializationManager.diagnose(@foundation, bad) end
    end
  end

  test "kiểm toán mã nguồn giữ di sản và không gọi oracle trong production" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_inclusive_cutlet_first_day.ex"))
    patch = File.read!(Path.join(root, "cutlet_first_day_patch.ex"))
    manager = File.read!(Path.join(root, "cutlet_materialization_manager.ex"))
    assert legacy =~ "first_day: Map.fetch!(state.gate, cursor)"
    assert patch =~ "LegacyInclusiveCutletFirstDay.materialize(year, partition, names, state)"
    assert patch =~ "first_day: Map.fetch!(state.gate, piece.open_gate_index) + 1"
    assert manager =~ "CutletFirstDayPatch.diagnose("
    refute patch =~ "NormativeReference"
    refute manager =~ "NormativeReference"
    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end
end
