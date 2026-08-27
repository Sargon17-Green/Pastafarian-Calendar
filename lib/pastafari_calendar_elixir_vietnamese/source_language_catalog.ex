defmodule PastafariCalendarElixirVietnamese.SourceLanguageCatalog do
  @moduledoc """
  Danh mục ngôn ngữ nguồn tiếng Việt của cách triển khai này.

  Chỉ số chuẩn là nguồn sự thật về thứ tự. Chuỗi tiếng Việt chỉ dùng ở lớp trình bày.
  Tên có nghĩa được dịch theo nghĩa. Tên địa danh cổ giữ dạng Latin quốc tế quen dùng.
  Hai chuỗi âm vô nghĩa được cố định thành `Palgurash` và `Karshumab`; không suy diễn nghĩa cho chúng.
  Danh mục này được đóng băng từ giai đoạn 1 và không được đổi nếu không có thay đổi đặc tả rõ ràng.
  """

  @version "1.0.0"

  @cutlets [
    {1, "đồng thiếc"},
    {2, "cáo"},
    {3, "thận"},
    {4, "Lagash"},
    {5, "ý nghĩ"},
    {6, "bốn phần chín"},
    {7, "Palgurash"},
    {8, "cói"},
    {9, "chùm"},
    {10, "bọ cạp"},
    {11, "tro"},
    {12, "lúa mì"},
    {13, "sông"},
    {14, "tiếng cười"},
    {15, "Akkad"},
    {16, "sừng"},
    {17, "cái bình rỗng"}
  ]

  @months [
    {1, "đất sét"},
    {2, "lựu"},
    {3, "khuỷu tay"},
    {4, "ghen tị"},
    {5, "Eridu"},
    {6, "kem đánh răng"},
    {7, "ba phần năm"},
    {8, "Karshumab"},
    {9, "báo hoa mai"},
    {10, "thiếc"},
    {11, "sương mù"},
    {12, "nhũ hương"},
    {13, "trục quay sợi"},
    {14, "xương sườn"},
    {15, "quả carob"},
    {16, "Uruk"},
    {17, "sự xấu hổ"},
    {18, "lạc đà"},
    {19, "đồng"},
    {20, "giếng"},
    {21, "lòng đỏ trứng"},
    {22, "ngôi sao"},
    {23, "mật ong"},
    {24, "lá lách"},
    {25, "đá vôi"},
    {26, "niềm vui"},
    {27, "quả sung"},
    {28, "Nineveh"},
    {29, "ếch"},
    {30, "hắc ín"},
    {31, "nến"},
    {32, "cánh cửa đóng"},
    {33, "mè"},
    {34, "gáy"},
    {35, "bạc"},
    {36, "hoa loa kèn"},
    {37, "bão"},
    {38, "lừa"},
    {39, "bột"},
    {40, "sự hối tiếc"},
    {41, "Babylon"},
    {42, "lưỡi"},
    {43, "lanh"},
    {44, "muối"},
    {45, "lê"},
    {46, "cung"},
    {47, "cát"}
  ]

  def version, do: @version
  def cutlets, do: @cutlets
  def months, do: @months

  def cutlet_name(index), do: fetch_name(@cutlets, index)
  def month_name(index), do: fetch_name(@months, index)

  defp fetch_name(entries, index) do
    case List.keyfind(entries, index, 0) do
      {^index, name} -> name
      nil -> raise ArgumentError, "chỉ số chuẩn không hợp lệ"
    end
  end
end
