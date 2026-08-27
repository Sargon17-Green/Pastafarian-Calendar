# Bàn giao giai đoạn 1 — Elixir / tiếng Việt

## Phạm vi

Đây là toàn bộ cây của một kho mới, được dựng từ số không cho giai đoạn 1. Không có kho nền, không có tệp cần chồng lên và không có tệp hiện hữu cần giữ lại. Khi giải nén gói vào một thư mục trống, thư mục đó chính là gốc kho của dòng Elixir + tiếng Việt.

Nội dung được dựng độc lập từ phụ lục A của đặc tả đã cung cấp, không đọc hay dùng mã, kiểm thử, dữ liệu kiểm thử, kết quả, giá trị băm, nhật ký hoặc bảng sinh ra của bất kỳ cách triển khai ngôn ngữ nào khác.

## Tệp được tạo

- `mix.exs`
- `README.md`
- `SOURCE_LANGUAGE_CATALOG.md`
- `ARCHITECTURE_STAGE_01.md`
- `SPAGHETTI_DEVELOPMENT_HISTORY.md`
- `DEVELOPMENT_STAGE.md`
- `HANDOFF_STAGE_01.md`
- `lib/pastafari_calendar_elixir_vietnamese.ex`
- `lib/pastafari_calendar_elixir_vietnamese/source_language_catalog.ex`
- `lib/pastafari_calendar_elixir_vietnamese/monster/context.ex`
- `lib/pastafari_calendar_elixir_vietnamese/monster/dispatcher.ex`
- `lib/pastafari_calendar_elixir_vietnamese/monster/error.ex`
- `lib/pastafari_calendar_elixir_vietnamese/monster/metrics.ex`
- `lib/pastafari_calendar_elixir_vietnamese/monster/validator.ex`
- `test/test_helper.exs`
- `test/stage_01_test.exs`
- `test/fixtures/stage_01_fixtures.exs`
- `test/support/normative_reference.ex`
- `.github/workflows/elixir-vietnamese-stage.yml`

## Nội dung đã dựng

`SourceLanguageCatalog` có phiên bản cố định, 17 tên miếng và 47 tên tháng bằng tiếng Việt, với thứ tự chỉ dựa trên `canonicalIndex`.

Bộ tham chiếu sạch chỉ dành cho kiểm thử triển khai số nguyên chính xác, `SAVE`, đếm ngày, đá, giọt ẩn và giọt hiện, thứ tự bát, rót, 12 lần khuấy sau, dòng trả lời, chọn hạng ngắn và rộng, hợp thành bị chặn, mở hạng tên khác nhau, phân hoạch miếng có điều kiện, đan tháng, cổng, năm, cấu trúc năm và hàm năm trường cuối.

Mã sản xuất chỉ có hạ tầng quái vật trung tính được phép ở giai đoạn 1 và cố ý ném lỗi rõ ràng thay vì trả kết quả lịch chưa được tích hợp.

## Kiểm thử

Lệnh bắt buộc tại gốc kho:

```text
mix test
```

Kết quả mong đợi: toàn bộ bộ kiểm thử thành công.

Kết quả thực tế trong môi trường tạo gói: **chưa chạy được**. Môi trường không cài `elixir`, `elixirc` hoặc `mix`. Không dùng môi trường chạy của ngôn ngữ khác để thay thế.

Vì vậy giai đoạn 1 chưa được phép đánh dấu hoàn tất hoặc `GREEN` cho đến khi lệnh Elixir ở trên chạy thành công.

## Tiêu đề commit đề xuất

`Khởi tạo kho Elixir quái vật spaghetti bằng tiếng Việt từ số không`

## Nội dung commit đề xuất

`Dựng toàn bộ gốc kho mới cho giai đoạn 1 của cách triển khai Elixir, với tiếng Việt là ngôn ngữ nguồn duy nhất. Đóng băng SourceLanguageCatalog theo canonicalIndex cho 17 tên miếng và 47 tên tháng, thêm bộ tham chiếu chuẩn sạch chỉ dành cho kiểm thử và các dữ liệu kiểm thử được suy ra lại từ phụ lục A. Mã sản xuất chỉ thêm ngữ cảnh riêng cho mỗi lần gọi, bộ phân phối cơ sở, kiểm tra, biên lỗi và số liệu phi ngữ nghĩa; chưa có bất kỳ khuyết tật hay bản vá lịch sử nào và không gọi bộ tham chiếu.`

`Kiểm thử bắt buộc: mix test tại gốc kho. Môi trường tạo gói hiện tại không có môi trường chạy Elixir nên chưa thể xác nhận kết quả thực tế; không được bắt đầu giai đoạn 2 cho đến khi bộ kiểm thử này xanh.`

## Ghi chú GitHub đề xuất

`Giai đoạn 1/55 cho kho mới Elixir + tiếng Việt, được dựng từ số không. Danh mục nguồn đã được đóng băng theo canonicalIndex; bộ tham chiếu đầy đủ nằm trong cây kiểm thử; mã sản xuất chỉ có hạ tầng trung tính và không gọi bộ tham chiếu. Không có mã của các bản vá 01–26. Hãy chạy mix test và chỉ tiếp tục sang DISCOVERY 01 sau khi toàn bộ kiểm thử xanh.`

## Cách đưa gói vào kho

1. Tạo một thư mục trống.
2. Giải nén toàn bộ gói vào thư mục đó.
3. Coi chính thư mục đó là gốc kho; không đặt nội dung dưới `implementations/elixir/` và không chồng lên kho khác.
4. Chạy `mix test` tại gốc kho trước khi tạo commit cho giai đoạn 1.
