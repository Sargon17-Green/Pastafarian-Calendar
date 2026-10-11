# Thay đổi riêng giai đoạn 6 — Phát hiện 03

## Điểm bắt đầu

Commit khép giai đoạn 5: `75e85839a6c38b68f8db337107a71644b37ae89a`.
Đã xác minh 45 kiểm thử, 0 lỗi, khóa tên chuẩn đạt.
Không thực hiện bản vá 03 trong commit phát hiện này.

## Công thức cũ bắt buộc

```text
oldDistance(c,t) = abs(dayTag(c) - dayTag(t))
```

Hai dayTag đi qua bản vá 02 đã có từ giai đoạn 5.
Không cộng một. Không tính hiệu thời gian để sửa lỗi.

Khoảng cách chuẩn chỉ tồn tại trong đối chứng kiểm thử:
`abs(t-c)+1`.

## Đường sản xuất

- `LegacyDistance.old_distance/2` thực thi công thức cũ thật.
- `DistanceManager.calculate/2` kiểm tra hai ngày nguyên và gọi nó.
- `Dispatcher.bootstrap/2` lưu kết quả sai vào `Context.distance_count`.
- `distance_spaghetti/2` đi qua cùng quản lý và cùng hàm cũ.
- Giữ nguyên `LegacyDayTag`, `DayTagPatch`, các bản vá 01/02,
  bộ tham chiếu chỉ dùng trong kiểm thử và khóa tên chuẩn.

## Kịch bản phân biệt

- Ngày giống nhau: 0 thay vì 1.
- Cả hai ngày sau Ngày Nền, cách nhau hai ngày: 4 thay vì 3.
- Cả hai ngày trước Ngày Nền, cách nhau hai ngày: 4 thay vì 3.
- Đi qua Ngày Nền: 1 thay vì 3.
- Đối chứng bất ngờ đúng: Ngày Nền-2 đến Ngày Nền, 3 so với 3.
- Đối chứng cùng phía: Ngày Nền+1 đến Ngày Nền+2, 2 so với 2.

## Kiểm thử và trạng thái dự kiến

- Tổng cộng 55 kiểm thử: 45 cũ và 10 mới.
- 4 kiểm thử chuẩn cố ý thất bại, 51 kiểm thử đạt.
- Không lỗi biên dịch, không hỏng hồi quy cũ.
- Khóa tên chuẩn hoàn tất thành công.
- Trạng thái lịch sử hợp lệ: EXPECTED_RED.

## Tiêu đề commit

Giai đoạn 6: phơi bày sai lệch khoảng cách giữa nhãn ngày

## Nội dung commit

Đưa phép trừ hai nhãn ngày vào đường thực thi và context.
Giữ bản vá SAVE và ngày đã hoàn thành, bổ sung bốn hồi quy
chuẩn cố ý đỏ, chưa thêm sửa khoảng cách theo thứ tự thời gian.

## Kết quả thực tế đã kiểm chứng

- Môi trường: Elixir 1.18.5, Erlang/OTP 27.
- 55 kiểm thử, đúng 4 thất bại có chủ đích, 51 đạt.
- Cùng ngày: thực tế 0, chuẩn 1.
- Hai ngày trước Ngày Nền: thực tế 4, chuẩn 3.
- Hai ngày sau Ngày Nền: thực tế 4, chuẩn 3.
- Đi qua Ngày Nền: thực tế 1, chuẩn 3.
- Không có lỗi biên dịch, không sửa kỳ vọng chuẩn.
- Khóa tên chuẩn PASS.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154864908
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154864891

Trạng thái cuối giai đoạn 6: EXPECTED_RED đã được xác minh.
Bản vá 03 chỉ được bắt đầu ở giai đoạn 7.
