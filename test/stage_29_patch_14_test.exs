defmodule PastafariCalendarElixirVietnamese.Stage29Patch14Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    LegacySingleDigitWidePick,
    ShortRejectionPatch,
    WideDetourPatch
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference.AnswerStream, as: RefStream

  @m (1 <<< 127) - 1

  defp ring(first, step), do: %AnswerStreamManager{first: first, direction_step: step}
  defp oracle(first, step), do: %RefStream{first: first, direction_step: step}

  test "bốn hồi quy chuẩn của phát hiện 14 trở lại xanh" do
    stream = ring(1, 1)
    reference = oracle(1, 1)

    for n <- [@m + 1, @m * @m, @m * @m + 1, @m * @m * @m + 1] do
      assert AnswerStreamManager.choose_rank(stream, n) == Ref.choose_rank(reference, n)
      assert WideDetourPatch.choose_rank_wide(stream, n) == Ref.choose_rank(reference, n)
      assert LegacySingleDigitWidePick.choose_rank(stream, n) == 1
    end
  end

  test "số chữ số tối thiểu đúng tại cả bốn ranh giới" do
    for {n, digits, space} <- [
          {@m + 1, 2, @m * @m},
          {@m * @m, 2, @m * @m},
          {@m * @m + 1, 3, @m * @m * @m},
          {@m * @m * @m + 1, 4, @m * @m * @m * @m}
        ] do
      report = WideDetourPatch.diagnose(ring(1, 1), n)
      assert report.digit_count == digits
      assert report.space == space
      assert div(space, @m) < n
      assert report.initial_wide <= space
    end
  end

  test "chữ số little-endian thứ hai có trọng số M" do
    report = WideDetourPatch.diagnose(ring(1, 1), @m + 1)
    assert report.initial_wide == @m + 1
    assert report.accepted_wide == @m + 1
    assert report.rejected_count == 0
    assert report.rank == @m + 1
  end

  test "hướng lùi dùng chính chữ số thứ hai ở đuôi vòng" do
    n = @m + 1
    report = WideDetourPatch.diagnose(ring(1, -1), n)
    assert report.initial_wide == 1 + (@m - 1) * @m
    assert report.rank == Ref.choose_rank(oracle(1, -1), n)
    assert report.rank != LegacySingleDigitWidePick.choose_rank(ring(1, -1), n)
  end

  test "các phần tử ở cả hai biên M không đổi seed hoặc chiều" do
    for first <- [1, 2, 3, @m - 2, @m - 1, @m],
        step <- [-1, 1], n <- [@m + 1, @m * @m, @m * @m + 1] do
      original = ring(first, step)
      trace = WideDetourPatch.diagnose(original, n)
      if trace.initial_wide <= trace.rejection_limit do
        assert AnswerStreamManager.choose_rank(original, n) ==
                 Ref.choose_rank(oracle(first, step), n)
      else
        assert trace.rank == (if step == 1, do: 1,
                               else: Integer.mod(trace.rejection_limit - 1, n) + 1)
        assert AnswerStreamManager.choose_rank(original, n) == trace.rank
      end
      assert original.first == first
      assert original.direction_step == step
    end
  end

  test "khi n=M² mọi giá trị wide được chấp nhận ngay" do
    n = @m * @m

    for first <- [1, 2, @m - 1, @m], step <- [-1, 1] do
      result = WideDetourPatch.diagnose(ring(first, step), n)
      assert result.rejection_limit == result.space
      assert result.accepted_wide == result.initial_wide
      assert result.rejected_count == 0
    end
  end

  test "detour tiến thực hiện vòng về 1 với hàng tỷ tỷ bước tương đương" do
    space = @m * @m
    n = div(space, 2) + 1
    result = WideDetourPatch.diagnose(ring(@m - 2, 1), n)
    assert result.initial_wide > result.rejection_limit
    assert result.rejection_limit == n
    assert result.accepted_wide == 1
    assert result.rejected_count == space - result.initial_wide + 1
    assert result.rejected_count > @m
    assert result.rank == 1
  end

  test "detour lùi dừng đúng tại limit dù khoảng cách khổng lồ" do
    space = @m * @m
    n = div(space, 2) + 1
    result = WideDetourPatch.diagnose(ring(@m - 1, -1), n)
    assert result.initial_wide > n
    assert result.rejection_limit == n
    assert result.accepted_wide == n
    assert result.rejected_count == result.initial_wide - n
    assert result.rejected_count > @m
    assert result.rank == n
  end

  test "không dịch chuyển khi giá trị bằng limit" do
    n = @m * @m - 1

    for first <- [1, 2, @m - 1, @m], step <- [-1, 1] do
      result = WideDetourPatch.diagnose(ring(first, step), n)
      assert result.initial_wide <= result.rejection_limit
      assert result.accepted_wide == result.initial_wide
      assert result.rejected_count == 0
    end
  end

  test "hạng ngắn vẫn thuộc ShortRejectionPatch và không đổi biên" do
    for first <- [1, 2, @m - 1, @m], step <- [-1, 1],
        n <- [1, 2, 3, 720, @m - 3, @m] do
      stream = ring(first, step)
      assert AnswerStreamManager.choose_rank(stream, n) ==
               ShortRejectionPatch.choose_rank_short(stream, n)
      assert AnswerStreamManager.choose_rank(stream, n) == Ref.choose_rank(oracle(first, step), n)
    end
  end

  test "các miền rộng 127 đến 2048 bit đều khớp oracle" do
    for n <- [@m + 1, @m * @m - 1, @m * @m + 1, @m * @m * @m,
               Integer.pow(@m, 7), Integer.pow(@m, 8) + 1, 1 <<< 2048],
        first <- [1, 2, 17, @m - 1], step <- [-1, 1] do
      stream = ring(first, step)
      report = WideDetourPatch.diagnose(stream, n)
      if report.rejected_count == 0 do
        assert report.rank == Ref.choose_rank(oracle(first, step), n)
      else
        assert report.rank == (if step == 1, do: 1,
                               else: Integer.mod(report.rejection_limit - 1, n) + 1)
      end
      assert report.rank == WideDetourPatch.choose_rank_wide(stream, n)
    end
  end

  test "báo cáo wide tự nhất quán với phép chọn và điều kiện rejection" do
    for n <- [@m + 1, @m * @m, @m * @m + 1, Integer.pow(@m, 4)],
        first <- [1, 2, 17, @m], step <- [-1, 1] do
      stream = ring(first, step)
      report = WideDetourPatch.diagnose(stream, n)
      assert report.space >= n
      assert report.rejection_limit == div(report.space, n) * n
      assert report.accepted_wide in 1..report.rejection_limit
      assert report.rank == Integer.mod(report.accepted_wide - 1, n) + 1
      assert report.rank == AnswerStreamManager.choose_rank(stream, n)
      assert report.rejected_count >= 0
    end
  end

  test "hạng trả lại luôn ở 1..N dù các giá trị cực lớn" do
    for first <- [1, @m], step <- [-1, 1],
        n <- [@m + 1, @m * @m, @m * @m * @m + 1, 1 <<< 2048] do
      rank = WideDetourPatch.choose_rank_wide(ring(first, step), n)
      assert rank >= 1 and rank <= n
    end
  end

  test "API công khai khớp oracle trên ngày thực và bát khác nhau" do
    foundation = Ref.foundation_day()
    pairs = [{foundation, foundation}, {foundation - 17, foundation + 29},
             {foundation + 41, foundation - 31}]

    for {c, t} <- pairs, id <- [1, 3, 6], seal <- [1, 21],
        n <- [@m + 1, @m * @m + 1] do
      expected = Ref.sauce(c, t) |> Ref.ask_bowl(id, seal) |> Ref.choose_rank(n)
      assert Calendar.choose_rank_spaghetti(c, t, id, seal, n) == expected
    end
  end

  test "ngày đếm 2048 bit vẫn dùng cùng seed và nhiều chữ số" do
    f = Ref.foundation_day()
    jump = (1 <<< 2048) + 29

    for {c, t} <- [{f - jump, f + jump}, {f + jump, f - jump}] do
      stream = Calendar.answer_stream_spaghetti(c, t, 2, 31)
      reference = Ref.sauce(c, t) |> Ref.ask_bowl(2, 31)
      assert stream.first == reference.first
      assert stream.direction_step == reference.direction_step

      for n <- [@m + 1, @m * @m + 1, 1 <<< 2048] do
        assert AnswerStreamManager.choose_rank(stream, n) == Ref.choose_rank(reference, n)
      end
    end
  end

  test "nhiều lựa chọn wide song song không dùng trạng thái chia sẻ" do
    f = Ref.foundation_day()
    pairs = for k <- -10..10, do: {f + 17 * k, f - 19 * k}
    n = @m * @m + 1

    actual =
      Task.async_stream(pairs, fn {c, t} ->
        Calendar.choose_rank_spaghetti(c, t, 4, 21, n)
      end, max_concurrency: 6, ordered: true, timeout: 20_000)
      |> Enum.map(fn {:ok, value} -> value end)

    Enum.zip(pairs, actual)
    |> Enum.each(fn {{c, t}, rank} ->
      reference = Ref.sauce(c, t) |> Ref.ask_bowl(4, 21)
      assert rank == Ref.choose_rank(reference, n)
    end)
  end

  test "LegacySingleDigitWidePick không bị sửa bởi bản vá" do
    stream = ring(1, 1)
    for n <- [@m + 1, @m * @m, Integer.pow(@m, 3) + 1] do
      assert LegacySingleDigitWidePick.choose_rank(stream, n) == 1
      assert AnswerStreamManager.choose_rank(stream, n) > 1
    end
  end

  test "dữ liệu không hợp lệ bị từ chối trong patch" do
    stream = ring(7, 1)
    for n <- [0, -1, @m, nil, 1.5, "n"] do
      assert_raise ArgumentError, "miền chọn rộng phải lớn hơn M", fn ->
        WideDetourPatch.choose_rank_wide(stream, n)
      end
    end
    assert_raise ArgumentError, "miền chọn rộng phải lớn hơn M", fn ->
      WideDetourPatch.choose_rank_wide(%{}, @m + 1)
    end
  end

  test "kiểm toán mã nguồn: patch không dùng oracle hoặc hạt mới" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    manager = Path.join(root, "answer_stream_manager.ex") |> File.read!()
    patch = Path.join(root, "wide_detour_patch.ex") |> File.read!()
    legacy = Path.join(root, "legacy_single_digit_wide_pick.ex") |> File.read!()

    assert manager =~ "WideDetourPatch.choose_rank_wide(stream, n)"
    assert patch =~ "AnswerStreamManager.answer_at(stream, j)"
    assert patch =~ "Integer.mod(accepted - 1, n) + 1"
    assert patch =~ "defp detour(wide, -1, _space, limit)"
    assert patch =~ "defp detour(wide, 1, space, _limit)"
    assert legacy =~ "LegacyBiasedPick.biased_legacy_pick(x, n)"
    refute patch =~ "NormativeReference"
    refute patch =~ "LegacySingleDigitWidePick.choose_rank"
  end
end
