defmodule PastafariCalendarElixirVietnamese.Monster.WideDetourPatch do
  @moduledoc """
  Bản vá 14: chọn hạng rộng từ nhiều chữ số trên cùng vòng đáp án.

  Với n > M, dùng số chữ số k nhỏ nhất sao cho M^k >= n,
  theo thứ tự little-endian: chữ số tại vị trí j có trọng số M^j.
  Giữ cùng hạt và chiều của AnswerStreamManager đã khởi tạo.

  Khi wide vượt giới hạn chia hết, đi +/-1 trên vòng wide.
  Tính trực tiếp điểm chấp nhận đầu tiên và số bước tương đương,
  tránh hàng tỷ tỷ vòng lặp ở các biên số nguyên lớn. Không
  khởi tạo vòng mới và không đọc thêm chữ số sau khi từ chối.
  LegacySingleDigitWidePick vẫn được giữ riêng để kiểm toán.
  """

  import Bitwise

  alias PastafariCalendarElixirVietnamese.Monster.AnswerStreamManager

  @m (1 <<< 127) - 1

  def choose_rank_wide(stream, n), do: diagnose(stream, n).rank

  def diagnose(%AnswerStreamManager{} = stream, n)
      when is_integer(n) and n > @m do
    {digits, space} = smallest_power(n, 1, @m)

    {wide0, _weight} =
      Enum.reduce(0..(digits - 1), {1, 1}, fn j, {wide, weight} ->
        digit = AnswerStreamManager.answer_at(stream, j) - 1
        {wide + digit * weight, weight * @m}
      end)

    limit = div(space, n) * n
    {accepted, rejected} = detour(wide0, stream.direction_step, space, limit)

    %{
      rank: Integer.mod(accepted - 1, n) + 1,
      digit_count: digits,
      space: space,
      initial_wide: wide0,
      rejection_limit: limit,
      accepted_wide: accepted,
      rejected_count: rejected
    }
  end

  def diagnose(_stream, _n) do
    raise ArgumentError, "miền chọn rộng phải lớn hơn M"
  end

  defp smallest_power(n, k, space) when space >= n, do: {k, space}

  defp smallest_power(n, k, space) do
    smallest_power(n, k + 1, space * @m)
  end

  defp detour(wide, _step, _space, limit) when wide <= limit, do: {wide, 0}

  # Tương đương trừ từng bước đến khi gặp limit trên cùng vòng wide.
  defp detour(wide, -1, _space, limit), do: {limit, wide - limit}

  # Tương đương cộng từng bước, qua space rồi gặp 1 trên vòng wide.
  defp detour(wide, 1, space, _limit), do: {1, space - wide + 1}
end
