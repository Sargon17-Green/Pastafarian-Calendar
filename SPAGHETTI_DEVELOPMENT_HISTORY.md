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

## Giai đoạn 9 — Bản vá 04: chụp lại hàng cũ trước khi cập nhật đá

**Giữ lỗi lịch sử:** `LegacyStoneMutation.mutate_stones_wrong`
vẫn cập nhật năm vị trí nối tiếp, đọc lại các ô vừa ghi. Không sửa
tệp legacy và không loại bỏ lời gọi của nó.

**Bọc lỗi:** `StonePatch.patch_row` chụp `old_snapshot`,
tạo `legacy_clone` từ năm giá trị, gọi thật hàm lịch sử để
nhận `garbage` rồi ghi đè cả năm ô trên tuple ấy, mỗi phép tính
chỉ đọc năm giá trị của `old_snapshot`. `StoneManager`
dùng lớp bọc này cho tất cả hàng từ 2 đến 46.

**Vì sao đúng:** Cả năm công thức chuẩn chỉ phụ thuộc hàng trước.
Vì mọi ô được ghi đè bằng chính công thức ấy, hàng 2 khớp chuẩn;
theo quy nạp, cả 46 hàng khớp bộ tham chiếu, mà hàm lịch sử
vẫn được thực thi thật trong cùng đường sản xuất.

**Kiểm thử:** Giữ nguyên bốn kỳ vọng hồi quy chuẩn của giai đoạn 8;
điều chỉnh chỉ các kiểm thử dây nối dựa vào kết quả sai công khai.
Thêm 11 kiểm thử về công thức, điều kiện biên, số nguyên tùy ý,
độc lập context và song song. Không khởi động giai đoạn 10.

**Bằng chứng đóng:** GitHub Actions chạy 88 kiểm thử, 0 lỗi,
không cảnh báo biên dịch, khóa tên chuẩn PASS độc lập.
`LegacyStoneMutation` giữ blob SHA
`91260b89961571e9c96a0f0e563c27115c1aa697`.
Giai đoạn 9 khép GREEN.

## Giai đoạn 10 — Phát hiện 05: đảo thứ tự lưu trữ giọt ẩn

**Điều từng được tin:** Bộ lưu trữ bảy giọt dùng tuple theo
thứ tự `hidden7, hidden6, ..., hidden1`, nhưng phần đọc cũ
lại giả định `hidden1` nằm ở ô đầu. Hàm cũ đọc ô `k` cho
giọt ẩn mang tên `k`.

**Giá trị đúng và chỗ sai:** `HiddenDropCalculator` tự tính
chính xác bảy giọt, dùng năm đếm công việc, hệ số riêng cho
mỗi giọt, bảy lần nghiền cùng các giá trị đá từ bảng chuẩn.
Không phải lỗi tính số. Sai số xuất hiện khi
`LegacyHiddenStorage.store_reversed` đưa hidden7 vào ô 1
và `read_as_if_forward` đọc trực tiếp ô đó như hidden1.
Ô giữa dành cho hidden4 là đối chứng khớp tình cờ.

**Đường thực thi sản xuất:** `hidden_drop_spaghetti →
Dispatcher.hidden_drop → HiddenDropManager.read →
LegacyHiddenStorage.read_as_if_forward`. Bảng ban đầu được
xây qua `HiddenDropManager.build_storage →
HiddenDropCalculator.calculate → SaveManager.calculate`
và sau đó được đảo trong `LegacyHiddenStorage.store_reversed`.
`bootstrap_context` tự sở hữu bản tuple cho mỗi lần gọi.

**Giới hạn lịch sử:** Giữ nguyên việc lưu đảo ngược và việc
đọc sai. Không xây bộ truy cập vá địa chỉ 8-k; việc sửa thuộc
giai đoạn 11. Không mở nhánh lỗi đọc lịch sử ẩn/hiện của
giai đoạn 12 trước hạn.

**Kiểm thử:** Thêm 13 kiểm thử mới, bốn hồi quy chuẩn mong đợi
đỏ tại giọt 1, 2, 3 và 7. Kiểm thử kiểm soát xác minh số học
đúng, thứ tự đảo, giọt giữa đúng, tính độc lập của context,
số nguyên rất lớn, lỗi đầu vào và các bản vá 01-04.

