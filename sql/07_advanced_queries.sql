USE HotelBookingDB;
GO

-- TRUY VAN 1: Thong ke danh sach khach hang, so lan dat phong va tong diem tich luy
PRINT '--- Q1: Thong ke tong quan khach hang ---';
SELECT 
    c.CustomerID,
    c.FullName,
    c.Phone,
    c.LoyaltyTier,
    c.TotalPoints,
    COUNT(b.BookingID) AS TotalBookings,
    ISNULL(SUM(inv.FinalAmount), 0) AS TotalAmountSpent
FROM Customers c
LEFT JOIN Bookings b ON c.CustomerID = b.CustomerID
LEFT JOIN Invoices inv ON b.BookingID = inv.BookingID AND inv.PaymentStatus = N'Paid'
GROUP BY c.CustomerID, c.FullName, c.Phone, c.LoyaltyTier, c.TotalPoints
ORDER BY TotalAmountSpent DESC;
GO

-- TRUY VAN 2: Ty le phong trong (Available) va dang co khach (Occupied) theo tung chi nhanh
PRINT '--- Q2: Ty le phong theo chi nhanh ---';
SELECT 
    br.BranchName,
    br.City,
    COUNT(r.RoomID) AS TotalRooms,
    SUM(CASE WHEN r.Status = N'Available' THEN 1 ELSE 0 END) AS AvailableRooms,
    SUM(CASE WHEN r.Status = N'Occupied' THEN 1 ELSE 0 END) AS OccupiedRooms,
    SUM(CASE WHEN r.Status = N'Maintenance' THEN 1 ELSE 0 END) AS MaintenanceRooms,
    CAST(ROUND(SUM(CASE WHEN r.Status = N'Occupied' THEN 1.0 ELSE 0.0 END) / COUNT(r.RoomID) * 100, 2) AS DECIMAL(5,2)) AS OccupancyRatePercent
FROM Branches br
JOIN Rooms r ON br.BranchID = r.BranchID
GROUP BY br.BranchID, br.BranchName, br.City
ORDER BY OccupancyRatePercent DESC;
GO

-- TRUY VAN 3: Top 5 loai phong mang lai doanh thu cao nhat cho he thong
PRINT '--- Q3: Top 5 loai phong doanh thu cao nhat ---';
SELECT TOP 5
    rt.TypeName,
    rt.BasePricePerNight,
    COUNT(br.BookingID) AS BookingCount,
    SUM(br.Nights) AS TotalNightsSold,
    SUM(br.PricePerNight * br.Nights) AS TotalRevenue
FROM RoomTypes rt
JOIN Rooms r ON rt.RoomTypeID = r.RoomTypeID
JOIN BookingRooms br ON r.RoomID = br.RoomID
JOIN Bookings b ON br.BookingID = b.BookingID
WHERE b.BookingStatus IN (N'CheckedIn', N'CheckedOut')
GROUP BY rt.RoomTypeID, rt.TypeName, rt.BasePricePerNight
ORDER BY TotalRevenue DESC;
GO

-- TRUY VAN 4: Top 5 dich vu gia tang duoc su dung nhieu nhat
PRINT '--- Q4: Top 5 dich vu pho bien nhat ---';
SELECT TOP 5
    s.ServiceID,
    s.ServiceName,
    s.Category,
    s.UnitPrice,
    s.Unit,
    SUM(so.Quantity) AS TotalQuantityOrdered,
    SUM(so.TotalServicePrice) AS TotalRevenueGenerated
FROM Services s
JOIN ServiceOrders so ON s.ServiceID = so.ServiceID
GROUP BY s.ServiceID, s.ServiceName, s.Category, s.UnitPrice, s.Unit
ORDER BY TotalQuantityOrdered DESC;
GO

-- TRUY VAN 5: Tim nhung khach hang da tung dat phong tai tu 2 chi nhanh tro len (Khach hang lien tinh)
PRINT '--- Q5: Khach hang lien tinh (Cross-branch customers) ---';
SELECT 
    c.CustomerID,
    c.FullName,
    c.Phone,
    c.Email,
    COUNT(DISTINCT b.BranchID) AS DistinctBranchesVisited,
    COUNT(b.BookingID) AS TotalBookings
FROM Customers c
JOIN Bookings b ON c.CustomerID = b.CustomerID
GROUP BY c.CustomerID, c.FullName, c.Phone, c.Email
HAVING COUNT(DISTINCT b.BranchID) >= 2
ORDER BY DistinctBranchesVisited DESC, TotalBookings DESC;
GO

