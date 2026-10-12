defmodule PastafariCalendarElixirVietnamese.Stage12Discovery06Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar

  alias PastafariCalendarElixirVietnamese.Monster.{
    HiddenDropManager,
    LegacyPrior,
    VisibleDropCalculator,
    VisibleDropManager
  }

  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  defp oracle(c, t) do
    counts = Ref.work_counts(c, t)
    stones = Ref.build_stones()
    hidden = Ref.build_hidden_drops(counts, stones)
    Ref.build_visible_drops(counts, stones, hidden)
  end

  test "đường legacy chỉ lấy giọt nhìn thấy và dùng số không cho ô vắng" do
    store = %{1 => 19, 2 => 23, 3 => 31}

    assert LegacyPrior.legacy_prior(store, 1, 1) == 0
    assert LegacyPrior.legacy_prior(store, 1, 3) == 0
    assert LegacyPrior.legacy_prior(store, 1, 7) == 0
    assert LegacyPrior.legacy_prior(store, 2, 1) == 19
    assert LegacyPrior.legacy_prior(store, 3, 1) == 23
    assert LegacyPrior.legacy_prior(store, 4, 3) == 19
    assert LegacyPrior.legacy_prior(store, 8, 7) == 19
    assert LegacyPrior.legacy_prior(store, 8, 1) == 0
  end

  test "ba vị trí ở đầu chuỗi thiếu đúng các giọt ẩn tương ứng" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f - 4, f + 9)
    visible = context.visible_drops

    for index <- 1..7 do
      for back <- [1, 3, 7] do
        slot = index - back
        actual = LegacyPrior.legacy_prior(Map.filter(visible, fn {number, _value} -> number < index end), index, back)

        if slot <= 0 do
          hidden_number = 1 - slot
          correct_hidden = HiddenDropManager.read(context.hidden_drops_storage, hidden_number)
          assert actual == 0
          assert correct_hidden >= 1 and correct_hidden <= Ref.m()
        else
          assert actual == Map.fetch!(visible, slot)
        end
      end
    end
  end

  test "46 giọt được tạo trong đường bootstrap bằng cùng mô-đun sản xuất" do
    f = Ref.foundation_day()
    c = f - 22
    t = f + 31
    context = Calendar.bootstrap_context(c, t)

    calculated =
      VisibleDropCalculator.calculate(
        c,
        t,
        Ref.day_count(c),
        Ref.day_count(t),
        Ref.work_counts(c, t).distance,
        Ref.build_stones(),
        context.hidden_drops_storage
      )

    assert context.visible_drops == calculated
    assert Calendar.visible_drops_spaghetti(c, t) == calculated
    assert map_size(calculated) == 46
    assert Enum.sort(Map.keys(calculated)) == Enum.to_list(1..46)
    assert Enum.all?(Map.values(calculated), fn x -> x >= 1 and x <= Ref.m() end)
  end

  test "đường truy cập một giọt đọc đúng kho sản xuất đang giữ lỗi lịch sử" do
    f = Ref.foundation_day()
    visible = Calendar.visible_drops_spaghetti(f + 3, f - 7)

    for index <- [1, 2, 3, 7, 8, 23, 46] do
      assert VisibleDropManager.read(visible, index) == Map.fetch!(visible, index)
      assert Calendar.visible_drop_spaghetti(f + 3, f - 7, index) == visible[index]
    end
  end

  test "tất cả công thức nghiền hoạt động với đầu vào lịch sử thiếu giọt ẩn" do
    f = Ref.foundation_day()
    c = f
    t = f
    action = Ref.day_count(c)
    target = Ref.day_count(t)
    distance = Ref.work_counts(c, t).distance
    stones = Ref.build_stones()
    {w, b, s, m, r} = stones[1]

    x0 = Ref.save(w * action + b * target + s * distance +
                  m * (action + target) + r * 2 + 1)

    grinds = [
      {3, 5, 7, 11, 1},
      {5, 7, 11, 13, 2},
      {7, 11, 13, 17, 3},
      {11, 13, 17, 19, 4},
      {13, 17, 19, 23, 5},
      {17, 19, 23, 29, 1},
      {19, 23, 29, 31, 2},
      {23, 29, 31, 37, 3},
      {29, 31, 37, 41, 4},
      {31, 37, 41, 43, 5},
      {37, 41, 43, 47, 1}
    ]

    computed =
      Enum.reduce(grinds, x0, fn {a, _b, _c, _d, kind}, prior_x ->
        Ref.save(prior_x * prior_x + a * prior_x + elem(stones[1], kind - 1))
      end)

    refute Calendar.visible_drop_spaghetti(c, t, 1) == computed
    assert Calendar.visible_drop_spaghetti(c, t, 1) == oracle(c, t)[1]
    refute computed == oracle(c, t)[1]
  end

  test "các giọt tiếp theo đọc lại giá trị nhìn thấy thay vì mất lịch sử" do
    f = Ref.foundation_day()
    visible = Calendar.visible_drops_spaghetti(f - 4, f + 9)

    for index <- 8..46 do
      for back <- [1, 3, 7] do
        assert LegacyPrior.legacy_prior(visible, index, back) ==
                 Map.fetch!(visible, index - back)
      end
    end
  end

  test "giữ riêng bảy giọt ẩn và kết quả các bản vá trước" do
    f = Ref.foundation_day()
    c = f - 8
    t = f + 5
    context = Calendar.bootstrap_context(c, t)
    counts = Ref.work_counts(c, t)
    hidden = Ref.build_hidden_drops(counts, Ref.build_stones())

    assert context.stones_table == Ref.build_stones()
    assert context.calculation_day_tag == counts.action
    assert context.target_day_tag == counts.target
    assert context.distance_count == counts.distance
    assert context.hidden_drops_storage ==
             List.to_tuple(Enum.map(7..1//-1, &Map.fetch!(hidden, &1)))

    for k <- 1..7 do
      assert Calendar.hidden_drop_spaghetti(c, t, k) == hidden[k]
    end
  end

  test "không dùng trạng thái chung khi tính nhiều cặp ngày đồng thời" do
    f = Ref.foundation_day()
    pairs = for delta <- -12..12, do: {f + delta * 7, f - delta * 13}

    contexts =
      Task.async_stream(pairs, fn {c, t} -> Calendar.bootstrap_context(c, t) end,
        ordered: true, max_concurrency: 8, timeout: 15_000
      )
      |> Enum.map(fn {:ok, context} -> context end)

    Enum.zip(pairs, contexts)
    |> Enum.each(fn {{c, t}, context} ->
      assert map_size(context.visible_drops) == 46
      assert context.visible_drops ==
               Calendar.visible_drops_spaghetti(c, t)
    end)
  end

  test "ngày nguyên rất lớn vẫn tạo 46 giọt trong miền SAVE" do
    f = Ref.foundation_day()
    big = 1 <<< 512

    for {c, t} <- [{f + big, f - big}, {f - big, f + big}] do
      context = Calendar.bootstrap_context(c, t)
      assert map_size(context.visible_drops) == 46
      assert Enum.all?(Map.values(context.visible_drops), fn value ->
        is_integer(value) and value >= 1 and value <= Ref.m()
      end)
      assert context.hidden_drops_storage ==
               Calendar.hidden_drops_storage_spaghetti(c, t)
    end
  end

  test "chỉ số sai và ngày không nguyên bị từ chối trước phép tính" do
    f = Ref.foundation_day()
    visible = Calendar.visible_drops_spaghetti(f, f)

    for index <- [0, -1, 47, nil, :khong_hop_le, 2.5, "2"] do
      assert_raise ArgumentError, "chỉ số giọt nhìn thấy phải từ 1 đến 46", fn ->
        VisibleDropManager.read(visible, index)
      end

      assert_raise ArgumentError, "chỉ số giọt nhìn thấy phải từ 1 đến 46", fn ->
        Calendar.visible_drop_spaghetti(f, f, index)
      end
    end

    for bad <- [nil, 1.0, "4", :sai, %{}] do
      assert_raise ArgumentError, "ngày phải là số nguyên chính xác", fn ->
        Calendar.visible_drops_spaghetti(bad, f)
      end
    end

    assert_raise ArgumentError,
                 "chỉ được đọc giọt trước với độ lùi 1, 3 hoặc 7",
                 fn -> LegacyPrior.legacy_prior(%{}, 1, 2) end
  end

  test "mã nguồn giữ lookup cũ nhưng định tuyến qua bản vá 06" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    legacy = Path.join(root, "legacy_prior.ex") |> File.read!()
    calculator = Path.join(root, "visible_drop_calculator.ex") |> File.read!()
    patch = Path.join(root, "prior_patch.ex") |> File.read!()
    dispatcher = Path.join(root, "dispatcher.ex") |> File.read!()

    assert legacy =~ "slot = index - back"
    assert legacy =~ "Map.get(visible_store, slot, 0)"
    refute legacy =~ "HiddenDropManager"
    assert calculator =~ "PriorPatch.read(visible_store, hidden_storage, index, 1)"
    assert calculator =~ "PriorPatch.read(visible_store, hidden_storage, index, 3)"
    assert calculator =~ "PriorPatch.read(visible_store, hidden_storage, index, 7)"
    assert dispatcher =~ "VisibleDropManager.build("
    assert dispatcher =~ "visible_drops: visible_drops"
    refute calculator =~ "NormativeReference"
    assert File.exists?(Path.join(root, "prior_patch.ex"))
    assert patch =~ "LegacyPrior.legacy_prior(visible_store, index, back)"
    assert patch =~ "HiddenDropManager.read(hidden_storage, hidden_number)"
    assert patch =~ "hidden_number = 1 - slot"
  end

  test "hồi quy chuẩn giọt nhìn thấy thứ nhất: cố ý đỏ cho phát hiện 06" do
    f = Ref.foundation_day()
    assert Calendar.visible_drop_spaghetti(f, f, 1) == oracle(f, f)[1]
  end

  test "hồi quy chuẩn giọt nhìn thấy thứ hai: cố ý đỏ cho phát hiện 06" do
    f = Ref.foundation_day()
    assert Calendar.visible_drop_spaghetti(f - 1, f + 5, 2) ==
             oracle(f - 1, f + 5)[2]
  end

  test "hồi quy chuẩn giọt nhìn thấy thứ bảy: cố ý đỏ cho phát hiện 06" do
    f = Ref.foundation_day()
    assert Calendar.visible_drop_spaghetti(f + 3, f - 8, 7) ==
             oracle(f + 3, f - 8)[7]
  end

  test "hồi quy chuẩn giọt nhìn thấy cuối cùng: cố ý đỏ cho phát hiện 06" do
    f = Ref.foundation_day()
    assert Calendar.visible_drop_spaghetti(f - 12, f + 40, 46) ==
             oracle(f - 12, f + 40)[46]
  end
end
