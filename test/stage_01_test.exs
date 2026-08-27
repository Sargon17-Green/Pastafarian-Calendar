defmodule PastafariCalendarElixirVietnamese.Stage01Test do
  use ExUnit.Case, async: false

  alias PastafariCalendarElixirVietnamese
  alias PastafariCalendarElixirVietnamese.SourceLanguageCatalog
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @fixtures Code.eval_file(Path.join(__DIR__, "fixtures/stage_01_fixtures.exs")) |> elem(0)

  test "các mốc và phép đếm ngày khớp phụ lục A" do
    assert Ref.tablets_day() == @fixtures.anchors.tablets_day
    assert Ref.foundation_day() == @fixtures.anchors.foundation_day
    assert Ref.tablets_day() - Ref.foundation_day() == @fixtures.anchors.distance

    Enum.each(@fixtures.day_counts, fn {day, expected} ->
      assert Ref.day_count(day) == expected
    end)
  end

  test "SAVE dùng số nguyên chính xác và đưa bội số M về M" do
    m = Ref.m()
    assert Ref.save(1) == 1
    assert Ref.save(m - 1) == m - 1
    assert Ref.save(m) == m
    assert Ref.save(m + 1) == 1
    assert Ref.save(2 * m) == m
    assert Ref.save(0) == m
  end

  test "mẫu đếm công việc tại ngày nền là chính xác" do
    f = Ref.foundation_day()
    counts = Ref.work_counts(f, f)
    assert counts.action == 1
    assert counts.target == 1
    assert counts.distance == 1
    assert counts.connection == 2
    assert counts.direction == 2
  end

  test "bảng đá có 46 hàng và mỗi hàng nằm trong miền SAVE" do
    stones = Ref.build_stones()
    assert map_size(stones) == 46

    Enum.each(1..46, fn i ->
      tuple = Map.fetch!(stones, i)
      assert tuple_size(tuple) == 5

      tuple
      |> Tuple.to_list()
      |> Enum.each(fn value -> assert value >= 1 and value <= Ref.m() end)
    end)
  end

  test "mở hạng hoán vị theo thứ tự từ điển là một dựa" do
    assert Ref.bowl_order_from_number(1) == @fixtures.permutations[1]
    assert Ref.bowl_order_from_number(720) == @fixtures.permutations[720]
  end

  test "hợp thành bị chặn được đếm và mở hạng chính xác" do
    f = @fixtures.bounded_composition
    assert Ref.count_bounded_compositions(f.total, f.slots, f.lo, f.hi) == f.count
    assert Ref.unrank_bounded_composition(f.total, f.slots, f.lo, f.hi, 1) == f.rank_1
    assert Ref.unrank_bounded_composition(f.total, f.slots, f.lo, f.hi, 5) == f.rank_5
  end

  test "đan tháng nhỏ giữ đúng thứ tự lần đầu và lần cuối" do
    f = @fixtures.weaving_2_2
    assert Ref.count_weavings([2, 2]) == f.count
    assert Ref.unrank_weaving([2, 2], 1) == f.rank_1
    assert Ref.unrank_weaving([2, 2], 2) == f.rank_2
  end

  test "phân hoạch miếng có thể buộc một tổng tiền tố" do
    count = Ref.make_cutlet_partition_count(8, 3, 5)
    assert count > 0

    Enum.each(1..count, fn rank ->
      partition = Ref.unrank_cutlet_partition(8, 3, 5, rank)
      prefix = Enum.scan(partition, &+/2)
      assert 5 in prefix
    end)
  end

  test "rót và khuấy của nước sốt là xác định" do
    f = Ref.foundation_day()
    first = Ref.sauce(f, f)
    second = Ref.sauce(f, f)
    assert first == second
    assert length(first.order_at_drop_46) == 6
    assert Enum.sort(first.order_at_drop_46) == [1, 2, 3, 4, 5, 6]

    Enum.each(Map.values(first.bowls), fn value ->
      assert value >= 1 and value <= Ref.m()
    end)
  end

  test "bát sau bát cuối của thứ tự giọt 46 là bát đầu" do
    f = Ref.foundation_day()
    result = Ref.sauce(f, f)
    last = List.last(result.order_at_drop_46)
    assert Ref.next_bowl_in_drop_46_order(result, last) == hd(result.order_at_drop_46)
  end

  test "bộ chọn ngắn và rộng giữ hạng trong miền" do
    f = Ref.foundation_day()
    stream = Ref.sauce(f, f) |> Ref.ask_bowl(1, 1)
    assert Ref.choose_rank(stream, 1) == 1

    rank_m = Ref.choose_rank(stream, Ref.m())
    assert rank_m >= 1 and rank_m <= Ref.m()

    wide_n = Ref.m() + 1
    wide_rank = Ref.choose_rank(stream, wide_n)
    assert wide_rank >= 1 and wide_rank <= wide_n
  end

  test "danh mục nguồn tiếng Việt được đóng băng theo chỉ số chuẩn" do
    assert SourceLanguageCatalog.version() == "1.0.0"
    assert length(SourceLanguageCatalog.cutlets()) == 17
    assert length(SourceLanguageCatalog.months()) == 47
    assert Enum.map(SourceLanguageCatalog.cutlets(), &elem(&1, 0)) == Enum.to_list(1..17)
    assert Enum.map(SourceLanguageCatalog.months(), &elem(&1, 0)) == Enum.to_list(1..47)
    assert SourceLanguageCatalog.cutlet_name(12) == "lúa mì"
    assert SourceLanguageCatalog.month_name(44) == "muối"
  end

  test "hai ngữ cảnh sản xuất là các giá trị bất biến độc lập" do
    left = PastafariCalendarElixirVietnamese.bootstrap_context(10, 20)
    right = PastafariCalendarElixirVietnamese.bootstrap_context(10, 20)
    changed_left = %{left | status: :changed_only_here}
    assert right.status == :validated
    assert changed_left.status == :changed_only_here
  end

  test "đường sản xuất không trả kết quả trước giai đoạn tích hợp" do
    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      PastafariCalendarElixirVietnamese.calendar_date_spaghetti(1, 1)
    end
  end

  test "mã sản xuất không tham chiếu bộ tham chiếu kiểm thử hay sẹo tương lai" do
    root = Path.expand("../lib", __DIR__)

    source =
      root
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.map_join("\n", &File.read!/1)

    refute source =~ "NormativeReference"

    forbidden = [
      "oldRemainder",
      "oldDayTag",
      "oldDistance",
      "mutateStonesWrong",
      "orderAt46Latch",
      "biasedLegacyPick",
      "LEGACY_YEAR_MAX",
      "oldJumpGuess",
      "VirtualLegacyList",
      "legacyChooseEachDaySeparately",
      "oldContiguousMonthDayGuess"
    ]

    Enum.each(forbidden, fn token -> refute source =~ token end)
  end

  test "văn bản do dòng triển khai tạo không chứa chữ Hebrew" do
    implementation_root = Path.expand("..", __DIR__)

    files =
      ["**/*.ex", "**/*.exs", "**/*.md"]
      |> Enum.flat_map(fn pattern -> Path.wildcard(Path.join(implementation_root, pattern)) end)
      |> Enum.uniq()

    Enum.each(files, fn path ->
      content = File.read!(path)
      refute Regex.match?(~r/[\x{0590}-\x{05FF}]/u, content), "phát hiện chữ Hebrew trong #{path}"
    end)
  end
end
