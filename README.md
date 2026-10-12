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

## Giai đoạn 11 — Bản vá 05 cho kho bảy giọt ẩn

`LegacyHiddenStorage` tiếp tục cất giá trị theo thứ tự
`hidden7, hidden6, ..., hidden1`; cả hai hàm
`store_reversed` và `read_as_if_forward` đều giữ nguyên.

`HiddenStoragePatch.read_hidden(storage,k)` chỉ chuyển địa chỉ
đọc sang vị trí `8-k` và gọi chính hàm lịch sử
`LegacyHiddenStorage.read_as_if_forward(storage, 8-k)`.
Không đảo tuple, không thay vị trí các giá trị đang lưu, không
sử dụng bộ tham chiếu chuẩn trong đường sản xuất.
`HiddenDropManager.read` đi qua lớp vá, do đó
`hidden_drop_spaghetti` nhận đúng giọt được yêu cầu.

Bốn hồi quy chuẩn ở phát hiện 05 không thay đổi kỳ vọng và
phải chuyển sang đạt. Kiểm thử nối dây giữ hai bằng chứng riêng:
kho và hàm đọc legacy còn sai, trong khi lớp truy cập công khai
đã đúng. Mười bài kiểm thử mới so sánh bảy giọt qua nhiều cặp
ngày, số nguyên tùy ý, kho độc lập trong context, đồng thời,
kiểm tra nguồn và tính bất biến của các bản vá trước.
Chưa thêm cơ chế lấy giọt lịch sử của giai đoạn 12.

## Xác minh hoàn tất giai đoạn 11

CI trên Elixir 1.18.5 và Erlang/OTP 27 xác nhận **111 kiểm thử,
0 lỗi, không có cảnh báo biên dịch**. Bốn hồi quy chuẩn thuộc phát hiện
05 đã chuyển thành đạt mà không đổi kỳ vọng. Mười bài kiểm thử mới
đều đạt; khóa tên chuẩn độc lập PASS.

- [Kiểm thử xanh của giai đoạn 11](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38163456728)
- [Khóa tên chuẩn đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38163456763)

LegacyHiddenStorage và HiddenDropCalculator không thay đổi.
Giai đoạn 11/55 được đóng GREEN. Bước tiếp theo là
giai đoạn 12/55, `DISCOVERY 06`: lỗi giả định mọi giọt
quá khứ đều nằm trong kho các giọt nhìn thấy. Chưa thêm
bản vá 06 trong giai đoạn này.

## Giai đoạn 12 — Phát hiện 06: lịch sử giọt không biết kho giọt ẩn

Theo hợp đồng số học, 46 giọt nhìn thấy được tạo theo thứ tự.
Mỗi giọt `i` cần ba giá trị trước đó tại vị trí `i-1`,
`i-3`, `i-7`, kể cả những vị trí 0 đến -6 thuộc bảy
giọt ẩn đã tính ở giai đoạn 10.

Sai lầm lịch sử thứ sáu: `LegacyPrior.legacy_prior(visible_store,i,back)`
chỉ đọc `visible_store[i-back]`. Vì kho giọt nhìn thấy
không có phần tử tại các địa chỉ 0 đến -6, hàm cũ thay ô thiếu
bằng **0**, không đi đến kho giọt ẩn. Các ô dương đã tồn tại
vẫn được đọc đúng. Chưa có phép phân nhánh giữa giọt nhìn thấy
và giọt ẩn; bản vá 06 thuộc giai đoạn 13.

`VisibleDropCalculator` thực thi đầy đủ 11 lần nghiền đối với
từng giọt, dùng bảng đá đã vá, năm bộ đếm và SAVE chuẩn.
`VisibleDropManager` tạo đúng 46 ô trong kho nhìn thấy,
nhưng các giá trị bị lệch từ giọt đầu do lịch sử vắng.
Cả `visible_drops_spaghetti` và `bootstrap_context.visible_drops`
đều chạy trên đường sản xuất thực.

Bốn hồi quy chuẩn mới tại giọt nhìn thấy 1, 2, 7, 46 phải
đỏ có chủ đích. Các kiểm thử bảo vệ khẳng định giọt ẩn
không bị hỏng, thứ tự các ô và tính độc lập của các lần gọi.

## Xác minh đóng giai đoạn 12

