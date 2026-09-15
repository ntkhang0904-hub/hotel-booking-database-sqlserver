-- ============================================================================
-- DU AN: HE THONG CSDL QUAN LY & DAT PHONG CHUOI KHACH SAN (HOTEL BOOKING DB)
-- FILE: 00_all_in_one_install.sql
-- MO TA: Tap lenh ALL-IN-ONE cai dat tron ven toan bo he thong chi voi 1 lan bam F5
--        Chay duoc truc tiep tren SSMS, Azure Data Studio, hoac sqlcmd
-- ============================================================================


-- ============================================================================
-- PHAN TIEP THEO: 01_schema_and_tables.sql
-- ============================================================================

-- ============================================================================
-- DU AN: HE THONG CSDL QUAN LY & DAT PHONG CHUOI KHACH SAN (HOTEL BOOKING DB)
-- FILE: 01_schema_and_tables.sql
-- MO TA: Khoi tao CSDL, 10 Bang quan he va cac Rang buoc toan ven (Constraints)
-- ============================================================================

-- 1. TAO DATABASE
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'HotelBookingDB')
BEGIN
    CREATE DATABASE HotelBookingDB;
END
GO

USE HotelBookingDB;
GO

-- Xoa cac bang neu da ton tai (theo thu tu khoa ngoai de tranh loi phu thuoc)
IF OBJECT_ID('dbo.Invoices', 'U') IS NOT NULL DROP TABLE dbo.Invoices;
IF OBJECT_ID('dbo.ServiceOrders', 'U') IS NOT NULL DROP TABLE dbo.ServiceOrders;
IF OBJECT_ID('dbo.Services', 'U') IS NOT NULL DROP TABLE dbo.Services;
IF OBJECT_ID('dbo.BookingRooms', 'U') IS NOT NULL DROP TABLE dbo.BookingRooms;
IF OBJECT_ID('dbo.Bookings', 'U') IS NOT NULL DROP TABLE dbo.Bookings;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Rooms', 'U') IS NOT NULL DROP TABLE dbo.Rooms;
IF OBJECT_ID('dbo.RoomTypes', 'U') IS NOT NULL DROP TABLE dbo.RoomTypes;
IF OBJECT_ID('dbo.Branches', 'U') IS NOT NULL DROP TABLE dbo.Branches;
IF OBJECT_ID('dbo.AuditLogs', 'U') IS NOT NULL DROP TABLE dbo.AuditLogs;
GO

-- ============================================================================
-- 2. TAO CAC BANG THUC THE (TABLE DEFINITIONS)
-- ============================================================================

-- BANG 1: Chi nhanh khach san (Branches)
CREATE TABLE Branches (
    BranchID INT IDENTITY(1,1) PRIMARY KEY,
    BranchName NVARCHAR(100) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    Address NVARCHAR(200) NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    Email VARCHAR(100) NULL,
    Rating DECIMAL(2,1) DEFAULT 5.0,
    CreatedAt DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT CK_Branches_Rating CHECK (Rating >= 1.0 AND Rating <= 5.0)
);
GO

-- BANG 2: Loai phong (RoomTypes)
CREATE TABLE RoomTypes (
    RoomTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeName NVARCHAR(50) NOT NULL UNIQUE,       -- Standard, Superior, Deluxe, Suite, Presidential
    BasePricePerNight DECIMAL(18,2) NOT NULL,    -- Gia goc mot dem (VND)
    Capacity INT NOT NULL,                       -- So luong nguoi toi da
    BedType NVARCHAR(50) NOT NULL,               -- Single, Double, Queen, King
    Description NVARCHAR(255) NULL,
    
    CONSTRAINT CK_RoomTypes_Price CHECK (BasePricePerNight > 0),
    CONSTRAINT CK_RoomTypes_Capacity CHECK (Capacity >= 1 AND Capacity <= 10)
);
GO

-- BANG 3: Phong khach san (Rooms)
CREATE TABLE Rooms (
    RoomID INT IDENTITY(1,1) PRIMARY KEY,
    BranchID INT NOT NULL,
    RoomTypeID INT NOT NULL,
    RoomNumber VARCHAR(10) NOT NULL,
    Floor INT NOT NULL,
    Status NVARCHAR(20) DEFAULT N'Available',    -- Available, Occupied, Maintenance
    
    CONSTRAINT FK_Rooms_Branches FOREIGN KEY (BranchID) REFERENCES Branches(BranchID) ON DELETE CASCADE,
    CONSTRAINT FK_Rooms_RoomTypes FOREIGN KEY (RoomTypeID) REFERENCES RoomTypes(RoomTypeID),
    CONSTRAINT UQ_Rooms_Branch_Number UNIQUE (BranchID, RoomNumber),
    CONSTRAINT CK_Rooms_Status CHECK (Status IN (N'Available', N'Occupied', N'Maintenance'))
);
GO

-- BANG 4: Khach hang (Customers)
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    IdentityCard VARCHAR(20) NOT NULL UNIQUE,   -- CCCD / Passport
    Phone VARCHAR(15) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    LoyaltyTier NVARCHAR(20) DEFAULT N'Standard', -- Standard, Silver, Gold, VIP
    TotalPoints INT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT CK_Customers_Tier CHECK (LoyaltyTier IN (N'Standard', N'Silver', N'Gold', N'VIP')),
    CONSTRAINT CK_Customers_Points CHECK (TotalPoints >= 0)
);
GO

