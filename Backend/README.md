# Backend Sprint 2

TypeScript/NestJS, PostgreSQL và ảnh riêng tư. Luồng đang triển khai: US-022–040, US-103, US-107; không viết lại thiết kế frontend `main`. Quy tắc tạo yêu cầu của US-021 vẫn được áp dụng; phần phân tích CSDL riêng của task đó không nằm trong đợt này.

## Chạy trên Windows để kiểm tra

Cần Node.js 24 và npm. Trong thư mục `Backend`:

```powershell
npm ci
npm run demo
```

Lệnh demo tạo PostgreSQL thật trong `.local/postgres`, chỉ lắng nghe localhost, chạy migration và tạo ba tài khoản kiểm thử. Mật khẩu ngẫu nhiên nằm ở `.local/dev-accounts.json`, được Git bỏ qua. Không gửi SMS, không xác minh số điện thoại thật, không cài service hoặc tạo người dùng hệ điều hành. Ctrl+C dừng riêng instance này; dữ liệu vẫn còn cho lần chạy tiếp. Không chạy hai instance đồng thời. PostgreSQL đóng gói chỉ là tiện ích phát triển, không phải cấu hình production.

Trong `Frontend`:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Địa chỉ trên dành cho Android emulator truy cập localhost của máy phát triển. Với thiết bị khác phải cấu hình địa chỉ máy chủ có thể truy cập; bản release bắt buộc HTTPS. Nếu chạy web kiểm tra, dùng cổng 8080 đã được CORS cho phép:

```powershell
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
```

Web hiện giữ dữ liệu trong phiên, có thông báo rõ khi lưu nháp. Lưu bền vững/mã hóa được triển khai cho ứng dụng Android/iOS; không coi web demo là bản offline đầy đủ.

## Dùng PostgreSQL được quản lý riêng

Sao chép `.env.example` thành `.env`, điền kết nối DB riêng. Sau đó:

```powershell
npm ci
npm run migrate
npm run seed:dev
npm run dev
```

Chỉ chạy seed trong DB phát triển. Seed từ chối ghi đè tài khoản không phải kiểm thử. Production từ chối đăng nhập và phiên của mọi `is_test_account=true`. Luồng đăng ký, OTP, khôi phục số điện thoại trả `503 SMS_PROVIDER_NOT_CONFIGURED` cho tới khi nhà cung cấp và quy trình thật được chọn. Không có mã OTP dùng chung hoặc đường tắt xác minh production.

## Hợp đồng API

Tiền tố `/api/v1`; các API nghiệp vụ cần `Authorization: Bearer <token>`. Không truyền token trong URL. ID là UUID, không phải mã `CR-0247` của prototype.

| API | Mục đích / quyền |
|---|---|
| `POST /auth/login`, `GET /auth/me`, `DELETE /auth/session` | Phiên mật khẩu đã băm; xác minh/khóa/quyền được kiểm tra tại server |
| `GET /catalogs` | Loại hỗ trợ và mức khẩn cấp chuẩn |
| `GET /requests?before=<uuid>` | Trang 30 bản ghi; người dân chỉ của mình, đội chỉ phần đang phụ trách, admin cần quyền đọc |
| `POST /requests` | Chủ tài khoản gửi `{operationId,data}`; tối đa một yêu cầu mở |
| `GET /requests/:id` | Nội dung, liên hệ, vị trí, ảnh, lịch sử đầu và giờ thiết bị/máy chủ theo quyền |
| `PUT /requests/:id` | Sửa trước nhận, cùng mã; `If-Match: "<revision>"` |
| `POST /requests/:id/cancel` | `{operationId,confirmed:true}` và `If-Match`; chỉ chủ yêu cầu đang chờ, chưa có đội |
| `POST /evidence` | Multipart gồm `metadata` JSON và `image`; kiểm tra/chuẩn hóa ảnh thật, không tin MIME/tên tệp |
| `PUT /requests/:id/evidence` | Gắn ảnh bổ sung riêng; `{operationId,evidenceIds}` và `If-Match`, chỉ chủ yêu cầu còn chờ |
| `GET /evidence/:id?thumbnail=1` | Ảnh riêng tư; kiểm tra quyền trước khi xét ETag |
| `POST /requests/:id/reviews` | Admin có quyền đọc + kiểm tra; `{operationId,decision,reason}`, `If-Match` |
| `POST /requests/:id/reports` | Đội đã được duyệt báo nghi vấn; `{operationId,reason}`; không kết luận giả mạo tự động |
| `GET /requests/:id/similar` | Admin đối chiếu ứng viên gần vị trí và gần nội dung; không tự từ chối/gộp |
| `GET /requests/:id/history?before=<id>` | Lịch sử phân trang, kiểm tra quyền từng lần |
| `GET /notices`, `PUT /notices/:id/read` | Thông báo trong ứng dụng của đúng tài khoản |
| `/health/live`, `/health/ready` | Tiến trình và kiểm tra kết nối DB |

`data` có `types`, `people`, `elderly`, `children`, `disabled`, `special`, `specialNotes`, `description`, `urgency`, `address`, `landmark`, `latitude`, `longitude`, `locationSource`, `locationConfirmedAt`, `clientActionAt`, `evidenceIds`. Tọa độ 0 hợp lệ. Có địa chỉ hoặc hướng dẫn; không lấy địa chỉ thay cho vị trí đã xác nhận. Các nhóm chăm sóc có thể giao nhau; không tự thêm tuổi hay tổng nhóm bằng tổng người.