**Kiểm chứng thực tế:** GitHub Actions biên dịch 22 tệp Elixir,
chạy 101 kiểm thử; đúng bốn hồi quy chuẩn của phát hiện 05 thất bại
tại hidden1, hidden2, hidden3, hidden7. 97 kiểm thử còn lại đạt.
Kiểm thử riêng xác nhận `HiddenDropCalculator` tạo cả bảy giá trị
đúng bằng oracle và tuple lưu thứ tự đảo. Hidden4 là đối chứng xanh.
Đã bổ sung trực tiếp hai phép thử mô-đun sản xuất để hết cảnh báo
alias chưa dùng; không sửa mã sản xuất hoặc kỳ vọng chuẩn.
Kết quả cuối không có cảnh báo biên dịch, khóa tên chuẩn PASS.
Giai đoạn 10 khép EXPECTED_RED; chưa có lớp vá 05.

## Giai đoạn 11 — Bản vá 05: sửa địa chỉ đọc giọt ẩn

**Lỗi không bị xóa:** `LegacyHiddenStorage.store_reversed`
vẫn lưu `hidden7` ở ô 1 và `hidden1` ở ô 7; hàm cũ
`read_as_if_forward(storage,k)` vẫn đọc trực tiếp ô `k`,
nên sai với sáu tên giọt ngoài giọt thứ tư.

**Cách đi vòng:** Tầng `HiddenStoragePatch.read_hidden`
dùng `legacy_position = 8-k` để định vị giọt số k,
sau đó gọi lại `LegacyHiddenStorage.read_as_if_forward`
ở vị trí đã ánh xạ. Nhờ đó không cần và không được
đảo tuple đang lưu. Bộ tính `HiddenDropCalculator`
không thay đổi và tiếp tục dùng các bản vá trước.

**Lý do đúng:** Phần tử ở vị trí p của kho đảo tương ứng
với giọt số `8-p`. Khi thay `p=8-k`, phần tử đó
tương ứng đúng với giọt k. Đẳng thức đúng cho cả bảy
giá trị, kể cả giọt 4 có địa chỉ đối xứng.

**Kiểm thử:** Giữ nguyên cả bốn hồi quy chuẩn của
phát hiện 05; sửa riêng các khẳng định dây nối từng
đòi kết quả công khai sai. Bổ sung mười bài kiểm thử
để chứng minh kho vẫn đảo, hàm cũ vẫn sai, truy cập
qua lớp vá đúng, không thay đổi trạng thái giữa các lần gọi,
và bảo toàn các bản vá 01–04. Không bắt đầu phát hiện 06
của giai đoạn 12.

**Kiểm chứng thực tế:** GitHub Actions đã biên dịch 23 tệp sản xuất
trong Elixir 1.18.5, OTP 27, chạy **111 kiểm thử, 0 thất bại**
và không cảnh báo biên dịch. Mười bài mới đều đạt; bốn hồi quy
chuẩn của phát hiện 05 đã chuyển thành đạt với kỳ vọng không đổi.
Kho `LegacyHiddenStorage` giữ nguyên blob SHA
`cb00f07e880368cf3aa4be81546944bd09bfa4c1`.
Bộ tính `HiddenDropCalculator` giữ nguyên blob SHA
`5afcaf5cff02a84fbbd92398b134adc34a08c885`.
Khóa tên chuẩn đạt độc lập. Giai đoạn 11 kết thúc GREEN.

## Giai đoạn 12 — Phát hiện 06: đọc lịch sử chỉ trong kho nhìn thấy

**Giả định lịch sử sai:** Một giọt nhìn thấy được tính từ
các giọt trước đó bằng cách đọc trực tiếp `visible_store[i-back]`
với `back` bằng 1, 3 hoặc 7. Chưa phân biệt những ô trước
giọt số 1 thuộc bảy giọt ẩn, vốn lưu riêng.

**Tình trạng trong lần phát hiện:** `LegacyPrior.legacy_prior`
chỉ tra kho giọt nhìn thấy và dùng số 0 cho ô không có.
Các vị trí 0 đến -6 thiếu tại các bước đầu nên sai số
đi vào công thức ngay từ giọt 1, sau đó lan qua 46 giọt.
Ở giọt 8 trở đi, tất cả ba vị trí trước đều thuộc kho
nhìn thấy và bản thân lookup cũ hoạt động đúng, nhưng
các giá trị đã được xây từ lịch sử sai.

**Đường thực thi:** `visible_drop_spaghetti →
Dispatcher.visible_drop → VisibleDropManager.read`.
Kho được tạo trong `Dispatcher.bootstrap` qua
`VisibleDropManager.build → VisibleDropCalculator.calculate →
LegacyPrior.legacy_prior`. Nhánh giọt ẩn vẫn tồn tại và
đọc đúng qua PATCH 05, nhưng không được dùng trong lookup này.

