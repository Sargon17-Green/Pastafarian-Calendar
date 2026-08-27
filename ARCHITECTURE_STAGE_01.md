# Kiến trúc ở giai đoạn 1

Mã sản xuất chỉ có các lớp trung tính được phép ở bước khởi tạo:

- `Monster.Context`: giá trị bất biến riêng cho từng lần gọi.
- `Monster.Dispatcher`: tuyến cơ sở đi qua kiểm tra đầu vào.
- `Monster.Validator`: kiểm tra số nguyên chính xác và các bất biến cơ sở.
- `Monster.Metrics`: vỏ quan sát phi ngữ nghĩa.
- `StageNotIntegratedError`: biên lỗi rõ ràng để tránh trả kết quả một phần.

Không có trạng thái ngữ nghĩa toàn cục có thể thay đổi. Không có bộ nhớ đệm ngữ nghĩa. Không có cơ chế thử lại, phục hồi, đường tương thích, bộ chuyển tiếp di sản hay lớp bọc bản vá dành cho các giai đoạn tương lai.

Bộ tham chiếu chuẩn sạch được giữ hoàn toàn dưới cây kiểm thử. Nó triển khai phụ lục A bằng số nguyên Elixir chính xác và không được mã sản xuất tham chiếu.
