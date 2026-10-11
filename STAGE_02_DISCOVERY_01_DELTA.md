# Gói thay đổi riêng của giai đoạn 2 — Phát hiện 01

## Giới hạn

- Chỉ nhánh `Elixir+tiếng-Việt`; tuyệt đối không chạm vào `main`.
- Chỉ sai lệch SAVE so với phép dư thông thường; không đưa vào bản vá số 01.
- Không lấy mã, kiểm thử, giá trị mẫu hoặc dữ liệu băm từ cách triển khai khác.
- Giữ nguyên bộ tham chiếu thử nghiệm và danh mục ngôn ngữ đã đóng băng.

## Thay đổi

- Thêm `Monster.LegacyRemainder` với phép dư thông thường.
- Thêm `Monster.SaveManager` để điều phối giá trị nguyên chính xác.
- Nối đường sản xuất `save_value_spaghetti` qua bộ phân phối và quản lý SAVE.
- Thêm sáu kiểm thử: ba kiểm tra thành công và ba hồi quy chuẩn cố ý thất bại.
- Cập nhật trạng thái, README và lịch sử phát triển trong cùng một commit.

## Kiểm chứng dự kiến

Chạy `mix test` với Elixir 1.18 và Erlang/OTP 27.

- Tổng số dự kiến: 22 kiểm thử, trong đó có 16 kiểm thử cũ.
- Số thất bại dự kiến: 3, chỉ tại M, 2M và 3M.
- Phần dư sai dự kiến: 0; SAVE đúng dự kiến: M.
- Kiểm tra tên chuẩn và văn bản nguồn phải độc lập thành công.

## Tiêu đề commit

Giai đoạn 2: phơi bày sai lệch phần dư SAVE đầu tiên

## Nội dung commit

Thêm đường SAVE lịch sử chạy thật và ba hồi quy chuẩn cố ý đỏ.
Giữ nguyên nguồn tham chiếu thử nghiệm, các kiểm thử nền và danh mục đã đóng băng.
Không thêm bất kỳ lớp vá nào trước giai đoạn 3.
