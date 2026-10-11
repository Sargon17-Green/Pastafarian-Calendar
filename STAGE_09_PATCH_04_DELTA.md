# Phần thay đổi giai đoạn 9 — Bản vá 04

## Điểm bắt đầu

Commit đóng giai đoạn 8: `9f9fd46e9da4639134c8e6a6937edd5859f4d44f`.
CI giai đoạn trước: 77 kiểm thử, đúng bốn hồi quy đỏ có chủ đích.
Mọi thay đổi dưới đây thuộc PATCH 04; không thêm DISCOVERY 05.

## Bảo toàn vết lịch sử

Giữ nguyên `LegacyStoneMutation.mutate_stones_wrong/2`, bao gồm
năm lần ghi nối tiếp khiến các phép tính sau đọc kết quả mới.
Không sửa, tối ưu bỏ, thay thế hoặc coi lời gọi legacy chỉ là giả lập.

## Trình tự bắt buộc của bản vá

1. Nhận hàng cũ `previous_row` cùng chỉ số hàng `index`.
2. Chụp `old_snapshot` gồm đủ năm giá trị cũ, theo đúng thứ tự.
3. Tạo `legacy_clone` độc lập về quyền sở hữu từ snapshot.
4. **Thực sự chạy** `LegacyStoneMutation.mutate_stones_wrong(legacy_clone, index)`
   và nhận tuple trung gian `garbage`.
5. Ghi đè cả năm ô trong tuple trung gian bằng công thức chỉ đọc
   `old_snapshot`; không ô nào đọc kết quả đã ghi trong cùng hàng.
6. Trả tuple đã vá, không giữ `garbage` trong trạng thái ngữ nghĩa.

Công thức sửa cho hàng cũ `(w,b,s,m,r)`:

```text
w_new = SAVE(w*w + 3*b + index)
b_new = SAVE(b*b + 5*s + w)
s_new = SAVE(s*s + 7*m + b)
m_new = SAVE(m*m + 11*r + s)
r_new = SAVE(r*r + 13*w + m)
```

Tất cả giá trị bên phải đều lấy từ ảnh chụp hàng cũ.

## Đường sản xuất

`stones_table_spaghetti → Dispatcher.stones_table → StoneManager.build_table
→ StonePatch.patch_row → LegacyStoneMutation.mutate_stones_wrong`.

`bootstrap_context` cũng xây cùng bảng 46 hàng qua `StoneManager`.
Các nhánh SAVE, nhãn ngày và khoảng cách từ các bản vá trước được giữ.
Mã sản xuất không gọi hoặc nhập `TestOnly.NormativeReference`.

## Thay đổi kiểm thử giai đoạn 8

Giữ nguyên toàn bộ bốn hồi quy chuẩn của giai đoạn 8, để chúng
chuyển đỏ thành xanh khi bản vá thực sự hoạt động. Chỉ điều chỉnh
các kiểm thử dây nối từng khẳng định đầu ra sai là kết quả công khai:
chúng nay khẳng định trực tiếp legacy vẫn sai, trong khi
`StoneManager` và API công khai trả kết quả chuẩn.

## Kiểm thử bổ sung

Tệp `test/stage_09_patch_04_test.exs` bổ sung 11 kiểm thử:
- Hàng thứ hai và cả năm vị trí.
- Mọi hàng từ 1 đến 46 đối chiếu oracle.
- Công thức độc lập của từng ô, chỉ đọc hàng cũ.
- Lời gọi legacy thật và kết quả sai còn quan sát được riêng.
- Đầu vào với số nguyên hơn 2048 bit.
- Không nhiễm giữa ba vị trí cuối.
- Kiểm tra nguồn và tất cả năm lần ghi đè.
- Ngữ cảnh độc lập theo ngày.
- Thực thi nhiều yêu cầu song song.
- Lỗi đầu vào.
- Bảo toàn ba bản vá cũ và biên lịch cuối chưa tích hợp.

Dự kiến **88 kiểm thử, 0 lỗi**, không cảnh báo biên dịch.
Khóa tên chuẩn phải đạt độc lập. Không sửa danh mục tên.

## Trạng thái kiểm chứng

Mã được áp dụng trên nhánh Elixir tiếng Việt. Giai đoạn chưa được
đóng cho đến khi CI chạy xanh và bằng chứng cuối cùng được xác minh.

## Commit triển khai dự kiến

Giai đoạn 9: vá cập nhật đá bằng ảnh chụp hàng cũ

Giữ nguyên phép cập nhật nối tiếp lịch sử, thực sự gọi nó trên
một bản sao rồi ghi đè năm giá trị từ snapshot. Giữ bốn hồi quy
chuẩn không đổi, bổ sung kiểm thử biên, số lớn và quyền sở hữu ngữ nghĩa.

## Kết quả thực tế được kiểm chứng

- Commit triển khai `75d703a08cd4ed44c4beeb13713cb6a973f1c8dc`.
- 88 kiểm thử, 0 lỗi, 0 cảnh báo biên dịch.
- Môi trường: Elixir 1.18.5, Erlang/OTP 27.
- Cả bốn hồi quy chuẩn từ giai đoạn 8 vẫn giữ nguyên và nay đạt.
- 11 kiểm thử mới đã đạt, bao gồm số nguyên 2048 bit,
  tính độc lập song song và đối chiếu đủ 46 hàng.
- Khóa tên chuẩn PASS.
- `LegacyStoneMutation` giữ nguyên blob SHA
  `91260b89961571e9c96a0f0e563c27115c1aa697`.
- Bốn tệp mã và kiểm thử khớp với bản bàn giao đã chuẩn bị.
- Không thay đổi main, không đưa lỗi giai đoạn 10 vào trước.

Kiểm thử: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38159415842
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38159415828

Trạng thái kết thúc giai đoạn 9: GREEN đã được xác minh.
Điểm tiếp theo: giai đoạn 10, DISCOVERY 05, chưa được khởi động.
