# Báo cáo kiểm thử tự động (Testing Report)

Ngày kiểm thử: 18/11/2026.
Môi trường kiểm thử: Windows 11 x64, Node.js 24, Flutter 3.x, PostgreSQL 18.

---

## 1. Backend Testing (`npm test`)

- **Lệnh thực thi**:
  ```powershell
  $env:TEST_DATABASE_URL = "postgresql://postgres:***@127.0.0.1:5432/dacn_test"
  cd Backend
  npm test
  ```
- **Kết quả tổng thể**: **22/22 tests passed (0 failed)**.
- **Thời gian chạy**: ~10.15 giây.
- **Danh sách ca kiểm thử chi tiết**:
  1. `✔ recordAccessAudit and recordBatchAccessAudit log views without personal info and throttle per hour`
  2. `✔ recordAccessAudit catches write error and logs audit_write_failed without PII`
  3. `✔ Sprint 3: redact waiting tasks, link owners, serialize competing claims, transfer and return`
  4. `✔ authentication is real; registration never simulates phone verification`
  5. `✔ validates confirmed coordinates and fields; optional photo; owner data stays private`
  6. `✔ parallel retries and competing new operations commit exactly one open request`
  7. `✔ Sprint 2 rejects missing and invalid request fields with useful Vietnamese messages`
  8. `✔ edit uses version; cancellation needs explicit confirmation and server receipt before reopening`
  9. `✔ verification and reports are authorized, audited and notify without automatically cancelling`
  10. `✔ cancellation and assignment cannot both succeed; accepted request cannot be cancelled or edited`
  11. `✔ real image decode, watermark, thumbnail, idempotent upload and private authenticated download`
  12. `✔ similarity includes distant matching text as well as nearby candidates; history is authorized and paginated`
  13. `✔ login throttling, expired sessions and unverified accounts fail safely`
  14. `✔ committed operations survive app restart and migrations can be run twice`
  15. `✔ dispatch location privacy on PostgreSQL: rounded distance in mode=waiting and km validation`
  16. `✔ loadConfig validates sslmode on production DATABASE_URL unless DB_ALLOW_INSECURE is true`
  17. `✔ database pool registers error listener that logs generic message without leaking credentials`
  18. `✔ DispatchController enforces location privacy, km validation, and 30 req/min location rate limit`
  19. `✔ ApiErrorFilter masks 5xx errors without leaking SQL or stack traces, and includes requestId`
  20. `✔ Fastify request logger serializes req without query string and excludes lat, lon, and search params`
  21. `✔ AuthService rate limits by (phone + IP) pair (5 fails) and phone threshold (20 fails), without locking out other IPs`
  22. `✔ runMaintenance dry-run counts items, and live run deletes aged sessions, receipts, and unlinked evidence files`

---

## 2. Frontend Static Analysis (`flutter analyze`)

- **Lệnh thực thi**:
  ```powershell
  cd Frontend
  flutter analyze
  ```
- **Kết quả**:
  ```text
  Analyzing Frontend...
  No issues found! (ran in 8.8s)
  ```
- Không có lỗi cú pháp, kiểu dữ liệu hay lint warning nào tồn đọng.

---

## 3. Frontend Unit & Widget Testing (`flutter test`)

- **Lệnh thực thi**:
  ```powershell
  cd Frontend
  flutter test
  ```
- **Kết quả tổng thể**: **49/49 tests passed (0 failed)**.
- **Kiểm tra SQLite mã hóa (`test/encrypted_vault_test.dart`) trên Windows**:
  - Ca kiểm thử: `real SQLite persists encrypted drafts and atomic receipts; large image encryption survives reopen`.
  - Kết quả: **PASSED**. Cơ chế mã hóa AES-GCM và lưu trữ SQLite cục bộ trên máy chạy ổn định, không gặp lỗi biên dịch native hay thiếu DLL.
- **Phân nhóm các bộ kiểm thử đã vượt qua**:
  - `encrypted_vault_test.dart`: Lưu trữ bản nháp mã hóa và biên nhận nguyên tử (1 test).
  - `navigation_regression_test.dart`: Điều hướng phím Back, xóa lịch sử đăng nhập, giữ shell tab (15 tests).
  - `sprint2_location_test.dart`: Xác nhận tọa độ GPS và điều chỉnh ghim bản đồ (3 tests).
  - `sprint2_widgets_test.dart`: Responsive màn hình nhỏ, Preview ảnh chụp, Card hiển thị (6 tests).
  - `sprint2_workflows_test.dart`: Đăng xuất thu hồi phiên, báo cáo nghi vấn, cấp quyền thông báo/camera (18 tests).
  - `sprint2_validation_test.dart`: Kiểm tra hợp lệ dữ liệu yêu cầu.
  - `sprint2_request_actions_test.dart`: Thao tác sửa/hủy yêu cầu trước tiếp nhận.
  - `offline_repository_test.dart`: Đồng bộ ngoại tuyến và hàng đợi outbox.
