use QLNH

/*
	Thủ Tục (Stored Procedures)
*/


-- =================  BÀI LÀM ===================
/*
	lab1: Chuyển Tiền
		-- Yêu cầu: Phải đảm bảo tiền được trừ  ở tài khoản A VÀ cộng vào tài khoản B. Nếu một 
		            trong hai bước thất bại, cả giao dịch phải được hủy (ROLLBACK).
		-- Logic: Đây là một TRANSACTION kinh điển, nhận vào MaTKNguon, MaTKDich, SoTien
		
*/

CREATE OR ALTER PROCEDURE sp_ChuyenTien
    @MaTKNguon VARCHAR(20),
    @MaTKDich VARCHAR(20),
    @SoTien DECIMAL(18,2),
    @MaNV VARCHAR(10),
    @MaLoaiGD_Chuyen VARCHAR(10),
    @MaLoaiGD_Nhan VARCHAR(10),
    @TrangThai INT OUTPUT,
    @ThongBao NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @TrangThai = 0;
    SET @ThongBao = N'Lỗi không xác định';

    BEGIN TRY
        -- 1. Kiểm tra đầu vào
        IF @SoTien <= 0
        BEGIN
            SET @ThongBao = N'Số tiền phải lớn hơn 0';
            RETURN;
        END;

        IF @MaTKNguon = @MaTKDich
        BEGIN
            SET @ThongBao = N'Tài khoản nguồn phải khác tài khoản đích';
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaTK = @MaTKNguon)
        BEGIN
            SET @ThongBao = N'Tài khoản nguồn không tồn tại.';
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaTK = @MaTKDich)
        BEGIN
            SET @ThongBao = N'Tài khoản đích không tồn tại.';
            RETURN;
        END;

        -- 2. Bắt đầu transaction
        BEGIN TRANSACTION;

        -- Lấy khóa ứng dụng để tránh race khi sinh MaGiaoDich
        DECLARE @rc INT;
        EXEC @rc = sp_getapplock @Resource = N'GIAODICH_ID_GENERATION', 
                                @LockMode = N'Exclusive', 
                                @LockTimeout = 10000, 
                                @LockOwner = N'Transaction';
        IF @rc < 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @ThongBao = N'Không thể lấy khóa để sinh mã giao dịch. Vui lòng thử lại.';
            RETURN;
        END;

        DECLARE @SoDuNguon DECIMAL(18,2);

        SELECT @SoDuNguon = SoDu
        FROM TAIKHOAN WITH (UPDLOCK, ROWLOCK)
        WHERE MaTK = @MaTKNguon;

        IF @SoDuNguon < @SoTien
        BEGIN
            ROLLBACK TRANSACTION;
            SET @ThongBao = N'Số dư tài khoản nguồn không đủ';
            RETURN;
        END;

        -- Cập nhật số dư
        UPDATE TAIKHOAN
        SET SoDu = SoDu - @SoTien
        WHERE MaTK = @MaTKNguon;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @ThongBao = N'Lỗi khi trừ tiền tài khoản nguồn';
            RETURN;
        END;

        UPDATE TAIKHOAN
        SET SoDu = SoDu + @SoTien
        WHERE MaTK = @MaTKDich;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @ThongBao = N'Lỗi khi cộng tiền tài khoản đích';
            RETURN;
        END;

        -- Sinh MaGiaoDich (dạng GD00001, GD00002, ...)
        DECLARE @MaxSuffix INT = 0;
        SELECT @MaxSuffix = ISNULL(MAX(TRY_CAST(SUBSTRING(MaGiaoDich,3, 18) AS INT)), 0)
        FROM GIAODICH WITH (TABLOCK); -- giữ khóa đọc toàn bảng trong transaction để an toàn hơn

        DECLARE @Id1 INT = @MaxSuffix + 1;
        DECLARE @Id2 INT = @MaxSuffix + 2;

        DECLARE @MaGD_Chuyen VARCHAR(20) = 'GD' + RIGHT('00000' + CAST(@Id1 AS VARCHAR(10)), 5);
        DECLARE @MaGD_Nhan   VARCHAR(20) = 'GD' + RIGHT('00000' + CAST(@Id2 AS VARCHAR(10)), 5);

        DECLARE @Now DATETIME = GETDATE();

        -- Ghi log giao dịch (ghi rõ MaGiaoDich)
        INSERT INTO GIAODICH (MaGiaoDich, NgayGD, SoTien, MaNV, MaTK, MaLoaiGD)
        VALUES
            (@MaGD_Chuyen, @Now, @SoTien, @MaNV, @MaTKNguon, @MaLoaiGD_Chuyen);

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @ThongBao = N'Lỗi khi ghi giao dịch chuyển';
            RETURN;
        END;

        INSERT INTO GIAODICH (MaGiaoDich, NgayGD, SoTien, MaNV, MaTK, MaLoaiGD)
        VALUES
            (@MaGD_Nhan, @Now, @SoTien, @MaNV, @MaTKDich, @MaLoaiGD_Nhan);

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @ThongBao = N'Lỗi khi ghi giao dịch nhận';
            RETURN;
        END;

        -- Commit và trả kết quả
        COMMIT TRANSACTION;

        SET @TrangThai = 1;
        SET @ThongBao = N'Chuyển tiền thành công. Giao dịch chuyển #' 
                         + @MaGD_Chuyen 
                         + N', nhận #' 
                         + @MaGD_Nhan + N'.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @TrangThai = 0;
        SET @ThongBao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

