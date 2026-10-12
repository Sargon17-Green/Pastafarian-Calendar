# Trạng thái phát triển

TOTAL_STAGES=55
CURRENT_STAGE=21
CURRENT_KIND=PATCH
CURRENT_PATCH=10
LAST_COMPLETED_STAGE=21
EXPECTED_REPOSITORY_STATE=GREEN
FOREIGN_LANGUAGE_USAGE=NONE
IMPLEMENTATION_STARTED_FROM_ZERO=YES
CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO
CROSS_IMPLEMENTATION_HASH_CHECKS=NO
CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO
PROGRAMMING_LANGUAGE=Elixir
NATURAL_LANGUAGE=Tiếng Việt
SOURCE_LANGUAGE_CATALOG_FROZEN=YES
MONSTER_ARCHITECTURE_GROWTH=Giữ nguyên LegacyInPlaceStir.run ghi đè tuần tự; BowlVaultPatch sử dụng LegacyInPlaceStir.compute_one với một vault_old cố định và tích lũy sáu kết quả vào pending, Map.merge một lần sau cùng. Giữ PATCH 01..09.
SEMANTIC_STATE_OWNER_VALIDATED=YES
GITHUB_ACTIONS_PERFORMED=YES
GIT_HISTORY_MUTATED=STAGE_21_PATCH_COMMIT
HANDOFF_PACKAGE_PREPARED=NO
LOCAL_VERIFICATION=NOT_RUN_ELIXIR_UNAVAILABLE
CI_ELIXIR_VERSION=1.18.5
CI_OTP_RELEASE=27
CI_TESTS=253
CI_FAILURES=0
HUMAN_AUTHORED_TEXT_LANGUAGE_AUDIT=PASS_EXISTING_TESTS
CLOSURE_VERIFICATION_PENDING=NO

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
LAST_COMPLETED_STAGE đã nâng lên 7 sau xác minh CI của giai đoạn 7.
Kết quả xác nhận: 65 kiểm thử đạt, 0 lỗi, khóa tên chuẩn đạt.

Giai đoạn 7 được kiểm chứng bằng GitHub Actions: Elixir 1.18.5, OTP 27.
65 kiểm thử, 0 thất bại và không có cảnh báo biên dịch.
Lần chạy đầu có một lỗi trong kiểm thử phân loại nhánh do một cặp
ngày trùng có hai khoảng cách cơ sở bằng nhau. Đã chuyển cặp đó sang
nhánh giữ và bổ sung cặp khác cho nhánh sửa. Mã sản xuất không thay đổi.
Bốn hồi quy chuẩn từ giai đoạn 6 và ba lớp hàm lịch sử được giữ nguyên.
Kiểm thử: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155925314
Khóa tên chuẩn: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155925331
Giai đoạn 7 kết thúc ở GREEN, giai đoạn 8 tiếp theo là DISCOVERY 04.

Giai đoạn 8 đưa bảng đá 46 hàng vào đường sản xuất thật.
LegacyStoneMutation cố ý đọc giá trị vừa cập nhật trong cùng một hàng.
Hàng đầu và giá trị lúa mì hàng thứ hai vẫn đúng làm đối chứng.
Bốn hồi quy chuẩn dự kiến đỏ: hàng 2 vị trí 2/3, hàng 3 vị trí 1,
và cả hàng 46. 12 kiểm thử mới; tổng 77 kiểm thử, dự kiến 4 thất bại.
Không thêm bản vá 04; LAST_COMPLETED_STAGE đã nâng lên 8 sau xác minh CI.

Giai đoạn 8 hoàn tất EXPECTED_RED theo hợp đồng: Elixir 1.18.5, OTP 27.
77 kiểm thử, đúng 4 sai lệch chuẩn ở hàng 2 ô 2/3, hàng 3 ô 1,
và toàn bộ hàng 46. 73 kiểm thử còn lại đạt, không lỗi ngoài dự kiến.
Lần chạy đầu có cảnh báo import Bitwise không dùng ở tệp kiểm thử mới.
Import thừa đã được xóa trong commit riêng, không thay đổi mã sản xuất
hoặc kết quả bốn hồi quy chuẩn; lần chạy sau không có cảnh báo.
Khóa tên chuẩn PASS.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38157396943
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38157396924
Giai đoạn tiếp theo là 9, PATCH 04, chưa bắt đầu.

