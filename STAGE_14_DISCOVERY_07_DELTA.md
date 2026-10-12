# Thay đổi giai đoạn 14 — Phát hiện 07

## Nền đã xác minh

Commit khép giai đoạn 13:
`9724e4e95e9a9af2ba2381cc77009159ddbf017a`.
137 kiểm thử, 0 lỗi, khóa tên chuẩn PASS.
Giai đoạn 14 thuộc DISCOVERY 07, không phải PATCH 07.

## Lỗi chỉ số cần để lộ

Bảng nguyên gốc gồm đúng 11 hàng nghiền bắt đầu tại index 0.
Mã lịch sử đọc `legacy_row(number)` với number = 1..11,
tức tra phần tử tại chỉ số `number` thay vì `number-1`.

```text
hàng thực 0..10 = grind1..grind11
legacy_row(1) = grind2
...
legacy_row(10) = grind11
legacy_row(11) = {0,0,0,0,1} (ô dự phòng)
```

Số vòng lặp luôn là 11; lần cuối chạy bằng giá trị dự phòng
thay vì sập hoặc bỏ vòng. Không sửa phép đọc legacy,
không đổi các công thức SAVE hay nguồn dữ liệu chuẩn.

## Mã sản xuất

`LegacyGrindTable` chứa 11 hàng chính xác và
`legacy_row(number)` cố ý dùng
`Enum.at(@real_rows,number,@missing_row)`.
`VisibleDropCalculator` gọi hàm này thật ở cả 11 bước
cho từng giọt nhìn thấy trong 46 giọt, sau khi đã gọi
`PriorPatch` để lấy đúng ba giọt trước.

Các lớp cũ từ SAVE, đá, hidden, legacy history tới PATCH 06
được giữ nguyên. Không gọi oracle test-only trong mã sản xuất.

## Kiểm thử và kiểm soát

- Bổ sung 14 kiểm thử giai đoạn 14. Bốn hồi quy chuẩn mới
  cố ý đỏ: hàng nghiền đầu, hàng nghiền cuối, giọt nhìn thấy
  đầu và giọt nhìn thấy thứ 46.
- Những kiểm thử đối chiếu chuẩn đã có từ giai đoạn 12–13
  không được chỉnh cho qua: các phép so sánh giá trị giọt
  nhìn thấy sẽ đỏ thêm do đúng lỗi mới, được ghi rõ từng ca.
- Các phép thử cấu trúc và đường đọc dữ liệu cũ phải tiếp tục
  đạt. Kiểm chứng trật tự sai bằng dãy hàng và bảng nguyên bản.
- Dự kiến tổng 151 kiểm thử; số lượng thất bại kiểm theo CI
  và không được coi mọi lỗi là có chủ đích nếu chưa phân loại.

## Điều kiện để vá ở giai đoạn 15

Thêm sentinel thật tại index 0, chuyển 11 hàng nghiền đúng sang
index 1..11, **không đổi legacy_row(number)** và không xóa
sentinel. Những kiểm thử oracle đã có phải trở lại xanh.
Không đưa bản vá vào lần phát hiện hiện tại.

## Kiểm chứng thực tế và phân loại sai lệch

- Commit triển khai: `fb3a163dba277511c87cb52dcea34b067be2dee4`.
- Elixir 1.18.5 / Erlang/OTP 27.
- **151 kiểm thử; đúng 16 thất bại vì lỗi nghiền**, 135 bài đạt.
- 4 hồi quy chuẩn mới giai đoạn 14 đỏ: hàng đầu, hàng cuối,
  giọt nhìn thấy đầu tiên và giọt nhìn thấy 46.
- 5 bài chuẩn giai đoạn 12 đỏ: bốn hồi quy chuẩn và phép
  kiểm công thức đầu ra chuẩn ở bài kiểm thử kết hợp.
- 7 bài chuẩn giai đoạn 13 đỏ: đối chiếu toàn bộ giọt,
  ngữ cảnh, giọt đầu, số nguyên cực lớn, đồng thời,
  vùng tiếp giáp và bất biến kho lịch sử.
- 10 bài kiểm soát Stage14 đều đạt: chứng minh lỗi index,
  thực hiện đủ 11 vòng, ô dự phòng, đường sản xuất, tài nguyên
  riêng, số nguyên lớn, lỗi đầu vào và không có bản vá 07.
- Không cảnh báo biên dịch, khóa tên chuẩn PASS độc lập.
- Không sửa các kỳ vọng chuẩn cũ hoặc oracle.
- `LegacyGrindTable` còn thiếu sentinel ở index 0 có chủ đích.
- Không thay main, chưa bắt đầu giai đoạn 15.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38213818081
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38213818145

Trạng thái cuối giai đoạn 14: EXPECTED_RED đã được xác minh.
Bước tiếp theo: giai đoạn 15 PATCH 07, chưa bắt đầu.
