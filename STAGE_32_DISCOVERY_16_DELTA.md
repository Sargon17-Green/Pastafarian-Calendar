# Giai đoạn 32 — DISCOVERY 16: đảo ưu tiên năm neo 5000

## Nền
Stage31 đóng GREEN ở commit `6a61b01f0771d7cbdbaff31f4880076981f94eb3`
với 431/431 PASS. Không mở giai đoạn 33 trước xác minh Stage32.

## Những phần đúng
Year5000CandidateManager phủ c-5778..c+5778 trên GateTimelineManager
đã chuẩn, liệt kê cặp i<j, ít nhất 6 khoảng, độ dài 252..5778,
và gate(i)<c<=gate(j). Không lặp cặp, không làm mất chỉ số âm.
Year5000Manager hỏi Dispatcher.answer_stream(c,c,1,10), chọn rank
qua AnswerStreamManager. Giá trị year.number=5000 và các ngày biên
được trả dưới Monster.Year; không gọi oracle test-only.

## Di sản lỗi 16
LegacyLongestFirstYear5000.sort đặt độ dài giảm dần
`{-candidate.length,candidate.open_gate_day}`.
Chuẩn bắt buộc tăng dần theo `{length,open_gate_day}`.
Vì vậy tập ứng viên, phạm vi cửa sổ và rank đều đúng;
chỉ ánh xạ rank sang ứng viên bị sai trên đường production thực.
Stage33 phải giữ legacy và gọi nó qua lớp patch riêng, không
sửa hàm legacy tại chỗ.

## Kiểm chứng
20 kiểm thử Stage32: 16 kiểm soát nguồn cổng, lọc ứng viên,
giao diện, rank, tính bất biến và thiếu patch 16;
4 hồi quy normative cố ý đỏ với c = FOUNDATION, FOUNDATION+1,
FOUNDATION+417, FOUNDATION-539. Không sửa oracle hay PATCH 01..15.
Dự kiến 451 kiểm thử, đúng bốn hồi quy đỏ và 0 compiler warnings.
Đóng chỉ khi CI xác minh, Canonical Names Lock PASS.
Không thay main; không tạo lịch hoàn chỉnh.

## Kết quả chạy CI

Giai đoạn 32 DISCOVERY 16 đã xác minh Elixir 1.18.5 / OTP 27
trên GitHub Actions: biên dịch 54 tệp .ex,
**451 kiểm thử, 447 PASS, đúng bốn hồi quy normative sai cố ý**,
không cảnh báo biên dịch Elixir. Canonical Names Lock PASS.
Bốn fixture c=FOUNDATION, FOUNDATION+1, FOUNDATION+417,
FOUNDATION-539 đều trả cặp chỉ số cổng sai do xếp độ dài giảm dần.
393+38 bài từ các giai đoạn trước (431 bài Stage1..31)
và 16 kiểm soát Stage32 đều xanh.
Không thay oracle test-only, Year5000CandidateManager hoặc các patch 01..15
để che sai lệch. Không tích hợp tìm năm mục tiêu hoặc lịch cuối.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38565791324
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38565791544
Cảnh báo Node.js 20 từ checkout@v4 là cảnh báo nền tảng, không phải Elixir.
Đóng Stage32 EXPECTED_RED. Stage33 PATCH 16 chưa bắt đầu.
