# Cách triển khai lịch Pastafari bằng Elixir

Đây là một kho mới được dựng từ số không cho đúng một dòng triển khai: Elixir là ngôn ngữ lập trình duy nhất và tiếng Việt là ngôn ngữ nguồn duy nhất cho mọi văn bản do dòng triển khai tạo ra. Kho này không dựa trên cây mã có trước và không cần ghép vào một kho khác.

Giai đoạn 1 chỉ dựng nền móng. Mã sản xuất có ngữ cảnh riêng cho từng lần gọi, bộ phân phối cơ sở, kiểm tra đầu vào, vỏ lỗi và trạng thái quan sát phi ngữ nghĩa. Nó chưa chứa bất kỳ khuyết tật lịch sử hay bản vá nào của các giai đoạn sau và cố ý chưa trả ngày lịch.

Bộ tham chiếu chuẩn sạch nằm dưới `test/support/` và chỉ phục vụ kiểm thử. Mã sản xuất không nhập, không gọi và không dùng nó làm đường dự phòng.

Elixir dùng số nguyên có độ chính xác tùy ý, vì vậy phép tính chuẩn không cần thư viện số lớn hay cầu nối sang ngôn ngữ khác.

## Chạy kiểm thử

Từ thư mục gốc của kho:

```text
mix test
```

Kết quả mong đợi là toàn bộ kiểm thử của giai đoạn 1 thành công. Trong môi trường tạo gói hiện tại không có `elixir` hoặc `mix`, nên lệnh này chưa thể được thực thi tại chỗ.
