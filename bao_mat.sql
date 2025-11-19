-- bảo mật csdl
/*
==========================================================================
SCRIPT KÍCH HOẠT MÃ HÓA TDE (TRANSPARENT DATA ENCRYPTION)
==========================================================================
*/

-- BƯỚC 1: Tạo Chìa khóa chủ (Database Master Key) trong 'master'
-- (Chìa khóa này sẽ bảo vệ Chứng chỉ ở bước 2)
-- Nếu bạn đã có Master Key rồi, bước này sẽ báo lỗi, nhưng không sao,
-- cứ tiếp tục sang bước 2.
--------------------------------------------------------------------------
USE master;
GO
--CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'phuongnam@3333';
GO


-- BƯỚC 2: Tạo Chứng chỉ (Certificate) trong 'master'
-- (Chứng chỉ này sẽ dùng để bảo vệ chìa khóa mã hóa CSDL)
-- Đặt tên Chứng chỉ (TdeCert) theo ý bạn.
--------------------------------------------------------------------------
USE master;
GO
CREATE CERTIFICATE pnam
WITH SUBJECT = 'Chung Chi Dung De Ma Hoa TDE';
GO


-- BƯỚC 3: Tạo Chìa khóa Mã hóa CSDL (Database Encryption Key - DEK)
-- Chìa khóa này được lưu trong CSDL của bạn và được bảo vệ bởi
-- Chứng chỉ (TdeCert) mà chúng ta vừa tạo ở bước 2.
--------------------------------------------------------------------------
USE [QLNH]; -- <-- THAY TÊN DB CỦA BẠN Ở ĐÂY
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE pnam;
GO


-- BƯỚC 4: KÍCH HOẠT MÃ HÓA TDE
-- **HÃY ĐỔI [TenDatabaseCuaBan] thành tên database của bạn (ví dụ: QLNH)**
-- Đây là lúc quá trình mã hóa BẮT ĐẦU.
-- Tùy CSDL lớn hay nhỏ, quá trình này có thể mất vài giây đến vài giờ.
--------------------------------------------------------------------------
ALTER DATABASE  [QLNH]-- <-- THAY TÊN DB CỦA BẠN Ở ĐÂY
SET ENCRYPTION ON;
GO


/*
==========================================================================
KIỂM TRA TRẠNG THÁI MÃ HÓA
==========================================================================
*/

-- Chạy lệnh này để xem trạng thái mã hóa.
-- encryption_state = 3 là ĐÃ MÃ HÓA (ENCRYPTED)
-- encryption_state = 2 là ĐANG MÃ HÓA (ENCRYPTION_IN_PROGRESS)
-- encryption_state = 1 là CHƯA MÃ HÓA (UNENCRYPTED)
--------------------------------------------------------------------------
USE master;
GO
SELECT
    db.name,
    db.is_encrypted,
    dm.encryption_state,
    dm.percent_complete
FROM
    sys.databases AS db
LEFT JOIN
    sys.dm_database_encryption_keys AS dm
    ON db.database_id = dm.database_id;
GO


/*
==========================================================================
BACKUP CHỨNG CHỈ (CỰC KỲ QUAN TRỌNG)
==========================================================================
*/
USE master;
GO

-- Backup Chứng chỉ và Khóa riêng (Private Key) ra file
-- Hãy lưu 2 file này (TdeCert.cer và TdeCert.pvk) ở một nơi an toàn
-- (ví dụ: USB, Google Drive,...)
BACKUP CERTIFICATE pnam
TO FILE = 'D:\Backup\TdeCert.cer' -- Bạn có thể đổi đường dẫn
WITH PRIVATE KEY (
    FILE = 'D:\Backup\TdeCert.pvk', -- Bạn có thể đổi đường dẫn
    ENCRYPTION BY PASSWORD = 'phuongnam@3333'
);
GO

USE master;
GO
SELECT 
    db.name,
    db.is_encrypted,
    dm.encryption_state,
    dm.percent_complete
FROM sys.databases db
LEFT JOIN sys.dm_database_encryption_keys dm
    ON db.database_id = dm.database_id
WHERE db.name = 'QLNH';
GO







