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

## Giai đoạn 14 — Phát hiện 07: chỉ số sai trong bảng nghiền

**Lỗi lịch sử được tạo trên đường sản xuất:** Bảng
`LegacyGrindTable` chứa 11 hàng nghiền thực từ vị trí
0 đến 10, trong khi bộ đọc `legacy_row(number)` được
viết như thể bảng bắt đầu tại vị trí 1. Bộ đọc gọi
`Enum.at(@real_rows,number,@missing_row)` với number
từ 1 đến 11; giá trị dự phòng cố định tại lần đọc cuối
là `{0,0,0,0,1}`. Hàng thực thứ nhất bị bỏ qua.

**Vết sai có thể tái lập:** Thay vì 11 hàng đúng, mã
dùng hàng thứ 2..11 rồi hàng dự phòng. Bảy giọt ẩn,
ba lần đọc lịch sử qua PATCH 06, bảng đá và SAVE
đều còn đúng. Sai lệch sinh ra trong 11 phép nghiền
mỗi giọt và lan qua các giọt 1..46.

**Bằng chứng kiểm thử:** 14 bài kiểm thử mới gồm kiểm tra
mười lần dịch hàng, fallback, tính độc lập, đối chứng giọt
đầu và giọt cuối, số nguyên rất lớn, mã nguồn và tham số.
Các kiểm thử chuẩn cũ không được sửa để che lỗi mới:
các kiểm thử so sánh giọt nhìn thấy với oracle phải
đỏ cho đến khi bản vá 07 được triển khai.

**Giới hạn của lần phát hiện:** Không đưa sentinel vào
index 0 tại giai đoạn 14. Bản vá 07 của giai đoạn 15
phải thêm sentinel ở index 0, 11 hàng thực tại 1..11,
và giữ nguyên phép đọc chỉ số `legacy_row`. Không
mở các lỗi hoán vị và bát ở các giai đoạn sau.

**Kết quả CI phát hiện 07:** Tổng 151 kiểm thử, 16 sai lệch
đều do hàng nghiền bị đọc lệch một chỉ số (135 bài đạt),
0 cảnh báo biên dịch. Phân loại lỗi: bốn hồi quy chuẩn
mới của giai đoạn 14, năm bài cũ từ giai đoạn 12 và bảy bài
cũ từ giai đoạn 13. Giữ nguyên các kiểm thử cũ, không
sửa kỳ vọng của oracle. Cả mười bài điều khiển Stage14
đều PASS; khóa tên chuẩn PASS. Kết thúc EXPECTED_RED.

## Giai đoạn 15 — Bản vá 07: thêm hàng canh tại ô không

**Di sản vẫn được thực thi:** Hàm
`LegacyGrindTable.legacy_row(number)` giữ nguyên
`Enum.at(@real_rows,number,@missing_row)` và miền number=1..11.
Không thay phép tính number thành number-1, không xóa
hàm legacy, không chỉnh `VisibleDropCalculator` khỏi
đường gọi lịch sử.

**Cách vá:** Thêm `@sentinel_row` tại index 0 của
`@real_rows`, đẩy toàn bộ 11 hàng nghiền chuẩn tới index 1..11.
Sentinel là phần tử thật của bảng, không phải comment hay
giá trị logic bị lọc trước khi đọc. Hàm `row_at_zero`
nay quan sát được sentinel; fallback cũ vẫn giữ nguyên.

**Chứng minh:** Với mọi number từ 1 đến 11, sau khi chèn
sentinel, `Enum.at(@real_rows,number,@missing_row)`
trả đúng hàng nghiền số number. Kết quả 11 lần nghiền cho
giọt đầu khớp oracle; vì mọi tiền nhiệm đã được vá, theo
quy nạp 46 giọt đều khớp. Lịch sử bị lệch ở giai đoạn 14
vẫn thể hiện qua thứ tự cũ trước khi chèn và các đối chứng
trong kiểm thử.