GitHub Actions chạy Elixir 1.18.5, Erlang/OTP 27 với
**126 kiểm thử, đúng 4 hồi quy chuẩn cố ý đỏ**, 122 bài đạt,
không cảnh báo biên dịch. Cả 111 bài kiểm thử từ giai đoạn
1 đến 11 vẫn đạt và khóa tên chuẩn độc lập PASS.

Bốn hồi quy đỏ ở giọt nhìn thấy 1, 2, 7, 46 chứng minh
lookup lịch sử không đọc được bảy giọt ẩn. Mã tính 46 giọt
và kho giọt ẩn vẫn được giữ riêng trong context.
Một cảnh báo deprecation của Range trong kiểm thử mới
được sửa bằng `Map.filter`, không thay mã sản xuất.

- [CI với bốn hồi quy đỏ dự kiến](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38165148360)
- [Khóa tên chuẩn đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38165148358)

Giai đoạn 12/55 khép ở trạng thái `EXPECTED_RED` đã xác minh.
Giai đoạn 13/55, `PATCH 06`, sẽ giữ `LegacyPrior` để đọc
những vị trí dương, còn vị trí 0 đến -6 phải được ánh xạ về
giọt ẩn số `1-slot`. Không thêm phần sửa này ở giai đoạn 12.

## Giai đoạn 13 — Bản vá 06 cho ba giọt quá khứ

Lỗi từ giai đoạn 12 đã được cô lập ở `LegacyPrior`: hàm cũ
chỉ tra các vị trí thuộc kho giọt nhìn thấy, và trả về 0 nếu
vị trí không tồn tại. **Hàm này được giữ nguyên**.

`PriorPatch.read(visible_store, hidden_storage, i, back)`
tính `slot=i-back`. Nếu `slot>=1`, gọi
`LegacyPrior.legacy_prior(visible_store,i,back)` thực sự.
Nếu `slot<=0`, tính `hidden_number=1-slot` rồi lấy
giọt tương ứng qua `HiddenDropManager.read(hidden_storage,hidden_number)`,
tức tiếp tục dùng bản vá 05 cho thứ tự lưu đảo.
Không đảo hoặc gộp hai kho, không thay dữ liệu lịch sử.

`VisibleDropManager.build` nhận tuple giọt ẩn đã tính một lần
trong `Dispatcher.bootstrap`, truyền qua
`VisibleDropCalculator.calculate` và `PriorPatch.read`
cho cả ba độ lùi 1, 3, 7. Bộ tính vẫn dùng 11 hàng nghiền
và SAVE; đầu ra 46 giọt phải khớp bộ chuẩn.
Bốn hồi quy từ giai đoạn 12 được giữ nguyên và phải chuyển xanh.
11 kiểm thử giai đoạn 13 xác minh những vùng tiếp giáp,
46 giọt, ngày số nguyên lớn, thực thi song song,
đường legacy còn nguyên và các lớp vá trước.

## Kiểm chứng đóng giai đoạn 13

GitHub Actions xác nhận **137 kiểm thử, 0 thất bại, 0 cảnh báo biên dịch**.
Bốn hồi quy chuẩn từ phát hiện 06 giữ nguyên kỳ vọng và đều đạt.
Mười một kiểm thử mới đều đạt; khóa tên chuẩn hoàn tất.

`LegacyPrior` và bộ tham chiếu chuẩn test-only giữ nguyên.
`PriorPatch` phân nhánh chỉ trên vị trí của giọt trước,
vẫn gọi legacy thật khi vị trí dương. Không thay đổi các
lớp vá 01–05, kho các giọt hay giới hạn chưa tích hợp lịch.

- [Kiểm thử xanh của giai đoạn 13](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212531371)
- [Khóa tên chuẩn đạt](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212531416)

Trạng thái giai đoạn 13/55: `GREEN` đã được xác minh.
Giai đoạn tiếp theo là 14/55, `DISCOVERY 07`,
liên quan sai lệch chỉ số của bảng nghiền. Chưa khởi động.

## Giai đoạn 14 — Phát hiện 07: bảng nghiền sai chỉ số

Đã có 11 hàng nghiền đúng trong chương trình giai đoạn 13,
nhưng lần phát hiện thứ bảy lưu chúng từ index 0 trong
`LegacyGrindTable` và cho hàm `legacy_row(number)` đọc
trực tiếp index từ 1 đến 11. Vì vậy lần nghiền thứ nhất
sử dụng hàng thứ hai; lần thứ mười sử dụng hàng thứ mười một;
lần thứ mười một dùng hàng dự phòng `{0,0,0,0,1}`.

