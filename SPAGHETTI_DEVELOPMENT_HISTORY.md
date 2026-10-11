# Lịch sử phát triển spaghetti

## Giai đoạn 1 — Khởi tạo

Dòng triển khai được bắt đầu từ số không bằng Elixir. Tiếng Việt được cố định làm ngôn ngữ nguồn. `SourceLanguageCatalog` phiên bản `1.0.0` được đóng băng với 17 tên miếng và 47 tên tháng, mỗi tên có chỉ số chuẩn cố định.

Ở bước này chưa có giả định lịch sử sai nào được đưa vào, vì khuyết tật đầu tiên chỉ được phép xuất hiện ở giai đoạn khám phá kế tiếp. Kiến trúc quái vật mới chỉ có vỏ trung tính: ngữ cảnh riêng cho mỗi lần gọi, phân phối cơ sở, kiểm tra, biên lỗi và quan sát phi ngữ nghĩa.

Bộ tham chiếu sạch của phụ lục A được dựng riêng dưới kiểm thử. Nó không được nhập vào đường sản xuất.

Trong lần đóng giai đoạn 1, tệp giấy phép còn sót lại đã được Việt hóa, kiểm tra văn bản được mở rộng để bao gồm cả giấy phép và YAML, và hai cảnh báo biến không dùng trong bộ tham chiếu chỉ dành cho kiểm thử đã được loại bỏ bằng thay đổi tên biến không mang ý nghĩa ngữ nghĩa. Không có khuyết tật legacy, bản vá tương lai hay hành vi sản xuất mới nào được thêm.

Việc xác minh đóng cuối cùng đã chạy thành công trên GitHub Actions bằng Elixir 1.18.5 và Erlang/OTP 27. `mix test` hoàn tất với 16 kiểm thử và 0 lỗi. Sau lần xác minh này, giai đoạn 1 được đánh dấu hoàn tất; bước lịch sử kế tiếp là giai đoạn 2, `DISCOVERY 01`.

## Giai đoạn 2 — Phát hiện 01: phần dư bằng không

**Điều từng được tin:** Phép SAVE có thể được thực hiện bằng phần dư thông thường theo M. Thiết kế cũ của `old_remainder` dùng phép chia lấy dư có kết quả từ 0 đến M−1.

**Điều đã phát hiện:** SAVE theo quy tắc chuẩn phải trả kết quả từ 1 đến M, và khi đầu vào chia hết cho M thì phải trả chính M. Với M = 2^127−1, đầu vào M, 2M, 3M là ba phản ví dụ độc lập. Đầu vào M+1 là đối chứng, không có sai lệch.

Đường thực thi hiện tại đi từ `save_value_spaghetti` qua `Dispatcher.save_value`, `SaveManager.calculate` tới `LegacyRemainder.old_remainder`. Đây là đường sản xuất thực tế, không phải bản mô phỏng trong kiểm thử. Đường ngày lịch đầy đủ vẫn tạm dừng ở biên chưa tích hợp như giai đoạn 1.

Các kiểm thử chuẩn cố ý giữ nguyên kỳ vọng đúng. Trong giai đoạn khám phá, ba kiểm thử M, 2M và 3M dự kiến thất bại; các kiểm thử còn lại phải đạt. Không đưa vào điều kiện sửa giá trị 0 thành M. Bản vá thuộc giai đoạn 3.

**Xác minh thực tế:** GitHub Actions với Elixir 1.18.5 và OTP 27 đã chạy 22 kiểm thử. Đúng ba hồi quy M, 2M, 3M thất bại với phần dư thực tế 0 thay vì M = 170141183460469231731687303715884105727. Mười chín kiểm thử còn lại đạt. Khóa tên chuẩn độc lập đạt. Giai đoạn 2 được khép ở trạng thái EXPECTED_RED; không lén đưa vào bản vá.
