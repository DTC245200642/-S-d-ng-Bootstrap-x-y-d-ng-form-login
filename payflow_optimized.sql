-- =============================================================================
-- HỆ THỐNG VÍ ĐIỆN TỬ PAYFLOW (DATABASE PERFORMANCE OPTIMIZATION)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS payflow_db;
USE payflow_db;

-- Xóa bảng cũ nếu tồn tại để chạy lại sạch sẽ từ đầu
DROP TABLE IF EXISTS Transactions;

CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    amount DECIMAL(15,2),
    transaction_type VARCHAR(20), -- 'DEPOSIT', 'WITHDRAW', 'TRANSFER'
    created_at DATETIME
);

-- =============================================================================
-- 1. BÁO CÁO CŨ (LEGACY QUERY) - GÂY QUÉT TOÀN BẢNG (FULL TABLE SCAN)
-- Nguyên nhân: Dùng hàm YEAR() và MONTH() bọc quanh cột created_at (Non-SARGable)
-- =============================================================================
EXPLAIN 
SELECT SUM(amount) AS total_deposit
FROM Transactions
WHERE transaction_type = 'DEPOSIT' 
  AND YEAR(created_at) = 2026 
  AND MONTH(created_at) = 6;

-- =============================================================================
-- 2. GIẢI PHÁP TỐI ƯU HÓA (OPTIMIZED SOLUTION)
-- =============================================================================

-- Bước A: Tạo Composite Index (Index kết hợp) trên 2 cột phục vụ điều kiện lọc
-- Thứ tự: Đặt `transaction_type` trước vì có tính lọc (Selectivity) tuyệt đối, tiếp theo là `created_at`
CREATE INDEX idx_type_date ON Transactions(transaction_type, created_at);

-- Bước B: Tái cấu trúc truy vấn dạng SARGable (Sử dụng toán tử Range thay vì hàm)
-- Thay thế YEAR() và MONTH() bằng khoảng thời gian cụ thể (>= ngày đầu tháng và < ngày đầu tháng sau)
EXPLAIN 
SELECT SUM(amount) AS total_deposit
FROM Transactions
WHERE transaction_type = 'DEPOSIT' 
  AND created_at >= '2026-06-01 00:00:00' 
  AND created_at < '2026-07-01 00:00:00';