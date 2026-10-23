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
