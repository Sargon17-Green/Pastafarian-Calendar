# Lịch sử phát triển spaghetti

## Giai đoạn 1 — Khởi tạo

Dòng triển khai được bắt đầu từ số không bằng Elixir. Tiếng Việt được cố định làm ngôn ngữ nguồn. `SourceLanguageCatalog` phiên bản `1.0.0` được đóng băng với 17 tên miếng và 47 tên tháng, mỗi tên có chỉ số chuẩn cố định.

Ở bước này chưa có giả định lịch sử sai nào được đưa vào, vì khuyết tật đầu tiên chỉ được phép xuất hiện ở giai đoạn khám phá kế tiếp. Kiến trúc quái vật mới chỉ có vỏ trung tính: ngữ cảnh riêng cho mỗi lần gọi, phân phối cơ sở, kiểm tra, biên lỗi và quan sát phi ngữ nghĩa.

Bộ tham chiếu sạch của phụ lục A được dựng riêng dưới kiểm thử. Nó không được nhập vào đường sản xuất.

Việc xác minh độc lập của giai đoạn 1 đã được thực hiện bằng GitHub Actions với Elixir 1.18.4 và Erlang/OTP 27. `mix test` hoàn tất với 16 kiểm thử và 0 lỗi. Lần đóng giai đoạn 1 chỉ sửa trạng thái/tài liệu, Việt hóa tệp giấy phép còn sót lại và loại bỏ hai cảnh báo biến không dùng trong bộ tham chiếu chỉ dành cho kiểm thử; không thêm khuyết tật legacy, bản vá tương lai hay hành vi sản xuất mới.
