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
