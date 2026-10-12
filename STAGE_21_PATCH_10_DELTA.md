# Phần thay đổi giai đoạn 21 — Bản vá 10

## Điểm xuất phát và giới hạn

Commit đóng DISCOVERY 10:
`f5b91ad87874423734a407c6548e38749a296fb3`.
CI Elixir 1.18.5 / OTP 27: 239 kiểm thử,
14 thất bại đã phân loại (4 ở Stage20, 6 ở Stage18,
4 ở Stage19), 225 bài đạt và không cảnh báo biên dịch.
Khóa tên chuẩn PASS.

Giai đoạn 21 là PATCH 10; chỉ sửa ô nhiễm trong sáu phép
khuấy của mỗi giọt, không làm 12 lượt khuấy sau giọt 46,
không bắt đầu lỗi mới thuộc giai đoạn 22.

## Di sản còn nguyên

`LegacyInPlaceStir.run` giữ đúng lỗi:
```elixir
Enum.reduce(1..6, old, fn position, current ->
  {id, updated} = compute_one(current, pours, drop, row, order, index, position)
  Map.put(current, id, updated)
end)
```

Gọi trực tiếp legacy vẫn tạo sai lệch so với oracle,
nhưng đây không còn là đường production. Hàm
`LegacyInPlaceStir.compute_one` giữ nguyên công thức chuẩn
và vẫn là bộ tính thực tế của mỗi vị trí trong bản vá.
Không sao chép công thức sang một thuật toán mới.

## Bản vá: vaultOld và pending

`BowlVaultPatch.run` thực hiện:

```text
vaultOld = old
pending = {}
for position in 1..6:
    (id, updated) = LegacyInPlaceStir.compute_one(
        vaultOld, pours, drop, row, order, index, position)
    pending[id] = updated
return merge(vaultOld, pending)
```

Bản sao logic `vaultOld` là map bất biến chứa sáu ID bát
tại đầu bước giọt. Bản đồ `pending` độc lập gom sáu cập nhật
mà không bao giờ được dùng làm nguồn. `Map.merge` chỉ
xảy ra sau khi sáu lời gọi compute_one đã hoàn tất.
Các ID thuộc một hoán vị sáu phần tử nên không có ghi hai
lần vào một ID. Snapshot của caller vẫn nguyên.

`BowlDropCalculator.step` tiếp tục tạo ba nguồn rót
đã được vá qua `BowlAliasPatch.pour` từ snapshot `old`,
sau đó gọi `BowlVaultPatch.run`; đường 46 giọt, SAVE,
đá, hoán vị, kho ẩn, các bộ đếm không bị sửa.

## Bằng chứng và kiểm thử

- Giữ nguyên bốn hồi quy chuẩn Stage20 và mười phép
  so sánh chuẩn Stage18–19 đã đỏ; tất cả phải xanh lại.
- Điều chỉnh chỉ ba bài kiểm soát Stage20 đòi production
  còn lỗi (và bài kiểm toán nguồn), nhưng giữ
  `LegacyInPlaceStir.run` làm bằng chứng sai trực tiếp.
- Thêm 14 bài `stage_21_patch_10_test.exs`: snapshot
  và commit sáu ID, đọc sai trực tiếp qua legacy,
  đối chiếu đủ 720 hoán vị, mọi vị trí, 46 giọt,
  nhiều hướng ngày, đồng thời, số nguyên 2048 bit,
  lỗi đầu vào, API và mã nguồn.
- Tổng dự kiến 253 kiểm thử, 0 lỗi; khóa tên chuẩn PASS.
- Không sửa `test/support/normative_reference.ex`.
- Không sửa `LegacyInPlaceStir` (blob SHA của Stage20:
  `49554b37e329adb05e4f2ee77b8f51a69e944d4b`).
- Không thay branch main; không khởi động DISCOVERY 11.

## Tên commit

Giai đoạn 21: giữ vaultOld và commit sáu bát cùng lúc

## Kết quả CI và bằng chứng đã xác minh

- Commit triển khai: `f6e69f22f2f36f9dc77cc0fa326e88c517215d11`.
- Commit kiểm thử bỏ cảnh báo:
  `c64cf74b1276d113fa62b073c0ec01300c5f5487`.
- Elixir 1.18.5 / Erlang OTP 27; 36 tệp .ex được biên dịch.
- 253 kiểm thử, 0 thất bại, 0 cảnh báo (CI sau commit kiểm thử).
- Bốn hồi quy chuẩn Stage20, sáu Stage18 và bốn Stage19
  đều đạt mà không thay biểu thức assert của oracle.
- 14 bài Stage21 mới đạt, 720 hoán vị được đối chiếu.
- Khóa tên chuẩn độc lập PASS.
- LegacyInPlaceStir giữ nguyên blob SHA
  `49554b37e329adb05e4f2ee77b8f51a69e944d4b`.
- Oracle giữ nguyên blob SHA
  `be1638f46b2190d617af0378a61b077bda10bf32`.
- Không sửa main, không mở Stage22, không khuấy 12 lượt sau 46 giọt.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38254477457
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38254477452

Trạng thái cuối Stage21: GREEN đã được xác minh.
Giai đoạn tiếp theo: 22/55 DISCOVERY 11.
