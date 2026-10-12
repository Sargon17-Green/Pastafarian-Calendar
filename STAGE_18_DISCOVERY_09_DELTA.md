# Thay đổi giai đoạn 18 — Phát hiện 09

## Cơ sở đã xác minh

Commit đóng giai đoạn 17:
`bbe96e03f70d39b714876dc06e48dc16d91e254c`.
CI Elixir 1.18.5, OTP 27: 193 kiểm thử, 0 lỗi,
khóa tên chuẩn PASS. Giai đoạn 18 là DISCOVERY 09;
không triển khai PATCH 09 của giai đoạn 19.

## Mã sản xuất mới

- `BowlSeedCalculator`: tính độc lập sáu ID bát
  từ day tags, distance, direction, prime 17..37 và SAVE.
- `LegacyPourPositions.read_old`: đọc thẳng
  `Map.fetch!(bowls_old,position)`, position=1..3,
  không nhận hoán vị và không tìm ID bát thật.
- `LegacyPourPositions.pour`: SAVE của
  `drop² + stone(position)*old[position] + (2*position+1)*i`.
- `BowlDropCalculator`: 46 vòng lặp, mỗi vòng có đúng
  ba lần rót vào vị trí 1..3 và sáu lần khuấy.
  Các phép khuấy đọc cùng snapshot old, ghi map next mới,
  lấy ID bát tại `order[position]`, ID trước/sau theo
  vòng hoán vị, dùng stone kind [1,2,3,4,5,1].
  Chỉ ba phép đọc nguồn rót là lịch sử sai.
- `Dispatcher.bootstrap` ghi `initial_bowls` và
  `bowls_after_drops` vào context riêng.
  API công khai phục vụ đọc hai kho này.

## Lỗi chính xác và bằng chứng so sánh

Khi order=[4,5,6,1,2,3] và sáu giá trị cũ khác nhau,
nguồn rót đúng cho position 1 phải là `old[4]`,
nhưng legacy đọc `old[1]`. Tương tự cho position
2 và 3. Tất cả giá trị vẫn ở miền SAVE, nhưng số bát
sau một lần khuấy và sau 46 giọt lệch oracle.

Từng công thức cập nhật sáu bát ngoài ba nguồn rót
được giữ đúng. Không sửa hoán vị, không thêm lỗi
in-place của DISCOVERY 10, không khuấy thêm 12 lượt,
không thực hiện truy vấn lịch cuối.

## Kiểm thử

16 kiểm thử mới, 12 điều khiển và bốn hồi quy chuẩn
cố ý đỏ ở rót thứ nhất, cập nhật bước đầu, sáu bát
sau 46 giọt cùng ngày và nhiều ngày hai hướng.
Tổng dự kiến: 209 kiểm thử, đúng bốn thất bại
sau khi xác minh CI. 193 kiểm thử cũ phải xanh;
không sửa `test/support/normative_reference.ex`.

## Giai đoạn kế tiếp

PATCH 09 giữ `LegacyPourPositions`,
định tuyến `bowlAlias[position]=order[position]`,
và tất cả ba nguồn rót dùng ID đã ánh xạ.
Giữ các phép khuấy đúng, không bắt đầu DISCOVERY 10.

## Kết quả kiểm chứng thực tế

- Commit triển khai: `a14de0de404801cca954db020a3e45f69ff8181f`.
- Elixir 1.18.5 / Erlang/OTP 27, 33 tệp nguồn được biên dịch.
- 209 kiểm thử, chính xác 4 thất bại dự kiến, 205 bài đạt.
- 4 hồi quy chuẩn đỏ: nguồn rót đầu, khuấy đầu,
  bát sau 46 giọt, hai chiều ngày.
- 193 bài kiểm thử giai đoạn 1-17 vẫn PASS.
- 12 bài kiểm soát mới đều PASS, không cảnh báo biên dịch.
- Khóa tên chuẩn độc lập PASS.
- Oracle test-only không thay đổi; không thêm PATCH 09;
  không sử dụng biến trạng thái dùng chung, không đổi main.

CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239350202
Khóa tên: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239350320

Trạng thái cuối: EXPECTED_RED đã kiểm chứng.
Điểm tiếp theo: giai đoạn 19 PATCH 09, chưa bắt đầu.
