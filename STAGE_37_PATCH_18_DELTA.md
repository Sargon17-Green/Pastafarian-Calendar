# Giai đoạn 37 — PATCH 18: sửa chốt năm trước

## Di sản
Stage36 DISCOVERY18 đóng EXPECTED_RED với 531 bài, đúng
bốn nhóm hồi quy normative đỏ. LegacyNextYearSealForPreviousSeed
gọi thực Dispatcher.answer_stream(c,close_day,1,11), trái với
chốt chuẩn 12. Giữ nguyên blob legacy, oracle và các PATCH01..17.

## Bản vá
PreviousYearSealPatch.diagnose(c,close_day,count) gọi thật legacy
để lưu legacy_rank. Sau đó hỏi lại cùng hai ngày, cùng bát 1,
nhưng chốt 12, tạo corrected_rank. PreviousYearManager chọn
cổng theo corrected_rank, lưu historical_rank, và không thay
cửa sổ cổng, tập ứng viên, thứ tự hoặc năm 5000.

Các hồi quy normative Stage36 giữ expected gốc, cùng 16 kiểm
soát Stage36 sau khi cập nhật hai kiểm toán về rank và đường
production. Thêm 20 bài Stage37 về 16 mốc, cổng, rank, state,
tính tương tranh, di sản và tính toàn vẹn nguồn. Mục tiêu
551 kiểm thử GREEN, 0 compiler warnings và Canonical Names Lock PASS.

Không chỉnh main, oracle, hoặc chuyển tài liệu HANDOFF_ lên GitHub.
