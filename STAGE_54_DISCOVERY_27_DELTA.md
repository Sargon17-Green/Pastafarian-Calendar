# Giai đoạn 54 — DISCOVERY27: hạng tên tháng bị dịch một bước

## Điểm xuất phát
Stage53 PATCH26 đã đóng GREEN với 868/868 PASS,
92 tệp Elixir không cảnh báo biên dịch và Canonical Names Lock PASS.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39930785628
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39930783967

## Quy tắc chuẩn
Lấy đúng k tháng từ PATCH26, chọn k chỉ số tên khác nhau
trong 1..47 theo thứ tự từ điển tăng. Số phương án
P(47,k) được đếm chính xác bằng số nguyên lớn, kể cả k=47.
Hạng một-based được chọn bằng bowl 5, seal 33 tại
ngày mở năm đích + 1. Không đổi chuỗi đan tháng.

## Sai lệch lịch sử cố ý
LegacyNextMonthNameRank.transform(rank,total) trả
rank+1 trong vòng 1..total, kể cả total thành 1.
Production gọi trực tiếp di sản, giữ hạng lịch sử và
danh sách tên lịch sử, không tự sửa trong DISCOVERY.
Sai lệch chỉ thuộc chọn tên, không thay năm, cốt-lết,
chiều dài, số tháng, đan tháng hay dòng đáp án.

18 bài kiểm thử mới: 14 kiểm soát số lượng, mở hạng,
trật tự, bảo toàn dữ liệu và nguồn, cộng đúng bốn nhóm
normative dự kiến RED. Mục tiêu 886 bài: 882 PASS,
4 normative RED, Names Lock PASS, không cảnh báo Elixir.

## Tiếp theo
Stage55 PATCH27 phải gọi thật legacy, lưu dấu sai lệch,
khôi phục hạng tên chuẩn, hoàn tất tuple lịch ngày và
kiểm tra độc lập. Không sửa main, oracle hoặc legacy.
