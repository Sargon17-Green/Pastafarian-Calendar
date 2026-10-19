# Giai đoạn 39 — PATCH 19: trả năm hiện tại ở cổng đóng

LegacyUpperBoundaryBelongsToNextYear giữ nguyên sai lệch
:next_at_upper_boundary. TargetYearBoundaryPatch luôn gọi
legacy rồi đổi riêng tuyến biên thành :found.
Các tuyến :next, :previous và :found khác giữ nguyên.
TargetYearManager dùng bản vá, không sửa bộ chọn cổng.

Bốn hồi quy normative Stage38 giữ nguyên expected và phải
chuyển xanh. Hai điều khiển Stage38 được cập nhật để phân biệt
di sản và production. Thêm 20 kiểm thử Stage39 về nhiều năm,
hai đầu cổng, state, concurrency, tính lặp và nguồn mã.
Mục tiêu 593 bài PASS, không compiler warnings, khóa tên PASS.
Không sửa main, oracle hoặc PATCH01..18.
