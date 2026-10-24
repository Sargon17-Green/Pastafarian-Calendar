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

## Tăng tốc bổ sung
Bảng đuôi thay việc gọi nhị thức đầy đủ tại từng ô bằng
hệ thức C(s+days-1, days-2) = C(s+days-2, days-2)
* (s+days-1)/(s+1), tính chính xác bằng số nguyên.
Hàm unrank_in_orders dùng chung một bảng đuôi cho
thứ tự di sản và thứ tự chuẩn; không bỏ gọi di sản thật.
Không thay đổi ngữ nghĩa, cần xác nhận Native CI và soak.

## Khép kiểm toán hồi quy và kích hoạt soak
Native 40125840583 trên 326d38df: 903 bài, 902 PASS,
1 lỗi tìm chuỗi gọi cũ; không timeout, khóa tên PASS.
Đổi kiểm toán sang unrank_in_orders, thêm 4 kiểm thử mới
so sánh cả hai thứ tự với phép mở hạng độc lập và oracle.
Đưa job soak vào workflow native hiện có, chỉ chạy trên
nhánh Elixir+tiếng-Việt, giới hạn 30 phút và giữ log kể cả lỗi.
