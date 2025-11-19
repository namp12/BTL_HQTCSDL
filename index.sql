use QLNH

/*
	index 

	-- cluster index :
		- bảng thường xuyên truy vấn theo khóa chính hoặc dải giá trị liên tục (Between, >, <, order by)
		CREATE CLUSTERED INDEX IX_Orders_OrderDate ON Orders(OrderDate);
	
	--  Non - cluster index :
		- cần tăng tốc truy vấn tìm kiếm theo điều kiện (where) hoặc join trên các cột không phải khóa chính
		- các cột được truy vấn thường xuyên nhưng không cập nhật thường xuyên
		- cần sắp xếp hoặc nhóm dữ liệu (order by, group by)
		CREATE NONCLUSTERED INDEX IX_Employees_Email
		ON Employees(Email);

	-- unique index:
		-- muốn đảm bảo giá trị trong cột không trùng lặp(tương tự unique constraint)
		-- tăng tốc truy vấn tìm kiếm chính sác trên cột đó
		CREATE UNIQUE INDEX IX_Customers_Email ON Customers(Email);

	-- Composite Index (Index trên nhiều cột):
		-- truy vấn thường kết hợp nhiều cột trong where hoặc order by
		-- thứ tự cột trong index phù hợp với thứ tự truy vấn
		CREATE INDEX IX_Orders_CustomerDate
		ON Orders(CustomerID, OrderDate);

	--  Filtered Index:
		- Bảng rất lớn nhưng thường chỉ truy vấn một phần nhỏ dữ liệu
		- muốn tiết kiệm dung lượng và tăng tốc chỉ cho subset dữ liệu
		CREATE NONCLUSTERED INDEX IX_Orders_Active
		ON Orders(Status)
		WHERE Status = 'Active';

	-- Full-Text Index :
		- cần tím kiếm văn bản hoặc mô tả dài
		- không thể tìm kiếm hiệu quả bằng like
		(CREATE FULLTEXT INDEX ON Articles(Content)
		KEY INDEX PK_Articles; )
		-- truy vấn
		(SELECT * FROM Articles
		WHERE CONTAINS(Content, '("AI" OR "Machine Learning")');)

	-- Columnstore Index
		- dữ liệu có hàng triệu bản ghi và phân tích nhiều hơn các giao dịch
		- cần truy vấn tổng hợp (sum, avg, count)
		CREATE CLUSTERED COLUMNSTORE INDEX IX_Sales_Analytics
		ON Sales;

*/

-- ============ BÀI LÀM ==============

/*
====== các cluster index có sẵn ========

	CHINHANH(MaChiNhanh)

	NHANVIENGIAODICH(MaNV)

	KHACHHANG(MaKH)

	LOAITAIKHOAN(MaLoaiTK)

	LOAIGIAODICH(MaLoaiGD)

	TAIKHOAN(MaTK)

	GIAODICH(MaGiaoDich)

*/


-- Mục đích: Tăng tốc tìm kiếm hoặc join bảng TAIKHOAN dựa trên MaKhachHang (MaKH).
CREATE NONCLUSTERED INDEX IX_TAIKHOAN_MaKH
ON TAIKHOAN (MaKH);

-- Mục đích: Tăng tốc tìm kiếm hoặc lọc các tài khoản theo MaChiNhanh.
CREATE NONCLUSTERED INDEX IX_TAIKHOAN_MaChiNhanh
ON TAIKHOAN (MaChiNhanh);

-- Mục đích: Tăng tốc tìm kiếm lịch sử giao dịch của một MaTaiKhoan (MaTK) cụ thể.
CREATE NONCLUSTERED INDEX IX_GIAODICH_MaTK
ON GIAODICH (MaTK);

-- Mục đích: Tăng tốc tìm kiếm các giao dịch được thực hiện bởi một MaNhanVien (MaNV).
CREATE NONCLUSTERED INDEX IX_GIAODICH_MaNV
ON GIAODICH (MaNV);

-- Mục đích: Tăng tốc lọc, sắp xếp, hoặc làm báo cáo giao dịch theo NgayGiaoDich (NgayGD).
-- (Lưu ý: Tên index là 'MaLoaiGD' nhưng lại được tạo trên cột 'NgayGD').
CREATE NONCLUSTERED INDEX IX_GIAODICH_MaLoaiGD
ON GIAODICH (NgayGD);

-- Mục đích: Tăng tốc đáng kể việc tìm kiếm khách hàng bằng SoDienThoai (SDT).
CREATE NONCLUSTERED INDEX IX_KHACHHANG_SDT
ON KHACHHANG (SDT);

