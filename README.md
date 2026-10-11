# Cách triển khai lịch Pastafari bằng Elixir

Đây là một kho mới được dựng từ số không cho đúng một dòng triển khai: Elixir là ngôn ngữ lập trình duy nhất và tiếng Việt là ngôn ngữ nguồn duy nhất cho mọi văn bản do dòng triển khai tạo ra. Kho này không dựa vào mã, kiểm thử, dữ liệu kiểm thử, kết quả, bảng sinh ra hay giá trị băm của bất kỳ cách triển khai nào khác.

Giai đoạn 1 đã dựng nền móng: mã sản xuất có ngữ cảnh riêng cho từng lần gọi, bộ phân phối cơ sở, kiểm tra đầu vào, biên lỗi và trạng thái quan sát phi ngữ nghĩa.

Bộ tham chiếu chuẩn sạch nằm dưới `test/support/` và chỉ phục vụ kiểm thử. Mã sản xuất không nhập, không gọi và không dùng nó làm đường dự phòng.

Elixir dùng số nguyên có độ chính xác tùy ý, vì vậy phép tính chuẩn không cần thư viện số lớn hay cầu nối sang ngôn ngữ khác.

`SourceLanguageCatalog` phiên bản `1.0.0` đã được đóng băng ở giai đoạn 1. Mọi thứ tự chuẩn dùng `canonicalIndex`; chuỗi tiếng Việt chỉ được giải ra ở lớp kết quả hoặc trình bày.

## Xác minh giai đoạn 1

Giai đoạn 1 đã hoàn tất. GitHub Actions đã chạy `mix test` bằng Elixir 1.18.5 trên Erlang/OTP 27 và hoàn tất với 16 kiểm thử, 0 lỗi.

## Giai đoạn 2 — Phát hiện 01

Giai đoạn 2 chủ ý làm lộ sai lệch đầu tiên: `old_remainder(value)` trả phần dư thông thường trong miền 0..M−1 thay cho SAVE trong miền 1..M, với M = 2^127−1. Sai lệch xuất hiện khi `value` chia hết cho M.

Có thể đi qua đường sản xuất chưa vá bằng `PastafariCalendarElixirVietnamese.save_value_spaghetti(value)`. Hàm trả kết quả sai tại M, 2M và 3M; điều này được kiểm chứng bằng các hồi quy chuẩn cố ý thất bại. Tại M+1 hàm trả 1 như chuẩn.

Đó là trạng thái `EXPECTED_RED` lịch sử của giai đoạn khám phá; các hồi quy chỉ được chuyển thành đạt ở giai đoạn 3 nhờ lớp vá thực tế, không phải bằng cách đổi kỳ vọng. Hàm tính ngày lịch đầy đủ vẫn chưa được tích hợp.

Chạy tại gốc kho:

```text
mix test
```

Bước lịch sử tiếp theo sau giai đoạn 2 là giai đoạn 3/55, `PATCH 01`. Bước này hiện đã hoàn tất với lớp vá chuyển phần dư 0 thành M, còn `old_remainder` được giữ nguyên làm dấu vết lịch sử.

## Bằng chứng khép giai đoạn 2

GitHub Actions chạy Elixir 1.18.5 với OTP 27 và xác nhận 22 kiểm thử,
3 thất bại đúng tại M, 2M, 3M; 19 kiểm thử còn lại thành công.
Không có lỗi biên dịch hay sai lệch kiểm thử ngoài dự kiến.

- [Nhật ký kiểm thử dự kiến đỏ](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38150668369)
- [Kiểm tra khóa tên chuẩn đã đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38150668429)

## Giai đoạn 3 — Bản vá 01

Vẫn giữ nguyên hàm lịch sử `LegacyRemainder.old_remainder` trả 0
đối với các bội số của M. Lớp `SavePatch` gọi chính hàm đó, rồi
chỉ thay kết quả 0 bằng M. `SaveManager` tiếp tục qua lớp vá này.
Ba hồi quy chuẩn của giai đoạn 2 không bị sửa hoặc xóa và phải chuyển sang đạt.

