# Giai đoạn 50 — DISCOVERY25: phản chiếu hạng hợp thành tháng

## Điểm xuất phát
Stage49 PATCH24 đóng GREEN tại
`3e7f680bd0c9cc2ac281329fb8373679e7faae36`.
Bộ kiểm thử Elixir 793/793 PASS, không warning.
Bước verify Canonical Names Lock hoàn tất SUCCESS trên cùng HEAD.

## Phép tính đúng không được thay đổi
Độ dài năm L = close_gate_day-open_gate_day; số tháng k do
PATCH24 chọn từ bowl3/seal30. Hợp thành có thứ tự
(x1,...,xk), mỗi 4<=xi<=123, tổng xi=L.
Số phương án N được đếm chính xác bằng nguyên lớn,
quy đổi zi=xi-4 rồi bù trừ các hạn zi<=119.
Bộ mở hạng duyệt xi tăng dần, trừ số phần hoàn thành
của từng nhánh, sử dụng hạng một-based. Ngày nguồn cho
cấu trúc là year.open_gate_day+1; dòng trả lời dùng
bowl3/seal31, N có thể vượt mô-đun SAVE.

## Di sản lỗi có chủ đích
LegacyMirroredMonthLengthsRank.transform(rank,N)
trả N-rank+1 thay cho rank từ dòng đáp án. Đây là
sai lệch duy nhất trong production; không đổi năm,
cốt-lết, số tháng, N, source_day hay bowl/seal.
Stage51 PATCH25 cần gọi thật hàm di sản rồi sửa lại hạng.

20 bài Stage50: 16 kiểm soát đếm, mở hạng, giới hạn,
phản chiếu, bảo toàn dữ liệu, API/kiểm toán mã và
4 so sánh normative RED tại các mốc năm.
Mục tiêu 813 bài: đúng 4 RED, Canonical Names Lock PASS,
không warning biên dịch. Không sửa main, oracle hoặc
các PATCH trước; chưa đan tháng/tên tháng/lịch cuối.
