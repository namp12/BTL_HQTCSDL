-- tối ưu hóa hiệu suất csdl


/*
	6.4 Quản lý hiệu suất cơ sở dữ liệu
1. Tối ưu hóa truy vấn (Query Optimization)

Mục tiêu: giảm thời gian thực thi và giảm tải cho máy chủ.

Kỹ thuật chính

Chọn lọc cột (SELECT cột cần thiết)
→ Không dùng SELECT *.

Lọc sớm ở WHERE
→ WHERE càng cụ thể, dữ liệu lấy ra càng ít → nhanh hơn.

Dùng JOIN đúng cách

Ưu tiên INNER JOIN khi có thể.

JOIN theo cột có index.

Tránh subquery lồng nhau phức tạp
→ Dùng JOIN hoặc CTE (WITH) khi phù hợp.

Sử dụng LIMIT / TOP khi chỉ cần một số dòng nhỏ.

Tránh hàm trên cột trong WHERE
(ví dụ WHERE YEAR(Ngay) = 2025 → chậm)
→ dùng WHERE Ngay >= '2025-01-01' AND Ngay < '2026-01-01'.

2. Tối ưu hóa chỉ mục (Index Optimization)

Mục tiêu: tăng tốc độ tìm kiếm, JOIN, ORDER BY, GROUP BY.

Khi nào cần index

Cột dùng trong WHERE

Cột dùng trong JOIN

Cột dùng trong ORDER BY / GROUP BY

Cột có dữ liệu lặp ít (selectivity cao)

Các loại index quan trọng

Clustered Index

Quyết định cách dữ liệu sắp xếp vật lý trong bảng

Thường đặt ở khóa chính (PK)

Non-clustered Index

Giúp tăng tốc truy vấn trên cột không phải PK

Composite Index (đa cột)

Chú ý thứ tự cột (tối ưu cho điều kiện từ trái sang phải)

Covering Index

Index chứa tất cả các cột truy vấn → SELECT không cần đọc bảng

Lưu ý: Index nhiều quá → INSERT/UPDATE/DELETE chậm.

3. Tối ưu hóa cấu trúc bảng và dữ liệu

Chuẩn hóa dữ liệu (3NF) để giảm trùng lặp → truy vấn nhanh hơn

Backup và bảo trì định kỳ

Rebuild/Reorganize Index

Update statistics

Partitioning

Chia bảng lớn (hàng triệu bản ghi) thành các phần nhỏ theo ngày/tháng → truy vấn nhanh hơn

Archiving

Chuyển dữ liệu cũ sang bảng khác giúp bảng chính nhỏ gọn

4. Tối ưu hóa tài nguyên và cấu hình hệ thống

Tối ưu RAM cho SQL Server / MySQL / PostgreSQL

Cấu hình số lượng kết nối tối đa

Bố trí ổ cứng:

SSD nhanh hơn HDD

Log và Data nên tách ổ

Caching

Query caching (MySQL)

Buffer Pool (SQL Server)

5. Giám sát hiệu suất (Monitoring)

Công cụ:

SQL Server: Execution Plan, Profiler, Extended Events

MySQL: EXPLAIN, Performance Schema

PostgreSQL: EXPLAIN ANALYZE

Theo dõi:

CPU – RAM – Disk I/O

Slow Query Log

Deadlock / Locking

Tình trạng index (fragmentation)

6. Cách thực hành tối ưu hóa trong thực tế
Bước 1: Dùng EXPLAIN / Execution Plan

→ Xem truy vấn đang quét bao nhiêu dòng.

Bước 2: Thêm hoặc chỉnh index

→ Đảm bảo toàn bộ truy vấn được “seek” thay vì “scan”.

Bước 3: Viết lại truy vấn cho tối ưu

→ Tránh phép toán không cần thiết.

Bước 4: Tối ưu bảng, partition, archive.
Bước 5: Theo dõi và bảo trì định kỳ.

*/