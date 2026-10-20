# Giai đoạn 44 — DISCOVERY22: lệch một hạng của tên cốt-lết

## Xuất phát
Stage43 PATCH21 đóng GREEN tại commit
`418b48a4013b85959b6114fdedcca89d60d99e34`,
673/673 kiểm thử PASS, Canonical Names Lock PASS.

## Phần đúng
CutletNameIndexManager chọn số lượng tên bằng đúng số cốt-lết
từ CutletPartitionManager, giữ năm và phân hoạch đã vá. Số
lựa chọn là chỉnh hợp P(17,k), chỉ số tên là các số nguyên
phân biệt trong 1..17, thứ tự mở hạng từ điển một-based.
Nguồn sauce là (calculation_day,year.open_gate_day+1);
bát 5 và chốt 22 là chính xác.

## Sai lệch lịch sử
LegacyRotatedCutletNameRank chọn rank đúng từ answer stream
rồi sai lệch một vị trí theo `rem(chosen_rank,count)+1`:
trường hợp cuối vòng quay về đầu. Production thật mở hạng
với vị trí đã dịch sai, trong khi phép đếm và mở hạng chính xác.
Stage45 PATCH22 phải giữ nguyên di sản rồi lấy lại hạng chuẩn,
không chỉnh oracle hay thay thứ tự tên.

20 bài kiểm thử Stage44 mới gồm 16 kiểm soát kiểm toán
chỉnh hợp, lexicographic, tên phân biệt, rank, nguồn ngày,
production path và trạng thái; 4 nhóm hồi quy normative
cố ý RED ở nhiều ngày trước/sau Foundation và cổng đóng.
Mục tiêu 693 bài, đúng 4 RED, không compiler warnings,
Canonical Names Lock PASS. Không sửa main, PATCH01..21.
Không tích hợp tên hiển thị hoặc lịch cuối.

## Chứng cứ CI

Đã xác minh Elixir 1.18.5 / OTP27: biên dịch 76 tệp,
**693 bài, 689 PASS, đúng bốn normative RED**, không
compiler warnings. Bốn bài đều về rank tên cốt-lết;
16 kiểm soát mới cùng 673 bài trước đều xanh.
Canonical Names Lock PASS.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39495814532
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39495814488
Stage44 đóng EXPECTED_RED, Stage45 PATCH22 chưa bắt đầu.
