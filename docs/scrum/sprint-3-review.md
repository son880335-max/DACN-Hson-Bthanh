# Báo cáo Sơ kết Sprint 3 (Sprint 3 Review)

**Dự án**: Hệ thống Cứu trợ đồng bào lũ lụt
**Thời gian Sprint**: [nhóm điền ngày bắt đầu – ngày kết thúc]
**Người tham gia**: Hoàng Sơn, Bảo Thanh, [nhóm điền thêm nếu có]

---

## 1. Mục tiêu Sprint 3 (Sprint Goal)

Xây dựng và hoàn thiện phân hệ **Điều phối Cứu trợ (Dispatch System)**: Cho phép đội cứu hộ tìm kiếm, tiếp nhận độc quyền và cập nhật tiến độ nhiệm vụ; hỗ trợ quản trị viên chuyển đội và liên kết yêu cầu; bảo vệ nghiêm ngặt thông tin nhạy cảm (tọa độ GPS, số điện thoại) và xử lý mượt mà xung đột thao tác mạng.

---

## 2. Kết quả Triển khai Thực tế (Suy ra từ mã nguồn và kiểm thử)

### A. Các User Story đã hoàn thành (Done)
1. **US-041 – US-043**: Hiển thị trạng thái nhiệm vụ chuẩn hóa (`waiting`, `accepted`, `travelling`, `arrived`, `completed`, `cancelled`, `invalid`) và lịch sử diễn biến sự kiện `dispatch.*`.
2. **US-044 – US-047**: Hàng chờ nhiệm vụ cho đội cứu hộ (`mode=waiting`):
   - Che giấu hoàn toàn số điện thoại, địa chỉ cụ thể và tọa độ chi tiết của nạn nhân.
   - Tính toán khoảng cách dựa trên tọa độ đã được làm tròn 2 chữ số thập phân (~1.1 km) để bảo vệ quyền riêng tư vị trí.
   - Hỗ trợ lọc theo loại cứu trợ, mức khẩn cấp và khoảng cách giới hạn trong tập `{1, 3, 5, 10, 20, 50}` km.
   - Khống chế tần suất truy vấn vị trí tối đa 30 lần/phút/tài khoản.
3. **US-051 – US-054**: Cơ chế tiếp nhận nhiệm vụ độc quyền (Claim Task):
   - Sử dụng khóa dòng giao dịch `FOR UPDATE` và kiểm tra số hiệu phiên bản `revision`.
   - Chặn đứng tình trạng hai đội cùng tiếp nhận một đơn; đội thao tác sau nhận lỗi HTTP 409 `TASK_TAKEN`.
   - Danh sách nhiệm vụ đang phụ trách (`mode=assigned`) cho riêng từng đội.
4. **US-055 – US-057**: Cơ chế trả và chuyển giao nhiệm vụ:
   - Đội cứu hộ được quyền trực tiếp trả nhiệm vụ về hàng chờ kèm lý do khi gặp sự cố phương tiện/địa hình mà không cần quản trị viên duyệt trước.
   - Quản trị viên nhận thông báo và có thẩm quyền điều động, chuyển giao nhiệm vụ sang đội khác.
5. **US-058 – US-060**: Bảo vệ dữ liệu liên hệ và tiến độ cứu trợ:
   - Chỉ đội đang chính thức phụ trách hoặc quản trị viên mới được phép xem số điện thoại và vị trí chi tiết (ghi nhận nhật ký kiểm toán vào bảng `access_audit`).
   - Cập nhật tiến độ thực địa bắt buộc theo đúng trình tự nghiệp vụ: `accepted` -> `travelling` -> `arrived`.
6. **US-050**: Liên kết đơn trùng lặp: Cho phép quản trị viên liên kết đơn phụ vào đơn chính, triệt để ngăn chặn tạo chuỗi liên kết nhiều cấp (`LINK_UNAVAILABLE`).
7. **US-104 & US-108**: Trợ năng giao diện khẩn cấp (nút bấm >= 48px) và hộp thoại hướng dẫn thao tác gửi/theo dõi cứu trợ.

### B. Kết quả Đo lường Kỹ thuật
- **Backend**: 23/23 ca kiểm thử tự động đạt 100% (bao gồm kiểm thử bảo mật vị trí, chống xung đột, audit truy cập, giới hạn tần suất).
- **Frontend**: 49/49 ca kiểm thử tự động đạt 100%; Static analyzer đạt 0 cảnh báo.

---

## 3. Nội dung Cần Con người Điền

### Kịch bản Demo thực tế tại buổi Review
[nhóm điền]

### Phản hồi từ Giảng viên hướng dẫn / Product Owner
[nhóm điền]

### Đóng góp cụ thể của từng thành viên trong Sprint 3
- Hoàng Sơn: [nhóm điền]
- Bảo Thanh: [nhóm điền]
