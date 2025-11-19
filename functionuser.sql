use QLNH
/*
 function user
*/


/*
	lab 1: Lấy Tên Khách hàng (Scalar Function):

		Yêu cầu: Cần một cách nhanh để lấy TenKH chỉ từ MaKH.

		Logic: Hàm nhận vào MaKH, trả về TenKH (kiểu NVARCHAR). Dùng trong các câu SELECT để làm báo cáo dễ đọc hơn.
*/
create or alter function fn_laytenkh
(
	@makh varchar(10)
)
returns nvarchar(100)
as
begin
	declare @tenkh nvarchar(100);

	select @tenkh = TenKH 
		from KHACHHANG
		where MaKH = @makh

	return @tenkh;
end;

-- cách gọi 1 
select dbo.fn_laytenkh('KH001') as tenkh


/*
	lab 2: Tính Lãi suất thực (Scalar Function):

		Yêu cầu: Cần một hàm để tính số tiền lãi dự kiến cho một tài khoản.

		Logic: Hàm nhận vào MaTK, trả về SoTienLai (kiểu DECIMAL). Bên trong, nó SELECT SoDu * LaiSuat / 100.
*/

create or alter function fn_tinhlaixuat
(
	@matk varchar(10)
)
returns decimal(18, 2)
as
begin
	declare @sotienlai decimal(18,2)

	select 
		@sotienlai = (tk.SoDu * ltk.LaiSuat / 100)
		from TAIKHOAN tk
		inner join LOAITAIKHOAN ltk 
			on tk.MaLoaiTK = ltk.MaLoaiTK
		where tk.MaTK = MaTK
	return @sotienlai
end

select dbo.fn_tinhlaixuat('TK003') as tienlaitk

/*
	lab 3: Lấy Trạng thái Tài khoản (Scalar Function):

		Yêu cầu: Cần biết tài khoản "Bình thường", "Bị âm tiền" hay "Sắp hết hạn".

		Logic: Hàm nhận vào MaTK, dùng CASE WHEN trên SoDu và NgayMo để trả về một chuỗi trạng thái (ví dụ: 'Hoạt động').
*/

create or alter function fn_laytrangthaitk
(
	@matk varchar(10)
)
returns nvarchar(100)
as
begin
	declare @trangthai nvarchar(100);

	select 
		@trangthai = case
			when SoDu < 0 then 'đang nợ'
			when DATEDIFF(YEAR, NgayMo, GETDATE()) > 5 then N'tài khoản cũ sắp hết hạn'
			else N'bình thường'
		end 
		from TAIKHOAN
		where MaTK = @matk
	return @trangthai
end

select dbo.fn_laytrangthaitk('TK002') as trangthai


/*
	lab 4: Lấy tất cả Tài khoản của Khách (Inline Table-Valued Function):

		Yêu cầu: Cần một cách để lấy tất cả tài khoản của một khách hàng (giống như một View có tham số).

		Logic: Hàm nhận vào MaKH, trả về TABLE (kết quả của SELECT * FROM TAIKHOAN WHERE MaKH = @MaKH).
*/
create or alter function fn_laytkhach
(
	@makh varchar(10)
)
returns table
as
return
(
	select 
	*
	from TAIKHOAN
	where MaKH = @makh
)

select * from fn_laytkhach('KH001');


/*
	lab 5: Chuẩn hóa Tên (Scalar Function):

		Yêu cầu: Dữ liệu nhập vào có thể là "nguyễn văn AN". Cần chuẩn hóa thành "Nguyễn Văn An".

		Logic: Hàm nhận vào một chuỗi Ten, trả về chuỗi đã được chuẩn hóa.
*/