Giai đoạn 9 đưa StonePatch vào đường xây bảng 46 hàng thực.
Ảnh chụp old_snapshot và legacy_clone được tạo trước khi gọi hàm cũ.
Kết quả trung gian của LegacyStoneMutation được ghi đè đủ năm ô.
Bốn hồi quy chuẩn giai đoạn 8 vẫn giữ nguyên kết quả kỳ vọng.
Các kiểm thử nối dây cũ được sửa để phân biệt legacy sai và đường công khai đúng.
Kết quả: 88 kiểm thử đạt, 0 lỗi; khóa tên chuẩn đã đạt.
LAST_COMPLETED_STAGE đã nâng lên 9 sau xác minh cả kiểm thử và khóa tên.

Giai đoạn 9 được xác minh bằng GitHub Actions: Elixir 1.18.5, OTP 27.
88 kiểm thử, 0 lỗi và không có cảnh báo biên dịch. Khóa tên chuẩn đạt.
Cả bốn hồi quy chuẩn từ phát hiện 04 được giữ nguyên và chuyển thành xanh.
Hàm lịch sử LegacyStoneMutation có blob SHA không đổi:
91260b89961571e9c96a0f0e563c27115c1aa697.
Bốn tệp triển khai và kiểm thử đã đối chiếu khớp bản bàn giao.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38159415842
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38159415828
Giai đoạn 9 đóng GREEN; tiếp theo là giai đoạn 10, DISCOVERY 05.

Giai đoạn 10 tính bảy giọt ẩn chính xác bằng các tham số theo ngày,
bảng đá 46 hàng đã vá, hệ số ẩn và bảy lần nghiền.
LegacyHiddenStorage lưu chúng theo thứ tự hidden7 đến hidden1,
nhưng đọc trực tiếp theo vị trí mà chưa áp dụng ánh xạ 8-k.
Giọt số 4 tình cờ khớp chuẩn; bốn hồi quy số 1, 2, 3, 7
dự kiến cố ý đỏ. 13 kiểm thử mới, tổng 101, đúng 4 thất bại.
Không thêm bản vá 05 thuộc giai đoạn 11.
LAST_COMPLETED_STAGE đã nâng lên 10 sau kiểm chứng CI và khóa tên.

Giai đoạn 10 được kiểm chứng trên Elixir 1.18.5, Erlang/OTP 27:
101 kiểm thử, đúng bốn sai lệch chuẩn ở giọt ẩn số 1, 2, 3, 7;
97 kiểm thử khác đạt, bao gồm 88 bài cũ. Không cảnh báo biên dịch.
Cả bảy giá trị số học khớp oracle trước khi lưu ngược.
Khóa tên chuẩn đạt độc lập.
Lần CI đầu tiên có hai cảnh báo alias chưa dùng trong kiểm thử mới;
đã bổ sung đối chứng trực tiếp bằng hai mô-đun ấy và chạy lại sạch.
Mã sản xuất không đổi, bốn kỳ vọng chuẩn không đổi.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38161317725
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38161317727
Trạng thái đóng: EXPECTED_RED. Tiếp theo là giai đoạn 11, PATCH 05.

Giai đoạn 11 thêm HiddenStoragePatch đọc hidden k tại vị trí 8-k
trong tuple đảo lịch sử. Mọi lần đọc công khai đều đi qua lớp vá;
LegacyHiddenStorage.store_reversed và read_as_if_forward không đổi.
Bốn hồi quy chuẩn của giai đoạn 10 giữ nguyên kỳ vọng.
Các kiểm thử dây nối cũ được sửa để kiểm tra legacy vẫn sai,
còn đường công khai đã đúng. Mười bài kiểm thử độc lập được thêm.
CI xác nhận 111 kiểm thử, 0 lỗi; LAST_COMPLETED_STAGE đã nâng lên 11
sau khi cả kiểm thử và khóa tên chuẩn xác nhận GREEN.