`VisibleDropCalculator` gọi hàm legacy thực cho cả 11 lần,
không bỏ qua lời gọi nào. SAVE, bảng đá, các giọt ẩn và cách
đọc ba giá trị trước đó vẫn qua sáu bản vá đã xác minh.
Các giá trị giọt nhìn thấy lệch chuẩn do thứ tự hàng nghiền,
không phải lỗi tính toán của các thành phần trước.

Giai đoạn DISCOVERY 07 không được sửa bảng hay đưa sentinel
vào index 0. Giai đoạn 15, `PATCH 07`, sẽ **đặt một hàng
sentinel thực tại index 0** và để 11 hàng nghiền thật tại
index 1..11, không thay hàm `legacy_row` hoặc xóa sentinel.

Giữ các kiểm thử đối chiếu chuẩn từ giai đoạn trước: lỗi mới
ảnh hưởng cả đường sản xuất, nên những kiểm thử đầu ra cũ có
thể đỏ có chủ đích và phải xanh lại sau PATCH 07. 14 kiểm thử
mới chứng minh dãy hàng lệch, giá trị dự phòng và toàn bộ
đường gọi thực. Không sửa các kỳ vọng chuẩn.

## Kiểm chứng kết thúc phát hiện 07

CI Elixir 1.18.5 / OTP 27 chạy **151 kiểm thử, đúng 16 sai lệch
được phân loại**, 135 bài đạt, không cảnh báo biên dịch.
Trong 16 bài đỏ: 4 bài mới trực tiếp kiểm hàng nghiền và
kết quả chuẩn, 5 bài cũ ở giai đoạn 12, 7 bài cũ ở giai đoạn 13.
Cả mười bài kiểm soát mới đều đạt. Những kỳ vọng chuẩn cũ
được giữ nguyên để kiểm tra rằng tác động của sai thứ tự nghiền
không bị che khuất. Khóa tên chuẩn độc lập đạt.

- [CI phát hiện 07, 16 sai lệch dự kiến](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38213818081)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38213818145)

Giai đoạn 14/55 kết thúc `EXPECTED_RED` đã được xác minh.
Giai đoạn 15/55 là `PATCH 07`: thêm sentinel tại index 0,
đặt 11 hàng thực ở 1..11 và giữ nguyên hàm đọc legacy.

## Giai đoạn 15 — Bản vá 07: giữ chỉ số cũ, thêm sentinel

Lỗi phát hiện 07 được sửa **bằng dữ liệu bảng**, không bằng
sửa phép đọc legacy. Bảng `LegacyGrindTable.@real_rows` giờ
chứa 12 hàng: `sentinel={0,0,0,0,1}` ở index 0 và
đủ 11 hàng nghiền nguyên bản ở index 1..11.
`LegacyGrindTable.legacy_row(number)` tiếp tục thực thi
`Enum.at(@real_rows,number,@missing_row)`, giữ nguyên cả
nhánh xử lý lỗi. `VisibleDropCalculator` tiếp tục gọi
hàm này cho cả 11 bước và 46 giọt thực.

Đường sản xuất không đảo bảng, không thay biến đếm, không
bỏ qua sentinel trong dữ liệu, và không gọi oracle trong
các module sản xuất. 16 sai lệch trong giai đoạn 14
phải chuyển thành xanh với kỳ vọng chuẩn giữ nguyên.
Mười bài kiểm soát cũ được chỉnh chỉ để kiểm cả sentinel
và hàm lịch sử; bốn hồi quy chuẩn của giai đoạn 14
không thay đổi. Thêm 12 kiểm thử mạnh về ánh xạ chỉ số,
đủ 46 giọt, số nguyên tới 2048 bit, tính độc lập,
tính đồng thời, những bản vá đã có và các biên.
Chưa tích hợp ngày lịch cuối, hoặc phát hiện 08.

## Kiểm chứng hoàn tất giai đoạn 15

CI Elixir 1.18.5 / Erlang/OTP 27 xác nhận **163 kiểm thử,
0 thất bại, 0 cảnh báo biên dịch**. Cả 16 hồi quy đã đỏ
vì lỗi nghiền giai đoạn 14 hiện xanh, không thay kỳ vọng chuẩn.
12 kiểm thử mới đều đạt; khóa tên chuẩn PASS độc lập.

