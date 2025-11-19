use QLNH
-- trigger


/*
Ghi Log thay đổi SĐT (Auditing):

Yêu cầu: Phải ghi lại dấu vết mỗi khi ai đó thay đổi SĐT của khách hàng vì lý do bảo mật.

Logic: Tạo AFTER UPDATE Trigger trên bảng KHACHHANG. Nếu cột SDT bị thay đổi, INSERT vào bảng Log_ThayDoi (chứa MaKH, SDTCu, SDTMoi, NguoiSua, NgaySua).
*/

-- tạo bảng log để ghi vào
CREATE TABLE Log_ThayDoi (
    MaLog INT IDENTITY PRIMARY KEY,
    MaKH varchar(10),
    SDTCu NVARCHAR(15),
    SDTMoi NVARCHAR(15),
    NguoiSua NVARCHAR(100),
    NgaySua DATETIME
);


create or alter trigger trg_DML_thaysdt
on KHACHHANG
after update
as
begin
	set nocount on;

	if update(SDT)
	begin
		insert into Log_ThayDoi (MaKH, SDTcu, SDTmoi, NguoiSua, NgaySua)
		select
			d.MaKH,
			d.SDT as sdt_cu,
			i.SDT as sdt_moi,
			SUSER_SNAME() as nguoisua,
			GETDATE() as ngaysua
		from deleted d
		inner join inserted i on d.MaKH = i.MaKH
		where d.SDT <> i.SDT
	end
end

select * from KHACHHANG

update KHACHHANG
set SDT = '092548452'
where MaKH = 'KH001'

select * from Log_ThayDoi

SELECT kh.MaKH, kh.TenKH, kh.SDT, log.SDTCu, log.SDTMoi, log.NgaySua
FROM KHACHHANG kh
LEFT JOIN Log_ThayDoi log ON kh.MaKH = log.MaKH
ORDER BY log.NgaySua DESC;

SELECT * FROM sys.triggers;
sp_helptext 'trg_DML_ThaySDT';


/*
Ngăn chặn xóa Tài khoản còn tiền:

Yêu cầu: Không ai được phép DELETE một TAIKHOAN nếu SoDu của nó vẫn > 0.

Logic: Tạo FOR DELETE Trigger trên bảng TAIKHOAN. Kiểm tra SoDu của hàng đang bị xóa (từ bảng deleted), nếu > 0, báo lỗi RAISERROR và ROLLBACK.
*/

create or alter trigger trg_nganxoatk
on TAIKHOAN
after delete
as
begin
	set nocount on;
	if exists (
		select 1
		from deleted
		where SoDu > 0
	)
	begin
		-- báo lỗi và hủy thao tavs
		raiserror('không được phép xóa tài khoản còn tiền!', 16, 1);
		rollback transaction
		return;
	end
	
end

select * from TAIKHOAN
delete from TAIKHOAN
where MaTK = 'TK1001'


/*
Ngăn giao dịch âm:

Yêu cầu: Đảm bảo không ai có thể INSERT một GIAODICH với SoTien là số âm.

Logic: Tạo FOR INSERT Trigger trên bảng GIAODICH. Kiểm tra SoTien của hàng vừa chèn (từ bảng inserted), nếu < 0, báo lỗi và ROLLBACK.
*/

create or alter trigger trg_checkgiaodich
on GIAODICH
for insert 
as
begin
	set nocount on;

	if exists (
		select 1
		from inserted
		where SoTien < 0
	)
	begin
		raiserror('không được phép chèn giao dịch có số tiền âm', 16, 1);
		rollback transaction;
		return;
	end
end

-- thử chèn giao dịch âm
INSERT INTO GIAODICH (MaGiaoDich, NgayGD, SoTien, MaNV, MaTK, MaLoaiGD)
VALUES ('GD00007', GETDATE(), -1000.00, 'NV002', 'TK1002', 'RT');

select * from GIAODICH


