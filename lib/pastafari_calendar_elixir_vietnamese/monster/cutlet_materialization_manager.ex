defmodule PastafariCalendarElixirVietnamese.Monster.CutletMaterializationManager do
  @moduledoc """
  PATCH23 ghép các phần và chỉ số tên, gọi di sản
  sai lệch ngày cổng mở để lưu chứng cứ, rồi sửa ngày đầu
  theo khoảng chuẩn (mở,đóng] mà không thay dữ liệu khác.
  Chưa tích hợp tháng hay lịch hoàn chỉnh.
  """

  alias PastafariCalendarElixirVietnamese.Monster.{
    CutletNameIndexManager, CutletFirstDayPatch
  }

  def cutlets(c, t), do: diagnose(c, t).cutlets

  def diagnose(c, t) when is_integer(c) and is_integer(t) do
    parent = CutletNameIndexManager.diagnose(c, t)
    patch = CutletFirstDayPatch.diagnose(
      parent.year, parent.cutlet_partition, parent.name_indices, parent.gate_state
    )
    cutlets = patch.corrected_cutlets

    %{year: parent.year, gate_state: parent.gate_state,
      calculation_day: c, target_day: t,
      cutlet_count: parent.cutlet_count,
      cutlet_partition: parent.cutlet_partition,
      name_indices: parent.name_indices,
      cutlets: cutlets, historical_cutlets: patch.historical_cutlets,
      first_day_was_corrected: patch.changed, legacy_open_day_included: false}
  end

  def diagnose(_, _),
    do: raise(ArgumentError, "ngày tính và ngày đích phải là số nguyên")
end
