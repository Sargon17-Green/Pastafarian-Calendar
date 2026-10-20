# Giai đoạn 43 — PATCH21: sửa chốt phân hoạch cốt-lết

## Xuất phát
Stage42 đã đóng EXPECTED_RED ở commit
`28712f6e8dcbcc433a14f8632b6f327a3a1d2af8`;
653 bài, đúng bốn nhóm normative đỏ do rank lấy từ chốt20.
LegacyCutletPartitionCountSeal được giữ nguyên và hoạt động thật.

## Sửa lỗi
CutletPartitionSealPatch.diagnose(c,first_day,count) gọi
LegacyCutletPartitionCountSeal.choose_rank để lưu legacy_rank,
sau đó hỏi lại Dispatcher.answer_stream(c,first_day,2,21)
và chọn corrected_rank qua AnswerStreamManager.
CutletPartitionManager chọn phân hoạch theo corrected_rank,
ghi lại hạng cũ và trạng thái changed. Không sửa các thuật toán
đếm DP hoặc unrank từ điển, cổng nội bộ bắt buộc, năm đích,
số cốt-lết hoặc cấu trúc dữ liệu.

Bốn nhóm expected chuẩn Stage42 giữ nguyên. Hai kiểm soát
Stage42 được đổi để kiểm toán tuyến legacy và patch, không che
kết quả chuẩn. Thêm 20 bài Stage43 về hạng di sản/chốt21,
đếm, mở hạng, cổng bắt buộc, kết quả oracle ở nhiều ngày,
tính bất biến, chạy song song và kiểm toán nguồn.

Dự kiến 673 bài GREEN, 0 compiler warnings và Canonical Names
Lock PASS. Không sửa main, oracle, các PATCH01..20 hoặc
tích hợp ngày lịch cuối; không commit HANDOFF_*.