**Giới hạn:** Không thêm nhánh `slot>=1` hay ánh xạ
`hidden_number=1-slot` của PATCH 06 vào mã sản xuất.
Không tích hợp phép nghiền với bát, thứ tự hoán vị
hoặc lịch cuối trước giai đoạn riêng.

**Kiểm thử:** Bốn hồi quy chuẩn cố ý đỏ ở giọt 1, 2, 7, 46;
mười một bài kiểm soát xác nhận lookup cũ, 46 ô,
số nguyên lớn, bảng đá và kho giọt ẩn còn đúng,
thực thi song song, kiểm tra nguồn và bảo vệ ranh giới.

**Bằng chứng thực tế:** GitHub Actions trên Elixir 1.18.5
và OTP 27 đã biên dịch 26 tệp nguồn, chạy 126 kiểm thử.
Đúng bốn hồi quy chuẩn từ lần phát hiện 06 thất bại ở
giọt nhìn thấy 1, 2, 7 và 46; 122 kiểm thử khác đạt,
bao gồm đủ 111 bài cũ. Khóa tên chuẩn PASS.
Lần chạy ban đầu cảnh báo việc dùng `Map.take` với Range
trong kiểm thử mới. Chỉ điều chỉnh kiểm thử sang `Map.filter`,
không sửa mã sản xuất hoặc kỳ vọng chuẩn. Lần kiểm chứng cuối
không cảnh báo biên dịch. Giai đoạn 12 khép EXPECTED_RED;
bản vá đọc giọt ẩn của giai đoạn 13 chưa được thêm.

## Giai đoạn 13 — Bản vá 06: phân nhánh địa chỉ giọt quá khứ

**Di sản còn sống:** `LegacyPrior.legacy_prior` tiếp tục
lấy `visible_store[i-back]` và trả 0 khi vị trí vắng.
Không sửa hoặc xóa hàm này. Kho các giọt nhìn thấy và
tuple bảy giọt ẩn tiếp tục có chủ sở hữu riêng.

**Lớp vá mới:** `PriorPatch.read` tính `slot=i-back`.
Khi `slot>=1`, gọi lại hàm legacy trên kho giọt nhìn thấy;
khi `slot<=0`, ánh xạ `hidden_number=1-slot` và
đọc qua `HiddenDropManager.read`, vốn dùng ánh xạ 8-k
đã hoàn thành ở bản vá 05. `VisibleDropCalculator`
thay ba lần gọi legacy trực tiếp bằng ba lần gọi bản vá,
nhận tuple ẩn từ `Dispatcher.bootstrap`.

**Chứng minh:** Với mỗi i từ 1 đến 46 và các bước lùi
1, 3, 7, slot thuộc một trong hai miền rời nhau.
Ở miền dương, nó ứng đúng với giọt nhìn thấy đã tính;
ở miền không dương, vị trí 0..-6 ứng đúng hidden1..7.
Vì cả ba giá trị trước được lấy đúng, công thức 11 phép
nghiền cho giọt đầu chính xác; theo quy nạp toàn bộ
46 giọt tiếp theo chính xác. Cách tính, SAVE và đá
đã được kiểm chứng ở các giai đoạn trước.

**Giới hạn:** Bảo toàn bốn hồi quy chuẩn từ giai đoạn 12;
sửa riêng các khẳng định dây nối từng đòi kết quả sai.
Không bắt đầu lỗi bảng nghiền có chỉ số lệch
của giai đoạn 14 hoặc thay đổi các nguồn chuẩn.

**Kiểm chứng cuối:** Trong Elixir 1.18.5, Erlang/OTP 27,
CI chạy 137 kiểm thử, 0 lỗi và không có cảnh báo biên dịch.
Bốn hồi quy chuẩn của giai đoạn 12 đều chuyển sang đạt
mà không đổi kỳ vọng. Mười một kiểm thử mới đều đạt;
khóa tên chuẩn PASS.

`LegacyPrior` không đổi, blob SHA
`4c2b416bf089f8a538908fd4d310bcb6900c2419`.
Oracle test-only không đổi, blob SHA
`be1638f46b2190d617af0378a61b077bda10bf32`.
Đóng giai đoạn 13 ở GREEN; chưa bắt đầu DISCOVERY 07.
