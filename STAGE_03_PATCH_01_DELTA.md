# Phần thay đổi giai đoạn 3 — Bản vá 01

## Cơ sở

Bắt đầu từ commit đóng giai đoạn 2 \`dcef0ef26ca8fb705577812c888b6b6ae7e4b68f\`,
đã xác minh 22 kiểm thử, đúng ba sai lệch dự kiến tại M, 2M, 3M.
Không đưa mã từ nhánh khác; giữ nguyên danh mục tên và tài liệu tham chiếu thử nghiệm.

## Cách vá bắt buộc

\`\`\`text
savePatch(x):
    r = oldRemainder(x)
    if r == 0:
        r = M
    return r
\`\`\`

Dòng sản xuất vẫn thực thi \`old_remainder\` sai; \`SavePatch\` chỉ bổ sung
nhánh đổi 0 thành M. Không thay đổi \`LegacyRemainder\`.

## Kiểm thử dự định

- Cả ba hồi quy M, 2M, 3M cũ trở thành đạt, không đổi kỳ vọng chuẩn.
- Kiểm thử độc lập của phần dư lịch sử xác nhận lỗi cũ vẫn tồn tại.
- Kiểm thử 0 và các bội số âm, vùng lân cận bội số hai chiều.
- Kiểm thử số nguyên lớn và chu kỳ modulo M.
- Kiểm thử truy vết cấu trúc, tính đồng thời và từ chối đầu vào không hợp lệ.
- Giai đoạn ngày lịch tổng thể chưa được tích hợp.

Dự kiến 29 kiểm thử, không lỗi. Khóa tên chuẩn phải đạt.

## Kiểm toán thay đổi kiểm thử

Chỉ kiểm thử nối dây cũ được điều chỉnh để kiểm chứng tuyến đã vá.
Ba kiểm thử hồi quy chuẩn của giai đoạn 2 được giữ nguyên hoàn toàn.
Không sửa bài kiểm thử để phù hợp với lỗi.

## Tiêu đề commit

Giai đoạn 3: bọc phần dư SAVE lịch sử bằng bản vá 01

## Nội dung commit

Giữ nguyên phép dư sai và đặt lớp SavePatch có nhánh chuyển 0 thành M.
Nối vào đường sản xuất, xác minh số nguyên âm, biên và đồng thời.
Bảo toàn tất cả hồi quy chuẩn của giai đoạn phát hiện trước.