-- TRUY VAN 6: Danh sach chi nhanh co doanh thu cao hon muc doanh thu trung binh toan he thong
PRINT '--- Q6: Chi nhanh vuot muc doanh thu trung binh ---';
WITH BranchRevenue AS (
    SELECT 
        br.BranchID,
        br.BranchName,
        br.City,
        ISNULL(SUM(inv.FinalAmount), 0) AS TotalRevenue
    FROM Branches br
    JOIN Bookings b ON br.BranchID = b.BranchID
    JOIN Invoices inv ON b.BookingID = inv.BookingID AND inv.PaymentStatus = N'Paid'
    GROUP BY br.BranchID, br.BranchName, br.City
)
SELECT 
    BranchID,
    BranchName,
    City,
    TotalRevenue,
    (SELECT AVG(TotalRevenue) FROM BranchRevenue) AS SystemAverageRevenue,
    TotalRevenue - (SELECT AVG(TotalRevenue) FROM BranchRevenue) AS DifferenceFromAvg
FROM BranchRevenue
WHERE TotalRevenue > (SELECT AVG(TotalRevenue) FROM BranchRevenue)
ORDER BY TotalRevenue DESC;
GO

-- TRUY VAN 7: Co cau doanh thu chi tiet (Tien phong vs Tien dich vu vs Giam gia) theo chi nhanh
PRINT '--- Q7: Co cau doanh thu chi tiet ---';
SELECT 
    br.BranchName,
    COUNT(inv.InvoiceID) AS PaidInvoiceCount,
    SUM(inv.RoomCharge) AS TotalRoomCharge,
    SUM(inv.ServiceCharge) AS TotalServiceCharge,
    SUM(inv.DiscountAmount) AS TotalDiscountGiven,
    SUM(inv.TaxAmount) AS TotalTaxCollected,
    SUM(inv.FinalAmount) AS NetRevenue,
    CAST(ROUND(SUM(inv.ServiceCharge) / NULLIF(SUM(inv.FinalAmount), 0) * 100, 2) AS DECIMAL(5,2)) AS ServiceContributionPercent
FROM Branches br
JOIN Bookings b ON br.BranchID = b.BranchID
JOIN Invoices inv ON b.BookingID = inv.BookingID
WHERE inv.PaymentStatus = N'Paid'
GROUP BY br.BranchID, br.BranchName
ORDER BY NetRevenue DESC;
GO

-- TRUY VAN 8: Danh sach cac don dat phong co su dung cac dich vu cao cap (Spa hoac Dua don san bay)
PRINT '--- Q8: Don dat phong su dung dich vu cao cap ---';
SELECT 
    b.BookingID,
    c.FullName AS CustomerName,
    br.BranchName,
    b.CheckInDate,
    b.CheckOutDate,
    s.ServiceName,
    so.Quantity,
    so.TotalServicePrice
FROM Bookings b
JOIN Customers c ON b.CustomerID = c.CustomerID
JOIN Branches br ON b.BranchID = br.BranchID
JOIN ServiceOrders so ON b.BookingID = so.BookingID
JOIN Services s ON so.ServiceID = s.ServiceID
WHERE s.Category IN (N'Spa', N'Transport')
ORDER BY so.TotalServicePrice DESC;
GO

-- TRUY VAN 9: Xep hang Top 3 khach hang chi tieu cao nhat trong tung chi nhanh (DENSE_RANK)
PRINT '--- Q9: Top 3 khach hang chi tieu theo tung chi nhanh ---';
WITH CustomerBranchSpending AS (
    SELECT 
        br.BranchID,
        br.BranchName,
        c.CustomerID,
        c.FullName AS CustomerName,
        c.LoyaltyTier,
        SUM(inv.FinalAmount) AS TotalSpentInBranch
    FROM Branches br
    JOIN Bookings b ON br.BranchID = b.BranchID
    JOIN Customers c ON b.CustomerID = c.CustomerID
    JOIN Invoices inv ON b.BookingID = inv.BookingID AND inv.PaymentStatus = N'Paid'
    GROUP BY br.BranchID, br.BranchName, c.CustomerID, c.FullName, c.LoyaltyTier
),
RankedCustomers AS (
    SELECT 
        BranchName,
        CustomerName,
        LoyaltyTier,
        TotalSpentInBranch,
        DENSE_RANK() OVER (PARTITION BY BranchID ORDER BY TotalSpentInBranch DESC) AS SpendingRank
    FROM CustomerBranchSpending
)
SELECT * 
FROM RankedCustomers
WHERE SpendingRank <= 3
ORDER BY BranchName, SpendingRank;
GO