Giai đoạn 11 đã được kiểm chứng bằng Elixir 1.18.5, Erlang/OTP 27.
111 kiểm thử đạt, không có lỗi hoặc cảnh báo biên dịch.
Bốn hồi quy chuẩn từ phát hiện 05 vẫn giữ nguyên kỳ vọng và đều đạt.
Cả mười bài kiểm thử mới của PATCH 05 đạt; khóa tên chuẩn PASS.
LegacyHiddenStorage giữ nguyên blob SHA:
cb00f07e880368cf3aa4be81546944bd09bfa4c1.
HiddenDropCalculator giữ nguyên blob SHA:
5afcaf5cff02a84fbbd92398b134adc34a08c885.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38163456728
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38163456763
Giai đoạn 11 đóng GREEN; tiếp theo là giai đoạn 12, DISCOVERY 06.

Giai đoạn 12 đưa 46 giọt nhìn thấy vào đường sản xuất qua VisibleDropManager.
LegacyPrior.legacy_prior chỉ đọc kho nhìn thấy ở vị trí index-back,
không biết địa chỉ âm của bảy giọt ẩn và dùng 0 khi thiếu vị trí.
Bảng đá đã vá, giọt ẩn đã vá và SAVE vẫn hoạt động đúng.
Bốn hồi quy chuẩn mới kiểm các giọt 1, 2, 7, 46; cố ý đỏ.
Mười một kiểm thử kiểm soát và bốn hồi quy: tổng 126 kiểm thử,
dự kiến đúng bốn thất bại. Không có bản vá 06 của giai đoạn 13.
LAST_COMPLETED_STAGE đã nâng lên 12 sau xác minh CI và khóa tên.

Giai đoạn 12 hoàn tất theo hợp đồng EXPECTED_RED trên Elixir 1.18.5,
Erlang/OTP 27. Có 126 kiểm thử, đúng bốn hồi quy chuẩn cố ý đỏ:
giọt nhìn thấy 1, 2, 7, 46. 122 bài khác đạt, bao gồm
toàn bộ 111 kiểm thử đã hoàn tất ở giai đoạn 11.
Không có cảnh báo biên dịch trong lần kiểm chứng cuối.
Lần CI đầu sinh cảnh báo từ Map.take với Range trong một
kiểm thử mới. Đã thay bằng Map.filter, không sửa mã sản xuất,
không sửa hồi quy chuẩn hoặc bốn sai lệch dự kiến.
Khóa tên chuẩn độc lập PASS.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38165148360
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38165148358
Giai đoạn 12 đóng EXPECTED_RED. Giai đoạn 13 là PATCH 06.

Giai đoạn 13 đưa PriorPatch vào đường tính 46 giọt nhìn thấy.
Đối với slot=index-back >=1, bản vá gọi LegacyPrior thật;
với slot<=0, lấy hidden_number=1-slot từ HiddenDropManager
trên đúng tuple đảo đã được xây trong ngữ cảnh bootstrap.
Không thay đổi LegacyPrior, HiddenDropCalculator, hay oracle;
bản vá số 05 tiếp tục được sử dụng cho mọi truy cập hidden.
Bốn hồi quy chuẩn của phát hiện 06 giữ nguyên kỳ vọng.
Hai bài kiểm thử khám phá theo dây nối đã đổi để xác nhận
đường công khai đúng nhưng đường legacy vẫn sai.
Mười một kiểm thử Stage13 mới. Tổng dự kiến 137 bài, 0 lỗi.
LAST_COMPLETED_STAGE đã nâng lên 13 sau khi CI và khóa tên đều PASS.

