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
