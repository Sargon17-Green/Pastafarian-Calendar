# Kiểm thử chịu tải độc lập — Stage55

Bộ kiểm thử tại qa/elixir_vietnamese_soak.exs chạy tách khỏi
CI phát triển, với giới hạn 30 phút ở mức công việc và
240 giây mỗi bài. Dữ liệu đầu vào gồm 47 tháng dài tổng
cộng 5.778 ngày, hai hạng biên, các véc-tơ ngắn có oracle
và nhiều hướng chuyển ngày. Nhật ký thời gian được giữ
thành artifact ngay cả khi thất bại.

Đây chỉ là thử nghiệm soak có giới hạn, không phải chứng
minh tương đương toàn miền hay kết quả của các ngôn ngữ khác.
Không sửa main hoặc bộ tham chiếu.

## Kết quả đã kiểm chứng

Ở commit 58401ac3e85e351894ff514d2a75e685e4d61271,
Native soak job 120993967873 trong run 40134812877 thành
công: 4/4 bài và 0 FAIL, thời gian 132,8 giây. Trong
trường hợp 47 tháng/5.778 ngày, đếm trong khoảng 380 ms,
hạng đầu khoảng 418 ms, hạng cuối khoảng 24,0 giây.
Phần test đơn vị khác thất bại với 3 lỗi liên quan cấu
trúc kiểm thử và tài nguyên đồng thời, không được che giấu.
