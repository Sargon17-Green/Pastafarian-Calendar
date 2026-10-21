# Giai đoạn 45 — PATCH22: sửa hạng chọn tên cốt-lết

## Trạng thái xuất phát
Stage44 DISCOVERY22 đóng EXPECTED_RED tại
`05974ffd5371ed72d27ad6f222e58c046ea1baad`.
GitHub Actions chạy 693 bài, đúng bốn sai lệch normative ở tên.

## Bản vá
CutletNameRankPatch.diagnose gọi thật
LegacyRotatedCutletNameRank.choose_rank để giữ historical_rank.
Sau đó dùng Dispatcher.answer_stream(c,first_day,5,22) và
AnswerStreamManager.choose_rank(stream,count) để lấy
corrected_rank một-based. CutletNameIndexManager mở hạng
DistinctCutletNameIndices.unrank(17,k,corrected_rank), giữ
rank_was_corrected và historical_rank trong báo cáo.
Không chỉnh các thành phần legacy, oracle test-only, năm,
số cốt-lết, phân hoạch, source_day, P(17,k), hoặc lexicographic.

Bốn nhóm normative Stage44 giữ nguyên expected và dự kiến
xanh trở lại; hai điều khiển kiểm toán của Stage44 được cập
nhật để xác nhận cả legacy và production. Thêm 20 bài Stage45
về các mốc trước/sau Foundation, cổng đóng, rank lịch sử,
tính duy nhất, song song, bất biến và kiểm toán source.
Mục tiêu 713 bài, không lỗi, không compiler warnings, cùng
Canonical Names Lock PASS. Không sửa main và không thêm
HANDOFF_* vào repo. Chưa tích hợp lịch hoàn chỉnh.
