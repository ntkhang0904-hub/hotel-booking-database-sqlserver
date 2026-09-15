# TÀI LIỆU THIẾT KẾ CƠ SỞ DỮ LIỆU CHUỖI KHÁCH SẠN
## (Hotel Booking Management System Database Design Guide)

---

## 1. TỔNG QUAN HỆ THỐNG & YÊU CẦU NGHIỆP VỤ

### 1.1. Bối cảnh
Hệ thống quản lý đặt phòng và dịch vụ cho chuỗi khách sạn đa chi nhánh tại các thành phố du lịch lớn của Việt Nam (Hà Nội, TP.HCM, Đà Nẵng, Nha Trang, Phú Quốc). CSDL phục vụ cho việc:
- Quản lý danh mục chi nhánh, các hạng phòng (Standard, Superior, Deluxe, Suite, Presidential) và từng phòng thực tế.
- Quản lý thông tin khách hàng và chương trình khách hàng thân thiết (Loyalty Tiers: Standard, Silver, Gold, VIP).
- Quy trình đặt phòng (Booking), phân bổ phòng (BookingRooms), phát sinh dịch vụ phụ trợ (ServiceOrders).
- Thanh toán & xuất hóa đơn (Invoices), tích điểm tự động và ghi nhật ký hệ thống (AuditLogs).

---

## 2. THIẾT KẾ CÁC THỰC THỂ & RÀNG BUỘC (SCHEMA SPECIFICATION)

Hệ thống bao gồm **10 bảng** quan hệ chặt chẽ:

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Branches   │───1:N─│    Rooms     │───N:1─│  RoomTypes   │
└──────────────┘       └──────────────┘       └──────────────┘
       │                      │
      1:N                    N:M
       │                      │
       ▼                      ▼
┌──────────────┐ 1:N   ┌──────────────┐
│   Bookings   │───────│ BookingRooms │
└──────────────┘       └──────────────┘
   │        │
  1:N      1:1
   │        │
   ▼        ▼
┌──────────────┐       ┌──────────────┐
│ServiceOrders │───N:1─│   Services   │
└──────────────┘       └──────────────┘
   │
