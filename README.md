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

## Giai đoạn 23 — Bản vá 11: chốt thứ tự tại giọt 46

Bản vá `OrderAt46LatchPatch` được đưa vào đường sản xuất,
nhưng `LegacyOrderMemory` **không bị sửa đổi**: nó vẫn ghi
46 lần trong chuỗi giọt và ghi thêm 12 lần vào cùng ô trong
12 lượt khuấy cuối. Tổng `writes=58`, `last_source={:stir,12}`
vẫn đúng như di sản của phát hiện 11.

Sau khi hoàn thành giọt 46 và **trước** 12 lượt post-stir,
`Dispatcher.bootstrap` gọi `OrderAt46LatchPatch.capture`
trên `memory_after_drops`. Hàm chỉ chấp nhận
`writes=46` và `last_source={:drop,46}` cùng hoán vị
đủ sáu ID. Chốt `order_at_46_latch` được lưu trong
`Context` riêng và không bị ghi đè trong các lượt sau.

`next_bowl_spaghetti` đọc chốt này thay vì ô memory
đã bị ghi đè. Để bảo tồn chính mã truy vấn lịch sử,
`OrderAt46LatchPatch.next_bowl` gọi lại
`LegacyOrderMemory.next_bowl` với bản xem
`%{order: order_at_46_latch}`. Như vậy thuật toán
truy vấn không được sao chép hoặc thay mới; chỉ sửa
nguồn thứ tự được truyền vào. Các giá trị sáu bát cuối
và cả 58 lần ghi không đổi.

Bốn so sánh chuẩn đỏ từ giai đoạn 22 giữ nguyên biểu thức
`assert` và phải trở lại xanh. Kiểm thử điều khiển cũ
tiếp tục chứng minh hàm legacy thô trả quan hệ sai;
đường production trả kết quả từ giọt 46. Thêm 14 bài
kiểm thử Stage23 kiểm 720 hoán vị, các biên, bất biến,
46+12 lượt, ngày 2048 bit, chạy song song và mã nguồn.
Không bắt đầu giai đoạn 24.

## Kiểm chứng đóng bản vá 11

GitHub Actions Elixir 1.18.5 / Erlang OTP 27 xác nhận
**283 kiểm thử, 0 thất bại và 0 cảnh báo biên dịch**.
Bốn hồi quy chuẩn Stage22 trở lại xanh mà không thay kỳ vọng;
14 bài Stage23 mới đều đạt. Khóa tên chuẩn PASS độc lập.

Vết lỗi lịch sử còn nguyên: LegacyOrderMemory tiếp tục
58 lần ghi và kết thúc với `last_source={:stir,12}`.
Bản vá tạo `order_at_46_latch` từ memory ở giọt 46
trước khi có 12 lần ghi thêm. Truy vấn production dùng latch
và vẫn gọi hàm đọc LegacyOrderMemory thực.
Module legacy và oracle test-only không bị sửa.

- [CI Stage23 283/283](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38263249194)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38263249280)

Giai đoạn 23/55 kết thúc `GREEN`. Điểm tiếp theo:
giai đoạn 24/55 `DISCOVERY 12`; chưa bắt đầu.

## Giai đoạn 24 — Phát hiện 12: tìm bát kế tiếp theo tên cố định

Một lỗi mới được phơi bày mà không phá các bản vá trước.
`OrderAt46LatchPatch` vẫn chốt đúng hoán vị sáu ID khi
giọt thứ 46 hoàn tất, và `LegacyOrderMemory` vẫn ghi đè
46+12=58 lần như hợp đồng lịch sử. Sáu giá trị bát cuối
vẫn đúng với oracle. Tuy nhiên, đường truy vấn mới
`LegacyFixedNameSuccessor.old_next_bowl_fixed_name(id)`
bỏ qua **vị trí của ID trong hoán vị đã chốt** và chỉ trả
vòng tên cố định `1→2→3→4→5→6→1`.

