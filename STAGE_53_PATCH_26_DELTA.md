# Giai đoạn 53 — PATCH26: khôi phục thứ tự đan tháng

## Điểm xuất phát
Stage52 DISCOVERY26 đóng EXPECTED_RED ở
6447c55ce01e7668edd5ad4b718e61b74b20f388.
854 bài: 850 PASS, đúng bốn normative RED, không lỗi bất ngờ.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39841404382
Tên chuẩn: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39841404572

## Sửa sai
MonthWeavingOrderPatch.diagnose gọi trực tiếp
LegacyDescendingWeavingOrder.labels và mở hạng theo thứ tự
lịch sử, ghi cả danh sách nhãn cùng chuỗi lịch sử.
Bản vá sau đó đảo lại chính danh sách nhãn ấy để mở
cùng hạng theo từ điển tăng dần. Bảo toàn phép chọn hạng
từ bowl 4, seal 32 và độ dài tháng do PATCH25 cung cấp.
Bốn nhóm normative Stage52 phải GREEN.

Thêm 14 bài độc lập để kiểm toán sự gọi di sản thật,
chuỗi lịch sử, trường hợp một tháng, các hạng khác nhau,
phân biệt dữ liệu, tính bất biến và từ chối dữ liệu sai.
Tổng mong đợi 868 bài GREEN, Names Lock PASS.

## Giới hạn
Chưa chứng minh khả năng xử lý đủ miền 47 tháng và 5.778
ngày. Tính đúng trên bộ nhỏ không thay thế kiểm tra thời
gian, bộ nhớ hoặc soak. Không sửa main, bộ tham chiếu
normative_reference.ex hay mô-đun di sản.

## Giảm độ phức tạp để chuẩn bị kiểm thử tải
WeavingCombinatorics thay cách đếm trạng thái còn lại có
khả năng bùng nổ bằng bảng tích lũy cho những tháng chưa mở.
Mỗi bước tính kích thước nhánh từ số cách hoàn tất của các
tháng đang hoạt động và bảng phần đuôi. Bảo toàn quy tắc
thứ tự lần xuất hiện đầu và cuối, thứ tự từ điển và hạng.
Hai bài thử mới bao phủ 47 tháng ngắn và phép đếm năm dài
5.778 ngày. Soak thực tế và đo thời gian vẫn còn chờ CI.
