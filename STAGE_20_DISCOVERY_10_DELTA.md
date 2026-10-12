# Phần thay đổi giai đoạn 20 — Phát hiện 10

## Nền đã xác minh

Giai đoạn 19 khép tại commit
`57b45b112373f5ad4c2cd8ffbf1d5906a19b9b61`.
CI Elixir 1.18.5, Erlang/OTP 27: 223 kiểm thử, 0 lỗi,
0 cảnh báo biên dịch, khóa tên chuẩn PASS.
DISCOVERY 10 phải gây ô nhiễm in-place có thể tái lập;
không thực hiện PATCH 10 ở giai đoạn 20.

## Đường lỗi lịch sử

`LegacyInPlaceStir.compute_one(source,pours,drop,row,order,index,position)`
tính chính xác công thức sáu bát theo nguồn `source`.
Ở `LegacyInPlaceStir.run`, sáu vị trí được tính bằng:

```text
current = old
for position in 1..6:
    (id, updated) = compute_one(current, pours, drop, row, order, index, position)
    current = Map.put(current, id, updated)
return current
```

Trong Elixir, map bất biến về bộ nhớ, nhưng vòng lặp
sử dụng map `current` mới ngay lập tức, tái hiện đúng
lỗi đọc giá trị đã ghi đè. Không có dữ liệu toàn cục,
không dùng put vào snapshot chuẩn `old` lúc bắt đầu vòng.

`BowlDropCalculator.step` tạo ba giá trị rót đúng
qua `BowlAliasPatch.pour` **trước** vòng sáu vị trí;
đường rót vẫn gọi LegacyPourPositions chính xác qua alias.
Các phép khuấy lấy ID danh tính qua order, các láng giềng
cũng từ order, đá và SAVE vẫn như chuẩn. Chỉ biến source
của lần khuấy thứ 2..6 đã nhiễm.

`Dispatcher.bootstrap` tiếp tục chạy đủ 46 giọt và lưu
`Context.bowls_after_drops`. Sáu ID vẫn đầy đủ, không
thêm 12 lần khuấy sau đó hoặc lịch thành phẩm.

## Bằng chứng và hồi quy

- Thêm 16 bài `test/stage_20_discovery_10_test.exs`,
  gồm 12 điều khiển, bốn hồi quy chuẩn cố ý đỏ.
- Chứng minh vị trí 1 bằng nguồn old còn đúng, vị trí 2
  khác vì đọc bát đã cập nhật; tự mô phỏng toàn bộ sáu
  vị trí để kiểm `LegacyInPlaceStir.run`.
- Kiểm định tiếp nguồn ba phép rót, SAVE, giọt và hoán vị,
  giới hạn đầu vào, ngày số nguyên 2048 bit, song song,
  bất biến map nguồn và bằng chứng mã nguồn.
- Bảo toàn các khẳng định oracle trước đó ở giai đoạn
  18 và 19, dù nhiều kiểm thử trở lại đỏ do đúng lỗi
  mới được đưa vào sản xuất. Chỉ cập nhật kiểm thử
  kiểm toán vị trí mã nguồn bị chuyển vào module lịch sử.
- Tổng dự kiến: 239 kiểm thử; số thất bại chính xác
  sẽ được phân loại từ CI, không giả định trước.
- Không sửa oracle test-only; không thay branch main.

## Yêu cầu của PATCH 10 — giai đoạn 21

Giữ nguyên `LegacyInPlaceStir` như bằng chứng, tạo
snapshot riêng `vaultOld` đầu giọt và map `pending`.
Mọi `compute_one` lấy cùng `vaultOld`, chỉ sau cả
sáu lần mới commit cùng lúc các kết quả của pending.
Không triển khai thay đổi ấy trong DISCOVERY 10.

## Kết quả CI được xác minh

- Commit triển khai: `0af1eac7daf66fce7e819a132ace9c026d729667`.
- Elixir 1.18.5 / Erlang/OTP 27; biên dịch 35 tệp .ex.
- **239 kiểm thử, chính xác 14 thất bại do lỗi in-place**;
  225 kiểm thử đạt, không cảnh báo biên dịch.
- 4 hồi quy chuẩn mới Stage20 đỏ tại bước khuấy đầu,
  ngày bằng nhau, ngày đảo hướng, ngày rất lớn.
- 6 bài Stage18 đỏ do so sánh nguồn old bất biến với
  kết quả in-place; 4 bài Stage19 đỏ do so sánh bát
  sau 46 giọt với oracle, gồm ngày rất lớn và song song.
- 12 bài kiểm soát Stage20 đều PASS; ba nguồn rót qua alias
  vẫn đúng, giọt và hoán vị vẫn đúng, map không chia sẻ.
- Khóa tên chuẩn độc lập PASS.
- Giữ các kiểm thử chuẩn cũ và oracle nguyên vẹn.
- Không sửa main; không tạo vaultOld, pending,
  hoặc sửa lỗi ở giai đoạn 21.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38248260572
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38248260716

Trạng thái cuối: EXPECTED_RED đã xác minh.
Điểm tiếp theo: giai đoạn 21 PATCH 10, chưa bắt đầu.