Một lỗi escape trong bài kiểm toán mã nguồn mới được sửa
mà không ảnh hưởng mã sản xuất, phép đọc legacy hoặc dữ liệu bảng.
Sentinel vẫn nằm nguyên trong bảng tại index 0 và
11 hàng nghiền thật nằm ở index 1..11.

- [CI hoàn tất Stage15: 163/163](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38229835498)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38229835434)

Giai đoạn 15/55 khép `GREEN`. Giai đoạn 16/55 tiếp theo
là `DISCOVERY 08` về xếp hạng hoán vị gốc không.
Chưa triển khai nhánh phát hiện tiếp theo.

## Giai đoạn 16 — Phát hiện 08: nhầm hạng hoán vị từ một với gốc không

Dãy thứ tự sáu bát được chọn từ từng giọt nhìn thấy trong 46 giọt.
Bộ mở hạng lịch sử `LegacyPermutationUnrank0.old_permutation_unrank0(rank0)`
mở hoán vị bằng hệ giai thừa, với hạng bắt đầu từ **0**.
Dạng đại diện chạy vòng cho các bội của 720 để không có lỗi ngoài
miền, nhưng cách đánh số của thuật toán lịch sử vẫn gốc không.

Lần phát hiện 08 đặt `one_based=rem(drop-1,720)+1`
rồi **truyền trực tiếp `one_based`** vào hàm lịch sử thay vì
`one_based-1`. Do đó hạng 1 nhận thứ tự thứ hai, hạng
719 nhận thứ tự cuối, còn 720 quay về thứ tự đầu tiên.
Mọi hoán vị vẫn chứa đủ sáu ID 1..6 nhưng lệch chuẩn một hạng.

`BowlOrderManager.build_orders` tạo 46 thứ tự từ
`visible_drops` đã chính xác, và `Dispatcher.bootstrap`
giữ kết quả trong `Context.bowl_orders`. Giai đoạn này
chưa rót vào bát hoặc cập nhật trạng thái sáu bát.
Bốn hồi quy chuẩn mới phải đỏ ở hạng 1, 720, giọt đầu
và giọt cuối. Các bước SAVE, hidden, stone, grind và
46 giọt vẫn đúng; không đổi oracle hoặc các kiểm thử cũ.

Ở giai đoạn 17, PATCH 08 phải giữ hàm lịch sử và chuyển
theo chuỗi chuẩn:
```text
oneBased = regularMod(drop-1,720)+1
legacyRank0 = oneBased-1
order = oldPermutationUnrank0(legacyRank0)
```
Không dùng chuỗi vá này trong lần phát hiện hiện tại.

## Kiểm chứng hoàn tất giai đoạn 16

GitHub Actions với Elixir 1.18.5 / Erlang/OTP 27 chạy
**179 kiểm thử, đúng 4 hồi quy chuẩn đỏ có chủ đích**, 175 đạt,
0 cảnh báo biên dịch. Cả 163 bài kiểm thử thuộc giai đoạn
1–15 vẫn xanh. Các bài đỏ chỉ tại hạng 1, hạng 720,
thứ tự của giọt đầu và thứ tự của giọt thứ 46.
Khóa tên chuẩn độc lập PASS.

- [CI phát hiện 08, 4 hồi quy đỏ dự kiến](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38232940991)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38232941046)

Giai đoạn 16/55 kết thúc `EXPECTED_RED` đã xác minh.
Giai đoạn 17/55 là `PATCH 08`: giữ hàm mở hạng gốc không,
đổi `one_based` thành `legacy_rank0=one_based-1`
trước lời gọi. Chưa thêm bản vá trong giai đoạn 16.

## Giai đoạn 17 — Bản vá 08: ánh xạ hạng về gốc không

Giữ nguyên module lịch sử `LegacyPermutationUnrank0` và cả
thuật toán mở hạng bằng giai thừa. Bản vá chỉ thay đường gọi
trong `BowlOrderManager.order_from_drop`:

```text
one_based = rem(drop-1,720)+1
legacy_rank0 = one_based-1
order = old_permutation_unrank0(legacy_rank0)
```

