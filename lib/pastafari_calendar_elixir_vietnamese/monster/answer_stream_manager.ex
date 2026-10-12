defmodule PastafariCalendarElixirVietnamese.Monster.AnswerStreamManager do
  @moduledoc """
  Xây dựng vòng đáp án từ sáu bát đúng và ID kế cận đã vá.

  Công thức first, hướng chạy và từng phần tử vòng đều chuẩn.
  Bản vá 13 xử lý hạng ngắn n<=M. Bản vá 14 ghép
  nhiều chữ số trên cùng answer ring để xử lý n>M,
  và loại bỏ phần dư của không gian wide đúng chuẩn.
  """

  import Bitwise

  alias PastafariCalendarElixirVietnamese.Monster.{
    SaveManager,
    ShortRejectionPatch,
    WideDetourPatch
  }

  @m (1 <<< 127) - 1

  defstruct [:first, :direction_step]

  def modulus, do: @m

  def build(bowls, queried_id, next_id, seal)
      when is_map(bowls) and is_integer(queried_id) and queried_id in 1..6 and
             is_integer(next_id) and next_id in 1..6 and
             is_integer(seal) and seal >= 1 do
    queried_value = Map.fetch!(bowls, queried_id)
    following_value = Map.fetch!(bowls, next_id)
    sixth_value = Map.fetch!(bowls, 6)

    first =
      SaveManager.calculate(
        (queried_value + seal + 181) * (queried_value + seal + 181) +
          179 * following_value + seal
      )

    direction_number =
      SaveManager.calculate(
        (first + seal + 1 + 193) * (first + seal + 1 + 193) +
          193 * first + 197 * sixth_value
      )

    direction_step = if rem(direction_number, 2) == 1, do: 1, else: -1
    %__MODULE__{first: first, direction_step: direction_step}
  end

  def build(_bowls, _queried_id, _next_id, _seal) do
    raise ArgumentError, "đầu vào vòng đáp án không hợp lệ"
  end

  def answer_at(%__MODULE__{first: first, direction_step: step}, k)
      when is_integer(k) and k >= 0 and is_integer(first) and
             first in 1..@m and step in [-1, 1] do
    1 + Integer.mod(first - 1 + step * k, @m)
  end

  def answer_at(_stream, _k) do
    raise ArgumentError, "vị trí vòng đáp án không hợp lệ"
  end

  def choose_rank_short_biased(%__MODULE__{} = stream, n)
      when is_integer(n) and n >= 1 and n <= @m do
    ShortRejectionPatch.choose_rank_short(stream, n)
  end

  def choose_rank_short_biased(_stream, _n) do
    raise ArgumentError, "miền chọn ngắn phải thuộc 1..M"
  end

  def choose_rank(%__MODULE__{} = stream, n)
      when is_integer(n) and n >= 1 and n <= @m do
    ShortRejectionPatch.choose_rank_short(stream, n)
  end

  def choose_rank(%__MODULE__{} = stream, n)
      when is_integer(n) and n > @m do
    WideDetourPatch.choose_rank_wide(stream, n)
  end

  def choose_rank(_stream, _n) do
    raise ArgumentError, "miền chọn phải là số nguyên dương"
  end
end
