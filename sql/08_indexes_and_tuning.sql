-- ============================================================================
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
