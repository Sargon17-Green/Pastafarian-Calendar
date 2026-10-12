# Giai đoạn 25 — Bản vá 12: bát kế cận theo vị trí thực trong chốt

## Điểm xuất phát

Giai đoạn 24 khép tại
`5aaf36d0d30434dc4163d99e094b490c883c7c88`.
Elixir 1.18.5, Erlang/OTP 27: 301 kiểm thử với
đúng 12 hồi quy đỏ do vòng ID cố định,
289 bài đạt, không cảnh báo; khóa tên chuẩn PASS.

## Bảo tồn lỗi lịch sử

Không sửa `LegacyFixedNameSuccessor`:
`old_next_bowl_fixed_name(id)` tiếp tục trả `rem(id,6)+1`.
Nó vẫn được gọi **trực tiếp và thật** trong production,
nhưng chỉ để giữ `legacy_next_id` của chẩn đoán.
Module này vẫn sai khi hoán vị không phải một trong
sáu phép xoay vòng cố định.

`LegacyOrderMemory` vẫn ghi 58 lần; chốt giọt 46
vẫn được tạo trước 12 lượt post-stir. Không thay
source hoặc dữ liệu sản xuất của các bản vá 01..11.
Không dùng oracle từ `test/support` trong production.

## Tách kết quả chuẩn và kết quả lịch sử

Module `NextBowlPatchWrapper` cung cấp:

- `diagnose(order_at_46_latch,id)` gọi đầu tiên
  `LegacyFixedNameSuccessor.old_next_bowl_fixed_name(id)`
  để nhận `legacy_next_id`. Lời gọi này cũng xác minh
  ID thuộc 1..6 và bảo tồn thông báo lỗi legacy.
- Tiếp theo gọi `OrderAt46LatchPatch.next_bowl(latch,id)`
  để nhận `correct_next_id` từ vị trí ID trong chốt.
  Mã của bản vá 11 này gọi thật bộ đọc vị trí lịch sử
  `LegacyOrderMemory.next_bowl` trên bản xem chốt.
- Chẩn đoán trả map tách biệt với `queried_id`,
  `legacy_next_id`, `correct_next_id`, `diverges`.
- `next_bowl(latch,id)` gọi `diagnose`, chỉ trả
  `correct_next_id`. Giá trị sai của legacy không
  đi vào kết quả chuẩn.
- `Dispatcher.next_bowl` dùng wrapper, và API công khai
  mới `next_bowl_diagnostic_spaghetti` cho phép kiểm
  chứng việc gọi legacy mà không thay đổi kết quả.

Ví dụ: latch=[4,5,2,3,6,1], queried ID 3, kết quả
legacy=4, kết quả chuẩn=6, diverges=true.
Với queried ID 1 là phần tử cuối, kết quả chuẩn
đảo vòng về phần tử đầu là 4, dù legacy cho 2.

## Kiểm thử và giới hạn

- Bốn hồi quy chuẩn Stage24 và sáu Stage22, hai Stage23
  phải trở lại xanh với nguyên kỳ vọng oracle.
- Một bài Stage24 dùng trực tiếp legacy trong assert
  chuẩn sẽ chuyển sang dùng wrapper trên fixture,
  không thay giá trị expected; bài kiểm soát khác vẫn
  chứng minh legacy trực tiếp trả 4 thay vì 6.
- Các bài kiểm soát Stage24 đòi production cố ý sai
  được đổi để xác minh legacy vẫn sai nhưng production
  đã đúng. Kiểm toán nguồn Stage23/24 cập nhật theo
  wrapper thực sự dùng legacy để chẩn đoán.
- 16 kiểm thử mới trong `stage_25_patch_12_test.exs`,
  gồm tất cả 720 hoán vị x 6 ID, đúng 6 phép xoay khớp
  vòng legacy, chốt vị trí cuối-đầu, lỗi đầu vào,
  lưu chẩn đoán, đồng thời, ngày 2048 bit và
  tính độc lập của context.
- Tổng dự kiến 317 kiểm thử, 0 thất bại,
  0 cảnh báo và khóa tên chuẩn PASS.
- Không sửa `test/support/normative_reference.ex`,
  không sửa branch main, không mở Stage26.

## Commit

Giai đoạn 25: sửa vòng bát theo latch, giữ legacy để chẩn đoán
