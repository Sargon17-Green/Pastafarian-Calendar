# Giai đoạn 24 — Phát hiện 12: kế cận theo tên ID cố định

## Mốc nền đã xác minh

Giai đoạn 23 khép tại
`be7912cb17fcac6b7d675e3f82874d9ec329276b`.
GitHub Actions Elixir 1.18.5 / OTP 27 xác minh
283 kiểm thử đạt, không cảnh báo, khóa tên chuẩn PASS.
Bản vá 11 đã chốt thứ tự sáu ID tại giọt 46;
lịch sử vẫn ghi 58 lần vào LegacyOrderMemory.

## Hàm lỗi lịch sử

`LegacyFixedNameSuccessor.old_next_bowl_fixed_name(id)`
trả `rem(id,6)+1` cho các ID 1..6.
Nó lấy ID tiếp theo theo vòng tên cố định:
`1→2→3→4→5→6→1`; không nhận hoán vị thật
và không tìm vị trí `queriedId` trong chốt giọt 46.

Mã sản xuất `Dispatcher.next_bowl` vẫn bootstrap toàn
bộ context và giữ `order_at_46_latch` chính xác,
nhưng **cố ý bỏ qua latch** khi trả lời query,
gọi đúng hàm fixed-name mới. Đây là lỗi phát hiện 12.
Không làm thay đổi dữ liệu bát hay bất cứ bản vá 01..11.

## Chứng cứ độc lập

Với `orderAt46Latch=[4,5,2,3,6,1]`, ánh xạ chuẩn:
`4→5,5→2,2→3,3→6,6→1,1→4`.
Legacy lại trả `1→2,2→3,3→4,4→5,5→6,6→1`.
Do đó queriedId=3 có kết quả legacy=4, chuẩn=6;
ID 1 có legacy=2, chuẩn=4;
ID 5 có legacy=6, chuẩn=2.

Tổng có 720 hoán vị; chỉ sáu phép xoay vòng của thứ tự
[1,2,3,4,5,6] tạo đúng quan hệ next-bowl cố định.
Mọi thứ tự còn lại bị sai ít nhất ở một ID.

## Thử nghiệm

Thêm 18 kiểm thử trong `stage_24_discovery_12_test.exs`,
gồm 14 điều khiển của vòng ID cố định, quan hệ chuẩn
với fixture, toàn bộ 720 hoán vị, latch còn đúng,
58 lần ghi, SAVE và bowl cuối, số ngày 2048 bit,
chạy đồng thời, đầu vào sai và kiểm toán source.
Bốn hồi quy chuẩn mới được cố ý giữ đỏ.
Không đổi oracle test-only. Không sửa các biểu thức
so chuẩn Stage22/23, nên một số bài cũ có thể đỏ do
đúng lỗi fixed-name; phân loại chính xác theo log CI.
Dự kiến 301 kiểm thử, số thất bại cụ thể sẽ xác minh.
Không sửa branch main.

## Điểm tiếp theo — PATCH 12, giai đoạn 25

**Giữ nguyên** `old_next_bowl_fixed_name` byte-for-byte
và thật sự gọi nó để lưu một chẩn đoán riêng.
Lớp `NextBowlPatchWrapper` sẽ tìm ID được hỏi trong
`orderAt46Latch` và lấy phần tử kế tiếp mod 6,
trả kết quả đã vá (không phải chẩn đoán legacy).
Không triển khai bản vá này trong DISCOVERY 12.

## Kết quả kiểm chứng và phân loại

- Commit triển khai:
  `757dbe8427e71c1a40504c68da646b05720a4a8d`.
- Commit kiểm toán nguồn và alias:
  `12dcf74a8c61529f11f7136c59c03eb868133b72`.
- Elixir 1.18.5 / OTP 27: biên dịch 40 tệp .ex.
- 301 kiểm thử, 12 thất bại có chủ đích, 289 đạt.
- 4 hồi quy chuẩn Stage24 đỏ: ID 3 tại fixture,
  sáu ID cùng ngày, đảo ngày và ngày nguyên rất lớn.
- 6 bài Stage22 đỏ (4 so chuẩn + 2 kiểm thử đường query
  không còn đọc latch); 2 bài Stage23 đỏ (so truy vấn
  production với latch ở các ngày thường và rất lớn).
- Không có lỗi ngoài fixed-name query, 0 cảnh báo.
- Canonical Names Lock độc lập PASS.
- Oracle test-only vẫn giữ blob SHA
  `be1638f46b2190d617af0378a61b077bda10bf32`.
- Bản vá 01..11 không bị xoá, orderAt46Latch vẫn đúng,
  LegacyOrderMemory vẫn ghi 58 lần, số học bát cuối đúng.
- CI đầu có 14 lỗi, trong đó 2 kiểm toán source cũ;
  sửa đúng hai kiểm toán và unused alias, không sửa
  so sánh normative hoặc thuật toán sản xuất.
- Không chỉnh main, không thêm PATCH 12.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38265844932
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38265844794

Trạng thái cuối: EXPECTED_RED đã xác minh.
Điểm tiếp theo: giai đoạn 25 PATCH 12, chưa bắt đầu.
