defmodule PastafariCalendarElixirVietnamese.Monster.LegacySingleDigitWidePick do
  @moduledoc """
  Phát hiện 14: coi một chữ số đáp án như đủ cho miền N lớn.

  Hàm lịch sử chỉ lấy phần tử đầu của vòng đáp án rồi dùng
  phép dư legacy. Khi n > M, giá trị x luôn nhỏ hơn n,
  vì vậy chỉ có thể trả hạng 1..M, không bao phủ miền N.
  Bản vá ở giai đoạn 29 phải giữ nguyên bằng chứng này,
  nhưng xây số nhiều chữ số từ cùng vòng đáp án.
  """

  import Bitwise

  alias PastafariCalendarElixirVietnamese.Monster.{
    AnswerStreamManager,
    LegacyBiasedPick
  }

  @m (1 <<< 127) - 1

  def choose_rank(%AnswerStreamManager{} = stream, n)
      when is_integer(n) and n > @m do
    x = AnswerStreamManager.answer_at(stream, 0)
    LegacyBiasedPick.biased_legacy_pick(x, n)
  end

  def choose_rank(_stream, _n) do
    raise ArgumentError, "miền chọn rộng phải lớn hơn M"
  end
end