**Kiểm thử:** Giữ nguyên bốn hồi quy chuẩn giai đoạn 14
và các hồi quy cũ. Sửa chỉ mười bài kiểm soát từng đòi
trạng thái lỗi để kiểm trạng thái lịch sử có sentinel.
Thêm 12 kiểm thử mới. Chưa bắt đầu DISCOVERY 08.

**Bằng chứng xác minh:** GitHub Actions chạy 163 kiểm thử,
tất cả đạt, không cảnh báo biên dịch. 16 phép so sánh
normative đã đỏ ở lần phát hiện 07 chuyển sang xanh mà
không sửa kỳ vọng. Có 12 kiểm thử mới đạt và khóa tên PASS.
Một escape dư trong phép kiểm toán chuỗi nguồn được loại
bỏ ở commit kiểm thử riêng, không thay mã sản xuất.

Mã legacy còn nguyên biểu thức tra hàng
`Enum.at(@real_rows, number, @missing_row)`.
Sentinel thật vẫn ở index 0, 11 hàng nghiền ở 1..11.
Giai đoạn 15 khép GREEN, chưa bắt đầu DISCOVERY 08.

## Giai đoạn 16 — Phát hiện 08: hạng hoán vị bị lệch một

**Hàm lịch sử:** `LegacyPermutationUnrank0.old_permutation_unrank0`
dùng hạng từ 0, lấy chữ số giai thừa trong sáu ID bát,
và quay vòng theo 720 hoán vị. Với rank0 = 0, thứ tự là
[1,2,3,4,5,6]; rank0 = 719 tạo thứ tự đảo ngược.

**Sai lầm của lần phát hiện:** `BowlOrderManager` xác định
hạng chuẩn một-based bằng `rem(drop-1,720)+1` nhưng
đưa thẳng giá trị ấy cho hàm gốc không. Đối với hạng 720,
hàm cũ quay vòng thành 0, do đó vẫn trả một hoán vị
hợp lệ nhưng không phải hoán vị chuẩn của hạng 720.
Tất cả 46 thứ tự được tạo trên đường sản xuất thật.

**Ranh giới:** Không sửa thành `one_based-1` trước
giai đoạn 17. Không thay hàm gốc không để nhận hạng một,
không gọi oracle từ production, không tích hợp các phép
rót bát hoặc lỗi tiếp theo của lịch sử.

**Bằng chứng:** 16 kiểm thử mới kiểm tra đủ 720 hạng của
hàm gốc không, chu kỳ ở 720, công thức gán hạng sai,
cả 46 thứ tự, số nguyên rất lớn, đồng thời, mã nguồn
và bốn hồi quy chuẩn cố ý đỏ. Những kiểm thử giai đoạn
1-15 phải tiếp tục xanh.

**Bằng chứng thực tế:** CI chạy 179 kiểm thử với đúng bốn
hồi quy chuẩn đỏ của phát hiện 08, 175 bài đạt, 0 cảnh báo.
Tất cả 163 bài của các giai đoạn 1–15 đều giữ kết quả xanh.
Bốn bài đỏ thuộc hạng 1, hạng 720 và hai giọt biên
trong 46 thứ tự đã tạo. Bộ mở hạng gốc không không sai;
lỗi là hạng từ một được truyền thẳng cho nó.
Khóa tên chuẩn PASS. Đóng giai đoạn 16 ở EXPECTED_RED.

## Giai đoạn 17 — Bản vá 08: giữ hoán vị gốc không

**Vết lỗi lịch sử được bảo tồn:** Hàm
`LegacyPermutationUnrank0.old_permutation_unrank0(rank0)`
không thay đổi; nó tiếp tục coi hạng truyền vào là zero-based
và mở hoán vị bằng sáu bước giai thừa. Chuyển trực tiếp
hạng one-based vào nó vẫn cho hoán vị kế tiếp.

