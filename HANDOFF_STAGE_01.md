# Bàn giao giai đoạn 1 — Elixir / tiếng Việt

## Phạm vi

Đây là dòng triển khai Elixir + tiếng Việt được dựng từ số không theo phụ lục A của đặc tả. Không dùng mã, kiểm thử, dữ liệu kiểm thử, kết quả, giá trị băm, nhật ký hay bảng sinh ra của bất kỳ cách triển khai ngôn ngữ nào khác.

Gói đóng giai đoạn 1 này sửa đúng những điểm còn thiếu sau lần chạy CI đầu tiên; nó không bắt đầu giai đoạn 2 và không thêm bất kỳ khuyết tật legacy hay bản vá nào của các giai đoạn 2–53.

## Kết quả xác minh đã có

Workflow `Kiểm thử Elixir tiếng Việt` đã chạy trên nhánh hiện tại bằng Elixir 1.18.4 và Erlang/OTP 27. Lệnh `mix test` biên dịch thành công và hoàn tất với:

```text
16 tests, 0 failures
```

Kết quả này xác nhận bộ kiểm thử giai đoạn 1 trước gói đóng hiện tại. Gói đóng chỉ thay đổi tài liệu/trạng thái, Việt hóa `LICENSE`, mở rộng kiểm tra văn bản cho tệp giấy phép và loại bỏ hai cảnh báo biến không dùng trong bộ tham chiếu chỉ dành cho kiểm thử. Sau khi tải gói này lên, cần để CI chạy lại và chỉ chuyển sang DISCOVERY 01 nếu lần chạy mới vẫn xanh.

## Nội dung sửa trong gói đóng

- `DEVELOPMENT_STAGE.md`: ghi nhận bằng chứng CI đã có nhưng giữ `LAST_COMPLETED_STAGE=0` cho đến khi chính gói đóng này được CI xác minh lại.
- `README.md`: bỏ thông tin cũ nói rằng Elixir chưa thể chạy và ghi kết quả xác minh thực tế.
- `HANDOFF_STAGE_01.md`: chuyển từ trạng thái “chưa xác minh” sang bàn giao đóng giai đoạn.
- `SPAGHETTI_DEVELOPMENT_HISTORY.md`: ghi nhận việc xác minh và đóng Bootstrap mà không viết trước lịch sử của bản vá 01.
- `LICENSE`: thay phần văn bản tiếng Anh còn sót lại bằng bản tiếng Việt giữ nguyên ý nghĩa cấp phép.
- `test/stage_01_test.exs`: đưa `LICENSE`, YAML và các tệp văn bản liên quan vào kiểm tra chữ Hebrew, đồng thời ngăn hồi quy về phần giấy phép tiếng Anh trước đó.
- `test/support/normative_reference.ex`: chỉ đổi tên hai biến không dùng thành dạng gạch dưới để loại bỏ cảnh báo; không thay đổi tính toán.

## Trạng thái kiến trúc

`SourceLanguageCatalog` phiên bản `1.0.0` vẫn đóng băng với 17 tên miếng và 47 tên tháng. Thứ tự chuẩn vẫn chỉ dựa trên `canonicalIndex`.

Mã sản xuất vẫn chỉ có hạ tầng trung tính được phép ở Bootstrap: ngữ cảnh theo từng lần gọi, bộ phân phối cơ sở, bộ kiểm tra, biên lỗi và quan sát phi ngữ nghĩa. `calendar_date_spaghetti/2` vẫn cố ý ném lỗi “chưa tích hợp” và không gọi bộ tham chiếu chuẩn.

Bộ tham chiếu chuẩn đầy đủ vẫn chỉ nằm trong cây kiểm thử. Không có fallback sang oracle và không có mã của các bản vá 01–26.

## Kiểm thử cần chạy sau khi tải lên

Tại gốc kho:

```text
mix test
```

Kết quả bắt buộc: toàn bộ kiểm thử xanh. Nếu có lỗi, vẫn ở giai đoạn 1 và sửa đúng lỗi đó trước khi tiếp tục.

## Tiêu đề commit đề xuất

`Đóng giai đoạn 1 sau khi xác minh CI`

## Nội dung commit đề xuất

`Hoàn tất phần đóng Bootstrap của dòng Elixir + tiếng Việt sau khi GitHub Actions chạy mix test thành công với Elixir 1.18.4, Erlang/OTP 27, 16 kiểm thử và 0 lỗi. Cập nhật trạng thái và tài liệu theo kết quả thực tế, Việt hóa tệp LICENSE còn sót lại, mở rộng kiểm tra văn bản và loại bỏ hai cảnh báo biến không dùng trong bộ tham chiếu chỉ dành cho kiểm thử. Không thêm hành vi sản xuất, khuyết tật legacy hay bản vá của giai đoạn tương lai.`

## Ghi chú GitHub đề xuất

`Đây là lần đóng giai đoạn 1/55. Bootstrap đã có bằng chứng CI xanh; gói này chỉ đồng bộ trạng thái/tài liệu với kết quả thực tế, loại bỏ phần văn bản tiếng Anh còn sót lại trong LICENSE và làm sạch hai cảnh báo không mang ý nghĩa ngữ nghĩa. Sau khi commit này được tải lên, hãy chờ workflow mix test chạy lại; chỉ khi workflow xanh mới bắt đầu DISCOVERY 01.`