Các kiểm thử mở rộng gồm phần dư âm, số 0, số nguyên lớn hơn 1024 bit,
tính chu kỳ, nhiều yêu cầu đồng thời và kiểm tra đường gọi lịch sử.
Hàm ngày lịch đầy đủ vẫn bị chặn cho đến giai đoạn tích hợp bắt buộc.

## Xác minh hoàn tất giai đoạn 3

Quy trình GitHub Actions dùng Elixir 1.18.5 và Erlang/OTP 27 đã chạy
`mix test` với 29 kiểm thử, 0 lỗi. Cả ba hồi quy chuẩn của giai đoạn 2
đã chuyển thành đạt mà không đổi các kỳ vọng. Quy trình khóa tên chuẩn
hoàn tất thành công; mô-đun `LegacyRemainder` vẫn nguyên trạng.

- [Kiểm thử Elixir — đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151138352)
- [Khóa tên chuẩn — đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151138317)

Giai đoạn 3/55 đã được đóng với trạng thái `GREEN`.
Bước lịch sử tiếp theo là giai đoạn 4/55: `DISCOVERY 02`, không được
đưa bản vá thứ hai vào cùng bước khám phá.

## Giai đoạn 4 — Phát hiện 02: sai số nhãn ngày

Bộ đánh số ngày mới được nối vào đường sản xuất thông qua
`day_count_spaghetti(day)` và hai nhãn riêng trong `bootstrap_context`.
Công thức lịch sử `2 * abs(day - FOUNDATION)` bị sai tại ngày nền
và tất cả các ngày sau đó; trước ngày nền nó trùng quy tắc chuẩn.

Ba kiểm thử hồi quy chuẩn của giai đoạn 4 cố ý yêu cầu nhãn đúng ở
`FOUNDATION`, `FOUNDATION+1`, `FOUNDATION+2`; do đó trạng thái
mong đợi ở pha khám phá là `EXPECTED_RED`. Lớp vá thứ hai chỉ được
đưa vào ở giai đoạn 5. Lớp vá SAVE thứ nhất và các kiểm thử cũ
vẫn phải hoạt động không thay đổi.

## Xác minh hoàn tất giai đoạn 4

GitHub Actions với Elixir 1.18.5 và Erlang/OTP 27 xác nhận 36 kiểm thử,
3 thất bại có chủ đích chỉ tại ngày nền và hai ngày tiếp theo, 33 đạt.
Khóa tên chuẩn độc lập đạt. Không có lỗi biên dịch.
Đây là trạng thái `EXPECTED_RED` đã được xác minh, không phải hỏng hóc mới.

- [Nhật ký kiểm thử phát hiện 02](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38152863320)
- [Kiểm tra khóa tên chuẩn](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38152863404)

Bước kế tiếp là giai đoạn 5/55, `PATCH 02`: giữ `old_day_tag`
và thêm lớp sửa theo đúng quy tắc đã xác định, không xóa vết lịch sử.

## Giai đoạn 5 — Bản vá 02 của nhãn ngày

Hàm `LegacyDayTag.old_day_tag` của giai đoạn 4 tiếp tục giữ nguyên
công thức sai. Lớp `DayTagPatch` gọi nó rồi cộng một nếu ngày không
trước Ngày Nền. Một điều kiện kiểm tra thừa tại chính Ngày Nền cũng
được giữ nguyên như dấu vết phát triển, không được xóa hoặc tối ưu hóa.

`DayCountManager`, `day_count_spaghetti` và hai nhãn trong
`bootstrap_context` đều sử dụng lớp vá này.
Ba hồi quy của giai đoạn 4 giữ nguyên kỳ vọng chuẩn và phải chuyển
thành đạt. Các kiểm thử mới bao gồm biên, số nguyên cực lớn, hai
phía ngày nền, đồng thời, tính độc lập của context và bất biến của
SAVE. Ngày lịch đầy đủ chưa được tích hợp.

## Xác minh hoàn tất giai đoạn 5

GitHub Actions đã chạy 45 kiểm thử trên Elixir 1.18.5 và Erlang/OTP 27
với không lỗi và không có cảnh báo biên dịch. Ba hồi quy chuẩn của
giai đoạn 4 nay đạt mà không đổi kỳ vọng. Khóa tên chuẩn cũng đạt.

- [Kết quả kiểm thử xanh của giai đoạn 5](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154035832)
- [Kết quả khóa tên chuẩn](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154035856)

