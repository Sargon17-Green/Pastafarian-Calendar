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

## Kết quả CI đã xác minh

Stage38 DISCOVERY19 đã xác minh trên Elixir 1.18.5 / OTP 27:
biên dịch 65 tệp .ex, **573 bài, 569 PASS, đúng 4 hồi quy
normative đỏ**, không có warning trình biên dịch Elixir.
Canonical Names Lock độc lập PASS. Bốn sai lệch đều ở ngày
đúng cổng đóng năm 5000 tại c=FOUNDATION, +1, +417, -539.
18 kiểm soát Stage38 và toàn bộ 551 bài cũ đạt.
LegacyUpperBoundaryBelongsToNextYear trả :next_at_upper_boundary
khi target==close; không có TargetYearBoundaryPatch.
Lần CI ban đầu có hai lỗi điều khiển biên kép và một cảnh báo
alias, đã sửa riêng trong commit f5f20fcbe0e6731f2ddaf70637dc64ce672d5ba7,
không thay bốn expected normative.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39220862669
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39220862708
Stage38 đóng EXPECTED_RED; Stage39 PATCH19 chưa bắt đầu.
Không đổi main, oracle hoặc những bản vá cũ.
