# Giai đoạn 41 — PATCH 20: trả thứ tự số cốt-lết tăng dần

## Di sản được bảo toàn
Stage40 DISCOVERY20 đóng EXPECTED_RED tại commit
`540f8c925ca767d56a51ea8e9b660d251c014a86`.
613 kiểm thử, 609 PASS và đúng bốn nhóm normative đỏ.
LegacyDescendingCutletCount.sort vẫn sắp thứ tự giảm dần,
không được sửa bất kỳ byte nào trong Stage41.

## Bản vá
AscendingCutletCountPatch.diagnose(candidates) gọi thật
LegacyDescendingCutletCount.sort(candidates), giữ
historical_order; sau đó dùng Enum.sort(historical_order)
trả corrected_order tăng dần. CutletCountManager dùng đúng
rank đã xác định từ sauce(c,open_day+1), bowl 2/chốt 20
nhưng chọn từ corrected_order; vẫn giữ toàn bộ dấu vết cũ.
Tập ứng viên, số cổng, năm đích và trạng thái không đổi.

Bốn nhóm normative Stage40 giữ expected gốc. Hai kiểm soát
về production và file patch được cập nhật, không sửa oracle.
20 kiểm thử Stage41: trùng các hạt năm, biên trên, năm trước/sau,
bảng gate, đồng thời, thứ tự, bất biến, tham chiếu test-only
và kiểm toán các thành phần lịch sử.
Mục tiêu 633/633 bài GREEN, Canonical Names Lock PASS.
Không sửa main, không tích hợp lịch hoàn chỉnh.

## Kết quả xác minh

Elixir 1.18.5 / OTP27: biên dịch 69 tệp .ex,
**633/633 kiểm thử PASS, 0 lỗi, không compiler warnings**.
Bốn hồi quy normative Stage40 giữ expected, tất cả xanh.
Canonical Names Lock PASS. Di sản và oracle test-only không đổi.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39298935288
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39298935385
Stage41 đóng GREEN, Stage42 DISCOVERY21 chưa bắt đầu.
