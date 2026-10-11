defmodule PastafariCalendarElixirVietnamese.Stage08Discovery04Test do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{LegacyStoneMutation, StoneManager}
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "hàng đầu nguyên vẹn và giá trị lúa mì đầu tiên tình cờ đúng" do
    table = Calendar.stones_table_spaghetti()
    oracle = Ref.build_stones()

    assert map_size(table) == 46
    assert table[1] == {17, 29, 43, 71, 101}
    assert table[1] == oracle[1]
    assert elem(table[2], 0) == 378
    assert elem(table[2], 0) == elem(oracle[2], 0)
  end

  test "hàng thứ hai lộ thứ tự ghi nối tiếp thực sự" do
    initial = {17, 29, 43, 71, 101}
    row = LegacyStoneMutation.mutate_stones_wrong(initial, 2)

    assert row == {378, 1434, 3780, 9932, 25047}
    assert StoneManager.row_at(2) == row
    assert Calendar.stone_row_spaghetti(2) == row
    refute row == Ref.build_stones()[2]
  end

  test "bảng đá phát hiện được tính ở đường bootstrap sản xuất" do
    f = Ref.foundation_day()
    context = Calendar.bootstrap_context(f - 5, f + 8)

    assert context.stones_table == Calendar.stones_table_spaghetti()
    assert context.stones_table[2] == Calendar.stone_row_spaghetti(2)
    assert context.calculation_day_tag == Ref.day_count(f - 5)
    assert context.target_day_tag == Ref.day_count(f + 8)
    assert context.distance_count == Ref.work_counts(f - 5, f + 8).distance
  end

  test "46 hàng đều lấy trực tiếp hàng trước và nằm trong miền SAVE" do
    table = StoneManager.build_table()
    m = Ref.m()

    Enum.each(2..46, fn index ->
      expected = LegacyStoneMutation.mutate_stones_wrong(Map.fetch!(table, index - 1), index)
      assert Map.fetch!(table, index) == expected

      table
      |> Map.fetch!(index)
      |> Tuple.to_list()
      |> Enum.each(fn value -> assert is_integer(value) and value >= 1 and value <= m end)
    end)
  end

  test "ngữ cảnh có sở hữu bảng đá riêng và không thể làm hỏng kết quả lần gọi sau" do
    f = Ref.foundation_day()
    original = Calendar.bootstrap_context(f, f)
    other = Calendar.bootstrap_context(f + 1, f - 1)

    assert original.stones_table == other.stones_table
    changed = %{original | stones_table: Map.put(original.stones_table, 2, {0, 0, 0, 0, 0})}

    assert original.stones_table[2] != changed.stones_table[2]
    assert other.stones_table[2] == original.stones_table[2]
    assert Calendar.stone_row_spaghetti(2) == other.stones_table[2]
  end

  test "không đổi SAVE, nhãn ngày, khoảng cách và biên tích hợp" do
    f = Ref.foundation_day()
    m = Ref.m()

    for value <- [-m, 0, m, 2 * m, m + 1] do
      assert Calendar.save_value_spaghetti(value) == Ref.save(value)
    end

    for day <- [f - 3, f, f + 3] do
      assert Calendar.day_count_spaghetti(day) == Ref.day_count(day)
    end

    for {c, t} <- [{f, f}, {f - 3, f + 4}, {f + 12, f + 8}] do
      assert Calendar.distance_spaghetti(c, t) == Ref.work_counts(c, t).distance
    end

    assert_raise PastafariCalendarElixirVietnamese.Monster.StageNotIntegratedError, fn ->
      Calendar.calendar_date_spaghetti(f, f)
    end
  end

  test "lỗi chỉ số hàng đá không che lấp tính toán chuẩn xác" do
    for invalid <- [0, -1, 47, 99, nil, 1.0, "2", :hai, %{}, [2]] do
      assert_raise ArgumentError, "chỉ số hàng đá phải từ 1 đến 46", fn ->
        Calendar.stone_row_spaghetti(invalid)
      end
    end

    assert Calendar.stone_row_spaghetti(1) == {17, 29, 43, 71, 101}
    assert Calendar.stone_row_spaghetti(46) == Calendar.stones_table_spaghetti()[46]
  end

  test "mô-đun lịch sử viết nối tiếp và chưa có bản vá chụp hàng cũ" do
    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    old_source = Path.join(root, "legacy_stone_mutation.ex") |> File.read!()
    manager_source = Path.join(root, "stone_manager.ex") |> File.read!()
    dispatcher_source = Path.join(root, "dispatcher.ex") |> File.read!()

    assert old_source =~ "updated_w = put_elem(row, 0"
    assert old_source =~ "elem(updated_w, 0)"
    assert old_source =~ "elem(updated_b, 1)"
    assert old_source =~ "elem(updated_s, 2)"
    assert old_source =~ "elem(updated_m, 0)"
    assert old_source =~ "elem(updated_m, 3)"
    assert manager_source =~ "LegacyStoneMutation.mutate_stones_wrong(previous_row, index)"
    assert dispatcher_source =~ "StoneManager.build_table()"
    refute old_source =~ "NormativeReference"
    refute File.exists?(Path.join(root, "stone_patch.ex"))
  end

  test "hồi quy chuẩn tại đá thứ hai, vị trí lúa mạch: cố ý đỏ cho phát hiện 04" do
    assert elem(Calendar.stone_row_spaghetti(2), 1) == elem(Ref.build_stones()[2], 1)
  end

  test "hồi quy chuẩn tại đá thứ hai, vị trí muối: cố ý đỏ cho phát hiện 04" do
    assert elem(Calendar.stone_row_spaghetti(2), 2) == elem(Ref.build_stones()[2], 2)
  end

  test "hồi quy chuẩn tại đá thứ ba, vị trí lúa mì: cố ý đỏ cho phát hiện 04" do
    assert elem(Calendar.stone_row_spaghetti(3), 0) == elem(Ref.build_stones()[3], 0)
  end

  test "hồi quy chuẩn toàn bộ hàng cuối 46: cố ý đỏ cho phát hiện 04" do
    assert Calendar.stone_row_spaghetti(46) == Ref.build_stones()[46]
  end
end
