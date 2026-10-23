defmodule PastafariCalendarElixirVietnamese.Stage45Patch22Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    CutletNameIndexManager,
    CutletNameRankPatch,
    CutletPartitionManager,
    DistinctCutletNameIndices,
    LegacyRotatedCutletNameRank
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @foundation -15_055_671

  defp reference_names(c, t) do
    {year, _state} = Ref.find_target_year(c, t)
    sauce = Ref.sauce(c, year.open_gate_day + 1)
    k = Ref.choose_cutlet_count(sauce, year)
    Ref.choose_cutlet_name_indices(sauce, k)
  end

  test "bốn nhóm hồi quy Stage44 được phục hồi mà không sửa oracle" do
    for delta <- [-721, -539, -417, -101, -17, -3, -1, 0, 1, 3,
                  17, 71, 101, 417] do
      c = @foundation + delta
      assert Calendar.cutlet_name_indices_spaghetti(c, c) == reference_names(c, c)
    end
  end

  test "các cổng đóng và năm đích giữ tên chuẩn" do
    for delta <- [-539, 0, 1, 417] do
      c = @foundation + delta
      t = Calendar.year5000_spaghetti(c).close_gate_day
      assert Calendar.cutlet_name_indices_spaghetti(c, t) == reference_names(c, t)
    end
  end

  test "lời gọi di sản thực được giữ lại trong báo cáo" do
    for delta <- [-71, 0, 71] do
      c = @foundation + delta
      r = CutletNameIndexManager.diagnose(c, c)
      assert r.historical_rank == LegacyRotatedCutletNameRank.choose_rank(
        c, r.structure_source_day, r.candidate_count)
      assert r.rank_was_corrected == (r.historical_rank != r.rank)
    end
  end

  test "rank được lấy lại từ cùng ngày, bát 5, chốt 22" do
    for delta <- [-417, -17, 0, 17, 417] do
      c = @foundation + delta
      r = CutletNameIndexManager.diagnose(c, c)
      stream = Calendar.answer_stream_spaghetti(c, r.structure_source_day, 5, 22)
      assert r.rank == AnswerStreamManager.choose_rank(stream, r.candidate_count)
      assert r.rank == CutletNameRankPatch.choose_rank(c, r.structure_source_day, r.candidate_count)
    end
  end

  test "rank di sản xoay kế tiếp rank chuẩn kể cả ở cuối vòng" do
    for delta <- [-101, 0, 101] do
      c = @foundation + delta
      r = CutletNameIndexManager.diagnose(c, c)
      assert r.historical_rank == rem(r.rank, r.candidate_count) + 1
      assert r.historical_rank in 1..r.candidate_count
      assert r.rank in 1..r.candidate_count
    end
  end

  test "bản vá nêu rõ rank lịch sử và rank sửa trên đầu vào thực" do
    c = @foundation + 37
    r = CutletNameIndexManager.diagnose(c, c)
    patch = CutletNameRankPatch.diagnose(c, r.structure_source_day, r.candidate_count)
    assert patch.historical_rank == r.historical_rank
    assert patch.corrected_rank == r.rank
    assert patch.changed == r.rank_was_corrected
    assert patch.bowl == 5 and patch.seal == 22
  end

  test "miền một phần tử trả lại hạng duy nhất" do
    r = CutletNameRankPatch.diagnose(@foundation, @foundation - 37, 1)
    assert r.historical_rank == 1 and r.corrected_rank == 1
    refute r.changed
  end

  test "production mở đúng rank một-based thay vì rank xoay" do
    for delta <- [-539, 0, 417] do
      c = @foundation + delta
      r = CutletNameIndexManager.diagnose(c, c)
      expected = DistinctCutletNameIndices.unrank(17, r.cutlet_count, r.rank)
      assert r.name_indices == expected
      assert Calendar.cutlet_name_indices_spaghetti(c, c) == expected
    end
  end

  test "tất cả chỉ số tên khác nhau và đều trong 1..17" do
    for delta <- [-721, -107, 0, 107, 721] do
      c = @foundation + delta
      r = CutletNameIndexManager.diagnose(c, c)
      assert length(r.name_indices) == r.cutlet_count
      assert length(Enum.uniq(r.name_indices)) == r.cutlet_count
      assert Enum.all?(r.name_indices, &(&1 in 1..17))
    end
  end

  test "số lựa chọn bằng chỉnh hợp P của đúng số cốt-lết" do
    for delta <- [-417, 0, 417] do
      c = @foundation + delta
      r = CutletNameIndexManager.diagnose(c, c)
      assert r.candidate_count == Ref.falling_factorial(17, r.cutlet_count)
      assert r.candidate_count == DistinctCutletNameIndices.count(17, r.cutlet_count)
    end
  end

  test "bản vá tên không làm thay đổi phân hoạch đã vá trước" do
    for delta <- [-17, 0, 17] do
      c = @foundation + delta
      r = CutletNameIndexManager.diagnose(c, c)
      parent = CutletPartitionManager.diagnose(c, c)
      assert r.year == parent.year
      assert r.cutlet_partition == parent.partition
      assert r.gate_state == parent.gate_state
      assert r.structure_source_day == parent.structure_source_day
    end
  end

  test "bất biến thứ tự tên từ điển ở mẫu nhỏ" do
    sequences = for rank <- 1..12, do: DistinctCutletNameIndices.unrank(4, 2, rank)
    assert sequences == Enum.sort(sequences)
    assert sequences == Enum.uniq(sequences)
  end

  test "chỉnh hợp ở hai ranh giới hạng vẫn đúng" do
    for k <- [6, 9, 17] do
      last_rank = DistinctCutletNameIndices.count(17, k)
      first = DistinctCutletNameIndices.unrank(17, k, 1)
      last = DistinctCutletNameIndices.unrank(17, k, last_rank)
      assert first == Enum.to_list(1..k)
      assert last == Enum.reverse(Enum.to_list((18-k)..17))
    end
  end

  test "đầu vào không hợp lệ bị từ chối trong PATCH22" do
    for bad <- [nil, "9", 1.5, %{}] do
      assert_raise ArgumentError, fn -> CutletNameRankPatch.diagnose(bad, @foundation, 3) end
      assert_raise ArgumentError, fn -> CutletNameRankPatch.diagnose(@foundation, bad, 3) end
    end
    for bad <- [nil, 0, -1, 1.5, "7"] do
      assert_raise ArgumentError, fn -> CutletNameRankPatch.choose_rank(@foundation, @foundation, bad) end
    end
  end

  test "cùng ngày trả cấu trúc chẩn đoán bất biến" do
    c = @foundation - 113
    assert CutletNameIndexManager.diagnose(c, c) == CutletNameIndexManager.diagnose(c, c)
  end

  test "kết quả không phụ thuộc thứ tự truy vấn" do
    days = Enum.map(-3..3, &(@foundation + 31*&1))
    direct = Enum.map(days, &Calendar.cutlet_name_indices_spaghetti(&1, &1))
    reverse = Enum.reverse(days) |> Enum.map(&Calendar.cutlet_name_indices_spaghetti(&1, &1)) |> Enum.reverse()
    assert direct == reverse
  end

  test "chạy song song không chia sẻ trạng thái giữa các ngày" do
    days = Enum.map(-3..3, &(@foundation + 47*&1))
    actual =
      Task.async_stream(days,
        fn c -> Calendar.cutlet_name_indices_spaghetti(c, c) end,
        max_concurrency: 4, ordered: true, timeout: 60_000)
      |> Enum.map(fn {:ok, result} -> result end)
    assert actual == Enum.map(days, fn c -> reference_names(c, c) end)
  end

  test "thời điểm của cấu trúc là ngày đầu năm kể cả khi ngày đích khác" do
    c = @foundation
    year = Calendar.year5000_spaghetti(c)
    r = CutletNameIndexManager.diagnose(c, year.close_gate_day)
    assert r.structure_source_day == year.open_gate_day + 1
    assert r.year == year
  end

  test "lịch hoàn chỉnh vẫn báo chưa tích hợp" do
    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end

  test "kiểm toán mã nguồn xác nhận di sản giữ nguyên và oracle tách biệt" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = File.read!(Path.join(root, "legacy_rotated_cutlet_name_rank.ex"))
    patch = File.read!(Path.join(root, "cutlet_name_rank_patch.ex"))
    manager = File.read!(Path.join(root, "cutlet_name_index_manager.ex"))
    assert legacy =~ "rem(chosen_rank, count) + 1"
    assert patch =~ "LegacyRotatedCutletNameRank.choose_rank(c, first_day, count)"
    assert patch =~ "Dispatcher.answer_stream(c, first_day, 5, 22)"
    assert manager =~ "CutletNameRankPatch.diagnose(c, parent.structure_source_day, total)"
    assert manager =~ "rank = seed.corrected_rank"
    refute patch =~ "NormativeReference"
    refute manager =~ "NormativeReference"
  end
end