**Bản vá đường gọi:** `BowlOrderManager` tính
`one_based=rem(drop-1,720)+1`, sau đó
`legacy_rank0=one_based-1` và gọi lại chính hàm legacy.
Không triển khai thuật toán mở hạng mới; không sửa hàm
legacy để biết hạng từ một. `Dispatcher.bootstrap` vẫn
tạo đủ 46 thứ tự riêng từ 46 giọt đã vá.

**Chứng minh:** Đối với mọi drop dương, dư sau khi trừ
một nằm trong 0..719. Hàm gốc không với cùng rank0 tương
ứng đúng với hoán vị chuẩn của hạng one-based = rank0+1.
Khi drop là bội 720, one_based = 720 và legacy_rank0 = 719,
do đó nhận hoán vị cuối thay vì hoán vị đầu.

**Kiểm thử:** Bảo toàn bốn hồi quy chuẩn ở giai đoạn 16,
điều chỉnh các bài kiểm soát cũ kiểm chứng lỗi để bảo vệ
vết legacy và kết quả mới. Thêm 14 bài bao phủ 720 thứ tự,
lịch 46 giọt, biên bội 720, số nguyên 2048 bit,
chạy song song và chưa rót bát. Không bắt đầu giai đoạn 18.

**Kiểm chứng thực tế:** CI trên Elixir 1.18.5 / Erlang/OTP 27
hoàn tất 193 kiểm thử, 0 lỗi, không có cảnh báo biên dịch.
Bốn hồi quy chuẩn giai đoạn 16 đều đạt với kỳ vọng nguyên vẹn;
14 kiểm thử mới đạt; khóa tên chuẩn PASS độc lập.

Hàm lịch sử giữ nguyên blob SHA
`d553b2a637e54ca74eb7d6e90b8aab437ed7fc13`.
Oracle test-only giữ nguyên blob SHA
`be1638f46b2190d617af0378a61b077bda10bf32`.
Bản vá 08 kết thúc GREEN. Chưa bắt đầu DISCOVERY 09.

## Giai đoạn 18 — Phát hiện 09: ba nguồn rót dùng vị trí cũ

**Điểm xuất phát:** Các bước SAVE, day tag, distance, đá,
hidden, visible, bảng nghiền và hoán vị sáu bát đã qua
PATCH 01..08. Đường sản xuất mới tính sáu bát ban đầu và
46 bước khuấy với snapshots bất biến trong mỗi lần cập nhật.

**Hàm lỗi lịch sử:** `LegacyPourPositions.read_old`
thực hiện `Map.fetch!(bowls_old,position)` với position
thuộc 1..3. Nó không biết rằng hoán vị hiện tại ánh xạ
mỗi vị trí sang một ID bát khác. Ba phép rót dùng
`drop² + stone(position)*old[position] + (2*position+1)*i`
bên trong SAVE. Công thức chuẩn phải dùng
`old[order[position]]`.

**Ranh giới trách nhiệm:** Chỉ phép đọc nguồn ba lần
rót được làm sai; kết quả cập nhật của mỗi vị trí vẫn
được lưu dưới ID bát thật, các bát trước/sau vẫn đọc từ
`old`. Không đưa lỗi contamination in-place hay lỗi latch
sớm hơn các giai đoạn đã định.

**Bản vá tương lai:** PATCH 09 sẽ giữ
`LegacyPourPositions` nhưng định tuyến
`bowlAlias[position]=order[position]` tới mỗi lần
đọc của ba phép rót. Không đổi thứ tự bát đã vá hoặc
hệ số của công thức.

**Kiểm thử:** 16 bài mới: 12 điều khiển vị trí sai,
phép SAVE, một bước đúng khi order là đồng nhất,
sáu bát khởi đầu, 46 bước, biến lớn, chạy đồng thời,
các bản vá cũ và kiểm toán nguồn; bốn hồi quy chuẩn
cố ý đỏ ở rót trực tiếp, một bước khuấy và kết quả cuối.

