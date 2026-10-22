# Giai đoạn 48 — DISCOVERY24: sai thứ tự số tháng

## Mốc mở
Stage47 PATCH23 đóng GREEN tại
`1b3ce24b53f8bcc01c9af9fe97e2c1f36d96c825`.
Native CI Elixir 1.18.5 / OTP27: 753/753 PASS không warning,
Canonical Names Lock PASS.

## Phép tính chuẩn
Số ngày trong năm L=close_gate_day-open_gate_day.
Ứng viên số tháng là các số nguyên liên tiếp tăng từ
ceil(L/123) đến min(47,floor(L/4)), vì mỗi tháng dài
từ 4 đến 123 ngày. Hỏi vòng đáp án dùng
(calculation_day,year.open_gate_day+1), bát 3/chốt 30.
Hạng một-based từ AnswerStreamManager.choose_rank được giữ.

## Di sản lỗi chủ đích
LegacyDescendingMonthCount đảo thứ tự các ứng viên số tháng
thành giảm dần nhưng vẫn giữ đủ tập số tháng. Production
thực sự chọn Enum.at(historical_order,rank-1), không phải
thứ tự tăng dần chuẩn. Stage49 PATCH24 sẽ giữ/chạy di sản
thật rồi lấy lại theo thứ tự tăng dần; không sửa oracle.

20 bài Stage48 mới: 16 kiểm soát giới hạn tháng, rank,
nguồn sauce, năm, cổng, cốt-lết, miền đối số và API;
4 nhóm normative RED về trước/sau Foundation và cổng đóng.
Mục tiêu 773 bài, đúng 4 RED, Canonical Names Lock PASS,
không cảnh báo compiler. Chưa chọn độ dài/tên tháng hoặc
tích hợp lịch cuối. Không sửa main/PATCH01..23.
