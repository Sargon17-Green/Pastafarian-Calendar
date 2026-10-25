# Kiểm tra vi sai với Python độc lập

Thử nghiệm chạy trên nhánh Elixir+tiếng-Việt với hai cây
GitHub tách biệt:
- Elixir đúng SHA của workflow hiện tại.
- Python+Türkçe tại commit
  b3501b4296403bc33cb36f81a763269e5af97523.

Không chuyển mã từ Python sang Elixir. Không gọi oracle chuẩn
trong production. Chỉ so bộ năm phần theo chỉ số chuẩn:
(năm, chỉ số cốt-lết, ngày trong cốt-lết,
chỉ số tháng, ngày trong tháng) trên cùng dayIndex.

Tập đầu tiên gồm năm cặp gần Foundation, bao gồm chuyển
ngày theo hai hướng. Mọi bất đồng đều làm job FAIL và xuất
hai bộ dữ liệu TSV, log thực thi, báo cáo so sánh.
Không đánh đồng đạt năm mẫu với chứng minh toàn miền.
Các mốc ngày hiện đại và đổi năm sẽ là đợt mở rộng sau.

Trước khi workflow chạy: trạng thái PENDING; không tuyên bố PASS.

## Mở rộng 9 ca, nguồn đầu vào chung

`qa/differential_cases.tsv` giữ đúng cùng một danh sách
cặp (ngày tính, ngày đích) cho Python và Elixir.
Năm ca cũ gần Foundation giữ nguyên. Bốn ca mới:
- ngày hiện đại dayIndex 739834 (tự cùng ngày),
- tiến sáu ngày từ mốc hiện đại,
- lùi một ngày từ mốc hiện đại,
- năm dài 5778 ngày từ nhân chứng JDN -14269936,
  chuyển đúng thành dayIndex -15991361.

Ngày hiện đại lấy từ nhân chứng regression đã có ở Python.
Các giá trị bằng chữ không được so sánh; chỉ chỉ số chuẩn
và số ngày. Trình Python xác nhận SHA của peer trước khi
thực thi. Chứng cứ TSV được ghi từng bước để hỗ trợ
chẩn đoán khi vượt timeout. Không diễn giải PASS trước CI.
