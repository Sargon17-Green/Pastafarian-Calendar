defmodule PastafariCalendarElixirVietnamese.Stage25Patch12Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{
    LegacyFixedNameSuccessor,
    LegacyOrderMemory,
    NextBowlPatchWrapper,
    OrderAt46LatchPatch
  }
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  @fixture [4, 5, 2, 3, 6, 1]
  @ids [1, 2, 3, 4, 5, 6]

  defp correct_next(order, id) do
    position = Enum.find_index(order, &(&1 == id))
    Enum.at(order, rem(position + 1, 6))
  end

  test "ID 3 trả 6 từ vị trí thật, giữ legacy trả 4 riêng trong chẩn đoán" do
    report = NextBowlPatchWrapper.diagnose(@fixture, 3)

    assert report == %{
      queried_id: 3,
      legacy_next_id: 4,
      correct_next_id: 6,
      diverges: true
    }

    assert NextBowlPatchWrapper.next_bowl(@fixture, 3) == 6
    assert LegacyFixedNameSuccessor.old_next_bowl_fixed_name(3) == 4
  end

  test "mọi ID trong ví dụ chứng minh hai chu trình kế cận khác nhau" do
    actual = Enum.map(@ids, &NextBowlPatchWrapper.next_bowl(@fixture, &1))
    expected = Enum.map(@ids, &correct_next(@fixture, &1))
    old = Enum.map(@ids, &LegacyFixedNameSuccessor.old_next_bowl_fixed_name/1)

    assert actual == [4, 3, 6, 5, 2, 1]
    assert actual == expected
    assert old == [2, 3, 4, 5, 6, 1]
    refute actual == old
  end

  test "đường nối vòng từ vị trí thứ sáu trở về vị trí đầu" do
    assert List.last(@fixture) == 1
    assert hd(@fixture) == 4
    assert NextBowlPatchWrapper.next_bowl(@fixture, 1) == 4

    for rank <- [1, 2, 119, 360, 719, 720] do
      order = Ref.bowl_order_from_number(rank)
      assert NextBowlPatchWrapper.next_bowl(order, List.last(order)) == hd(order)
    end
  end

  test "so sánh đủ 720 hoán vị và cả sáu ID với thuật toán chuẩn" do
    for rank <- 1..720 do
      order = Ref.bowl_order_from_number(rank)

      for id <- @ids do
        expected = correct_next(order, id)
        assert NextBowlPatchWrapper.next_bowl(order, id) == expected

        report = NextBowlPatchWrapper.diagnose(order, id)
        assert report.correct_next_id == expected
        assert report.legacy_next_id == rem(id, 6) + 1
        assert report.diverges == (expected != report.legacy_next_id)
      end
    end
  end

  test "chỉ sáu hoán vị xoay của vòng ID cố định không tạo sai lệch" do
    matches =
      Enum.count(1..720, fn rank ->
        order = Ref.bowl_order_from_number(rank)

        Enum.all?(@ids, fn id ->
          not NextBowlPatchWrapper.diagnose(order, id).diverges
        end)
      end)

    assert matches == 6
  end

  test "với vòng danh tính nguyên gốc vẫn gọi legacy và trả cùng kết quả" do
    order = [1, 2, 3, 4, 5, 6]

    for id <- @ids do
      report = NextBowlPatchWrapper.diagnose(order, id)
      assert report.legacy_next_id == report.correct_next_id
      assert report.diverges == false
      assert report.correct_next_id == rem(id, 6) + 1
    end
  end

  test "legacy không bị sửa và vẫn sai nếu gọi trực tiếp" do
    for id <- @ids do
      assert LegacyFixedNameSuccessor.old_next_bowl_fixed_name(id) == rem(id, 6) + 1
    end

    assert LegacyFixedNameSuccessor.old_next_bowl_fixed_name(3) !=
             NextBowlPatchWrapper.next_bowl(@fixture, 3)
    assert OrderAt46LatchPatch.next_bowl(@fixture, 3) == 6
  end

  test "mỗi kết quả chẩn đoán là dữ liệu riêng không bị rò giữa truy vấn" do
    first = NextBowlPatchWrapper.diagnose(@fixture, 3)
    second = NextBowlPatchWrapper.diagnose(@fixture, 5)

    assert first.queried_id == 3
    assert second.queried_id == 5
    assert first.correct_next_id == 6
    assert second.correct_next_id == 2

    fake = Map.put(first, :correct_next_id, -1)
    assert fake.correct_next_id == -1
    assert NextBowlPatchWrapper.diagnose(@fixture, 3) == first
  end

  test "truy vấn công khai và báo cáo chẩn đoán khớp sáu ID theo oracle" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 17, f + 37}, {f + 37, f - 17}] do
      result = Ref.sauce(c, t)

      for id <- @ids do
        expected = Ref.next_bowl_in_drop_46_order(result, id)
        report = Calendar.next_bowl_diagnostic_spaghetti(c, t, id)

        assert Calendar.next_bowl_spaghetti(c, t, id) == expected
        assert report.correct_next_id == expected
        assert report.legacy_next_id == LegacyFixedNameSuccessor.old_next_bowl_fixed_name(id)
      end
    end
  end

  test "các kết quả từ bộ đếm ngày rất xa vẫn đúng cho 2048 bit" do
    f = Ref.foundation_day()

    for jump <- [1 <<< 128, (1 <<< 512) + 7, 1 <<< 2048],
        {c, t} <- [{f - jump, f + jump}, {f + jump, f - jump}] do
      ctx = Calendar.bootstrap_context(c, t)
      oracle = Ref.sauce(c, t)

      assert ctx.order_at_46_latch == oracle.order_at_drop_46
      assert ctx.bowls_after_post_stirs == oracle.bowls

      for id <- @ids do
        assert NextBowlPatchWrapper.next_bowl(ctx.order_at_46_latch, id) ==
                 Ref.next_bowl_in_drop_46_order(oracle, id)
      end
    end
  end

  test "46 giọt và 12 khuấy tiếp tục ghi đè bộ nhớ cũ đủ 58 lần" do
    f = Ref.foundation_day()
    ctx = Calendar.bootstrap_context(f, f)

    assert ctx.order_memory.writes == 58
    assert ctx.order_memory.last_source == {:stir, 12}
    assert ctx.order_at_46_latch == ctx.bowl_orders[46]
    assert ctx.order_at_46_latch == Ref.sauce(f, f).order_at_drop_46

    historical = Enum.map(@ids, &LegacyOrderMemory.next_bowl(ctx.order_memory, &1))
    corrected = Enum.map(@ids, &NextBowlPatchWrapper.next_bowl(ctx.order_at_46_latch, &1))
    refute historical == corrected
  end

  test "không thay các kết quả SAVE và mười hai lần khuấy cuối" do
    f = Ref.foundation_day()

    for {c, t} <- [{f, f}, {f - 101, f + 93}, {f + 93, f - 101}] do
      ctx = Calendar.bootstrap_context(c, t)
      oracle = Ref.sauce(c, t)

      assert ctx.bowls_after_post_stirs == oracle.bowls
      assert ctx.bowls_after_post_stirs ==
               Ref.post_stir12(ctx.bowls_after_drops)
      assert Enum.sort(Map.keys(ctx.bowls_after_post_stirs)) == @ids
    end
  end

  test "hai mươi lăm context đồng thời không chia sẻ kết quả chẩn đoán" do
    f = Ref.foundation_day()
    pairs = for k <- -12..12, do: {f + 19 * k, f - 23 * k}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        ordered: true, max_concurrency: 8, timeout: 15_000
      )
      |> Enum.map(fn {:ok, context} -> context end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, ctx} ->
      result = Ref.sauce(c, t)
      assert ctx.order_at_46_latch == result.order_at_drop_46

      for id <- @ids do
        report = NextBowlPatchWrapper.diagnose(ctx.order_at_46_latch, id)
        assert report.correct_next_id == Ref.next_bowl_in_drop_46_order(result, id)
        assert report.legacy_next_id == rem(id, 6) + 1
      end
    end)
  end

  test "đầu vào sai không gây thành công giả hoặc lộ giá trị rác" do
    for id <- [0, 7, -1, nil, 2.5, "3", :ba] do
      assert_raise ArgumentError, "mã bát phải thuộc 1..6", fn ->
        NextBowlPatchWrapper.diagnose(@fixture, id)
      end
    end

    for order <- [nil, :sai, [], [1, 2, 3], "123456"] do
      assert_raise ArgumentError, "thứ tự giọt 46 không hợp lệ", fn ->
        NextBowlPatchWrapper.next_bowl(order, 3)
      end
    end

    assert_raise ArgumentError, "thứ tự giọt 46 phải chứa sáu ID bát", fn ->
      NextBowlPatchWrapper.next_bowl([1, 1, 3, 4, 5, 6], 3)
    end
  end

  test "kiểm toán nguồn: đường chính trả kết quả chuẩn, legacy vẫn được gọi" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_fixed_name_successor.ex") |> File.read!()
    patch = Path.join(root, "next_bowl_patch_wrapper.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()
    latch = Path.join(root, "order_at_46_latch_patch.ex") |> File.read!()

    assert legacy =~ "rem(id, 6) + 1"
    assert patch =~ "LegacyFixedNameSuccessor.old_next_bowl_fixed_name(queried_id)"
    assert patch =~ "OrderAt46LatchPatch.next_bowl(order_at_46_latch, queried_id)"
    assert patch =~ "correct_next_id: correct_next_id"
    assert patch =~ "legacy_next_id: legacy_next_id"
    assert dispatcher =~ "NextBowlPatchWrapper.next_bowl(queried_bowl_id)"
    assert dispatcher =~ "NextBowlPatchWrapper.diagnose(queried_bowl_id)"
    assert latch =~ "LegacyOrderMemory.next_bowl("
    refute legacy =~ "NextBowlPatchWrapper"
    refute patch =~ "NormativeReference"
  end

  test "lịch đầy đủ chưa tích hợp, không bước sang phát hiện kế" do
    f = Ref.foundation_day()
    assert Calendar.next_bowl_spaghetti(f, f, 3) ==
             Ref.next_bowl_in_drop_46_order(Ref.sauce(f, f), 3)

    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end
end
