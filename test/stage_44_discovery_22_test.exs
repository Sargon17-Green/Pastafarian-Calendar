defmodule PastafariCalendarElixirVietnamese.Stage44Discovery22Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    CutletNameIndexManager,
    CutletPartitionManager,
    DistinctCutletNameIndices,
    LegacyRotatedCutletNameRank,
    StageNotIntegratedError
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  @foundation -15_055_671

  defp oracle(c, t) do
    {year, _state} = Ref.find_target_year(c, t)
    sauce = Ref.sauce(c, year.open_gate_day + 1)
    cutlet_count = Ref.choose_cutlet_count(sauce, year)
    Ref.choose_cutlet_name_indices(sauce, cutlet_count)
  end

  test "đếm chỉnh hợp chập k, không tạo toàn bộ hoán vị" do
    assert DistinctCutletNameIndices.count(17, 6) == Ref.falling_factorial(17, 6)
    assert DistinctCutletNameIndices.count(17, 17) == Ref.falling_factorial(17, 17)
    assert DistinctCutletNameIndices.count(4, 2) == 12
  end

  test "trường hợp k bằng không có đúng một dãy rỗng" do
    assert DistinctCutletNameIndices.count(0, 0) == 1
    assert DistinctCutletNameIndices.count(17, 0) == 1
    assert DistinctCutletNameIndices.unrank(17, 0, 1) == []
  end

  test "mở hạng ví dụ ba tên hai vị trí theo thứ tự từ điển" do
    actual = Enum.map(1..6, &DistinctCutletNameIndices.unrank(3, 2, &1))
    assert actual == [[1, 2], [1, 3], [2, 1], [2, 3], [3, 1], [3, 2]]
  end

  test "mở hạng đầu và cuối cho mọi chỉ số tên" do
    assert DistinctCutletNameIndices.unrank(17, 6, 1) == [1, 2, 3, 4, 5, 6]
    last_rank = DistinctCutletNameIndices.count(17, 6)
    assert DistinctCutletNameIndices.unrank(17, 6, last_rank) ==
      [17, 16, 15, 14, 13, 12]
  end

  test "tất cả chỉ số tên production là phân biệt và hợp lệ" do
    for delta <- [-539, -17, 0, 17, 417] do
      c = @foundation + delta
      report = CutletNameIndexManager.diagnose(c, c)
      assert length(report.name_indices) == report.cutlet_count
      assert Enum.uniq(report.name_indices) == report.name_indices
      assert Enum.all?(report.name_indices, &(&1 in 1..17))
    end
  end

  test "số cốt-lết khớp phân hoạch từ PATCH21" do
    for delta <- [-37, 0, 37] do
      c = @foundation + delta
      report = CutletNameIndexManager.diagnose(c, c)
      partition = CutletPartitionManager.diagnose(c, c)
      assert report.cutlet_count == length(partition.partition)
      assert report.cutlet_partition == partition.partition
      assert report.year == partition.year
    end
  end

  test "hạt chọn tên lấy ngày đầu năm, không lấy ngày đích" do
    for delta <- [-11, 0, 11] do
      c = @foundation + delta
      report = CutletNameIndexManager.diagnose(c, c)
      assert report.structure_source_day == report.year.open_gate_day + 1
      assert report.calculation_day == c
    end
  end

  test "rank sai lệch đúng một sau câu trả lời bát 5 chốt 22" do
    for delta <- [-19, 0, 19] do
      c = @foundation + delta
      report = CutletNameIndexManager.diagnose(c, c)
      stream = Calendar.answer_stream_spaghetti(c, report.structure_source_day, 5, 22)
      correct = AnswerStreamManager.choose_rank(stream, report.candidate_count)
      assert report.rank == rem(correct, report.candidate_count) + 1
      assert report.bowl == 5 and report.seal == 22
    end
  end

  test "di sản quay hạng cuối về một và miền một giữ nguyên" do
    assert LegacyRotatedCutletNameRank.choose_rank(@foundation, @foundation, 1) == 1
    report = CutletNameIndexManager.diagnose(@foundation, @foundation)
    assert report.rank in 1..report.candidate_count
  end

  test "mã production lấy trực tiếp mở hạng ở rank di sản" do
    c = @foundation + 31
    report = CutletNameIndexManager.diagnose(c, c)
    assert report.name_indices == DistinctCutletNameIndices.unrank(
      17, report.cutlet_count, report.rank)
    assert Calendar.cutlet_name_indices_spaghetti(c, c) == report.name_indices
  end

  test "số lượng hạng là chỉnh hợp đúng theo số cốt-lết" do
    report = CutletNameIndexManager.diagnose(@foundation, @foundation)
    assert report.candidate_count == DistinctCutletNameIndices.count(
      17, report.cutlet_count)
    assert report.name_capacity == 17
  end

  test "ngày cổng đóng thuộc năm 5000 đúng" do
    c = @foundation
    anchor = Calendar.year5000_spaghetti(c)
    report = CutletNameIndexManager.diagnose(c, anchor.close_gate_day)
    assert report.year == anchor
  end

  test "kết quả không phụ thuộc thứ tự gọi lại" do
    c = @foundation - 97
    assert CutletNameIndexManager.diagnose(c, c) ==
      CutletNameIndexManager.diagnose(c, c)
  end

  test "đầu vào giới hạn chỉnh hợp không hợp lệ bị từ chối" do
    for {n, k} <- [{-1, 0}, {3, 4}, {3, -1}, {nil, 1}, {1.5, 1}] do
      assert_raise ArgumentError, fn -> DistinctCutletNameIndices.count(n, k) end
    end
    assert_raise ArgumentError, fn -> DistinctCutletNameIndices.unrank(3, 2, 0) end
    assert_raise ArgumentError, fn -> DistinctCutletNameIndices.unrank(3, 2, 7) end
  end

  test "đầu vào ngày không hợp lệ bị từ chối" do
    for bad <- [nil, 1.5, "1", %{}] do
      assert_raise ArgumentError, fn -> CutletNameIndexManager.diagnose(bad, @foundation) end
      assert_raise ArgumentError, fn -> CutletNameIndexManager.diagnose(@foundation, bad) end
      assert_raise ArgumentError, fn ->
        LegacyRotatedCutletNameRank.choose_rank(bad, @foundation, 5)
      end
    end
  end

  test "kiểm toán mã nguồn giữ lỗi di sản và không gọi oracle trong production" do
    dir = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(dir, "legacy_rotated_cutlet_name_rank.ex"))
    manager = File.read!(Path.join(dir, "cutlet_name_index_manager.ex"))
    assert legacy =~ "rem(chosen_rank, count) + 1"
    assert legacy =~ "Dispatcher.answer_stream(c, first_day, 5, 22)"
    assert manager =~ "LegacyRotatedCutletNameRank.choose_rank("
    assert manager =~ "DistinctCutletNameIndices.unrank("
    refute manager =~ "NormativeReference"
    refute File.exists?(Path.join(dir, "cutlet_name_rank_patch.ex"))
    assert_raise StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(@foundation, @foundation)
    end
  end

  test "hồi quy normative đỏ 1: quanh Ngày Nền" do
    for delta <- [-3, -1, 0, 1, 3] do
      c = @foundation + delta
      assert Calendar.cutlet_name_indices_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "hồi quy normative đỏ 2: sau Ngày Nền" do
    for delta <- [17, 71, 101, 417] do
      c = @foundation + delta
      assert Calendar.cutlet_name_indices_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "hồi quy normative đỏ 3: trước Ngày Nền" do
    for delta <- [-721, -539, -417, -101, -17] do
      c = @foundation + delta
      assert Calendar.cutlet_name_indices_spaghetti(c, c) == oracle(c, c)
    end
  end

  test "hồi quy normative đỏ 4: các cổng đóng năm đích" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      t = Calendar.year5000_spaghetti(c).close_gate_day
      assert Calendar.cutlet_name_indices_spaghetti(c, t) == oracle(c, t)
    end
  end
end
