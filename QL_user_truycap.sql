-- 6.1 Quản lý người dùng và quyền truy cập
/*
/*
==========================================================================
GIẢI THÍCH LỆNH CREATE LOGIN VÀ CÁC TÙY CHỌN
Bạn có thể dán (paste) toàn bộ file này vào SQL Server để tham khảo.
==========================================================================
*/

-- Lệnh `CREATE LOGIN` dùng để tạo một "Tài khoản đăng nhập" mới
-- ở cấp độ Server. Tài khoản này cho phép kết nối vào SQL Server.
-- (Nó khác với CREATE USER, là tạo người dùng ở cấp độ Database).

--========================================================================
-- MẪU 1: CƠ BẢN NHẤT (Tạo Login với mật khẩu cụ thể)
--========================================================================

-- Đây là lệnh tạo login tên 'NhanVienA' với mật khẩu 'P@ssword!123'.
-- Mật khẩu này PHẢI tuân thủ chính sách bảo mật của Windows.
CREATE LOGIN NhanVienA
    WITH PASSWORD = 'P@ssword!123';
GO

--========================================================================
-- MẪU 2: TÙY CHỌN PHỔ BIẾN (Cho Môi trường Test/Dev)
--========================================================================

CREATE LOGIN TaiKhoanTest
    -- WITH PASSWORD: Chỉ định mật khẩu cho tài khoản.
    WITH PASSWORD = '123',

    -- DEFAULT_DATABASE: Chỉ định CSDL mặc định.
    -- Khi login này đăng nhập, họ sẽ tự động được trỏ vào CSDL này.
    DEFAULT_DATABASE = QLNH,

    -- CHECK_POLICY = OFF: TẮT kiểm tra chính sách mật khẩu.
    -- Cho phép bạn đặt mật khẩu yếu (như '123') mà không bị lỗi.
    -- CHỈ DÙNG CHO MÔI TRƯỜNG TEST.
    CHECK_POLICY = OFF,

    -- CHECK_EXPIRATION = OFF: TẮT kiểm tra hết hạn mật khẩu.
    -- Mật khẩu sẽ không bao giờ bị hết hạn.
    CHECK_EXPIRATION = OFF;
GO

--========================================================================
-- MẪU 3: ĐẦY ĐỦ TÙY CHỌN THƯỜNG DÙNG
--========================================================================

CREATE LOGIN NhanVienMoi
    WITH PASSWORD = 'T@mThoi12345',

    -- MUST_CHANGE: Bắt buộc người dùng phải đổi mật khẩu
    -- ngay trong lần đăng nhập đầu tiên. Rất bảo mật khi cấp tài khoản mới.
    MUST_CHANGE,

    -- DEFAULT_DATABASE: Đặt CSDL mặc định là 'master'.
    DEFAULT_DATABASE = master,

    -- DEFAULT_LANGUAGE: Đặt ngôn ngữ mặc định (ví dụ: cho thông báo lỗi).
    -- Mặc định là 'us_english'.
    DEFAULT_LANGUAGE = us_english,

    -- CHECK_POLICY = ON: (Đây là giá trị mặc định)
    -- BẬT kiểm tra chính sách mật khẩu (độ dài, độ phức tạp...).
    CHECK_POLICY = ON;
GO

--========================================================================
-- CÁC TÙY CHỌN NÂNG CAO (Ít dùng hơn)
--========================================================================

/*
-- HASHED: Tạo login từ một mật khẩu đã được hash (băm).
-- Thường dùng khi bạn cần di chuyển login từ Server cũ sang Server mới
-- và muốn giữ nguyên mật khẩu mà không cần biết mật khẩu đó là gì.
CREATE LOGIN LoginDiChuyen
    WITH PASSWORD = 0x0200...[CHUOI_HASH_DAI_NAM_O_DAY]... HASHED;
*/


/*
-- SID (Security Identifier): Chỉ định một SID cụ thể cho Login.
-- Cực kỳ quan trọng khi bạn cần đồng bộ Login/User giữa các Server,
-- ví dụ như trong môi trường High Availability (AlwaysOn)
-- để tránh lỗi "orphaned users" (user mồ côi).
CREATE LOGIN LoginDongBo
    WITH PASSWORD = 'some_password',
    SID = 0x010500000000000515000000...[CHUOI_SID_DA_LAY_TU_SERVER_GOC]...;
*/


/*
-- CREDENTIAL: Ánh xạ Login này tới một Credential đã được tạo.
-- Dùng cho các kịch bản xác thực nâng cao, ví dụ như
-- xác thực qua Azure Key Vault hoặc các dịch vụ bên ngoài.
CREATE LOGIN LoginTuCredential
    WITH CREDENTIAL = TenCredentialDaTao;
*/
*/



-- lệnh tạo login
create login develop
	with password = '1',	    -- must_change nếu muốn đổi mật khẩu khi đăng nhập
	default_database = QLNH,	-- chỉ định database mặc định
	check_policy = off			-- tắ kiểm tra chính sách bảo mật (chỉ nên dùng khi test)
go

create login phunnam
    with password = '2',
    default_database = QLNH,
    check_policy = off
go

use QLNH
go
-- tạo tên user theo tên [tenuser] và liên kết với login [tenlogin]
create user phuongnam for login develop
go

create user khachhang for login phunnam
go


-- cấp quyền grant (lệnh cho phép user làm gì đó)
grant select on CHINHANH to phuongnam

grant insert, update on GIAODICH to phuongnam

-- thu hồi quyền revoke (lấy lại quyền grand trước đó) hủy cả grant và deny
revoke update on GIAODICH to phuongnam

-- cấm quyền deny
/*
    deny cấm mạnh hơn revoke. deny là một lệnh cấm tuyệt đối ,ngay cả khi user đó
    thuộc một role(vai trò) có quyền, quyền deny luôn đc ưu tiên cao nhất
*/

deny delete on TAIKHOAN to phuongnam


-- phân vai trò role
create role nhanviennganhang;
go

grant select, insert, update, delete on KHACHHANG to nhanviennganhang
grant select, insert, update, delete on GIAODICH to nhanviennganhang

alter ROLE nhanviennganhang add member phuongnam

-- tạo schema 
create schema HR;
create schema sales;
create schema finance;
go;

alter schema HR transfer dbo.GIAODICH
alter schema sales transfer dbo.KHACHHANG


grant select on schema::hr to phunnam


revoke select on schema::hr from phunnam