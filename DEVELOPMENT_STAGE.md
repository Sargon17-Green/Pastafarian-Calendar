# Trạng thái phát triển

TOTAL_STAGES=55
CURRENT_STAGE=7
CURRENT_KIND=PATCH
CURRENT_PATCH=03
LAST_COMPLETED_STAGE=6
EXPECTED_REPOSITORY_STATE=GREEN
FOREIGN_LANGUAGE_USAGE=NONE
IMPLEMENTATION_STARTED_FROM_ZERO=YES
CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO
CROSS_IMPLEMENTATION_HASH_CHECKS=NO
CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO
PROGRAMMING_LANGUAGE=Elixir
NATURAL_LANGUAGE=Tiếng Việt
SOURCE_LANGUAGE_CATALOG_FROZEN=YES
MONSTER_ARCHITECTURE_GROWTH=Giữ LegacyDistance sai; DistancePatch gọi hàm lịch sử rồi đối chiếu với abs(t-c), chỉ sửa khác biệt, cuối cùng cộng 1; DistanceManager và context dùng kết quả đã vá.
SEMANTIC_STATE_OWNER_VALIDATED=YES
GITHUB_ACTIONS_PERFORMED=STAGE_07_PENDING
GIT_HISTORY_MUTATED=STAGE_07_PATCH_COMMIT
HANDOFF_PACKAGE_PREPARED=NO
LOCAL_VERIFICATION=NOT_RUN_ELIXIR_UNAVAILABLE
CI_ELIXIR_VERSION=1.18.5
CI_OTP_RELEASE=27
CI_TESTS=STAGE_07_PENDING
CI_FAILURES=STAGE_07_PENDING
HUMAN_AUTHORED_TEXT_LANGUAGE_AUDIT=PASS_EXISTING_TESTS
CLOSURE_VERIFICATION_PENDING=YES

Giai đoạn 1 đã được xác minh độc lập với 16 kiểm thử đạt và không có lỗi.
Giai đoạn 2 cố ý để lộ lỗi của phép dư lịch sử: M, 2M và 3M phải
trả M theo chuẩn nhưng hiện trả 0; M+1 vẫn trả 1.
Không thêm bản vá trước giai đoạn 3. Không thay đổi nhánh main.

Đã xác minh bằng GitHub Actions với Elixir 1.18.5 và OTP 27.
Kết quả: 22 kiểm thử, đúng 3 thất bại có chủ đích; 19 kiểm thử còn lại đạt.
Khóa tên chuẩn độc lập đã đạt. Không có cảnh báo biên dịch.
Bằng chứng: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38150668369
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38150668429
Giai đoạn 2 kết thúc với trạng thái EXPECTED_RED đã được xác minh.

Giai đoạn 3 đã thêm lớp SavePatch chuyển phần dư bằng không thành M.
LAST_COMPLETED_STAGE đã nâng lên 3 sau kiểm chứng CI thành công.
Kết quả xác nhận: 29 kiểm thử, 0 lỗi, khóa tên chuẩn đạt, không thay đổi main.

Bằng chứng kiểm thử giai đoạn 3: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151138352
Bằng chứng khóa tên chuẩn: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151138317
Chốt giai đoạn 3: GREEN; giai đoạn tiếp theo là 4, DISCOVERY 02.

Giai đoạn 4 bổ sung giả định cũ `old_day_tag(day) = 2 * abs(day - FOUNDATION)`.
Ba hồi quy mới tại FOUNDATION, FOUNDATION+1, FOUNDATION+2 phải thất bại.
Các bài kiểm tra trước đó phải tiếp tục đạt. Chưa có bản vá 02.
LAST_COMPLETED_STAGE đã nâng lên 4 sau xác minh chính xác ba sai lệch dự kiến.

Giai đoạn 4 kết thúc ở EXPECTED_RED đã được kiểm chứng bằng Elixir 1.18.5 và OTP 27.
36 kiểm thử, đúng ba thất bại ở FOUNDATION, FOUNDATION+1, FOUNDATION+2; 33 kiểm thử còn lại thành công.
Không có lỗi biên dịch, cảnh báo từ bộ mã nguồn hoặc sai lệch ngoài dự kiến.
Bằng chứng: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38152863320
Khóa tên chuẩn: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38152863404
Bước lịch sử tiếp theo là giai đoạn 5, PATCH 02.

Bản vá 02 đã được đưa vào luồng sản xuất và giữ nguyên hàm sai cũ.
Điều kiện bảo vệ riêng ở Ngày Nền vẫn hiện diện dù không cần thiết.
LAST_COMPLETED_STAGE đã nâng lên 5 sau kiểm chứng CI xanh.
Kết quả thực tế: 45 kiểm thử, 0 thất bại, không thay đổi main.

Giai đoạn 5 được kiểm chứng bằng GitHub Actions, Elixir 1.18.5 và OTP 27.
45 kiểm thử, 0 lỗi, không có cảnh báo biên dịch.
Khóa tên chuẩn hoàn thành; LegacyDayTag cũ không thay đổi.
Trong lần chạy đầu, mô-đun kiểm thử mới thiếu từ khóa end và chưa chạy được;
lỗi cú pháp đã được sửa ở commit riêng trước khi xác minh cuối cùng.
Bằng chứng: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154035832
Khóa tên chuẩn: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154035856
Trạng thái đóng giai đoạn 5: GREEN. Giai đoạn 6 tiếp theo là DISCOVERY 03.

Giai đoạn 6 thêm old_distance(c,t) = abs(day_tag(c)-day_tag(t)), không cộng 1.
Lỗi lộ ở cùng ngày, hai trường hợp cùng phía và trường hợp qua Ngày Nền.
Hai đối chứng vô tình đúng; các bản vá 01/02 vẫn hoạt động.
Không thêm kiểm tra chronological của bản vá 03 trước giai đoạn 7.
LAST_COMPLETED_STAGE đã nâng lên 6 sau xác minh CI giai đoạn 6.
Kết quả thực tế: 55 kiểm thử, đúng 4 thất bại có chủ đích, 51 đạt.

Giai đoạn 6 được kiểm chứng bằng GitHub Actions: Elixir 1.18.5, OTP 27.
55 kiểm thử, đúng bốn thất bại dự kiến: cùng ngày, hai ngày bên trái,
hai ngày bên phải và một cặp qua Ngày Nền. 51 kiểm thử còn lại đạt.
Không có lỗi biên dịch hay thất bại ngoài dự kiến. Khóa tên chuẩn đạt.
Bằng chứng: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154864908
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154864891
Giai đoạn 6 hoàn tất ở EXPECTED_RED đã xác minh; tiếp theo là giai đoạn 7, PATCH 03.

Giai đoạn 7 bổ sung DistancePatch và định tuyến qua DistanceManager.
Giữ nguyên bốn hồi quy chuẩn đã đỏ ở giai đoạn 6; chỉ kiểm thử nối dây
từng xác nhận đầu ra sai được cập nhật để kiểm toán lớp vá mới.
Không thêm thành phần của giai đoạn 8 và không thay đổi main.
LAST_COMPLETED_STAGE vẫn bằng 6 cho đến khi CI giai đoạn 7 thành công.
Mục tiêu: 65 kiểm thử đạt, 0 lỗi, khóa tên chuẩn đạt.
