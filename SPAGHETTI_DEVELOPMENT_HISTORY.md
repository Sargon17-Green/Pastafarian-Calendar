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

## Giai đoạn 3 — Bản vá 01: bọc phép dư lịch sử

**Điều được đi vòng:** Thay vì sửa `old_remainder`, thêm lớp `SavePatch`
bên trên để kiểm tra đúng một trường hợp: nếu phần dư bằng 0, trả M.
Đường đi: `save_value_spaghetti → Dispatcher.save_value → SaveManager.calculate
→ SavePatch.save_patch → LegacyRemainder.old_remainder`.

**Vì sao tương đương:** Phần dư nguyên không âm theo M luôn nằm trong 0..M−1.
Với phần dư r khác 0, r là kết quả SAVE chuẩn; riêng khi r bằng 0,
giá trị chuẩn là M. Bằng chứng đúng cho mọi số nguyên, kể cả số âm và
số nguyên có độ dài tùy ý.

**Vì sao giữ vết cũ:** Hàm lỗi vẫn được gọi trên tuyến sản xuất thực tế;
tầng bọc thêm nhánh xử lý để hệ thống phát triển theo lịch sử spaghetti.
Không thêm bất kỳ bản vá nào thuộc các giai đoạn tương lai.

**Điều chỉnh kiểm thử:** Kiểm thử nối dây của giai đoạn 2 từng đòi đầu ra
công khai bằng kết quả sai. Chỉ xác nhận nối dây được cập nhật để chứng minh
hàm lịch sử còn sai nhưng đầu ra được sửa. Ba hồi quy chuẩn không thay đổi.

**Bằng chứng hoàn tất:** Với Elixir 1.18.5 và OTP 27, quy trình
`mix test` chạy 29 kiểm thử, 0 lỗi. Khóa tên chuẩn đạt ở quy trình độc lập.
Hàm `LegacyRemainder.old_remainder` giữ nguyên nội dung trước và sau
bản vá; ba hồi quy chuẩn của giai đoạn 2 giữ nguyên kỳ vọng. Trạng thái
giai đoạn 3 đã được xác minh là GREEN.

## Giai đoạn 4 — Phát hiện 02: nhãn ngày thiếu độ lệch

**Điều từng được tin:** Nhãn ngày chỉ là gấp đôi khoảng cách tuyệt đối
đến ngày nền, nên dùng `old_day_tag(day) = 2 * abs(day - FOUNDATION)`.

**Điều được phát hiện:** Trước ngày nền, các nhãn chẵn là chính xác.
Tại ngày nền, nhãn chuẩn là 1 thay vì 0; sau ngày nền, các nhãn lẻ
là 3, 5, 7... thay vì 2, 4, 6...

**Đường sản xuất thực sự:** `bootstrap_context` gọi `Dispatcher.bootstrap`,
sau đó mỗi ngày được gửi qua `DayCountManager.tag` đến
`LegacyDayTag.old_day_tag`; kết quả nằm trong hai trường riêng
`calculation_day_tag` và `target_day_tag` của context. API
`day_count_spaghetti` cũng đi qua tuyến quản lý này.

Ba hồi quy chuẩn tại ngày nền và hai ngày ngay sau đó được viết để
thất bại trong giai đoạn phát hiện. Không thêm bản vá hoặc nhánh tự
điều chỉnh ở giai đoạn 4; không thay đổi chức năng SAVE đã vá.

**Xác minh phát hiện:** Quy trình CI với Elixir 1.18.5 và OTP 27 đã
chạy 36 kiểm thử, đúng ba lỗi kỳ vọng: ngày nền (0 so với 1), ngày
nền cộng một (2 so với 3), ngày nền cộng hai (4 so với 5).
Ba mươi ba kiểm thử còn lại, gồm toàn bộ kiểm thử từ các giai đoạn
trước, đã đạt. Khóa tên chuẩn đạt độc lập. Không có bản vá thứ hai
trong commit này; giai đoạn 4 khép với trạng thái EXPECTED_RED.

## Giai đoạn 5 — Bản vá 02: nhãn ngày có nhánh thừa

**Điều được đi vòng:** `LegacyDayTag.old_day_tag` vẫn trả
`2 * abs(day - FOUNDATION)`. Lớp `DayTagPatch` gọi hàm sai này
trên đường sản xuất, cộng thêm một khi `day >= FOUNDATION`, rồi
kiểm tra thêm: nếu `day == FOUNDATION` và nhãn chưa bằng một,
ép nhãn về một. Nhánh sau là dư thừa nhưng bắt buộc giữ lại.