Lần chạy đầu của giai đoạn 5 không đến phần thực thi kiểm thử vì thiếu
`end` ở cuối mô-đun kiểm thử mới; lỗi cú pháp đó được sửa trước khi
kiểm chứng xanh. Không thay đổi mã sản xuất trong bản sửa cú pháp.

Giai đoạn 5/55 được đóng với trạng thái `GREEN`.
Bước tiếp theo là giai đoạn 6/55, `DISCOVERY 03` với lỗi lịch sử
về khoảng cách giữa nhãn ngày; chưa thêm bản vá 03.

## Giai đoạn 6 — Phát hiện 03: khoảng cách giữa nhãn ngày

Bổ sung `LegacyDistance.old_distance(calculation_day, target_day)`,
lấy giá trị tuyệt đối giữa hai nhãn ngày đã đi qua bản vá 02. Đây là
một giả định lịch sử sai: khoảng cách chuẩn phải dựa trên hai ngày
theo thứ tự thời gian và cộng thêm 1. Giai đoạn phát hiện **không**
được tính khoảng cách chuẩn trong mã sản xuất.

Đường sản xuất `distance_spaghetti` và `bootstrap_context` đi qua
`DistanceManager → LegacyDistance → DayCountManager → DayTagPatch`.
Context có trường riêng `distance_count` để lưu giá trị thô sai.
Không chỉnh các kiểm thử nòng cốt từ giai đoạn 1–5.

Bốn hồi quy chuẩn cố ý đỏ: cùng một ngày, hai ngày cùng phía trước
Ngày Nền, hai ngày cùng phía sau Ngày Nền và một cặp vượt Ngày Nền.
Hai đối chứng đi qua đúng khi sai số tình cờ triệt tiêu.
Bản vá 03 bắt buộc thuộc giai đoạn 7 và chưa được thêm ở đây.

## Xác minh hoàn tất giai đoạn 6

CI dùng Elixir 1.18.5, OTP 27 đã thực thi 55 kiểm thử:
51 đạt, đúng 4 thất bại có chủ đích thuộc phát hiện 03.
Không có lỗi biên dịch và không có thất bại của các kiểm thử trước.
Khóa tên chuẩn độc lập đạt.

- [Nhật ký phát hiện 03 có bốn hồi quy đỏ](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154864908)
- [Khóa tên chuẩn đã đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38154864891)

Giai đoạn 6/55 khép ở trạng thái `EXPECTED_RED` đã xác minh.
Giai đoạn 7/55 là `PATCH 03`: giữ `old_distance`, chỉ khi
khác khoảng cách theo ngày thời gian mới thay giá trị; sau đó
cộng một. Không sửa các hồi quy chuẩn của giai đoạn phát hiện.

## Giai đoạn 7 — Bản vá 03: điều chỉnh khoảng cách

`LegacyDistance.old_distance(c,t)` từ phát hiện 03 vẫn tồn tại và
tiếp tục chạy. Lớp `DistancePatch` lấy giá trị cũ, tính
`chronological = abs(t-c)`; chỉ nếu hai số khác nhau mới chọn
`chronological` làm khoảng cách cơ sở. Cuối cùng cộng một.
`DistanceManager`, `distance_spaghetti` và
`bootstrap_context` đều đi qua lớp vá này.

Bốn hồi quy chuẩn của giai đoạn 6 không thay đổi. Các kiểm thử
chỉ kiểm tra dây nối sai từ giai đoạn khám phá được điều chỉnh:
chúng xác nhận thuật toán cũ vẫn sai nhưng đầu ra công khai đã đúng.
Mười kiểm thử giai đoạn 7 kiểm soát hai nhánh điều kiện, số nguyên rất
lớn, lưới quanh Ngày Nền, tính đối xứng, sự cô lập khi chạy đồng thời
và không hồi quy các bản vá 01/02.

## Xác minh đóng giai đoạn 7

Trên GitHub Actions, Elixir 1.18.5 cùng Erlang/OTP 27 đã chạy 65
kiểm thử và không có lỗi hay cảnh báo biên dịch. Cả bốn hồi quy
của giai đoạn 6 đã đạt mà không đổi kỳ vọng chuẩn. Phép tính sai
LegacyDistance và hai bản vá cũ không bị sửa. Khóa tên chuẩn đạt.

