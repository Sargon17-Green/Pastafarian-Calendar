# Phần thay đổi riêng giai đoạn 8 — Phát hiện 04

## Nguồn gốc và giới hạn

Điểm bắt đầu: commit đóng giai đoạn 7
`27803b2538d8466da4c386cbf0fee0f70c5b7360`.
CI trước đó: 65 kiểm thử, 0 lỗi, khóa tên chuẩn đạt.
Giai đoạn 8 chỉ phát hiện lỗi cập nhật bảng đá liên tiếp.
Không đưa vào bản vá 04, không trộn giai đoạn 9.

## Công thức chuẩn để làm đối chứng kiểm thử

Hàng đầu là `{17,29,43,71,101}`. Với hàng cũ `{w,b,s,m,r}`
và chỉ số hàng `i`, năm kết quả chính xác phải là:

```text
w' = SAVE(w*w + 3*b + i)
b' = SAVE(b*b + 5*s + w)
s' = SAVE(s*s + 7*m + b)
m' = SAVE(m*m + 11*r + s)
r' = SAVE(r*r + 13*w + m)
```

Tất cả giá trị sau dấu cộng là của **hàng cũ**.

## Giả định lịch sử sai cố ý

`LegacyStoneMutation.mutate_stones_wrong(row,i)` dùng cùng
năm phép tính nhưng đọc từ tuple đang được cập nhật:

```text
w' = SAVE(w*w + 3*b + i)
b' = SAVE(b*b + 5*s + w')
s' = SAVE(s*s + 7*m + b')
m' = SAVE(m*m + 11*r + s')
r' = SAVE(r*r + 13*w' + m')
```

Những giá trị sai này được cam kết vào hàng kế tiếp, khiến sai số
lan đến hàng 46. Không chụp snapshot `old` và không sửa bằng oracle.

## Đường thực thi sản xuất

- `StoneManager.build_table` tạo đủ 46 hàng từ hàng đầu cố định.
- Mọi hàng sau gọi `LegacyStoneMutation.mutate_stones_wrong`.
- Từng phép tính gọi `SaveManager.calculate`, sử dụng bản vá 01 đã hoàn thành.
- `Dispatcher.bootstrap` lưu bảng tính sai ở `Context.stones_table`.
- Hai API `stones_table_spaghetti` và `stone_row_spaghetti`
  cũng đi vào cùng bộ quản lý.
- Không thay đổi ba bản vá trước hoặc kết quả ngày lịch chưa tích hợp.

## Đối chứng và hồi quy

- Hàng 1: vẫn trùng với chuẩn.
- Hàng 2, vị trí 1: 378, vẫn trùng chuẩn.
- Hàng 2, vị trí 2: 1434, khác 1073 theo chuẩn.
- Hàng 2, vị trí 3: 3780, khác 2375 theo chuẩn.
- Hàng 3, vị trí 1: sai lệch dây chuyền.
- Hàng 46: sai lệch toàn bộ tuple.

12 kiểm thử mới, bốn hồi quy chuẩn phải đỏ, tám kiểm thử bảo vệ
phải xanh. Tổng dự kiến: 77 kiểm thử, 4 thất bại, 73 đạt.
Khóa tên chuẩn phải đạt độc lập. Không sửa kỳ vọng oracle chuẩn.

## Bản vá kế tiếp (không được thực hiện ở đây)

Giai đoạn 9 sẽ lấy snapshot của hàng `old`, gọi hàm sai thật
trên bản sao để thu `garbage`, rồi ghi đè đủ năm ô bằng công thức
chỉ đọc các giá trị của `old`. Không xóa lần gọi legacy.

## Tiêu đề commit

Giai đoạn 8: phát hiện cập nhật đá nối tiếp sai

## Nội dung commit

Đưa LegacyStoneMutation vào đường xây bảng đá 46 hàng và
bootstrap. Thêm các đối chứng hợp lệ và bốn hồi quy chuẩn cố ý
thất bại; giữ ba lớp vá trước và không khởi động PATCH 04.