**Kết quả CI đã kiểm chứng:** 209 kiểm thử, đúng bốn hồi
quy chuẩn đỏ, 205 bài đạt, không cảnh báo biên dịch.
193 bài kiểm thử từ giai đoạn 1 tới 17 không hồi quy;
12 bài kiểm soát mới đạt, khóa tên chuẩn độc lập PASS.
Bốn sai lệch thuộc nguồn rót 1, bước khuấy đầu và kết
quả sau 46 giọt ở các ngày khác nhau. Phần khuấy đọc
snapshot cũ và ghi next riêng như công thức chuẩn.
Không thêm alias của giai đoạn 19. Đóng EXPECTED_RED.

## Giai đoạn 19 — Bản vá 09: bảo tồn legacy và thêm bản xem alias

**Hàm lịch sử còn nguyên:** `LegacyPourPositions` vẫn lấy
`Map.fetch!(bowls_old,position)` cho các vị trí 1..3.
Khi được gọi trên map sáu ID bát thật, nó vẫn đọc ID sai
như bằng chứng của DISCOVERY 09. Không có sửa chữa bên
trong hàm legacy, không thay vị trí hay hệ số rót.

**Lớp vá:** `BowlAliasPatch.alias_view(old,order)` ánh xạ
ba khóa vị trí tới `old[order[position]]`. `pour` chuyển
bản xem này vào đúng hàm legacy hiện có, để ba lời gọi
vị trí 1..3 đều qua alias. Các phép khuấy của sáu bát
tiếp tục đọc snapshot `old` thật, ghi map `next` mới;
không mở lỗi ghi đè in-place giai đoạn 20.

**Chứng minh:** Với mọi hoán vị hợp lệ, mỗi `position`
trong 1..3 được ánh xạ đúng đến ID của vị trí đó.
Legacy dùng đúng khóa `position` trong bản xem, do đó
có cùng giá trị đầu vào và SAVE như công thức chuẩn.
Vì sáu phép khuấy và snapshot `old` đã đúng, trạng thái
sau giọt đầu chính xác; quy nạp qua 46 giọt chứng minh
kho `bowls_after_drops` chính xác.

**Kiểm thử:** Giữ bốn hồi quy chuẩn giai đoạn 18, sửa
riêng tiền xử lý và kiểm tra cấu trúc cần thiết,
thêm 14 bài thử, giữ bất biến các bản vá 01..08 và
không thay oracle. Giai đoạn 20 chưa khởi động.

**Kết quả CI thực tế:** 223 kiểm thử, 0 lỗi,
0 cảnh báo biên dịch, khóa tên chuẩn PASS.
Bốn hồi quy chuẩn từ giai đoạn 18 đạt với kỳ vọng nguyên vẹn,
14 bài kiểm thử mới đạt. LegacyPourPositions vẫn nguyên
blob SHA `6ab77efeb07c74fb88fe1d62ad04c523d23c3c80`,
oracle test-only vẫn nguyên blob SHA
`be1638f46b2190d617af0378a61b077bda10bf32`.
Kết thúc giai đoạn 19 GREEN, chưa bắt đầu DISCOVERY 10.

## Giai đoạn 20 — Phát hiện 10: ô nhiễm in-place giữa các vị trí

**Di sản mới:** `LegacyInPlaceStir.compute_one` chứa
công thức chuẩn của mỗi lần khuấy sáu bát, kể cả các ID
láng giềng từ thứ tự hoán vị, SAVE và loại đá tương ứng.
`LegacyInPlaceStir.run` thực hiện `Enum.reduce`
qua 1..6, đọc map `current`, rồi lập tức
`Map.put(current,id,updated)`. Dữ liệu vừa được cập nhật
được chuyển vào lần khuấy tiếp theo. Đây là lỗi in-place
về mặt ngữ nghĩa dù cấu trúc dữ liệu Elixir bất biến.