CREATE OR ALTER FUNCTION fn_chuanhoa
(
    @ten NVARCHAR(100)
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE 
        @tenchuanhoa NVARCHAR(100) = N'',
        @i INT = 1,
        @len INT,
        @ch NVARCHAR(1),
        @upcoming BIT = 1;

    -- Loại bỏ khoảng trắng thừa đầu cuối
    SET @ten = LTRIM(RTRIM(@ten));
    SET @len = LEN(@ten);

    WHILE @i <= @len
    BEGIN
        SET @ch = SUBSTRING(@ten, @i, 1);

        IF @ch = N' '
        BEGIN
            SET @tenchuanhoa += @ch;
            SET @upcoming = 1; -- sau khoảng trắng, chữ cái kế tiếp cần viết hoa
        END
        ELSE
        BEGIN
            IF @upcoming = 1
                SET @tenchuanhoa += UPPER(@ch);
            ELSE
                SET @tenchuanhoa += LOWER(@ch);
            SET @upcoming = 0;
        END

        SET @i += 1;
    END

    RETURN @tenchuanhoa;
END;
GO
SELECT dbo.fn_chuanhoa(N'nguyễn văn AN') AS TenChuanHoa;


/*
=================================================================
🧾 Đề Lab 6 – Multi-statement Table-Valued Function

	Đề bài:
	Viết hàm fn_TraCuuGiaoDichTheoKH nhận vào mã khách hàng (@MaKH)
	và trả về bảng gồm các giao dịch của khách đó,
bao gồm:

	Mã giao dịch
	Ngày giao dịch
	Loại giao dịch
	Số tiền
	Mã tài khoản
	Tên nhân viên thực hiện

Hàm phải:

	Có thể trả về nhiều dòng.

Viết theo kiểu đa câu lệnh (multi-statement), nghĩa là phải dùng biến bảng (@result) trong thân hàm.

*/=========================================================================

create or alter function fn_tracuugiaodichtheokh
(
	@makh varchar(10)
)
returns @Result table
(
	MaGiaoDich varchar(10),
	NgayGD datetime,
	TenLoaiGD nvarchar(100),
	SoTien decimal(18,2),
	MaTK varchar(10),
	TenNV nvarchar(100)
)
as
begin
	insert into @Result
	 SELECT 
        gd.MaGiaoDich,
        gd.NgayGD,
        lgd.TenLoaiGD,
        gd.SoTien,
        tk.MaTK,
        nv.TenNV
    FROM GIAODICH gd
    INNER JOIN TAIKHOAN tk ON gd.MaTK = tk.MaTK
    INNER JOIN LOAIGIAODICH lgd ON gd.MaLoaiGD = lgd.MaLoaiGD
    LEFT JOIN NHANVIENGIAODICH nv ON gd.MaNV = nv.MaNV
    WHERE tk.MaKH = @MaKH;
	return;
end

select * from dbo.fn_tracuugiaodichtheokh('KH001')

/*
=================================================================
🧩 Lab 7 — Tra cứu giao dịch theo khoảng ngày
	🧾 Đề bài:
	Viết hàm fn_TraCuuGiaoDichTheoNgay nhận vào:

		@TuNgay DATE
		@DenNgay DATE

	Trả về danh sách giao dịch trong khoảng thời gian đó, gồm:
	MaGiaoDich, TenLoaiGD, SoTien, NgayGD, TenKH, TenNV, TenChiNhanh.

*/=========================================================================
create or alter function fn_TraCuuGiaoDichTheoNgay
(
	@tungay date,
	@dengay date
)
returns @result table
(
	MaGiaoDich varchar(10),
	TenLoaiGD nvarchar(100),
	SoTien decimal(18,2),
	NgayGD datetime,
	TenKH Nvarchar(100),
	TenNV nvarchar(100),
	TenChiNhanh nvarchar(100)
)
as
begin
	insert into @result
	 SELECT 
        gd.MaGiaoDich,
        lgd.TenLoaiGD,
        gd.SoTien,
        gd.NgayGD,
        kh.TenKH,
        nv.TenNV,
        cn.TenChiNhanh
    FROM GIAODICH gd
    INNER JOIN TAIKHOAN tk ON gd.MaTK = tk.MaTK
    INNER JOIN KHACHHANG kh ON tk.MaKH = kh.MaKH
    LEFT JOIN NHANVIENGIAODICH nv ON gd.MaNV = nv.MaNV
    LEFT JOIN CHINHANH cn ON tk.MaChiNhanh = cn.MaChiNhanh
    INNER JOIN LOAIGIAODICH lgd ON gd.MaLoaiGD = lgd.MaLoaiGD
    WHERE CAST(gd.NgayGD AS DATE) BETWEEN @TuNgay AND @DenNgay;
	return;
end

select * from fn_TraCuuGiaoDichTheoNgay('2023-10-20', '2023-10-25')




