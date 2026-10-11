# Thay đổi riêng giai đoạn 5 — Bản vá 02

## Phạm vi

Bắt đầu từ commit đóng giai đoạn 4: `ef32a98fd00b99a532b20f973d7ad41fa64d746e`.
Kết quả giai đoạn trước: 36 kiểm thử, đúng ba thất bại có chủ đích.
Chỉ bổ sung bản vá 02. Không sửa hàm lịch sử, không bắt đầu
phát hiện 03 hoặc đưa mã của các nhánh khác vào.

## Thuật toán bắt buộc

```text
n = oldDayTag(day)
if day >= FOUNDATION:
    n += 1
if day == FOUNDATION and n != 1:
    n = 1
return n
```

Giữ nguyên cả điều kiện bảo vệ riêng Ngày Nền dù thừa.
Hàm sai cũ tiếp tục được gọi trực tiếp trong đường tính sản xuất.

## Đường đi sản xuất

`day_count_spaghetti` và `bootstrap_context` cùng đi qua
`Dispatcher → DayCountManager → DayTagPatch → LegacyDayTag`.
Vết nhánh context ghi cả nhánh lịch sử lẫn nhánh vá.

## Kiểm thử

- Ba hồi quy chuẩn ở giai đoạn 4 không sửa, phải đổi từ đỏ sang xanh.
- Đổi riêng kiểm thử dây nối trước đây đòi đúng giá trị sai.
- Chín kiểm thử mới: đối chứng lỗi cũ, lân cận Ngày Nền,
  tính chẵn/lẻ, số nguyên cực lớn, bước đếm, cặp context,
  cấu trúc lớp vá, chạy song song, lỗi đầu vào và bất biến SAVE.
- Dự kiến 45 kiểm thử, không lỗi.
- Khóa tên chuẩn phải tiếp tục đạt.
- Không tích hợp ngày lịch đầy đủ tại giai đoạn này.

## Commit đề xuất

Giai đoạn 5: vá nhãn ngày trên phép tính lịch sử

Giữ nguyên old_day_tag sai và thêm DayTagPatch có hai điều kiện bắt buộc,
kể cả lớp bảo vệ thừa. Sửa đầu ra qua DayCountManager, giữ các hồi quy
chuẩn, bổ sung kiểm thử biên và bảo toàn trạng thái riêng mỗi lần gọi.
