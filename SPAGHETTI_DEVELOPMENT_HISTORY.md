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

**Kết quả CI thực tế:** Elixir 1.18.5 / OTP 27,
301 kiểm thử, 12 sai lệch đã phân loại, 289 bài đạt,
0 cảnh báo, Canonical Names Lock PASS. Bốn bài Stage24,
sáu bài Stage22, hai bài Stage23 đỏ do fixed-name
successor thay cho vị trí trong latch. Các bài còn lại
đều đạt. Hai kiểm toán nguồn từ CI đầu đã được cập
nhật, một alias unused đã dùng trong kiểm thử;
không thay các phép so chuẩn hay số học production.
Giai đoạn 24 đóng EXPECTED_RED. Kế tiếp PATCH 12
phải bảo tồn và thực thi legacy cố định cho chẩn đoán,
trả kết quả từ vị trí thực trong latch.

## Giai đoạn 25 — Bản vá 12: giữ vòng ID làm bằng chứng, trả kết quả từ latch

**Di sản:** `LegacyFixedNameSuccessor` giữ nguyên,
vẫn tính `rem(id,6)+1` mà không biết thứ tự bát.
Với dữ liệu fixture Stage24, hỏi ID 3 trực tiếp qua
legacy vẫn cho 4, không phải 6. Không có sửa
LegacyOrderMemory, OrderAt46LatchPatch hoặc các bước
tính bát và giọt trước đó.

**Bản vá mới:** `NextBowlPatchWrapper` gọi
`LegacyFixedNameSuccessor.old_next_bowl_fixed_name`
cho mỗi truy vấn và cất kết quả vào trường
`legacy_next_id` của chẩn đoán. Nó gọi tiếp
`OrderAt46LatchPatch.next_bowl(order_at_46_latch,id)`
để tính `correct_next_id`, sử dụng đúng vị trí của
ID trong hoán vị đã chốt, kể cả vòng từ vị trí cuối
về đầu. Cờ `diverges` phản ánh sự khác nhau giữa
hai giá trị; `next_bowl` chỉ trả kết quả đúng.

**Bảo toàn:** Cả 58 lần ghi legacy, thứ tự giọt 46,
12 lần khuấy cuối và mọi giá trị SAVE được giữ.
Các so sánh oracle thuộc Stage22..24 không đổi kỳ vọng,
các kiểm soát Stage24 tách hành vi legacy trực tiếp
khỏi lời gọi production. Bổ sung 16 bài kiểm thử về
tất cả 720 hoán vị, dữ liệu xa, bối cảnh song song,
giới hạn và chẩn đoán trực tiếp. Giai đoạn 26 chưa mở.

**Kết quả thực tế Stage25:** 317 kiểm thử Elixir 1.18.5,
OTP 27, 0 lỗi, 0 cảnh báo biên dịch. Canonical Names Lock
PASS. Cả 12 sai lệch trước đây từ Stage22/23/24 đã
trở lại xanh; 16 bài thử Stage25 mới đạt.
Hàm cố định lịch sử vẫn được gọi và giá trị sai
được cất trong chẩn đoán, nhưng đường sản xuất trả
đúng successor từ chốt giọt 46.

LegacyFixedNameSuccessor blob SHA
`56397c39d13a4a1b7bc345d98c5b37029b3fcdf0`;
LegacyOrderMemory blob SHA
`4d7610e41443d4a37d60befa76a456cd8c85e06d`;
OrderAt46LatchPatch blob SHA
`9c695184dbe79cdccd6250915d5ac09128c96f9d`;
oracle test-only blob SHA
`be1638f46b2190d617af0378a61b077bda10bf32`.
Không mở giai đoạn 26; đóng Stage25 GREEN.

## Giai đoạn 26 — Phát hiện 13: phép modulo thiên lệch trước từ chối

