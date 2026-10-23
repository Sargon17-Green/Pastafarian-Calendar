defmodule PastafariCalendarElixirVietnamese.Stage43Patch21Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager, CutletCountManager,
    CutletPartitionCombinatorics, CutletPartitionManager,
    CutletPartitionSealPatch, LegacyCutletPartitionCountSeal
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  @foundation -15_055_671

  defp oracle(c, t) do
    {year, state} = Ref.find_target_year(c, t)
    sauce = Ref.sauce(c, year.open_gate_day + 1)
    count = Ref.choose_cutlet_count(sauce, year)
    elem(Ref.choose_cutlet_partition(c, sauce, year, count, state), 0)
  end

  test "bốn nhóm chuẩn Stage42 trở về xanh, expected không thay" do
    deltas = [-721, -539, -417, -101, -17, -3, -1, 0, 1, 3,
      17, 71, 101, 417, 721, 1031, 1337, 2003, 2711, 3333, 4096, 5000]
    for delta <- deltas do
      c = @foundation + delta
      assert Calendar.cutlet_partition_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "các cổng đóng có phân hoạch đúng" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      target = Calendar.year5000_spaghetti(c).close_gate_day
      assert Calendar.cutlet_partition_spaghetti(c, target) == oracle(c, target)
    end
  end

  test "lỗi di sản chốt 20 vẫn hoạt động tách biệt" do
    c = @foundation - 3
    report = CutletPartitionManager.diagnose(c, c)
    old_stream = Calendar.answer_stream_spaghetti(c, report.structure_source_day, 2, 20)
    assert report.historical_rank == AnswerStreamManager.choose_rank(
      old_stream, report.candidate_count)
    assert report.historical_rank == LegacyCutletPartitionCountSeal.choose_rank(
      c, report.structure_source_day, report.candidate_count)
  end

  test "patch gọi thật legacy rồi lấy hạng từ chốt 21" do
    for delta <- [-3, 0, 101] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      patch = CutletPartitionSealPatch.diagnose(c, r.structure_source_day, r.candidate_count)
      assert patch.legacy_rank == r.historical_rank
      assert patch.corrected_rank == r.rank
      assert patch.historical_seal == 20
      assert patch.normative_seal == 21
      assert patch.bowl == 2
    end
  end

  test "hạng production từ cùng bowl 2 và chốt 21" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      stream = Calendar.answer_stream_spaghetti(c, r.structure_source_day, 2, 21)
      assert r.rank == AnswerStreamManager.choose_rank(stream, r.candidate_count)
      assert r.rank in 1..r.candidate_count
    end
  end

  test "patch thay đổi hạng đúng khi di sản sai" do
    c = @foundation - 3
    r = CutletPartitionManager.diagnose(c, c)
    assert r.seal_was_corrected == (r.rank != r.historical_rank)
    assert r.partition == oracle(c, c)
  end

  test "phân hoạch tuân theo số cốt-lết từ PATCH20" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      assert r.cutlet_count == CutletCountManager.cutlet_count(c, c)
      assert length(r.partition) == r.cutlet_count
      assert Enum.sum(r.partition) == r.gate_gaps
    end
  end

  test "mọi phần tử phân hoạch đều dương" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      assert Enum.all?(r.partition, &(&1 > 0))
      assert length(r.partition) == r.cutlet_count
    end
  end

  test "hạng được mở bằng tổ hợp DP lexicographic cũ không thay" do
    for delta <- [-37, 0, 37] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      assert r.partition == CutletPartitionCombinatorics.unrank(
        r.gate_gaps, r.cutlet_count, r.required_boundary, r.rank)
    end
  end

  test "số cách chia đúng oracle độc lập" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      assert r.candidate_count == Ref.make_cutlet_partition_count(
        r.gate_gaps, r.cutlet_count, r.required_boundary)
    end
  end

  test "ranh giới nội bộ bắt buộc vẫn được ghi nhận" do
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

  test "biên đóng năm 5000 không đổi" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = CutletPartitionManager.diagnose(c, year.close_gate_day)
    assert r.year == year
    assert r.structure_source_day == year.open_gate_day + 1
  end

  test "hàm patch trả một cho miền có đúng một phân hoạch" do
    r = CutletPartitionSealPatch.diagnose(@foundation, @foundation - 131, 1)
    assert r.legacy_rank == 1 and r.corrected_rank == 1
    refute r.changed
  end

  test "hàm patch từ chối đầu vào sai" do
    for invalid <- [nil, "3", 1.5, %{}] do
      assert_raise ArgumentError, fn -> CutletPartitionSealPatch.diagnose(invalid, 0, 2) end
      assert_raise ArgumentError, fn -> CutletPartitionSealPatch.diagnose(@foundation, invalid, 2) end
    end
    for invalid <- [nil, -1, 0, 1.5] do
      assert_raise ArgumentError, fn ->
        CutletPartitionSealPatch.choose_rank(@foundation, @foundation, invalid)
      end
    end
  end

  test "cùng đầu vào thì kết quả bất biến" do
    c = @foundation + 83
    assert CutletPartitionManager.diagnose(c, c) == CutletPartitionManager.diagnose(c, c)
  end

  test "tính đồng thời không chia sẻ state và khớp tham chiếu" do
    days = Enum.map(-4..4, &(@foundation + &1 * 37))
    actual = Task.async_stream(days,
      fn c -> Calendar.cutlet_partition_spaghetti(c, c) end,
      max_concurrency: 5, ordered: true, timeout: 90_000)
      |> Enum.map(fn {:ok, value} -> value end)
    assert actual == Enum.map(days, fn c -> oracle(c, c) end)
  end

  test "PATCH21 không thay năm hoặc cổng" do
    for delta <- [-17, 0, 17] do
      c = @foundation + delta
      r = CutletPartitionManager.diagnose(c, c)
      assert r.year == Calendar.find_target_year_spaghetti(c, c)
      assert r.gate_state.gate[r.year.open_gate_index] == r.year.open_gate_day
      assert r.gate_state.gate[r.year.close_gate_index] == r.year.close_gate_day
    end
  end

  test "các phân hoạch từ điển nhỏ vẫn đúng" do
    assert CutletPartitionCombinatorics.unrank(5, 2, nil, 1) == [1, 4]
    assert CutletPartitionCombinatorics.unrank(5, 2, nil, 4) == [4, 1]
    assert CutletPartitionCombinatorics.unrank(5, 2, 2, 1) == [2, 3]
  end

  test "ngày lịch cuối vẫn chưa được tích hợp" do
    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end

  test "kiểm toán mã nguồn bảo vệ legacy và tách oracle khỏi production" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_cutlet_partition_count_seal.ex"))
    patch = File.read!(Path.join(root, "cutlet_partition_seal_patch.ex"))
    manager = File.read!(Path.join(root, "cutlet_partition_manager.ex"))
    assert legacy =~ "Dispatcher.answer_stream(c, first_day, 2, 20)"
    assert patch =~ "LegacyCutletPartitionCountSeal.choose_rank(c, first_day, count)"
    assert patch =~ "Dispatcher.answer_stream(c, first_day, 2, 21)"
    assert manager =~ "CutletPartitionSealPatch.diagnose(c, parent.structure_source_day, count)"
    assert manager =~ "rank = seed.corrected_rank"
    refute patch =~ "NormativeReference"
    refute manager =~ "NormativeReference"
  end
end
