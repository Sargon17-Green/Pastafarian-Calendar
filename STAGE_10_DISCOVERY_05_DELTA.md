# Thay đổi riêng giai đoạn 10 — Phát hiện 05

## Điểm bắt đầu và giới hạn

Commit khép giai đoạn 9:
`7db40392e68c589aa5464f0ef4d64bae69e5d5f9`.
Đã xác minh 88 kiểm thử, 0 lỗi, khóa tên chuẩn đạt.
Chỉ thêm lỗi lưu bảy giọt ẩn đảo ngược; không thêm PATCH 05
hoặc cơ chế lấy giọt ẩn cho chuỗi giọt nhìn thấy của giai đoạn sau.

## Số học đúng, lưu trữ sai

Tính riêng bảy giá trị `hidden1` đến `hidden7` dùng:

- `action`, `target`, `distance`, `connection`, `direction`.
- Bảng đá 46 hàng từ `StoneManager.build_table` đã qua PATCH 04.
- Hệ số `{a,b,c,d}` của từng giọt và tổng năm viên đá của hàng `k`.
- `SAVE` với M = 2^127 - 1 qua bản vá 01.
- Bảy phép nghiền theo loại đá `[1,2,3,4,5,1,2]`.

Công thức:

```text
x0 = SAVE(action + a*target + b*distance +
          c*connection + d*direction + sum(stones[k,1..5]))
x_next = SAVE(x*x + 3*x + stones[k,stoneKind] + grindIndex)
```

Tất cả bảy giá trị được tính đúng; sai lệch chỉ ở lớp lưu trữ.

## Di sản cần phơi bày

`LegacyHiddenStorage.store_reversed` lưu tuple theo thứ tự:

```text
[hidden7, hidden6, hidden5, hidden4, hidden3, hidden2, hidden1]
```

Hàm đọc cũ `read_as_if_forward(storage,k)` vẫn dùng `elem(storage,k-1)`.
Bởi vậy `hidden1` được hiểu là giá trị thật của `hidden7`,
`hidden2` là `hidden6` và tương tự. Ô giọt 4 trùng chuẩn.
Không có đường sửa `8-k` trong mã sản xuất giai đoạn 10.

## Đường sản xuất

`hidden_drop_spaghetti → Dispatcher.hidden_drop →
HiddenDropManager.read → LegacyHiddenStorage.read_as_if_forward`.

`bootstrap_context` xây tuple bằng
`HiddenDropCalculator.calculate → LegacyHiddenStorage.store_reversed`,
và giữ nó trong `Context.hidden_drops_storage` riêng cho từng lần gọi.

## Kiểm thử

13 bài kiểm thử mới: 9 bài kiểm soát đạt và 4 hồi quy chuẩn
cố ý đỏ ở giọt 1, 2, 3, 7. Dự kiến 101 kiểm thử, đúng 4 thất bại.
Mọi kiểm thử giai đoạn 1-9 phải tiếp tục đạt.
Chứng minh riêng số học theo bộ chuẩn, giữ nguyên lỗi đọc sai.
Không chỉnh kỳ vọng oracle, không bắt đầu PATCH 05.

## Tiêu đề commit

Giai đoạn 10: phát hiện lưu bảy giọt ẩn theo thứ tự đảo

## Nội dung commit

Tính bảy giọt ẩn trong đường Elixir thực, lưu đảo từ hidden7
đến hidden1 và đọc sai theo chỉ số cũ. Bổ sung bốn hồi quy
chuẩn cố ý đỏ, không thực hiện ánh xạ vá 8-k trước giai đoạn 11.
