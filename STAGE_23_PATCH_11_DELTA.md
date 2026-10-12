# Giai đoạn 23 — Bản vá 11: chốt thứ tự giọt 46

## Điểm xuất phát

Giai đoạn 22 đã khép tại commit
`d1b9a31b3c195a810814158a5bc75301ee422fae`.
CI Elixir 1.18.5 / OTP 27: 269 kiểm thử,
bốn hồi quy chuẩn next-bowl đỏ dự kiến, 265 bài đạt,
0 cảnh báo biên dịch và Canonical Names Lock PASS.

## Lỗi cần sửa và di sản được giữ

LegacyOrderMemory là một ô thứ tự có thể ghi đè,
được ghi 46 lần cho 46 giọt và 12 lần cho 12 lượt
khuấy sau đó. Truy vấn từ ô này sẽ đọc thứ tự stir 12
thay vì thứ tự giọt 46. Giữ nguyên source, hành vi,
cấu trúc và mọi lần ghi của LegacyOrderMemory.

Không thay `PostStirCalculator`, số lượt khuấy,
SAVE, hoán vị, sáu ID bát, hoặc phép tính sau giọt.
Không sao chép thuật toán đọc next-bowl sang mã mới.

## Chốt và định tuyến truy vấn

Bản vá thêm `OrderAt46LatchPatch`:

1. Sau `BowlDropCalculator.apply_all_with_order_memory`,
   khi `memory_after_drops.writes=46` và
   `last_source={:drop,46}`, dùng `capture/1`.
2. `capture` đòi hoán vị sáu ID 1..6 không trùng.
   Chỉ nhận đúng mốc giọt 46, không nhận trước/sau.
3. Ghi `order_at_46_latch` vào `Context` riêng.
4. Tiếp tục `PostStirCalculator.apply_all` như cũ:
   12 lần ghi tiếp vào LegacyOrderMemory,
   tổng `writes=58`, nguồn cuối `{:stir,12}`.
5. `Dispatcher.next_bowl` gọi
   `OrderAt46LatchPatch.next_bowl` với latch.
   Lớp vá kiểm tra hoán vị và gọi thật
   `LegacyOrderMemory.next_bowl(%{order: latch}, id)`.
   Thuật toán legacy vẫn hoạt động, nhưng đọc đúng nguồn.

Với mọi ID và mọi hoán vị hợp lệ, next-bowl của lớp vá
bằng quan hệ kế cận của hoán vị được chốt, bất kể
12 lần ghi đè về sau.

## Bằng chứng dự kiến

- Bốn so sánh chuẩn Stage22 giữ nguyên `assert`
  và chuyển từ đỏ sang xanh.
- Hai bài điều khiển Stage22 được cập nhật để phân biệt
  legacy đọc memory58 sai và production đọc latch đúng.
- 14 kiểm thử mới trong `stage_23_patch_11_test.exs`,
  bao gồm 720 hoán vị x 6 ID, chốt đúng mốc, từ chối
  dữ liệu sai, 58 lần ghi, bất biến giá trị bát,
  bối cảnh song song, ngày 2048 bit, và kiểm toán code.
- Dự kiến 283 kiểm thử và 0 thất bại sau xác minh CI.
- `LegacyOrderMemory` giữ nguyên blob SHA
  `4d7610e41443d4a37d60befa76a456cd8c85e06d`.
- Oracle test-only giữ nguyên blob SHA
  `be1638f46b2190d617af0378a61b077bda10bf32`.
- Không thay main hoặc mở DISCOVERY 12 của giai đoạn 24.

## Tên commit

Giai đoạn 23: chốt thứ tự giọt 46, giữ 58 lần ghi legacy
