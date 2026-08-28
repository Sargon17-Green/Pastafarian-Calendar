# Cách triển khai lịch Pastafari bằng Elixir

Đây là một kho mới được dựng từ số không cho đúng một dòng triển khai: Elixir là ngôn ngữ lập trình duy nhất và tiếng Việt là ngôn ngữ nguồn duy nhất cho mọi văn bản do dòng triển khai tạo ra. Kho này không dựa vào mã, kiểm thử, dữ liệu kiểm thử, kết quả, bảng sinh ra hay giá trị băm của bất kỳ cách triển khai nào khác.

Giai đoạn 1 chỉ dựng nền móng. Mã sản xuất có ngữ cảnh riêng cho từng lần gọi, bộ phân phối cơ sở, kiểm tra đầu vào, biên lỗi và trạng thái quan sát phi ngữ nghĩa. Nó chưa chứa bất kỳ khuyết tật lịch sử hay bản vá nào của các giai đoạn sau và cố ý chưa trả ngày lịch.

Bộ tham chiếu chuẩn sạch nằm dưới `test/support/` và chỉ phục vụ kiểm thử. Mã sản xuất không nhập, không gọi và không dùng nó làm đường dự phòng.

Elixir dùng số nguyên có độ chính xác tùy ý, vì vậy phép tính chuẩn không cần thư viện số lớn hay cầu nối sang ngôn ngữ khác.

`SourceLanguageCatalog` phiên bản `1.0.0` đã được đóng băng ở giai đoạn 1. Mọi thứ tự chuẩn dùng `canonicalIndex`; chuỗi tiếng Việt chỉ được giải ra ở lớp kết quả hoặc trình bày.

## Xác minh giai đoạn 1

Quy trình GitHub Actions của dòng triển khai đã chạy `mix test` bằng Elixir 1.18.4 trên Erlang/OTP 27 và hoàn tất thành công với 16 kiểm thử, 0 lỗi.

Lệnh kiểm thử tại gốc kho vẫn là:

```text
mix test
```

Sau khi áp dụng gói đóng giai đoạn 1, cần để quy trình CI chạy lại. Chỉ khi lần chạy mới vẫn xanh mới bắt đầu giai đoạn 2, tức DISCOVERY 01.
