/*
	view
*/

/*
-- view lấy thông tin khách hàng - tài khoản
	mục đích: tạo một bảng đơn giản cho nhân viên xem nhanh thông tin của khách hàng
		và tài khoản họ sở hữu mà không cần join 4 bảng
*/

create or alter view View_KHACHHANG as 
select 
	kh.TenKH,
	kh.SDT,
	tk.MaTK,
	tk.SoDu,
	ltk.TenLoaiTK,
	ltk.LaiSuat,
	cn.TenChiNhanh,
	cn.DiaChi as DiaChiChiNhanh
	from KHACHHANG as kh
	inner join TAIKHOAN as tk
			on kh.MaKH = tk.MaKH
	inner join LOAITAIKHOAN as ltk 
			on tk.MaLoaiTK = ltk.MaLoaiTK
	inner join CHINHANH as cn 
			on tk.MaChiNhanh = cn.MaChiNhanh

select * from View_KHACHHANG

/*
	view lịch sử giao dịch (đơn giản hóa & làm rõ nghĩa)
	mục đích: cung cấp một bản sao kê dễ đọc. Bảng GIAODICH gốc chỉ lưu các ma...,
		rất khó đọc
*/

create or alter view V_lichsugiaodich as
select 
	gd.MaGiaoDich,
	gd.NgayGD,
	gd.SoTien,
	lgd.TenLoaiGD,
	gd.MaTK,
	nvgd.TenNV
	from GIAODICH as gd
	left join LOAIGIAODICH as lgd 
		on gd.MaLoaiGD = lgd.MaLoaiGD
	left join NHANVIENGIAODICH as nvgd
		on gd.MaGiaoDich = nvgd.MaChiNhanh

select * from V_lichsugiaodich


/*
	View Báo cáo Tổng hợp (Dùng cho Indexed View)
	Mục đích: Tạo một báo cáo tổng hợp (dùng cho sếp hoặc quản lý) xem hiệu 
			suất của các chi nhánh.
*/

create or alter view V_BaoCao_TaiKhoan_ChiNhanh 
with SCHEMABINDING
as
select 
	tk.MaChiNhanh,
	COUNT_BIG(*) as tongsotk,
	sum(isnull(tk.SoDu, 0)) as tongsodu
	from [dbo].[TAIKHOAN] as tk
	group by
		tk.MaChiNhanh
go

create unique clustered index IDX_V_BaoCao_TaiKhoan_ChiNhanh 
on V_BaoCao_TaiKhoan_ChiNhanh (MaChiNhanh);
go

select * from V_BaoCao_TaiKhoan_ChiNhanh 

/*
	View Bảo mật (Che giấu dữ liệu nhạy cảm)
	Mục đích: Cung cấp cho một bộ phận (ví dụ: marketing hoặc phân tích) quyền xem dữ liệu khách hàng nhưng ẩn 
			đi thông tin cá nhân nhạy cảm
*/


CREATE VIEW V_ThongTinKhachHang_BaoMat AS
SELECT
    kh.MaKH,
    -- Giả sử TenKH là "Nguyễn Văn An", hàm này sẽ lấy "An"
    -- Nếu bạn muốn lấy họ "Nguyễn", dùng: LEFT(kh.TenKH, CHARINDEX(' ', kh.TenKH + ' ') - 1)
    RIGHT(kh.TenKH, CHARINDEX(' ', REVERSE(kh.TenKH) + ' ') - 1) AS TenKhachHang,
    tk.MaLoaiTK,
    tk.SoDu
FROM
    KHACHHANG AS kh
JOIN
    TAIKHOAN AS tk ON kh.MaKH = tk.MaKH;

select * from V_ThongTinKhachHang_BaoMat
