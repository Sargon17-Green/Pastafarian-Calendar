# Giai đoạn 22 — Phát hiện 11: ô thứ tự bát ghi đè

## Mốc bắt đầu

Giai đoạn 21 đã khép ở HEAD
`a47d356127530948e52d4f2c07abdd2e40904949`.
CI Elixir 1.18.5 / OTP 27: 253 kiểm thử đạt,
0 thất bại, 0 cảnh báo, Canonical Names Lock PASS.
Phát hiện 11 không thực hiện PATCH 11 của giai đoạn 23.

## Công thức chính xác được bổ sung

Sau 46 giọt đã đúng qua mười bản vá, giai đoạn này
tính đủ 12 lượt khuấy cuối. Với mỗi `stir=1..12`:

- `old` là snapshot của sáu ID đầu lượt.
- `saved_bowl_sum=SAVE(sum(old[1..6])+149*stir)`.
- Hạng một-based của hoán vị sáu ID là
  `regularMod(saved_bowl_sum-1,720)+1`; tính thông qua
  `BowlOrderManager.order_from_drop` đã qua PATCH 08.
- Với mỗi vị trí `p`, `id=order[p]`,
  `prev=order[wrap(p-1)]`, `next=order[wrap(p+1)]`.
- `mix=old[id]+3*old[prev]+5*old[next]+saved_bowl_sum+stir+p²`.
- `updated=SAVE(mix²+7*old[prev]*old[next])`.
- Sáu ID đọc chung old và lưu đồng loạt vào map next.

`PostStirCalculator.step` và `apply_all` thực hiện
trực tiếp các công thức trên, không dùng oracle trong production.
`Context.bowls_after_post_stirs` chứa kết quả chuẩn.

## Lỗi lịch sử thực trong đường truy vấn

`LegacyOrderMemory` là một map riêng từng Context với
`order`, `writes`, `last_source`. Trên đường production:

1. `BowlDropCalculator.apply_all_with_order_memory`
   cập nhật cả 46 giọt và ghi `order` 46 lần,
   ghi cuối `{:drop,46}`.
2. `PostStirCalculator.apply_all` cập nhật đúng sáu bát
   qua 12 lượt khuấy, nhưng ghi cùng ô `order` thêm 12 lần.
3. Tổng `writes=58`; nguồn cuối `{:stir,12}`.
4. `LegacyOrderMemory.next_bowl` được gọi thật bởi
   `Dispatcher.next_bowl` / `next_bowl_spaghetti`.
   Nó dùng hoán vị hiện tại sau khuấy cuối, **không**
   dùng hoán vị đã có tại giọt 46.
5. Không tạo `order_at_drop_46_latch` hoặc bản vá
   định tuyến tới latch ở DISCOVERY 11.

Map `Context.bowl_orders[46]` vẫn tồn tại như dữ liệu
phục vụ các giọt; nó không được dùng trong truy vấn legacy.
Kết quả khuấy và hoán vị phải hợp lệ, chỉ quan hệ kế cận
khi truy vấn từ bộ nhớ ghi đè là sai.

## Bằng chứng kiểm thử

`test/stage_22_discovery_11_test.exs` bổ sung 16 bài,
12 bài điều khiển và bốn so sánh chuẩn cố ý đỏ:

- Ghi nhớ lần 46 và tổng 58, nguồn cuối stir 12.
- So khớp công thức 12 lượt, kết quả sáu ID với
  `NormativeReference.post_stir12` và `sauce.bowls`.
- Chứng minh đường truy vấn legacy thực dùng ô order
  đã ghi đè, trong khi order giọt 46 còn trong map.
- Giữ bất biến 253 kiểm thử giai đoạn 1–21, số nguyên
  2048 bit, chạy đồng thời, lỗi đầu vào.
- Bốn phép so sánh chuẩn next-bowl dùng order tại
  giọt 46; không thay oracle test-only.
- Dự kiến tổng 269 kiểm thử với đúng bốn hồi quy đỏ,
  nhưng chỉ xác nhận sau CI và phân loại log.
- Không thay main, không dùng thư viện ngôn ngữ khác.

## Việc dành cho giai đoạn 23 — PATCH 11

Giữ nguyên LegacyOrderMemory (vẫn 58 lần ghi).
Tại thời điểm giọt 46, chốt riêng
`orderAt46Latch`, không để các lần khuấy sau ghi đè.
Các lời gọi next-bowl của production phải lấy hoán vị từ
latch đúng, không sửa công thức sáu bát hoặc 12 lượt khuấy.
Không thực hiện sớm ở giai đoạn 22.