**Biên lỗi:** `BowlAliasPatch` vẫn cung cấp ba giá trị
rót từ ID chính xác trên snapshot ban đầu của bước.
Dữ liệu đầu vào, giọt nhìn thấy, vị trí hoán vị,
hệ số khuấy và thứ tự ghi ID không đổi. Chỉ nguồn đọc
của vòng khuấy thứ 2..6 bị nhiễm giá trị cập nhật.

**Điều phải sửa ở giai đoạn 21:** Bảo tồn LegacyInPlaceStir,
tạo `vaultOld` từ trạng thái đầu vòng; mỗi vị trí tính bằng
`compute_one(vaultOld,...)`, ghi kết quả vào `pending`,
và chỉ sau sáu phép tính mới hợp nhất vào kho bát.
Chưa thực hiện vault hay pending trong giai đoạn này.

**Chứng cứ:** 16 bài kiểm thử mới gồm bước đầu vẫn chuẩn,
đọc giá trị bị ghi đè ở vị trí thứ hai, mô phỏng vòng 6,
nguồn rót chính xác, miền SAVE, 46 giọt và nhiều ngữ cảnh.
Bốn hồi quy chuẩn mới cố ý đỏ. Giữ các kiểm thử chuẩn cũ
dù ảnh hưởng dây chuyền tạo thêm lỗi mong đợi.

**Kết quả xác minh:** CI ghi nhận 239 kiểm thử,
14 sai lệch chuẩn được phân loại, 225 kiểm thử đạt,
không cảnh báo. Phân loại 14 ca: bốn hồi quy mới Stage20,
sáu ca nguồn khuấy chuẩn Stage18 và bốn ca Stage19.
Tất cả 12 bài kiểm soát Stage20 đạt, khóa tên chuẩn PASS.
Những khẳng định normative trước đó được giữ nguyên
để không che lỗi mới. Hàm legacy dùng map current đã
được cập nhật sau mỗi vị trí, nguồn rót từ BowlAliasPatch
vẫn chính xác. Kết thúc Stage20 EXPECTED_RED.

## Giai đoạn 21 — Bản vá 10: snapshot và commit sáu bát

**Di sản không sửa:** `LegacyInPlaceStir.run` vẫn
thực hiện Enum.reduce với map `current` rồi
Map.put ngay sau mỗi vị trí; gọi nó trực tiếp vẫn
tạo ô nhiễm. `LegacyInPlaceStir.compute_one`
vẫn chứa công thức chuẩn của một vị trí.

**Bản vá:** Module mới `BowlVaultPatch` tạo
`vault_old=old` trước khi bắt đầu. Sáu lần gọi
`LegacyInPlaceStir.compute_one` lấy duy nhất map này.
Mọi giá trị tính ra được cất trong `pending`, chưa
được dùng làm nguồn cho vị trí sau. Sau sáu vị trí,
`Map.merge(vault_old,pending)` thực hiện commit chung.
Elixir vẫn giữ giá trị old bất biến cho caller.
`BowlDropCalculator.step` dùng lớp vá này mà vẫn
dùng BowlAliasPatch cho ba nguồn rót.

**Chứng minh:** Với bất kỳ hoán vị ID hợp lệ của sáu
bát, các lần tính vị trí đều đọc cùng trạng thái
`vault_old`; công thức trong compute_one chính là
công thức oracle. Sáu ID đích là một hoán vị nên
`pending` chứa đủ đúng sáu khóa không trùng nhau.
Commit cuối áp dụng sáu giá trị đồng thời. Quy nạp
qua 46 giọt cho sáu bát đúng, không sửa lỗi từ các
giai đoạn khác. Giữ nguyên hồi quy cũ, thêm 14 bài.
Chưa bắt đầu DISCOVERY 11.