Mọi lần thử lại giữ **cùng operationId, payload và revision**. Biên nhận cùng giao dịch với thay đổi và audit. Mất phản hồi phải giữ chờ, không tạo mã thao tác mới để đoán kết quả. `409` yêu cầu xem lại dữ liệu; `428` thiếu phiên bản; `422` dữ liệu chưa hợp lệ. Trạng thái xác minh độc lập với tiến độ cứu trợ. `invalid` không tự hủy hoặc mở thêm yêu cầu.

## Ảnh, mạng yếu và thiết bị ít tài nguyên

- Gửi nội dung yêu cầu trước, nhận ACK, rồi hàng đợi ảnh bổ sung chạy riêng. Ảnh không chặn gửi yêu cầu chính. Nếu đội tiếp nhận hoặc phiên bản đổi trước khi gắn ảnh, dừng và thông báo xung đột; không tự cho phép sửa sau nhận.
- Chụp ảnh bằng camera gốc; thu nhỏ tối đa 1280 px, chất lượng JPEG 75 trước upload. Server giải mã lại, loại metadata không cần thiết, chuẩn hóa JPEG tối đa 1280 px, chất lượng 78 và thumbnail 320 px. Hai lượt xử lý ảnh đồng thời; các con số là ngân sách tài nguyên có thể điều chỉnh, không phải luật nghiệp vụ.
- Dấu ảnh ghi giờ thiết bị và tọa độ tham chiếu khai báo. Đây không phải bằng chứng chống giả mạo, không cam kết đồng hồ hay GPS đã được kiểm chứng. `receivedAt` do DB ghi độc lập.
- SQLite lưu bản nháp/outbox/cache, mã hóa AES-GCM với khóa theo tài khoản trong kho khóa hệ điều hành; giao dịch ghi ACK và xóa outbox nguyên tử. Ảnh lớn mã hóa/giải mã trong isolate. Đã có kiểm thử SQLite file thật, mở lại và phát hiện sửa ciphertext.
- Chỉ tải ảnh lớn khi mở xem; cache dữ liệu/ảnh riêng mặc định 32 MiB, cache tile xem thông thường 64 MiB; không xóa nháp/outbox theo cơ chế dọn cache. Chưa có tải bản đồ ngoại tuyến theo vùng.
- Giữ font Be Vietnam Pro của thiết kế và đóng gói font cùng ứng dụng, có OFL; không cần tải Google Fonts lúc sử dụng. Các tab được khởi tạo khi mở lần đầu.
- Retry có giãn nhịp, hủy request mạng khi timeout và giữ cùng ID; có cập nhật khi ứng dụng mở lại hoặc mạng đổi. Chưa triển khai Android WorkManager/iOS background delivery; không hứa gửi được khi ứng dụng bị đóng hoàn toàn.

## Ranh giới vận hành

Đây là phần triển khai Sprint 2 có kiểm thử, chưa phải sản phẩm đã nghiệm thu cứu trợ thực tế. Phải hoàn thành OTP/SMS thật, provisioning tài khoản/đội/admin, các sprint còn lại, kiểm thử camera/GPS/quyền và profiling thiết bị thật, kiểm thử tải/mạng yếu và khôi phục trước khi mở cho người dân.

Production cần HTTPS, DB role tối thiểu và kết nối xác thực chứng chỉ khi qua mạng; DB/máy chủ/ảnh riêng tư có sao lưu và diễn tập phục hồi; logging không ghi token, mật khẩu, liên hệ hay tọa độ. Ảnh dùng volume bền vững được khai báo rõ hoặc storage S3 private qua IAM. Không dùng thư mục container tạm làm kho ảnh. `SESSION_HOURS`, giới hạn ảnh và rate limit trong `.env.example` là giá trị kỹ thuật mặc định cần hiệu chỉnh theo môi trường, không phải SLA hoặc cam kết bảo mật đã được nghiệm thu.

Không public PostgreSQL ra Internet. Migration chạy với role quản trị schema; runtime dùng role không có quyền thay schema/tắt trigger. Rà soát vận hành, chính sách lưu giữ/xóa dữ liệu và mục tiêu khôi phục còn cần chủ dự án/đơn vị vận hành chốt. Rate limit hiện trong một instance; khi chạy nhiều instance cần kho giới hạn dùng chung và cấu hình proxy tin cậy rõ ràng. PostGIS chưa cài trong gói demo; truy vấn phạm vi/bản đồ quy mô lớn ở sprint sau cần migration không gian và đo tải riêng.

## Kiểm tra

```powershell
npm test
```

Windows tự khởi tạo cụm PostgreSQL thử nghiệm tách biệt, không xóa DB của người dùng. Hệ khác đặt `TEST_DATABASE_URL` tới **DB thử nghiệm có thể xóa toàn bộ dữ liệu**; suite dùng `TRUNCATE` các bảng của ứng dụng. Không dùng URL production. Kết quả/giới hạn hiện hành: `docs/implementation-status.md` và `../PROJECT_HANDOFF.md`.

Nguồn kỹ thuật: [Flutter offline first](https://docs.flutter.dev/app-architecture/design-patterns/offline-first), [OWASP object authorization](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/), [OWASP password storage](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html), [OWASP file upload](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html), [PostgreSQL locking](https://www.postgresql.org/docs/current/explicit-locking.html), [OSM tile policy](https://operations.osmfoundation.org/policies/tiles/), [flutter_map caching](https://docs.fleaflet.dev/layers/raster-tile-layer/caching).
