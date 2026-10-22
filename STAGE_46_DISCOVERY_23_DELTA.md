# Giai đoạn 46 — DISCOVERY23: vật chất hóa cốt-lết và lỗi ngày đầu

## Điểm khởi đầu
Stage45 PATCH22 đóng GREEN tại
`eb9c0956916d105e00235ba20b1afe30be164298`,
713/713 bài PASS và Canonical Names Lock PASS.

## Phần chuẩn được giữ
CutletMaterializationManager tiếp nhận năm đích, bảng gate,
phân hoạch và các chỉ số tên từ CutletNameIndexManager đã vá.
Từng Cutlet có name_index, open_gate_index, close_gate_index,
first_day, last_day. Chỉ số đóng = chỉ số mở + độ dài phần,
và cốt-lết tiếp theo mở ở cổng đóng trước. last_day là
gate(close); không thay tên, số phần, bảng cổng hoặc năm.

## Sai lệch lịch sử
LegacyInclusiveCutletFirstDay cố ý ghi first_day bằng
gate(open), mặc dù cốt-lết chuẩn dùng khoảng (open,close]:
first_day phải bằng gate(open)+1. Di sản được gọi thật trên
đường production để Stage47 PATCH23 có thể giữ vết lỗi.
Các chuỗi ngày hiện tại vì vậy chồng nhau đúng tại cổng;
đây là sai lệch được kiểm tra, không phải quy tắc mới.

20 kiểm thử Stage46: 16 điều khiển kiểu Cutlet, tính liên
tục của cổng, tên, số lượng, dữ liệu lịch sử, API và kiểm
toán source; bốn nhóm so sánh nguyên dạng với oracle
test-only dự kiến đỏ. Mục tiêu 733 bài, đúng 4 RED,
Canonical Names Lock PASS, không cảnh báo biên dịch.
Không thay main, oracle hoặc PATCH01..22; chưa tích hợp
tháng hoặc kết quả lịch cuối. HANDOFF_* không lên GitHub.