Giai đoạn 13 được xác minh bằng GitHub Actions trên Elixir 1.18.5,
Erlang/OTP 27: 137 kiểm thử, 0 thất bại, không có cảnh báo biên dịch.
Bốn hồi quy chuẩn đỏ của giai đoạn 12 vẫn giữ nguyên kỳ vọng,
hiện chuyển sang xanh. 11 kiểm thử bổ sung đều đạt.
Khóa tên chuẩn PASS độc lập.
LegacyPrior không thay đổi, blob SHA:
4c2b416bf089f8a538908fd4d310bcb6900c2419.
Bộ tham chiếu chuẩn test-only không thay đổi, blob SHA:
be1638f46b2190d617af0378a61b077bda10bf32.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212531371
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212531416
Giai đoạn 13 đóng GREEN; bước tiếp theo giai đoạn 14, DISCOVERY 07.

Giai đoạn 14: chỉ số bảng nghiền bị lệch một ô.
LegacyGrindTable lưu 11 hàng thật từ index 0, nhưng phép gọi
legacy_row(number) dùng Enum.at(@real_rows, number, @missing_row)
với number từ 1 đến 11. Do đó bỏ mất hàng đầu, lấy 10 hàng
2..11 và kết thúc bằng hàng dự phòng {0,0,0,0,1}.
Không thêm sentinel ở index 0; đó là PATCH 07 của giai đoạn 15.
Hàm VisibleDropCalculator thực hiện đủ 11 lần lặp theo chỉ số cũ.
Các bản vá SAVE, đá, giọt ẩn, lịch sử trước tiếp tục không đổi.
Các kiểm thử chuẩn giai đoạn 12-13 phải giữ nguyên để lưu
bằng chứng lỗi mới, dù đầu ra 46 giọt hiện cố ý sai.
14 kiểm thử bổ sung, tổng 151 kiểm thử; 16 thất bại đã phân loại.
LAST_COMPLETED_STAGE nâng lên 14 sau khi CI và khóa tên đã xác nhận.

Giai đoạn 14 đã được kiểm chứng trên Elixir 1.18.5, Erlang/OTP 27.
151 kiểm thử, 16 thất bại đều có nguyên nhân xác minh là
lỗi bảng nghiền đang cố ý được để lộ; 135 kiểm thử đạt.
Trong số thất bại: 4 hồi quy chuẩn mới thuộc giai đoạn 14,
5 phép so sánh chuẩn cũ thuộc giai đoạn 12, và 7 phép so sánh
chuẩn từ giai đoạn 13. Các kiểm thử cũ giữ nguyên kỳ vọng.
10 kiểm thử điều khiển mới đạt, xác minh phép đọc lệch chỉ số
và chuỗi bước nghiền sai. Không có cảnh báo biên dịch.
Khóa tên chuẩn PASS độc lập.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38213818081
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38213818145
Giai đoạn 14 kết thúc EXPECTED_RED; tiếp theo giai đoạn 15 PATCH 07.

Giai đoạn 15 thực hiện PATCH 07. Chỉ thêm một sentinel thật
{0,0,0,0,1} vào đầu @real_rows của LegacyGrindTable,
đưa 11 hàng nghiền nguyên bản đến vị trí 1..11.
Giữ nguyên chính xác biểu thức đọc lịch sử
Enum.at(@real_rows, number, @missing_row), không xóa sentinel.
VisibleDropCalculator vẫn gọi bộ đọc lịch sử 11 lần cho mỗi giọt.
Không thay oracle và bốn hồi quy chuẩn giai đoạn 14.
Mười kiểm thử khám phá cũ được chuyển thành kiểm soát lịch sử
và cấu trúc bảng đã vá; 12 kiểm thử mới kiểm chứng toàn diện.
Dự kiến 163 kiểm thử, không lỗi, khóa tên chuẩn PASS.
LAST_COMPLETED_STAGE đã được nâng lên 15 sau khi CI và khóa tên PASS.