Ví dụ với `orderAt46Latch=[4,5,2,3,6,1]`, hỏi ID 3
thì phần tử kế theo hoán vị là **6**, nhưng hàm legacy
trả **4**. Hỏi ID 1 cho 2 thay vì 4, hỏi ID 5 cho 6 thay
vì 2. `Dispatcher.next_bowl` thực sự gọi hàm legacy
cố định, còn latch chuẩn vẫn có trong Context để kiểm chứng.

Thêm 18 bài kiểm thử: 14 bài kiểm soát vòng fixed ID,
đủ 720 hoán vị, nguồn latch, 58 lần ghi, lỗi đầu vào,
ngày rất lớn, đồng thời và kiểm toán mã nguồn; bốn hồi
quy chuẩn cố ý đỏ. Giữ các biểu thức normative từ giai
đoạn 22/23, dù có thể đỏ lại do query cố định.
Không thêm `NextBowlPatchWrapper` của giai đoạn 25.

Trong PATCH 12 phải giữ `old_next_bowl_fixed_name`
nguyên vẹn và gọi riêng cho chẩn đoán, nhưng trả kết quả
qua tìm vị trí `queriedId` trong `orderAt46Latch`,
sau đó lấy phần tử tiếp theo với vòng 6→1.

## Kiểm chứng đóng phát hiện 12

CI Elixir 1.18.5 / Erlang OTP 27 đã chạy **301 bài kiểm thử,
đúng 12 thất bại có chủ đích**, 289 bài đạt, không cảnh
báo biên dịch; Canonical Names Lock PASS. Phân loại:
4 hồi quy chuẩn mới Stage24, 6 bài Stage22 và
2 bài Stage23 đỏ trở lại do query chọn vòng tên ID cố định.
Tất cả thất bại đều do `old_next_bowl_fixed_name`
không tìm vị trí trong latch; các phép SAVE, 46 giọt,
12 lần khuấy, sáu bát, chốt order giọt 46 vẫn đúng.

Trong lần CI đầu có thêm hai lỗi kiểm toán nguồn cũ
và một cảnh báo alias trong bài Stage24. Đã cập nhật
kiểm toán theo tên mới, sửa chú thích tránh token bị
cấm của Stage01, dùng alias LegacyOrderMemory trực tiếp.
Không đổi công thức sản xuất hoặc khẳng định oracle.

- [CI phát hiện 12: chính xác 12 sai lệch dự kiến](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38265844932)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38265844794)

Giai đoạn 24/55 kết thúc `EXPECTED_RED` đã xác minh.
Giai đoạn 25 `PATCH 12`: giữ và gọi hàm
`old_next_bowl_fixed_name` để chẩn đoán, còn kết quả
phải tìm ID trong `order_at_46_latch` và lấy phần tử
tiếp theo theo vòng sáu vị trí. Chưa bắt đầu giai đoạn 25.

## Giai đoạn 25 — Bản vá 12: bát kế tiếp theo vị trí, legacy chỉ chẩn đoán

`LegacyFixedNameSuccessor.old_next_bowl_fixed_name(id)` được
giữ nguyên, vẫn trả vòng ID cố định `rem(id,6)+1`.
Bản vá không thay thuật toán legacy, cũng không bỏ nó
khỏi đường chạy. `NextBowlPatchWrapper.diagnose` gọi
**thật** hàm legacy để lấy `legacy_next_id`, rồi gọi
`OrderAt46LatchPatch.next_bowl` để lấy `correct_next_id`
qua vị trí của ID trong hoán vị đã chốt sau giọt 46.
Báo cáo riêng cho từng lời gọi có cả hai kết quả và
cờ `diverges`; API sản xuất `next_bowl_spaghetti`
chỉ trả `correct_next_id`.

Với thứ tự [4,5,2,3,6,1], ID 3 nhận giá trị chuẩn 6
trong khi báo cáo legacy giữ nguyên kết quả sai 4.
Với ID ở vị trí thứ sáu, kết quả quay về phần tử
đầu danh sách theo thứ tự thực. Đường public cho phép
xem chẩn đoán tách biệt, không dùng biến chung hoặc
đưa giá trị sai vào tính toán chuẩn.

