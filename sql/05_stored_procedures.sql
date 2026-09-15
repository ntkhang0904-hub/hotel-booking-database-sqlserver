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