Vì `drop` thuộc các số nguyên dương, `rem(drop-1,720)`
bằng phép dư chuẩn không âm, nên `legacy_rank0` thuộc
0..719. Kết quả đúng cả hạng 1 và 720, không còn quay vòng
sai qua 720 trong đường sản xuất. Hàm legacy trực tiếp vẫn
giữ nguyên cách hiểu hạng gốc không và tính chu kỳ của nó.

Bốn hồi quy chuẩn từ DISCOVERY 08 không thay đổi và phải
chuyển sang xanh. Các bài kiểm soát đã đòi kết quả sai
được thay bằng kiểm tra đồng thời đường chuẩn và lời gọi
legacy thô vẫn lệch một hạng. Thêm 14 bài kiểm thử mới
để so sánh trọn bộ 720 hoán vị, 46 vị trí trong nhiều context,
các bội 720, số nguyên lớn, không trạng thái dùng chung
và các bản vá trước. Không triển khai phép rót bát của
DISCOVERY 09.

## Kiểm chứng đóng giai đoạn 17

GitHub Actions trên Elixir 1.18.5 / Erlang/OTP 27 xác nhận
**193 kiểm thử, 0 thất bại và 0 cảnh báo biên dịch**.
Bốn hồi quy chuẩn giai đoạn 16 đều chuyển sang đạt
mà không đổi kỳ vọng; 14 bài kiểm thử mới đều đạt.
Khóa tên chuẩn độc lập PASS.

Hàm `LegacyPermutationUnrank0` không thay đổi so với
giai đoạn 16; oracle test-only không thay đổi. Các hoán vị
tính qua bản vá từ toàn bộ 720 hạng, cả hạng 1 và hạng 720,
đều trùng với oracle.

- [CI Stage17 193/193](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235528620)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235528637)

Giai đoạn 17/55 kết thúc `GREEN`. Điểm tiếp theo là
giai đoạn 18/55, `DISCOVERY 09`: lỗi các lần rót
tham chiếu đến vị trí cũ thay vì danh tính bát cố định.
Chưa bắt đầu giai đoạn 18.

## Giai đoạn 18 — Phát hiện 09: rót sai vì nhầm vị trí với ID bát

Sau khi tính chính xác 46 giọt và 46 hoán vị sáu ID bát,
chương trình khởi tạo sáu bát `initial_bowls` theo công thức
chuẩn rồi đi qua cả 46 lần khuấy, mỗi lần dùng snapshot
`old` và map `next` độc lập. Đường sản xuất thực được
kết nối tới `Dispatcher.bootstrap`, lưu
`Context.initial_bowls` và `Context.bowls_after_drops`.

Sai lầm lịch sử thứ chín nằm chính xác ở ba nguồn rót:
`LegacyPourPositions.read_old(bowls_old,position)` đọc
`bowls_old[position]` trực tiếp đối với vị trí 1, 2, 3,
dù theo thứ tự `order` thì ID bát thực tại vị trí đó
là `order[position]`. Công thức cho mỗi lần rót đúng
ở các hệ số, SAVE và độ lệch theo số giọt, nhưng dùng
giá trị của **bát sai**. Các bước khuấy tiếp theo đặt kết
quả vào ID bát thật, đọc đúng các bát lân cận từ snapshot;
không giới thiệu lỗi ghi đè in-place của giai đoạn 20.

Bốn hồi quy chuẩn mới đối chiếu một lần rót, bước khuấy
đầu và kết quả sau 46 giọt tại nhiều ngày. Chúng cố ý
đỏ; các bản vá từ 01 tới 08 vẫn phải xanh. Không làm
12 lần khuấy bổ sung sau giọt 46, không tích hợp lịch cuối.

Giai đoạn 19, `PATCH 09`, sẽ bảo toàn LegacyPourPositions,
thêm ánh xạ `bowlAlias[position]=order[position]` và
cho **mọi lần đọc nguồn bát trong ba phép rót** đi qua alias
trước khi gọi legacy. Chưa thực hiện điều này ở giai đoạn 18.

## Kiểm chứng đóng giai đoạn 18

GitHub Actions Elixir 1.18.5 / Erlang/OTP 27 chạy **209 kiểm thử,
đúng bốn hồi quy chuẩn đỏ dự kiến**, 205 bài đạt,
không có cảnh báo biên dịch. Toàn bộ 193 kiểm thử cũ
vẫn đạt và 12 bài kiểm soát mới đều xanh.
Bốn bài đỏ kiểm tra phép rót đầu, lần khuấy đầu,
trạng thái sáu bát sau 46 giọt và hai hướng thời gian.
Khóa tên chuẩn độc lập PASS.

