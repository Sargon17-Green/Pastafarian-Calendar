# Giai đoạn 28 — Phát hiện 14: chọn hạng rộng chỉ dùng một chữ số

## Mốc đã xác minh

Giai đoạn 27 khép tại
`0f07913a4da3208a7cd70d3311cd20245b2ba73d`.
CI Elixir 1.18.5 / OTP 27: 354 kiểm thử, 0 lỗi,
0 cảnh báo; Canonical Names Lock PASS.

## Lỗi lịch sử thực tế

`AnswerStreamManager.choose_rank` đã được mở như
API chọn hạng tổng quát, nhưng nhánh n>M gọi trực tiếp
`LegacySingleDigitWidePick.choose_rank`, chỉ đọc
`AnswerStreamManager.answer_at(stream,0)` và gọi
`LegacyBiasedPick.biased_legacy_pick(x,n)`.
Với M=(2^127)-1, x luôn thuộc 1..M và n>M;
phép dư lịch sử trả chính x, chỉ phủ được hạng 1..M
trong khi miền chọn là 1..n. Chọn ngắn n<=M vẫn
dùng ShortRejectionPatch chuẩn của Stage27.

Đây không phải lỗi hạt/hướng, cũng không phải
lỗi từ chối của miền ngắn. LegacyWide cần giữ nguyên
trong Stage29 như bằng chứng của lỗi thiếu chữ số.

## Thuật toán chuẩn chưa được triển khai

Với n>M, cần tìm số nguyên k nhỏ nhất sao cho
`space=M^k>=n`. Các phần tử liên tiếp
`answer_at(stream,j)` tạo chữ số
`digit_j=answer_at(stream,j)-1` trong miền 0..M-1.
Số wide một-based là:

```text
wide0 = 1 + Σ[j=0..k-1] digit_j*M^j
```

Chữ số đầu có trọng số thấp nhất. Giới hạn nhận
`limit=div(space,n)*n`. Khi wide0>limit, chuẩn
tiến +/-1 trên **vòng wide** từ wide0, không tạo
seed mới và không bắt đầu lại từ answer ring.
Stage28 cố ý chưa chứa giải pháp wideDetour này.

## Bằng chứng trong 20 kiểm thử mới

`test/stage_28_discovery_14_test.exs` thêm 16 bài
kiểm soát và bốn hồi quy chuẩn cố ý đỏ.
Các kiểm soát xác nhận: legacy đọc đúng một phần tử,
không trả hạng lớn hơn M, nhánh short vẫn đúng,
answer ring không đổi cả hai chiều, API thực dùng
nhánh wide sai, ngày số nguyên 2048-bit, chạy song
song, phân ranh giới N=M, N>M và mã nguồn không
có `wide_detour_patch.ex`.

Bốn hồi quy chuẩn đỏ dùng
`first=1,direction_step=+1`, chọn các miền:
- N=M+1: cần k=2, expected=M+1, legacy=1.
- N=M²: cần k=2, expected=M+1, legacy=1.
- N=M²+1: cần k=3, expected=M-1, legacy=1.
- N=M³+1: cần k=4, expected=2M²+M-2, legacy=1.

Các expected lấy từ oracle độc lập
`NormativeReference.choose_rank`; không hardcode
trong test normative. Các kiểm thử Stage1..27
được giữ, không đổi công thức SAVE, 46 giọt,
12 lượt khuấy, chốt giọt 46, bát hoặc query ID.

Dự kiến tổng 374 kiểm thử với bốn sai lệch cố ý.
Sẽ phân loại log CI thực tế trước khi đóng Stage28.

## Điểm sửa ở giai đoạn 29

Giữ `LegacySingleDigitWidePick` nguyên vẹn.
Thêm `WideDetourPatch` dùng cùng k chữ số và
cùng vòng wide, chỉ chọn rank sau rejection,
sau đó trả kết quả đúng cho mọi n>M. Không
làm trước PATCH 14, không tích hợp lịch.

Không thay branch main, không commit HANDOFF_*,
không nhập module oracle vào mã production.

## Kết quả GitHub Actions đã xác minh

- Commit triển khai:
  `4da3dafeef74f57c97a4a308095942fa312b3137`.
- CI Elixir 1.18.5 / OTP 27: biên dịch 45 tệp .ex.
- **374 kiểm thử, đúng bốn thất bại cố ý, 370 đạt.**
- Bốn hồi quy normative Stage28 đỏ: n=M+1, M²,
  M²+1 và M³+1; tất cả do legacy một chữ số.
- 354 bài cũ và 16 điều khiển Stage28 đều đạt,
  0 cảnh báo biên dịch.
- Canonical Names Lock PASS độc lập.
- LegacyBiasedPick không đổi blob SHA:
  `94816d3aac30296eeded3abdd0bfaea5f46614ae`.
- Oracle test-only không đổi blob SHA:
  `be1638f46b2190d617af0378a61b077bda10bf32`.
- Không sửa main, không làm WideDetourPatch Stage29.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38283015914
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38283016003

Trạng thái kết thúc: EXPECTED_RED đã xác minh.
Điểm tiếp theo: Stage29 PATCH 14.