**Phần tính đúng được mở:** Từ sáu bát hoàn chỉnh và
ID kế tiếp đã vá, `AnswerStreamManager.build`
tính first, direction_step theo hai công thức SAVE chuẩn,
và `answer_at(k)` theo vòng 1..M với chiều +/-1.
Với k lớn hơn M, kết quả vẫn quấn vòng chính xác.
Không có lỗi trong nguồn bát, seal hoặc modulo vòng.

**Di sản lỗi mới:** `LegacyBiasedPick.biased_legacy_pick`
thực hiện `rem(x-1,n)+1` ngay. Đường thực
`AnswerStreamManager.choose_rank_short_biased` chỉ
lấy x=answer_at(0) và gọi legacy tức thời, bất kể
x>floor(M/n)*n. Đây là lựa chọn sai về tính đều xác suất,
không phải lỗi SAVE hoặc trường vòng đáp án.

**Chứng cứ:** Với M=2^127-1, n=floor(M/2)+1,
limit=n và vòng có first=M,step=+1, lựa chọn chuẩn
loại x=M, nhận x=1 và trả hạng 1. Legacy không loại
và trả n-1. Các mẫu first=M-1, hoặc n=M-3 với chiều
đi +/-1 cũng tạo sai lệch hữu hạn. Khi n=M hoặc n=1,
không cần loại, legacy vẫn trả đúng. Bốn hồi quy
normative mới phải đỏ trong DISCOVERY 13.

**Yêu cầu Stage27:** Giữ hàm legacy và gọi nó thật
chỉ sau khi đã nhận x thỏa `x<=limit`. Dùng chính
AnswerStreamManager.answer_at với chỉ số k tăng
trên cùng vòng, không lấy ngẫu nhiên mới hoặc đổi
hướng. Chưa thực hiện ở Stage26.

**Kết quả thực tế DISCOVERY 13:** CI Elixir 1.18.5,
OTP 27: 336 kiểm thử, đúng bốn sai lệch normative
mới Stage26, 332 bài đạt, không cảnh báo; Canonical
Names Lock PASS. Tất cả 317 test cũ và 15 kiểm soát
Stage26 vẫn đạt. Lần CI đầu có thêm một test sai
cho k=0, đã sửa danh sách đầu vào kiểm soát;
không đổi implementation, không đổi các assert
normative. Vòng đáp án đã chuẩn, chỉ lựa chọn
x=answerAt(0) thiếu rejection khiến modulo thiên lệch.
Stage26 đóng EXPECTED_RED, chưa làm PATCH 13.

## Giai đoạn 27 — Bản vá 13: rejection trên cùng answer ring

**Giữ legacy:** Hàm `LegacyBiasedPick` vẫn chọn
`1+rem(x-1,n)` và không biết giới hạn. Nó được
gọi thực trong đường chọn hạng, nhưng từ đây chỉ
sau khi lọc x hợp lệ bằng lớp vá mới.

**Đường sản xuất:** `AnswerStreamManager` giữ
nguyên các công thức SAVE, first, direction_step
và answer_at(k). `choose_rank_short_biased`
định tuyến qua `ShortRejectionPatch`.
Lớp này tính `limit=div(M,n)*n`, đọc tuần tự
`answer_at(stream,0)`, rồi k=1,2,... khi x>limit.
Chỉ khi có x<=limit, gọi hàm legacy chính xác
một lần và dùng kết quả trả về. Trace riêng chỉ
ghi vị trí, giá trị đã nhận, số lần bác bỏ và rank;
không thay trạng thái stream hay dùng số ngẫu nhiên.

**Chứng minh:** Vì `answer_at` đi trong vòng đủ
M số với bước +/-1, mọi n hợp lệ có limit>=1 và
sẽ gặp giá trị được nhận. Chuỗi bị bác bỏ có thể
dài; vòng không đặt giới hạn tùy tiện. Ở n=M hoặc
n=1, không có phần tử bị bỏ và legacy được gọi
ngay. Dùng fixture x=M,M-1 với n sát M để quan sát
1..3 lần bác bỏ mà không cần chờ vòng lớn.

