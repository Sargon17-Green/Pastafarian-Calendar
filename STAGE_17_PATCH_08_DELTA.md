# Thay đổi giai đoạn 17 — Bản vá 08

## Nền và ranh giới

Giai đoạn 16 đóng tại commit
`49d62f82137aacbcee1554148fbdd6cc5b41c2a2`.
Elixir đã xác minh 179 kiểm thử, đúng bốn hồi quy chuẩn
cố ý đỏ ở hạng 1, hạng 720 và thứ tự giọt 1/46.
Khóa tên chuẩn PASS, không cảnh báo biên dịch.

Giai đoạn 17 chỉ sửa đường chuyển hạng hoán vị.
Không thực hiện DISCOVERY 09 về phép rót bát.

## Di sản giữ nguyên

Không thay đổi `LegacyPermutationUnrank0.old_permutation_unrank0(rank0)`.
Hàm này nhận số nguyên không âm theo zero-based, chọn sáu
ID bát bằng triển khai giai thừa và quay vòng theo 720.
Khi gọi thô với hạng one-based, vẫn cho hoán vị sai như
ở giai đoạn 16. Không xóa lời gọi legacy, không dùng
oracle trong production.

## Bản vá

Tại `BowlOrderManager.order_from_drop(drop)`:

```text
one_based = rem(drop-1,720)+1
legacy_rank0 = one_based-1
order = LegacyPermutationUnrank0.old_permutation_unrank0(legacy_rank0)
```

Với drop dương, rem(drop-1,720) không âm, do đó
legacy_rank0 luôn trong 0..719. Với drop=720k,
legacy_rank0=719 và thứ tự đúng là [6,5,4,3,2,1].
Đối với drop=720k+1, rank0=0, thứ tự đúng là
[1,2,3,4,5,6]. Các biên 719, 720, 721 đều được
thử trực tiếp.

`Dispatcher.bootstrap` vẫn cất 46 hoán vị riêng
trong `Context.bowl_orders`, tạo chúng từ giọt
hiển thị đã qua các bản vá 01–07. Không thay dòng
dữ liệu, quyền sở hữu hoặc API công khai.

## Kiểm thử

Bốn hồi quy chuẩn của giai đoạn 16 giữ nguyên từng
khẳng định và phải chuyển từ đỏ sang xanh.
Các bài kiểm soát ở giai đoạn 16 cập nhật để xác nhận
lời gọi legacy thô vẫn lệch một vị trí trong khi
đường production đã đúng.

14 bài kiểm thử mới tại
`test/stage_17_patch_08_test.exs` kiểm tra toàn bộ
720 hoán vị, chu kỳ và mốc biên, sai lệch legacy thô,
46 giọt, số nguyên tới 2048 bit, tính đồng thời,
quyền sở hữu, đầu vào sai và ranh giới giai đoạn sau.
Tổng dự kiến 193 kiểm thử, 0 lỗi, khóa tên PASS.
Không sửa `test/support/normative_reference.ex`.

## Tên commit

Giai đoạn 17: vá hạng hoán vị trước khi gọi legacy

## Kết quả CI đã xác minh

- Commit triển khai: `d2c783c8e7d9819cdb9e9e433776e9a74b8331db`.
- Elixir 1.18.5, Erlang/OTP 27; 30 tệp nguồn biên dịch.
- 193 kiểm thử, 0 lỗi, 0 cảnh báo biên dịch.
- Bốn hồi quy chuẩn Stage16 giữ nguyên và chuyển sang xanh.
- 14 kiểm thử Stage17 mới đều đạt; 720 hoán vị chuẩn đầy đủ.
- Khóa tên chuẩn độc lập PASS.
- LegacyPermutationUnrank0 không đổi, blob SHA
  `d553b2a637e54ca74eb7d6e90b8aab437ed7fc13`.
- Oracle test-only không đổi, blob SHA
  `be1638f46b2190d617af0378a61b077bda10bf32`.
- Giữ 46 thứ tự riêng trong context, chưa rót vào sáu bát.
- Không thay main và chưa bắt đầu giai đoạn 18.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235528620
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235528637

Kết thúc giai đoạn 17: GREEN đã xác minh.
Điểm tiếp theo: giai đoạn 18 DISCOVERY 09 chưa bắt đầu.
