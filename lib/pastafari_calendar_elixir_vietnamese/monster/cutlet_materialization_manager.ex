defmodule PastafariCalendarElixirVietnamese.Monster.CutletMaterializationManager do
  @moduledoc """
  DISCOVERY23 ghép phân hoạch và chỉ số tên thành các
  cốt-lết cụ thể. Các tầng số lượng, thứ tự tên, biên cổng
  và ngày cuối vẫn chuẩn; di sản lấy ngày cổng mở làm
  ngày đầu, không cộng một ngày như khoảng (mở,đóng].
  Chưa tích hợp tháng hay lịch hoàn chỉnh.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    CutletNameIndexManager, LegacyInclusiveCutletFirstDay
  }

  def cutlets(c, t), do: diagnose(c, t).cutlets

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = CutletNameIndexManager.diagnose(c, t)
    cutlets = LegacyInclusiveCutletFirstDay.materialize(
      parent.year, parent.cutlet_partition, parent.name_indices, parent.gate_state
    )

    %{year: parent.year, gate_state: parent.gate_state,
      calculation_day: c, target_day: t,
      cutlet_count: parent.cutlet_count,
      cutlet_partition: parent.cutlet_partition,
      name_indices: parent.name_indices,
      cutlets: cutlets, legacy_open_day_included: true}
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