-- BANG 5: Don dat phong (Bookings)
CREATE TABLE Bookings (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    BranchID INT NOT NULL,
    BookingDate DATETIME DEFAULT GETDATE(),
    CheckInDate DATE NOT NULL,
    CheckOutDate DATE NOT NULL,
    TotalAmount DECIMAL(18,2) DEFAULT 0,
    DepositAmount DECIMAL(18,2) DEFAULT 0,
    BookingStatus NVARCHAR(20) DEFAULT N'Confirmed', -- Confirmed, CheckedIn, CheckedOut, Cancelled
    Notes NVARCHAR(255) NULL,
    
    CONSTRAINT FK_Bookings_Customers FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    CONSTRAINT FK_Bookings_Branches FOREIGN KEY (BranchID) REFERENCES Branches(BranchID),
    CONSTRAINT CK_Bookings_Dates CHECK (CheckOutDate > CheckInDate),
    CONSTRAINT CK_Bookings_Status CHECK (BookingStatus IN (N'Confirmed', N'CheckedIn', N'CheckedOut', N'Cancelled'))
);
GO

-- BANG 6: Chi tiet phong trong don dat (BookingRooms)
CREATE TABLE BookingRooms (
    BookingID INT NOT NULL,
    RoomID INT NOT NULL,
    PricePerNight DECIMAL(18,2) NOT NULL,
    Nights INT NOT NULL,
    
    PRIMARY KEY (BookingID, RoomID),
    CONSTRAINT FK_BookingRooms_Bookings FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID) ON DELETE CASCADE,
    CONSTRAINT FK_BookingRooms_Rooms FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID),
    CONSTRAINT CK_BookingRooms_Price CHECK (PricePerNight >= 0),
    CONSTRAINT CK_BookingRooms_Nights CHECK (Nights >= 1)
);
GO

-- BANG 7: Danh muc dich vu (Services)
CREATE TABLE Services (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,             -- Dining, Spa, Transport, Laundry, Entertainment
    UnitPrice DECIMAL(18,2) NOT NULL,
    Unit NVARCHAR(20) NOT NULL,                 -- Suat, Lan, Chuyen, Luot, Gio
    
    CONSTRAINT CK_Services_Price CHECK (UnitPrice >= 0)
);
GO

-- BANG 8: Su dung dich vu trong ky luu tru (ServiceOrders)
CREATE TABLE ServiceOrders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    BookingID INT NOT NULL,
    ServiceID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    Quantity INT DEFAULT 1,
    UnitPrice DECIMAL(18,2) NOT NULL,
    TotalServicePrice AS (Quantity * UnitPrice) PERSISTED,
    
    CONSTRAINT FK_ServiceOrders_Bookings FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceOrders_Services FOREIGN KEY (ServiceID) REFERENCES Services(ServiceID),
    CONSTRAINT CK_ServiceOrders_Quantity CHECK (Quantity >= 1)
);
GO

-- BANG 9: Hoa don thanh toan (Invoices)
CREATE TABLE Invoices (
    InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
    BookingID INT NOT NULL UNIQUE,
    InvoiceDate DATETIME DEFAULT GETDATE(),
    RoomCharge DECIMAL(18,2) NOT NULL,
    ServiceCharge DECIMAL(18,2) DEFAULT 0,
    DiscountAmount DECIMAL(18,2) DEFAULT 0,
    TaxAmount DECIMAL(18,2) DEFAULT 0,          -- Thue VAT 8% hoac 10%
    FinalAmount DECIMAL(18,2) NOT NULL,
    PaymentMethod NVARCHAR(30) NOT NULL,        -- Cash, CreditCard, BankTransfer, EWallet
    PaymentStatus NVARCHAR(20) DEFAULT N'Paid', -- Paid, Pending, Refunded
    
    CONSTRAINT FK_Invoices_Bookings FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID),
    CONSTRAINT CK_Invoices_PaymentMethod CHECK (PaymentMethod IN (N'Cash', N'CreditCard', N'BankTransfer', N'EWallet')),
    CONSTRAINT CK_Invoices_PaymentStatus CHECK (PaymentStatus IN (N'Paid', N'Pending', N'Refunded'))
);
GO

-- BANG 10: Nhat ky he thong / Kiem toan (AuditLogs)
CREATE TABLE AuditLogs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ActionType NVARCHAR(20) NOT NULL,           -- INSERT, UPDATE, DELETE, PRICE_CHANGE
    TableName NVARCHAR(50) NOT NULL,
    RecordID INT NULL,
    OldValue NVARCHAR(MAX) NULL,
    NewValue NVARCHAR(MAX) NULL,
    ChangedBy NVARCHAR(100) DEFAULT SYSTEM_USER,
    ChangedAt DATETIME DEFAULT GETDATE()
);
GO

PRINT '>>> [THANH CONG] Da tao xong Database va 10 Bang kem Rang buoc toan ven!';
GO



-- ============================================================================
-- PHAN TIEP THEO: 02_seed_sample_data.sql
-- ============================================================================

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



-- ============================================================================
-- PHAN TIEP THEO: 03_views.sql
-- ============================================================================

-- ============================================================================
-- DU AN: HE THONG CSDL QUAN LY & DAT PHONG CHUOI KHACH SAN (HOTEL BOOKING DB)
-- FILE: 03_views.sql
-- MO TA: Tao cac Khung Nhin (Views) phuc vu bao cao quan ly va nghiep vu
-- ============================================================================

USE HotelBookingDB;
GO