- [CI giai đoạn 18: bốn sai lệch mong đợi](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239350202)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239350320)

Giai đoạn 18 kết thúc `EXPECTED_RED` đã xác minh.
Giai đoạn 19 `PATCH 09` cần giữ `LegacyPourPositions`,
đưa `order[position]` qua `bowlAlias` tới các nguồn rót
và không bắt đầu lỗi trộn in-place của giai đoạn 20.

## Giai đoạn 19 — Bản vá 09: định tuyến ba nguồn rót qua danh tính bát

`LegacyPourPositions.read_old(bowls_old,position)` tiếp tục
đọc `Map.fetch!(bowls_old,position)`. Hàm này được bảo tồn
nguyên vẹn, kể cả lỗi lịch sử nếu gọi với map ID bát thật.
Không sửa chỉ số trong hàm legacy.

Lớp mới `BowlAliasPatch` tạo bản xem riêng chỉ gồm ba vị trí
rót: `bowlAlias[position]=old[order[position]]`
với position 1..3. Sau đó lớp vá thực sự gọi
`LegacyPourPositions.pour(bowlAlias,...)`. Bằng cách đó,
cả ba nguồn đọc giá trị của ID bát phù hợp với thứ tự hiện tại,
nhưng hàm lịch sử vẫn được sử dụng. Kho `old` không thay đổi;
cả sáu phép khuấy khác tiếp tục đọc từ snapshot ID nguyên bản
và ghi vào map `next` riêng.

Bốn hồi quy chuẩn của giai đoạn 18 được giữ nguyên kỳ vọng;
riêng tiền xử lý ở bài kiểm thử rót trực tiếp được đổi để gọi
đường bản vá. Các kiểm thử cấu trúc cũ cũng phải chứng minh
hàm legacy còn tồn tại. Bổ sung 14 bài thử, bao gồm toàn bộ
720 hoán vị và ba nguồn rót, nhiều cặp ngày, số nguyên lớn,
thực thi song song, bất biến kho và ranh giới còn chưa tích hợp.
Chưa làm lỗi contamination in-place ở DISCOVERY 10.

## Kiểm chứng hoàn tất bản vá 09

CI Elixir 1.18.5 / Erlang/OTP 27 chạy **223 kiểm thử,
0 thất bại và 0 cảnh báo biên dịch**. Bốn hồi quy chuẩn
của phát hiện 09 chuyển sang đạt, kỳ vọng giữ nguyên.
14 bài kiểm thử Stage19 mới đều đạt, bao gồm kiểm tra
720 hoán vị và ba nguồn rót qua alias.

Hàm LegacyPourPositions không đổi và tiếp tục thực thi
Map.fetch! theo position, nhưng bản xem alias mới đưa
giá trị ID bát đúng vào cả ba lời gọi. Không đổi snapshot
old cho sáu phép khuấy. Khóa tên chuẩn PASS.

- [CI Stage19 223/223](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38242471594)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38242471534)

Trạng thái Stage19/55 là `GREEN`, đã xác minh.
Tiếp theo Stage20 `DISCOVERY 10` về ghi đè bát in-place;
chưa bắt đầu.

## Giai đoạn 20 — Phát hiện 10: ghi đè bát khi khuấy

Các giai đoạn trước đã sửa nguồn rót và thứ tự sáu ID.
Trong phát hiện 10, ba nguồn rót vẫn đọc đúng snapshot
`old` qua `BowlAliasPatch`, nhưng đường khuấy lịch sử
`LegacyInPlaceStir.run` nhận map `current` và thực hiện
tuần tự sáu vị trí. Ngay khi tính một ID, nó
`Map.put(current,id,updated)`, rồi đưa map mới ấy cho lần
tiếp theo. Elixir có map bất biến, song cách truyền map
đã cập nhật tái tạo chính xác lỗi in-place: nguồn lân cận
của các vị trí sau không còn là snapshot đầu vòng.

`LegacyInPlaceStir.compute_one` giữ công thức khuấy và
giao diện riêng có thể gọi với source. Vị trí 1 còn đúng
vì chưa có ghi đè; vị trí 2 và các vị trí tiếp theo bị
nhiễm do đọc source đã thay, ngay cả khi hoán vị là đồng nhất.
Kết quả sau 46 giọt khác oracle nhưng các bước SAVE, đá,
giọt, hoán vị và rót còn chính xác. Không có trạng thái
ngữ nghĩa toàn cục.

