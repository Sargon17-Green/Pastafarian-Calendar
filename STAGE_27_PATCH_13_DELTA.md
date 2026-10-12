# Giai đoạn 27 — Bản vá 13: lọc answer ring trước khi gọi legacy

## Mốc xuất phát

Giai đoạn 26 đóng tại
`74583376c451b380a35ac16d279c98dc5caa8dab`.
CI Elixir 1.18.5 / OTP 27: 336 test, đúng bốn
sai lệch chuẩn cố ý, 332 test đạt, 0 cảnh báo.
Canonical Names Lock PASS.

Bốn trường hợp bắt buộc trở lại xanh:

- first=M, step=+1, n=floor(M/2)+1;
- first=M-1, step=+1, cùng n;
- first=M, step=-1, n=M-3;
- first=M, step=+1, n=M-3.

## Di sản được giữ nguyên

`LegacyBiasedPick.biased_legacy_pick(x,n)` tiếp tục
trả `rem(x-1,n)+1` mà không kiểm tra rejection.
Không sửa module đó, oracle test-only, seed/hướng
của `AnswerStreamManager`, 58 lần ghi order legacy
hay các PATCH 01..12.

## Lớp vá mới

`ShortRejectionPatch` giữ vòng AnswerStreamManager
đã khởi tạo; không xây stream mới hay lấy seed từ dữ
liệu ngoài. Nó thực hiện:

```text
limit = div(M,n)*n
k = 0
loop:
    x = AnswerStreamManager.answer_at(stream,k)
    if x > limit:
        k = k+1
        continue
    rank = LegacyBiasedPick.biased_legacy_pick(x,n)
    return rank
```

Hàm `diagnose/2` cung cấp dữ liệu kiểm toán của cùng
đường chạy gồm `accepted_index`, `accepted_value`,
`rejected_count`, `rejection_limit` và `rank`.
Hàm `choose_rank_short/2` chỉ lấy hạng đã nhận
từ `diagnose/2`. Bộ quản lý giữ tên cũ
`choose_rank_short_biased/2` để tương thích với API,
nhưng định tuyến vào lớp vá. Không có hàm
`wideDetour` hay chọn hạng n>M tại giai đoạn này.

Điều kiện quan trọng: **LegacyBiasedPick chỉ gọi
trên nhánh `x<=limit`**. Mọi lần bác bỏ chỉ cập
nhật chỉ số k và đọc lại chính vòng cũ, tuyệt đối
không sinh một chuỗi khác.

## Kiểm thử bổ sung

Giữ nguyên bốn assert normative Stage26.
Hai kiểm thử điều khiển của Stage26 được cập nhật:
một kiểm tra legacy trực tiếp vẫn thiên lệch nhưng
route production trả chuẩn; một kiểm toán source
xác nhận thứ tự rejection → call legacy.

`test/stage_27_patch_13_test.exs` thêm 18 bài:
mẫu M, M-1 theo hai chiều; n=3, n=M-1,
n=M-2, n=M-3 và n=M; kiểm limit; đọc lại
legacy với giá trị đã chấp nhận; trace của các
trường hợp k=0,1,2,3; so sánh oracle nhiều miền
n, ngày thực, bộ đếm 2048-bit, nhiều task song
song, biên lỗi và giữ source legacy. Không thêm
hệ thống cổng hoặc tính lịch hoàn chỉnh.

Tổng dự kiến: 354 bài test GREEN và 0 warning.
Không đổi branch main, không commit HANDOFF_*.

## Điều kiện đóng

Chỉ đóng `LAST_COMPLETED_STAGE=27` sau khi
GitHub Actions CI chạy được 354/354 và Canonical
Names Lock PASS trên commit triển khai; sau đó
chạy lại cả hai trên commit đóng.

## Kết quả CI và bằng chứng đóng

- Commit triển khai:
  `c5e1862eb710a8c8d0bee23b9376a108587031dc`.
- Elixir 1.18.5 / OTP 27, biên dịch 44 tệp .ex.
- **354 bài kiểm thử, 0 lỗi, 0 cảnh báo biên dịch.**
- Bốn hồi quy chuẩn Stage26 đạt mà không sửa expected.
- 18 bài Stage27 mới PASS, gồm hướng tiến/lùi,
  n=M, n=1, M-1, M-2, M-3, vùng thừa n=3,
  dữ liệu 2048-bit, gọi lặp và đồng thời.
- Canonical Names Lock PASS độc lập.
- LegacyBiasedPick SHA không đổi:
  `94816d3aac30296eeded3abdd0bfaea5f46614ae`.
- Oracle test-only SHA không đổi:
  `be1638f46b2190d617af0378a61b077bda10bf32`.
- Bộ tìm ID legacy và bộ nhớ legacy Stage24/22 không đổi.
- `LAST_COMPLETED_STAGE=27`, `EXPECTED_REPOSITORY_STATE=GREEN`.
- Không chỉnh main, không triển khai wideDetour Stage28.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38280022089
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38280022253

Giai đoạn 27 đóng GREEN đã xác minh.
Giai đoạn tiếp: 28/55 DISCOVERY 14, chưa bắt đầu.