Chốt giọt 46, cả 58 lần ghi LegacyOrderMemory, 12 lượt
khuấy cuối và sáu bát đều giữ nguyên. Mười hai phép
so sánh đỏ từ giai đoạn 24 cần trở lại đạt:
bốn hồi quy Stage24, sáu Stage22 và hai Stage23.
Ở bài fixture Stage24 vẫn giữ giá trị chuẩn kỳ vọng
nhưng gọi wrapper, còn lời gọi thô legacy vẫn được
kiểm chứng riêng. Thêm 16 bài Stage25 gồm 720 hoán vị
x 6 ID, sai lệch chẩn đoán, biên cuối-đầu, ngày lớn,
không trạng thái chung, tính bất biến và mã nguồn.
Không bắt đầu DISCOVERY 13.

## Kiểm chứng đóng bản vá 12

CI Elixir 1.18.5 / Erlang OTP 27 xác nhận **317 kiểm thử,
0 thất bại và 0 cảnh báo biên dịch**; khóa tên chuẩn độc
lập PASS. Mười hai bài từng đỏ tại DISCOVERY 12 đều xanh.
16 bài kiểm thử Stage25 mới đều đạt, bao gồm 720 hoán vị
x sáu ID và truy vấn chẩn đoán song song.

`LegacyFixedNameSuccessor` và `LegacyOrderMemory`
không thay đổi. `NextBowlPatchWrapper` tiếp tục gọi
hàm ID cố định và giữ giá trị `legacy_next_id`, nhưng
trả `correct_next_id` lấy từ hoán vị giọt 46.
`OrderAt46LatchPatch` cũng giữ nguyên và 58 lần ghi
memory lịch sử tiếp tục xảy ra. Giá trị sai của legacy
được giữ làm bằng chứng, không dùng làm kết quả chính.

- [CI Stage25: 317/317](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38269570216)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38269570259)

Giai đoạn 25/55 kết thúc `GREEN` đã xác minh.
Bước tiếp theo là giai đoạn 26 `DISCOVERY 13`;
chưa triển khai trong giai đoạn này.

## Giai đoạn 26 — Phát hiện 13: lựa chọn hạng modulo bị thiên lệch

Sau PATCH 12, ID bát được hỏi và ID bát kế tiếp đều đúng.
`AnswerStreamManager` mở **vòng đáp án chuẩn** từ sáu bát
sau 12 lượt khuấy: `first` dùng SAVE của bình phương
`bát_được_hỏi + dấu_hỏi + 181`, cộng
`179*bát_kế + dấu_hỏi`. Chiều vòng là +1 hoặc -1
theo tính chẵn lẻ của SAVE thứ hai với hệ số 193 và
197*bát_6. Phần tử thứ k bằng
`1+regularMod(first-1+step*k,M)`, M=2^127-1.
Dữ liệu khởi tạo và các bước vòng phải khớp oracle
ở mọi hướng ngày và cả số nguyên rất lớn.

**Khuyết tật lịch sử thứ 13** nằm ở chọn hạng ngắn.
`LegacyBiasedPick.biased_legacy_pick(x,N)` lập tức
trả `1+rem(x-1,N)`. `choose_rank_short_biased`
lấy ngay `answer_at(0)` rồi gọi hàm legacy dù x
vượt ngưỡng chia đều `floor(M/N)*N`. Các phần dư cuối
của miền 1..M vì vậy bị phân phối không đều. Không
được thay phép chọn này thành rejection trước Stage27.

Các hồi quy sử dụng vòng thử tổng hợp có `first=M`
hoặc `M-1` và chiều được kiểm soát. Với N>M/2,
ngưỡng nhận là N; phần tử M phải bị bỏ và vòng tiến
tới 1, nhưng legacy trả một hạng khác. Với N=M-3,
số bước từ chối khi đi lùi từ M là chính xác ba,
không phải vòng lặp lớn. Không sửa kỳ vọng oracle
để che khuyết tật. Thêm 19 test, gồm 15 bài kiểm soát
và bốn hồi quy chuẩn đỏ; 317 bài của Stage1..25
phải còn xanh.