Bốn hồi quy Stage26 sẽ quay về xanh với expected
oracle giữ nguyên. Thêm 18 kiểm thử Stage27,
không sửa các lỗi lịch sử 01..12 hoặc oracle.
Stage28 (DISCOVERY 14) chưa bắt đầu.

**Kết quả CI thực tế Stage27:** Elixir 1.18.5 / OTP 27:
354 kiểm thử, 0 lỗi, 0 cảnh báo; Canonical Names Lock PASS.
Bốn hồi quy Stage26 trở lại xanh với expected giữ nguyên.
18 bài Stage27 mới PASS. ShortRejectionPatch đi trong
cùng answer ring, tăng k khi x>limit và gọi lại chính
LegacyBiasedPick một lần chỉ sau khi chấp nhận.
Trace độc lập cho từng lần gọi, không có nguồn random khác.

LegacyBiasedPick blob SHA
`94816d3aac30296eeded3abdd0bfaea5f46614ae`;
oracle test-only blob SHA
`be1638f46b2190d617af0378a61b077bda10bf32`.
Không đổi main, không có wideDetour, chưa mở Stage28.
Đóng Stage27 GREEN.

## Giai đoạn 28 — Phát hiện 14: bộ chọn một chữ số cho miền rộng

**Phần đúng:** Vòng đáp án sau 46 giọt và 12 lượt
khuấy không đổi, hạt/hướng theo SAVE chuẩn; n<=M
tiếp tục dùng ShortRejectionPatch với rejection đúng.
Không sửa bát, ID kế, memory latch, đá hoặc nguồn rót.

**Di sản lỗi mới:** Với n>M, `LegacySingleDigitWidePick`
đọc chỉ `answer_at(0)` và gọi legacy modulo.
Vì n lớn hơn mọi số có thể nằm trong answer ring,
kết quả luôn bằng x đầu (1..M), làm mất các hạng
cao M+1..n. `AnswerStreamManager.choose_rank` và
`Dispatcher.choose_rank` dùng hàm lịch sử này
trong đường production thật, không chỉ ở kiểm thử.

**Bằng chứng:** Khi first=1 và step=+1, câu trả
lời đầu là 1, kế là 2. Số rộng một-based cho hai
chữ số phải bắt đầu ở M+1, không phải 1.
Hạng n=M+1 hoặc M² đều cần hai chữ số; M²+1 cần
ba; M³+1 cần bốn. Bốn hồi quy oracle chuẩn được
giữ đỏ cố ý. 16 điều khiển khác giữ các bản vá trước.

**Giai đoạn 29:** Giữ LegacySingleDigitWidePick
không sửa để tái hiện lỗi, đưa wideDetour vào
đường production: lấy k chữ số theo cùng answer
ring (cơ số M, chữ số đầu ít trọng số nhất),
dùng bước +/-1 trên không gian rộng M^k khi
giá trị lớn hơn giới hạn chia đều. Chưa làm
bước vá ở DISCOVERY 14.

**Kết quả CI thật của Stage28:** Elixir 1.18.5 /
OTP 27: 374 kiểm thử, đúng bốn hồi quy chuẩn đỏ,
370 bài đạt, không cảnh báo và Canonical Names Lock
PASS. Toàn bộ 354 bài Stage1..27 đạt. 16 điều khiển
Stage28 PASS, khẳng định hàm legacy wide chỉ đọc
answer_at(0) nên không thể trả hạng M+1..n.
Cả bốn so sánh ở n=M+1, M², M²+1, M³+1 đỏ đúng.
Không thêm wideDetour; Stage28 đóng EXPECTED_RED.


## Giai đoạn 29/55 — PATCH 14, chọn hạng rộng chuẩn (đã đóng)