**Vì sao tương đương:** Với `day < FOUNDATION`, chuẩn là
`2 * (FOUNDATION - day)`, trùng đầu ra cũ. Với `day >= FOUNDATION`,
chuẩn là `2 * (day - FOUNDATION) + 1`, đúng bằng đầu ra cũ cộng
một. Tại ngày nền, nhánh cộng một đã biến 0 thành 1, nên điều kiện
bảo vệ không bao giờ phải sửa lại giá trị khi hàm cũ vận hành đúng
theo giả định lịch sử.

**Đường đi:** `day_count_spaghetti / bootstrap_context →
Dispatcher → DayCountManager → DayTagPatch → LegacyDayTag`.
Ngữ cảnh vẫn bất biến và giữ hai nhãn độc lập. Vết nhánh
`:day_tag_patch_02` được thêm sau `:legacy_day_count`.

**Kiểm thử cũ:** Ba hồi quy chuẩn ở giai đoạn 4 giữ nguyên.
Chỉ kiểm thử dây nối từng giả định nhãn đích sai 14 được chỉnh để
xác nhận hàm cũ vẫn trả 14, còn đầu ra đã vá trả 15.
Không thay đổi công thức sai hoặc bộ tham chiếu chuẩn.

**Kiểm chứng thực tế:** Sau khi sửa dấu kết thúc mô-đun kiểm thử
bị thiếu, GitHub Actions đã biên dịch mã sản xuất và thực thi
45 kiểm thử, 0 lỗi, không có cảnh báo. Ba hồi quy chuẩn của
giai đoạn 4 giữ nguyên kỳ vọng và đã chuyển thành xanh.
Khóa tên chuẩn đạt độc lập. Không sửa `LegacyDayTag.old_day_tag`,
không thêm thành phần tương lai. Giai đoạn 5 khép với trạng thái GREEN.

## Giai đoạn 6 — Phát hiện 03: hiểu sai hai nhãn thành khoảng cách

**Giả định lịch sử:** Do mỗi ngày đã có một nhãn được chuẩn hóa bởi
bản vá 02, lấy trị tuyệt đối hiệu hai nhãn là đủ:
`old_distance(c,t) = abs(day_tag(c) - day_tag(t))`.

**Sai lệch:** Nhãn ngày không phải trục thời gian tuyến tính đơn vị.
Vì thế cùng một ngày trả 0 thay vì khoảng cách chuẩn 1; trong
một số khoảng hai ngày cùng phía Ngày Nền, độ chênh nhãn gấp đôi
độ chênh thời gian; khi băng qua Ngày Nền, hiệu nhãn có thể thu nhỏ
khoảng cách thật. Có cả các đối chứng khớp tình cờ.

**Đường thực thi:** `distance_spaghetti → Dispatcher.distance →
DistanceManager.calculate → LegacyDistance.old_distance →
DayCountManager.tag → DayTagPatch.day_tag_patch → LegacyDayTag.old_day_tag`.
Cùng một tuyến được gọi trong `bootstrap_context`, giá trị thô được
lưu vào `distance_count`. Mỗi lần gọi có context và metric riêng.

**Hồi quy:** Thêm bốn kiểm thử đối chiếu chuẩn cố ý đỏ và sáu
kiểm thử bảo vệ về đường chạy thực, tính đối xứng, số nguyên lớn,
đầu vào sai, tính độc lập song song và hồi quy các lớp vá đã hoàn tất.
Không thay đổi bất kỳ hồi quy chuẩn nào thuộc giai đoạn cũ.
Bản vá 03 không được phép xuất hiện trước giai đoạn 7.

**Kiểm chứng phát hiện thực tế:** GitHub Actions chạy 55 kiểm thử;
đúng bốn hồi quy thuộc phát hiện 03 thất bại: 0/1 khi cùng ngày,
4/3 ở mỗi phía Ngày Nền, 1/3 khi băng qua Ngày Nền.
51 kiểm thử còn lại đạt, bao gồm toàn bộ 45 kiểm thử trước đó.
Khóa tên chuẩn đạt độc lập. Giai đoạn 6 đóng ở EXPECTED_RED,
không thêm lớp sửa của giai đoạn 7.

## Giai đoạn 7 — Bản vá 03: vòng tránh hiệu nhãn ngày sai

**Cách bọc:** Giữ `LegacyDistance.old_distance` đúng nguyên trạng.
`DistancePatch` gọi hàm đó trước, lấy
`chronological = abs(target_day - calculation_day)`, rồi dùng
nhánh `if legacy != chronological` để chỉ thay khác biệt.
Kết quả cuối cùng bằng khoảng cách cơ sở sau lựa chọn cộng một.

