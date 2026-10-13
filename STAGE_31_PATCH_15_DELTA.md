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

## Kết quả kiểm chứng và đóng

Giai đoạn 31 PATCH 15 được xác minh bằng CI trên Elixir 1.18.5, OTP 27
tại commit `274c153e7d24fb578c5835648ba14af46a3a080e`.
Biên dịch 50 tệp .ex, **431/431 kiểm thử PASS**, 0 lỗi và
không cảnh báo biên dịch Elixir; Canonical Names Lock PASS.
Giữ nguyên blob SHA của LegacyMirroredNegativeGateGap
`f83ed6a47550dd9c4306146d09ab48d50ab81caf`,
oracle test-only `be1638f46b2190d617af0378a61b077bda10bf32`.
Cảnh báo Node.js 20 thuộc checkout@v4 của CI, không phải nguồn Elixir.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38367321898
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38367321846
Stage31 đóng GREEN. Stage32/55 DISCOVERY 16 chưa bắt đầu.
Không đổi main; không nhập oracle vào production.