**Kiểm chứng Stage21:** CI 253 kiểm thử, tất cả xanh,
0 cảnh báo, khóa tên chuẩn PASS. Bốn hồi quy Stage20,
sáu hồi quy Stage18 và bốn hồi quy Stage19 đều xanh
với khẳng định oracle cũ không đổi. 14 kiểm thử Stage21
mới đạt. Lần đầu có warning unused alias trong kiểm thử
kiểm soát; đã dùng alias trong kiểm tra vault trực tiếp,
không cần đổi production và chạy lại CI 0 warning.

`LegacyInPlaceStir` giữ nguyên blob SHA
`49554b37e329adb05e4f2ee77b8f51a69e944d4b`.
Oracle test-only giữ nguyên blob SHA
`be1638f46b2190d617af0378a61b077bda10bf32`.
Bản vá dùng cùng vaultOld cho sáu kết quả pending,
chỉ sau đó áp dụng Map.merge. Kết thúc Stage21 GREEN,
chưa mở Stage22.

## Giai đoạn 22 — Phát hiện 11: mất hoán vị giọt 46 vì ghi đè

**Nền:** Giai đoạn 21 đóng GREEN với 253 bài kiểm thử
đạt và 0 cảnh báo. Hệ thống đã tính đúng 46 giọt và
sáu bát kết quả tại giọt 46.

**Mở rộng đúng:** `PostStirCalculator` thực hiện
12 lượt khuấy cuối theo đúng hợp đồng: saved sum
bằng SAVE của tổng sáu giá trị old cộng 149*stir;
hoán vị dựa trên saved sum; sáu phép tính đọc chung
snapshot old; giá trị khuấy lưu SAVE với hệ số 3,5,7.
Đầu ra `bowls_after_post_stirs` phải chính xác
với oracle, không thêm sai số số học.

**Dấu vết lỗi mới:** `LegacyOrderMemory` ghi
đè một ô `order`: 46 lần từ các giọt, 12 lần từ khuấy.
Sau 58 lần, `last_source={:stir,12}`. Thứ tự giọt 46
vẫn có trong map các giọt nhưng không được chốt thành
latch dành cho truy vấn. `next_bowl` đọc ô overwritable
nên dùng thứ tự lần khuấy thứ mười hai và sai chuẩn.
Không thêm latch, không sửa hàm legacy hoặc oracle
trong giai đoạn 22.

**Bằng chứng kiểm thử:** 12 bài điều khiển xác nhận
cả 58 lần ghi, đủ 12 lượt và kết quả bát chuẩn,
giữ bất biến 253 kiểm thử trước. Bốn hồi quy mới
cố ý đỏ ở thứ tự kế cận của các ID và nhiều ngày.
PATCH 11 tại giai đoạn 23 sẽ cần chốt orderAt46
và đọc latch đó để sửa mà không xóa di sản 58 lần ghi.

**Kết quả kiểm chứng:** CI Elixir 1.18.5 / OTP 27
có 269 kiểm thử, đúng bốn hồi quy chuẩn đỏ thuộc
truy vấn next-bowl Stage22, 265 bài đạt, 0 cảnh báo.
Toàn bộ 253 bài Stage1..21 đạt. Bài kiểm toán nguồn
Stage18 được cập nhật theo tên hàm bootstrap mới,
một alias Stage22 được dùng trực tiếp; không đổi
hàm sản xuất hoặc khẳng định normative.
Khóa tên chuẩn PASS độc lập.

Bộ nhớ bị ghi đủ 58 lần, nguồn cuối là {:stir,12}.
Sáu bát sau 12 lần khuấy hoàn toàn đúng với oracle,
nhưng query lấy thứ tự post-stir cuối, không phải giọt 46.
Không thêm orderAt46Latch; đóng Stage22 EXPECTED_RED.

## Giai đoạn 23 — Bản vá 11: latch thứ tự giọt 46

**Giữ nguyên di sản:** Module `LegacyOrderMemory`
vẫn chứa đúng `order`, `writes`, `last_source`
và ghi đè `order` 58 lần. Module `PostStirCalculator`
tiếp tục thực hiện đúng 12 lượt khuấy cuối, sau đó bộ
nhớ lịch sử vẫn trỏ tới thứ tự của stir 12.