DECLARE @trangthai INT, @thongbao NVARCHAR(4000);

EXEC sp_ChuyenTien
    @MaTKNguon = 'TK1002',
    @MaTKDich = 'TK1003',
    @SoTien = 200000,
    @MaNV = 'NV001',
    @MaLoaiGD_Chuyen = 'RT'
    @MaLoaiGD_Nhan = 'NT',
    @TrangThai = @trangthai OUTPUT,
    @ThongBao = @thongbao OUTPUT;

SELECT @trangthai AS TrangThai, @thongbao AS ThongBao;




/*
   lab2 Rút tiền:
        Yêu cầu: Phải kiểm tra số dư trong TAIKHOAN trước khi rút. Nếu đủ tiền, 
                trừ tiền (UPDATE TAIKHOAN) và ghi lại lịch sử (INSERT GIAODICH).

        Logic: Đây cũng là một TRANSACTION để đảm bảo 2 hành động xảy ra cùng lúc.
*/


CREATE OR ALTER PROCEDURE sp_RutTien
    @MaTK NVARCHAR(10),
    @SoTien DECIMAL(18,2),
    @MaNV VARCHAR(10),
    @MaLoaiGD INT,         -- mã loại giao dịch rút tiền
    @TrangThai INT OUT,
    @ThongBao NVARCHAR(4000) OUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @TrangThai = 0;
    SET @ThongBao = N'Lỗi không xác định.';

    BEGIN TRY
        -- 1️ Kiểm tra dữ liệu đầu vào
        IF @SoTien <= 0
        BEGIN
            SET @ThongBao = N'Số tiền phải lớn hơn 0';
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaTK = @MaTK)
        BEGIN
            SET @ThongBao = N'Tài khoản không tồn tại';
            RETURN;
        END

        DECLARE @SoDu DECIMAL(18,2);
        SELECT @SoDu = SoDu 
        FROM TAIKHOAN WITH (UPDLOCK, ROWLOCK)
        WHERE MaTK = @MaTK;

        IF @SoDu < @SoTien
        BEGIN
            SET @ThongBao = N'Số dư không đủ để rút.';
            RETURN;
        END

        -- 2️ Bắt đầu transaction
        BEGIN TRANSACTION;

        -- 3️ Trừ tiền
        UPDATE TAIKHOAN
        SET SoDu = SoDu - @SoTien
        WHERE MaTK = @MaTK;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @ThongBao = N'Lỗi khi trừ tiền tài khoản.';
            RETURN;
        END

        -- 4️ Sinh MaGiaoDich thủ công
        DECLARE @MaxSuffix INT;
        SELECT @MaxSuffix = ISNULL(MAX(TRY_CAST(SUBSTRING(MaGiaoDich,3,10) AS INT)),0)
        FROM GIAODICH WITH (TABLOCK); -- khóa toàn bảng để tránh trùng

        DECLARE @MaGiaoDich VARCHAR(20);
        SET @MaGiaoDich = 'GD' + RIGHT('00000' + CAST(@MaxSuffix + 1 AS VARCHAR(10)), 5);

        -- 5️ Ghi lịch sử giao dịch
        INSERT INTO GIAODICH(MaGiaoDich, MaTK, MaLoaiGD, SoTien, MaNV, NgayGD)
        VALUES (@MaGiaoDich, @MaTK, CAST(@MaLoaiGD AS VARCHAR(10)), @SoTien, @MaNV, GETDATE());

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @ThongBao = N'Lỗi khi ghi lịch sử giao dịch.';
            RETURN;
        END

        -- 6️ Commit transaction
        COMMIT TRANSACTION;

        SET @TrangThai = 1;
        SET @ThongBao = N'Rút tiền thành công. Mã GD: ' + @MaGiaoDich;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @TrangThai = 0;
        SET @ThongBao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
    END CATCH
