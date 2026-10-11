# Phần thay đổi giai đoạn 7 — Bản vá 03

## Điểm bắt đầu và giới hạn

Commit đóng giai đoạn 6: `a4601f67bb526329efd515d6bca297f354b81417`.
CI giai đoạn 6 có 55 kiểm thử và đúng bốn hồi quy cố ý đỏ.
Không sửa `LegacyDistance`, `DayTagPatch` hay `SavePatch`.
Chỉ hoàn thành bản vá 03, chưa bắt đầu giai đoạn 8.

## Công thức lịch sử giữ lại

```text
oldDistance(c,t) = abs(dayTag(c) - dayTag(t))
```

## Bản vá bắt buộc

```text
legacy = oldDistance(c,t)
chronological = abs(t-c)
if legacy != chronological:
    legacy = chronological
distance = legacy + 1
```

Mã Elixir dùng `DistancePatch.distance_patch/2`, bảo đảm gọi hàm
lịch sử thật trước khi chọn khoảng cách cơ sở. Không dùng tham chiếu
chỉ dành cho kiểm thử trong mã sản xuất.

## Tuyến thực thi

`distance_spaghetti → Dispatcher.distance → DistanceManager.calculate
→ DistancePatch.distance_patch → LegacyDistance.old_distance →
DayCountManager.tag → DayTagPatch.day_tag_patch → LegacyDayTag.old_day_tag`.

Trong `bootstrap_context`, kết quả lưu ở `distance_count`, giữ
các metric phi ngữ nghĩa cho legacy và bản vá, không có trạng thái
có thể thay đổi dùng chung giữa các lần gọi.

## Kiểm toán kiểm thử

- Không đổi bốn hồi quy chuẩn ở giai đoạn 6.
- Đổi chỉ các xác nhận nối dây của giai đoạn phát hiện vốn đòi kết
  quả sai từ đầu ra công khai; giữ kiểm tra lỗi cũ tại LegacyDistance.
- Mười kiểm thử mới: nhánh giữ, nhánh sửa, lưới quanh Ngày Nền,
  số nguyên lớn, tính đối xứng, kiểm toán hàm lịch sử,
  phân tầng đường gọi, thực thi song song, đầu vào không hợp lệ
  và tính bất biến của các bản vá trước.
- Kỳ vọng: 65 kiểm thử, 0 lỗi; khóa tên chuẩn PASS.
- Không tích hợp lịch cuối ở giai đoạn này.

## Tiêu đề commit

Giai đoạn 7: vá khoảng cách theo trục thời gian

## Nội dung commit

Giữ phép trừ nhãn ngày sai và đặt lớp so sánh khoảng cách thời gian
ở trên nó. Giữ nguyên bốn hồi quy chuẩn, bổ sung kiểm thử hai nhánh,
biên và đồng thời; chỉ làm việc trên nhánh Elixir tiếng Việt.

## Kiểm chứng cuối cùng

- Commit triển khai: `17ea07f3640583df0fda3fb33daa35f9e80fd6b8`.
- Commit phân loại lại ca thử: `321ba9998038b16c5400a1690361887d809fd27b`.
- Lần chạy đầu: 65 kiểm thử, 1 lỗi ở kiểm thử mới, do
  cặp cùng một ngày được xếp sai vào nhánh sửa.
- Lần chạy sau: 65 kiểm thử, 0 lỗi, 0 cảnh báo biên dịch.
- Elixir 1.18.5, Erlang/OTP 27.
- Bốn hồi quy chuẩn của giai đoạn 6 không đổi và đều đạt.
- Mã `LegacyDistance` vẫn có blob SHA
  `2807e3922d930f954ebdd952320de2ebf1e3017e`.
- Khóa tên chuẩn PASS, các bản vá 01/02 không thay đổi.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155925314
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155925331

Trạng thái đóng giai đoạn 7: GREEN. Giai đoạn 8 chưa bắt đầu.
