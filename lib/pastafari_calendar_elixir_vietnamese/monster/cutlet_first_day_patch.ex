defmodule PastafariCalendarElixirVietnamese.Monster.CutletFirstDayPatch do
  @moduledoc """
  PATCH23: luôn gọi thật di sản bao gồm ngày cổng mở,
  giữ toàn bộ vật liệu cũ trong chẩn đoán, rồi sửa
  first_day thành gate(open)+1. Không đổi tên, chỉ số
  cổng, last_day, phân hoạch hay bất kỳ bảng gate nào.
  """
  alias PastafariCalendarElixirVietnamese.Monster.LegacyInclusiveCutletFirstDay

  def materialize(year, partition, names, state),
    do: diagnose(year, partition, names, state).corrected_cutlets

  def diagnose(year, partition, names, state) do
    historical_cutlets =
      LegacyInclusiveCutletFirstDay.materialize(year, partition, names, state)

    corrected_cutlets =
      Enum.map(historical_cutlets, fn piece ->
        %{piece | first_day: Map.fetch!(state.gate, piece.open_gate_index) + 1}
      end)

    %{historical_cutlets: historical_cutlets,
      corrected_cutlets: corrected_cutlets,
      changed: historical_cutlets != corrected_cutlets,
      cutlet_count: length(historical_cutlets)}
  end
end
