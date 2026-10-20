-- =============================================================================
-- HỆ THỐNG QUẢN LÝ CHO THUÊ XE AUTORIDE (OPTIMIZED DATABASE SCHEMA)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS autoride_db;
USE autoride_db;

-- 1. Bảng Cars (Quản lý xe)
CREATE TABLE IF NOT EXISTS Cars (
    car_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL
);

-- 2. Bảng Rentals (Hợp đồng thuê xe - Đã được bổ sung các trường tài chính & ENUM trạng thái)
CREATE TABLE IF NOT EXISTS Rentals (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    rent_date DATETIME NOT NULL,
    return_date DATETIME NULL,
    
    -- Sử dụng ENUM để kiểm soát chặt chẽ trạng thái vòng đời hợp đồng
    status ENUM('BOOKED', 'ACTIVE', 'COMPLETED', 'CANCELLED') DEFAULT 'BOOKED',
    
    -- Các cột tài chính phục vụ bài toán kế toán và hoàn tiền (Dùng DECIMAL tránh sai số)
    security_deposit DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    late_fee DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    damage_fee DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    
    FOREIGN KEY (car_id) REFERENCES Cars(car_id)
);

-- 3. Bảng Inspections (Biên bản kiểm tra tình trạng xe khi trả)
CREATE TABLE IF NOT EXISTS Inspections (
    inspection_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_id INT NOT NULL,
    inspection_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    damage_description TEXT NULL,
    inspector_name VARCHAR(100) NOT NULL,
    
    -- Ràng buộc khóa ngoại chặt chẽ
    FOREIGN KEY (rental_id) REFERENCES Rentals(rental_id) ON DELETE RESTRICT
);

-- =============================================================================
-- MÔ PHỎNG KỊCH BẢN NGHIỆP VỤ THỰC TẾ (DML)
-- =============================================================================

-- Thêm dữ liệu xe mẫu
INSERT INTO Cars (model_name, license_plate) VALUES 
('Toyota Vios 2024', '30E-123.45'),
('Mazda CX-5', '29A-999.99');

-- Bước 1: Khách hàng "Nguyen Van A" đặt xe và đóng cọc 10.000.000 VNĐ. Trạng thái: ACTIVE
INSERT INTO Rentals (car_id, customer_name, rent_date, status, security_deposit)
VALUES (1, 'Nguyen Van A', '2026-10-20 08:00:00', 'ACTIVE', 10000000.00);

-- Bước 2: Khách trả xe. Nhân viên kiểm tra phát hiện vỡ đèn pha trái.
-- Ghi nhận biên bản kiểm tra vào bảng Inspections
INSERT INTO Inspections (rental_id, damage_description, inspector_name)
VALUES (1, 'Vỡ đèn pha trái, xước nhẹ cửa phụ bên lái', 'Le Van Nhan Vien');

-- Bước 3: Cập nhật thông tin hợp đồng khi hoàn tất (COMPLETED)
-- Ghi nhận phí trễ giờ (late_fee = 0) và phí sửa chữa hư hỏng (damage_fee = 2.000.000 VNĐ)
UPDATE Rentals 
SET status = 'COMPLETED',
    return_date = '2026-10-25 10:00:00',
    late_fee = 0.00,
    damage_fee = 2000000.00
WHERE rental_id = 1;

-- =============================================================================
-- TRUY VẤN ĐỐI SOÁT & TÍNH TOÁN TIỀN HOÀN LẠI CHO KHÁCH
-- =============================================================================
-- Công thức hoàn tiền: Tiền cọc - Phí phạt trễ - Phí sửa chữa hư hỏng
SELECT 
    r.rental_id,
    r.customer_name,
    c.model_name,
    c.license_plate,
    r.status,
    r.security_deposit AS TienCoC,
    r.late_fee AS PhiPhatTre,
    r.damage_fee AS PhiSuaChuaHuHong,
    -- Tính toán số tiền thực tế hoàn trả cho khách hàng bằng biểu thức toán học SQL
    (r.security_deposit - r.late_fee - r.damage_fee) AS TienHoanLaiChoKhach,
    i.damage_description AS ChiTietHuHong
FROM Rentals r
JOIN Cars c ON r.car_id = c.car_id
LEFT JOIN Inspections i ON r.rental_id = i.rental_id
WHERE r.rental_id = 1;