- [Kiểm thử 65/65 đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155925314)
- [Khóa tên chuẩn đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155925331)

Lần chạy đầu lộ một ca thử mới bị phân loại sai: hai ngày giống
nhau là nhánh giữ vì cả hai khoảng cách cơ sở đều bằng 0.
Ca thử đã được chuyển sang nhánh giữ, một đối chứng khác được dùng
cho nhánh sửa. Không sửa mã sản xuất hoặc hồi quy chuẩn.

Giai đoạn 7/55 đã đóng ở trạng thái `GREEN`. Giai đoạn 8/55 sẽ
là `DISCOVERY 04`; chưa khởi động và chưa thêm bản vá 04.

## Giai đoạn 8 — Phát hiện 04: cập nhật đá nối tiếp

Mỗi hàng đá có năm giá trị: lúa mì, lúa mạch, muối, thịt và cơm.
Hàng đầu cố định: `{17, 29, 43, 71, 101}`.
`StoneManager.build_table` dựng 46 hàng, mỗi hàng sau dùng hàm
`LegacyStoneMutation.mutate_stones_wrong` thực thi thực tế.

Lỗi lịch sử: khi tính giá trị thứ hai đến thứ năm, các công thức
đọc lại giá trị của các ô trước đã cập nhật trong cùng một hàng.
Điều đó tương đương cập nhật `in-place` dù Elixir dùng tuple bất biến.
Phép chuẩn lại yêu cầu mọi công thức dùng riêng năm giá trị của
hàng trước, không bị pha trộn với hàng đang xây dựng.

Hai đường sản xuất: `stones_table_spaghetti / stone_row_spaghetti`
và trường `stones_table` của `bootstrap_context`.
Tất cả tiếp tục gọi SAVE đã vá đúng và không dựa vào oracle kiểm thử.

Bốn hồi quy chuẩn cố ý đỏ tại hàng 2, hàng 3 và hàng cuối 46.
Hàng đầu và giá trị đầu tiên của hàng 2 là đối chứng vẫn khớp.
Bản vá 04 dùng snapshot hàng cũ chỉ được thêm vào giai đoạn 9.

## Xác minh hoàn tất giai đoạn 8

GitHub Actions đã chạy Elixir 1.18.5 trên Erlang/OTP 27 với 77 kiểm thử.
Đúng bốn kiểm thử chuẩn phát hiện 04 thất bại: hai vị trí của hàng 2,
giá trị lúa mì hàng 3 và cả hàng 46. 73 kiểm thử còn lại đạt.
Cả 65 kiểm thử cũ đều đạt. Không có lỗi biên dịch hoặc cảnh báo
trong lần xác minh cuối, và khóa tên chuẩn đạt độc lập.

- [Kiểm thử phát hiện 04: 77 kiểm thử, 4 sai lệch dự kiến](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38157396943)
- [Khóa tên chuẩn đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38157396924)

Lần chạy đầu có cảnh báo import `Bitwise` không dùng trong kiểm thử mới.
Một commit riêng đã xóa import thừa, không sửa bất kỳ công thức
lịch sử hay kỳ vọng chuẩn nào.

Giai đoạn 8/55 được đóng với trạng thái `EXPECTED_RED`.
Giai đoạn 9/55 là `PATCH 04`: giữ phép cập nhật nối tiếp sai,
thực sự gọi legacy trên bản sao, nhận garbage rồi ghi đè đủ năm
kết quả từ snapshot của hàng cũ.

## Giai đoạn 9 — Bản vá 04 cho bảng đá

`StonePatch.patch_row/2` lưu ảnh chụp của hàng cũ, tạo bản sao
`legacy_clone`, thực thi thật `LegacyStoneMutation.mutate_stones_wrong/2`
trên bản sao và nhận năm kết quả trung gian sai. Sau đó bản vá ghi đè
cả năm giá trị từ công thức chỉ đọc ảnh chụp hàng cũ.
`StoneManager.build_table`, `stone_row_spaghetti` và
`bootstrap_context` đều đi qua bản vá này.

