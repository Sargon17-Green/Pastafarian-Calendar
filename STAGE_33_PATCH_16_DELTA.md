# Giai đoạn 33 — PATCH 16: thứ tự năm 5000 ngắn trước

## Di sản lỗi được giữ nguyên
Stage32 đóng EXPECTED_RED tại commit `8f136b33504dce9f4781bd328836df8f66a617a2`;
451 kiểm thử, đúng bốn hồi quy chuẩn đỏ tại Foundation và các mốc
+1,+417,-539. LegacyLongestFirstYear5000 vẫn đặt năm dài trước và
không được sửa bất kỳ ký tự nào trong Stage33.

## Cách vá
ShortestFirstYear5000Patch.diagnose(candidates) gọi thật
LegacyLongestFirstYear5000.sort(candidates) để lưu historical_order,
sau đó sắp chính kết quả đó theo {length,open_gate_day} tăng dần.
Báo cáo trả corrected_order, changed và số lượng ứng viên. Trong
Year5000Manager, mọi bước tạo gate, lọc ứng viên, tạo answer stream,
chọn rank từ bowl 1/seal 10 giữ nguyên. Chỉ thay phần tử được lấy
tại rank-1 từ historical_order sang corrected_order.

Bốn hồi quy normative gốc giữ nguyên expected. Hai bài kiểm soát
Stage32 được điều chỉnh để kiểm toán đường legacy và đường patch.
20 bài Stage33 mới bao gồm các tie, tính duy nhất của tập ứng viên,
đúng rank, đối chiếu oracle nhiều ngày, song song, state bất biến,
đầu vào xấu và kiểm toán mã nguồn. Dự kiến 471 bài GREEN.
Không dùng oracle trong production; không tích hợp lịch hoàn chỉnh.

## Điều kiện đóng
Elixir 1.18.5 / OTP 27 chạy đầy đủ mix test, không warning source.
Canonical Names Lock PASS. Không sửa main, không commit HANDOFF_*.
