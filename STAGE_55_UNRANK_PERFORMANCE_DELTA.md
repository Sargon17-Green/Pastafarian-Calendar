# Tối ưu Stage55: chuyển số cách giữa các bước mở hạng

Nguyên nhân timeout ở commit 9fee0ceb207562155346b0d809b5dff1c2b59374:
unrank_loop tính lại tích nhị thức cho các tháng đang mở
ở mỗi ngày; suffix_ratios đọc từng vị trí của danh sách
tiền tố nhiều lần. Ba kiểm thử lịch đầy đủ vượt 60 giây.

Bản sửa mang biến base là số cách các tháng đã mở từ
bước trước, cập nhật bằng tỉ lệ tổ hợp chính xác cho
ngày giữa tháng, đóng tháng hoặc mở tháng tiếp theo.
Các tỉ số hậu tố được tính bằng một lượt đảo danh sách,
thay vì đọc Enum.at ở mỗi chỉ số. Công thức đóng tháng
kiểm tra độc lập với 11.200 bộ trạng thái sinh ngẫu nhiên.

Không đổi quy tắc đan, hạng một-based, di sản thứ tự giảm,
bộ tham chiếu hoặc main. Chờ kiểm thử native và soak mới;
không đánh dấu Stage55 GREEN trước khi xác nhận.
