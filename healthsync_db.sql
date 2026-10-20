-- =============================================================================
-- HỆ THỐNG QUẢN LÝ PHÒNG KHÁM HEALTHSYNC (OPTIMIZED DATABASE SCHEMA)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS healthsync_db;
USE healthsync_db;

-- 1. Bảng Patients (Bệnh nhân)
CREATE TABLE IF NOT EXISTS Patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL
);

-- 2. Bảng Doctors (Bác sĩ)
CREATE TABLE IF NOT EXISTS Doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(50)
);

-- 3. Bảng Appointments (Lịch hẹn - Đã được tối ưu hóa chuẩn nghiệp vụ)
CREATE TABLE IF NOT EXISTS Appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    
    -- Sử dụng ENUM để quản lý chính xác 5 trạng thái vòng đời lịch hẹn
    status ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED') DEFAULT 'PENDING',
    
    -- Kiểu DECIMAL(10,2) đảm bảo tính chính xác cho giao dịch tài chính
    deposit_amount DECIMAL(10, 2) DEFAULT 0.00,
    penalty_fee DECIMAL(10, 2) DEFAULT 0.00,
    cancel_reason VARCHAR(255) NULL,
    
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
);

-- 4. Bảng Prescriptions (Đơn thuốc đi kèm khi khám COMPLETED)
CREATE TABLE IF NOT EXISTS Prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT UNIQUE NOT NULL, -- Quan hệ 1-1 với Lịch hẹn
    medication_details TEXT NOT NULL,
    issued_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id) ON DELETE CASCADE
);

-- =============================================================================
-- KỊCH BẢN THỰC THI VÀ MÔ PHỎNG DỮ LIỆU THỰC TẾ
-- =============================================================================

-- Thêm dữ liệu mẫu Bệnh nhân & Bác sĩ
INSERT INTO Patients (full_name, phone) VALUES 
('Nguyễn Văn A', '0912345678'),
('Trần Thị B', '0987654321');

INSERT INTO Doctors (full_name, specialty) VALUES 
('BS. Lê Văn C', 'Nội khoa'),
('BS. Phạm Thị D', 'Nhi khoa');

-- -----------------------------------------------------------------------------
-- KỊCH BẢN 1: Luồng thành công (PENDING -> CONFIRMED -> CHECKED_IN -> COMPLETED -> Kê đơn)
-- -----------------------------------------------------------------------------
-- 1. Bệnh nhân A đặt lịch hẹn
INSERT INTO Appointments (patient_id, doctor_id, appointment_date, status, deposit_amount)
VALUES (1, 1, '2026-10-25 09:00:00', 'PENDING', 500000.00);

-- 2. Đã xác nhận cọc & Đến khám
UPDATE Appointments 
SET status = 'CHECKED_IN' 
WHERE appointment_id = 1;

-- 3. Bác sĩ khám xong (COMPLETED)
UPDATE Appointments 
SET status = 'COMPLETED' 
WHERE appointment_id = 1;

-- 4. Bác sĩ kê đơn thuốc
INSERT INTO Prescriptions (appointment_id, medication_details)
VALUES (1, 'Paracetamol 500mg (20 viên), Amoxicillin 500mg (14 viên). Uống sau ăn.');

-- -----------------------------------------------------------------------------
-- KỊCH BẢN 2: Luồng hủy lịch có phạt tiền cọc (CONFIRMED -> CANCELLED + Penalty)
-- -----------------------------------------------------------------------------
-- 1. Bệnh nhân B đặt lịch và đóng cọc
INSERT INTO Appointments (patient_id, doctor_id, appointment_date, status, deposit_amount)
VALUES (2, 2, '2026-10-26 14:00:00', 'CONFIRMED', 300000.00);

-- 2. Bệnh nhân B báo hủy lịch -> Tính phí phạt 150.000đ
UPDATE Appointments 
SET status = 'CANCELLED',
    cancel_reason = 'Bận việc đột xuất không thể tới khám',
    penalty_fee = 150000.00
WHERE appointment_id = 2;

-- =============================================================================
-- TRUY VẤN ĐỐI SOÁT KIỂM TRA DỮ LIỆU
-- =============================================================================
-- Truy vấn danh sách bệnh nhân đã hoàn thành khám kèm đơn thuốc:
SELECT 
    a.appointment_id,
    p.full_name AS patient_name,
    d.full_name AS doctor_name,
    a.appointment_date,
    a.status,
    a.deposit_amount,
    pr.medication_details,
    pr.issued_date
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Doctors d ON a.doctor_id = d.doctor_id
JOIN Prescriptions pr ON a.appointment_id = pr.appointment_id
WHERE a.status = 'COMPLETED';