**Giải thích đúng:** Dù hiệu nhãn sai hay tình cờ bằng khoảng cách
thời gian, sau nhánh so sánh cơ sở luôn đúng bằng `abs(t-c)`.
Vì vậy cộng một luôn cho `abs(t-c)+1` với mọi cặp ngày nguyên,
kể cả ngày trùng, đảo thứ tự và ngày nằm hai phía Ngày Nền.

**Vết lịch sử:** Hàm sai vẫn được thực thi trên đường công khai;
không được tối ưu bỏ qua lần gọi hoặc thay trực tiếp thuật toán
cũ bằng lời gọi tham chiếu thử nghiệm. Các lớp vá SAVE và
nhãn ngày vẫn giữ nguyên hành vi.

**Kiểm thử:** Bốn hồi quy chuẩn từ giai đoạn 6 không sửa.
Các kiểm thử nối dây đòi kết quả sai được cập nhật để xác minh
lỗi lịch sử còn tồn tại bên dưới lớp vá. Mười kiểm thử độc lập mới
được bổ sung, không khởi động giai đoạn 8.

**Bằng chứng hoàn tất:** GitHub Actions xác nhận 65 kiểm thử, 0 lỗi
với Elixir 1.18.5 và OTP 27; khóa tên chuẩn đạt độc lập.
Lần kiểm thử đầu có một lỗi ở ca thử mới phân loại sai nhánh,
không phải do thuật toán sản xuất. Cặp ngày giống nhau có
`legacy == chronological == 0`, thuộc nhánh giữ; ca này được
chuyển sang đúng nhánh, thêm ca khác cho nhánh sửa rồi chạy
toàn bộ kiểm thử xanh. Không đổi bốn hồi quy chuẩn từ phát hiện 03,
không thay `LegacyDistance` và không xóa các lớp vá cũ.
Giai đoạn 7 đã đóng GREEN.

## Giai đoạn 8 — Phát hiện 04: nhiễm bản cập nhật đá nối tiếp

**Giả định cũ:** Có thể tính hàng tiếp theo bằng cách cập nhật từng ô
trên cùng một vùng lưu. Ngay sau khi lúa mì mới được ghi, lúa mạch
đọc lúa mì mới; muối đọc lúa mạch mới; thịt đọc muối mới; cơm
đọc cả lúa mì và thịt mới.

**Điều đã phát hiện:** Các công thức chuẩn phải đọc tất cả năm giá trị
từ hàng cũ. Dùng tuple trung gian đã thay đổi kết quả ngay từ vị trí
lúa mạch của hàng thứ hai. Giá trị lúa mì hàng 2 vẫn đúng vì nó
được tính trước mọi ô khác, nhưng sai số lan sang các hàng tiếp theo.

**Đường thực thi thật:** `bootstrap_context → Dispatcher.bootstrap →
StoneManager.build_table → LegacyStoneMutation.mutate_stones_wrong →
SaveManager.calculate → SavePatch → LegacyRemainder`.
Ngoài ra, cả `stones_table_spaghetti` và `stone_row_spaghetti`
đều đi qua `StoneManager`, không gọi oracle chuẩn.

**Giới hạn:** Không thêm bản chụp hàng cũ, không gọi legacy trên clone,
không ghi đè giá trị sai bằng kết quả chuẩn. Những việc đó chỉ thuộc
giai đoạn 9 PATCH 04. Giữ nguyên các bản vá 01/02/03 và 65
kiểm thử nòng cốt đã được xác minh.

**Xác minh phát hiện:** GitHub Actions với Elixir 1.18.5 và OTP 27
chạy 77 kiểm thử; đúng bốn hồi quy chuẩn của giai đoạn 8 thất bại:
1434/1073 và 3780/2375 ở hàng 2, 147189/146106 ở ô đầu
hàng 3, và toàn bộ tuple của hàng 46. Bảy mươi ba kiểm thử
còn lại đạt, gồm đủ 65 kiểm thử nòng cốt trước đó.

Lần chạy đầu có một cảnh báo import Bitwise thừa trong kiểm thử mới;
xóa import mà không thay mã sản xuất hay kết quả chuẩn. Lần xác minh
sau không có cảnh báo và khóa tên chuẩn độc lập PASS.
Không có bản vá chụp dữ liệu hay sửa đầu ra ở giai đoạn này.
Trạng thái đóng giai đoạn 8 là EXPECTED_RED.
