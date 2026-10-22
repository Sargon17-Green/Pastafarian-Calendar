defmodule PastafariCalendarElixirVietnamese.Monster.LegacyInclusiveCutletFirstDay do
  @moduledoc """
  Di sản lỗi DISCOVERY23: coi ngày cổng mở là ngày đầu
  cốt-lết, thay vì ngày liền sau cổng mở. Các chỉ số cổng,
  tên và ngày cuối không thay đổi. PATCH23 phải gọi thật
  chức năng sai lệch lịch sử này.
  """

  alias PastafariCalendarElixirVietnamese.Monster.Cutlet

  def materialize(year, partition, names, state)
      when is_list(partition) and is_list(names) and
           length(partition) == length(names) do
    {cutlets, _cursor} =
      Enum.zip(partition, names)
      |> Enum.map_reduce(year.open_gate_index, fn {part, name}, cursor ->
        close = cursor + part
        cutlet = %Cutlet{
          name_index: name,
          open_gate_index: cursor,
          close_gate_index: close,
          first_day: Map.fetch!(state.gate, cursor),
          last_day: Map.fetch!(state.gate, close)
        }
        {cutlet, close}
      end)

    cutlets
  end

  def materialize(_, _, _, _),
    do: raise(ArgumentError, "năm, phân hoạch hoặc tên không hợp lệ")
end
