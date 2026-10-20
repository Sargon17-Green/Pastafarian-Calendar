defmodule PastafariCalendarElixirVietnamese.Stage42Discovery21Test do
  use ExUnit.Case, async: true
  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    CutletCountManager,
    CutletPartitionCombinatorics,
    CutletPartitionManager,
    LegacyCutletPartitionCountSeal,
    CutletPartitionSealPatch,
    StageNotIntegratedError
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  @foundation -15_055_671

  defp oracle(c, t) do
    {year, state} = Ref.find_target_year(c, t)
    sauce = Ref.sauce(c, year.open_gate_day + 1)
    cutlet_count = Ref.choose_cutlet_count(sauce, year)
    elem(Ref.choose_cutlet_partition(c, sauce, year, cutlet_count, state), 0)
  end

  test "bộ đếm không ràng buộc trả đúng các phân hoạch nhỏ" do
    assert CutletPartitionCombinatorics.count(5, 2, nil) == 4
    assert CutletPartitionCombinatorics.count(6, 3, nil) == 10
    assert CutletPartitionCombinatorics.unrank(5, 2, nil, 1) == [1, 4]
    assert CutletPartitionCombinatorics.unrank(5, 2, nil, 4) == [4, 1]
  end

  test "cổng bắt buộc chia đúng một vị trí trong ví dụ nhỏ" do
    assert CutletPartitionCombinatorics.count(5, 2, 2) == 1
    assert CutletPartitionCombinatorics.unrank(5, 2, 2, 1) == [2, 3]
    assert CutletPartitionCombinatorics.count(6, 3, 3) == 4
  end

  test "mở hạng đúng thứ tự từ điển trên mẫu nhỏ" do
    all = for rank <- 1..CutletPartitionCombinatorics.count(6, 3, nil),
      do: CutletPartitionCombinatorics.unrank(6, 3, nil, rank)
    assert all == Enum.sort(all)
    assert all == Enum.uniq(all)
    assert length(all) == 10
  end

  test "cổng ràng buộc không bị vượt qua trong mọi hạng" do
    total = CutletPartitionCombinatorics.count(8, 4, 3)
    assert total > 1
    for rank <- 1..total do
      partition = CutletPartitionCombinatorics.unrank(8, 4, 3, rank)
      assert 3 in Enum.scan(partition, &+/2)
      assert Enum.sum(partition) == 8
    end
  end

  test "số phân hoạch production bằng bộ đếm độc lập test-only" do
    for delta <- [-37, 0, 37] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      assert r.candidate_count ==
        Ref.make_cutlet_partition_count(r.gate_gaps, r.cutlet_count, r.required_boundary)
    end
  end

  test "cùng năm và số cốt-lết đã được PATCH20 sửa" do
    for delta <- [-101, 0, 101] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      count = CutletCountManager.diagnose(c, c)
      assert r.year == count.year
      assert r.cutlet_count == count.cutlet_count
      assert r.gate_state == count.gate_state
    end
  end

  test "nguồn cấu trúc là ngày đầu tiên của năm" do
    c = @foundation
    r = CutletPartitionManager.diagnose(c, c)
    assert r.structure_source_day == r.year.open_gate_day + 1
    assert r.calculation_day == c
    assert r.target_day == c
  end

  test "di sản giữ bowl 2 seal 20, production lấy seal 21 chuẩn" do
    c = @foundation + 17
    r = CutletPartitionManager.diagnose(c, c)
    assert r.historical_rank == LegacyCutletPartitionCountSeal.choose_rank(
      c, r.structure_source_day, r.candidate_count)
    assert r.rank == CutletPartitionSealPatch.choose_rank(
      c, r.structure_source_day, r.candidate_count)
    assert r.bowl == 2 and r.historical_seal == 20
    assert r.normative_seal == 21
  end

  test "số hạng luôn nằm trong miền cho phép" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      assert r.candidate_count >= 1
      assert r.rank in 1..r.candidate_count
    end
  end

  test "production mở hạng đúng từ hạng lịch sử được chọn" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      assert r.partition == CutletPartitionCombinatorics.unrank(
        r.gate_gaps, r.cutlet_count, r.required_boundary, r.rank)
    end
  end

  test "phân hoạch chứa đúng số phần tử dương tổng bằng số khoảng" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      assert length(r.partition) == r.cutlet_count
      assert Enum.all?(r.partition, &(&1 >= 1))
      assert Enum.sum(r.partition) == r.gate_gaps
    end
  end

  test "ngày tính trùng cổng nội bộ thì cổng phải là ranh giới" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      if not is_nil(r.required_boundary) do
        assert r.required_boundary in Enum.scan(r.partition, &+/2)
        assert r.calculation_gate_index ==
          r.year.open_gate_index + r.required_boundary
      end
    end
  end

  test "ngày đích tại cổng đóng không thay năm đã tìm" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = CutletPartitionManager.diagnose(c, year.close_gate_day)
    assert r.year == year
  end

  test "đầu vào không hợp lệ bị từ chối" do
    for invalid <- [nil, 1.5, "1", %{}] do
      assert_raise ArgumentError, fn -> CutletPartitionManager.diagnose(invalid, @foundation) end
      assert_raise ArgumentError, fn -> CutletPartitionManager.diagnose(@foundation, invalid) end
      assert_raise ArgumentError, fn -> LegacyCutletPartitionCountSeal.choose_rank(invalid, 0, 3) end
    end
    assert_raise ArgumentError, fn -> CutletPartitionCombinatorics.count(0, 2, nil) end
    assert_raise ArgumentError, fn -> CutletPartitionCombinatorics.unrank(5, 2, nil, 0) end
  end

  test "chạy lặp lại tạo cùng dữ liệu bất biến" do
    c = @foundation + 57
    assert CutletPartitionManager.diagnose(c, c) ==
      CutletPartitionManager.diagnose(c, c)
  end

  test "source xác nhận PATCH21 gọi legacy và không dùng oracle" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_cutlet_partition_count_seal.ex"))
    manager = File.read!(Path.join(root, "cutlet_partition_manager.ex"))
    combinatorics = File.read!(Path.join(root, "cutlet_partition_combinatorics.ex"))
    assert legacy =~ "Dispatcher.answer_stream(c, first_day, 2, 20)"
    assert manager =~ "CutletPartitionSealPatch.diagnose"
    assert combinatorics =~ "count_state("
    refute manager =~ "NormativeReference"
    assert File.exists?(Path.join(root, "cutlet_partition_seal_patch.ex"))
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "normative đỏ 1: ngày Foundation và lân cận" do
    for delta <- [-3, -1, 0, 1, 3] do
      c = @foundation + delta
      assert Calendar.cutlet_partition_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "normative đỏ 2: ngày phía trước" do
    for delta <- [17, 71, 101, 417, 721, 1031, 1337, 2003, 2711, 3333, 4096, 5000] do
      c = @foundation + delta
      assert Calendar.cutlet_partition_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "normative đỏ 3: ngày phía sau" do
    for delta <- [-721, -539, -417, -101, -17] do
      c = @foundation + delta
      assert Calendar.cutlet_partition_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "normative đỏ 4: ngày đích tại cổng đóng năm neo" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      t = Calendar.year5000_spaghetti(c).close_gate_day
      assert Calendar.cutlet_partition_spaghetti(c, t) == oracle(c, t)
    end
  end
end