END
GO

declare @trangthai int, @thongbao Nvarchar(4000)
exec sp_RutTien
    @MaTk = 'TK1002',
    @sotien = 500000,
    @MaNV = 'NV001',
    @MaLoaiGD = 1,
    @TrangThai = @trangthai out,
    @ThongBao = @thongbao out

select @trangthai as TrangThai, @thongbao as ThongBao


/*
    lab 3: Tạo Khách hàng & Mở Tài khoản:

        Yêu cầu: Nhân viên cần một chức năng "Mở tài khoản" duy nhất.

        Logic: SP này nhận vào TenKH, SDT, MaLoaiTK... Nó sẽ tự kiểm tra SDT đã tồn tại chưa.
                Nếu chưa, INSERT vào KHACHHANG trước, sau đó INSERT vào TAIKHOAN.
*/

CREATE OR ALTER PROCEDURE sp_MoTaiKhoan
    @TenKH NVARCHAR(100),
    @SDT VARCHAR(15),
    @MaLoaiTK INT,
    @SoDuBanDau DECIMAL(18,2),
    @MaNV VARCHAR(10),
    @TrangThai INT OUT,
    @ThongBao NVARCHAR(4000) OUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MaKH CHAR(10);
    DECLARE @MaTK CHAR(10);

    SET @TrangThai = 0;
    SET @ThongBao = N'Lỗi chưa xác định.';

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1️ Kiểm tra KH đã tồn tại chưa
        SELECT @MaKH = MaKH
        FROM KHACHHANG WITH (UPDLOCK)
        WHERE SDT = @SDT;

        -- 2️ Nếu chưa có -> tạo mới KH
        IF @MaKH IS NULL
        BEGIN
            DECLARE @MaxKH INT = ISNULL(
                (SELECT MAX(TRY_CAST(SUBSTRING(MaKH,3,10) AS INT)) FROM KHACHHANG WITH (TABLOCK)), 
                0
            );
            SET @MaKH = 'KH' + RIGHT('00000' + CAST(@MaxKH + 1 AS VARCHAR(10)), 5);

            INSERT INTO KHACHHANG(MaKH, TenKH, SDT)
            VALUES (@MaKH, @TenKH, @SDT);
        END

        -- 3️ Sinh mã tài khoản mới
        DECLARE @MaxTK INT = ISNULL(
            (SELECT MAX(TRY_CAST(SUBSTRING(MaTK,3,10) AS INT)) FROM TAIKHOAN WITH (TABLOCK)),
            0
        );
        SET @MaTK = 'TK' + RIGHT('00000' + CAST(@MaxTK + 1 AS VARCHAR(10)), 5);

        -- 4️ Tạo tài khoản
        INSERT INTO TAIKHOAN(MaTK, MaKH, MaLoaiTK, SoDu, NgayMo)
        VALUES (@MaTK, @MaKH, @MaLoaiTK, @SoDuBanDau, GETDATE());

        COMMIT TRANSACTION;

        SET @TrangThai = 1;
        SET @ThongBao = N'Mở tài khoản thành công. Mã TK: ' + @MaTK + N', Mã KH: ' + @MaKH;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @TrangThai = 0;
        SET @ThongBao = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
    END CATCH
