# Giai đoạn 31 — PATCH 15: sửa nguồn ngày cổng âm

Giai đoạn 30 đóng ở commit `70613d49c51562d080a0cafe0a354cac5b6aaae0`:
413 kiểm thử, đúng bốn sai lệch normative cổng -1..-4, khóa tên PASS.

`NegativeGateGapPatch` gọi thật `LegacyMirroredNegativeGateGap`
để lưu kết quả sai, rồi tính lại khoảng cách bằng
`Dispatcher.answer_stream(FOUNDATION,FOUNDATION-n,1,1)`,
lấy `41+choose_rank(stream,922)`. Không sửa nội dung module legacy.
`GateGapManager.negative_gap` chuyển qua patch; thuật toán
`GateTimelineManager` giữ nguyên và chỉ nhận gap âm đúng.

Bốn expected normative Stage30 không sửa; hai điều khiển lịch sử
được chuyển để tách legacy sai khỏi đường production đã vá.
18 bài kiểm thử mới kiểm tra n=1..8, cổng hai hướng,
state bất biến, đồng thời, đầu vào và 2048-bit, không tích hợp
lịch hoàn chỉnh và bất biến source. Dự kiến 431 bài GREEN.
Không sửa main, không commit HANDOFF_*; phải qua CI và khóa tên.
