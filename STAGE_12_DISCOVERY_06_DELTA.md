# Thay đổi giai đoạn 12 — Phát hiện 06

## Điểm bắt đầu và giới hạn

Commit cuối giai đoạn 11:
`3813372f1fbf8b6c0422b7a79c6348c3e0569659`.
CI Elixir: 111 kiểm thử đạt, 0 lỗi, khóa tên chuẩn PASS.
Không thay đổi main, không thêm PATCH 06 của giai đoạn 13.

## Công thức giọt nhìn thấy

Tạo 46 giọt theo thứ tự với bảng đá 46 hàng và năm bộ đếm.
Mỗi giọt `i` cần ba giọt trước `i-1`, `i-3`, `i-7`.
Giá trị khởi đầu:

```text
x0 = SAVE(stone(i,1)*action + stone(i,2)*target +
          stone(i,3)*distance + stone(i,4)*connection +
          stone(i,5)*direction + prev1 + 3*prev3 + 5*prev7 + i)
```

Sau đó thực hiện lần lượt 11 hàng nghiền `(a,b,c,d,kind)`:

```text
x' = SAVE(x*x + a*x + b*prev1 + c*prev3 + d*prev7
          + stone(i,kind))
```

Nguồn công thức chuẩn thuộc bộ tham chiếu test-only.
Mã sản xuất viết độc lập bằng Elixir, dùng `SaveManager`
và `StoneManager` đã vá; không nhập bộ tham chiếu.

## Sai lệch lịch sử dự kiến

`LegacyPrior.legacy_prior(visible_store,i,back)` chỉ đọc
`visible_store[i-back]`. Do kho chỉ chứa ô từ 1 đến 46,
các ô 0 đến -6 bị coi là vắng và trả về 0, dù theo chuẩn:

```text
slot = i-back
nếu slot >= 1: dùng giọt nhìn thấy số slot
nếu slot <= 0: dùng giọt ẩn số 1-slot
```

Quy tắc thứ hai chỉ mô tả oracle và hướng vá tiếp theo,
**không được triển khai ở giai đoạn 12**.
Khi `i >= 8`, ba địa chỉ trước đều dương; hàm cũ
tra đúng kho nhìn thấy, nhưng các giọt trước đã bị nhiễm lỗi.

## Dây nối sản xuất

- `Dispatcher.bootstrap` tạo cả `hidden_drops_storage`
  và `visible_drops` độc lập trong mỗi context.
- `VisibleDropManager.build` tạo 46 giọt qua
  `VisibleDropCalculator.calculate`.
- Bộ tính thực sự gọi `LegacyPrior.legacy_prior`
  ba lần cho mỗi giọt với độ lùi 1, 3, 7.
- `visible_drops_spaghetti` và `visible_drop_spaghetti`
  đi qua dispatcher và manager, không gọi oracle.
- Bảy giọt ẩn vẫn được tính/lưu/đọc đúng qua PATCH 05.
- Chưa làm phép hoán vị, bát, hoặc đầu ra ngày lịch cuối.

## Kiểm thử

15 kiểm thử mới, trong đó 4 hồi quy chuẩn cố ý đỏ:
giọt nhìn thấy 1, 2, 7, 46. Mười một bài kiểm soát
kiểm tra đường cũ, ô âm, ô dương, công thức nghiền,
46 giá trị trong miền SAVE, sai chỉ số, số nguyên lớn,
quyền sở hữu và chạy song song, cùng các bản vá 01–05.

Tổng dự kiến: 126 kiểm thử, đúng 4 thất bại có chủ đích.
Không thay đổi bài kiểm thử các giai đoạn trước.

## Thay đổi mã

`lib/pastafari_calendar_elixir_vietnamese/monster/legacy_prior.ex`
`lib/pastafari_calendar_elixir_vietnamese/monster/visible_drop_calculator.ex`
`lib/pastafari_calendar_elixir_vietnamese/monster/visible_drop_manager.ex`
`lib/pastafari_calendar_elixir_vietnamese/monster/context.ex`
`lib/pastafari_calendar_elixir_vietnamese/monster/dispatcher.ex`
`lib/pastafari_calendar_elixir_vietnamese.ex`
`test/stage_12_discovery_06_test.exs`
và tài liệu trạng thái lịch sử.

## Giai đoạn kế tiếp

PATCH 06 phải giữ `LegacyPrior.legacy_prior`, chỉ dùng
nó cho `slot >= 1`; với `slot <= 0` dùng giọt ẩn
`hidden_number=1-slot` qua `HiddenDropManager.read`.
Không mở sớm bản vá này.
