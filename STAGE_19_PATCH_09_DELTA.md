# Phần thay đổi giai đoạn 19 — Bản vá 09

## Nền tảng

Điểm đóng giai đoạn 18:
`fb3bff3095bdab8b067d340adda583c08a5edf10`.
CI Elixir 1.18.5 / OTP 27: 209 kiểm thử, đúng 4
hồi quy chuẩn đỏ của phát hiện 09; khóa tên PASS.
Giai đoạn 19 chỉ vá ba nguồn rót, không bắt đầu
DISCOVERY 10 về contamination in-place.

## Giữ code lịch sử

`LegacyPourPositions.read_old(bowls_old,position)`
tiếp tục gọi `Map.fetch!(bowls_old,position)` cho
position thuộc 1..3. Module legacy và biểu thức này
giữ nguyên hoàn toàn. `LegacyPourPositions.pour`
vẫn dùng `drop²+stone*read_old(...)+(2*position+1)*index`
qua SaveManager. Trực tiếp gọi legacy với map ID thật
vẫn tái hiện được lỗi lịch sử phát hiện 09.

## Bản vá ánh xạ vị trí đến ID

`BowlAliasPatch.alias_view(old,order)` tạo một map riêng:
```text
bowlAlias[1] = old[order[1]]
bowlAlias[2] = old[order[2]]
bowlAlias[3] = old[order[3]]
```
Với code Elixir, order là list chỉ số từ 0; lấy
`Enum.at(order,position-1)`. `BowlAliasPatch.pour`
chuyển `bowlAlias` thực sự cho
`LegacyPourPositions.pour` và không giả lập lời gọi cũ.

`BowlDropCalculator.step` dùng lớp vá này trong cả
ba lần rót. Sáu lần khuấy tiếp theo vẫn đọc `old`
làm snapshot danh tính thật, viết map `next` riêng.
Không sửa `BowlSeedCalculator`, hoán vị, 46 giọt,
SAVE, công thức khuấy, hoặc 12 lần khuấy sau giọt 46
(chưa triển khai).

## Bằng chứng hồi quy

- Giữ nguyên các biểu thức `assert` thuộc bốn hồi quy
  chuẩn từ giai đoạn 18. Chỉ đổi dữ liệu `got` trước
  phép assert trực tiếp để thử đường bản vá.
- Những kiểm thử kiểm tra lỗi legacy gọi trực tiếp
  vẫn giữ được; các bài kiểm tra kết quả sản xuất
  đổi sang xác nhận oracle đúng.
- Bổ sung 14 kiểm thử `stage_19_patch_09_test.exs`:
  ba nguồn rót qua mọi 720 hoán vị, đường legacy sai
  còn nguyên, bất biến snapshot old, 46 giọt ở nhiều
  hướng ngày, số nguyên 2048 bit, chạy đồng thời,
  API public và kiểm tra mã nguồn.
- Tổng dự kiến 223 kiểm thử, 0 thất bại, khóa tên PASS.
- Oracle test-only giữ nguyên. Không sửa main.

## Điểm tiếp theo

Giai đoạn 20 DISCOVERY 10 sẽ mở lỗi ghi đè in-place
trên sáu bát. Bản vá hiện tại không gây lỗi này và
không được thực hiện trước giai đoạn sau.