END
GO

DECLARE @TrangThai INT, @ThongBao NVARCHAR(4000);
EXEC sp_MoTaiKhoan
    @TenKH = N'Nguyễn Văn A',
    @SDT = '0987123976',
    @MaLoaiTK = 1,
    @SoDuBanDau = 1000000,
    @MaNV = 'NV001',
    @TrangThai = @TrangThai OUTPUT,
    @ThongBao = @ThongBao OUTPUT;
SELECT @TrangThai AS TrangThai, @ThongBao AS ThongBao;



/*

    lab 4: Tính lãi hàng loạt:

        Yêu cầu: Vào cuối tháng, hệ thống phải tự động chạy để cộng tiền lãi cho tất cả các tài khoản đang hoạt động.

        Logic: Dùng con trỏ (Cursor) hoặc WHILE để lặp qua TAIKHOAN, tính lãi dựa trên LaiSuat 
                (từ LOAITAIKHOAN) và SoDu, sau đó UPDATE SoDu mới.

*/
create or alter proc sp_tinhlaii
    @MaTK varchar(20)
as
begin
    set nocount on;

    declare @soduhientai money;
    declare @laixuat float;
    declare @tienlai money;

    select 
        @soduhientai = SoDu,
        @laixuat = l.LaiSuat
            from TAIKHOAN t
            inner join LOAITAIKHOAN l 
                on t.MaLoaiTK = l.MaLoaiTK
            where t.MaKH = @MaTK
    if @soduhientai is null
    begin
        print N'lỗi: không tìm thấy TK ' + @MaTK;
        return;
    end

    set @tienlai = @soduhientai *@laixuat;
    update TAIKHOAN
    set SoDu = SoDu + @tienlai
    where MaTK = @MaTK

    print N'--- kết quả ----'
    print N'Tài Khoản' + @MaTK
    PRINT N'Số dư gốc: ' + CAST(@SoDuHienTai AS NVARCHAR(50));
    PRINT N'Tiền lãi cộng thêm: ' + CAST(@TienLai AS NVARCHAR(50));
    PRINT N'Số dư mới: ' + CAST((@SoDuHienTai + @TienLai) AS NVARCHAR(50));
end
EXEC sp_tinhlaii 'TK1003';
select * from TAIKHOAN
/*
    lab 5: In Sao kê (Báo cáo linh hoạt):

        Yêu cầu: Cần một báo cáo để lấy lịch sử giao dịch chi tiết của một tài khoản 
            (MaTK) trong một khoảng thời gian (TuNgay, DenNgay).

        Logic: SP này nhận 3 tham số và trả về một tập kết quả (dùng SELECT phức tạp từ V_LichSuGiaoDich_ChiTiet).
*/
create or alter view V_LichSuGiaoDich_ChiTiet as
select 
    gd.MaGiaoDich,
    gd.MaTK,
    gd.NgayGD,
    gd.SoTien,
    lgd.TenLoaiGD,      
    nv.TenNV AS NguoiThucHien 
    from GIAODICH gd
    inner join LOAIGIAODICH lgd on gd.MaLoaiGD = lgd.MaLoaiGD
    inner join NHANVIENGIAODICH nv on gd.MaNV = nv.MaNV 

    select * from V_LichSuGiaoDich_ChiTiet
create or alter proc sp_insaoke
    @MaTK varchar(20),
    @TuNgay datetime,
    @DenNgay datetime
as
begin
    if not exists (select 1 from TAIKHOAN where MaTK = @MaTK)
    begin
        print N'Không tìm thấy tk này'
        return;
    end
    SELECT * FROM V_LichSuGiaoDich_ChiTiet
    WHERE MaTK = @MaTK
      AND CAST(NgayGD AS DATE) >= @TuNgay
      AND CAST(NgayGD AS DATE) <= @DenNgay
    ORDER BY NgayGD DESC;
end

EXEC sp_InSaoKe 
    @MaTK = 'TK1001', 
    @TuNgay = '2025-10-20', 
    @DenNgay = '2025-10-21';