Giai đoạn 15 được xác minh trên Elixir 1.18.5, Erlang/OTP 27:
163 kiểm thử, 0 lỗi, 0 cảnh báo biên dịch. Cả 16 bài đỏ
của lần phát hiện 07 chuyển thành xanh, không sửa
bốn hồi quy chuẩn và không sửa oracle.
12 kiểm thử mới đạt; bảng có đủ 12 hàng gồm một sentinel thật.
Hàm đọc legacy vẫn dùng nguyên biểu thức
Enum.at(@real_rows, number, @missing_row).
Lần CI đầu có một lỗi escape trong kiểm thử cấu trúc,
đã sửa duy nhất phép tìm chuỗi nguồn; không sửa mã sản xuất.
Lần CI cuối đạt hoàn toàn, khóa tên chuẩn độc lập PASS.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38229835498
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38229835434
Giai đoạn 15 đóng GREEN; tiếp theo giai đoạn 16, DISCOVERY 08.

Giai đoạn 16 phát hiện lỗi hạng hoán vị từ một truyền thẳng vào LegacyPermutationUnrank0 bắt đầu từ không. Quay vòng hạng 720 để giữ thứ tự hợp lệ nhưng sai. Xây 46 thứ tự trong context; chưa dùng các thứ tự để rót vào bát. Thêm 16 kiểm thử: 12 điều khiển, bốn hồi quy chuẩn cố ý đỏ. Dự kiến 179 kiểm thử với đúng bốn lỗi. Giữ LAST_COMPLETED_STAGE=15 đến khi xác minh CI; PATCH 08 thuộc giai đoạn 17.

Giai đoạn 16 đã kiểm chứng trên Elixir 1.18.5 và Erlang/OTP 27:
179 kiểm thử, đúng bốn thất bại dự kiến tại hạng 1, hạng 720,
giọt đầu, giọt 46. 175 kiểm thử khác đạt, bao gồm cả 163
bài kiểm thử giai đoạn 1-15. Không có cảnh báo biên dịch.
Khóa tên chuẩn độc lập PASS. Hàm old_permutation_unrank0
thật sự được gọi trong mỗi lần tạo 46 thứ tự; lỗi chỉ nằm
ở một đơn vị hạng truyền vào. Không khởi động PATCH 08.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38232940991
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38232941046
Giai đoạn 16 đóng EXPECTED_RED; bước tiếp theo giai đoạn 17 PATCH 08.

Giai đoạn 17 thực hiện PATCH 08 bằng chuỗi ánh xạ hạng
one_based=rem(drop-1,720)+1, legacy_rank0=one_based-1;
gọi thật LegacyPermutationUnrank0.old_permutation_unrank0(legacy_rank0).
Không sửa hàm legacy, oracle hoặc bất kỳ dữ liệu hoán vị cũ.
Bốn hồi quy chuẩn của giai đoạn 16 giữ nguyên. Các bài
kiểm soát chứng minh sai lệch cũ được chuyển sang xác minh
legacy vẫn sai khi gọi trực tiếp nhưng đường sản xuất đúng.
14 bài kiểm thử Stage17 bổ sung; tổng dự kiến 193 bài GREEN,
không lỗi. LAST_COMPLETED_STAGE đã nâng lên 17 sau khi CI và khóa tên xác minh PASS.
Không tiến tới giai đoạn 18 về vị trí rót bát.

Giai đoạn 17 được xác minh trên Elixir 1.18.5, Erlang/OTP 27:
193 kiểm thử, 0 thất bại, không có cảnh báo biên dịch.
Bốn hồi quy chuẩn từ phát hiện 08 giữ nguyên kỳ vọng
và đều đạt. 14 bài kiểm thử mới đều đạt.
Khóa tên chuẩn độc lập PASS.
Hàm LegacyPermutationUnrank0 giữ nguyên blob SHA:
d553b2a637e54ca74eb7d6e90b8aab437ed7fc13.
Oracle test-only giữ nguyên blob SHA:
be1638f46b2190d617af0378a61b077bda10bf32.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235528620
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235528637
Giai đoạn 17 đóng GREEN; tiếp theo giai đoạn 18 DISCOVERY 09.