WideDetourPatch tạo đúng k chữ số từ cùng AnswerStreamManager,
k tối thiểu sao cho M^k>=N; ghép little-endian và giới hạn
limit=floor(M^k/N)*N. Nếu wide0>limit, bước +/-1 trên vòng
wide được tính bằng công thức tương đương chính xác,
không đổi hạt, chiều hay thứ tự các chữ số.
Lớp ShortRejectionPatch cho N<=M và module
LegacySingleDigitWidePick sai lịch sử được giữ nguyên.
Không nhập oracle test-only vào production.

Bốn hồi quy chuẩn Stage28 nay đạt, thêm 19 kiểm thử Stage29:
**393/393 PASS, 0 thất bại, không cảnh báo biên dịch Elixir**
trên Elixir 1.18.5, Erlang/OTP 27.
Canonical Names Lock PASS độc lập. Cảnh báo Node.js 20
từ checkout@v4 là cảnh báo nền tảng workflow, không phải biên dịch.

- [CI Stage29 đóng GREEN](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38286909827)
- [Canonical Names Lock PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38286909853)

Stage29 hoàn tất, NEXT=Stage30/55 DISCOVERY 15.
Không sửa nhánh main, không tích hợp lịch đầy đủ tại Stage29.

## Giai đoạn 30/55 — DISCOVERY 15: lỗi phản chiếu cổng âm

Đã thêm GateGapManager và GateTimelineManager cho chỉ số cổng nguyên âm/dương
từ neo 0 tại FOUNDATION=-15_055_671. Cổng dương dùng câu hỏi
sauce(FOUNDATION,FOUNDATION+n), bát 1, chốt 1, chọn hạng 922 và cộng 41.
Cổng âm lịch sử dùng nhầm cùng ngày hỏi FOUNDATION+n thay vì FOUNDATION-n,
nên dãy âm bị phản chiếu, mặc dù vẫn giảm nghiêm ngặt.

LegacyMirroredNegativeGateGap được gọi thật qua đường production.
Không có NegativeGateGapPatch ở giai đoạn 30. Toàn bộ 14 bản vá
đã hoàn thành còn nguyên, không khởi động bộ tìm năm hay ngày lịch cuối.

CI Elixir 1.18.5 / OTP 27 xác minh **413 kiểm thử,
đúng bốn hồi quy normative cố ý đỏ**, 409 đạt, không cảnh báo
biên dịch; **Canonical Names Lock PASS**. Bốn sai lệch nằm duy nhất
ở chỉ số cổng -1..-4. 393 bài cũ và 16 điều khiển mới đều đạt.
- [CI Stage30 EXPECTED_RED](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38289526828)
- [Canonical Names Lock PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38289526872)

Stage30 đóng EXPECTED_RED. Bước kế tiếp là Stage31 PATCH 15:
giữ LegacyMirroredNegativeGateGap nguyên vẹn, thêm lớp sửa riêng,
và chuyển bốn hồi quy trở lại xanh mà không thay expected.

## Giai đoạn 31/55 — PATCH 15: cổng âm trở lại chuẩn

`NegativeGateGapPatch` gọi thật `LegacyMirroredNegativeGateGap`
nhưng dùng `FOUNDATION-n` cho phép tính chuẩn. Bản vá lưu lại
cả độ dài legacy, độ dài chuẩn, hai ngày hỏi và phần chênh lệch.
`GateGapManager.negative_gap` dùng patch; `GateTimelineManager`
không cần thay thuật toán và state vẫn bất biến.
Bốn hồi quy chuẩn cổng -1..-4 từ Stage30 giữ nguyên expected
và đều trở lại xanh; thêm 18 bài Stage31, bao gồm cổng -8..8,
số nguyên 2048-bit, đồng thời và bất biến legacy.