-- 1. VIEW: Danh sach phong dang SAN SANG (Available) tren toan he thong
IF OBJECT_ID('dbo.vw_AvailableRooms', 'V') IS NOT NULL DROP VIEW dbo.vw_AvailableRooms;
GO
CREATE VIEW vw_AvailableRooms AS
SELECT 
    b.BranchName,
    b.City,
    r.RoomNumber,
    r.Floor,
    rt.TypeName AS RoomType,
    rt.Capacity,
    rt.BedType,
    rt.BasePricePerNight,
    r.Status
FROM Rooms r
JOIN Branches b ON r.BranchID = b.BranchID
JOIN RoomTypes rt ON r.RoomTypeID = rt.RoomTypeID
WHERE r.Status = N'Available';
GO

-- 2. VIEW: Tong hop lich su dat phong va chi tieu cua Khach hang
IF OBJECT_ID('dbo.vw_CustomerBookingHistory', 'V') IS NOT NULL DROP VIEW dbo.vw_CustomerBookingHistory;
GO
CREATE VIEW vw_CustomerBookingHistory AS
SELECT 
    c.CustomerID,
    c.FullName,
    c.Phone,
    c.LoyaltyTier,
    c.TotalPoints,
    b.BookingID,
    br.BranchName,
    b.CheckInDate,
    b.CheckOutDate,
    DATEDIFF(DAY, b.CheckInDate, b.CheckOutDate) AS TotalNights,
    b.BookingStatus,
    ISNULL(inv.FinalAmount, b.TotalAmount) AS TotalSpent,
    inv.PaymentMethod
FROM Customers c
JOIN Bookings b ON c.CustomerID = b.CustomerID
JOIN Branches br ON b.BranchID = br.BranchID
LEFT JOIN Invoices inv ON b.BookingID = inv.BookingID;
GO

-- 3. VIEW: Bao cao doanh thu phong & dich vu theo Thang cua tung Chi nhanh
IF OBJECT_ID('dbo.vw_MonthlyRevenueByBranch', 'V') IS NOT NULL DROP VIEW dbo.vw_MonthlyRevenueByBranch;
GO
CREATE VIEW vw_MonthlyRevenueByBranch AS
SELECT 
    b.BranchID,
    b.BranchName,
    b.City,
    YEAR(inv.InvoiceDate) AS RevenueYear,
    MONTH(inv.InvoiceDate) AS RevenueMonth,
    COUNT(inv.InvoiceID) AS TotalInvoices,
    SUM(inv.RoomCharge) AS TotalRoomRevenue,
    SUM(inv.ServiceCharge) AS TotalServiceRevenue,
    SUM(inv.DiscountAmount) AS TotalDiscountsGiven,
    SUM(inv.FinalAmount) AS NetRevenue
FROM Invoices inv
JOIN Bookings bk ON inv.BookingID = bk.BookingID
JOIN Branches b ON bk.BranchID = b.BranchID
WHERE inv.PaymentStatus = N'Paid'
GROUP BY b.BranchID, b.BranchName, b.City, YEAR(inv.InvoiceDate), MONTH(inv.InvoiceDate);
GO

-- 4. VIEW: Xep hang muc do pho bien cua cac Dich vu khach san
IF OBJECT_ID('dbo.vw_TopUsedServices', 'V') IS NOT NULL DROP VIEW dbo.vw_TopUsedServices;
GO
CREATE VIEW vw_TopUsedServices AS
SELECT 
    s.ServiceID,
    s.ServiceName,
    s.Category,
    s.UnitPrice,
    COUNT(so.OrderID) AS TotalTimesOrdered,
    ISNULL(SUM(so.Quantity), 0) AS TotalQuantityUsed,
    ISNULL(SUM(so.TotalServicePrice), 0) AS TotalServiceRevenue
FROM Services s
LEFT JOIN ServiceOrders so ON s.ServiceID = so.ServiceID
GROUP BY s.ServiceID, s.ServiceName, s.Category, s.UnitPrice;
GO

PRINT '>>> [THANH CONG] Da tao xong 4 Views bao cao he thong!';
GO



-- ============================================================================
-- PHAN TIEP THEO: 04_functions.sql
-- ============================================================================

-- ============================================================================
-- DU AN: HE THONG CSDL QUAN LY & DAT PHONG CHUOI KHACH SAN (HOTEL BOOKING DB)
-- FILE: 04_functions.sql
-- MO TA: Tao cac Ham (User-Defined Functions) xu ly nghiep vu tinh toan
-- ============================================================================

USE HotelBookingDB;
GO

