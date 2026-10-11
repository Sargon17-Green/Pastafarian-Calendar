# Phần thay đổi riêng giai đoạn 4 — Phát hiện 02

## Giới hạn lịch sử

Bắt đầu từ commit đóng giai đoạn 3 `adb33cf5983b32f89f7b492c80e14af847e22de9`.
Giai đoạn 3 đã được xác minh với 29 kiểm thử đạt, không lỗi.
Giai đoạn 4 chỉ thêm lỗi đánh số ngày; tuyệt đối không thêm bản vá 02
hoặc bất cứ thành phần nào thuộc các giai đoạn tiếp theo.

## Sai lệch bắt buộc

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION)
```

Ngày Nền: -15_055_671.

Giá trị cũ so với giá trị chuẩn:
- FOUNDATION-1: 2 so với 2 — đối chứng đúng.
- FOUNDATION: 0 so với 1 — hồi quy đỏ.
- FOUNDATION+1: 2 so với 3 — hồi quy đỏ.
- FOUNDATION+2: 4 so với 5 — hồi quy đỏ.

## Liên kết sản xuất

- Tạo `LegacyDayTag.old_day_tag` với đúng công thức sai.
- Tạo `DayCountManager.tag` gọi trực tiếp hàm lịch sử.
- Tích hợp cả nhãn tính và nhãn đích vào bootstrap context bất biến.
- Tạo `day_count_spaghetti` dùng chính tuyến sản xuất này.
- Giữ nguyên tất cả hồi quy của SAVE và danh mục ngôn ngữ nguồn.
- Không thay đổi main và không trộn giai đoạn 5.

## Xác minh cần thu thập

- Dự kiến 36 kiểm thử, 3 thất bại đúng tại FOUNDATION,
  FOUNDATION+1, FOUNDATION+2.
- 33 kiểm thử còn lại đạt.
- Khóa tên chuẩn PASS.
- Không có lỗi biên dịch.
- Ghi lại liên kết GitHub Actions sau khi hoàn tất.

## Tiêu đề commit

Giai đoạn 4: phơi bày sai lệch nhãn ngày lịch sử

## Nội dung commit

Đưa công thức cũ của nhãn ngày vào luồng bootstrap và bộ quản lý ngày.
Thêm hồi quy chuẩn cố ý đỏ ở ngày nền và hai ngày sau.
Giữ nguyên bản vá SAVE thứ nhất, chưa đưa vào bản vá 02.

## Kết quả kiểm chứng thực tế

- Elixir 1.18.5, Erlang/OTP 27.
- 36 kiểm thử, đúng 3 thất bại, 33 thành công.
- FOUNDATION: kết quả thực tế 0, giá trị chuẩn 1.
- FOUNDATION+1: kết quả thực tế 2, giá trị chuẩn 3.
- FOUNDATION+2: kết quả thực tế 4, giá trị chuẩn 5.
- Không có lỗi biên dịch; không có lỗi ngoài ba hồi quy bắt buộc.
- Bằng chứng CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38152863320
- Khóa tên chuẩn PASS: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38152863404

Trạng thái đóng giai đoạn 4: EXPECTED_RED được xác minh.
Không khởi động hoặc gộp giai đoạn 5.
