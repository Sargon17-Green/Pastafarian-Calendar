defmodule PastafariCalendarElixirVietnamese.Stage55SharedWeavingTableTest do
  use ExUnit.Case, async: true

  alias PastafariCalendarElixirVietnamese.Monster.WeavingCombinatorics, as: Weave
  alias PastafariCalendarElixirVietnamese.TestOnly.NormativeReference, as: Ref

  test "bảng chung khớp hai phép mở hạng độc lập" do
    for lengths <- [[4], [4, 4], [4, 5], [5, 4], [4, 4, 4], [4, 5, 6]] do
      count = Weave.count(lengths)
      labels = Enum.to_list(1..length(lengths))
      orders = [Enum.reverse(labels), labels]

      for rank <- Enum.uniq([1, 2, div(count + 1, 2), count]) |> Enum.filter(&(&1 <= count)) do
        [historical, corrected] = Weave.unrank_in_orders(lengths, rank, orders)
        assert historical == Weave.unrank(lengths, rank, :descending)
        assert corrected == Weave.unrank(lengths, rank)
        assert corrected == Ref.unrank_weaving(lengths, rank)
      end
    end
  end

  test "hai kết quả phân biệt khi thứ tự mở hạng thay đổi" do
    orders = [[2, 1], [1, 2]]
    [old, new] = Weave.unrank_in_orders([4, 4], 1, orders)
    assert old != new
    assert Enum.count(old, &(&1 == 1)) == 4
    assert Enum.count(new, &(&1 == 2)) == 4
  end

  test "bảng dùng chung từ chối thứ tự và hạng sai" do
    for bad_orders <- [[], [[1]], [[2, 2]], [[1, 3]], :ascending] do
      assert_raise ArgumentError, fn ->
        Weave.unrank_in_orders([4, 4], 1, bad_orders)
      end
    end

    for bad_rank <- [0, -1, 21, nil, 1.5] do
      assert_raise ArgumentError, fn ->
        Weave.unrank_in_orders([4, 4], bad_rank, [[1, 2], [2, 1]])
      end
    end
  end

  test "mọi lần lặp dùng chung bảng nhưng không lưu trạng thái ngoài" do
    lengths = [4, 5, 4]
    order = [3, 2, 1]
    result = Weave.unrank_in_orders(lengths, 3, [order, [1, 2, 3]])
    assert result == Weave.unrank_in_orders(lengths, 3, [order, [1, 2, 3]])
  end
end
