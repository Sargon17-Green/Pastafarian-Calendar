# Giai đoạn 36 — DISCOVERY 18: dùng nhầm chốt năm sau cho năm trước

## Mốc
Stage35 đóng GREEN tại `55e0d26eafc8df0d4d1105862eed9f860eea2b30`.
511 bài PASS; Canonical Names Lock PASS.

## Kiến trúc và lỗi lịch sử
PreviousYearCandidateManager tìm cổng mở của năm 4999 với cổng đóng
trùng cổng mở của năm 5000, mở gate xuống close_day-5778,
chỉ giữ ít nhất 6 khoảng với độ dài 252..5778 ngày,
và xếp ứng viên theo độ dài tăng. PreviousYearManager dùng
cặp ngày (c,close_day) đúng nhưng thông qua
LegacyNextYearSealForPreviousSeed hỏi bowl 1 / seal 11,
trong khi oracle dùng bowl 1 / seal 12. Rank sai được chọn
trên đường production thật. Không dùng oracle ở production.

Stage37 PATCH 18 phải giữ nguyên legacy này và sửa bằng lớp riêng;
không sửa những PATCH trước, candidate hay nguồn ngày.

## Kiểm chứng
Thêm 16 kiểm thử điều khiển và 4 hồi quy normative có chủ đích đỏ.
CI trên commit `55aa015bc956c9cf31889504c17f2c92210bfc18`:
**531 kiểm thử, 527 PASS, đúng 4 thất bại EXPECTED_RED**
trong bốn nhóm chuẩn năm 4999; không có lỗi khác,
không cảnh báo biên dịch Elixir. Canonical Names Lock PASS.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38915227760
- Tên chuẩn: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38915227891

Không thay nhánh main, không sửa oracle test-only, không đưa HANDOFF_* vào GitHub.
