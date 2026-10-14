# Giai đoạn 34 — DISCOVERY 17: sai ngày hỏi khi chọn năm kế tiếp

## Xuất phát
Stage33 đóng GREEN (PATCH 16) bằng CI 471/471 PASS tại commit
`e78a676032b3f144ad2f9456243941e633728fe4`;
mã legacy chọn năm 5000 dài-trước đã được giữ nguyên.

## Phần đúng
NextYearCandidateManager lấy open_index từ close_index năm 5000,
mở rộng gate đến open_day+5778, loại cặp dưới 6 khoảng hoặc
ngoài độ dài 252..5778, và sắp ứng viên theo độ dài tăng.
NextYearManager dùng bowl 1, seal 11, lấy rank 1-based,
trả cấu trúc Year có số 5001 và hai ngày cổng. Không tích hợp
tìm năm mục tiêu hay ngày lịch hoàn chỉnh.

## Lỗi legacy mới
LegacyCurrentDayNextYearSeed hỏi Dispatcher.answer_stream(c,c,1,11).
Oracle chọn rank trên stream từ sauce(c,open_day),
với open_day là cổng đóng của năm đã biết.
Đây là lỗi sai ngày hỏi, không phải lỗi tập ứng viên hoặc cổng.
Stage35 PATCH 17 phải giữ legacy và gọi nó thật, rồi chọn rank chuẩn.

20 kiểm thử Stage34 gồm 16 điều khiển và 4 hồi quy normative cố ý đỏ
tại c=FOUNDATION, FOUNDATION+1, FOUNDATION+417, FOUNDATION-539.
Giữ nguyên PATCH 01..16, oracle, Year5000Manager và gate.
Dự kiến 491 bài, đúng 4 sai lệch mới, 0 compiler warnings,
và Canonical Names Lock PASS. Không sửa main, không commit HANDOFF_*.