**Tách chốt đúng thời điểm:** Sau 46 giọt,
`memory_after_drops` phải mang
`writes=46,last_source={:drop,46}`. Khi ấy
`OrderAt46LatchPatch.capture` sao chép về mặt ngữ nghĩa
thứ tự sáu ID sang `Context.order_at_46_latch`.
Vì dữ liệu Elixir bất biến, các lần ghi tiếp theo trả
map LegacyOrderMemory khác và không thể đụng đến chốt.

**Đường truy vấn:** `Dispatcher.next_bowl` không đọc
`order_memory.order` nữa mà truyền latch vào
`OrderAt46LatchPatch.next_bowl`, rồi lớp vá gọi thực
`LegacyOrderMemory.next_bowl(%{order: latch}, id)`.
Do đó vẫn thực thi thuật toán legacy thật, chỉ thay
nguồn thứ tự thành đúng hoán vị giọt 46.

**Kiểm thử:** Bảo toàn bốn hồi quy chuẩn Stage22
trong khi đổi hai kiểm soát lịch sử để so sánh riêng
legacy sai và production đúng. Thêm 14 bài kiểm
toán 720 hoán vị, 58 lần ghi, tính độc lập ngữ cảnh,
số nguyên lớn, đầu vào không hợp lệ và ranh giới.
Không thay oracle, SAVE hoặc các giá trị bát cuối.

**Kết quả thực tế:** CI Elixir 1.18.5 / OTP 27:
283 kiểm thử, 0 lỗi, 0 cảnh báo biên dịch;
Canonical Names Lock PASS. Bốn hồi quy chuẩn Stage22
đạt với khẳng định cũ; 14 kiểm thử Stage23 mới đạt.
LegacyOrderMemory giữ nguyên blob SHA
`4d7610e41443d4a37d60befa76a456cd8c85e06d`;
oracle giữ nguyên blob SHA
`be1638f46b2190d617af0378a61b077bda10bf32`.
Memory vẫn bị ghi 58 lần, latch riêng lưu thứ tự giọt
46 để truy vấn. Giai đoạn 23 đóng GREEN, chưa mở Stage24.

## Giai đoạn 24 — Phát hiện 12: vòng tên ID cố định

**Di sản mới:** `LegacyFixedNameSuccessor` trả
`rem(id,6)+1` với ID 1..6, tương đương
1→2→3→4→5→6→1. Không tìm ID đang hỏi trong
`orderAt46Latch`, dù latch đã được PATCH 11
chốt chuẩn ở giọt 46.

**Đường production lỗi có chủ đích:** `Dispatcher.next_bowl`
bootstrap toàn bộ context, nhưng chỉ dùng
`LegacyFixedNameSuccessor.old_next_bowl_fixed_name`
thay vì thuật toán đọc hoán vị của latch. Sáu ID bát,
12 post-stir và 58 lần ghi memory giữ nguyên. Công thức
SAVE, stone, hidden, visible và các bản vá 01..11
không bị sửa. Lỗi chỉ ở cách chọn ID kế cận.

**Chứng cứ:** Với latch [4,5,2,3,6,1], ID 3 có kế
cận 6, còn legacy trả 4. ID 1 và 5 cũng sai.
Đủ 720 hoán vị, chỉ 6 thứ tự xoay của vòng cố định
có ánh xạ next-bowl trùng vòng tên legacy.

**Giai đoạn 25:** Không được xoá hay thay hàm
legacy; phải dùng nó để ghi nhận kết quả chẩn đoán
nhưng trả `nextBowlFromOrderAt46Latch` bằng cách
tìm vị trí ID rồi lấy phần tử tiếp theo mod 6. Chưa
triển khai trong DISCOVERY 12. Giữ mọi hồi quy chuẩn,
phân loại số thất bại từ CI trước khi đóng giai đoạn.
