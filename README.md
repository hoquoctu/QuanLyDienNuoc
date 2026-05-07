# quanlydiennc_app

A new Flutter project.
# QuanLyDienNuoc
TÊN DỰ ÁN: Ứng dụng Quản lý Hóa đơn Điện Nước (Utility Billing System)
1. Mô tả tổng quan (Project Overview)
Đây là ứng dụng di động hỗ trợ các chủ nhà trọ, ban quản lý chung cư hoặc người cho thuê mặt bằng tự động hóa quy trình ghi nhận chỉ số tiêu thụ, tính toán chi phí và quản lý trạng thái thanh toán hóa đơn điện nước hàng tháng. Ứng dụng giúp giảm thiểu sai sót do ghi chép thủ công, minh bạch hóa chi phí với người thuê và tiết kiệm thời gian vận hành.

2. Các tính năng chính (Core Features)
Dành cho Quản lý (Admin/Chủ nhà):

Quản lý danh mục: Tạo và quản lý danh sách khu vực, dãy trọ, số phòng và thông tin người thuê.

Thiết lập đơn giá: Cấu hình giá điện, giá nước theo mức giá cố định hoặc theo bậc thang (nếu có).

Ghi nhận chỉ số (Meter Reading): Giao diện nhập liệu nhanh chỉ số điện/nước cũ và mới của từng tháng. Tự động kiểm tra tính hợp lệ (chỉ số mới phải lớn hơn hoặc bằng chỉ số cũ).

Tính toán & Xuất hóa đơn: Tự động tính thành tiền dựa trên lượng tiêu thụ và đơn giá đã thiết lập. Khởi tạo hóa đơn chi tiết (bao gồm cả các phụ phí khác nếu cần như rác, wifi).

Quản lý thanh toán: Theo dõi trạng thái hóa đơn (Chưa thanh toán, Đã thanh toán một phần, Đã hoàn tất).

Báo cáo thống kê: Biểu đồ trực quan hóa doanh thu hàng tháng và xu hướng tiêu thụ điện/nước.

Dành cho Người thuê (Tenant - Tùy chọn mở rộng):

Xem hóa đơn: Nhận thông báo hóa đơn mới, xem chi tiết chỉ số và số tiền cần đóng.

Lịch sử tiêu thụ: Theo dõi biểu đồ sử dụng điện nước của các tháng trước để tự cân đối chi tiêu.

3. Kiến trúc hệ thống & Công nghệ (Tech Stack)
Để đảm bảo hiệu năng và dễ dàng mở rộng, hệ thống có thể được triển khai với cấu trúc sau:

Mobile App (Frontend):

Sử dụng Flutter và ngôn ngữ Dart để phát triển ứng dụng đa nền tảng (Android/iOS) với giao diện mượt mà.

Sử dụng Riverpod hoặc Provider để quản lý State, đảm bảo luồng dữ liệu khi nhập chỉ số điện nước cập nhật realtime lên UI.

Backend System:

Xây dựng hệ thống RESTful API với Spring Boot (hoặc PHP) để xử lý các logic tính toán phức tạp (như tính giá bậc thang) nhằm giảm tải cho thiết bị di động.

Cơ sở dữ liệu (Database):

Thiết kế kiến trúc quan hệ bằng công cụ DBML trước khi triển khai SQL. Các bảng chính sẽ bao gồm: Rooms, Tenants, MeterReadings, PricingTiers, và Invoices.

Kiểm thử & Quản lý:

Quản lý mã nguồn qua Git/GitHub.

Viết kịch bản kiểm thử (Test cases) chặt chẽ cho phần logic tính tiền để đảm bảo không có sai sót về tài chính.