Giai đoạn 21, `PATCH 10`, phải giữ module lịch sử và
cung cấp `vaultOld` cố định cho mọi lần gọi
`compute_one`, lưu sáu kết quả trong `pending`,
chỉ cập nhật kho bát sau khi tính xong cả sáu vị trí.
Không triển khai bản vá này tại giai đoạn 20.

## Kiểm chứng kết thúc phát hiện 10

CI Elixir 1.18.5 / Erlang/OTP 27 xác nhận **239 kiểm thử,
đúng 14 sai lệch được phân loại**, 225 đạt, không cảnh báo
biên dịch. Bốn hồi quy chuẩn mới của Stage20 đỏ, cùng sáu
phép so sánh chuẩn Stage18 và bốn phép so sánh Stage19.
Các sai lệch đều do vòng `LegacyInPlaceStir.run` đọc lại
map current đã được cập nhật trong cùng một giọt.
Không có lỗi khác; 12 bài kiểm soát Stage20 đều PASS.
Khóa tên chuẩn độc lập PASS.

- [CI phát hiện 10, 14 sai lệch dự kiến](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38248260572)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38248260716)

Giai đoạn 20/55 kết thúc `EXPECTED_RED` được xác minh.
Giai đoạn 21/55 là `PATCH 10`: giữ LegacyInPlaceStir,
đưa snapshot `vaultOld` vào sáu lần `compute_one`,
chứa sáu kết quả trong `pending`, rồi commit đồng loạt.
Chưa thực hiện ở giai đoạn 20.

## Giai đoạn 21 — Bản vá 10: vaultOld cố định và pending sáu bát

Hàm `LegacyInPlaceStir.run` **giữ nguyên** lỗi lịch sử:
mỗi lần khuấy một vị trí, nó đưa ngay map `current` đã
ghi kết quả vào lần khuấy tiếp theo. Module này vẫn được
giữ để tái hiện sai lệch phát hiện 10. Không sửa
`LegacyInPlaceStir.compute_one`, công thức SAVE, đá,
thứ tự ID hoặc các phép rót.

`BowlVaultPatch.run` thay đường gọi production:
`vault_old=old` là snapshot cố định của cả sáu vị trí.
Với mỗi position 1..6, gọi chính
`LegacyInPlaceStir.compute_one(vault_old,...)`, gom
`{id,updated}` vào map `pending` riêng. Chỉ sau khi
cả sáu giá trị đã được tính, thực hiện
`Map.merge(vault_old,pending)` đúng một lần. Như vậy
không vị trí nào đọc dữ liệu được viết trong cùng giọt.
Ba nguồn rót vẫn thông qua `BowlAliasPatch` và
`LegacyPourPositions` nguyên bản.

Bốn hồi quy chuẩn của Stage20 cùng mười hồi quy từ
Stage18-19 được giữ nguyên để chứng minh sửa tận gốc.
Bổ sung 14 bài kiểm thử về 720 hoán vị sáu bát,
tính đồng thời, số nguyên rất lớn, giới hạn và bất biến
snapshot; chưa tích hợp 12 lần khuấy cuối và lịch.

## Kiểm chứng đóng giai đoạn 21

CI Elixir 1.18.5 / OTP 27 xác nhận **253 kiểm thử,
0 thất bại và 0 cảnh báo**, khóa tên chuẩn độc lập PASS.
14 hồi quy chuẩn đã đỏ trong phát hiện 10 trở lại đạt,
không thay kỳ vọng. 14 bài kiểm thử Stage21 mới đều PASS,
bao gồm đủ 720 hoán vị và các thời điểm có số nguyên lớn.

Module `LegacyInPlaceStir` và oracle test-only không đổi.
Lời gọi trực tiếp `LegacyInPlaceStir.run` vẫn tái hiện lỗi
lịch sử; đường production dùng `BowlVaultPatch.run`,
tính sáu `LegacyInPlaceStir.compute_one(vault_old,...)`
trên một nguồn và commit kết quả `pending` sau cùng.

Trong lần kiểm đầu phát sinh warning unused alias trong
kiểm thử kiểm soát Stage20; một commit kiểm thử riêng đã
thêm khẳng định trực tiếp với alias đó. CI chạy lại
không cảnh báo, không sửa production.

