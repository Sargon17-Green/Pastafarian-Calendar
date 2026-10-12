defmodule PastafariCalendarElixirVietnamese.Stage28Discovery14Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    LegacyBiasedPick,
    LegacySingleDigitWidePick,
    ShortRejectionPatch
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference.AnswerStream, as: RefStream

  @m (1 <<< 127) - 1

  defp ring(first, step) do
    %AnswerStreamManager{first: first, direction_step: step}
  end

  defp reference_ring(first, step) do
    %RefStream{first: first, direction_step: step}
  end

  test "hàm lịch sử rộng chỉ dùng một phần tử đầu rồi gọi legacy modulo" do
    for first <- [1, 2, 7, div(@m, 2), @m - 1, @m],
        step <- [-1, 1],
        n <- [@m + 1, @m * @m, @m * @m + 1] do
      stream = ring(first, step)
      actual = LegacySingleDigitWidePick.choose_rank(stream, n)

      assert actual == AnswerStreamManager.answer_at(stream, 0)
      assert actual == LegacyBiasedPick.biased_legacy_pick(first, n)
    end
  end

  test "hạng legacy không thể vượt M khi N lớn hơn M" do
    for first <- [1, 2, 37, @m - 1, @m], n <- [@m + 1, @m * @m + 1] do
      rank = LegacySingleDigitWidePick.choose_rank(ring(first, 1), n)
      assert rank >= 1
      assert rank <= @m
      assert rank <= n
    end
  end

  test "hàm chọn tổng quát vẫn đúng với mọi N ngắn đã vá" do
    for first <- [1, 2, 7, @m - 1, @m],
        step <- [-1, 1],
        n <- [1, 2, 3, 17, 720, @m - 3, @m] do
      stream = ring(first, step)
      expected = Ref.choose_rank(reference_ring(first, step), n)
      assert AnswerStreamManager.choose_rank(stream, n) == expected
      assert AnswerStreamManager.choose_rank(stream, n) ==
               ShortRejectionPatch.choose_rank_short(stream, n)
    end
  end

  test "tại ranh giới N=M bộ tổng quát còn đọc đường ngắn" do
    for first <- [1, 2, @m - 1, @m], step <- [-1, 1] do
      stream = ring(first, step)
      assert AnswerStreamManager.choose_rank(stream, @m) == first
      assert AnswerStreamManager.choose_rank(stream, @m) ==
               Ref.choose_rank(reference_ring(first, step), @m)
    end
  end

  test "ngay trên biên N=M+1 đường rộng thực sử dụng vòng ID cố định" do
    stream = ring(1, 1)
    n = @m + 1

    assert LegacySingleDigitWidePick.choose_rank(stream, n) == 1
    assert AnswerStreamManager.choose_rank(stream, n) == @m + 1
    assert Ref.choose_rank_wide(reference_ring(1, 1), n) == @m + 1
  end

  test "chuỗi chuẩn cho N=M+1 dùng đúng hai chữ số little-endian" do
    stream = reference_ring(1, 1)
    n = @m + 1
    {k, space} = Ref.smallest_power_count(@m, n)

    assert k == 2
    assert space == @m * @m
    assert Ref.answer_at(stream, 0) == 1
    assert Ref.answer_at(stream, 1) == 2
    assert Ref.choose_rank_wide(stream, n) == @m + 1
  end

  test "N=M² cần hai chữ số, N=M²+1 cần ba chữ số" do
    assert Ref.smallest_power_count(@m, @m * @m) == {2, @m * @m}
    assert Ref.smallest_power_count(@m, @m * @m + 1) == {3, @m * @m * @m}
    assert Ref.smallest_power_count(@m, @m * @m * @m + 1) ==
             {4, @m * @m * @m * @m}
  end

  test "đường vòng answer_at vẫn đúng với cùng hạt và hai chiều" do
    for first <- [1, 2, 7, @m - 1, @m], step <- [-1, 1],
        position <- [0, 1, 2, 3, 31, @m + 2] do
      assert AnswerStreamManager.answer_at(ring(first, step), position) ==
               Ref.answer_at(reference_ring(first, step), position)
    end
  end

  test "công thức lưu chữ số chuẩn không đồng nhất với một chữ số" do
    stream = reference_ring(1, 1)
    d0 = Ref.answer_at(stream, 0) - 1
    d1 = Ref.answer_at(stream, 1) - 1
    wide0 = 1 + d0 + d1 * @m

    assert d0 == 0
    assert d1 == 1
    assert wide0 == @m + 1
    assert wide0 > @m
    assert LegacySingleDigitWidePick.choose_rank(ring(1, 1), @m + 1) == 1
  end

  test "khi đảo chiều, hàm lỗi vẫn bỏ qua chữ số kế bên" do
    stream = ring(1, -1)
    next_digit = AnswerStreamManager.answer_at(stream, 1)

    assert next_digit == @m
    assert AnswerStreamManager.answer_at(stream, 0) == 1
    assert AnswerStreamManager.choose_rank(stream, @m + 1) ==
             Ref.choose_rank(reference_ring(1, -1), @m + 1)
    assert LegacySingleDigitWidePick.choose_rank(stream, @m + 1) == 1
  end

  test "API sản xuất chọn hạng rộng thật qua legacy, ngày và dấu hỏi thực" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 17, f + 29}, {f + 29, f - 17}],
        id <- [1, 3, 6], seal <- [1, 21, 31] do
      stream = Calendar.answer_stream_spaghetti(c, t, id, seal)
      actual = Calendar.choose_rank_spaghetti(c, t, id, seal, @m + 1)

      expected = Ref.sauce(c, t) |> Ref.ask_bowl(id, seal) |> Ref.choose_rank(@m + 1)
      assert actual == expected
      assert LegacySingleDigitWidePick.choose_rank(stream, @m + 1) == stream.first
      assert stream.first in 1..@m
    end
  end

  test "API tổng quát bảo toàn chọn ngắn cho ngày thực" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 31, f + 41}, {f + 41, f - 31}],
        id <- [1, 4], seal <- [1, 21], n <- [1, 2, 5, 720, @m] do
      actual = Calendar.choose_rank_spaghetti(c, t, id, seal, n)
      expected = Ref.sauce(c, t) |> Ref.ask_bowl(id, seal) |> Ref.choose_rank(n)

      assert actual == expected
      assert actual == Calendar.choose_rank_short_spaghetti(c, t, id, seal, n)
    end
  end

  test "trường hợp N và hạt không hợp lệ bị từ chối" do
    stream = ring(7, 1)

    for bad <- [-1, 0, 1, @m, nil, 1.5, "4"] do
      assert_raise ArgumentError, "miền chọn rộng phải lớn hơn M", fn ->
        LegacySingleDigitWidePick.choose_rank(stream, bad)
      end
    end

    for bad <- [-1, 0, nil, 1.5, "4"] do
      assert_raise ArgumentError, "miền chọn phải là số nguyên dương", fn ->
        AnswerStreamManager.choose_rank(stream, bad)
      end
    end
  end

  test "ngày lớn 2048 bit không làm hỏng stream và legacy một chữ số" do
    f = Ref.foundation_day()
    jump = (1 <<< 2048) + 3

    for {c, t} <- [{f - jump, f + jump}, {f + jump, f - jump}] do
      stream = Calendar.answer_stream_spaghetti(c, t, 2, 31)
      expected = Ref.sauce(c, t) |> Ref.ask_bowl(2, 31)

      assert stream.first == expected.first
      assert stream.direction_step == expected.direction_step
      assert Calendar.choose_rank_spaghetti(c, t, 2, 31, @m + 1) ==
               Ref.choose_rank(expected, @m + 1)
    end
  end

  test "nhiều ngày song song không tạo trạng thái chung cho chọn rộng" do
    f = Ref.foundation_day()
    pairs = for k <- -12..12, do: {f + 17 * k, f - 23 * k}

    results =
      Task.async_stream(pairs, fn {c, t} ->
        stream = Calendar.answer_stream_spaghetti(c, t, 4, 21)
        {stream, Calendar.choose_rank_spaghetti(c, t, 4, 21, @m + 1)}
      end, max_concurrency: 8, ordered: true, timeout: 15_000)
      |> Enum.map(fn {:ok, result} -> result end)

    Enum.zip(pairs, results)
    |> Enum.each(fn {{c, t}, {stream, rank}} ->
      expected_stream = Ref.sauce(c, t) |> Ref.ask_bowl(4, 21)
      assert stream.first == expected_stream.first
      assert stream.direction_step == expected_stream.direction_step
      assert rank == Ref.choose_rank(expected_stream, @m + 1)
    end)
  end

  test "kiểm toán nguồn: production phân nhánh short đúng và wide legacy sai" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    manager = Path.join(root, "answer_stream_manager.ex") |> File.read!()
    legacy = Path.join(root, "legacy_single_digit_wide_pick.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert manager =~ "ShortRejectionPatch.choose_rank_short(stream, n)"
    assert manager =~ "WideDetourPatch.choose_rank_wide(stream, n)"
    assert legacy =~ "AnswerStreamManager.answer_at(stream, 0)"
    assert legacy =~ "LegacyBiasedPick.biased_legacy_pick(x, n)"
    assert dispatcher =~ "AnswerStreamManager.choose_rank(n)"
    refute legacy =~ "smallest_power_count"
    assert File.exists?(Path.join(root, "wide_detour_patch.ex"))
  end

  test "hồi quy chuẩn: N=M+1 cần hai chữ số, cố ý đỏ" do
    stream = ring(1, 1)
    n = @m + 1
    actual = AnswerStreamManager.choose_rank(stream, n)
    expected = Ref.choose_rank(reference_ring(1, 1), n)
    assert actual == expected
  end

  test "hồi quy chuẩn: N=M² vẫn cần chữ số thứ hai, cố ý đỏ" do
    stream = ring(1, 1)
    n = @m * @m
    actual = AnswerStreamManager.choose_rank(stream, n)
    expected = Ref.choose_rank(reference_ring(1, 1), n)
    assert actual == expected
  end

  test "hồi quy chuẩn: N=M²+1 cần ba chữ số, cố ý đỏ" do
    stream = ring(1, 1)
    n = @m * @m + 1
    actual = AnswerStreamManager.choose_rank(stream, n)
    expected = Ref.choose_rank(reference_ring(1, 1), n)
    assert actual == expected
  end

  test "hồi quy chuẩn: N=M³+1 cần bốn chữ số, cố ý đỏ" do
    stream = ring(1, 1)
    n = @m * @m * @m + 1
    actual = AnswerStreamManager.choose_rank(stream, n)
    expected = Ref.choose_rank(reference_ring(1, 1), n)
    assert actual == expected
  end
end
