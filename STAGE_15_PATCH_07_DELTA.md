# Phần thay đổi giai đoạn 15 — Bản vá 07

## Nguồn và điểm bắt đầu

Giai đoạn 14 đóng tại commit
`4d1205388e0c7b22cf628cc5bc841fc9730d2543`.
CI đã xác minh 151 kiểm thử, đúng 16 sai lệch liên quan
bảng nghiền sai chỉ số (4 bài mới, 5 bài giai đoạn 12,
7 bài giai đoạn 13), không cảnh báo; khóa tên PASS.
Giai đoạn 15 chỉ sửa bảng nghiền, chưa triển khai giai đoạn 16.

## Sửa bảng mà không sửa hàm đọc

Bộ đọc cũ trong `LegacyGrindTable` giữ nguyên:

```elixir
def legacy_row(number) when is_integer(number) and number in 1..11 do
  Enum.at(@real_rows, number, @missing_row)
end
```

Lỗi phát hiện 07 xuất hiện do bảng chỉ có 11 hàng thật tại index
0..10, còn legacy đọc theo index 1..11. Trong PATCH 07,
đặt sentinel thật vào index 0:

```text
index 0: {0,0,0,0,1} (sentinel, được lưu vĩnh viễn)
index 1..11: đủ 11 hàng nghiền chuẩn, không thay nội dung
```

Lời gọi `legacy_row(1..11)` giờ đọc các hàng thật tương ứng,
không chạm sentinel hoặc fallback. Sentinel vẫn nằm trong bảng,
không bị lọc đi, không thay phép đọc bằng number-1.

`VisibleDropCalculator` tiếp tục gọi `legacy_row`
đúng 11 lần cho mỗi giọt nhìn thấy; các phép SAVE, đá,
tiền nhiệm, hidden, bootstrap, phân nhánh PATCH 06 không đổi.

## Kiểm thử hồi quy

- Giữ nguyên bốn hồi quy chuẩn của giai đoạn 14,
  cùng các kỳ vọng chuẩn đã tồn tại giai đoạn 12–13.
- Các bài cũ thuộc phát hiện 07 kiểm tình trạng legacy sai
  được điều chỉnh để kiểm bằng chứng sai cũ trên mô hình
  zero-based song song và chứng minh bảng thật có sentinel.
- Thêm 12 bài mới `test/stage_15_patch_07_test.exs`
  xác minh sentinel 12 hàng, 11 hàng đúng, mã nguồn giữ
  nguyên legacy, giá trị 11 vòng nghiền độc lập, 46 giọt,
  các biên và lỗi đầu vào, số nguyên 2048 bit,
  tính đồng thời, không trạng thái toàn cục và các bản vá 01–06.
- Tổng dự kiến: 163 kiểm thử, không thất bại; khóa tên PASS.
- Giữ `test/support/normative_reference.ex` không thay đổi.
- Không đổi nhánh main, chưa khởi động DISCOVERY 08.

## Tiêu đề commit

Giai đoạn 15: đặt sentinel giữ nguyên cách đọc bảng nghiền lịch sử

## Kiểm chứng CI và quyết định đóng

- Commit triển khai: `399f042717078760f95233b7ec7b551966cbacbb`.
- Commit sửa kiểm thử nguồn: `acacae6a3521c8a9e56b9a3b63a67f91251f3abb`.
- Elixir 1.18.5 / Erlang/OTP 27.
- 163 kiểm thử, 0 thất bại, 0 cảnh báo biên dịch.
- Tất cả 16 bài đã đỏ ở giai đoạn 14 hiện xanh.
- Bốn hồi quy chuẩn Stage14 vẫn nguyên từng khẳng định.
- 12 bài kiểm thử Stage15 bổ sung đạt.
- Khóa tên chuẩn độc lập PASS.
- Hàm đọc `Enum.at(@real_rows, number, @missing_row)` giữ nguyên.
- Sentinel thật ở index 0, đủ 11 hàng ở index 1..11.
- Không dùng oracle trong production, không thay main.
- Chưa bắt đầu giai đoạn 16, DISCOVERY 08.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38229835498
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38229835434

Trạng thái cuối: GREEN đã xác minh. Giai đoạn 16 chưa bắt đầu.
