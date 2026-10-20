-- =============================================================================
-- BÀI THỰC HÀNH: VIEW, INDEX, STORED PROCEDURE TRONG MYSQL
-- =============================================================================

-- Bước 1: Tạo cơ sở dữ liệu demo
CREATE DATABASE IF NOT EXISTS demo;
USE demo;

-- Bước 2: Tạo bảng Products và chèn dữ liệu mẫu
DROP TABLE IF EXISTS Products;
CREATE TABLE Products (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    productCode VARCHAR(50) NOT NULL,
    productName VARCHAR(100) NOT NULL,
    productPrice DECIMAL(10, 2) NOT NULL,
    productAmount INT NOT NULL,
    productDescription TEXT,
    productStatus VARCHAR(50)
);

-- Chèn dữ liệu mẫu vào bảng Products
INSERT INTO Products (productCode, productName, productPrice, productAmount, productDescription, productStatus) VALUES
('P001', 'Laptop Dell Inspiron', 15000000.00, 10, 'Core i5, 8GB RAM, 512GB SSD', 'Available'),
('P002', 'Mouse Logitech', 350000.00, 50, 'Wireless optical mouse', 'Available'),
('P003', 'Keyboard Mechanical', 1200000.00, 20, 'RGB backlit mechanical keyboard', 'Out of Stock'),
('P004', 'Monitor LG 24 inch', 3200000.00, 15, 'Full HD IPS monitor', 'Available');


-- =============================================================================
-- Bước 3: TẠO VÀ SỬ DỤNG INDEX
-- =============================================================================

-- 1. Tạo Unique Index trên cột productCode
CREATE UNIQUE INDEX idx_productCode ON Products(productCode);

-- 2. Tạo Composite Index trên 2 cột productName và productPrice
CREATE INDEX idx_name_price ON Products(productName, productPrice);

-- 3. Sử dụng EXPLAIN để kiểm tra câu lệnh SQL thực thi
-- Kiểm tra truy vấn tìm kiếm theo productCode (Sử dụng Unique Index)
EXPLAIN SELECT * FROM Products WHERE productCode = 'P001';

-- Kiểm tra truy vấn tìm kiếm theo Composite Index (productName và productPrice)
EXPLAIN SELECT * FROM Products WHERE productName = 'Laptop Dell Inspiron' AND productPrice = 15000000.00;


-- =============================================================================
-- Bước 4: TẠO, SỬA ĐỔI VÀ XOÁ VIEW
-- =============================================================================

-- 1. Tạo view lấy về các thông tin: productCode, productName, productPrice, productStatus
CREATE VIEW view_products AS
SELECT productCode, productName, productPrice, productStatus
FROM Products;

-- Xem thử dữ liệu từ View vừa tạo
SELECT * FROM view_products;

-- 2. Tiến hành sửa đổi view (thêm cột productAmount vào view)
CREATE OR REPLACE VIEW view_products AS
SELECT productCode, productName, productPrice, productAmount, productStatus
FROM Products;

-- 3. Tiến hành xoá view
DROP VIEW IF EXISTS view_products;

-- (Tạo lại view cơ bản để hệ thống dữ liệu hoàn chỉnh nếu cần dùng tiếp)
CREATE VIEW view_products AS
SELECT productCode, productName, productPrice, productStatus
FROM Products;


-- =============================================================================
-- Bước 5: TẠO STORED PROCEDURES
-- =============================================================================

-- Xóa các procedure cũ nếu đã tồn tại để tránh lỗi trùng lặp khi chạy lại
DROP PROCEDURE IF EXISTS sp_GetAllProducts;
DROP PROCEDURE IF EXISTS sp_AddProduct;
DROP PROCEDURE IF EXISTS sp_UpdateProductById;
DROP PROCEDURE IF EXISTS sp_DeleteProductById;

-- 1. Stored Procedure lấy tất cả thông tin của tất cả các sản phẩm
DELIMITER //
CREATE PROCEDURE sp_GetAllProducts()
BEGIN
    SELECT * FROM Products;
END //
DELIMITER ;

-- Cách gọi thử: CALL sp_GetAllProducts();


-- 2. Stored Procedure thêm một sản phẩm mới
DELIMITER //
CREATE PROCEDURE sp_AddProduct(
    IN p_productCode VARCHAR(50),
    IN p_productName VARCHAR(100),
    IN p_productPrice DECIMAL(10, 2),
    IN p_productAmount INT,
    IN p_productDescription TEXT,
    IN p_productStatus VARCHAR(50)
)
BEGIN
    INSERT INTO Products (productCode, productName, productPrice, productAmount, productDescription, productStatus)
    VALUES (p_productCode, p_productName, p_productPrice, p_productAmount, p_productDescription, p_productStatus);
END //
DELIMITER ;

-- Cách gọi thử thêm sản phẩm:
-- CALL sp_AddProduct('P005', 'Headphone Sony', 2500000.00, 30, 'Noise cancelling headphone', 'Available');


-- 3. Stored Procedure sửa thông tin sản phẩm theo id
DELIMITER //
CREATE PROCEDURE sp_UpdateProductById(
    IN p_Id INT,
    IN p_productName VARCHAR(100),
    IN p_productPrice DECIMAL(10, 2),
    IN p_productAmount INT,
    IN p_productDescription TEXT,
    IN p_productStatus VARCHAR(50)
)
BEGIN
    UPDATE Products
    SET productName = p_productName,
        productPrice = p_productPrice,
        productAmount = p_productAmount,
        productDescription = p_productDescription,
        productStatus = p_productStatus
    WHERE Id = p_Id;
END //
DELIMITER ;

-- Cách gọi thử sửa sản phẩm (Ví dụ sửa sản phẩm có Id = 1):
-- CALL sp_UpdateProductById(1, 'Laptop Dell Inspiron Pro', 16000000.00, 8, 'Upgraded version', 'Available');


-- 4. Stored Procedure xoá sản phẩm theo id
DELIMITER //
CREATE PROCEDURE sp_DeleteProductById(
    IN p_Id INT
)
BEGIN
    DELETE FROM Products WHERE Id = p_Id;
END //
DELIMITER ;

-- Cách gọi thử xóa sản phẩm (Ví dụ xóa sản phẩm có Id = 4):
-- CALL sp_DeleteProductById(4);