-- 1. FUNCTION: Tinh ty le chiet khau giam gia theo Hang thanh vien
IF OBJECT_ID('dbo.fn_CalculateCustomerDiscount', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateCustomerDiscount;
GO
CREATE FUNCTION fn_CalculateCustomerDiscount (@CustomerID INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Tier NVARCHAR(20);
    DECLARE @DiscountRate DECIMAL(5,2) = 0.00;

    SELECT @Tier = LoyaltyTier FROM Customers WHERE CustomerID = @CustomerID;

    IF @Tier = N'VIP'
        SET @DiscountRate = 0.15; -- Giam 15%
    ELSE IF @Tier = N'Gold'
        SET @DiscountRate = 0.10; -- Giam 10%
    ELSE IF @Tier = N'Silver'
        SET @DiscountRate = 0.05; -- Giam 5%
    ELSE
        SET @DiscountRate = 0.00; -- Khach Standard khong giam

    RETURN @DiscountRate;
END;
GO

-- 2. FUNCTION: Kiem tra mot phong co TRONG trong khoang thoi gian hay khong
IF OBJECT_ID('dbo.fn_CheckRoomAvailable', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CheckRoomAvailable;
GO
CREATE FUNCTION fn_CheckRoomAvailable (
    @RoomID INT,
    @CheckIn DATE,
    @CheckOut DATE
)
RETURNS BIT
AS
BEGIN
    -- Neu phong dang bao duong thi khong san sang
    IF EXISTS (SELECT 1 FROM Rooms WHERE RoomID = @RoomID AND Status = N'Maintenance')
        RETURN 0;

    -- Kiem tra xem co don dat nao bi trung khoang thoi gian hay khong
    IF EXISTS (
        SELECT 1 
        FROM BookingRooms br
        JOIN Bookings b ON br.BookingID = b.BookingID
        WHERE br.RoomID = @RoomID
          AND b.BookingStatus IN (N'Confirmed', N'CheckedIn')
          AND NOT (b.CheckOutDate <= @CheckIn OR b.CheckInDate >= @CheckOut)
    )
    BEGIN
        RETURN 0; -- Bi trung phong
    END

    RETURN 1; -- Phong trong san sang dat
END;
GO

-- 3. FUNCTION: Tinh Tong tien mot Khach hang da chi tieu trong toan he thong
IF OBJECT_ID('dbo.fn_GetCustomerTotalSpent', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_GetCustomerTotalSpent;
GO
CREATE FUNCTION fn_GetCustomerTotalSpent (@CustomerID INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2) = 0;

    SELECT @Total = ISNULL(SUM(inv.FinalAmount), 0)
    FROM Invoices inv
    JOIN Bookings b ON inv.BookingID = b.BookingID
    WHERE b.CustomerID = @CustomerID AND inv.PaymentStatus = N'Paid';

    RETURN @Total;
END;
GO

-- 4. FUNCTION: Tinh Ty le lap day phong (%) cua mot Chi nhanh trong Thang
IF OBJECT_ID('dbo.fn_GetBranchOccupancyRate', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_GetBranchOccupancyRate;
GO
CREATE FUNCTION fn_GetBranchOccupancyRate (
    @BranchID INT,
    @Month INT,
    @Year INT
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @TotalRooms INT;
    DECLARE @OccupiedRoomNights INT;
    DECLARE @DaysInMonth INT;
    DECLARE @TotalCapacityRoomNights INT;
    DECLARE @Rate DECIMAL(5,2) = 0.00;

    -- So ngay trong thang
    SET @DaysInMonth = DAY(EOMONTH(DATEFROMPARTS(@Year, @Month, 1)));

    -- Tong so phong cua chi nhanh
    SELECT @TotalRooms = COUNT(*) FROM Rooms WHERE BranchID = @BranchID;

    IF @TotalRooms = 0 OR @TotalRooms IS NULL
        RETURN 0.00;

    SET @TotalCapacityRoomNights = @TotalRooms * @DaysInMonth;

    -- Tong so dem phong da duoc thue trong thang do
    SELECT @OccupiedRoomNights = ISNULL(SUM(br.Nights), 0)
    FROM BookingRooms br
    JOIN Bookings b ON br.BookingID = b.BookingID
    WHERE b.BranchID = @BranchID
      AND b.BookingStatus IN (N'CheckedIn', N'CheckedOut')
      AND MONTH(b.CheckInDate) = @Month AND YEAR(b.CheckInDate) = @Year;

    IF @TotalCapacityRoomNights > 0
        SET @Rate = CAST((@OccupiedRoomNights * 100.0) / @TotalCapacityRoomNights AS DECIMAL(5,2));

    RETURN @Rate;
END;
GO

PRINT '>>> [THANH CONG] Da tao xong 4 User-Defined Functions!';
GO



-- ============================================================================
-- PHAN TIEP THEO: 05_stored_procedures.sql
-- ============================================================================

-- ============================================================================
-- DU AN: HE THONG CSDL QUAN LY & DAT PHONG CHUOI KHACH SAN (HOTEL BOOKING DB)
-- FILE: 05_stored_procedures.sql
-- MO TA: Tao cac Thu tuc luu tru (Stored Procedures) co Transaction va Error Handling
-- ============================================================================

USE HotelBookingDB;
GO

-- 1. PROCEDURE: Dat phong moi (Kiem tra phong trong & Tinh tien trong 1 Transaction)
IF OBJECT_ID('dbo.sp_CreateBooking', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CreateBooking;
GO
CREATE PROCEDURE sp_CreateBooking
    @CustomerID INT,
    @BranchID INT,
    @RoomID INT,
    @CheckInDate DATE,
    @CheckOutDate DATE,
    @DepositAmount DECIMAL(18,2),
    @Notes NVARCHAR(255) = NULL,
    @NewBookingID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Kiem tra ngay hop le
        IF @CheckOutDate <= @CheckInDate
        BEGIN
            RAISERROR(N'Loi: Ngay Check-out phai lon hon ngay Check-in!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Kiem tra phong co trong hay khong bang Function
        IF dbo.fn_CheckRoomAvailable(@RoomID, @CheckInDate, @CheckOutDate) = 0
        BEGIN
            RAISERROR(N'Loi: Phong nay da co nguoi dat hoac dang bao duong trong khoang thoi gian nay!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Tinh so dem va gia phong
        DECLARE @Nights INT = DATEDIFF(DAY, @CheckInDate, @CheckOutDate);
        DECLARE @PricePerNight DECIMAL(18,2);

        SELECT @PricePerNight = rt.BasePricePerNight
        FROM Rooms r
        JOIN RoomTypes rt ON r.RoomTypeID = rt.RoomTypeID
        WHERE r.RoomID = @RoomID;

        DECLARE @TotalAmount DECIMAL(18,2) = @PricePerNight * @Nights;

        -- 4. Tao ban ghi Bookings
        INSERT INTO Bookings (CustomerID, BranchID, BookingDate, CheckInDate, CheckOutDate, TotalAmount, DepositAmount, BookingStatus, Notes)
        VALUES (@CustomerID, @BranchID, GETDATE(), @CheckInDate, @CheckOutDate, @TotalAmount, @DepositAmount, N'Confirmed', @Notes);

        SET @NewBookingID = SCOPE_IDENTITY();

        -- 5. Tao ban ghi BookingRooms
        INSERT INTO BookingRooms (BookingID, RoomID, PricePerNight, Nights)
        VALUES (@NewBookingID, @RoomID, @PricePerNight, @Nights);

        COMMIT TRANSACTION;
        PRINT N'>>> [THANH CONG] Da tao don dat phong thanh cong voi BookingID = ' + CAST(@NewBookingID AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- 2. PROCEDURE: Check-in Nhan phong (Chuyen trang thai don sang CheckedIn va phong sang Occupied)
IF OBJECT_ID('dbo.sp_CheckInBooking', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CheckInBooking;
GO
CREATE PROCEDURE sp_CheckInBooking
    @BookingID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiem tra don co ton tai va o trang thai Confirmed khong
        IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingID = @BookingID AND BookingStatus = N'Confirmed')
        BEGIN
            RAISERROR(N'Loi: Don dat phong khong hop le hoac da check-in/huy truoc do!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Cap nhat don dat phong
        UPDATE Bookings
        SET BookingStatus = N'CheckedIn'
        WHERE BookingID = @BookingID;

        -- Cap nhat trang thai cac phong lien quan sang Occupied
        UPDATE Rooms
        SET Status = N'Occupied'
        WHERE RoomID IN (SELECT RoomID FROM BookingRooms WHERE BookingID = @BookingID);

        COMMIT TRANSACTION;
        PRINT N'>>> [THANH CONG] Check-in thanh cong cho don dat phong BookingID = ' + CAST(@BookingID AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

-- 3. PROCEDURE: Goi them dich vu (Spa, An uong, Xe dua don...)
IF OBJECT_ID('dbo.sp_OrderService', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_OrderService;
GO
CREATE PROCEDURE sp_OrderService
    @BookingID INT,
    @ServiceID INT,
    @Quantity INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Kiem tra don dat phong dang CheckedIn
        IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingID = @BookingID AND BookingStatus = N'CheckedIn')
        BEGIN
            RAISERROR(N'Loi: Chi co the su dung dich vu khi khach dang luu tru (CheckedIn)!', 16, 1);
            RETURN;
        END

        DECLARE @UnitPrice DECIMAL(18,2);
        SELECT @UnitPrice = UnitPrice FROM Services WHERE ServiceID = @ServiceID;

        IF @UnitPrice IS NULL
        BEGIN
            RAISERROR(N'Loi: Dich vu khong ton tai!', 16, 1);
            RETURN;
        END

        INSERT INTO ServiceOrders (BookingID, ServiceID, OrderDate, Quantity, UnitPrice)
        VALUES (@BookingID, @ServiceID, GETDATE(), @Quantity, @UnitPrice);

        PRINT N'>>> [THANH CONG] Da ghi nhan su dung dich vu cho BookingID = ' + CAST(@BookingID AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

-- 4. PROCEDURE: Check-out, Thanh toan & Xuat Hoa Don
IF OBJECT_ID('dbo.sp_CheckOutAndGenerateInvoice', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CheckOutAndGenerateInvoice;
GO
CREATE PROCEDURE sp_CheckOutAndGenerateInvoice
    @BookingID INT,
    @PaymentMethod NVARCHAR(30) = N'CreditCard'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Kiem tra trang thai don
        IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingID = @BookingID AND BookingStatus = N'CheckedIn')
        BEGIN
            RAISERROR(N'Loi: Don dat phong nay khong o trang thai dang luu tru (CheckedIn)!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DECLARE @CustomerID INT, @RoomCharge DECIMAL(18,2), @Deposit DECIMAL(18,2);
        SELECT @CustomerID = CustomerID, @RoomCharge = TotalAmount, @Deposit = DepositAmount
        FROM Bookings WHERE BookingID = @BookingID;

        -- 2. Tinh tien dich vu phat sinh
        DECLARE @ServiceCharge DECIMAL(18,2) = 0;
        SELECT @ServiceCharge = ISNULL(SUM(TotalServicePrice), 0)
        FROM ServiceOrders WHERE BookingID = @BookingID;

        -- 3. Tinh giam gia VIP bang Function
        DECLARE @DiscountRate DECIMAL(5,2) = dbo.fn_CalculateCustomerDiscount(@CustomerID);
        DECLARE @DiscountAmount DECIMAL(18,2) = @RoomCharge * @DiscountRate;

        -- 4. Tinh thue VAT 8%
        DECLARE @SubTotal DECIMAL(18,2) = (@RoomCharge - @DiscountAmount) + @ServiceCharge;
        DECLARE @TaxAmount DECIMAL(18,2) = @SubTotal * 0.08;
        DECLARE @FinalAmount DECIMAL(18,2) = @SubTotal + @TaxAmount;

        -- 5. Tao Hoa Don (Invoices)
        INSERT INTO Invoices (BookingID, InvoiceDate, RoomCharge, ServiceCharge, DiscountAmount, TaxAmount, FinalAmount, PaymentMethod, PaymentStatus)
        VALUES (@BookingID, GETDATE(), @RoomCharge, @ServiceCharge, @DiscountAmount, @TaxAmount, @FinalAmount, @PaymentMethod, N'Paid');

        -- 6. Cap nhat trang thai don va phong
        UPDATE Bookings SET BookingStatus = N'CheckedOut' WHERE BookingID = @BookingID;
        UPDATE Rooms SET Status = N'Available' WHERE RoomID IN (SELECT RoomID FROM BookingRooms WHERE BookingID = @BookingID);

        -- 7. Tich diem thuong (100,000 VND = 1 diem)
        DECLARE @EarnedPoints INT = CAST(@FinalAmount / 100000 AS INT);
        UPDATE Customers 
        SET TotalPoints = TotalPoints + @EarnedPoints
        WHERE CustomerID = @CustomerID;

        -- 8. Tu dong nang hang thanh vien neu du diem
        UPDATE Customers
        SET LoyaltyTier = CASE 
            WHEN TotalPoints >= 2000 THEN N'VIP'
            WHEN TotalPoints >= 500 THEN N'Gold'
            WHEN TotalPoints >= 150 THEN N'Silver'
            ELSE N'Standard'
        END
        WHERE CustomerID = @CustomerID;

        COMMIT TRANSACTION;

        -- In bien ban thanh toan
        PRINT N'======================================================';
        PRINT N'             HOA DON THANH TOAN KHACH SAN             ';
        PRINT N'======================================================';
        PRINT N' Ma dat phong:        ' + CAST(@BookingID AS NVARCHAR(20));
        PRINT N' Tien phong:          ' + CAST(@RoomCharge AS NVARCHAR(30)) + ' VND';
        PRINT N' Tien dich vu:        ' + CAST(@ServiceCharge AS NVARCHAR(30)) + ' VND';
        PRINT N' Giam gia hoi vien:  -' + CAST(@DiscountAmount AS NVARCHAR(30)) + ' VND';
        PRINT N' Thue VAT (8%):       ' + CAST(@TaxAmount AS NVARCHAR(30)) + ' VND';
        PRINT N' TONG THANH TOAN:     ' + CAST(@FinalAmount AS NVARCHAR(30)) + ' VND';
        PRINT N' Tien coc da thu:    -' + CAST(@Deposit AS NVARCHAR(30)) + ' VND';
        PRINT N' CON LAI PHAI THU:    ' + CAST((@FinalAmount - @Deposit) AS NVARCHAR(30)) + ' VND';
        PRINT N' Diem thuong cong them: +' + CAST(@EarnedPoints AS NVARCHAR(20)) + ' diem';
        PRINT N'======================================================';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

-- 5. PROCEDURE: Huy don dat phong (Cancel Booking)
IF OBJECT_ID('dbo.sp_CancelBooking', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CancelBooking;
GO
CREATE PROCEDURE sp_CancelBooking
    @BookingID INT,
    @Reason NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Bookings WHERE BookingID = @BookingID AND BookingStatus = N'Confirmed')
        BEGIN
            RAISERROR(N'Loi: Chi co the huy nhung don dat phong chua Check-in!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Bookings
        SET BookingStatus = N'Cancelled',
            Notes = ISNULL(Notes + N' | ', N'') + N'Ly do huy: ' + ISNULL(@Reason, N'Khach yeu cau')
        WHERE BookingID = @BookingID;

        -- Giai phong phong ve Available
        UPDATE Rooms
        SET Status = N'Available'
        WHERE RoomID IN (SELECT RoomID FROM BookingRooms WHERE BookingID = @BookingID);

        COMMIT TRANSACTION;
        PRINT N'>>> [THANH CONG] Da huy don dat phong BookingID = ' + CAST(@BookingID AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

PRINT '>>> [THANH CONG] Da tao xong 5 Stored Procedures co Transaction & Error Handling!';
GO



-- ============================================================================
-- PHAN TIEP THEO: 06_triggers.sql
-- ============================================================================

﻿-- ============================================================================
-- DU AN: HE THONG CSDL QUAN LY & DAT PHONG CHUOI KHACH SAN (HOTEL BOOKING DB)
-- FILE: 06_triggers.sql
-- MO TA: Cac Trigger tu dong kiem soat toan ven du lieu, chong trung lich va ghi log
-- ============================================================================

USE HotelBookingDB;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 1: trg_PreventDoubleBooking
-- Muc dich: Ngan chan viec them phong vao don dat neu phong do da co nguoi dat
--           trong khoang thoi gian trung lap (Overlapping dates).
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_PreventDoubleBooking', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_PreventDoubleBooking;
GO

CREATE TRIGGER trg_PreventDoubleBooking
ON BookingRooms
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiem tra neu ton tai bat ky phong nao bi trung lich
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Bookings b_new ON i.BookingID = b_new.BookingID
        JOIN BookingRooms br_exist ON i.RoomID = br_exist.RoomID AND i.BookingID <> br_exist.BookingID
        JOIN Bookings b_exist ON br_exist.BookingID = b_exist.BookingID
        WHERE b_exist.BookingStatus IN (N'Confirmed', N'CheckedIn')
          AND b_new.BookingStatus IN (N'Confirmed', N'CheckedIn')
          -- Dieu kien trung lap thoi gian: (StartA < EndB) AND (EndA > StartB)
          AND b_new.CheckInDate < b_exist.CheckOutDate
          AND b_new.CheckOutDate > b_exist.CheckInDate
    )
    BEGIN
        RAISERROR(N'LOI: Phong da duoc dat boi khach hang khac trong khoang thoi gian nay!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 2: trg_LogRoomPriceChange
-- Muc dich: Tu dong ghi nhat ky vao bang AuditLogs khi gia loai phong bi thay doi
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_LogRoomPriceChange', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_LogRoomPriceChange;
GO

CREATE TRIGGER trg_LogRoomPriceChange
ON RoomTypes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chi ghi log neu co thay doi cot BasePricePerNight
    IF UPDATE(BasePricePerNight)
    BEGIN
        INSERT INTO AuditLogs (ActionType, TableName, RecordID, OldValue, NewValue, ChangedBy, ChangedAt)
        SELECT 
            N'PRICE_CHANGE',
            N'RoomTypes',
            i.RoomTypeID,
            N'Gia cu: ' + CAST(d.BasePricePerNight AS NVARCHAR(30)) + N' VND',
            N'Gia moi: ' + CAST(i.BasePricePerNight AS NVARCHAR(30)) + N' VND (Loai phong: ' + i.TypeName + N')',
            SYSTEM_USER,
            GETDATE()
        FROM inserted i
        JOIN deleted d ON i.RoomTypeID = d.RoomTypeID
        WHERE i.BasePricePerNight <> d.BasePricePerNight;
    END
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 3: trg_UpdateCustomerLoyaltyOnInvoice
-- Muc dich: Khi hoa don thanh toan thanh cong (Paid), tu dong cong diem tich luy
--           (1 diem cho moi 100.000 VND) va tu dong nang hang thanh vien khach hang.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_UpdateCustomerLoyaltyOnInvoice', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_UpdateCustomerLoyaltyOnInvoice;
GO

CREATE TRIGGER trg_UpdateCustomerLoyaltyOnInvoice
ON Invoices
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chi xu ly cho cac hoa don hop le va da thanh toan (Paid)
    IF EXISTS (SELECT 1 FROM inserted WHERE PaymentStatus = N'Paid')
    BEGIN
        -- Tinh diem moi cong them va cap nhat cho Customer
        ;WITH NewPoints AS (
            SELECT 
                b.CustomerID,
                SUM(CAST(FLOOR(i.FinalAmount / 100000.0) AS INT)) AS EarnedPoints
            FROM inserted i
            JOIN Bookings b ON i.BookingID = b.BookingID
            WHERE i.PaymentStatus = N'Paid'
            GROUP BY b.CustomerID
        )
        UPDATE c
        SET 
            c.TotalPoints = c.TotalPoints + np.EarnedPoints,
            c.LoyaltyTier = CASE 
                WHEN (c.TotalPoints + np.EarnedPoints) >= 600 THEN N'VIP'
                WHEN (c.TotalPoints + np.EarnedPoints) >= 300 THEN N'Gold'
                WHEN (c.TotalPoints + np.EarnedPoints) >= 100 THEN N'Silver'
                ELSE N'Standard'
            END
        FROM Customers c
        JOIN NewPoints np ON c.CustomerID = np.CustomerID;
    END
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 4: trg_AutoUpdateBookingTotal
-- Muc dich: Tu dong tinh lai tong tien don dat phong (TotalAmount) khi them/sua
--           chi tiet phong (BookingRooms)
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_AutoUpdateBookingTotal', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_AutoUpdateBookingTotal;
GO

CREATE TRIGGER trg_AutoUpdateBookingTotal
ON BookingRooms
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Danh sach cac BookingID bi anh huong boi thao tac INSERT / UPDATE / DELETE
    DECLARE @AffectedBookings TABLE (BookingID INT PRIMARY KEY);

    INSERT INTO @AffectedBookings (BookingID)
    SELECT DISTINCT BookingID FROM inserted WHERE BookingID IS NOT NULL
    UNION
    SELECT DISTINCT BookingID FROM deleted WHERE BookingID IS NOT NULL;

    -- Cap nhat lai TotalAmount trong Bookings
    UPDATE b
    SET b.TotalAmount = ISNULL(r.TotalRoomAmount, 0)
    FROM Bookings b
    JOIN @AffectedBookings ab ON b.BookingID = ab.BookingID
    LEFT JOIN (
        SELECT BookingID, SUM(PricePerNight * Nights) AS TotalRoomAmount
        FROM BookingRooms
        GROUP BY BookingID
    ) r ON b.BookingID = r.BookingID;
END;
GO

PRINT '>>> [THANH CONG] Da tao xong cac Triggers quan ly nghiep vu!';
GO



-- ============================================================================
-- PHAN TIEP THEO: 08_indexes_and_tuning.sql
-- ============================================================================

﻿-- ============================================================================
-- DU AN: HE THONG CSDL QUAN LY & DAT PHONG CHUOI KHACH SAN (HOTEL BOOKING DB)
-- FILE: 08_indexes_and_tuning.sql
-- MO TA: Toi uu hoa chi muc (Indexing Strategy), Filtered Indexes va Danh gia hieu nang
-- ============================================================================

USE HotelBookingDB;
GO

-- ============================================================================
-- 1. TAO CAC NON-CLUSTERED INDEXES CHO KHOA NGOAI & COT TRUY VAN PHO BIEN
-- ============================================================================

-- Index 1: Tim kiem phong theo chi nhanh va trang thai (Composite Index)
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Rooms_Branch_Status' AND object_id = OBJECT_ID('Rooms'))
    DROP INDEX IX_Rooms_Branch_Status ON Rooms;
GO
CREATE NONCLUSTERED INDEX IX_Rooms_Branch_Status 
ON Rooms (BranchID, Status)
INCLUDE (RoomNumber, Floor, RoomTypeID);
GO

-- Index 2: Filtered Index - Chi danh chi muc cac phong dang TRONG (Available)
-- Giup tang toc do tim kiem phong trong khi khach hang dat phong ma ton it dung luong
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Rooms_Available_Filtered' AND object_id = OBJECT_ID('Rooms'))
    DROP INDEX IX_Rooms_Available_Filtered ON Rooms;
GO
CREATE NONCLUSTERED INDEX IX_Rooms_Available_Filtered
ON Rooms (BranchID, RoomTypeID)
WHERE Status = N'Available';
GO

-- Index 3: Tim kiem va loc don dat phong theo khach hang va trang thai
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Bookings_CustomerID_Status' AND object_id = OBJECT_ID('Bookings'))
    DROP INDEX IX_Bookings_CustomerID_Status ON Bookings;
GO
CREATE NONCLUSTERED INDEX IX_Bookings_CustomerID_Status
ON Bookings (CustomerID, BookingStatus)
INCLUDE (BranchID, CheckInDate, CheckOutDate, TotalAmount);
GO

-- Index 4: Filtered Index cho cac don dat dang hoat dong (Active Bookings)
-- Toi uu hoa trigger kiem tra trung lich (Overlap dates check)
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Bookings_ActiveDates_Filtered' AND object_id = OBJECT_ID('Bookings'))
    DROP INDEX IX_Bookings_ActiveDates_Filtered ON Bookings;
GO
CREATE NONCLUSTERED INDEX IX_Bookings_ActiveDates_Filtered
ON Bookings (CheckInDate, CheckOutDate)
INCLUDE (BookingID, BranchID, CustomerID)
WHERE BookingStatus IN (N'Confirmed', N'CheckedIn');
GO

-- Index 5: Chi tiet phong dat theo RoomID (Toi uu JOIN giua Rooms va BookingRooms)
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_BookingRooms_RoomID' AND object_id = OBJECT_ID('BookingRooms'))
    DROP INDEX IX_BookingRooms_RoomID ON BookingRooms;
GO
CREATE NONCLUSTERED INDEX IX_BookingRooms_RoomID
ON BookingRooms (RoomID)
INCLUDE (BookingID, PricePerNight, Nights);
GO

-- Index 6: Su dung dich vu theo BookingID va ServiceID
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ServiceOrders_BookingID' AND object_id = OBJECT_ID('ServiceOrders'))
    DROP INDEX IX_ServiceOrders_BookingID ON ServiceOrders;
GO
CREATE NONCLUSTERED INDEX IX_ServiceOrders_BookingID
ON ServiceOrders (BookingID)
INCLUDE (ServiceID, Quantity, UnitPrice, TotalServicePrice);
GO

-- Index 7: Tim kiem hoa don theo trang thai thanh toan va ngay thanh toan
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Invoices_Status_Date' AND object_id = OBJECT_ID('Invoices'))
    DROP INDEX IX_Invoices_Status_Date ON Invoices;
GO
CREATE NONCLUSTERED INDEX IX_Invoices_Status_Date
ON Invoices (PaymentStatus, InvoiceDate)
INCLUDE (BookingID, FinalAmount, PaymentMethod);
GO

-- Index 8: Tim kiem thong tin khach hang theo so dien thoai (Phone Lookup)
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Customers_Phone' AND object_id = OBJECT_ID('Customers'))
    DROP INDEX IX_Customers_Phone ON Customers;
GO
CREATE NONCLUSTERED INDEX IX_Customers_Phone
ON Customers (Phone)
INCLUDE (FullName, IdentityCard, Email, LoyaltyTier, TotalPoints);
GO

-- ============================================================================
-- 2. DEMO SO SANH HIEU NANG VA KIEM TRA THONG KE (STATISTICS & EXECUTION PLAN)
-- ============================================================================

PRINT '--- Bat thong so do luong thoi gian va so lan doc I/O ---';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Thuc thi truy van tim kiem phong trong kem chi tiet loai phong
SELECT 
    r.RoomID,
    r.RoomNumber,
    r.Floor,
    rt.TypeName,
    rt.BasePricePerNight,
    rt.Capacity
FROM Rooms r
JOIN RoomTypes rt ON r.RoomTypeID = rt.RoomTypeID
WHERE r.BranchID = 1 AND r.Status = N'Available';
GO

-- Thuc thi truy van lich su thanh toan hoa don cua he thong
SELECT 
    inv.InvoiceID,
    inv.BookingID,
    inv.InvoiceDate,
    inv.FinalAmount,
    inv.PaymentMethod
FROM Invoices inv
WHERE inv.PaymentStatus = N'Paid' AND inv.InvoiceDate >= '2026-03-01';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- ============================================================================
-- 3. TRUY VAN KIEM SOAT MUC DO PHAN MANH CHI MUC (INDEX FRAGMENTATION REPORT)
-- ============================================================================
PRINT '--- Bao cao do phan manh chi muc trong he thong ---';
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.index_type_desc AS IndexType,
    CAST(ips.avg_fragmentation_in_percent AS DECIMAL(5,2)) AS FragmentationPercent,
    ips.page_count AS PageCount
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent IS NOT NULL
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

PRINT '>>> [THANH CONG] Da khoi tao chien luoc Indexing va toi uu hieu nang he thong!';
GO


