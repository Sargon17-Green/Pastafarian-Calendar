defmodule PastafariCalendarElixirVietnamese.Monster.ShortRejectionPatch do
  @moduledoc """
  Bản vá 13: loại bỏ phần đuôi gây lệch xác suất trước khi gọi legacy.

  Không tạo vòng mới, không đổi hạt hoặc chiều. Mỗi lần bị
  từ chối chỉ tăng chỉ số k trên cùng AnswerStreamManager.
  Chỉ khi x trong miền chia hết, mới được gọi thật
  LegacyBiasedPick.biased_legacy_pick(x, n).

  Báo cáo chẩn đoán chứa vị trí đã nhận, số phần tử bị
  từ chối và hạng thực tế; không giữ trạng thái dùng chung.
  """

  import Bitwise

  @m (1 <<< 127) - 1

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    LegacyBiasedPick
  }

  def choose_rank_short(stream, n), do: diagnose(stream, n).rank

  def diagnose(%AnswerStreamManager{} = stream, n)
      when is_integer(n) and n >= 1 and n <= @m do
    limit = div(AnswerStreamManager.modulus(), n) * n
    reject_until_accepted(stream, n, limit, 0)
  end

  def diagnose(_stream, _n) do
    raise ArgumentError, "miền chọn ngắn phải thuộc 1..M"
  end

  defp reject_until_accepted(stream, n, limit, k) do
    x = AnswerStreamManager.answer_at(stream, k)

    if x <= limit do
      # Lời gọi legacy chỉ có mặt trong nhánh đã qua rejection.
      rank = LegacyBiasedPick.biased_legacy_pick(x, n)

      %{
        rank: rank,
        accepted_value: x,
        accepted_index: k,
        rejected_count: k,
        rejection_limit: limit
      }
    else
      reject_until_accepted(stream, n, limit, k + 1)
    end
  end
end
