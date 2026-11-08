# Rà soát Flutter Android — Sprint 2

Phạm vi: US-021–040, US-103, US-107. Giữ dữ liệu mẫu theo yêu cầu, không xây backend và không sửa mã nghiệp vụ tài khoản/OTP/hồ sơ đội của sprint trước.

## Các lỗi đã phát hiện và sửa khi rà soát Android

1. **Plugin quyền không tương thích SDK dự án:** `permission_handler 13.0.2` kéo plugin Android yêu cầu compileSdk 37, trong khi dự án dùng compileSdk 36. Đã cố định `permission_handler: 12.0.1` (plugin Android 13.0.1, compileSdk 35), giữ nguyên Gradle/SDK của dự án. Đã build APK debug thành công với cấu hình này.
2. **Android có thể hủy Activity khi mở camera:** lưu checkpoint riêng của biểu mẫu trước khi mở camera, khôi phục qua `retrieveLostData` khi người dùng vào lại luồng soạn. Hỏi người dùng trước khi khôi phục; không ghi đè nội dung yêu cầu đã gửi. Giữ revision cũ để chặn ghi đè nếu yêu cầu đã được cập nhật ở nơi khác. Ảnh khôi phục chỉ có thời gian ước tính, không lấy vị trí hiện tại làm GPS lúc chụp.
3. **Nút Back Android:** ở bước 2–4, lùi một bước và giữ dữ liệu; ở bước đầu, biểu mẫu có thay đổi phải xác nhận ở lại/bỏ/lưu nháp. Trong lúc đang lưu, lấy GPS hoặc xử lý camera thì không cho Back làm gián đoạn thao tác.
4. **Số người ưu tiên:** mỗi nhóm không vượt tổng số người; tổng người cao tuổi + trẻ em không vượt tổng. Người khuyết tật/cần chăm sóc đặc biệt có thể thuộc nhóm khác nên không cộng tất cả bốn nhóm để so với tổng.
5. **Ảnh giả định dạng:** không chỉ kiểm tra chữ ký JPEG; ảnh phải giải mã được. Xử lý hướng EXIF để ảnh camera không bị xoay sai, đóng dấu vào pixel; xử lý ảnh camera ở isolate để hạn chế đứng giao diện Android.
6. **Duyệt lại yêu cầu cũ:** nếu một yêu cầu đã bị đánh dấu không hợp lệ và người dùng đã tạo yêu cầu mới đang hoạt động, quản trị không được chuyển yêu cầu cũ về hoạt động gây hai yêu cầu cùng lúc.
7. **GPS:** từ chối quyền/GPS tắt/quá thời gian có thông báo và phương án ghim bản đồ. Thiếu ảnh hoặc GPS của ảnh không tự chặn việc gửi yêu cầu cứu trợ; tạo dấu hiệu cần xác minh.
8. **Plugin chưa được đăng ký dù APK build được:** `pub get` trước đó dừng ở symlink của Windows desktop nên `GeneratedPluginRegistrant.java` còn bản cũ. Đã tắt target Windows/Linux desktop bằng `flutter.config` trong `pubspec.yaml` của riêng dự án (không đổi cài đặt Windows/toàn bộ Flutter SDK), chạy lại `pub get` thành công và xác nhận registrant có đủ camera/GPS/quyền/lưu dữ liệu. Không sửa tay tệp registrant tự sinh.

Luồng GPS thử provider mặc định trong 12 giây; nếu hết thời gian trên Android thì thử `LocationManager` trực tiếp thêm tối đa 8 giây. Cả hai đều không trả kết quả thì thông báo và cho phép chọn bản đồ/nhập tọa độ. Không biến việc quá thời gian thành thông báo định vị thành công.

## Ràng buộc được giữ