/*
Cập nhật TongSoDu (Denormalization):

Yêu cầu: Bảng KHACHHANG có một cột TongSoDu (tổng tiền của tất cả tài khoản). Cột này phải tự cập nhật.

Logic: Tạo AFTER INSERT, UPDATE, DELETE Trigger trên bảng TAIKHOAN. Mỗi khi SoDu thay đổi, tính lại tổng SoDu của MaKH bị ảnh hưởng và UPDATE vào bảng KHACHHANG.
*/

ALTER TABLE KHACHHANG
ADD TongSoDu DECIMAL(18,2) DEFAULT 0;

create or alter trigger trg_UpdateTongSoDu
on TAIKHOAN
after insert, update, delete
as
begin
	set nocount on;

	declare @AffectedKH table (MaKH varchar(10) primary key);

	insert into @AffectedKH(MaKH)
	select distinct MaKH
	from inserted
	where MaKH is not null;

	insert into @AffectedKH(MaKH)
	select distinct MaKH 
	from deleted
	where MaKH is not null
	and MaKH not in (select MaKH from @AffectedKH)

	update kh
	set TongSoDu = ISNULL(t.SoDuTong,0)
	from KHACHHANG kh
	inner join (
		select MaKH, SUM(SoDu) as sodutong
		from TAIKHOAN 
		where MaKH in (select MaKH from @AffectedKH)
		group by MaKH
	)t on kh.MaKH = t.MaKH

end

UPDATE TAIKHOAN
SET SoDu = 3000
WHERE MaTK = 'TK001';
SELECT MaKH, TongSoDu FROM KHACHHANG;


/*
Cảnh báo giao dịch lớn:

Yêu cầu: Tự động gửi cảnh báo nếu có giao dịch (rút hoặc chuyển) lớn hơn 500 triệu.

Logic: Tạo AFTER INSERT Trigger trên bảng GIAODICH. Nếu MaLoaiGD là 'RutTien' và SoTien > 500,000,000, INSERT một dòng vào bảng GiaoDichCanhBao để quản lý xem xét.
*/
CREATE TABLE GiaoDichCanhBao (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    MaGiaoDich VARCHAR(20),       -- Nên cùng kiểu dữ liệu với GIAODICH.MaGiaoDich
    MaTaiKhoan VARCHAR(20),       -- Nên cùng kiểu dữ liệu với GIAODICH.MaTK
    SoTien MONEY,                 -- Nên cùng kiểu dữ liệu với GIAODICH.SoTien
    ThoiGianGiaoDich DATETIME,    -- Nên cùng kiểu dữ liệu với GIAODICH.NgayGD
    LyDoCanhBao NVARCHAR(255)
);

create or alter trigger trig_canhbao
on GIAODICH
after insert 
as
begin
	set nocount on;
	insert into GiaoDichCanhBao(
		MaGiaoDich,
		MaTaiKhoan,
		SoTien,
		ThoiGianGiaoDich,
		LyDoCanhBao
	)
	select
		i.MaGiaoDich,
		i.MaTK,
		i.SoTien,
		i.NgayGD,
		N'Giao Dịch Rút Tiền Lớn Hơn 500M'
		from inserted i
		inner join LOAIGIAODICH l on i.MaLoaiGD = l.MaLoaiGD
		where l.TenLoaiGD = N'Rút tiền' and i.SoTien > 500000000;
end

INSERT INTO GIAODICH (
    MaGiaoDich, 
    NgayGD, 
    SoTien, 
    MaNV, 
    MaTK, 
    MaLoaiGD
)
VALUES (
    'GD00011',         
    GETDATE(),       
    600000000,       
    'NV002',          
    'TK1002',         
    'RT'          
);

create or alter trigger trg_check_giolamviec
on all server   -- áp dụng cho toàn bộ máy chủ
for logon		-- kích hoạt khi có sự kiện logon
as
begin
	set nocount on;
	declare @NgayTrongTuan varchar(20) = datename(WEEKDAY, getdate())

	if (@NgayTrongTuan = 'sunday' and ORIGINAL_LOGIN() <> 'sa')
	begin
	raiserror('khong duoc phep dang nhap vao chu nhat', 16,1);
	rollback;
	end
end

