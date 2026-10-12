# Giai đoạn 29 — Bản vá 14: ghép hạng rộng và detour cùng vòng

## Xuất phát

Stage28 đóng EXPECTED_RED tại commit `a1633d5045a64ee2e1a45cbbe445f2f8e310856e`.
CI 374 kiểm thử, đúng 4 sai lệch rộng; khóa tên chuẩn PASS.

## Bản vá sản xuất

`WideDetourPatch` chọn k nhỏ nhất với M^k>=N, ghép k chữ số
`answer_at(stream,j)-1` theo little-endian thành wide0 từ 1..M^k.
Ngưỡng limit=floor(M^k/N)*N. Nếu wide0<=limit, trả
1+mod(wide0-1,N). Nếu wide0>limit, tiếp tục +/-1 trên
chính vòng rộng, không tái khởi tạo seed hoặc answer ring.

Để tránh hàng tỷ tỷ bước ở N rất lớn, phép detour được tính
chính xác về mặt toán học: hướng -1 dừng tại limit sau
wide0-limit bước, hướng +1 vòng qua M^k và dừng tại 1
sau M^k-wide0+1 bước. Kết quả và số bước tương đương hoàn toàn
với thuật toán tuần tự. Hàm `diagnose/2` cung cấp bằng chứng.

`AnswerStreamManager.choose_rank` dùng ShortRejectionPatch
cho N<=M và WideDetourPatch cho N>M. Không sửa nhánh short.
LegacySingleDigitWidePick giữ nguyên sai số lịch sử.
Không sửa oracle test-only hoặc nguồn định danh.

## Kiểm thử

Giữ nguyên bốn expected chuẩn của Stage28 (đổi sang xanh).
Các điều khiển Stage28 chỉ chuyển việc quan sát hành vi sai sang
module legacy và xác nhận đường công khai mới dùng patch.

19 bài test mới kiểm tra ranh giới M, M², M³, little-endian,
hai chiều, detour qua cuối vòng, số bước cực lớn, ngày 2048-bit,
N 2048-bit, API thực, chạy đồng thời, hồi quy short, bất biến
di sản và đối chiếu oracle test-only.

## Đóng giai đoạn

Đợi GitHub Actions với Elixir 1.18.5 / OTP 27,
393 kiểm thử (374+19), 0 lỗi, 0 cảnh báo và
Canonical Names Lock PASS trước khi nâng LAST_COMPLETED_STAGE.
Không sửa main. Không commit HANDOFF_*. Không tích hợp lịch.
