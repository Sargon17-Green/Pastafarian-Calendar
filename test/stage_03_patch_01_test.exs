defmodule PastafariCalendarElixirVietnamese.Stage03Patch01Test do
  use ExUnit.Case, async: true
  import Bitwise

  alias PastafariCalendarElixirVietnamese, as: Calendar
  alias PastafariCalendarElixirVietnamese.Monster.{LegacyRemainder, SavePatch}
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "lớp vá chỉ thay phần dư bằng không và giữ nguyên các phần dư khác" do
    m = Ref.m()

    Enum.each([-3, -2, -1, 0, 1, 2, 3], fn multiplier ->
      value = multiplier * m
      assert LegacyRemainder.old_remainder(value) == 0
      assert SavePatch.save_patch(value) == m
      assert Calendar.save_value_spaghetti(value) == m
    end)

    Enum.each([1, 2, 3, m - 2, m - 1], fn remainder ->
      assert SavePatch.save_patch(remainder) == LegacyRemainder.old_remainder(remainder)
    end)
  end

  test "kiểm tra tất cả vùng sát bội số M ở hai phía" do
    m = Ref.m()

    for multiplier <- -16..16, offset <- -3..3 do
      value = multiplier * m + offset
      actual = Calendar.save_value_spaghetti(value)

      assert actual == Ref.save(value)
      assert actual >= 1
      assert actual <= m
    end
  end

  test "phép SAVE có chu kỳ M và không phụ thuộc độ lớn số nguyên" do
    m = Ref.m()
    anchors = [-(1 <<< 1024), -(1 <<< 512), -m - 2, -1, 0, 1, m, m + 1, (1 <<< 512), (1 <<< 1024)]

    Enum.each(anchors, fn value ->
      expected = Ref.save(value)

      assert Calendar.save_value_spaghetti(value) == expected
      assert Calendar.save_value_spaghetti(value - m) == expected
      assert Calendar.save_value_spaghetti(value + m) == expected
      assert Calendar.save_value_spaghetti(value + m * (1 <<< 200)) == expected
    end)
  end

  test "mô-đun lỗi lịch sử vẫn sai và lớp vá thực sự gọi nó" do
    m = Ref.m()

    assert LegacyRemainder.old_remainder(m) == 0
    assert LegacyRemainder.old_remainder(-m) == 0
    assert SavePatch.save_patch(m) == m
    assert SavePatch.save_patch(-m) == m

    root = Path.expand("../lib/pastafari_calendar_elixir_vietnamese/monster", __DIR__)
    old_source = Path.join(root, "legacy_remainder.ex") |> File.read!()
    patch_source = Path.join(root, "save_patch.ex") |> File.read!()
    manager_source = Path.join(root, "save_manager.ex") |> File.read!()

    assert old_source =~ "Integer.mod(value, @m)"
    refute old_source =~ "SavePatch"
    assert patch_source =~ "LegacyRemainder.old_remainder(value)"
    assert manager_source =~ "SavePatch.save_patch(value)"
    refute patch_source =~ "NormativeReference"
  end

  test "nhiều yêu cầu song song trả cùng kết quả, không rò trạng thái" do
    m = Ref.m()
    inputs = Enum.map(-64..64, fn index -> index * m + rem(index * index + 7, 13) end)

    responses =
      inputs
      |> Task.async_stream(&Calendar.save_value_spaghetti/1, ordered: true, max_concurrency: 8, timeout: 15_000)
      |> Enum.map(fn {:ok, value} -> value end)

    assert responses == Enum.map(inputs, &Ref.save/1)
    assert responses == Enum.map(inputs, &Calendar.save_value_spaghetti/1)
  end

  test "đầu vào không phải số nguyên bị từ chối trước lớp vá" do
    Enum.each([nil, :khong_hop_le, "17", 1.5, %{}, [1]], fn value ->
      assert_raise ArgumentError, "giá trị phải là số nguyên chính xác", fn ->
        Calendar.save_value_spaghetti(value)
      end
    end)
  end

  test "hàm ngày lịch chưa được tích hợp không trở thành đường dự phòng" do
    assert function_exported?(PastafariCalendarElixirVietnamese, :calendar_date_spaghetti, 2)
  end
end
