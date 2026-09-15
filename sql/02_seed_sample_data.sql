-- ============================================================================
-- DU AN: HE THONG CSDL QUAN LY & DAT PHONG CHUOI KHACH SAN (HOTEL BOOKING DB)
-- FILE: 02_seed_sample_data.sql
-- MO TA: Nap du lieu mau phong phu phan anh nghiep vu thuc te tai Viet Nam
-- ============================================================================

USE HotelBookingDB;
GO

-- 1. CHEN DU LIEU CHI NHANH (Branches)
SET IDENTITY_INSERT Branches ON;
INSERT INTO Branches (BranchID, BranchName, City, Address, Phone, Email, Rating) VALUES
(1, N'Imperial Saigon Grand Hotel', N'TP Ho Chi Minh', N'128 Dong Khoi, Quan 1', '02838221122', 'saigon@imperialhotel.vn', 4.9),
(2, N'Imperial Hanoi Royal Palace', N'Ha Noi', N'45 Trang Tien, Quan Hoan Kiem', '02439332211', 'hanoi@imperialhotel.vn', 4.8),
(3, N'Imperial Danang Beach Resort', N'Da Nang', N'268 Vo Nguyen Giap, Quan Ngu Hanh Son', '02363844555', 'danang@imperialhotel.vn', 4.9),
(4, N'Imperial Nha Trang Oceanfront', N'Nha Trang', N'78 Tran Phu, Phuong Loc Tho', '02583855666', 'nhatrang@imperialhotel.vn', 4.7),
(5, N'Imperial Phu Quoc Sunset Resort', N'Phu Quoc', N'Bai Truong, Duong To', '02973866777', 'phuquoc@imperialhotel.vn', 5.0);
SET IDENTITY_INSERT Branches OFF;
GO

-- 2. CHEN DU LIEU LOAI PHONG (RoomTypes)
SET IDENTITY_INSERT RoomTypes ON;
INSERT INTO RoomTypes (RoomTypeID, TypeName, BasePricePerNight, Capacity, BedType, Description) VALUES
(1, N'Standard Twin', 800000, 2, N'2 Single Beds', N'Phong tieu chuan 2 giuong don, phu hop cong tac'),
(2, N'Superior King', 1200000, 2, N'1 King Bed', N'Phong cao cap 1 giuong lon, ban cong huong pho'),
(3, N'Deluxe Ocean View', 1800000, 2, N'1 King Bed', N'Phong sang trong huong bien truc dien, bon tam nam'),
(4, N'Executive Suite', 3200000, 3, N'1 King + 1 Sofa Bed', N'Phong Suite co phong khach rieng, dac quyen Lounge'),
(5, N'Family Two-Bedroom', 2800000, 4, N'1 King + 2 Single Beds', N'Phong gia dinh 2 phong ngu lien thong rong rai'),
(6, N'Presidential Luxury Penthouse', 8500000, 6, N'2 King Beds + Jacuzzi', N'Penthouse tong thong dinh cao, ho boi vo cuc rieng');
SET IDENTITY_INSERT RoomTypes OFF;
GO

-- 3. CHEN DU LIEU PHONG (Rooms)
SET IDENTITY_INSERT Rooms ON;
INSERT INTO Rooms (RoomID, BranchID, RoomTypeID, RoomNumber, Floor, Status) VALUES
-- Chi nhanh 1: Saigon (RoomID 1 -> 6)
(1, 1, 1, '101', 1, N'Available'),
(2, 1, 2, '201', 2, N'Occupied'),
(3, 1, 3, '301', 3, N'Available'),
(4, 1, 4, '401', 4, N'Occupied'),
(5, 1, 5, '501', 5, N'Available'),
(6, 1, 6, '601', 6, N'Available'),

-- Chi nhanh 2: Hanoi (RoomID 7 -> 12)
(7, 2, 1, '102', 1, N'Available'),
(8, 2, 2, '202', 2, N'Available'),
(9, 2, 3, '302', 3, N'Occupied'),
(10, 2, 4, '402', 4, N'Available'),
(11, 2, 5, '502', 5, N'Maintenance'),
(12, 2, 6, '602', 6, N'Available'),

