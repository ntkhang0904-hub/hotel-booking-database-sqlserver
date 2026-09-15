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