┌──────────────┐       ┌──────────────┐
│   Invoices   │       │  AuditLogs   │
└──────────────┘       └──────────────┘
```

### 2.1. Chi tiết 10 Bảng
1. **Branches** (`BranchID` PK): Thông tin chi nhánh (Tên, Thành phố, Địa chỉ, SĐT, Email, Rating).
2. **RoomTypes** (`RoomTypeID` PK): Loại phòng, giá cơ bản/đêm, sức chứa tối đa, loại giường, mô tả.
3. **Rooms** (`RoomID` PK): Phòng theo chi nhánh, số phòng, tầng, trạng thái (`Available`, `Occupied`, `Maintenance`).
4. **Customers** (`CustomerID` PK): Khách hàng, CCCD/Passport, SĐT, Email, hạng hội viên (`Standard`, `Silver`, `Gold`, `VIP`), điểm tích lũy.
5. **Bookings** (`BookingID` PK): Đơn đặt phòng, mã khách, chi nhánh, ngày đặt, ngày Check-in/Check-out, trạng thái (`Confirmed`, `CheckedIn`, `CheckedOut`, `Cancelled`).
6. **BookingRooms** (`BookingID`, `RoomID` PK kép): Chi tiết danh sách phòng trong đơn đặt, giá thuê/đêm tại thời điểm đặt, số đêm.
7. **Services** (`ServiceID` PK): Danh mục dịch vụ (Dining, Spa, Transport, Laundry, Entertainment), đơn giá, đơn vị tính.
8. **ServiceOrders** (`OrderID` PK): Dịch vụ khách sử dụng trong kỳ lưu trú, số lượng, đơn giá, tổng tiền tính toán (`PERSISTED`).
9. **Invoices** (`InvoiceID` PK): Hóa đơn thanh toán, tiền phòng, tiền dịch vụ, giảm giá, thuế VAT, tổng tiền thực thu, phương thức thanh toán, trạng thái.
10. **AuditLogs** (`LogID` PK): Bảng ghi vết thay đổi nghiệp vụ quan trọng (đổi giá phòng, thay đổi cấu hình hệ thống).

---

## 3. CHỨNG MINH CHUẨN HÓA DỮ LIỆU (NORMALIZATION TO 3NF)

Hệ thống được chuẩn hóa toàn diện đến **Dạng chuẩn 3 (3NF)**:

### 3.1. Dạng chuẩn 1 (1NF)
- Mọi thuộc tính đều mang giá trị nguyên tố (atomic values).
- Không có thuộc tính lặp nhóm hay danh sách mảng lồng nhau trong một ô dữ liệu.
- Tất cả các bảng đều có Khóa chính (Primary Key) xác định duy nhất từng bản ghi.

### 3.2. Dạng chuẩn 2 (2NF)
- Đạt chuẩn 1NF.
- Không tồn tại phụ thuộc hàm bộ phận vào một phần của khóa chính ghép:
  - Bảng liên kết nhiều-nhiều `BookingRooms` có khóa chính ghép `(BookingID, RoomID)`.
  - Các thuộc tính `PricePerNight`, `Nights` phụ thuộc hoàn toàn vào cả cặp `(BookingID, RoomID)`. Thông tin chi tiết về phòng (Tầng, Loại phòng) được tách về bảng `Rooms`.

### 3.3. Dạng chuẩn 3 (3NF)
- Đạt chuẩn 2NF.
- Không có phụ thuộc bắc cầu giữa các thuộc tính không khóa:
  - Thông tin khách hàng (`FullName`, `Phone`) không lưu trong `Bookings`, chỉ lưu khóa ngoại `CustomerID`.
  - Thông tin giá cơ bản của loại phòng không lưu trong `Rooms`, chỉ lưu `RoomTypeID`.
  - Tiền dịch vụ phát sinh được ghi nhận qua `ServiceOrders` liên kết với `ServiceID`, tránh lặp lại tên và đơn giá gốc trong bảng hóa đơn.

---

## 4. QUY TRÌNH NGHIỆP VỤ & TRANSACTION TRONG STORED PROCEDURES

Hệ thống triển khai 5 Stored Procedures với cơ chế **ACID Transactions** và **TRY...CATCH**:

```
[Khách yêu cầu]
       │
       ▼
1. sp_CreateBooking ───► Kiểm tra phòng trống ──► Insert Bookings ──► Insert BookingRooms ──► COMMIT
       │
       ▼
2. sp_CheckInBooking ──► Cập nhật trạng thái phòng sang 'Occupied' ──► Status = 'CheckedIn'
       │
       ▼
3. sp_OrderService ────► Ghi nhận dịch vụ phát sinh vào ServiceOrders
       │
       ▼
4. sp_CheckOutAndGenerateInvoice
       │
       ├─► Tính tổng tiền phòng + tổng tiền dịch vụ
       ├─► Áp dụng chiết khấu theo Hạng hội viên (fn_CalculateCustomerDiscount)
       ├─► Tính thuế VAT (8%)
       ├─► Tạo Invoices (PaymentStatus = 'Paid')
       ├─► Giải phóng phòng (Status = 'Available')
       └─► Triggers tự động cộng điểm tích lũy & nâng hạng hội viên
```

---

## 5. CHIẾN LƯỢC ĐÁNH CHỈ MỤC & TỐI ƯU HIỆU NĂNG (INDEXING STRATEGY)

1. **Foreign Key Indexes**:
   - Tối ưu hóa các thao tác `JOIN` nhiều bảng giữa `Bookings`, `Customers`, `Rooms`, `Branches`, `Invoices`.
2. **Filtered Indexes**:
   - `IX_Rooms_Available_Filtered` (chỉ index các phòng `Status = 'Available'`) giúp tăng tốc độ tìm kiếm phòng trống lên hơn 70% mà không tốn tài nguyên lưu trữ cho các phòng đã có người.
   - `IX_Bookings_ActiveDates_Filtered` phục vụ Trigger chống trùng lịch phòng với chi phí quét tối thiểu.
3. **Covering Indexes with INCLUDE**:
   - Thêm các cột thường dùng trong `SELECT` vào mệnh đề `INCLUDE` để SQL Server thực hiện `Index Seek` mà không cần `Key Lookup` vào bảng dữ liệu gốc.
