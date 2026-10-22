# Giai đoạn 47 — PATCH23: sửa ngày đầu cốt-lết

## Chứng cứ ban đầu
Stage46 DISCOVERY23 đóng EXPECTED_RED tại
`41062232bb6d15b06bfd0799e4c0e0ed6afa059d`.
733 bài: 729 PASS và đúng 4 hồi quy normative RED.
Số cốt-lết, tên, chỉ số cổng và last_day đều chính xác;
first_day bị đặt bằng ngày cổng mở thay vì ngày kế.

## Cách vá
CutletFirstDayPatch.diagnose gọi thật hàm lịch sử
LegacyInclusiveCutletFirstDay.materialize(year,partition,names,state),
giữ toàn bộ historical_cutlets, rồi sửa first_day cho từng phần:
gate(open_gate_index)+1. Chỉ thay trường đó, trả corrected_cutlets.
CutletMaterializationManager dùng bản đã sửa trong production và
lưu chứng cứ lịch sử. Ngày cuối và cổng không đổi.

Bốn hồi quy normative Stage46 vẫn giữ nguyên expected;
các kiểm soát Stage46 về biên ngày và kiểm toán production
được cập nhật để xác nhận khoảng chuẩn. Thêm 20 bài Stage47:
so sánh nhiều ngày với oracle, xác nhận từng trường giữ nguyên,
các cổng nối tiếp, kiểm tra song song, dữ liệu bất biến,
biên cuối năm và lỗi đầu vào. Dự kiến 753 bài GREEN,
không compiler warnings, Canonical Names Lock PASS.
Không sửa main, oracle, di sản hoặc PATCH01..22.

## Xác minh CI

Stage47 PATCH23 đã được kiểm chứng thành công bằng Elixir 1.18.5 / OTP27:
**753/753 bài PASS, không compiler warnings** sau khi bỏ alias
không dùng trong bài kiểm tra Stage46. Bốn hồi quy normative
Stage46 vẫn giữ expected gốc và đều xanh.
Canonical Names Lock PASS.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39772388102
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39772388280
Không sửa di sản, oracle, thuật toán gốc hoặc main.
Đóng Stage47 GREEN. Stage48/55 DISCOVERY24 chưa bắt đầu.
