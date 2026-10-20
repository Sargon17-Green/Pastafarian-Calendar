# Giai đoạn 42 — DISCOVERY21: sai chốt chọn phân hoạch

Stage41 PATCH20 đã đóng GREEN tại commit
`3e1319e1acca607ef6305d3a54fafd89d08a8fd4`:
633/633 bài PASS; Canonical Names Lock PASS.

CutletPartitionCombinatorics đếm các phân hoạch dương của số
khoảng cổng thành số cốt-lết đã chọn bằng DP ghi nhớ bất biến,
rồi mở hạng theo thứ tự từ điển. Khi ngày tính đúng cổng nằm
bên trong năm, cổng ấy bắt buộc có trong ranh giới phân hoạch.
Năm đích, số cốt-lết, source_day=year.open_gate_day+1,
bát 2 và tập ứng viên giữ đúng PATCH01..20.

LegacyCutletPartitionCountSeal cố ý lấy rank bằng chốt 20,
thay vì chốt 21 của phân hoạch. Production dùng cùng tập
phân hoạch chính xác nhưng rank sai. PATCH21 phải thực thi
di sản thật rồi chọn lại rank trên chốt 21.

20 bài Stage42 gồm 16 điều khiển về DP, thứ tự từ điển,
cổng bắt buộc, API, state và đầu vào sai, cộng 4 nhóm
normative cố ý RED. Mục tiêu 653 bài, đúng bốn RED,
Canonical Names Lock PASS và không compiler warnings.
Không sửa main/oracle/PATCH01..20, không tích hợp tên
cốt-lết hoặc lịch cuối; không lưu HANDOFF_* trong repo.
