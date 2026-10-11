# Phần thay đổi giai đoạn 11 — Bản vá 05

## Điểm bắt đầu

Commit khép giai đoạn 10:
`f5d65ec5fccdc086424aa16df09c825f8c7d204a`.
Elixir 1.18.5, OTP 27, 101 kiểm thử, đúng bốn hồi quy cố ý đỏ,
khóa tên chuẩn đạt. Giai đoạn 11 chỉ sửa truy cập giọt ẩn.
Không bắt đầu lỗi đọc lịch sử thuộc giai đoạn 12.

## Dấu vết lịch sử bắt buộc giữ

Kho cũ `LegacyHiddenStorage.store_reversed` lưu:

```text
vị trí 1: hidden7
vị trí 2: hidden6
vị trí 3: hidden5
vị trí 4: hidden4
vị trí 5: hidden3
vị trí 6: hidden2
vị trí 7: hidden1
```

Phép đọc sai `LegacyHiddenStorage.read_as_if_forward(storage,k)`
vẫn đọc phần tử tại vị trí k; không sửa hàm cũ và không đảo lại tuple.

## Lớp vá 05

`HiddenStoragePatch.read_hidden(storage,k)` nhận tên giọt k
và dùng `legacy_position = 8-k`, sau đó thực thi hàm cũ
`LegacyHiddenStorage.read_as_if_forward(storage,legacy_position)`.
Ánh xạ địa chỉ nằm ở lớp truy cập duy nhất, không thay đổi storage.

`HiddenDropManager.read` dùng lớp vá này cho mọi lần đọc
và đường công khai `hidden_drop_spaghetti` vẫn gọi manager.
`HiddenDropManager.build_storage`, `bootstrap_context`
và `HiddenDropCalculator.calculate` giữ nguyên công thức và
việc lưu đảo. Không dùng oracle trong mã sản xuất.

## Kiểm thử

Bốn hồi quy chuẩn của giai đoạn 10 về giọt 1, 2, 3, 7
giữ nguyên từng dòng; chỉ cập nhật hai kiểm thử cấu trúc/dây nối:
bản lưu cũ vẫn đảo và đọc trực tiếp sai, còn manager đã vá.

Thêm mười kiểm thử Stage11:
- Bảy vị trí, cả hai đầu kho và hàm legacy còn sai.
- Nhiều cặp ngày cùng và khác phía Ngày Nền.
- Đối chứng giọt thứ tư.
- Ngày nguyên rất lớn, tối đa hơn 2048 bit.
- Tham số số giọt và tuple sai.
- Ngữ cảnh độc lập và đồng thời.
- Kiểm toán mã nguồn, không đảo tuple.
- Hồi quy bốn bản vá trước và chưa tích hợp lịch đầy đủ.

Tổng dự kiến 111 kiểm thử, 0 lỗi, khóa tên chuẩn đạt.
Không sửa các kỳ vọng chuẩn.

## Commit dự kiến

Giai đoạn 11: vá truy cập giọt ẩn qua ánh xạ 8-k

Giữ nguyên kho lưu đảo ngược, thực thi phép đọc legacy
qua địa chỉ đã ánh xạ; bốn hồi quy chuẩn chuyển sang xanh.
