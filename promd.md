# Prompt cho Copilot: build và deploy ứng dụng vào `docs/`

Bạn là Copilot coding agent đang làm việc trực tiếp trong IDE với repository AXIOLEDGER. Hãy kiểm tra mã nguồn hiện tại và **thực hiện thay đổi**, không chỉ đưa ra hướng dẫn.

## Mục tiêu

Bổ sung các lệnh tại `package.json` ở thư mục gốc để build lại các ứng dụng phù hợp trong `apps/*` và xuất sản phẩm build vào `docs/`, sao cho mỗi ứng dụng có URL tương đối bắt đầu bằng `./` và có thể chạy dưới một đường dẫn con trên GitHub Pages.

## Trước khi sửa

1. Đọc `package.json`, `pnpm-workspace.yaml`, `turbo.json` và cấu hình build của từng app trong `apps/*`.
2. Xác định ứng dụng nào có thể xuất thành static site. Đặc biệt kiểm tra Next.js routes, API routes, middleware, image optimization, server actions và tính năng cần server runtime.
3. Không giả định tất cả thư mục `apps/*` đều là ứng dụng web tĩnh. Có thể có app server-side, service, thư mục thiếu `package.json`, hoặc chưa có cấu hình build.

## Yêu cầu triển khai

- Thêm script ở root `package.json` với tên dễ hiểu, ví dụ `rebuild:apps` hoặc `deploy:apps:docs`, để người dùng có thể chạy một lệnh bằng pnpm.
- Build các app có khả năng static export theo dependency order/workspace hiện có; dùng Turbo hoặc pnpm workspace filter nếu phù hợp.
- Mỗi app phải được xuất vào một thư mục riêng dưới `docs/` (ví dụ `docs/<app-name>/`) để tránh ghi đè lẫn nhau.
- Cấu hình asset/base path tương đối (`./`) hoặc cấu hình base path tương thích GitHub Pages cho từng app. Không sửa URL của toàn bộ website bằng thao tác thay thế chuỗi mù quáng; ưu tiên cấu hình chính thức của framework.
- Tạo hoặc cập nhật trang chỉ mục trong `docs/index.html` để liệt kê các app đã deploy và liên kết tương đối tới từng app. Nếu website hiện có trang chỉ mục cần được giữ lại, không ghi đè nội dung không liên quan.
- Script phải an toàn khi chạy lại: dọn đúng thư mục output do script quản lý, không xóa toàn bộ `docs/` và không xóa tài liệu/asset không thuộc quá trình deploy.
- Báo lỗi rõ ràng nếu app được yêu cầu deploy nhưng thiếu script build hoặc không có output hợp lệ. Không âm thầm bỏ qua build thất bại.
- Với app cần server runtime, ghi rõ lý do không thể xuất lên GitHub Pages tĩnh; không tạo bản deploy giả hoặc đưa link tới output chưa được sinh.
- Ưu tiên script Node.js hoặc shell script nhỏ có kiểm tra lỗi, xử lý tên/thư mục có khoảng trắng an toàn, và chạy được trên môi trường repository hỗ trợ. Không thêm dependency mới nếu không cần thiết.
- Chỉ thay đổi các file cần thiết. Không thực hiện deploy lên hosting/remote và không commit thay mặt người dùng.

## Kiểm tra

1. Xác thực JSON của `package.json` và chạy formatter/lint phù hợp nếu cấu hình repository hỗ trợ.
2. Chạy script mới hoặc kiểm tra từng bước có thể chạy an toàn trong môi trường hiện tại.
3. Kiểm tra output static có `index.html`, asset dùng URL tương đối, liên kết từ `docs/index.html` đúng và không tạo đường dẫn tuyệt đối sai như `/ _next` (không có khoảng trắng) hoặc `/_next` cho GitHub Pages ở đường dẫn con.
4. Nếu không thể chạy build do thiếu dependency, secrets, hoặc app lỗi sẵn có, nêu chính xác giới hạn và vẫn hoàn tất kiểm tra tĩnh.

## Kết quả cần báo cáo

- Liệt kê file đã thay đổi và mô tả ngắn gọn.
- Đưa lệnh build/deploy mới và cách chạy.
- Liệt kê app nào được xuất tĩnh, app nào không tương thích GitHub Pages tĩnh và nguyên nhân.
- Nêu các kiểm tra đã chạy và kết quả; không khẳng định thành công nếu chưa chạy.