Giai đoạn 31 PATCH 15 được xác minh bằng CI trên Elixir 1.18.5, OTP 27
tại commit `274c153e7d24fb578c5835648ba14af46a3a080e`.
Biên dịch 50 tệp .ex, **431/431 kiểm thử PASS**, 0 lỗi và
không cảnh báo biên dịch Elixir; Canonical Names Lock PASS.
Giữ nguyên blob SHA của LegacyMirroredNegativeGateGap
`f83ed6a47550dd9c4306146d09ab48d50ab81caf`,
oracle test-only `be1638f46b2190d617af0378a61b077bda10bf32`.
Cảnh báo Node.js 20 thuộc checkout@v4 của CI, không phải nguồn Elixir.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38367321898
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38367321846
Stage31 đóng GREEN. Stage32/55 DISCOVERY 16 chưa bắt đầu.
Không đổi main; không nhập oracle vào production.

## Giai đoạn 32/55 — DISCOVERY 16: sắp năm 5000 từ dài tới ngắn

Year5000CandidateManager dùng dãy cổng hai chiều đã qua
PATCH 15; phủ cửa sổ +/-5778 ngày rồi chọn mọi cặp cổng
i<j có ít nhất 6 khoảng, độ dài 252..5778 ngày,
gate(i)<c<=gate(j). Rank được chọn đúng bằng bát 1,
chốt 10 từ sauce(c,c).

LegacyLongestFirstYear5000.sort sắp độ dài giảm dần,
ngược với chuẩn tăng dần. Đường production
Year5000Manager thực sự chọn phần tử thứ rank trong
danh sách legacy. Bốn hồi quy chuẩn mới cố ý đỏ;
không có lỗi ở tập ứng viên, cổng hoặc rank.

Giai đoạn 32 DISCOVERY 16 đã xác minh Elixir 1.18.5 / OTP 27
trên GitHub Actions: biên dịch 54 tệp .ex,
**451 kiểm thử, 447 PASS, đúng bốn hồi quy normative sai cố ý**,
không cảnh báo biên dịch Elixir. Canonical Names Lock PASS.
Bốn fixture c=FOUNDATION, FOUNDATION+1, FOUNDATION+417,
FOUNDATION-539 đều trả cặp chỉ số cổng sai do xếp độ dài giảm dần.
393+38 bài từ các giai đoạn trước (431 bài Stage1..31)
và 16 kiểm soát Stage32 đều xanh.
Không thay oracle test-only, Year5000CandidateManager hoặc các patch 01..15
để che sai lệch. Không tích hợp tìm năm mục tiêu hoặc lịch cuối.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38565791324
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38565791544
Cảnh báo Node.js 20 từ checkout@v4 là cảnh báo nền tảng, không phải Elixir.
Đóng Stage32 EXPECTED_RED. Stage33 PATCH 16 chưa bắt đầu.

Stage33 phải giữ legacy và sửa riêng phép sắp thứ tự năm;
bốn expected normative không thay.

## Giai đoạn 33/55 — PATCH 16: năm 5000 ngắn trước

ShortestFirstYear5000Patch gọi thật hàm
LegacyLongestFirstYear5000.sort và giữ thứ tự lỗi để kiểm toán.
Lớp này sắp lại theo (độ dài tăng dần, ngày mở tăng dần).
Year5000Manager tiếp tục tạo đúng tập ứng viên và rank rồi
chọn từ corrected_order. Không đổi oracle hoặc 15 patch cũ.