PATCH 13 tại Stage27 sẽ **giữ nguyên LegacyBiasedPick**,
tiến trên cùng một vòng đáp án cho tới khi
`x<=floor(M/N)*N`, rồi mới gọi legacy với x hợp lệ.
Không thực hiện sớm ở Stage26; không mở wideDetour
cho N>M thuộc DISCOVERY 14.

## Kiểm chứng đóng phát hiện 13

GitHub Actions Elixir 1.18.5 / OTP 27 đã chạy
**336 kiểm thử, đúng bốn hồi quy chuẩn đỏ có chủ đích**,
332 bài đạt và 0 cảnh báo biên dịch. Toàn bộ 317 bài
Stage1..25 đạt, cùng 15 bài kiểm soát Stage26;
Canonical Names Lock PASS độc lập.

Vòng đáp án mới và các công thức SAVE đều chuẩn.
Bốn sai lệch chỉ xuất hiện khi `x=answer_at(0)`
vượt `floor(M/n)*n`, nhưng hàm
`LegacyBiasedPick.biased_legacy_pick` vẫn được gọi ngay.
Trong các mẫu hữu hạn, oracle phải bỏ một đến ba giá trị
trên cùng vòng, còn legacy lấy dư ngay trên x đầu.

Lần CI đầu có thêm một kiểm thử kiểm soát sai vì
coi k=0 là đầu vào không hợp lệ. Đã sửa duy nhất
tập đầu vào sai trong bài kiểm thử, giữ nguyên các
hồi quy chuẩn và code production. CI chạy lại đúng
bốn lỗi mong đợi và không có cảnh báo.

- [CI Stage26: đúng bốn sai lệch dự kiến](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38274786459)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38274786326)

Giai đoạn 26/55 kết thúc `EXPECTED_RED` đã xác minh.
PATCH 13 ở giai đoạn 27 phải giữ legacy và chỉ gọi nó
sau khi `x<=limit`, tiến dọc chính vòng trả lời
bằng tăng k. Chưa sửa khuyết tật ở Stage26.

## Giai đoạn 27 — Bản vá 13: từ chối trước khi dùng legacy chọn hạng

`LegacyBiasedPick.biased_legacy_pick(x,n)` vẫn giữ
nguyên `rem(x-1,n)+1`. Hàm legacy chỉ chính xác
cho cách chọn đồng đều khi x trước đó đã được lọc.
Không sửa hàm hoặc gọi nó trên giá trị vượt ngưỡng.

`ShortRejectionPatch` tính
`limit=div(M,n)*n` với M=2^127-1. Bắt đầu
`k=0`, lấy `x=AnswerStreamManager.answer_at(stream,k)`.
Nếu x>limit thì tăng k và đọc tiếp **trên cùng vòng**
đã có hạt và chiều không đổi. Khi x<=limit mới gọi
thật `LegacyBiasedPick.biased_legacy_pick(x,n)`.
Đây là bộ tính legacy nguyên vẹn sau lớp loại bỏ,
không phải bản sao công thức thay thế.

Bản vá cung cấp trace chứa số phần tử bị bỏ,
vị trí nhận, giá trị nhận, limit và rank. Đường
production `AnswerStreamManager.choose_rank_short_biased`
vẫn giữ tên tương thích nhưng trả kết quả từ bản vá.
Bốn so sánh chuẩn của Stage26 giữ nguyên kỳ vọng,
nhưng phải xanh. Hai kiểm thử kiểm soát Stage26
được sửa để xác nhận legacy vẫn thiên lệch trực tiếp
và lớp mới bác bỏ trước khi gọi nó.

18 kiểm thử Stage27 mới bao gồm nhiều n=1..M,
ràng buộc x<=limit, quấn vòng tiến/lùi, vị trí 0,
biên M, 720 và các giá trị lớn, gọi lại legacy
sau accept, dữ liệu ngày thực, đồng thời và nguồn.
Mọi giai đoạn trước giữ nguyên. Không mở wideDetour
cho N>M hay DISCOVERY 14, không công bố lịch hoàn chỉnh.

## Kiểm chứng đóng bản vá 13