-- Chi nhanh 3: Danang (RoomID 13 -> 18)
(13, 3, 1, '103', 1, N'Available'),
(14, 3, 2, '203', 2, N'Available'),
(15, 3, 3, '303', 3, N'Occupied'),
(16, 3, 3, '304', 3, N'Available'),
(17, 3, 4, '403', 4, N'Available'),
(18, 3, 6, '603', 6, N'Occupied'),

-- Chi nhanh 4: Nha Trang (RoomID 19 -> 24)
(19, 4, 1, '104', 1, N'Available'),
(20, 4, 2, '204', 2, N'Available'),
(21, 4, 3, '305', 3, N'Available'),
(22, 4, 4, '404', 4, N'Maintenance'),
(23, 4, 5, '504', 5, N'Available'),
(24, 4, 6, '604', 6, N'Available'),

-- Chi nhanh 5: Phu Quoc (RoomID 25 -> 30)
(25, 5, 2, '205', 2, N'Available'),
(26, 5, 3, '306', 3, N'Occupied'),
(27, 5, 3, '307', 3, N'Available'),
(28, 5, 4, '405', 4, N'Available'),
(29, 5, 5, '505', 5, N'Available'),
(30, 5, 6, '605', 6, N'Available');
SET IDENTITY_INSERT Rooms OFF;
GO

-- 4. CHEN DU LIEU KHACH HANG (Customers)
SET IDENTITY_INSERT Customers ON;
INSERT INTO Customers (CustomerID, FullName, IdentityCard, Phone, Email, LoyaltyTier, TotalPoints) VALUES
(1, N'Nguyen Tuan Khang', '079204001122', '0901234567', 'khang.nguyen@gmail.com', N'VIP', 1250),
(2, N'Tran Minh Duc', '079204003344', '0918765432', 'duc.tran@gmail.com', N'Gold', 680),
(3, N'Le Thi Mai Huong', '079204005566', '0983334444', 'huong.le@yahoo.com', N'Silver', 220),
(4, N'Pham Hoang Long', '079204007788', '0975556666', 'long.pham@outlook.com', N'VIP', 2100),
(5, N'Doan Bao Chau', '079204009900', '0934447777', 'chau.doan@gmail.com', N'Gold', 790),
(6, N'Hoang Gia Huy', '079204011122', '0908889999', 'huy.hoang@company.vn', N'Standard', 40),
(7, N'Dang Thuy Tien', '079204013344', '0912223333', 'tien.dang@gmail.com', N'Silver', 180),
(8, N'Bui Van Nam', '079204015566', '0987778888', 'nam.bui@gmail.com', N'Standard', 0),
(9, N'Vu Quoc Anh', '079204017788', '0963332211', 'anh.vu@techcorp.vn', N'Standard', 50),
(10, N'Cao Thi Kim Ngan', '079204019900', '0945551122', 'ngan.cao@gmail.com', N'Gold', 540);
SET IDENTITY_INSERT Customers OFF;
GO

-- 5. CHEN DU LIEU DANH MUC DICH VU (Services)
SET IDENTITY_INSERT Services ON;
INSERT INTO Services (ServiceID, ServiceName, Category, UnitPrice, Unit) VALUES
(1, N'Buffet Sang Quoc Te', N'Dining', 350000, N'Suat'),
(2, N'Set Menu Hai San Hoang Gia', N'Dining', 850000, N'Set'),
(3, N'Massage Toan Than Tinh Dau Thao Duoc', N'Spa', 600000, N'Suat 60 phut'),
(4, N'Goi Cham Soc Da Mat Chuyen Sau', N'Spa', 450000, N'Suat 45 phut'),
(5, N'Dua Don San Bay Xe Limousine', N'Transport', 500000, N'Chuyen'),
(6, N'Thue Xe May Tay Ga Theo Ngay', N'Transport', 180000, N'Ngay'),
(7, N'Giat Ui Quan Ao Lay Lien', N'Laundry', 120000, N'Kg'),
(8, N'Set Tra Chieu Hoang Gia', N'Dining', 250000, N'Set 2 nguoi'),
(9, N'Tour Lan Bien Ngam San Ho', N'Entertainment', 950000, N'Nguoi'),
(10, N'Dich Vu Trang Tri Phong Sinh Nhat / Honeymoon', N'Entertainment', 500000, N'Goi');
SET IDENTITY_INSERT Services OFF;
GO

