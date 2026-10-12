# Thay đổi giai đoạn 16 — Phát hiện 08

## Nền đã kiểm chứng

Giai đoạn 15 đã khép tại `67cb124288c056a6e58119a7c81998c0146ab57e`.
CI Elixir: 163 kiểm thử, không lỗi; khóa tên chuẩn PASS.
Lần này chỉ khám phá lỗi thứ tám, không thực hiện PATCH 08.

## Hạng gốc không và lỗi được đưa vào sản xuất

`LegacyPermutationUnrank0.old_permutation_unrank0(rank0)`
giữ thuật toán giai thừa trên [1,2,3,4,5,6] theo index 0.
Cho phép quay vòng theo 720 để tránh đọc ngoài miền khi hạng 720
được chuyển nhầm vào. Việc quay vòng không sửa lỗi khác biệt hạng.

`BowlOrderManager.order_from_drop(drop)` dùng:

```text
one_based = rem(drop - 1, 720) + 1
order = old_permutation_unrank0(one_based)  # cố ý sai
```

Đúng ra trong PATCH 08 phải tính `legacy_rank0=one_based-1`
rồi gọi bộ mở hạng cũ. **Chưa có nhánh chuyển này.**

Với drop=1, kết quả sai là [1,2,3,4,6,5].
Với drop=720, kết quả sai là [1,2,3,4,5,6].
Ở cả hai ví dụ thứ tự đúng lần lượt là [1,2,3,4,5,6]
và [6,5,4,3,2,1].

## Đường sản xuất

`Dispatcher.bootstrap` tạo 46 giọt đúng từ các bản vá trước,
gọi `BowlOrderManager.build_orders(visible_drops)`,
và giữ map 46 thứ tự trong `Context.bowl_orders`.
API công khai `bowl_orders_spaghetti` và `bowl_order_spaghetti`
đọc đúng map sản xuất, không gọi oracle.

Không rót bát, không làm thay đổi kết quả giọt đã qua PATCH 07.
Không dùng tài nguyên trạng thái toàn cục. Chưa triển khai bước
bát thuộc những giai đoạn sau.

## Kiểm thử

16 bài mới ở `test/stage_16_discovery_08_test.exs`:
12 bài kiểm soát của thuật toán gốc không, 720 hoán vị,
hai đầu hạng, kho 46 thứ tự, tính đồng thời, số nguyên lớn,
lỗi đầu vào, sở hữu context và bảo vệ mã nguồn.
4 hồi quy so chuẩn phải cố ý đỏ: hạng 1, hạng 720,
thứ tự giọt đầu và cuối.

Dự kiến 179 kiểm thử, đúng 4 hồi quy chuẩn đỏ,
mọi kiểm thử 1-15 vẫn xanh. Không chỉnh oracle
`test/support/normative_reference.ex`.
Cần phân loại kết quả CI trước khi khép giai đoạn.

## Bản vá tiếp theo

Giai đoạn 17 PATCH 08 phải giữ
`old_permutation_unrank0(rank0)` và thêm đúng chuỗi:

```text
oneBased=regularMod(drop-1,720)+1
legacyRank0=oneBased-1
order=oldPermutationUnrank0(legacyRank0)
```

Không khởi động bản vá trong giai đoạn 16.