Giai đoạn 18 mở lần phát hiện 09 về phép rót vào bát.
BowlSeedCalculator tính sáu bát ban đầu theo chuẩn.
BowlDropCalculator áp dụng đủ 46 giọt và 6 vị trí,
đọc snapshot old, ghi map next mới cho mỗi lần cập nhật.
Chỉ ba nguồn rót bị sai: LegacyPourPositions đọc
Map.fetch!(bowls_old,position) cho position=1..3 thay vì
ID bát tại order[position]. Số ID đích được lấy đúng từ order.
Không thêm lỗi trộn in-place của DISCOVERY 10. Không tích hợp
12 lần khuấy sau giọt 46 hoặc truy vấn ngày lịch cuối.
16 bài kiểm thử mới gồm 12 kiểm soát và bốn hồi quy chuẩn đỏ.
Dự kiến 209 bài kiểm thử, đúng bốn lỗi chủ đích.
LAST_COMPLETED_STAGE nâng lên 18 sau CI và khóa tên PASS.

Giai đoạn 18 kiểm chứng trên Elixir 1.18.5, Erlang/OTP 27:
209 kiểm thử, đúng 4 thất bại có chủ đích do nguồn rót sai;
205 bài đạt, trong đó đủ 193 kiểm thử giai đoạn 1-17.
Bốn hồi quy đỏ: nguồn rót đầu, bước khuấy đầu, sáu bát
sau 46 giọt và trường hợp hai chiều ngày. Tất cả 12 bài
kiểm soát mới đạt. Không cảnh báo biên dịch. Khóa tên
chuẩn độc lập PASS. Không có bộ alias của PATCH 09.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239350202
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239350320
Giai đoạn 18 đóng EXPECTED_RED; tiếp theo giai đoạn 19 PATCH 09.

Giai đoạn 19 thực hiện PATCH 09, chỉ sửa ba nguồn rót thông qua
BowlAliasPatch.alias_view. Các khóa vị trí 1..3 trong alias
nhận giá trị từ ID bát thật theo order. Module LegacyPourPositions
giữ nguyên, kể cả lời gọi trực tiếp sai nếu dùng old không alias.
BowlDropCalculator dùng BowlAliasPatch.pour cho cả ba vị trí,
không sửa công thức SAVE hoặc đường khuấy với snapshot old.
Bốn hồi quy chuẩn của giai đoạn 18 giữ nguyên mọi assert,
chỉ chuyển đường gọi trực tiếp ở ca một qua lớp vá.
Thêm 14 bài kiểm thử Stage19. Dự kiến 223 bài, 0 lỗi.
LAST_COMPLETED_STAGE đã nâng lên 19 sau khi CI và khóa tên đều PASS.
Không bắt đầu lỗi in-place ở giai đoạn 20 DISCOVERY 10.

Giai đoạn 19 đã xác minh trên Elixir 1.18.5, Erlang/OTP 27:
223 kiểm thử, 0 lỗi, 0 cảnh báo biên dịch.
Bốn hồi quy chuẩn của giai đoạn 18 đã chuyển sang xanh
và giữ nguyên từng khẳng định. 14 kiểm thử mới PASS;
khóa tên chuẩn độc lập PASS.
LegacyPourPositions không đổi, blob SHA:
6ab77efeb07c74fb88fe1d62ad04c523d23c3c80.
Oracle test-only không đổi, blob SHA:
be1638f46b2190d617af0378a61b077bda10bf32.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38242471594
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38242471534
Giai đoạn 19 đóng GREEN; tiếp theo giai đoạn 20 DISCOVERY 10.