Giai đoạn 33 PATCH 16 đã qua kiểm chứng thật bằng
Elixir 1.18.5 / Erlang OTP 27: biên dịch 55 tệp,
**471/471 kiểm thử PASS, 0 thất bại, không cảnh báo biên dịch Elixir**.
Canonical Names Lock độc lập PASS.
Bốn hồi quy normative của DISCOVERY 16 trở lại xanh với expected giữ nguyên.
20 bài Stage33 và 451 bài trước đều PASS.
Giữ nguyên LegacyLongestFirstYear5000 blob
`b4a0908392090f61d06bc1781e5bef636b91b27a`,
oracle test-only blob
`be1638f46b2190d617af0378a61b077bda10bf32`.
Cảnh báo duy nhất thuộc nền tảng checkout@v4 (Node.js 20).
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38586793285
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38586793164
Đóng Stage33 GREEN, tiếp theo Stage34 DISCOVERY 17 chưa bắt đầu.
Không thay main hoặc tích hợp lịch hoàn chỉnh.

## Giai đoạn 34/55 — DISCOVERY 17: nguồn ngày hỏi của năm tiếp theo

NextYearCandidateManager tạo năm sau năm neo 5000 bằng cổng mở
đúng, lọc ít nhất 6 khoảng, độ dài 252..5778 ngày; thứ tự
ứng viên chuẩn và rank vẫn chọn trong answer stream bát 1, chốt 11.
Lỗi có chủ đích nằm riêng ở LegacyCurrentDayNextYearSeed:
nó hỏi sauce(c,c) thay vì sauce(c,open_day).
Đã bổ sung 20 kiểm thử; bốn hồi quy normative giữ kỳ vọng đúng.

Giai đoạn 34 DISCOVERY 17 được xác minh trên Elixir 1.18.5 / OTP 27:
491 kiểm thử, 487 PASS và đúng bốn hồi quy normative cố ý đỏ
tại c=FOUNDATION-539, FOUNDATION+1, FOUNDATION+417, FOUNDATION+2.
Không có lỗi điều khiển, không cảnh báo biên dịch Elixir;
Canonical Names Lock PASS. Các fixture đỏ đã được xác nhận
bởi CI trên commit `7c92a0bdb8218bf08047fecf3d9c624547e9f8e7`.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38890087448
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38890087434
Lỗi là hạt ngày hỏi c,c ở LegacyCurrentDayNextYearSeed,
thay vì c,open_day; candidate set, gate và năm 5000 không đổi.
Cảnh báo checkout@v4 về Node.js 20 không phải warning Elixir.
Stage34 đóng EXPECTED_RED; Stage35 PATCH 17 chưa bắt đầu.
Không đổi main, không đổi oracle test-only hoặc các patch cũ.

Bước sau: Stage35 PATCH 17 giữ nguyên legacy và tính lại rank
từ nguồn ngày hỏi open_day, sau đó đưa bốn hồi quy trở lại xanh.

## Giai đoạn 35/55 — PATCH 17: sửa nguồn hạt năm tiếp theo

NextYearSeedPatch gọi thật LegacyCurrentDayNextYearSeed(c,count)
để ghi lại rank sai lịch sử, sau đó chọn rank chuẩn bằng
answer_stream(c,open_day,1,11), trong đó open_day là
cổng đóng của năm đã biết. Candidate, gate và Year5000
giữ nguyên; NextYearManager trả năm 5001 theo rank chuẩn.

Thêm 20 kiểm thử; bốn normative Stage34 vẫn giữ nguyên expected.
Giai đoạn 35 PATCH 17 đã được xác minh trên Elixir 1.18.5 / Erlang OTP 27:
biên dịch 59 tệp .ex, **511/511 kiểm thử PASS**, 0 lỗi và
không cảnh báo biên dịch Elixir. Canonical Names Lock PASS độc lập.
Bốn hồi quy normative của Stage34 đều chuyển xanh, không sửa expected.
LegacyCurrentDayNextYearSeed giữ blob SHA
`4fc34f60bf4703a348e4b2d49809e9100717d119`;
oracle test-only giữ blob SHA
`be1638f46b2190d617af0378a61b077bda10bf32`.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38890792213
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38890792155
Stage35 đóng GREEN. Stage36 DISCOVERY 18 chưa bắt đầu.
Không sửa main, không nhập oracle vào production, chưa hoàn thiện lịch cuối.