| Nhóm | Ràng buộc |
|---|---|
| Loại hỗ trợ | Chọn ít nhất một trong 5 loại đã nêu ở US-022. |
| Người được hỗ trợ | Tổng 1–10.000; các nhóm không âm. Có người cần chăm sóc đặc biệt phải mô tả nhu cầu. Gửi giúp người khác phải có tên và số điện thoại hợp lệ. |
| Hiện trạng | Mô tả bắt buộc, tối đa 2.000 ký tự. Mức khẩn cấp phải thuộc danh sách. |
| Vị trí | Vĩ độ/kinh độ hữu hạn, đúng miền; phải có địa chỉ hoặc chỉ dẫn. Ghim/nhập tọa độ không gắn nhãn GPS. |
| Nháp | Chấp nhận dữ liệu chưa đầy đủ; lưu/mở lại đúng bản ghi. Gửi nháp không tạo thêm bản trùng. |
| Gửi mới | Mỗi chủ yêu cầu có tối đa một yêu cầu đang chờ/đã tiếp nhận còn hợp lệ để xử lý. |
| Sửa/hủy | Đúng chủ, trước tiếp nhận, đúng phiên bản. Hủy phải xác nhận. Không sửa yêu cầu đã kết thúc/không hợp lệ. |
| Ảnh | Tối đa 5; đầu vào tối đa 10 MB, kết quả JPEG tối đa 1 MB. Xem trước, đồng ý mới thêm; chụp lại thay đúng ảnh. |
| Xác minh | Quản trị mới được kết luận. Cần bổ sung/không hợp lệ phải có lý do. Có lịch sử và thông báo. Sửa yêu cầu đưa về chờ xác minh lại. |
| Báo cáo | Có lý do, không gửi lặp theo cùng định danh mẫu, không tự kết luận giả mạo. |
| Quyền Android | Manifest có INTERNET, CAMERA, FINE/COARSE LOCATION, POST_NOTIFICATIONS. Chỉ xin quyền khi người dùng thực hiện thao tác tương ứng; không xin vị trí nền/microphone. |

Các ngưỡng 10.000 người, 5 ảnh, 10 MB/1 MB, 100 m, 500 m, 10 phút và độ tương tự nội dung 65% là quy tắc bản mẫu đang dùng; chúng không xuất phát từ con số cụ thể trong bảng US. Cần trình bày với giảng viên như quyết định thiết kế, không ghi là yêu cầu gốc đã quy định.

## Kết quả xác minh

- `flutter analyze --no-pub`: không có lỗi/cảnh báo.
- `flutter test --no-pub`: **40/40 đạt**, gồm thêm kiểm thử khôi phục camera, Android Back, ràng buộc nhóm người, JPEG hỏng và duyệt lại yêu cầu.
- `flutter build apk --debug --no-pub`: thành công. APK nằm ở `build/app/outputs/flutter-apk/app-debug.apk`.
- Bài kiểm thử thiết bị nằm tại `integration_test/android_request_flow_test.dart`. AVD tên `Pixel_API_36` nhưng image cài thực tế là **API 37**, đã kiểm tra bằng `getprop ro.build.version.sdk`.
- Đã chạy đạt trên AVD: gửi từ giao diện → lưu dữ liệu qua plugin Android → reload từ nền tảng → đọc lại → quản trị yêu cầu bổ sung; camera hệ thống chụp và trả ảnh về Flutter, xử lý JPEG có dấu (kết quả thử 35.634 byte, không phải ảnh mẫu).
- Lượt thử đầy đủ ban đầu: 2 trường hợp trên đạt; GPS chưa trả fix trong thời hạn. Không coi lượt đó là toàn bộ integration test đã đạt. **Lượt GPS riêng sau khi bổ sung provider dự phòng đã đạt**, trả về `20.8841, 105.6214983` khi bơm tọa độ thử nghiệm `20.8841, 105.6215` vào AVD. Log xác nhận `ANDROID_GPS_OK` và `All tests passed!`. Đây là plugin/location service Android thật với tín hiệu mô phỏng của AVD, không phải đo GPS trên điện thoại thật.
- Máy ảo từng treo System UI/mất kết nối; đã giảm độ phân giải, tắt Vulkan để thử lại. Máy cũng hết ổ C trong một lượt build; đã dọn thư mục build/cache sinh tự động đúng dự án. Đây là các điều kiện môi trường kiểm thử được ghi riêng, không che thành kết quả chức năng đạt.

Các case thiết bị được xác nhận qua hai lượt chạy: luồng lưu/gửi/xác minh và camera hệ thống ở lượt đầu; GPS ở lượt riêng cuối. Không ghi là một lượt 3/3 liền mạch. Vòng kiểm tra mã cuối: `flutter analyze` sạch và `flutter test` 40/40 đạt. APK bàn giao được build lại với target **`lib/main.dart`**, không dùng APK chứa entrypoint integration test.

Để lặp kiểm thử thiết bị: mở AVD, chạy `flutter test --no-pub --no-enable-impeller integration_test/android_request_flow_test.dart -d <device-id> --dart-define=ANDROID_CAMERA_TEST=true`. Bài test chờ cấp quyền cho app trong tối đa 40 giây sau marker `ANDROID_PERMISSION_SETUP_READY`; fixture AVD cần bơm GPS khi đang lấy vị trí. Case camera cần bấm chụp/xác nhận ở camera hệ thống. Các thiết lập này thuộc bài kiểm thử, không thay thế luồng người dùng cấp quyền trong ứng dụng.

## Bổ sung: lỗi dữ liệu khi mở APK thông thường

