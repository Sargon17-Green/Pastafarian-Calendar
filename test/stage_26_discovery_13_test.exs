defmodule PastafariCalendarElixirVietnamese.Stage26Discovery13Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    LegacyBiasedPick,
    NextBowlPatchWrapper
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference.AnswerStream, as: RefStream

  @m (1 <<< 127) - 1

  defp normative_stream(c, t, id, seal) do
    result = Ref.sauce(c, t)
    Ref.ask_bowl(result, id, seal)
  end

  defp from_first(first, step) do
    %AnswerStreamManager{first: first, direction_step: step}
  end

  defp oracle_from_first(first, step) do
    %RefStream{first: first, direction_step: step}
  end

  test "miền M nhất quán với SAVE và mô đun chuẩn" do
    assert AnswerStreamManager.modulus() == Ref.m()
    assert AnswerStreamManager.modulus() == @m
    assert Calendar.save_value_spaghetti(@m) == @m
    assert Calendar.save_value_spaghetti(@m + 1) == 1
  end

  test "hạt vòng đáp án từ ba hướng ngày, nhiều loại dấu hỏi" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 17, f + 41}, {f + 41, f - 17}],
        id <- [1, 3, 6],
        seal <- [1, 10, 21, 31] do
      expected = normative_stream(c, t, id, seal)
      got = Calendar.answer_stream_spaghetti(c, t, id, seal)

      assert got.first == expected.first
      assert got.direction_step == expected.direction_step
      assert got.first >= 1 and got.first <= @m
      assert got.direction_step in [-1, 1]
    end
  end

  test "giá trị đầu vòng dùng ID kế cận đúng chứ không phải tên cố định" do
    f = Ref.foundation_day()
    ctx = Calendar.bootstrap_context(f, f)
    id = 3
    seal = 21
    next_id = NextBowlPatchWrapper.next_bowl(ctx.order_at_46_latch, id)
    old_value = Map.fetch!(ctx.bowls_after_post_stirs, id)
    next_value = Map.fetch!(ctx.bowls_after_post_stirs, next_id)
    first = Ref.save((old_value + seal + 181) * (old_value + seal + 181) +
      179 * next_value + seal)

    assert Calendar.answer_stream_spaghetti(f, f, id, seal).first == first
    assert Calendar.next_bowl_spaghetti(f, f, id) == next_id
  end

  test "chiều của vòng đáp án lấy đúng parity của SAVE lần hai" do
    f = Ref.foundation_day()
    c = f - 31
    t = f + 79
    id = 6
    seal = 33
    ctx = Calendar.bootstrap_context(c, t)
    stream = Calendar.answer_stream_spaghetti(c, t, id, seal)
    z = Ref.save((stream.first + seal + 1 + 193) *
      (stream.first + seal + 1 + 193) +
      193 * stream.first + 197 * ctx.bowls_after_post_stirs[6])

    assert stream.direction_step == (if rem(z, 2) == 1, do: 1, else: -1)
  end

  test "các vị trí 0, 1, 2, 31 và M+5 của vòng đều khớp chuẩn" do
    f = Ref.foundation_day()
    c = f + 15
    t = f - 17

    for id <- [1, 4, 6], seal <- [1, 20, 33] do
      got = Calendar.answer_stream_spaghetti(c, t, id, seal)
      expected = normative_stream(c, t, id, seal)

      for k <- [0, 1, 2, 31, @m + 5] do
        assert AnswerStreamManager.answer_at(got, k) ==
                 Ref.answer_at(expected, k)
      end
    end
  end

  test "vòng tiến lên quấn từ M về 1" do
    stream = from_first(@m, 1)

    assert AnswerStreamManager.answer_at(stream, 0) == @m
    assert AnswerStreamManager.answer_at(stream, 1) == 1
    assert AnswerStreamManager.answer_at(stream, 2) == 2
    assert AnswerStreamManager.answer_at(stream, @m + 1) == 1
  end

  test "vòng lùi xuống quấn từ 1 về M" do
    stream = from_first(1, -1)

    assert AnswerStreamManager.answer_at(stream, 0) == 1
    assert AnswerStreamManager.answer_at(stream, 1) == @m
    assert AnswerStreamManager.answer_at(stream, 2) == @m - 1
    assert AnswerStreamManager.answer_at(stream, @m + 1) == @m
  end

  test "hàm legacy vẫn luôn chọn trực tiếp theo modulo" do
    n = div(@m, 2) + 1

    for x <- [1, 2, n, n + 1, @m - 1, @m] do
      assert LegacyBiasedPick.biased_legacy_pick(x, n) ==
               rem(x - 1, n) + 1
    end

    assert LegacyBiasedPick.biased_legacy_pick(@m, n) == n - 1
  end

  test "đường chọn ngắn thật gọi legacy cả khi x vượt limit" do
    n = div(@m, 2) + 1
    limit = div(@m, n) * n
    stream = from_first(@m, 1)

    assert limit == n
    assert stream.first > limit
    assert AnswerStreamManager.choose_rank_short_biased(stream, n) ==
             LegacyBiasedPick.biased_legacy_pick(@m, n)
    refute AnswerStreamManager.choose_rank_short_biased(stream, n) ==
             Ref.choose_rank_short(oracle_from_first(@m, 1), n)
  end

  test "khi N chia hết M, lựa chọn không cần từ chối vẫn đúng" do
    for x <- [1, 2, @m - 1, @m] do
      stream = from_first(x, 1)
      oracle = oracle_from_first(x, 1)

      assert AnswerStreamManager.choose_rank_short_biased(stream, @m) ==
               Ref.choose_rank_short(oracle, @m)
    end
  end

  test "N=1 luôn trả 1 mà không phụ thuộc chiều hay hạt vòng" do
    for x <- [1, div(@m, 2), @m], step <- [-1, 1] do
      assert AnswerStreamManager.choose_rank_short_biased(from_first(x, step), 1) == 1
    end
  end

  test "lựa chọn sản xuất với N=M vẫn trùng oracle từ ngày thực" do
    f = Ref.foundation_day()
    for {c, t} <- [{f, f}, {f - 47, f + 19}, {f + 19, f - 47}] do
      actual = Calendar.choose_rank_short_spaghetti(c, t, 4, 21, @m)
      stream = normative_stream(c, t, 4, 21)
      assert actual == Ref.choose_rank_short(stream, @m)
    end
  end

  test "không vượt biên dữ liệu ngắn và ngày 2048 bit vẫn tính đúng vòng" do
    f = Ref.foundation_day()
    shift = (1 <<< 2048) + 1

    for {c, t} <- [{f - shift, f + shift}, {f + shift, f - shift}] do
      stream = Calendar.answer_stream_spaghetti(c, t, 2, 31)
      expected = normative_stream(c, t, 2, 31)
      assert stream.first == expected.first
      assert stream.direction_step == expected.direction_step
      assert Calendar.choose_rank_short_spaghetti(c, t, 2, 31, @m) ==
               Ref.choose_rank_short(expected, @m)
    end
  end

  test "đầu vào vòng và chọn ngắn không hợp lệ bị từ chối" do
    for bad <- [0, -1, nil, 1.0, "1"] do
      assert_raise ArgumentError, "miền chọn ngắn phải thuộc 1..M", fn ->
        AnswerStreamManager.choose_rank_short_biased(from_first(7, 1), bad)
      end
    end

    for bad <- [-1, nil, 1.5, "1"] do
      assert_raise ArgumentError, "vị trí vòng đáp án không hợp lệ", fn ->
        AnswerStreamManager.answer_at(from_first(7, 1), bad)
      end
    end

    assert_raise ArgumentError, "miền chọn ngắn phải thuộc 1..M", fn ->
      AnswerStreamManager.choose_rank_short_biased(from_first(7, 1), @m + 1)
    end

    assert_raise ArgumentError, "đầu vào vòng đáp án không hợp lệ", fn ->
      AnswerStreamManager.build(%{}, 1, 2, 0)
    end
  end

  test "kiểm toán nguồn: stream chính xác, legacy chưa có rejection" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    source = Path.join(root, "answer_stream_manager.ex") |> File.read!()
    legacy = Path.join(root, "legacy_biased_pick.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert legacy =~ "rem(x - 1, n) + 1"
    assert source =~ "LegacyBiasedPick.biased_legacy_pick(x, n)"
    assert source =~ "x = answer_at(stream, 0)"
    assert dispatcher =~ "AnswerStreamManager.choose_rank_short_biased(n)"
    refute source =~ "rejection_limit"
    refute source =~ "reject_before_pick"
    refute File.exists?(Path.join(root, "short_rejection_patch.ex"))
  end

  test "hồi quy chuẩn: x=M phải bị từ chối trước khi chọn N>M/2" do
    n = div(@m, 2) + 1
    actual = AnswerStreamManager.choose_rank_short_biased(from_first(@m, 1), n)
    expected = Ref.choose_rank_short(oracle_from_first(@m, 1), n)
    assert actual == expected
  end

  test "hồi quy chuẩn: vòng tiến từ M-1 phải bỏ hai giá trị" do
    n = div(@m, 2) + 1
    actual = AnswerStreamManager.choose_rank_short_biased(from_first(@m - 1, 1), n)
    expected = Ref.choose_rank_short(oracle_from_first(@m - 1, 1), n)
    assert actual == expected
  end

  test "hồi quy chuẩn: vòng lùi từ M phải bỏ ba giá trị" do
    n = @m - 3
    actual = AnswerStreamManager.choose_rank_short_biased(from_first(@m, -1), n)
    expected = Ref.choose_rank_short(oracle_from_first(@m, -1), n)
    assert actual == expected
  end

  test "hồi quy chuẩn: vòng tiến với biên N=M-3 phải bỏ x=M" do
    n = @m - 3
    actual = AnswerStreamManager.choose_rank_short_biased(from_first(@m, 1), n)
    expected = Ref.choose_rank_short(oracle_from_first(@m, 1), n)
    assert actual == expected
  end
end
