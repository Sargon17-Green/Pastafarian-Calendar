# Giai đoạn 38 — DISCOVERY 19: sai quy tắc cổng đóng trong tìm năm đích

Stage37 PATCH18 đóng GREEN: 551/551 PASS, Canonical Names Lock PASS.
Tìm năm đích đi từ năm neo 5000, qua NextYearManager hoặc
PreviousYearManager đã được sửa. Năm hợp lệ có đoạn (open,close]:
ngày đúng cổng mở thuộc năm trước; ngày đúng cổng đóng vẫn
thuộc năm hiện tại.

Lỗi lịch sử: LegacyUpperBoundaryBelongsToNextYear.route trả
:next_at_upper_boundary khi target==close, thay vì :found.
TargetYearManager áp dụng quyết định sai vào production và trả
năm kế trực tiếp tại biên, không tự dao động với năm trước.
Đây là sai lệch chọn năm tại ranh giới, không phải cổng, rank,
nguồn ngày, hạt hay tập ứng viên.

Thêm 22 bài Stage38: 18 điều khiển hai hướng, nhiều bước,
state, biên mở, truy vấn lặp lại và kiểm toán nguồn; 4 so sánh
normative cố ý đỏ tại c=FOUNDATION, +1, +417, -539 với target
đúng cổng đóng năm 5000. Dự kiến 573 bài, đúng 4 lỗi có
chủ đích. Stage39 phải giữ legacy và vá tuyến điều hướng riêng.
Không thay main, không sửa oracle, không commit HANDOFF_*.
