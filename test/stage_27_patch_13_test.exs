defmodule PastafariCalendarElixirVietnamese.Stage27Patch13Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    LegacyBiasedPick,
    ShortRejectionPatch
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference.AnswerStream, as: RefStream

  @m (1 <<< 127) - 1

  defp sample(first, step) do
    %AnswerStreamManager{first: first, direction_step: step}
  end

  defp oracle(first, step) do
    %RefStream{first: first, direction_step: step}
  end

  test "từ M đi tiến qua đầu vòng trước khi gọi lại bộ legacy" do
    n = div(@m, 2) + 1
    stream = sample(@m, 1)
    result = ShortRejectionPatch.diagnose(stream, n)

    assert result.rejection_limit == n
    assert result.accepted_index == 1
    assert result.rejected_count == 1
    assert result.accepted_value == 1
    assert result.rank == 1
    assert LegacyBiasedPick.biased_legacy_pick(@m, n) != result.rank
    assert LegacyBiasedPick.biased_legacy_pick(result.accepted_value, n) == result.rank
  end

  test "từ M-1 đi tiến bỏ chính xác hai phần tử trên cùng vòng" do
    n = div(@m, 2) + 1
    result = ShortRejectionPatch.diagnose(sample(@m - 1, 1), n)

    assert result.accepted_index == 2
    assert result.rejected_count == 2
    assert result.accepted_value == 1
    assert result.rank == 1
    assert AnswerStreamManager.answer_at(sample(@m - 1, 1), 1) == @m
    assert AnswerStreamManager.answer_at(sample(@m - 1, 1), 2) == 1
  end

  test "từ M đi lùi bỏ ba phần tử rồi chọn chính giá trị limit" do
    n = @m - 3
    result = ShortRejectionPatch.diagnose(sample(@m, -1), n)

    assert result.rejection_limit == @m - 3
    assert result.accepted_index == 3
    assert result.rejected_count == 3
    assert result.accepted_value == @m - 3
    assert result.rank == @m - 3
    assert LegacyBiasedPick.biased_legacy_pick(@m, n) == 3
  end

  test "từ M đi tiến vượt biên và chọn ID thứ nhất" do
    n = @m - 3
    result = ShortRejectionPatch.diagnose(sample(@m, 1), n)

    assert result.accepted_index == 1
    assert result.accepted_value == 1
    assert result.rejected_count == 1
    assert result.rank == 1
  end

  test "giá trị bằng limit được chấp nhận tại chỉ số 0" do
    for n <- [2, 3, 5, 31, 127, div(@m, 2) + 1, @m - 3, @m] do
      limit = div(@m, n) * n

      for step <- [-1, 1] do
        result = ShortRejectionPatch.diagnose(sample(limit, step), n)

        assert result.rejection_limit == limit
        assert result.accepted_value == limit
        assert result.accepted_index == 0
        assert result.rejected_count == 0
        assert result.rank == LegacyBiasedPick.biased_legacy_pick(limit, n)
      end
    end
  end

  test "N chia hết M không kích hoạt một lần từ chối nào" do
    for n <- [1, @m], x <- [1, 2, div(@m, 2), @m], step <- [-1, 1] do
      result = ShortRejectionPatch.diagnose(sample(x, step), n)
      assert result.accepted_index == 0
      assert result.accepted_value == x
      assert result.rank == Ref.choose_rank_short(oracle(x, step), n)
    end
  end

  test "vùng thừa một phần tử với N=3 phải từ chối M" do
    n = 3
    assert rem(@m, n) == 1

    forward = ShortRejectionPatch.diagnose(sample(@m, 1), n)
    backward = ShortRejectionPatch.diagnose(sample(@m, -1), n)

    assert forward.rejection_limit == @m - 1
    assert forward.accepted_index == 1
    assert forward.accepted_value == 1
    assert forward.rank == 1

    assert backward.accepted_index == 1
    assert backward.accepted_value == @m - 1
    assert backward.rank == Ref.choose_rank_short(oracle(@m, -1), n)
  end

  test "ngưỡng N=M-1 đọc đúng phần tử kế cận theo cả hai hướng" do
    n = @m - 1

    forward = ShortRejectionPatch.diagnose(sample(@m, 1), n)
    backward = ShortRejectionPatch.diagnose(sample(@m, -1), n)

    assert forward.accepted_index == 1
    assert forward.accepted_value == 1
    assert forward.rank == 1
    assert backward.accepted_index == 1
    assert backward.accepted_value == @m - 1
    assert backward.rank == n
  end

  test "ngưỡng N=M-2 đi lùi tới phần tử thứ hai mà không thay vòng" do
    n = @m - 2
    result = ShortRejectionPatch.diagnose(sample(@m, -1), n)

    assert result.accepted_index == 2
    assert result.accepted_value == n
    assert result.rejected_count == 2
    assert result.rank == n
  end

  test "trạng thái biên nhận/chối có dạng đúng cho nhiều miền lựa chọn" do
    for n <- [2, 3, 5, 7, 17, 31, 127, 720, @m - 3, @m],
        first <- [1, 2, 3, 7, 127, 719, 720, @m - 3],
        step <- [-1, 1] do
      stream = sample(first, step)
      result = ShortRejectionPatch.diagnose(stream, n)

      assert result.rank == Ref.choose_rank_short(oracle(first, step), n)
      assert result.accepted_value >= 1
      assert result.accepted_value <= result.rejection_limit
      assert result.rank >= 1 and result.rank <= n
      assert result.accepted_index == result.rejected_count
      assert result.accepted_value ==
               AnswerStreamManager.answer_at(stream, result.accepted_index)
    end
  end

  test "mẫu đầu M và M-1 ở biên không lấy hạt ngẫu nhiên mới" do
    for first <- [@m - 1, @m], step <- [-1, 1],
        n <- [@m - 3, @m - 2, @m - 1] do
      stream = sample(first, step)
      trace = ShortRejectionPatch.diagnose(stream, n)
      assert trace.rank == Ref.choose_rank_short(oracle(first, step), n)

      for k <- 0..(trace.accepted_index - 1)//1 do
        assert AnswerStreamManager.answer_at(stream, k) > trace.rejection_limit
      end
    end
  end

  test "chỉ 1 lời gọi legacy trên giá trị đã chấp nhận, dù từ chối trước" do
    n = @m - 3
    trace = ShortRejectionPatch.diagnose(sample(@m, -1), n)

    assert trace.accepted_index == 3
    assert trace.rank ==
             LegacyBiasedPick.biased_legacy_pick(trace.accepted_value, n)
    assert trace.rank != LegacyBiasedPick.biased_legacy_pick(@m, n)
  end

  test "bộ quản lý và patch trả cùng kết quả cho mọi mẫu" do
    for first <- [1, 2, 3, 19, @m - 1, @m],
        step <- [-1, 1],
        n <- [1, 2, 3, 7, @m - 3, @m] do
      stream = sample(first, step)
      expected = Ref.choose_rank_short(oracle(first, step), n)

      assert AnswerStreamManager.choose_rank_short_biased(stream, n) ==
               ShortRejectionPatch.choose_rank_short(stream, n)
      assert ShortRejectionPatch.choose_rank_short(stream, n) == expected
    end
  end

  test "đường public cũng chọn chuẩn trên nhiều ngày thực và các dấu hỏi" do
    foundation = Ref.foundation_day()

    for {c, t} <- [{foundation, foundation},
                   {foundation - 31, foundation + 41},
                   {foundation + 41, foundation - 31}],
        id <- [1, 3, 6], seal <- [1, 21, 33], n <- [2, 3, 5, 31, 720, @m] do
      expected_stream = Ref.sauce(c, t) |> Ref.ask_bowl(id, seal)
      expected = Ref.choose_rank_short(expected_stream, n)
      actual = Calendar.choose_rank_short_spaghetti(c, t, id, seal, n)

      assert actual == expected
    end
  end

  test "ngày có bộ đếm lớn 2048 bit vẫn dùng cùng vòng đáp án" do
    foundation = Ref.foundation_day()

    for jump <- [1 <<< 128, (1 <<< 512) + 7, 1 <<< 2048],
        {c, t} <- [{foundation - jump, foundation + jump},
                   {foundation + jump, foundation - jump}] do
      actual_stream = Calendar.answer_stream_spaghetti(c, t, 2, 31)
      expected_stream = Ref.sauce(c, t) |> Ref.ask_bowl(2, 31)

      assert actual_stream.first == expected_stream.first
      assert actual_stream.direction_step == expected_stream.direction_step

      for n <- [2, 3, 720, @m] do
        assert AnswerStreamManager.choose_rank_short_biased(actual_stream, n) ==
                 Ref.choose_rank_short(expected_stream, n)
      end
    end
  end

  test "nhiều ngữ cảnh song song không truyền giá trị rejection qua lại" do
    foundation = Ref.foundation_day()
    pairs = for i <- -14..14, do: {foundation + 19 * i, foundation - 23 * i}

    results =
      Task.async_stream(pairs, fn {c, t} ->
        stream = Calendar.answer_stream_spaghetti(c, t, 4, 21)
        {stream, ShortRejectionPatch.diagnose(stream, 31)}
      end, max_concurrency: 8, ordered: true, timeout: 15_000)
      |> Enum.map(fn {:ok, output} -> output end)

    Enum.zip(pairs, results)
    |> Enum.each(fn {{c, t}, {stream, trace}} ->
      expected = Ref.sauce(c, t) |> Ref.ask_bowl(4, 21)
      assert stream.first == expected.first
      assert stream.direction_step == expected.direction_step
      assert trace.rank == Ref.choose_rank_short(expected, 31)
    end)
  end

  test "miền N không hợp lệ bị từ chối đúng lỗi từ bộ quản lý" do
    stream = sample(7, 1)

    for n <- [-7, -1, 0, nil, 2.0, "2", @m + 1] do
      assert_raise ArgumentError, "miền chọn ngắn phải thuộc 1..M", fn ->
        AnswerStreamManager.choose_rank_short_biased(stream, n)
      end

      assert_raise ArgumentError, "miền chọn ngắn phải thuộc 1..M", fn ->
        ShortRejectionPatch.diagnose(stream, n)
      end
    end
  end

  test "mã nguồn dùng vòng cũ chỉ sau chấp nhận; không có wide detour" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_biased_pick.ex") |> File.read!()
    patch = Path.join(root, "short_rejection_patch.ex") |> File.read!()
    manager = Path.join(root, "answer_stream_manager.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert legacy =~ "rem(x - 1, n) + 1"
    assert patch =~ "reject_until_accepted(stream, n, limit, k + 1)"
    assert patch =~ "AnswerStreamManager.answer_at(stream, k)"
    assert patch =~ "if x <= limit do"
    assert patch =~ "LegacyBiasedPick.biased_legacy_pick(x, n)"
    assert patch =~ "div(AnswerStreamManager.modulus(), n) * n"
    assert manager =~ "ShortRejectionPatch.choose_rank_short(stream, n)"
    assert dispatcher =~ "AnswerStreamManager.choose_rank_short_biased(n)"
    refute legacy =~ "ShortRejectionPatch"
    refute patch =~ "NormativeReference"
    refute File.exists?(Path.join(root, "wide_detour.ex"))
  end
end
