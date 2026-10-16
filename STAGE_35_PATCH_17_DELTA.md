# Giai đoạn 35 — PATCH 17: sửa ngày hỏi năm kế tiếp

## Xuất phát
Stage34 đóng EXPECTED_RED tại `9af83f54984d4c35d787ddcc8f95fac753175dd4`,
491 bài với đúng bốn hồi quy normative đỏ. NextYearCandidateManager,
Year5000Manager, GateTimelineManager và oracle test-only đều chuẩn.

## Thực thi
Tạo NextYearSeedPatch. Lớp vá gọi thật
LegacyCurrentDayNextYearSeed.choose_rank(c,count)
để giữ bằng chứng lịch sử chọn source_day=c sai. Sau đó gọi
Dispatcher.answer_stream(c,open_day,1,11),
AnswerStreamManager.choose_rank(stream,count), trả corrected_rank.
Open_day là ngày đóng của năm đã biết. Diagnostic ghi cả hai rank,
hai nguồn ngày, cờ changed, bowl/seal và số ứng viên.

NextYearManager giữ nguyên tập ứng viên, gate state, số năm 5001
và lựa chọn rank one-based, chỉ thay rank legacy bằng rank chuẩn.
Bốn hồi quy normative Stage34 không thay expected, 20 bài Stage35
mở rộng các phép đối chiếu cổng, ứng viên, oracle, trạng thái bất biến,
đồng thời, trace legacy và đầu vào sai.

Dự kiến 511 bài, không thất bại, Canonical Names Lock PASS.
Không sửa main, không commit HANDOFF_*, chưa tích hợp ngày lịch cuối.
