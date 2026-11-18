# Danh mục Dữ liệu Cá nhân & Căn cứ Pháp lý (Data Inventory)

**Dự án**: Hệ thống Cứu trợ đồng bào lũ lụt
**Ngày rà soát**: 18/11/2026.
**Căn cứ kỹ thuật**: Cơ sở dữ liệu PostgreSQL (`Backend/migrations/001_initial.sql` đến `007_consent.sql`) và mã nguồn Backend/Frontend.

---

## 1. Cơ sở Pháp lý về Bảo vệ Dữ liệu Cá nhân

### A. [Đã xác minh] Nghị định số 13/2023/NĐ-CP của Chính phủ
Nghị định số 13/2023/NĐ-CP ngày 17/04/2023 về Bảo vệ dữ liệu cá nhân (có hiệu lực từ ngày 01/07/2023) là căn cứ pháp lý hiện hành cao nhất đang áp dụng:
- **Điều 2, Khoản 3 (Dữ liệu cá nhân cơ bản)**: Bao gồm Họ, chữ đệm và tên khai sinh; Số điện thoại; Địa chỉ liên hệ; Thông tin tài khoản số.
- **Điều 2, Khoản 4, Điểm đ (Dữ liệu cá nhân nhạy cảm)**: *"Dữ liệu vị trí của cá nhân được xác định qua dịch vụ định vị"*.
- **Điều 2, Khoản 4, Điểm g (Dữ liệu cá nhân nhạy cảm)**: Tình trạng sức khỏe và đời tư (liên quan đến thông tin khai báo người khuyết tật, bệnh nền, phụ nữ mang thai, người cần chăm sóc đặc biệt).
- **Điều 17 (Xử lý dữ liệu cá nhân trong trường hợp không cần sự đồng ý)**:
  > *"1. Trong trường hợp khẩn cấp, cần xử lý ngay dữ liệu cá nhân có liên quan để bảo vệ tính mạng, sức khỏe của chủ thể dữ liệu hoặc người khác. Bên Kiểm soát dữ liệu cá nhân, Bên Xử lý dữ liệu cá nhân... có trách nhiệm chứng minh trường hợp này."*
  >
  > *(Đây là căn cứ pháp lý trọng yếu cho quyết định kỹ thuật: **KHÔNG chặn** việc gửi đơn cứu trợ khẩn cấp kể cả khi người dân chưa kịp tick ô đồng ý sử dụng dữ liệu).*

