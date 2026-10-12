# Giai đoạn 26 — Phát hiện 13: chọn modulo trước từ chối

## Nền đã xác minh

Giai đoạn 25 khép tại
`4249db8054a11dcdc4ea0e9358befb31971ed552`.
CI Elixir 1.18.5 / OTP 27 có 317 kiểm thử đạt,
0 thất bại, 0 cảnh báo, Canonical Names Lock PASS.
Các bản vá 01..12 đã tích hợp đúng; Stage26 không
sửa lại các chức năng này.

## Vòng đáp án chuẩn mở lần đầu

`AnswerStreamManager.build` nhận sáu bát từ sau 12
lượt khuấy, ID được hỏi và ID kế tiếp từ
`NextBowlPatchWrapper` cùng dấu hỏi (seal).
Với M=2^127-1:

```text
first = SAVE((bowls[queried]+seal+181)^2
             +179*bowls[next]+seal)
d = SAVE((first+seal+1+193)^2 +193*first+197*bowls[6])
step = +1 nếu d lẻ; -1 nếu d chẵn
answerAt(k) = 1+regularMod(first-1+step*k, M)
```

Các phép trên dùng `SaveManager` và Integer.mod;
không gọi hoặc sao chép mã từ oracle test-only vào
production. Vòng vẫn đúng khi k>M và với c,t nguyên
rất lớn. Cùng một request giữ một seed/hướng cố định.

## Lỗi thực được đưa vào production

`LegacyBiasedPick.biased_legacy_pick(x,n)`:
```text
return 1+rem(x-1,n)
```

`AnswerStreamManager.choose_rank_short_biased`
lấy `x=answer_at(stream,0)` rồi gọi legacy **ngay**.
Nó không xác định và không kiểm tra:
```text
limit = floor(M/n)*n
accept = x<=limit
```

Khi M không chia hết n, số lần gán vào các hạng
không đều. Đây là khuyết tật bias lịch sử chính xác;
không thêm rejection hay bước tăng k trong Stage26.
Cũng không thêm wideDetour cho n>M, vốn thuộc Stage28.

`Dispatcher.answer_stream`, `answer_at`,
`choose_rank_short` và các API công khai tương
ứng dùng tính toán production thực, bootstrap đúng
một lần cho mỗi lời gọi đầu vào.

## Chứng cứ kiểm thử

Thêm 19 bài `test/stage_26_discovery_13_test.exs`.
15 bài điều khiển: công thức seed, dấu hướng,
vòng quấn xuôi/ngược, các ID đã vá, số nguyên rất
lớn, kiểm toán source, miền n và chức năng legacy
còn tồn tại. N=M hoặc N=1 là miền không thiên lệch,
cho cùng kết quả với oracle.

Bốn hồi quy normative cố ý đỏ, không dùng may rủi:
- first=M,step=+1,n=floor(M/2)+1: chuẩn bỏ M và chọn 1.
- first=M-1,step=+1,cùng n: chuẩn bỏ M-1,M và chọn 1.
- first=M,step=-1,n=M-3: chuẩn bỏ M,M-1,M-2 và chọn M-3.
- first=M,step=+1,n=M-3: chuẩn bỏ M và chọn 1.

Giá trị expected lấy từ `Ref.choose_rank_short`
trên AnswerStream test-only; actual chạy qua
`AnswerStreamManager.choose_rank_short_biased`.
Không sửa normative oracle, không thay 317 test cũ.
Dự kiến 336 test, bốn lỗi có chủ đích nếu CI phù hợp.

## Giai đoạn 27 — PATCH 13, chưa thực hiện

Giữ `LegacyBiasedPick` nguyên vẹn. Tạo
`ShortRejectionPatch` dùng cùng vòng và k tăng
cho đến khi x<=floor(M/n)*n; **chỉ sau khi chấp nhận**
mới gọi hàm legacy. Không tạo seed mới, không gọi
legacy trước rejection. Không bắt đầu giai đoạn 27
hay các bước gate/date.

## Dấu vết và chính sách

Chỉ commit tới nhánh `Elixir+tiếng-Việt`,
không sửa main, không commit gói HANDOFF_*,
không nhập oracle trong mã production.

## Kết quả CI và phân loại thực tế

- Commit triển khai:
  `d45485a9c4c600cf6983f0413eeee775a433630c`.
- Commit sửa test k=0:
  `498a6eb0f30a2659ee52dfd8e9fdc9d071850d44`.
- Elixir 1.18.5 / Erlang OTP 27: biên dịch 43 tệp .ex.
- **336 kiểm thử, đúng 4 thất bại cố ý, 332 bài đạt.**
- Bốn sai lệch đều từ Stage26: x=M bước tiến,
  x=M-1 bước tiến, x=M bước lùi và biên n=M-3.
- Toàn bộ 317 bài Stage1..25 đạt; 15 bài kiểm soát
  Stage26 đạt, không cảnh báo biên dịch.
- Canonical Names Lock độc lập PASS.
- CI đầu 336/5 do sai lầm test k=0 cần chấp nhận;
  sửa duy nhất danh sách `bad`, không thay code hoặc
  các giá trị so sánh normative.
- Oracle test-only giữ nguyên blob SHA
  `be1638f46b2190d617af0378a61b077bda10bf32`.
- LegacyBiasedPick vẫn được gọi ngay từ x đầu.
  Không có ShortRejectionPatch và chưa mở wideDetour.
- Không sửa main; không có gói HANDOFF_* trong commit.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38274786459
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38274786326

Trạng thái cuối: EXPECTED_RED đã xác minh.
Điểm tiếp theo: Stage27 PATCH 13, chưa bắt đầu.
