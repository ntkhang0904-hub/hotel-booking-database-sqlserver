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
