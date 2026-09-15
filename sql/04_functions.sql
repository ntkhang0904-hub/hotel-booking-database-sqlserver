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