-- 6. CHEN DU LIEU DON DAT PHONG (Bookings)
SET IDENTITY_INSERT Bookings ON;
INSERT INTO Bookings (BookingID, CustomerID, BranchID, BookingDate, CheckInDate, CheckOutDate, TotalAmount, DepositAmount, BookingStatus, Notes) VALUES
(1, 1, 1, '2026-08-01 10:00:00', '2026-08-10', '2026-08-13', 3600000, 1000000, N'CheckedOut', N'Khach VIP yeu cau phong tang cao'),
(2, 2, 2, '2026-08-05 14:30:00', '2026-08-15', '2026-08-18', 3600000, 1000000, N'CheckedOut', N'Di cong tac'),
(3, 4, 3, '2026-08-12 09:15:00', '2026-08-20', '2026-08-24', 34000000, 10000000, N'CheckedOut', N'Nghi duong gia dinh Penthouse'),
(4, 5, 1, '2026-08-25 16:00:00', '2026-09-01', '2026-09-04', 9600000, 3000000, N'CheckedOut', N'Ky niem ngay cuoi'),
(5, 3, 4, '2026-09-01 11:20:00', '2026-09-10', '2026-09-13', 5400000, 2000000, N'CheckedOut', N'Huong bien'),
-- Cac don dang luu tru hien tai (CheckedIn)
(6, 1, 1, '2026-09-10 08:00:00', '2026-09-14', '2026-09-17', 3600000, 1500000, N'CheckedIn', N'Phong 201 Saigon'),
(7, 2, 2, '2026-09-11 15:00:00', '2026-09-14', '2026-09-16', 3600000, 1500000, N'CheckedIn', N'Phong 302 Hanoi'),
(8, 4, 3, '2026-09-12 10:45:00', '2026-09-15', '2026-09-19', 34000000, 10000000, N'CheckedIn', N'Phong 603 Danang'),
(9, 7, 5, '2026-09-12 12:00:00', '2026-09-15', '2026-09-18', 5400000, 2000000, N'CheckedIn', N'Phong 306 Phu Quoc'),
-- Cac don da dat truoc trong tuong lai (Confirmed)
(10, 6, 1, '2026-09-14 09:30:00', '2026-09-25', '2026-09-27', 1600000, 500000, N'Confirmed', N'Dat phong cho nguoi nha'),
(11, 10, 3, '2026-09-14 14:00:00', '2026-10-01', '2026-10-05', 7200000, 2000000, N'Confirmed', N'Honeymoon Da Nang'),
(12, 8, 4, '2026-09-15 08:30:00', '2026-10-10', '2026-10-12', 1600000, 500000, N'Cancelled', N'Khach huy do ban dot xuat');
SET IDENTITY_INSERT Bookings OFF;
GO

