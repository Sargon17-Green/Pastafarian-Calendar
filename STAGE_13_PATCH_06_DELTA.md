# Phần thay đổi giai đoạn 13 — Bản vá 06

## Điểm bắt đầu

Commit đã đóng phát hiện 06, giai đoạn 12:
`e822de60a8e99fb9612d438ce9fd4f61ad41643b`.
126 kiểm thử, đúng bốn hồi quy chuẩn cố ý đỏ ở
giọt nhìn thấy 1, 2, 7, 46. Không cảnh báo biên dịch,
khóa tên chuẩn PASS. Giai đoạn 13 chỉ bổ sung bản vá 06.

## Bảo toàn hàm lịch sử

`LegacyPrior.legacy_prior(visible_store,index,back)` vẫn
truy cập `visible_store[index-back]` và trả 0 khi thiếu;
không sửa mã cũ, không ghép kho giọt ẩn vào kho nhìn thấy.
Hàm cũ vẫn phải được gọi thật khi vị trí dương.

## Bản vá trên miền chỉ số

```text
slot = index-back
if slot>=1:
    previous = LegacyPrior.legacy_prior(visible_store,index,back)
else:
    hidden_number = 1-slot
    previous = HiddenDropManager.read(hidden_storage,hidden_number)
```

`HiddenDropManager.read` tiếp tục gọi bản vá 05
để truy cập đúng tuple giọt ẩn lưu đảo từ hidden7 đến hidden1.
Các miền cần truy cập của i=1..46, back trong {1,3,7}
chỉ có các địa chỉ dương hoặc 0..-6; không có ô ngoài miền.

`PriorPatch.read/4` thực hiện phân nhánh này và kiểm tra
tham số. Không dùng oracle trong mã sản xuất.

## Luồng sản xuất

`Dispatcher.bootstrap` tính bảng đá, tính bảy giọt ẩn
và lưu tuple `hidden_storage`. Cùng tuple ấy được truyền
vào `VisibleDropManager.build` rồi `VisibleDropCalculator.calculate`.
Mỗi giọt trong 46 giọt dùng `PriorPatch.read` cho
back = 1, 3, 7 và 11 phép nghiền vẫn như giai đoạn 12.

`visible_drops_spaghetti` và `visible_drop_spaghetti`
đi qua bộ quản lý mới, không có trạng thái toàn cục.

## Kiểm thử và giới hạn

- Bảo toàn bốn hồi quy chuẩn từ giai đoạn 12, không đổi kỳ vọng.
- Điều chỉnh riêng hai kiểm thử dây nối cũ từng đòi đầu ra sai.
- Thêm 11 kiểm thử độc lập ở `stage_13_patch_06_test.exs`:
  bảng 46 giọt trên nhiều ngày, cả bảy ô ẩn, địa chỉ dương
  vẫn gọi legacy, giọt đầu với 11 lần nghiền, ranh giới i=8,
  số nguyên hơn 2048 bit, chạy song song, lỗi đầu vào,
  kiểm toán mã nguồn và giữ các giai đoạn trước.
- Tổng dự kiến 137 kiểm thử, 0 lỗi; khóa tên chuẩn đạt.
- Chưa bắt đầu giai đoạn 14 (DISCOVERY 07 về bảng nghiền).
- Không sửa các nguồn kênh main hoặc mã oracle test-only.

## Commit

Giai đoạn 13: vá truy cập giọt trước qua kho ẩn

## Kết quả thực tế được xác minh

- Commit triển khai: `441566e689b064334658af3b490158d89cae3cea`.
- Elixir 1.18.5 / Erlang/OTP 27.
- 137 kiểm thử, 0 thất bại, không cảnh báo biên dịch.
- Bốn hồi quy chuẩn từ phát hiện 06 không đổi, đều đạt.
- Mười một kiểm thử mới đạt; đối chiếu đủ 46 giọt và
  các miền ẩn/hiện, số nguyên 2048 bit, song song, lỗi tham số.
- Khóa tên chuẩn độc lập PASS.
- LegacyPrior giữ nguyên blob SHA
  `4c2b416bf089f8a538908fd4d310bcb6900c2419`.
- Oracle test-only giữ nguyên blob SHA
  `be1638f46b2190d617af0378a61b077bda10bf32`.
- Không sửa main, không bắt đầu giai đoạn 14.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212531371
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212531416

Trạng thái cuối giai đoạn 13: GREEN đã được xác minh.
Tiếp theo giai đoạn 14, DISCOVERY 07, chưa bắt đầu.