- [CI Stage21 253/253](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38254477457)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38254477452)

Giai đoạn 21/55 kết thúc `GREEN`. Tiếp theo giai đoạn
22/55 `DISCOVERY 11`; chưa tích hợp 12 lần khuấy sau
46 giọt hoặc tính lịch hoàn chỉnh.

## Giai đoạn 22 — Phát hiện 11: ô thứ tự bát bị ghi đè 58 lần

Đường sản xuất tiếp tục xử lý chính xác 46 giọt
bằng `BowlVaultPatch` và sáu ID bát. Sau đó
`PostStirCalculator` thực hiện **12 lần khuấy cuối**
theo đúng công thức, dùng tổng SAVE của sáu bát cộng
`149 * stir`, chọn hoán vị và tính sáu ID từ snapshot
`old` riêng của từng lượt.

**Lỗi lịch sử thứ mười một chỉ nằm trong bộ nhớ thứ tự:**
`LegacyOrderMemory` lưu cùng một trường `order`.
Mỗi giọt ghi lại hoán vị của nó (46 lần); mỗi lần khuấy
cuối cũng ghi đè hoán vị vào đúng trường đó (12 lần).
Sau 58 lần, thứ tự cuối đến từ `{:stir,12}` chứ không
phải `{:drop,46}`. Truy vấn bát kế tiếp thật
`next_bowl_spaghetti/3` cố ý đọc bộ nhớ bị ghi đè.
`bowl_orders[46]` vẫn còn như dữ liệu kết quả các giọt,
nhưng **chưa có latch riêng** tại điểm giọt 46 dành cho
truy vấn nên đường truy vấn không sử dụng nó.

Sáu bát sau 12 lần khuấy phải khớp đầy đủ với
`NormativeReference.post_stir12` và `sauce.bowls`,
còn hồi quy truy vấn bát kế tiếp phải đỏ. Không sửa
`LegacyOrderMemory` trong phát hiện 11. PATCH 11
ở giai đoạn 23 phải giữ bộ nhớ lịch sử và chốt riêng
`orderAt46Latch` ngay tại giọt 46, rồi định tuyến
truy vấn tới latch thay vì bộ nhớ bị ghi đè. Không
thực hiện latch trong giai đoạn 22.

Thêm 16 kiểm thử bao gồm nguồn của 58 lần ghi, hoán vị
giọt 46, đủ 12 lần khuấy, SAVE, các bản vá 01..10,
số nguyên 2048 bit, đồng thời, và bốn hồi quy truy vấn
so sánh với thứ tự giọt 46. Không mở hệ thống dòng câu trả lời
hoặc logic chọn cổng của các giai đoạn sau.

## Kiểm chứng đóng phát hiện 11

CI trên Elixir 1.18.5 / Erlang OTP 27 chạy
**269 kiểm thử với chính xác bốn hồi quy chuẩn đỏ có chủ đích**,
265 bài đạt, 0 cảnh báo biên dịch. Cả 253 bài kiểm thử cũ
từ giai đoạn 1..21 đều đạt; 12 bài điều khiển mới cũng đạt.
Khóa tên chuẩn độc lập PASS.

Bốn bài đỏ kiểm tra quan hệ bát kế tiếp dùng hoán vị giọt
thứ 46 ở ngày gốc, ngày ngược hướng và ngày nguyên rất lớn.
Trong production, `LegacyOrderMemory` vẫn bị ghi lại
46+12=58 lần và query dùng thứ tự lượt khuấy thứ 12.
Cả 12 lượt khuấy và các giá trị sáu bát sau cùng khớp oracle.

Đã sửa một kiểm thử kiểm toán từ Stage18 trỏ sang tên
đường bootstrap mới và dùng alias đã khai báo trong
kiểm thử Stage22; không thay production, không che
bất kỳ hồi quy normative nào.

- [CI phát hiện 11: đúng bốn hồi quy đỏ](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38259198372)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38259198399)

Giai đoạn 22 kết thúc `EXPECTED_RED` đã xác minh.
Bước tiếp theo: giai đoạn 23 `PATCH 11`, giữ legacy
58 lần ghi và tạo orderAt46Latch riêng để truy vấn.
Chưa thực hiện bản vá trong DISCOVERY 11.