-- TRUY VAN 10: Tinh doanh thu luy ke theo thoi gian (Running Total / Cumulative Revenue)
PRINT '--- Q10: Doanh thu luy ke toan he thong ---';
WITH DailyRevenue AS (
    SELECT 
        CAST(InvoiceDate AS DATE) AS TransDate,
        COUNT(InvoiceID) AS InvoiceCount,
        SUM(FinalAmount) AS DailyTotal
    FROM Invoices
    WHERE PaymentStatus = N'Paid'
    GROUP BY CAST(InvoiceDate AS DATE)
)
SELECT 
    TransDate,
    InvoiceCount,
    DailyTotal,
    SUM(DailyTotal) OVER (ORDER BY TransDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotalRevenue,
    AVG(DailyTotal) OVER (ORDER BY TransDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAverage3Days
FROM DailyRevenue
ORDER BY TransDate;
GO

-- TRUY VAN 11: Tang truong doanh thu theo thang va so sanh voi thang truoc (LAG Window Function)
PRINT '--- Q11: Tang truong doanh thu Month-over-Month (MoM) ---';
WITH MonthlyRevenue AS (
    SELECT 
        YEAR(InvoiceDate) AS RevYear,
        MONTH(InvoiceDate) AS RevMonth,
        SUM(FinalAmount) AS MonthlyTotal
    FROM Invoices
    WHERE PaymentStatus = N'Paid'
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
)
SELECT 
    RevYear,
    RevMonth,
    MonthlyTotal,
    LAG(MonthlyTotal, 1) OVER (ORDER BY RevYear, RevMonth) AS PreviousMonthRevenue,
    MonthlyTotal - LAG(MonthlyTotal, 1) OVER (ORDER BY RevYear, RevMonth) AS MoM_Growth_Amount,
    CAST(ROUND((MonthlyTotal - LAG(MonthlyTotal, 1) OVER (ORDER BY RevYear, RevMonth)) / NULLIF(LAG(MonthlyTotal, 1) OVER (ORDER BY RevYear, RevMonth), 0) * 100, 2) AS DECIMAL(5,2)) AS MoM_Growth_Percent
FROM MonthlyRevenue
ORDER BY RevYear, RevMonth;
GO

-- TRUY VAN 12: Khoang cach giua cac lan dat phong lien tiep cua khach hang (LEAD Window Function)
PRINT '--- Q12: Khoang cach ngay giua cac lan dat phong ---';
WITH CustomerBookingSequence AS (
    SELECT 
        c.CustomerID,
        c.FullName,
        b.BookingID,
        b.BookingDate,
        b.CheckInDate,
        LEAD(b.CheckInDate, 1) OVER (PARTITION BY c.CustomerID ORDER BY b.CheckInDate) AS NextCheckInDate
    FROM Customers c
    JOIN Bookings b ON c.CustomerID = b.CustomerID
    WHERE b.BookingStatus <> N'Cancelled'
)
SELECT 
    CustomerID,
    FullName,
    BookingID,
    CheckInDate AS CurrentCheckIn,
    NextCheckInDate,
    DATEDIFF(DAY, CheckInDate, NextCheckInDate) AS DaysUntilNextBooking
FROM CustomerBookingSequence
WHERE NextCheckInDate IS NOT NULL
ORDER BY CustomerID, CurrentCheckIn;
GO

-- TRUY VAN 13: Phan khuc khach hang thanh 4 nhom chi tieu (Quartiles bang NTILE)
PRINT '--- Q13: Phan khuc khach hang (NTILE Quartiles) ---';
WITH CustomerTotalSpent AS (
    SELECT 
        c.CustomerID,
        c.FullName,
        c.Phone,
        c.LoyaltyTier,
        ISNULL(SUM(inv.FinalAmount), 0) AS LifetimeValue
    FROM Customers c
    LEFT JOIN Bookings b ON c.CustomerID = b.CustomerID
    LEFT JOIN Invoices inv ON b.BookingID = inv.BookingID AND inv.PaymentStatus = N'Paid'
    GROUP BY c.CustomerID, c.FullName, c.Phone, c.LoyaltyTier
)
SELECT 
    CustomerID,
    FullName,
    LoyaltyTier,
    LifetimeValue,
    NTILE(4) OVER (ORDER BY LifetimeValue DESC) AS SpendingQuartile,
    CASE NTILE(4) OVER (ORDER BY LifetimeValue DESC)
        WHEN 1 THEN N'Tier 1: VIP Champions (Top 25%)'
        WHEN 2 THEN N'Tier 2: High Value (25% - 50%)'
        WHEN 3 THEN N'Tier 3: Moderate (50% - 75%)'
        WHEN 4 THEN N'Tier 4: Low / New (Bottom 25%)'
    END AS CustomerSegment
FROM CustomerTotalSpent
ORDER BY LifetimeValue DESC;
GO

-- TRUY VAN 14: Bang chi so KPI Khach san (ADR - Average Daily Rate, RevPAR) theo chi nhanh
PRINT '--- Q14: Chi so KPI Khach san (ADR & Doanh thu) ---';
WITH BranchMetrics AS (
    SELECT 
        br.BranchID,
        br.BranchName,
        COUNT(DISTINCT r.RoomID) AS TotalRooms,
        COUNT(DISTINCT b.BookingID) AS CompletedBookings,
        SUM(brk.Nights) AS TotalRoomNightsSold,
        SUM(inv.RoomCharge) AS TotalRoomRevenue,
        SUM(inv.FinalAmount) AS TotalNetRevenue
    FROM Branches br
    JOIN Rooms r ON br.BranchID = r.BranchID
    LEFT JOIN Bookings b ON br.BranchID = b.BranchID AND b.BookingStatus IN (N'CheckedIn', N'CheckedOut')
    LEFT JOIN BookingRooms brk ON b.BookingID = brk.BookingID
    LEFT JOIN Invoices inv ON b.BookingID = inv.BookingID AND inv.PaymentStatus = N'Paid'
    GROUP BY br.BranchID, br.BranchName
)
SELECT 
    BranchName,
    TotalRooms,
    CompletedBookings,
    ISNULL(TotalRoomNightsSold, 0) AS TotalNightsSold,
    ISNULL(TotalNetRevenue, 0) AS TotalRevenue,
    -- ADR = Tong doanh thu phong / Tong so dem phong da ban
    CAST(ROUND(ISNULL(TotalRoomRevenue, 0) / NULLIF(TotalRoomNightsSold, 0), 2) AS DECIMAL(18,2)) AS AverageDailyRate_ADR,
    -- Doanh thu trung binh tren moi phong cua chi nhanh
    CAST(ROUND(ISNULL(TotalNetRevenue, 0) / NULLIF(TotalRooms, 0), 2) AS DECIMAL(18,2)) AS RevenuePerAvailableRoom
FROM BranchMetrics
ORDER BY TotalRevenue DESC;
GO

-- TRUY VAN 15: Phat hien cac phong lau chua duoc dat (Can kiem tra bao tri hoac quang ba)
PRINT '--- Q15: Danh sach phong chua co luot dat trong 30 ngay gan nhat ---';
SELECT 
    r.RoomID,
    br.BranchName,
    r.RoomNumber,
    rt.TypeName,
    r.Floor,
    r.Status,
    MAX(b.CheckOutDate) AS LastCheckedOutDate,
    DATEDIFF(DAY, ISNULL(MAX(b.CheckOutDate), '2026-01-01'), GETDATE()) AS DaysSinceLastOccupancy
FROM Rooms r
JOIN Branches br ON r.BranchID = br.BranchID
JOIN RoomTypes rt ON r.RoomTypeID = rt.RoomTypeID
LEFT JOIN BookingRooms brk ON r.RoomID = brk.RoomID
LEFT JOIN Bookings b ON brk.BookingID = b.BookingID AND b.BookingStatus <> N'Cancelled'
GROUP BY r.RoomID, br.BranchName, r.RoomNumber, rt.TypeName, r.Floor, r.Status
HAVING MAX(b.CheckOutDate) IS NULL OR DATEDIFF(DAY, MAX(b.CheckOutDate), GETDATE()) >= 30
ORDER BY DaysSinceLastOccupancy DESC;
GO

-- TRUY VAN 16: Tong hop phuong thuc thanh toan ua chuong theo nhom hang thanh vien
PRINT '--- Q16: Ty le phuong thuc thanh toan theo hang khach hang ---';
SELECT 
    c.LoyaltyTier,
    inv.PaymentMethod,
    COUNT(inv.InvoiceID) AS TransactionCount,
    SUM(inv.FinalAmount) AS TotalPaidAmount,
    CAST(ROUND(COUNT(inv.InvoiceID) * 100.0 / SUM(COUNT(inv.InvoiceID)) OVER (PARTITION BY c.LoyaltyTier), 2) AS DECIMAL(5,2)) AS PercentageWithinTier
FROM Customers c
JOIN Bookings b ON c.CustomerID = b.CustomerID
JOIN Invoices inv ON b.BookingID = inv.BookingID
WHERE inv.PaymentStatus = N'Paid'
GROUP BY c.LoyaltyTier, inv.PaymentMethod
ORDER BY c.LoyaltyTier, TransactionCount DESC;
GO

PRINT '>>> [HOAN TAT] Da thuc thi thanh cong 16 cau truy van nang cao!';
GO
