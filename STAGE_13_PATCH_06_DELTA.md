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
