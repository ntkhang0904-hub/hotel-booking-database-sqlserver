
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
