-- =============================================================================
-- HỆ THỐNG NHÀ MÁY THÔNG MINH SMARTFACTORY (DATABASE RE-INDEXING SCRIPT)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS smartfactory_db;
USE smartfactory_db;

-- Xóa bảng cũ nếu tồn tại để chạy lại sạch sẽ từ đầu
DROP TABLE IF EXISTS SensorLogs;

CREATE TABLE SensorLogs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sensor_id INT NOT NULL,
    recorded_at DATETIME NOT NULL,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    status VARCHAR(20) -- 'NORMAL', 'WARNING', 'CRITICAL'
);

-- =============================================================================
-- 1. TÌNH TRẠNG BAN ĐẦU: FAT INDEX GÂY NGHẼN CỔ CHAI GHI (WRITE BOTTLENECK)
-- Lập trình viên cũ đã nhét tất cả các cột vào Index làm tăng Write Penalty và dung lượng
-- =============================================================================
CREATE INDEX idx_fat_covering ON SensorLogs(sensor_id, recorded_at, temperature, humidity, status);

-- =============================================================================
-- 2. GIẢI PHÁP TỐI ƯU: TÁI CẤU TRÚC VỀ LEAN INDEX CÂN BẰNG ĐỌC/GHI
-- =============================================================================

-- Bước A: Xóa bỏ chỉ mục khổng lồ gây lãng phí storage và bóp nghẹt luồng INSERT
ALTER TABLE SensorLogs DROP INDEX idx_fat_covering;

-- Bước B: Tạo Lean Index mới (Chỉ mục tinh gọn chỉ dùng để tìm kiếm và lọc dữ liệu)
CREATE INDEX idx_lean_search ON SensorLogs(sensor_id, recorded_at);

-- =============================================================================
-- 3. KIỂM TRA KẾ HOẠCH THỰC THI (EXPLAIN) CHO DASHBOARD QUERY
-- =============================================================================
-- Truy vấn từ Dashboard: Vẫn sử dụng Lean Index để tìm kiếm cực nhanh, 
-- sau đó thực hiện Table Lookup để lấy các cột temperature, humidity, status.
EXPLAIN 
SELECT temperature, humidity, status 
FROM SensorLogs 
WHERE sensor_id = 105 
  AND recorded_at >= '2026-06-20';