Bốn hồi quy chuẩn của giai đoạn 8 không được sửa và hiện đã đạt.
Những kiểm thử cấu trúc từng đòi kết quả công khai sai được điều chỉnh
để chứng minh hàm legacy vẫn sai, còn bảng sản xuất đã chính xác.
11 kiểm thử bổ sung kiểm toán 46 hàng, số nguyên rất lớn,
các công thức độc lập, quyền sở hữu và thực thi đồng thời.

## Kiểm chứng đóng giai đoạn 9

GitHub Actions với Elixir 1.18.5 và OTP 27: **88 kiểm thử, 0 lỗi**,
không cảnh báo biên dịch. Khóa tên chuẩn độc lập đạt.
Mã `LegacyStoneMutation` của giai đoạn 8 giữ nguyên blob SHA.

- [Kiểm thử Elixir 88/88 đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38159415842)
- [Khóa tên chuẩn đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38159415828)

Trạng thái giai đoạn 9/55: `GREEN` đã xác minh.
Giai đoạn 10/55 kế tiếp: `DISCOVERY 05`, cách lưu bảy giọt
ẩn theo thứ tự đảo ngược. Không đưa bản vá 05 vào giai đoạn 9.

## Giai đoạn 10 — Phát hiện 05: lưu ngược bảy giọt ẩn

Bảy giọt ẩn được tính từ năm bộ đếm công việc, bảng đá đã vá,
bảy hàng hệ số và bảy phép nghiền. `HiddenDropCalculator` dùng
đúng số học và lớp SAVE đã hoàn thành. Các giá trị được tính
bằng mã sản xuất riêng, không dùng bộ tham chiếu kiểm thử.

Lỗi lịch sử của lần phát hiện 05 thuộc `LegacyHiddenStorage`:
tuple lưu theo thứ tự `hidden7, hidden6, ..., hidden1`, nhưng
`read_as_if_forward(storage, k)` vẫn đọc vị trí `k` thay vì
địa chỉ tương ứng với tên giọt. Sai lệch xảy ra ở giọt 1, 2, 3,
5, 6 và 7. Giọt số 4 là đối chứng vô tình đúng.

Đường công khai `hidden_drop_spaghetti(c,t,k)` đi qua
`HiddenDropManager` và `LegacyHiddenStorage`. Đồng thời
`bootstrap_context(c,t)` lưu tuple thô trong
`hidden_drops_storage`. Chưa dùng các giọt này để điều phối
46 giọt nhìn thấy hoặc lịch cuối cùng.

Bốn hồi quy chuẩn của giai đoạn khám phá thử các giọt 1, 2, 3, 7
và cố ý thất bại, trong khi kiểm thử độc lập xác nhận cả bảy
giá trị của tuple theo đúng thứ tự đảo. **Không thêm bản vá 05**:
phép ánh xạ truy cập `8-k` thuộc riêng giai đoạn 11.

## Kiểm chứng kết thúc giai đoạn 10

CI chạy trên Elixir 1.18.5, Erlang/OTP 27: 101 kiểm thử,
**đúng bốn thất bại có chủ đích** ở giọt ẩn 1, 2, 3 và 7.
97 kiểm thử đạt; toàn bộ 88 kiểm thử từ các giai đoạn 1-9 vẫn xanh.
Không có cảnh báo biên dịch, khóa tên chuẩn hoàn tất.

Bộ tính sản xuất `HiddenDropCalculator` đã được đối chiếu với
oracle cho toàn bộ bảy giọt trước khi lưu. Sai lệch chỉ xuất hiện
khi đọc tuple đảo ngược theo số hiệu trực tiếp. Giọt thứ tư
vẫn khớp chuẩn, làm đối chứng của lỗi địa chỉ chứ không phải
lỗi công thức.

- [CI phát hiện 05: 101 kiểm thử, 4 sai lệch dự kiến](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38161317725)
- [Khóa tên chuẩn đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38161317727)

Giai đoạn 10/55 khép ở `EXPECTED_RED` đã kiểm chứng.
Giai đoạn 11/55 là `PATCH 05`: giữ tuple đảo ngược,
thực hiện mọi lần đọc hidden k qua địa chỉ `8-k`;
không đảo lại tuple hoặc xóa cách lưu cũ.
