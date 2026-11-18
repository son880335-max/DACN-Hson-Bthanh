# Báo cáo Cải tiến Quy trình Sprint 3 (Sprint 3 Retrospective)

**Dự án**: Hệ thống Cứu trợ đồng bào lũ lụt
**Thời gian họp**: [nhóm điền ngày/giờ]
**Người tham gia**: Hoàng Sơn, Bảo Thanh, [nhóm điền thêm nếu có]

---

## 1. Điểm Làm Tốt (What Went Well)
*(Suy ra từ kết quả mã nguồn và kiến trúc kỹ thuật đã kiểm chứng)*

1. **Kiểm thử tự động bao phủ chặt chẽ**:
   - Backend đạt 23/23 tests và Frontend đạt 49/49 tests, bao phủ từ cấp độ đơn vị đến tích hợp cơ sở dữ liệu thật và các kịch bản cạnh tranh tiếp nhận đồng thời.
   - Cơ chế SQLite mã hóa AES-GCM cục bộ trên máy chạy ổn định trên môi trường Windows mà không bị lỗi thiếu thư viện hay lỗi native.
2. **Kỷ luật bảo vệ quyền riêng tư vị trí & dữ liệu cá nhân**:
   - Tuân thủ nguyên tắc ẩn dữ liệu tối đa: Tọa độ hàng chờ được làm tròn 2 chữ số thập phân (~1.1 km); số điện thoại và địa chỉ cụ thể không gửi ra client khi chưa tiếp nhận.
   - Thao tác ghi nhật ký truy cập kiểm toán `access_audit` được bọc try/catch an toàn, không bao giờ để lỗi audit phụ làm gián đoạn yêu cầu của người dùng.
3. **Xử lý trải nghiệm người dùng khi xảy ra xung đột điều phối**:
   - Frontend đã ánh xạ tự động toàn bộ mã lỗi nghiệp vụ sang tiếng Việt chuẩn và tự động kích hoạt tải lại dữ liệu khi phát hiện nhiệm vụ đã có đội khác nhận.

---

## 2. Điểm Cần Cải tiến & Hạn chế Kỹ thuật (What Could Be Improved)
*(Suy ra từ ranh giới kiến trúc và môi trường hiện tại)*

1. **Bộ đếm giới hạn tần suất (Rate Limit) trong RAM**:
   - Hiện bộ đếm khóa đăng nhập và giới hạn truy vấn vị trí lưu trực tiếp trong bộ nhớ tiến trình (RAM), chỉ áp dụng chính xác cho 1 instance. Khi mở rộng hệ thống lên cụm tải nhiều máy chủ (multi-instance/load balancing), cần tích hợp kho lưu trữ phân tán tập trung như Redis.
2. **Đánh đổi bảo mật của ngưỡng khóa 20 lần theo số điện thoại**:
   - Ngưỡng khóa 20 lần sai/15 phút tính tổng từ mọi IP giúp chặn botnet dò mật khẩu phân tán, nhưng có thể bị kẻ xấu cố tình nhập sai liên tục để gây từ chối dịch vụ (DoS) cho chủ tài khoản. Cần sớm bổ sung xác thực CAPTCHA hoặc OTP qua kênh thứ hai.
3. **Phụ thuộc cấu hình môi trường kiểm thử PostgreSQL**:
   - Tiện ích nhúng `embedded-postgres` trên Windows bị chặn khi chạy với tài khoản Administrator. Nhóm cần duy trì quy trình thiết lập biến môi trường `TEST_DATABASE_URL` trỏ vào cơ sở dữ liệu kiểm thử riêng biệt (`dacn_test`) và lệnh dọn sạch bảng trước mỗi đợt chạy suite.
4. **Hạ tầng viễn thông thực tế**:
   - Hiện luồng đăng ký mới và OTP vẫn đang ở trạng thái chuẩn bị (trả lỗi 503 cấu hình); cần kinh phí và hợp đồng tích hợp với nhà mạng SMS Brandname để đưa vào thử nghiệm thực địa.

---

## 3. Nội dung Cần Con người Điền

### Thảo luận nhóm về phối hợp công việc
[nhóm điền]

### Kế hoạch hành động cụ thể cho Sprint tiếp theo (Action Items)
- [nhóm điền mục tiêu 1]
- [nhóm điền mục tiêu 2]
- [nhóm điền mục tiêu 3]