## Giai đoạn 37/55 — PATCH 18: chốt 12 cho năm trước

PreviousYearSealPatch gọi LegacyNextYearSealForPreviousSeed
để lưu hạng lịch sử từ chốt 11; sau đó chọn đúng hạng
từ Dispatcher.answer_stream(c,close_day,1,12).
PreviousYearManager dùng corrected_rank; ứng viên, cổng,
năm 5000, năm 5001 và oracle không thay đổi.
20 kiểm thử Stage37 mới, bốn hồi quy Stage36 được giữ nguyên.

Giai đoạn 37 PATCH 18 được xác minh trên GitHub Actions
với Elixir 1.18.5 / OTP 27, biên dịch 63 tệp .ex,
**551/551 kiểm thử PASS, 0 lỗi, không compiler warnings**.
Canonical Names Lock độc lập PASS.
Bốn hồi quy normative Stage36 không đổi expected và đều xanh.
LegacyNextYearSealForPreviousSeed giữ blob SHA
`b1ab864a1a92a8899615e3e7649bdbdebd5e4ca7`;
oracle test-only giữ blob SHA
`be1638f46b2190d617af0378a61b077bda10bf32`.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39219614083
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39219614067
Đóng Stage37 GREEN; Stage38/55 DISCOVERY19 chưa bắt đầu.
Không sửa main hoặc tích hợp toàn bộ lịch.

## Giai đoạn 38/55 — DISCOVERY 19: cổng đóng năm đích

TargetYearManager đi từ năm 5000 về trước/sau bằng các
bản vá đã hoàn tất. LegacyUpperBoundaryBelongsToNextYear
cố ý đặt ngày bằng cổng đóng vào năm sau, ngược với
khoảng (open, close] của chuẩn. Lỗi chỉ ở tuyến biên;
không sửa thuật toán chọn năm, ứng viên, oracle hoặc cổng.

Stage38 DISCOVERY19 đã xác minh trên Elixir 1.18.5 / OTP 27:
biên dịch 65 tệp .ex, **573 bài, 569 PASS, đúng 4 hồi quy
normative đỏ**, không có warning trình biên dịch Elixir.
Canonical Names Lock độc lập PASS. Bốn sai lệch đều ở ngày
đúng cổng đóng năm 5000 tại c=FOUNDATION, +1, +417, -539.
18 kiểm soát Stage38 và toàn bộ 551 bài cũ đạt.
LegacyUpperBoundaryBelongsToNextYear trả :next_at_upper_boundary
khi target==close; không có TargetYearBoundaryPatch.
Lần CI ban đầu có hai lỗi điều khiển biên kép và một cảnh báo
alias, đã sửa riêng trong commit f5f20fcbe0e6731f2ddaf70637dc64ce672d5ba7,
không thay bốn expected normative.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39220862669
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39220862708
Stage38 đóng EXPECTED_RED; Stage39 PATCH19 chưa bắt đầu.
Không đổi main, oracle hoặc những bản vá cũ.

## Giai đoạn 39/55 — PATCH 19: khôi phục cổng đóng năm đích

TargetYearBoundaryPatch gọi LegacyUpperBoundaryBelongsToNextYear
trước khi chuyển :next_at_upper_boundary sang :found; mọi tuyến
khác giữ nguyên. Bước tìm năm quá khứ/tương lai đúng theo
khoảng (open,close]. Bốn hồi quy Stage38 trở lại xanh.

