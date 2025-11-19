use QLNH
-- 6.3 Quản lý sao lưu và phục hồi
/*
-- back up file (full backup)
*/

backup database QLNH
to disk = 'E:\SQL_Backup\QLNH_Full_2025_11_13.bak'	 -- dường dẫn nơi lưu file
with format,										 -- tạo mới file backup, định dạng lại thiết bị sao lưu
	init,											 -- ghi đè file backup nếu có
	name = 'BACKUP FULL 11-13-2025',				 -- tên mô tả cho bản backup
	medianame = 'quan li ngan hang backup',
	skip,
	stats = 10;										 -- hiển thị tiến trình 10% một lần



/*
-- Restore từ file .bak thành database mới
*/

RESTORE DATABASE QLNH_Restore
FROM DISK = 'E:\SQL_Backup\QLNH_Full_2025_11_13.bak'		-- đường dẫn file backup
WITH 
    MOVE 'QLNH' TO 'E:\SQLData\QLNH_Restore.mdf',			-- Tên logical name của file dữ liệu (.mdf)
    MOVE 'QLNH_log' TO 'E:\SQLData\QLNH_Restore_log.ldf',	-- Tên logical name của file log (.ldf)
    STATS = 10;												-- Hiển thị tiến trình 10% một lần

/*
	Restore ghi đè database cũ
	WITH REPLACE → cho phép ghi đè database cũ.

	SINGLE_USER → đảm bảo không ai đang truy cập database khi restore.
*/

USE master;
ALTER DATABASE QLNH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE QLNH
FROM DISK = 'E:\SQL_Backup\QLNH_Full_2025_11_13.bak'
WITH REPLACE, STATS = 10;

ALTER DATABASE QLNH SET MULTI_USER;

RESTORE FILELISTONLY
FROM DISK = 'D:\Backup\QLNH_Full_2025_11_13.bak';

