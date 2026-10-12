# Giai đoạn 30 — Phát hiện 15: độ dài cổng âm bị phản chiếu qua Ngày Nền

## Mốc xuất phát
Giai đoạn 29 đóng GREEN tại commit `017ae9b954dadd62794adfb6d7246c116ebd1735`.
393/393 kiểm thử PASS và Canonical Names Lock PASS.

## Giao diện production mới và lỗi lịch sử
Cổng 0 có ngày FOUNDATION=-15_055_671.
Với n>=1, gap dương chuẩn là 41+choose_rank(ask_bowl(sauce(F,F+n),1,1),922).
Cổng n tính từ cổng n-1 bằng cách cộng gap(n).
Cổng âm -n tính từ cổng -(n-1) bằng cách trừ gap âm n.

LegacyMirroredNegativeGateGap sai có chủ đích: gọi
sauce(F,F+n) thay vì sauce(F,F-n). Vì vậy gap âm sao chép
gap dương. Đường production đi qua GateGapManager.negative_gap
và GateTimelineManager thực; lỗi không nằm riêng trong test.
Hàm legacy phải giữ nguyên khi sang PATCH 15 (Stage31).
Không dùng oracle test-only trong production.

## Phạm vi và bảo toàn
Không thay SAVE, hạt answer ring, chiều, wide detour, 46 giọt,
12 lần khuấy, ID bát hoặc thứ tự. Cấu trúc state cổng bất biến,
lưu chỉ số âm và dương, không có trạng thái toàn cục.
Chưa tìm năm 5000 hoặc cấu trúc năm; API ngày lịch vẫn báo
StageNotIntegratedError.

16 bài điều khiển mới chứng minh neo, gap/cổng dương chuẩn,
đường legacy âm còn sai, truy vấn hai chiều, giới hạn 42..963,
state độc lập, đa luồng, lỗi đầu vào và không có patch 15.
Bốn hồi quy normative cố ý đỏ tại các cổng -1, -2, -3, -4.
Dự kiến 413 bài, đúng bốn lỗi đỏ và tất cả 393 bài cũ xanh.

## Điều kiện đóng
Kiểm chứng CI Elixir 1.18.5 / OTP 27 và Canonical Names Lock;
nếu có thêm sai lệch ngoài bốn cổng âm, không đóng giai đoạn.
Không sửa nhánh main, không commit HANDOFF_*.

## Kết quả CI được xác minh

Giai đoạn 30 DISCOVERY 15 đã được xác minh qua GitHub Actions Elixir 1.18.5 / OTP 27.
413 kiểm thử: 409 PASS, đúng bốn sai lệch normative đỏ tại cổng -1,-2,-3,-4.
Không có cảnh báo biên dịch Elixir; Canonical Names Lock PASS.
Bốn kết quả legacy và oracle lần lượt:
-1: -15056016 / -15056174;
-2: -15056834 / -15056615;
-3: -15057665 / -15056944;
-4: -15057883 / -15057703.
16 điều khiển Stage30 và 393 bài cũ đều đạt.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38289526828
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38289526872
Không sửa main, không sửa oracle hoặc các lớp lỗi cũ.
Đóng Stage30 EXPECTED_RED; tiếp theo Stage31 PATCH 15 chưa bắt đầu.