Người dùng phát hiện dòng `No instance with no name has been registered` trên trang chủ của APK chạy độc lập. Log truy về `SharedPreferencesApiForNativeInterop.getInstance` của `shared_preferences_android 2.5.4`. Các case integration trước đó chưa bao phủ đầy đủ cách khởi động này, nên không thể dùng kết quả cũ để khẳng định APK độc lập không có lỗi.

Đã cố định backend Android ở `shared_preferences_android: 2.4.28` (MethodChannel, trước đợt chuyển sang JNI), giữ API `shared_preferences` và định dạng dữ liệu hiện có. Không xóa dữ liệu app hoặc sửa nghiệp vụ sprint trước. Thông báo lỗi không xác định trong vùng yêu cầu được đổi sang tiếng Việt, không đưa lỗi kỹ thuật thô ra giao diện.

Xác minh lại trên chính APK `lib/main.dart` cài bằng `adb install -r` vào AVD thông thường:

- Đăng nhập Người dân → trang chủ: thấy CR-0247 và bản nháp, không còn lỗi registry.
- Mở tab Yêu cầu → DRAFT-0001 → tiếp tục → lưu lại nguyên nội dung: có thông báo lưu thành công.
- Đọc file SharedPreferences của Android: DRAFT-0001 có revision 1, lịch sử `Lưu bản nháp`, xác nhận thực sự ghi xuống bộ nhớ.
- Force-stop rồi mở lại app, đăng nhập lại: yêu cầu và bản nháp tải được; log của tiến trình mới không có lỗi registry hoặc unhandled exception.
- Sau thay dependency: phân tích mã sạch, 40/40 kiểm thử đạt; build APK thành công và đã cài lại lên máy ảo, giữ dữ liệu hiện có.

## Giới hạn phải trình bày đúng khi nộp

- Đây là bản mẫu dữ liệu lưu trên thiết bị. Chuyển vai trò mẫu trên cùng app thấy cùng dữ liệu; **hai điện thoại khác nhau chưa đồng bộ**.
- US-035 chưa đối chiếu được giờ máy chủ độc lập. Thời điểm tiếp nhận đang mô phỏng bằng đồng hồ thiết bị.
- US-037 là thông báo lưu/hiển thị trong app; chưa có push hoặc thông báo nền. Xin quyền thông báo hệ thống không đồng nghĩa đã có dịch vụ push.
- Phân quyền và chủ sở hữu dùng định danh mẫu; chưa có xác thực/token và kiểm tra quyền phía server.
- Camera/GPS trên máy ảo không thay thế việc kiểm tra một điện thoại thật. Đặc biệt nên thử từ chối quyền, tắt GPS, xoay màn hình và Android hủy Activity khi chụp.

Vì vậy có thể trình bày là **sprint chức năng Android dùng dữ liệu mẫu**, chưa được mô tả là hệ thống cứu trợ có backend, giờ server và push hoàn chỉnh.

Tham khảo chính thức về vòng đời camera Android: [image_picker — Handling MainActivity destruction](https://pub.dev/packages/image_picker). Manifest và luồng xin vị trí đối chiếu với [geolocator](https://pub.dev/packages/geolocator).

## Kiểm tra nhanh trong Android Studio trước buổi nộp

1. Mở thư mục `Frontend` như một Flutter project, chọn Android emulator/điện thoại, chạy `lib/main.dart`.
2. Người dân → Yêu cầu → mở CR-0247, sửa số người/nhu cầu, đi qua đủ bốn bước, kiểm tra lại và gửi cập nhật.
3. Chọn vị trí bằng GPS rồi thử ghim lại; kiểm tra nguồn vị trí và số tọa độ thay đổi đúng.
4. Chụp ảnh thật, xem dấu giờ/GPS, bỏ ảnh/chụp lại; thử từ chối camera và xác nhận vẫn có thể gửi với cảnh báo.
5. Lưu nháp, tắt/mở app và mở lại; kiểm tra đủ nhóm ưu tiên, mô tả, vị trí và ảnh.
6. Bấm Back Android ở các bước; ở bước đầu đang sửa phải có xác nhận rời biểu mẫu.
7. Hủy CR-0247: chọn Giữ yêu cầu thì không đổi, chọn Xác nhận hủy thì mới kết thúc. Sau đó gửi mới từ bản nháp và kiểm tra mã mới.
8. Đăng xuất bằng luồng có sẵn, chọn Quản trị → Yêu cầu; đánh dấu Cần bổ sung có lý do. Trở lại Người dân để kiểm tra lý do và thông báo.
9. Thử giá trị không hợp lệ: bỏ hết loại hỗ trợ, thiếu mô tả/mức khẩn cấp, nhóm người vượt tổng, thiếu cả địa chỉ và chỉ dẫn, tọa độ ngoài miền; phải báo lỗi, không tạo yêu cầu mới.
