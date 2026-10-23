# Stage55 PATCH27: phục hồi hạng tên tháng

DISCOVERY27: 886 bài, đúng 4 lỗi cố ý.
Bản vá dùng di sản thật, giữ cả tên và hạng lịch sử,
khôi phục hạng chuẩn theo quan hệ đảo vòng và mở tên.
Mọi bình, niêm, nguồn năm và thứ tự từ điển giữ nguyên.
Giai đoạn đầu sửa lớp tên và các nhóm RED; tích hợp
ngày lịch năm thành phần và kiểm thử lịch sử là phần tiếp.
Không sửa main hoặc normative_reference.ex.

## Tích hợp ngày lịch
CalendarDateManager nối tháng đã đan, tên tháng chuẩn,
tên cốt-lết và ngày một-based thành bộ năm thành phần.
API calendar_date_spaghetti gọi production thật, giữ đầy đủ
đường chẩn đoán. Các kiểm thử hồi quy có tiền đề API
chưa tích hợp được cập nhật để kiểm tra lối vào mới.
Thêm bảy kiểm thử tích hợp, gồm so sánh oracle toàn bộ ngày.
Tình trạng: chờ CI, chưa công bố GREEN hoặc soak.

## Phục hồi sau CI 39965564069
903 bài: 900 PASS, một lỗi kiểm tra văn bản do đổi tên biến,
hai test quá thời gian ở NormativeReference.weave_count/3.
Bộ tham chiếu không bị sửa. Các test tích hợp mới kiểm tra
năm và tên tháng trực tiếp từ quy phạm, cùng phép ghép bộ
năm thành phần độc lập; không tuyên bố đã kiểm chứng toàn bộ
đường nguyên mẫu lịch lớn. Ba biến không dùng được dọn.
