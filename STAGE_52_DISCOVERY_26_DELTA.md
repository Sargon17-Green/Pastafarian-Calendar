# Giai đoạn 52 — DISCOVERY26: thứ tự sai khi đan tháng

## Điểm xuất phát
Stage51 PATCH25 đóng GREEN tại c29b773d49a55c142718d4215bf2ae6eabab12a0.
833/833 PASS trên commit triển khai trước khi đóng; Canonical Names Lock PASS.
Hai lượt CI của commit đóng Stage51 lúc chuẩn bị vẫn ở hàng đợi.

## Thuật toán và lỗi cố ý
Nhận đúng độ dài tháng từ PATCH25. Đếm bằng số nguyên tùy ý
các chuỗi nhãn tháng có số lần xuất hiện bằng độ dài đã chọn,
với lần đầu theo thứ tự tháng 1..k và lần cuối cũng theo 1..k.
Mở hạng từ điển theo nhãn tăng là quy tắc chuẩn.
Hạng một-based lấy từ bowl 4, seal 32 tại ngày mở năm + 1.
Di sản LegacyDescendingWeavingOrder cố ý xét nhãn giảm.
Đây là lỗi thứ tự từ điển, không đổi tập chuỗi hợp lệ,
số cách đan, hạng từ dòng đáp án hoặc cấu trúc tháng.

Để tránh nhầm sự đúng đắn với khả năng chịu tải, giai đoạn
DISCOVERY26 dùng các vectơ nhỏ được kiểm tra độc lập,
bao gồm bốn nhóm normative dự kiến RED.
Bộ đếm quy hoạch động nguyên vẹn là nền chính xác nhưng
chưa được chứng minh khả thi cho tối đa 47 tháng,
mỗi tháng tối đa 123 ngày. Không tuyên bố soak hoàn thành.
PATCH26 phải gọi thật di sản, ghi thứ tự và đầu ra lịch sử,
khôi phục thứ tự tăng rồi kiểm chứng cả trường hợp lớn.

## Giới hạn
Không sửa main, normative_reference.ex, mã PATCH01..25,
hoặc bộ tên. Mọi tài liệu do nhánh tạo dùng tiếng Việt.

Lượt rà soát độc lập: production truyền trực tiếp danh sách
nhãn giảm do LegacyDescendingWeavingOrder.labels tạo ra cho
WeavingCombinatorics.unrank. Như vậy lỗi di sản nằm thực sự
trên đường tính, không chỉ được lưu trong chẩn đoán.