Giai đoạn 20 DISCOVERY 10 làm lộ lỗi in-place khi cập nhật sáu bát.
LegacyInPlaceStir.compute_one chứa nguyên công thức chuẩn khuấy,
nhưng run truyền map current vừa Map.put ở vị trí trước vào
compute_one cho vị trí sau. Ba phép rót vẫn được tính trước
và thông qua BowlAliasPatch chính xác. Không thêm vaultOld
hoặc pending của PATCH 10, không khuấy 12 lần sau giọt 46.
Bộ tính được gọi thật từ BowlDropCalculator.step cho cả 46 giọt.
16 kiểm thử mới: 12 kiểm soát, bốn hồi quy chuẩn cố ý đỏ.
Các bài chuẩn của giai đoạn 18-19 giữ nguyên kỳ vọng,
nên phép so sánh số bát toàn chặng có thể đỏ thêm đúng
do lỗi nhiễm hiện tại. Tổng dự kiến 239 kiểm thử.
LAST_COMPLETED_STAGE nâng lên 20 sau CI và khóa tên xác minh.

Giai đoạn 20 đã xác minh trên Elixir 1.18.5, Erlang/OTP 27:
239 kiểm thử, đúng 14 thất bại do cùng lỗi ô nhiễm in-place;
225 kiểm thử đạt, 0 cảnh báo biên dịch.
4 hồi quy chuẩn mới Stage20 đỏ có chủ đích.
6 kiểm thử chuẩn Stage18 và 4 kiểm thử chuẩn Stage19 đỏ
lại do vòng khuấy nhận current đã bị sửa. Không thay các
khẳng định normative cũ. 12 bài kiểm soát mới của Stage20 đạt.
Khóa tên chuẩn độc lập PASS; không có vaultOld hoặc pending.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38248260572
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38248260716
Giai đoạn 20 đóng EXPECTED_RED; tiếp theo giai đoạn 21 PATCH 10.

Giai đoạn 21 thực hiện PATCH 10: giữ byte-for-byte
LegacyInPlaceStir.run và compute_one của lần phát hiện 10.
BowlVaultPatch.run chọn vault_old=old và tạo pending riêng;
cả sáu LegacyInPlaceStir.compute_one đều đọc vault_old,
chỉ sau khi tính sáu vị trí mới Map.merge(vault_old,pending).
BowlDropCalculator.step chuyển toàn bộ đường sản xuất qua
BowlVaultPatch, không đổi ba phép rót qua BowlAliasPatch,
công thức khuấy, sáu tên ID hoặc 46 giọt.
Bốn hồi quy chuẩn Stage20 giữ nguyên assert.
Mười hồi quy chuẩn Stage18-19 giữ nguyên assert,
đều phải trở lại xanh. Mười hai điều khiển Stage20 tiếp tục
chứng minh legacy sai nếu gọi trực tiếp, production đã sửa.
Thêm 14 kiểm thử Stage21, tổng dự kiến 253 kiểm thử GREEN.
LAST_COMPLETED_STAGE đã nâng lên 21 sau khi CI và khóa tên PASS.
Không mở giai đoạn 22 hay phần khuấy sau 46 giọt.

Giai đoạn 21 được xác minh trên Elixir 1.18.5 / Erlang OTP 27:
253 kiểm thử, 0 thất bại, 0 cảnh báo.
14 hồi quy chuẩn đã đỏ ở DISCOVERY 10 (4 Stage20,
6 Stage18, 4 Stage19) đều xanh mà không sửa kỳ vọng.
14 bài kiểm thử Stage21 mới PASS. Kiểm toán 720 hoán vị,
46 giọt, đại số số nguyên 2048 bit, chạy song song,
quyền sở hữu snapshot và đường legacy trực tiếp đều đạt.
Lần CI đầu đạt 253/253 nhưng có một warning unused alias
BowlVaultPatch trong test Stage20; commit kiểm thử sau đó
dùng alias để đối chiếu trực tiếp module vault với oracle,
CI chạy lại 253/253 và 0 warning. Không sửa mã sản xuất.
LegacyInPlaceStir vẫn giữ nguyên blob SHA
49554b37e329adb05e4f2ee77b8f51a69e944d4b.
Oracle test-only vẫn giữ nguyên blob SHA
be1638f46b2190d617af0378a61b077bda10bf32.
Khóa tên chuẩn PASS độc lập.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38254477457
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38254477452
Giai đoạn 21 đóng GREEN; tiếp theo giai đoạn 22 DISCOVERY 11,
chưa bắt đầu.