### B. [CẦN XÁC MINH] Dự thảo Luật Bảo vệ Dữ liệu Cá nhân 2025 & Nghị định 356/2025/NĐ-CP
- **Luật Bảo vệ Dữ liệu Cá nhân**: Dự thảo do Bộ Công an chủ trì soạn thảo, đã được Chính phủ trình Quốc hội khóa XV cho ý kiến. Hiện cần đối chiếu lại văn bản luật chính thức đã được Quốc hội thông qua và thời điểm có hiệu lực thi hành cụ thể. [CẦN XÁC MINH số Điều và hiệu lực thi hành].
- **Nghị định 356/2025/NĐ-CP**: Cần xác minh tính chính thức và số hiệu ban hành của văn bản này trên Cổng Thông tin điện tử Chính phủ (http://chinhphu.vn) hoặc Cơ sở dữ liệu Quốc gia về Văn bản Pháp luật (http://vbpl.vn).
- *Quyết định hành động*: Nhóm sẽ làm việc và xin ý kiến xác nhận căn cứ pháp lý cụ thể với Giảng viên hướng dẫn trong buổi báo cáo chuyên đề.

---

## 2. Bảng Danh mục Dữ liệu Cá nhân Thu thập & Xử lý (Data Inventory)

| Trường dữ liệu (Schema/DB) | Phân loại dữ liệu | Mục đích thu thập | Ai được phép truy cập | Thời hạn lưu trữ | Căn cứ pháp lý (NĐ 13/2023) |
|---|---|---|---|---|---|
| **`accounts.phone`** | Dữ liệu cá nhân cơ bản | Định danh tài khoản, liên lạc cứu nạn khẩn cấp, gửi thông báo | - Chủ tài khoản<br>- Đội cứu hộ đã nhận đơn<br>- Quản trị viên (được phân quyền) | [nhóm chốt] | Điều 2, Khoản 3 |
| **`accounts.display_name`** | Dữ liệu cá nhân cơ bản | Hiển thị danh tính người yêu cầu hoặc tên đội cứu trợ | - Mọi vai trò đã đăng nhập (khi đội hiển thị) | [nhóm chốt] | Điều 2, Khoản 3 |
| **`accounts.password_hash`** | Dữ liệu nhạy cảm kỹ thuật | Xác thực truy cập (chỉ lưu băm Argon2id + salt) | - Hệ thống tự động (không ai được đọc giải mã) | Theo vòng đời tài khoản | Điều 13 (Biện pháp bảo vệ) |
| **`relief_requests.latitude`, `longitude`** | **Dữ liệu cá nhân nhạy cảm** | Xác định vị trí nạn nhân để đội cứu hộ tiếp cận cứu nạn | - Hàng chờ: **Chỉ hiển thị tọa độ làm tròn 2 chữ số (~1.1 km)**<br>- Đội đã nhận: Tọa độ chính xác<br>- Admin: Tọa độ chính xác | [nhóm chốt] | Điều 2, Khoản 4, Điểm đ & Điều 17 |
| **`relief_requests.data.address`, `landmark`** | Dữ liệu cá nhân cơ bản | Bổ sung hướng dẫn nhận diện địa điểm, số nhà, ngõ ngách | - Đội cứu hộ đã tiếp nhận<br>- Quản trị viên (ẩn trong hàng chờ) | [nhóm chốt] | Điều 2, Khoản 3 |
| **`relief_requests.data.people`, `elderly`, `children`, `disabled`, `specialNotes`** | **Dữ liệu cá nhân nhạy cảm** | Đánh giá mức độ khẩn cấp, chuẩn bị phương tiện y tế, ưu tiên cứu hộ người yếu thế | - Đội cứu hộ xem xét hàng chờ (chỉ số lượng)<br>- Đội đã tiếp nhận<br>- Quản trị viên | [nhóm chốt] | Điều 2, Khoản 4, Điểm g & Điều 17 |
| **`evidence` (Ảnh chụp hiện trường)** | Dữ liệu cá nhân nhạy cảm | Minh chứng hiện trạng ngập lụt, hỗ trợ nhận diện và đối chiếu gian lận | - Đội cứu hộ đã tiếp nhận<br>- Quản trị viên duyệt xác minh | Theo `OPERATION_RETENTION_DAYS` (mặc định 30 ngày) hoặc [nhóm chốt] | Điều 2, Khoản 4 & Điều 17 |
| **`access_audit` (Nhật ký truy cập PII)** | Dữ liệu kiểm toán bảo mật | Ghi vết việc xem SĐT/tọa độ của Admin và Đội cứu hộ; phát hiện vi phạm quyền riêng tư | - Quản trị viên cấp cao / Thanh tra kiểm toán | Tối thiểu 1 năm hoặc [nhóm chốt] | Điều 13, Khoản 2 (Lưu vết xử lý dữ liệu) |
| **`accounts.consent_version`, `consented_at`** | Dữ liệu quản lý đồng ý | Bằng chứng về việc người dùng đã được thông báo và đồng ý xử lý dữ liệu | - Quản trị viên / Cơ quan quản lý | Theo vòng đời tài khoản | Điều 9 & Điều 11 |

---

## 3. Biện pháp Kỹ thuật Bảo vệ Quyền Riêng tư Đã Triển khai

1. **Làm tròn tọa độ hàng chờ (Spatial Cloaking - US-047)**:
   Trước khi đội cứu hộ nhận đơn, API `GET /dispatch?mode=waiting` tự động làm tròn tọa độ GPS về 2 chữ số thập phân (`round(latitude, 2)`). Độ lệch bán kính khoảng 1.1 km đủ để đội cứu hộ tính khoảng cách áng chừng mà kẻ xấu không thể định vị chính xác vị trí căn nhà của người dân.
2. **Che giấu thông tin liên hệ**:
   Số điện thoại và địa chỉ nhận diện bị loại bỏ hoàn toàn khỏi JSON trả về trong danh sách hàng chờ công khai của các đội.
3. **Kiểm toán truy cập bắt buộc (Access Audit - US-102)**:
   Bảng `access_audit` tự động ghi nhận mỗi khi Admin hoặc Đội cứu hộ xem chi tiết có chứa số điện thoại hoặc tọa độ (tần suất khống chế tối đa 1 bản ghi/người/yêu cầu/giờ). Bảng kiểm toán tuyệt đối không lưu lại số điện thoại hay tọa độ.
4. **Giới hạn tần suất truy vấn vị trí**:
   Truy vấn có tham số `lat`/`lon` bị khống chế tối đa 30 lần/phút/tài khoản nhằm ngăn chặn hành vi quét vét dữ liệu (scraping/triangulation).
5. **Lọc sạch Log máy chủ**:
   Hệ thống Fastify serializer tự động cắt bỏ phần query string (chứa `lat`, `lon`, `search`) và che giấu các header ủy quyền (`Authorization: Bearer ***`).