-- 7. CHEN DU LIEU CHI TIET PHONG DAT (BookingRooms)
INSERT INTO BookingRooms (BookingID, RoomID, PricePerNight, Nights) VALUES
(1, 2, 1200000, 3),   -- Booking 1: Phong 201 (Superior King) 3 dem
(2, 8, 1200000, 3),   -- Booking 2: Phong 202 (Superior King) 3 dem
(3, 18, 8500000, 4),  -- Booking 3: Phong 603 (Penthouse) 4 dem
(4, 4, 3200000, 3),   -- Booking 4: Phong 401 (Executive Suite) 3 dem
(5, 21, 1800000, 3),  -- Booking 5: Phong 305 (Deluxe Ocean View) 3 dem
(6, 2, 1200000, 3),   -- Booking 6: Phong 201 3 dem
(7, 9, 1800000, 2),   -- Booking 7: Phong 302 2 dem
(8, 18, 8500000, 4),  -- Booking 8: Phong 603 4 dem
(9, 26, 1800000, 3),  -- Booking 9: Phong 306 3 dem
(10, 1, 800000, 2),   -- Booking 10: Phong 101 2 dem
(11, 15, 1800000, 4), -- Booking 11: Phong 303 4 dem
(12, 19, 800000, 2);  -- Booking 12: Phong 104 2 dem
GO

-- 8. CHEN DU LIEU SU DUNG DICH VU (ServiceOrders)
SET IDENTITY_INSERT ServiceOrders ON;
INSERT INTO ServiceOrders (OrderID, BookingID, ServiceID, OrderDate, Quantity, UnitPrice) VALUES
(1, 1, 1, '2026-08-11 07:30:00', 2, 350000),  -- Buffet sang x2
(2, 1, 5, '2026-08-10 14:00:00', 1, 500000),  -- Don san bay
(3, 2, 7, '2026-08-16 10:00:00', 3, 120000),  -- Giat ui 3kg
(4, 3, 2, '2026-08-21 19:00:00', 4, 850000),  -- Set hai san x4
(5, 3, 3, '2026-08-22 15:30:00', 2, 600000),  -- Spa tinh dau x2
(6, 3, 5, '2026-08-20 11:00:00', 2, 500000),  -- Xe Limousine x2 chuyen
(7, 4, 8, '2026-09-02 16:00:00', 1, 250000),  -- Tra chieu
(8, 4, 10, '2026-09-01 14:00:00', 1, 500000), -- Trang tri ky niem
(9, 5, 9, '2026-09-11 08:30:00', 2, 950000),  -- Lan bien x2
(10, 6, 1, '2026-09-15 07:00:00', 2, 350000), -- Buffet sang
(11, 8, 3, '2026-09-15 16:00:00', 2, 600000), -- Spa Penthouse
(12, 9, 6, '2026-09-15 09:00:00', 1, 180000); -- Thue xe may
SET IDENTITY_INSERT ServiceOrders OFF;
GO

-- 9. CHEN DU LIEU HOA DON (Invoices)
SET IDENTITY_INSERT Invoices ON;
INSERT INTO Invoices (InvoiceID, BookingID, InvoiceDate, RoomCharge, ServiceCharge, DiscountAmount, TaxAmount, FinalAmount, PaymentMethod, PaymentStatus) VALUES
-- Booking 1: Khach VIP (giam 15% tien phong)
(1, 1, '2026-08-13 11:30:00', 3600000, 1200000, 540000, 340800, 4600800, N'CreditCard', N'Paid'),
-- Booking 2: Khach Gold (giam 10% tien phong)
(2, 2, '2026-08-18 12:00:00', 3600000, 360000, 360000, 288000, 3888000, N'BankTransfer', N'Paid'),
-- Booking 3: Khach VIP Penthouse
(3, 3, '2026-08-24 11:45:00', 34000000, 5600000, 5100000, 2760000, 37260000, N'CreditCard', N'Paid'),
-- Booking 4: Khach Gold
(4, 4, '2026-09-04 10:30:00', 9600000, 750000, 960000, 751200, 10141200, N'EWallet', N'Paid'),
-- Booking 5: Khach Silver (giam 5% tien phong)
(5, 5, '2026-09-13 12:15:00', 5400000, 1900000, 270000, 562400, 7592400, N'Cash', N'Paid');
SET IDENTITY_INSERT Invoices OFF;
GO

PRINT '>>> [THANH CONG] Da nap toan bo du lieu mau thuc te vao he thong!';
GO