GitHub Actions Elixir 1.18.5 / Erlang OTP 27 đã chạy
**354 kiểm thử, 0 thất bại, 0 cảnh báo biên dịch**.
Bốn hồi quy chuẩn từng đỏ ở Stage26 đều xanh trở lại,
giữ nguyên giá trị expected. 18 bài Stage27 mới
cũng đạt; Canonical Names Lock độc lập PASS.

`ShortRejectionPatch` giữ nguyên stream đầu vào,
đọc các phần tử tuần tự từ `answer_at(stream,k)`
cho tới khi `x<=div(M,n)*n`, chỉ sau đó gọi hàm
legacy cũ. Báo cáo trace cho biết chính xác phần tử
được nhận, vị trí và số lần loại bỏ. Cả hạt, hướng,
SAVE, ID kế cận và 12 lần khuấy cuối đều giữ nguyên.
`LegacyBiasedPick` và oracle test-only không thay đổi.

- [CI Stage27: 354/354](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38280022089)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38280022253)

Giai đoạn 27/55 kết thúc `GREEN`. Bước tiếp theo
là Stage28/55 `DISCOVERY 14` của lựa chọn miền
rộng n>M; chưa triển khai trong Stage27.

## Giai đoạn 28 — Phát hiện 14: hạng rộng chỉ dùng một chữ số

Đường sản xuất `choose_rank_spaghetti` mới chấp nhận
n nguyên dương, nhưng có hai nhánh. Với `n<=M`,
đường short vẫn đi qua `ShortRejectionPatch`,
dùng rejection trên cùng answer ring chính xác như
PATCH 13. Với `n>M`, lịch sử dùng
`LegacySingleDigitWidePick.choose_rank`: đọc duy
nhất `answer_at(stream,0)` rồi gọi
`LegacyBiasedPick.biased_legacy_pick(x,n)`.
Vì x luôn thuộc 1..M nên hạng trả về cũng không thể
vượt M, dù n có thể lớn hơn M nhiều bậc.

Phương pháp chuẩn cho n>M phải lấy số chữ số tối
thiểu k sao cho `M^k>=n`, ghép k phần tử liên tiếp
trên cùng answer ring thành số một-based theo cơ số M
với chữ số đầu là bậc thấp nhất, sau đó mới tiến
và bác bỏ nếu vượt giới hạn đều. Chưa có mã này
trong DISCOVERY 14; `wideDetour` dành riêng Stage29.

Thêm 20 kiểm thử Stage28: 16 kiểm soát giữ nguyên
lựa chọn short và toàn bộ các công thức, kiểm thử
wide legacy thiếu phạm vi, kết quả từ ngày thật,
vòng đáp án 2048 bit và nhiều task song song;
bốn hồi quy chuẩn đỏ ở n=M+1, M², M²+1 và M³+1
với vòng tổng hợp first=1,step=+1. Không sửa oracle
test-only hoặc các bản vá 01..13. Không tạo lịch cuối.

## Kiểm chứng đóng phát hiện 14

CI Elixir 1.18.5 / Erlang OTP 27 đã chạy
**374 kiểm thử, đúng bốn sai lệch chuẩn đỏ cố ý**,
370 bài đạt và 0 cảnh báo biên dịch.
Toàn bộ 354 bài của Stage1..27 đều đạt; 16 bài
kiểm soát Stage28 mới đều PASS. Canonical Names
Lock độc lập PASS.

Bốn hồi quy chuẩn đỏ đều đến từ chọn hạng n>M
dùng một chữ số đầu, không có lỗi ở short rejection,
SAVE, answer ring, bát hoặc ID kế tiếp. Các miền
n=M+1, M², M²+1 và M³+1 cần lần lượt hai, hai,
ba và bốn chữ số theo cơ số M, nhưng nhánh legacy
trả 1 cho cả bốn fixture first=1,step=+1.

- [CI phát hiện 14, bốn sai lệch mong đợi](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38283015914)
- [Khóa tên chuẩn PASS](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38283016003)

Giai đoạn 28/55 đóng `EXPECTED_RED` được xác minh.
Stage29 `PATCH 14` phải giữ module lịch sử, xây
k chữ số từ cùng answer ring rồi thực hiện wide
rejection +/-1 trên modulo M^k. Chưa làm ở Stage28.


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
