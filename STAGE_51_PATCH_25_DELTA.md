# Giai đoạn 51 — PATCH25: khôi phục hạng độ dài tháng

## Chứng cứ bắt đầu
Stage50 DISCOVERY25 đã xác minh EXPECTED_RED:
813 bài, 809 PASS và đúng bốn nhóm normative RED,
không warnings, Canonical Names Lock PASS.
Commit đóng Stage50: a3b404fd9d077398a761b7f499aa12aad1d7f1b6.

## Sửa sai
MonthLengthsRankPatch.diagnose gọi thật
LegacyMirroredMonthLengthsRank.transform(rank,N), ghi
historical_rank=N-rank+1, rồi gọi lại chính di sản để
khôi phục corrected_rank=rank. MonthLengthsManager tiếp
tục chọn N bằng BoundedMonthCompositions.count,
hỏi bowl3/seal31 với cùng source_day, mở hạng corrected_rank
và giữ historical_month_lengths tương ứng historical_rank.

Bốn nhóm normative Stage50 giữ kỳ vọng nguyên bản; các
kiểm soát production được cập nhật có dấu vết lịch sử.
Thêm 20 bài Stage51 về chuẩn độc lập, hạng rộng, dữ liệu
không đổi, cổng năm, bất biến lần lặp và xử lý lỗi.
Mục tiêu 833 bài GREEN, Canonical Names Lock PASS,
không warnings. Không sửa main, oracle hoặc di sản.
