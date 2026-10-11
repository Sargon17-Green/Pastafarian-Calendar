# Cách triển khai lịch Pastafari bằng Elixir

Đây là một kho mới được dựng từ số không cho đúng một dòng triển khai: Elixir là ngôn ngữ lập trình duy nhất và tiếng Việt là ngôn ngữ nguồn duy nhất cho mọi văn bản do dòng triển khai tạo ra. Kho này không dựa vào mã, kiểm thử, dữ liệu kiểm thử, kết quả, bảng sinh ra hay giá trị băm của bất kỳ cách triển khai nào khác.

Giai đoạn 1 đã dựng nền móng: mã sản xuất có ngữ cảnh riêng cho từng lần gọi, bộ phân phối cơ sở, kiểm tra đầu vào, biên lỗi và trạng thái quan sát phi ngữ nghĩa.

Bộ tham chiếu chuẩn sạch nằm dưới `test/support/` và chỉ phục vụ kiểm thử. Mã sản xuất không nhập, không gọi và không dùng nó làm đường dự phòng.

Elixir dùng số nguyên có độ chính xác tùy ý, vì vậy phép tính chuẩn không cần thư viện số lớn hay cầu nối sang ngôn ngữ khác.

`SourceLanguageCatalog` phiên bản `1.0.0` đã được đóng băng ở giai đoạn 1. Mọi thứ tự chuẩn dùng `canonicalIndex`; chuỗi tiếng Việt chỉ được giải ra ở lớp kết quả hoặc trình bày.

## Xác minh giai đoạn 1

Giai đoạn 1 đã hoàn tất. GitHub Actions đã chạy `mix test` bằng Elixir 1.18.5 trên Erlang/OTP 27 và hoàn tất với 16 kiểm thử, 0 lỗi.

## Giai đoạn 2 — Phát hiện 01

Giai đoạn 2 chủ ý làm lộ sai lệch đầu tiên: `old_remainder(value)` trả phần dư thông thường trong miền 0..M−1 thay cho SAVE trong miền 1..M, với M = 2^127−1. Sai lệch xuất hiện khi `value` chia hết cho M.

Có thể đi qua đường sản xuất chưa vá bằng `PastafariCalendarElixirVietnamese.save_value_spaghetti(value)`. Hàm trả kết quả sai tại M, 2M và 3M; điều này được kiểm chứng bằng các hồi quy chuẩn cố ý thất bại. Tại M+1 hàm trả 1 như chuẩn.

Đó là trạng thái `EXPECTED_RED` lịch sử của giai đoạn khám phá; các hồi quy chỉ được chuyển thành đạt ở giai đoạn 3 nhờ lớp vá thực tế, không phải bằng cách đổi kỳ vọng. Hàm tính ngày lịch đầy đủ vẫn chưa được tích hợp.

Chạy tại gốc kho:

```text
mix test
```

Bước lịch sử tiếp theo sau giai đoạn 2 là giai đoạn 3/55, `PATCH 01`. Bước này hiện đã hoàn tất với lớp vá chuyển phần dư 0 thành M, còn `old_remainder` được giữ nguyên làm dấu vết lịch sử.

## Bằng chứng khép giai đoạn 2

GitHub Actions chạy Elixir 1.18.5 với OTP 27 và xác nhận 22 kiểm thử,
3 thất bại đúng tại M, 2M, 3M; 19 kiểm thử còn lại thành công.
Không có lỗi biên dịch hay sai lệch kiểm thử ngoài dự kiến.

- [Nhật ký kiểm thử dự kiến đỏ](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38150668369)
- [Kiểm tra khóa tên chuẩn đã đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38150668429)

## Giai đoạn 3 — Bản vá 01

Vẫn giữ nguyên hàm lịch sử `LegacyRemainder.old_remainder` trả 0
đối với các bội số của M. Lớp `SavePatch` gọi chính hàm đó, rồi
chỉ thay kết quả 0 bằng M. `SaveManager` tiếp tục qua lớp vá này.
Ba hồi quy chuẩn của giai đoạn 2 không bị sửa hoặc xóa và phải chuyển sang đạt.

Các kiểm thử mở rộng gồm phần dư âm, số 0, số nguyên lớn hơn 1024 bit,
tính chu kỳ, nhiều yêu cầu đồng thời và kiểm tra đường gọi lịch sử.
Hàm ngày lịch đầy đủ vẫn bị chặn cho đến giai đoạn tích hợp bắt buộc.

## Xác minh hoàn tất giai đoạn 3

Quy trình GitHub Actions dùng Elixir 1.18.5 và Erlang/OTP 27 đã chạy
`mix test` với 29 kiểm thử, 0 lỗi. Cả ba hồi quy chuẩn của giai đoạn 2
đã chuyển thành đạt mà không đổi các kỳ vọng. Quy trình khóa tên chuẩn
hoàn tất thành công; mô-đun `LegacyRemainder` vẫn nguyên trạng.

- [Kiểm thử Elixir — đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151138352)
- [Khóa tên chuẩn — đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151138317)

Giai đoạn 3/55 đã được đóng với trạng thái `GREEN`.
Bước lịch sử tiếp theo là giai đoạn 4/55: `DISCOVERY 02`, không được
đưa bản vá thứ hai vào cùng bước khám phá.

## Giai đoạn 4 — Phát hiện 02: sai số nhãn ngày

Bộ đánh số ngày mới được nối vào đường sản xuất thông qua
`day_count_spaghetti(day)` và hai nhãn riêng trong `bootstrap_context`.
Công thức lịch sử `2 * abs(day - FOUNDATION)` bị sai tại ngày nền
và tất cả các ngày sau đó; trước ngày nền nó trùng quy tắc chuẩn.

Ba kiểm thử hồi quy chuẩn của giai đoạn 4 cố ý yêu cầu nhãn đúng ở
`FOUNDATION`, `FOUNDATION+1`, `FOUNDATION+2`; do đó trạng thái
mong đợi ở pha khám phá là `EXPECTED_RED`. Lớp vá thứ hai chỉ được
đưa vào ở giai đoạn 5. Lớp vá SAVE thứ nhất và các kiểm thử cũ
vẫn phải hoạt động không thay đổi.