Stage39 PATCH19 đã qua kiểm chứng trên Elixir 1.18.5 / OTP 27:
biên dịch 66 tệp .ex, **593/593 bài PASS, 0 lỗi**, không
warning biên dịch Elixir. Canonical Names Lock độc lập PASS.
Bốn hồi quy normative Stage38 giữ nguyên expected và đều xanh;
20 bài Stage39 mới, 573 bài cũ đều xanh.
Giữ legacy blob SHA `0ccb0a91f828d97b319ddcdd9f06561815ee2ff6`;
oracle test-only SHA `be1638f46b2190d617af0378a61b077bda10bf32`.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39222112909
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39222112844
Stage39 đóng GREEN. Stage40 DISCOVERY20 chưa bắt đầu;
chưa tích hợp lịch cuối, không thay main.


## Giai đoạn 40/55 — DISCOVERY20: đảo thứ tự số cốt-lết

CutletCountManager chọn năm đích đã vá và số cốt-lết từ
6..min(17,gate_gaps); hạt đúng sauce(c,year.open_day+1),
bát 2/chốt 20, rank một-based. LegacyDescendingCutletCount
cố tình đảo thứ tự ứng viên nhưng không mất giá trị nào.
20 bài mới: 16 kiểm soát và 4 nhóm hồi quy normative RED.

Elixir 1.18.5 / OTP27: 613 bài, 609 PASS và đúng bốn RED;
Canonical Names Lock PASS, không compiler warnings.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39297740064
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39297739893
Stage40 đóng EXPECTED_RED; Stage41 PATCH20 chưa bắt đầu.


## Giai đoạn 41/55 — PATCH20: sửa thứ tự số cốt-lết

AscendingCutletCountPatch gọi thật LegacyDescendingCutletCount
để lưu thứ tự cũ, sau đó sắp tăng dần và trả corrected_order.
CutletCountManager giữ nguồn sauce(c,open_day+1), bát 2/chốt 20,
rank, tập ứng viên và bảng cổng. Bốn nhóm hồi quy Stage40
trở lại xanh mà không thay expected. Thêm 20 bài Stage41.

CI Elixir 1.18.5 / OTP27: **633/633 PASS, 0 lỗi**, không warning.
Canonical Names Lock PASS, legacy và oracle test-only không đổi.
CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39298935288
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39298935385
Stage41 đóng GREEN. Stage42/55 DISCOVERY21 chưa bắt đầu.


## Giai đoạn 42/55 — DISCOVERY21: nhầm chốt phân hoạch cốt-lết

CutletPartitionCombinatorics đếm và mở hạng từ điển của
các phân hoạch dương với cổng tính bắt buộc ở nội bộ.
LegacyCutletPartitionCountSeal lấy rank bằng bowl 2, chốt 20
thay vì chốt 21 chuẩn. Đường production thực sự dùng rank
legacy, trong khi năm đích, số cốt-lết và phân hoạch đều đúng.

CI Elixir 1.18.5 / OTP27: **653 bài, 649 PASS, đúng bốn RED**
ở normative, 16 điều khiển và 633 bài cũ PASS;
không cảnh báo biên dịch. Canonical Names Lock PASS.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39411372185
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39411372181

Stage42 đóng EXPECTED_RED; Stage43 PATCH21 chưa bắt đầu.


## Giai đoạn 44/55 — DISCOVERY22: lệch rank tên cốt-lết

CutletNameIndexManager chọn dãy tên phân biệt từ 1..17,
đếm chỉnh hợp P(17,k), mở hạng từ điển mà không tạo toàn bộ
ứng viên. Nguồn sauce (c,year.open_day+1), bowl5/seal22 và
tất cả các tầng chọn năm, phân hoạch đã qua PATCH21.
LegacyRotatedCutletNameRank cố ý xoay rank đúng lên một,
vòng rank cuối về đầu; production thật dùng rank legacy.

GitHub Actions Elixir 1.18.5 / OTP27: **693 bài, 689 PASS,
đúng bốn hồi quy normative RED**, không cảnh báo biên dịch.
Canonical Names Lock PASS. Stage44 đóng EXPECTED_RED;
Stage45 PATCH22 chưa bắt đầu. Không sửa main hoặc oracle.
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39495814532
- Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39495814488
