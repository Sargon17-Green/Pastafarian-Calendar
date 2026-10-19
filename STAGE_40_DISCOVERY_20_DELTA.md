# Giai đoạn 40 — DISCOVERY 20: đảo thứ tự đếm cốt-lết

Stage39 đóng GREEN với 593/593 kiểm thử PASS và khóa tên chuẩn
PASS tại commit `a30887096b05d59eccb66852f782d58fc33efb17`.

## Phần chuẩn được giữ
TargetYearManager chọn đúng năm đích theo (open,close]. Tập số
cốt-lết là các số nguyên từ 6 đến min(17, gate_gaps), không lặp.
Hạt chọn cấu trúc lấy từ (calculation_day,year.open_gate_day+1),
bát 2, chốt 20, cùng AnswerStreamManager.choose_rank(stream,count).

## Di sản lỗi
LegacyDescendingCutletCount đảo thứ tự ứng viên thành giảm dần.
CutletCountManager thực sự lấy phần tử thứ rank trong danh sách
legacy; cùng tập ứng viên, cùng bowl, seal và rank nhưng trả số
cốt-lết sai. PATCH20 sẽ giữ legacy này và thêm lớp sửa riêng.

20 kiểm thử mới: 16 điều khiển (nguồn ngày, cổng, ứng viên,
rank, API, tính ổn định và nguyên vẹn mã nguồn) cùng bốn nhóm
normative RED trên các ngày trước/sau Foundation và cổng đóng.
Mục tiêu 613 bài với đúng bốn lỗi và Canonical Names Lock PASS.
Không tích hợp phân hoạch/tên cốt-lết hay ngày lịch cuối.
Không sửa main, oracle hoặc PATCH 01..19; không commit HANDOFF_*.
